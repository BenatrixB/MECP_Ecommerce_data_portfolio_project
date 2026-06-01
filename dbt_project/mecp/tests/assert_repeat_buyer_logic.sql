/*
Test is succssesful when there is  NO OUTPUT
Test is unsucssesful when there IS AN OUTPUT
*/

SELECT
*
FROM
    {{ref('int_dim_users')}}
WHERE 
    -- if is_buyer is 0 then is_repeat_buyer must be 0
    (is_buyer = 0 AND is_repeat_buyer = 1)