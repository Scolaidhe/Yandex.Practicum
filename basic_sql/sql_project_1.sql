---
SELECT COUNT(*)
FROM company
WHERE status = 'closed'

---
SELECT funding_total AS total_funding
FROM company
WHERE country_code = 'USA'
  AND category_code = 'news'
ORDER BY total_funding DESC

---
SELECT SUM(price_amount) AS total_price_amount
FROM acquisition
WHERE EXTRACT(YEAR FROM CAST(acquired_at AS TIMESTAMP)) IN (2011, 2012, 2013)
  AND term_code='cash'

---
SELECT first_name,
       last_name,
       twitter_username
FROM people
WHERE twitter_username LIKE('Silver%')

---
SELECT *
FROM people
WHERE twitter_username LIKE ('%money%')
  AND last_name LIKE('K%')

---
SELECT country_code,
       SUM(funding_total) AS funding_total_amount
FROM company
GROUP BY country_code
ORDER BY funding_total_amount DESC

---
SELECT funded_at,
       MIN(raised_amount) AS min_raised_amount,
       MAX(raised_amount) AS max_raised_amount
FROM funding_round
WHERE funded_at IN (SELECT funded_at
                    FROM funding_round
                    GROUP BY funded_at
                    HAVING MIN(raised_amount) != 0
                       AND MIN(raised_amount) != MAX(raised_amount))
GROUP BY funded_at

---
SELECT *,
       CASE
         WHEN invested_companies >= 100 THEN 'high_activity'
         WHEN invested_companies < 20 THEN 'low_activity'
         ELSE 'middle_activity'
       END fund_category
FROM fund

---
SELECT CASE
           WHEN invested_companies>=100 THEN 'high_activity'
           WHEN invested_companies>=20 THEN 'middle_activity'
           ELSE 'low_activity'
       END AS activity,
       ROUND(AVG(investment_rounds)) as avg_investment_rounds
FROM fund
GROUP BY activity
ORDER BY avg_investment_rounds;

---
SELECT country_code,
       MIN(invested_companies) AS min_invested_companies,
       MAX(invested_companies) AS max_invested_companies,
       AVG(invested_companies) AS avg_invested_companies
FROM fund
WHERE EXTRACT(YEAR FROM CAST(founded_at AS TIMESTAMP)) IN (2010, 2011, 2012)
GROUP BY country_code
HAVING MIN(invested_companies) != 0
ORDER BY avg_invested_companies DESC,
         country_code
LIMIT 10

---
SELECT p.first_name,
       p.last_name,
       e.instituition
FROM people AS p
LEFT JOIN education AS e ON (p.id = e.person_id)

---
SELECT c.name,
       COUNT(DISTINCT instituition) AS distinct_instituition
FROM education AS e
LEFT JOIN (SELECT id,
                  company_id
           FROM people) AS p ON (e.person_id = p.id)
LEFT JOIN (SELECT id,
                  name
           FROM company) AS c ON (p.company_id = c.id)
GROUP BY c.name
ORDER BY distinct_instituition DESC
LIMIT 5 OFFSET 1;

---
SELECT DISTINCT c.name
FROM company AS c
WHERE c.id IN (SELECT c.id
               FROM funding_round AS f_r
               JOIN company AS c ON(f_r.company_id=c.id) 
               WHERE is_first_round=1
                 AND is_last_round=1
                 AND c.status = 'closed')
GROUP BY c.name

---
SELECT DISTINCT p.id
FROM company AS c
INNER JOIN people AS p ON (c.id = p.company_id)
WHERE c.id IN (SELECT c.id
               FROM funding_round AS f_r
               JOIN company AS c ON(f_r.company_id=c.id) 
               WHERE is_first_round=1
                 AND is_last_round=1
                 AND c.status = 'closed')
GROUP BY p.id

---
SELECT DISTINCT p.id,
       e.instituition
FROM company AS c
INNER JOIN people AS p ON (c.id = p.company_id)
INNER JOIN education AS e ON (p.id=e.person_id)
WHERE c.id IN (SELECT c.id
               FROM funding_round AS f_r
               JOIN company AS c ON(f_r.company_id=c.id) 
               WHERE is_first_round=1
                 AND is_last_round=1
                 AND c.status = 'closed')
GROUP BY p.id, e.instituition

---
SELECT DISTINCT p.id,
       COUNT(e.instituition)
FROM company AS c
INNER JOIN people AS p ON (c.id = p.company_id)
INNER JOIN education AS e ON (p.id=e.person_id)
WHERE c.id IN (SELECT c.id
               FROM funding_round AS f_r
               JOIN company AS c ON(f_r.company_id=c.id) 
               WHERE is_first_round=1
                 AND is_last_round=1
                 AND c.status = 'closed')
GROUP BY p.id

