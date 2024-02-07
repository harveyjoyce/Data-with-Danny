select *
from TIL_PLAYGROUND.CS3_FOODIE_FI.PLANS;

select *
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions;

select 
customer_id
,plan_name
,price
,start_date
from TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS s
inner join plans p
on s.plan_id=p.plan_id
WHERE customer_id BETWEEN 0 and 8;





-- How many customers has Foodie-Fi ever had? A. 1000
select
count(distinct customer_id)
from TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS;
-- What is the monthly distribution of trial plan start_date values for our dataset - use the start of the month as the group by value
select
date_trunc('MONTH', start_date) as month_date
,count(customer_id)
from TIL_PLAYGROUND.CS3_FOODIE_FI.SUBSCRIPTIONS
where plan_id=0
group by month_date;
-- What plan start_date values occur after the year 2020 for our dataset? Show the breakdown by count of events for each plan_name
select
plan_name
,count(*) as event 
from subscriptions s
inner join plans p
on s.plan_id=p.plan_id
where date_part('year', start_date)>2020
group by plan_name;

-- What is the customer count and percentage of customers who have churned rounded to 1 decimal place?
select
count(distinct customer_id) as total
,(select 
    count(distinct customer_id)
    from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
    where s.plan_id=4
    group by plan_id) 
as num_of_churn
, (round(((num_of_churn/total)*100),1))||'%' as percent
from subscriptions;


-- How many customers have churned straight after their initial free trial - what percentage is this rounded to the nearest whole number?
with cte as (
select *
, row_number() over (partition by customer_id order by start_date) as rnum 
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
inner join plans p
on s.plan_id=p.plan_id )

SELECT 
COUNT(DISTINCT customer_id) as churned_afer_trial_customers,
ROUND((COUNT(DISTINCT customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM subscriptions))*100,0) as percent_churn_after_trial
FROM CTE
WHERE rnum = 2 --after trial
AND plan_name = 'churn' --cancel
;

-- What is the number and percentage of customer plans after their initial free trial?
with cte as (
select *
, row_number() over (partition by customer_id order by start_date) as rnum 
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
inner join plans p
on s.plan_id=p.plan_id )

SELECT 
plan_name
,COUNT(DISTINCT customer_id) as afer_trial_customers
,ROUND((COUNT( customer_id) / (SELECT COUNT(DISTINCT customer_id) FROM cte))*100,1) as percent
FROM CTE
WHERE rnum = 2 
group by plan_name
;
-- What is the customer count and percentage breakdown of all 5 plan_name values at 2020-12-31?
WITH CTE AS (
SELECT *
,ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY start_date DESC) as rn
FROM subscriptions
WHERE start_date <= '2020-12-31'
)-- from this date, give me everyones history

select 
plan_name
,count(distinct customer_id) as num --num of custs per plan
,round((count(distinct customer_id) / (select count(distinct customer_id) from cte))*100,1) as percent --num of custs per plan/total custs
from cte
inner join plans p
on cte.plan_id=p.plan_id 
where rn=1 -- give me everyones current plan e.g rn=1
group by plan_name;

-- How many customers have upgraded to an annual plan in 2020?

with cte as 
(select 
s.plan_id
,p.plan_name
,s.start_date
,customer_id
, row_number() over (partition by customer_id order by start_date) as rnum 
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
inner join plans p
on s.plan_id=p.plan_id 
where date_part('year', start_date)=2020)

select 
count(distinct customer_id) as num 
from cte
inner join plans p
on cte.plan_id=p.plan_id 
where rnum > 1
AND p.plan_id = 3
group by p.plan_id;

-- How many days on average does it take for a customer to an annual plan from the day they join Foodie-Fi?
with trial as 
(select 
s.plan_id
,p.plan_name
,s.start_date as trial_date
,customer_id
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
inner join plans p
on s.plan_id=p.plan_id 
where p.plan_id=0)

, annual as (
SELECT 
customer_id,
start_date as annual_start
FROM subscriptions
WHERE plan_id = 3)

select 
round(avg(annual_start-trial_date)) as avg_days
from trial t
inner join annual a
on t.customer_id=a.customer_id

;


-- Can you further breakdown this average value into 30 day periods (i.e. 0-30 days, 31-60 days etc)
with trial as 
(select 
s.plan_id
,p.plan_name
,s.start_date as trial_start
,customer_id
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
inner join plans p
on s.plan_id=p.plan_id 
where p.plan_id=0)

, annual as (
SELECT 
customer_id,
start_date as annual_start
FROM subscriptions
WHERE plan_id = 3)

select 
count(t.customer_id) as num
, CASE
    WHEN DATEDIFF('days',trial_start,annual_start)<=30  THEN '0-30'
    WHEN DATEDIFF('days',trial_start,annual_start)<=60  THEN '31-60'
    WHEN DATEDIFF('days',trial_start,annual_start)<=90  THEN '61-90'
    WHEN DATEDIFF('days',trial_start,annual_start)<=120  THEN '91-120'
    WHEN DATEDIFF('days',trial_start,annual_start)<=150  THEN '121-150'
    WHEN DATEDIFF('days',trial_start,annual_start)<=180  THEN '151-180'
    WHEN DATEDIFF('days',trial_start,annual_start)<=210  THEN '181-210'
    WHEN DATEDIFF('days',trial_start,annual_start)<=240  THEN '211-240'
    WHEN DATEDIFF('days',trial_start,annual_start)<=270  THEN '241-270'
    WHEN DATEDIFF('days',trial_start,annual_start)<=300  THEN '271-300'
    WHEN DATEDIFF('days',trial_start,annual_start)<=330  THEN '301-330'
    WHEN DATEDIFF('days',trial_start,annual_start)<=360  THEN '331-360'
END as bin
from trial t
inner join annual a
on t.customer_id=a.customer_id
group by bin;

-- How many customers downgraded from a pro monthly to a basic monthly plan in 2020?
with prom as
(select 
s.plan_id
,p.plan_name
,s.start_date as prom_start
,customer_id
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
inner join plans p
on s.plan_id=p.plan_id 
where p.plan_id=2)

, basm as
(select 
s.plan_id
,p.plan_name
,s.start_date as basm_start
,customer_id
from TIL_PLAYGROUND.CS3_FOODIE_FI.subscriptions s
inner join plans p
on s.plan_id=p.plan_id 
where p.plan_id=1)

select 
*
from prom pro
inner join basm bas
on pro.customer_id=bas.customer_id
where DATE_PART('year',basm_start) = 2020
and (DATEDIFF('days',basm_start,prom_start)<0);


WITH PRO_MON AS (
SELECT 
customer_id,
start_date as pro_monthly_start
FROM subscriptions
WHERE plan_id = 2
)
,BASIC_MON AS (
SELECT 
customer_id,
start_date as basic_monthly_start
FROM subscriptions
WHERE plan_id = 1
)
SELECT 
P.customer_id,
pro_monthly_start,
basic_monthly_start
FROM PRO_MON as P
INNER JOIN BASIC_MON as B on P.customer_id = B.customer_id
WHERE pro_monthly_start < basic_monthly_start
AND DATE_PART('year',basic_monthly_start) = 2020;