
-- checking if the date is in future
-- If date is in future test is succsesful and returns the row
{% test future_date_test(model, column_name) %}

SELECT 
    *
FROM 
    {{ model }}
WHERE 
    {{ column_name }} > CURRENT_TIMESTAMP

{% endtest %}