---
SELECT AVG(i.instituition_quantity)
FROM (SELECT DISTINCT p.id,
       COUNT(e.instituition) AS instituition_quantity
FROM company AS c
INNER JOIN people AS p ON (c.id = p.company_id)
INNER JOIN education AS e ON (p.id=e.person_id)
WHERE c.id IN (SELECT c.id
               FROM funding_round AS f_r
               JOIN company AS c ON(f_r.company_id=c.id) 
               WHERE is_first_round=1
                 AND is_last_round=1
                 AND c.status = 'closed')
GROUP BY p.id) AS i

---
SELECT AVG(i.instituition_quantity)
FROM (SELECT DISTINCT p.id,
      COUNT(e.instituition) AS instituition_quantity
      FROM company AS c
      INNER JOIN people AS p ON (c.id = p.company_id)
      INNER JOIN education AS e ON (p.id=e.person_id)
      WHERE c.name = 'Facebook'
      GROUP BY p.id) AS i

---
WITH
i AS (SELECT id,
             name
      FROM company
      WHERE milestones > 6),
j AS (SELECT f_r.id,
             f_r.company_id AS company_id,
             f.name AS fund_name,
             SUM(raised_amount) AS amount
      FROM funding_round AS f_r
      INNER JOIN investment AS inv ON (f_r.id = inv.funding_round_id)
      INNER JOIN fund AS f ON (inv.fund_id=f.id)
      WHERE EXTRACT(YEAR FROM CAST(funded_at AS TIMESTAMP)) BETWEEN 2012 AND 2013
      GROUP BY f_r.id, f_r.company_id, f.name)
      
SELECT j.fund_name AS name_of_fund,
       ii.name AS name_of_company,
       j.amount AS amount
FROM j
INNER JOIN i AS ii ON (j.company_id=ii.id);

---
SELECT b.name AS acquiring_company_name,
       a.price_amount AS price_amount,
       c.name AS acquired_company_name,
       c.funding_total AS funding_total,
       ROUND(a.price_amount / c.funding_total) AS propotion
FROM acquisition AS a
LEFT JOIN (SELECT name,
                  id
           FROM company) AS b ON (a.acquiring_company_id=b.id)
LEFT JOIN (SELECT name,
                  id,
                  funding_total
           FROM company) AS c ON (a.acquired_company_id=c.id)
WHERE c.funding_total != 0
ORDER BY price_amount DESC,
         acquired_company_name
LIMIT 10;

---
SELECT c.name,
       EXTRACT(MONTH FROM CAST(funded_at AS TIMESTAMP)) AS month_funding
FROM funding_round AS f_r
LEFT JOIN company AS c ON (f_r.company_id=c.id)
WHERE EXTRACT(YEAR FROM CAST(funded_at AS TIMESTAMP)) BETWEEN 2010 AND 2013
  AND raised_amount != 0
  AND c.category_code = 'social'

---
WITH
   i AS (SELECT EXTRACT(MONTH FROM CAST(f_r.funded_at AS TIMESTAMP)) AS month_funding,
                COUNT(DISTINCT f.name) AS total_fond_names                     
         FROM funding_round AS f_r
         LEFT JOIN investment AS inv ON (f_r.id = inv.funding_round_id)
         LEFT JOIN fund AS f ON (inv.fund_id = f.id)
         WHERE EXTRACT(YEAR FROM CAST(f_r.funded_at AS TIMESTAMP)) BETWEEN 2010 AND 2013
           AND f.country_code = 'USA'
         GROUP BY month_funding),
   j AS (SELECT EXTRACT(MONTH FROM CAST(acquired_at AS TIMESTAMP)) AS acquired_month,
                COUNT(acquired_company_id) AS total_acquired_companies,
                SUM(price_amount) AS sum_prices
         FROM acquisition
         WHERE EXTRACT(YEAR FROM CAST(acquired_at AS TIMESTAMP)) BETWEEN 2010 AND 2013
         GROUP BY acquired_month)

SELECT i.month_funding AS month,
       i.total_fond_names AS total_fond_names,
       jj.total_acquired_companies,
       jj.sum_prices AS price_amount
FROM i
LEFT JOIN j AS jj ON (i.month_funding=jj.acquired_month)
ORDER BY month 

---
WITH
   i AS (SELECT country_code,
                AVG(funding_total) AS avg_funding_total
         FROM company
         WHERE EXTRACT(YEAR FROM CAST(founded_at AS TIMESTAMP)) = 2011
         GROUP BY country_code),
   j AS (SELECT country_code,
                AVG(funding_total) AS avg_funding_total
         FROM company
         WHERE EXTRACT(YEAR FROM CAST(founded_at AS TIMESTAMP)) = 2012
         GROUP BY country_code),
   k AS (SELECT country_code,
                AVG(funding_total) AS avg_funding_total
         FROM company
         WHERE EXTRACT(YEAR FROM CAST(founded_at AS TIMESTAMP)) = 2013
         GROUP BY country_code)

SELECT i.country_code AS country_code,
       i.avg_funding_total AS year_2011,
       j.avg_funding_total AS year_2012,
       k.avg_funding_total AS year_2013
FROM i
JOIN j USING(country_code)
JOIN k USING(country_code)
ORDER BY year_2011 DESC

---