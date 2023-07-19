---
SELECT COUNT(*)
FROM stackoverflow.posts sp
JOIN stackoverflow.post_types spt ON (sp.post_type_id=spt.id)
WHERE (sp.score > 300
OR sp.favorites_count >= 100)
AND spt.type = 'Question'

---
WITH qn AS
(SELECT CAST(sp.creation_date AS date) AS dt,
       COUNT(*) AS question_number
FROM stackoverflow.posts sp
JOIN stackoverflow.post_types spt ON (sp.post_type_id=spt.id)
WHERE spt.type = 'Question'
AND CAST(sp.creation_date AS date) BETWEEN '2008-11-01' AND '2008-11-18'
GROUP BY dt)
SELECT ROUND(AVG(question_number))
FROM qn

---
SELECT COUNT(DISTINCT su.id)
FROM stackoverflow.users su
JOIN stackoverflow.badges sb ON (su.id = sb.user_id)
WHERE CAST(su.creation_date AS date) = CAST(sb.creation_date AS date)

---
SELECT COUNT(DISTINCT sv.post_id)
FROM stackoverflow.users su
JOIN stackoverflow.posts sp ON (su.id=sp.user_id)
LEFT JOIN stackoverflow.votes sv ON (sp.id=sv.post_id)
WHERE su.display_name = 'Joel Coehoorn'
HAVING COUNT(sv.id)>=1

---
SELECT *,
       RANK() OVER (ORDER BY id DESC) AS rank
FROM stackoverflow.vote_types
ORDER BY id

---
SELECT sv.user_id,
       --RANK() OVER (PARTITION BY sv.user_id ORDER BY)
       COUNT(*) AS votes_cnt
FROM stackoverflow.votes sv
JOIN stackoverflow.vote_types svt ON (sv.vote_type_id=svt.id)
WHERE svt.name='Close'
GROUP BY sv.user_id
ORDER BY votes_cnt DESC
LIMIT 10

---
WITH badge_count AS
(SELECT DISTINCT
        su.id AS uu_id,
        COUNT(*) OVER (PARTITION BY su.id) AS badges_cnt
FROM stackoverflow.users su
JOIN stackoverflow.badges sb ON (su.id=sb.user_id)
WHERE CAST(sb.creation_date AS date) BETWEEN '2008-11-15' AND '2008-12-15'
)

SELECT uu_id,
       badges_cnt,
       DENSE_RANK() OVER (ORDER BY badges_cnt DESC) AS badges_rank
FROM badge_count
ORDER BY badges_rank,
         uu_id
LIMIT 10

---
SELECT sp.title,
       sp.user_id,
       sp.score,
       ROUND(AVG(sp.score) OVER (PARTITION BY user_id)) AS avg_score
FROM stackoverflow.posts sp
WHERE sp.title IS NOT NULL 
  AND sp.score != 0

---
WITH badges_leaders AS
(SELECT su.id AS uu_id
 FROM stackoverflow.users su
 JOIN stackoverflow.badges sb ON (su.id=sb.user_id)
 GROUP BY su.id
 HAVING COUNT(*) > 1000)
SELECT sp.title
FROM badges_leaders bl
JOIN stackoverflow.posts sp ON (bl.uu_id=sp.user_id)
WHERE sp.title IS NOT NULL

---
SELECT id,
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views < 100 THEN 3
           ELSE 2
       END AS views_group
FROM stackoverflow.users su
WHERE location LIKE '%_nited__tates%'
  AND views !=0

---
WITH views_grouped AS
(SELECT id,
       views,
       CASE
           WHEN views >= 350 THEN 1
           WHEN views < 100 THEN 3
           ELSE 2
       END AS views_group
FROM stackoverflow.users su
WHERE location LIKE '%_nited__tates%'
  AND views !=0),
rows_number AS
(SELECT id,
        views,
        views_group,
        DENSE_RANK() OVER (PARTITION BY views_group ORDER BY views DESC) AS rn
 FROM views_grouped)

SELECT id,
       views_group,
       views AS max_views
FROM rows_number
WHERE rn=1
ORDER BY max_views DESC,
         id

