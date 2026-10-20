"""
MECP Text-to-SQL
----------------
Reads mart model descriptions from schema.yml, sends them as context to
Ollama (Llama 3.2), generates PostgreSQL SQL, executes it on the MECP
database, and prints the results.

Usage:
    python text_to_sql.py
    python text_to_sql.py --question "What is the total revenue by product?"
    python text_to_sql.py --dry-run   # prints SQL without executing
"""

import argparse
import json
import os
import sys
import textwrap
import urllib.request
import urllib.error

import psycopg2
import yaml


# ── Config ────────────────────────────────────────────────────────────────────

OLLAMA_URL = "http://localhost:11434/api/generate"
OLLAMA_MODEL = "llama3.2"

DB_CONFIG = {
    "host": os.getenv("DB_HOST", "localhost"),
    "port": int(os.getenv("DB_PORT", 5432)),
    "dbname": os.getenv("DB_NAME", "mecp"),
    "user": os.getenv("DB_USER", "postgres"),
    "password": os.getenv("DB_PASSWORD", "postgres"),
}

# Path to schema.yml — adjust if running from a different directory
SCHEMA_PATH = os.getenv(
    "SCHEMA_PATH",
    os.path.join(os.path.dirname(__file__), "dbt_project/mecp/models/marts/schema.yml"),
)

MART_SCHEMA = os.getenv("MART_SCHEMA", "marts")   # PostgreSQL schema where mart tables live


# ── Schema loader ─────────────────────────────────────────────────────────────

def load_schema(path: str) -> str:
    """Read schema.yml and build a compact schema-context string for the LLM."""
    with open(path, "r", encoding="utf-8") as f:
        schema = yaml.safe_load(f)

    lines = [f"The following PostgreSQL tables are available (all in the '{MART_SCHEMA}' schema):\n"]

    for model in schema.get("models", []):
        table = model["name"]
        model_desc = model.get("description", "")
        lines.append(f"TABLE: {table}")
        if model_desc:
            lines.append(f"  Description: {model_desc}")
        lines.append("  Columns:")
        for col in model.get("columns", []):
            col_desc = col.get("description", "")
            if col_desc:
                lines.append(f"    - {col['name']}: {col_desc}")
            else:
                lines.append(f"    - {col['name']}")
        lines.append("")

    return "\n".join(lines)


# ── Prompt builder ────────────────────────────────────────────────────────────

SYSTEM_PROMPT = textwrap.dedent("""\
    You are a PostgreSQL expert. Your job is to convert natural-language
    business questions into correct, runnable PostgreSQL SQL queries.

    Rules:
    1. Output ONLY the SQL query — no explanation, no markdown fences, no
       commentary before or after.
    2. Use only the tables and columns listed in the schema context below.
    3. CRITICAL: All tables are in the PostgreSQL schema called 'marts'. You MUST always write the full qualified name: marts.mart_users, marts.mart_orders, marts.mart_products, marts.mart_sessions, marts.mart_funnel, marts.mart_cohorts, marts.mart_ab_tests. NEVER write just mart_users — always marts.mart_users.
    4. Always add a LIMIT 100 unless the question asks for aggregated totals
       where a limit makes no sense.
    5. Use standard PostgreSQL syntax. Do not use dialect-specific functions
       from other databases.
    6. If a question is ambiguous, make a reasonable assumption and write the
       query for the most likely interpretation.
""")


def build_prompt(schema_context: str, question: str) -> str:
    return f"{SYSTEM_PROMPT}\n\nSCHEMA CONTEXT:\n{schema_context}\n\nQUESTION: {question}\n\nSQL:"


# ── Ollama call ───────────────────────────────────────────────────────────────

