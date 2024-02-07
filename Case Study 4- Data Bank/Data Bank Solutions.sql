How many unique nodes are there on the Data Bank system?

select 
node_id
, count(*)
from TIL_PLAYGROUND.CS4_DATA_BANK.CUSTOMER_NODES
group by node_id;

-- What is the number of nodes per region?

select 
r.region_name
, count(distinct node_id)
from TIL_PLAYGROUND.CS4_DATA_BANK.CUSTOMER_NODES cn
inner join TIL_PLAYGROUND.CS4_DATA_BANK.REGIONS r
on r.region_id=cn.region_id
group by r.region_name;

-- How many customers are allocated to each region?

select 
r.region_name
, count(distinct cn.customer_id)
from TIL_PLAYGROUND.CS4_DATA_BANK.CUSTOMER_NODES cn
inner join TIL_PLAYGROUND.CS4_DATA_BANK.REGIONS r
on r.region_id=cn.region_id
group by r.region_name;

-- How many days on average are customers reallocated to a different node?

with cte as(
select
customer_id
,node_id
, sum(datediff(day,start_date,end_date)) as days_between
from customer_nodes
where end_date <> '9999-12-31'
group by customer_id, node_id)

select
round(avg(days_between))
from cte;

-- What is the median, 80th and 95th percentile for this same reallocation days metric for each region?

with cte1 as 
(select
region_name
,customer_id
,node_id
, sum(datediff(day,start_date,end_date)) as days_between
from customer_nodes cn
inner join TIL_PLAYGROUND.CS4_DATA_BANK.REGIONS r
on r.region_id=cn.region_id
where end_date <> '9999-12-31'
group by r.region_name, customer_id, node_id)

,cte2 as 
(select
region_name
, days_between
, ROW_NUMBER() OVER(PARTITION BY region_name ORDER BY days_between) as rn
from cte1)

, cte3 as 
(select
region_name
,max(rn) as max_row_num
from cte2
group by region_name)

select 
o.region_name
, case
    when rn = round(m.max_row_num/2,0) then 'Median'
    when rn = round(m.max_row_num*0.8,0) then '80th Percentile'
    when rn = round(m.max_row_num*0.95,0) then '95th Percentile'
end as metric
, days_between as value
from cte2 as o 
inner join cte3 as m 
on m.region_name=o.region_name
where rn in( 
            round(m.max_row_num/2,0), 
            round(m.max_row_num*0.8,0), 
            round(m.max_row_num*0.95,0));



;

with days as 
(select
region_name
,customer_id
,node_id
, sum(datediff(day,start_date,end_date)) as days_between
from customer_nodes as c
inner join regions as r on r.region_id=c.region_id
where end_date <> '9999-12-31'
group by region_name, customer_id, node_id)

select 
region_name
, round(avg(days_between)) as average
, median(days_between) as median_days
, percentile_cont(0.8) within group (order by days_between) as pc80
, percentile_cont(0.95) within group (order by days_between) as pc95
from days
group by region_name
;