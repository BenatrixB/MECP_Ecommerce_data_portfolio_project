{% test negative_price_test(model, column_name) %}

SELECT
    *
FROM
    {{ model }}
WHERE {{column_name}} < 0

{% endtest %}