---
WITH users_per_day AS
(SELECT EXTRACT(DAY FROM creation_date) AS day_number,
       COUNT(*) AS users_cnt_day
FROM stackoverflow.users
WHERE CAST(creation_date AS date) BETWEEN '2008-11-01' AND '2008-11-30'
GROUP BY day_number)

SELECT day_number,
       users_cnt_day,
       SUM(users_cnt_day) OVER (ORDER BY day_number)
FROM users_per_day

---
SELECT DISTINCT
       su.id,
       FIRST_VALUE(sp.creation_date) OVER (PARTITION BY su.id ORDER BY sp.creation_date) - su.creation_date AS reg_and_post_delta
FROM stackoverflow.users su
JOIN stackoverflow.posts sp ON (su.id=sp.user_id)

---
SELECT CAST(DATE_TRUNC('month', creation_date) AS date) AS month,
       SUM(views_count) AS views_cnt_per_month
FROM stackoverflow.posts
WHERE EXTRACT(YEAR FROM creation_date) = 2008
GROUP BY month
ORDER BY views_cnt_per_month DESC

---
SELECT su.display_name AS nickname,
       COUNT(DISTINCT sp.user_id) AS ids_cnt
FROM stackoverflow.users su
JOIN stackoverflow.posts sp ON (su.id=sp.user_id)
JOIN stackoverflow.post_types spt ON(sp.post_type_id=spt.id)
WHERE spt.type='Answer'
  AND sp.creation_date::date BETWEEN su.creation_date::date AND su.creation_date::date + INTERVAL '1 month' 
GROUP BY nickname
HAVING COUNT(sp.id) > 100
ORDER BY nickname

---
WITH users_2008 AS (SELECT sp.user_id AS uu_id
FROM stackoverflow.users su
JOIN stackoverflow.posts sp ON su.id=sp.user_id
WHERE su.creation_date::date BETWEEN '2008-09-01' AND '2008-09-30'
  AND sp.creation_date::date BETWEEN '2008-12-01' AND '2008-12-31'
GROUP BY uu_id)

SELECT DATE_TRUNC('month', p.creation_date)::date AS month_num,
       COUNT(p.id) AS posts_cnt
FROM users_2008 u
JOIN stackoverflow.posts p ON (u.uu_id=p.user_id)
GROUP BY month_num
ORDER BY month_num DESC

---
SELECT user_id,
       creation_date,
       views_count,
       SUM(views_count) OVER (PARTITION BY user_id ORDER BY creation_date) AS views_cum
FROM stackoverflow.posts sp
ORDER BY user_id,
         creation_date

---
WITH daily_activity AS
(SELECT user_id,
       COUNT(DISTINCT EXTRACT(DAY FROM creation_date)) AS days_active
FROM stackoverflow.posts sp
WHERE creation_date::date BETWEEN '2008-12-01' AND '2008-12-07'
GROUP BY user_id)
SELECT ROUND(AVG(days_active)) AS avg_days_active
FROM daily_activity

---
WITH posts_per_month AS(SELECT EXTRACT(MONTH FROM creation_date) AS month_num,
       COUNT(id) AS posts_cnt
FROM stackoverflow.posts
WHERE creation_date::date BETWEEN '2008-09-01' AND '2008-12-31'
GROUP BY month_num)
SELECT month_num,
       posts_cnt,
       ROUND((posts_cnt - LAG(posts_cnt) OVER ())::numeric / LAG(posts_cnt) OVER () * 100, 2) AS delta_posts_percent 
FROM posts_per_month

---
WITH active_user AS(SELECT user_id,
       COUNT(id) AS posts_cnt
FROM stackoverflow.posts
GROUP BY user_id
ORDER BY posts_cnt DESC
LIMIT 1),

posts_dt AS (SELECT DATE_PART('week', creation_date) AS week_number,
       LAST_VALUE(creation_date) OVER (ORDER BY DATE_PART('week', creation_date)) AS last_date 
FROM stackoverflow.posts
JOIN active_user USING (user_id)
WHERE creation_date::date BETWEEN '2008-10-01' AND '2008-10-31'
GROUP BY week_number, creation_date, user_id)

SELECT week_number,
       last_date
FROM posts_dt
GROUP BY week_number, last_date
ORDER BY week_number

---