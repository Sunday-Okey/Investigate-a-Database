1. What Movies in each Film category have been rented the most?

WITH sub AS (
    SELECT
        title AS film_title,
        name AS category_name,
        COUNT(*) rental_count
    FROM
        category c
    JOIN
        film_category f ON c.category_id = f.category_id
    JOIN
        film m ON m.film_id = f.film_id
    JOIN
        inventory i ON m.film_id = i.film_id
    JOIN
        rental r ON r.inventory_id = i.inventory_id
    WHERE
        name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
    GROUP BY
        1, 2
    ORDER BY
        2, 3 DESC
),
sub1 AS (
    SELECT
        category_name,
        MAX(rental_count) AS max_value
    FROM
        sub
    GROUP BY
        category_name
)

SELECT
    sub.film_title,
    sub1.category_name,
    max_value
FROM
    sub
JOIN
    sub1 ON sub.category_name = sub1.category_name
    AND sub1.max_value = sub.rental_count;


2. Which Family-Friendly category has the least number of movies in the first and third quartile of the rental duration?


WITH sub AS (
    SELECT
        title,
        name,
        rental_duration,
        NTILE(4) OVER (ORDER BY rental_duration) AS quartile
    FROM
        category c
    JOIN
        film_category f ON c.category_id = f.category_id
    JOIN
        film m ON m.film_id = f.film_id
    WHERE
        name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
)

SELECT
    name,
    quartile,
    COUNT(*)
FROM
    sub
GROUP BY
    1, 2
ORDER BY
    1, 2;


3. What were the total Rental Orders Per Staff?

SELECT
    DATE_PART('month', rental_date) AS month,
    DATE_PART('year', rental_date) AS year,
    store_id,
    COUNT(*)
FROM
    rental
JOIN
    staff USING(staff_id)
JOIN
    store USING(store_id)
GROUP BY
    1, 2, 3
ORDER BY
    4 DESC;


4. For each of the top 10 paying customers, which customer paid the maximum difference?

WITH t1 AS (
    WITH sub AS (
        SELECT
            CONCAT(first_name, ' ', last_name) AS name,
            SUM(amount) payment_amount
        FROM
            customer
        JOIN
            payment USING(customer_id)
        GROUP BY
            1
        ORDER BY
            2 DESC
        LIMIT
            10
    ),
    sub1 AS (
        SELECT
            DATE_TRUNC('month', payment_date) AS pay_month,
            CONCAT(first_name, ' ', last_name) AS name,
            COUNT(*) pay_count,
            SUM(amount) pay_amount
        FROM
            customer
        JOIN
            payment USING(customer_id)
        WHERE
            DATE_PART('year', payment_date) = '2007'
        GROUP BY
            1, 2
    )

    SELECT
        pay_month,
        sub1.name,
        pay_count,
        pay_amount
    FROM
        sub1
    WHERE
        sub1.name IN (SELECT name FROM sub)
    ORDER BY
        2, 1
)

SELECT
    name,
    lag_difference,
    pay_month
FROM (
    SELECT
        pay_month,
        name,
        pay_amount,
        pay_amount - LAG(pay_amount) OVER (PARTITION BY name ORDER BY pay_month) AS lag_difference
    FROM
        t1
    ORDER BY
        2, 1
) t2
WHERE
    lag_difference IS NOT NULL
ORDER BY
    2 DESC;