def call_ollama(prompt: str, model: str = OLLAMA_MODEL) -> str:
    """Send prompt to Ollama and return the generated text."""
    payload = json.dumps({
        "model": model,
        "prompt": prompt,
        "stream": False,
        "options": {
            "temperature": 0.0,   # deterministic — we want correct SQL, not creativity
            "num_predict": 512,
        },
    }).encode("utf-8")

    req = urllib.request.Request(
        OLLAMA_URL,
        data=payload,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(req, timeout=120) as resp:
            body = json.loads(resp.read().decode("utf-8"))
            return body.get("response", "").strip()
    except urllib.error.URLError as e:
        print(f"[ERROR] Cannot reach Ollama at {OLLAMA_URL}: {e}")
        print("Make sure Ollama is running: ollama serve")
        sys.exit(1)


MART_TABLES = [
    "mart_orders", "mart_products", "mart_sessions",
    "mart_users", "mart_funnel", "mart_cohorts", "mart_ab_tests",
]


def extract_sql(raw: str) -> str:
    """Strip markdown fences and ensure mart tables have schema prefix."""
    raw = raw.strip()
    if raw.startswith("```"):
        lines = raw.splitlines()
        lines = lines[1:]
        if lines and lines[-1].strip().startswith("```"):
            lines = lines[:-1]
        raw = "\n".join(lines).strip()

    import re

    # Fix "alias.marts.mart_table.column" → just "column"
    # e.g. m.marts.mart_sessions.session_id → session_id
    raw = re.sub(r'\b\w+\.marts\.mart_\w+\.(\w+)', r'\1', raw)

    # Fix "alias.mart_table.column" → "alias.column"
    # e.g. m.mart_sessions.session_id → m.session_id
    raw = re.sub(r'\b(\w+)\.mart_\w+\.(\w+)', r'\1.\2', raw)

    # Fix "alias.marts.mart_table" → "marts.mart_table"
    raw = re.sub(r'\b\w+\.marts\.(mart_\w+)', r'marts.\1', raw)

    # Remove double schema prefix: marts.marts.mart_table → marts.mart_table
    raw = re.sub(r'marts\.marts\.(mart_\w+)', r'marts.\1', raw)

    # Ensure all bare mart table references are schema-qualified
    # but NOT when preceded by an alias dot (e.g. "m.mart_sessions")
    for table in MART_TABLES:
        raw = re.sub(rf'(?<!marts\.)(?<!\w\.)\b{table}\b', f'marts.{table}', raw)

    return raw


# ── PostgreSQL execution ──────────────────────────────────────────────────────

def run_query(sql: str, config: dict) -> list[dict]:
    """Execute SQL and return rows as a list of dicts."""
    conn = psycopg2.connect(**config)
    try:
        with conn.cursor() as cur:
            cur.execute(sql)
            columns = [desc[0] for desc in cur.description]
            rows = cur.fetchall()
            return [dict(zip(columns, row)) for row in rows]
    finally:
        conn.close()


def print_results(rows: list[dict]) -> None:
    if not rows:
        print("(no rows returned)")
        return

    # Determine column widths
    cols = list(rows[0].keys())
    widths = {c: max(len(str(c)), max(len(str(r[c])) for r in rows)) for c in cols}

    header = "  ".join(str(c).ljust(widths[c]) for c in cols)
    separator = "  ".join("-" * widths[c] for c in cols)
    print(header)
    print(separator)
    for row in rows:
        print("  ".join(str(row[c]).ljust(widths[c]) for c in cols))
    print(f"\n({len(rows)} row{'s' if len(rows) != 1 else ''})")


# ── Interactive loop ──────────────────────────────────────────────────────────

def interactive_loop(schema_context: str, dry_run: bool = False) -> None:
    print("MECP Text-to-SQL  |  type 'exit' or Ctrl-C to quit\n")
    while True:
        try:
            question = input("Question: ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nBye!")
            break

        if not question:
            continue
        if question.lower() in ("exit", "quit", "q"):
            print("Bye!")
            break

        print("Generating SQL...")
        prompt = build_prompt(schema_context, question)
        raw = call_ollama(prompt)
        sql = extract_sql(raw)

        print(f"\n── SQL ──\n{sql}\n")

        if dry_run:
            print("[dry-run] Skipping execution.\n")
            continue

        print("── Results ──")
        try:
            rows = run_query(sql, DB_CONFIG)
            print_results(rows)
        except Exception as e:
            print(f"[DB ERROR] {e}")
        print()


# ── Entry point ───────────────────────────────────────────────────────────────

def main() -> None:
    parser = argparse.ArgumentParser(description="MECP Text-to-SQL via Ollama + Llama 3.2")
    parser.add_argument("--question", "-q", help="Single question (non-interactive mode)")
    parser.add_argument("--dry-run", action="store_true", help="Generate SQL but do not execute it")
    parser.add_argument("--schema", default=SCHEMA_PATH, help="Path to schema.yml")
    parser.add_argument("--model", default=OLLAMA_MODEL, help="Ollama model name")
    args = parser.parse_args()

    # Load schema
    schema_path = args.schema
    if not os.path.exists(schema_path):
        print(f"[ERROR] schema.yml not found at: {schema_path}")
        print("Set --schema or SCHEMA_PATH env variable to the correct path.")
        sys.exit(1)

    schema_context = load_schema(schema_path)

    if args.question:
        # Single-question mode
        print(f"Question: {args.question}")
        print("Generating SQL...")
        prompt = build_prompt(schema_context, args.question)
        raw = call_ollama(prompt, model=args.model)
        sql = extract_sql(raw)
        print(f"\n── SQL ──\n{sql}\n")

        if not args.dry_run:
            print("── Results ──")
            try:
                rows = run_query(sql, DB_CONFIG)
                print_results(rows)
            except Exception as e:
                print(f"[DB ERROR] {e}")
    else:
        # Interactive loop
        interactive_loop(schema_context, dry_run=args.dry_run)


if __name__ == "__main__":
    main()
