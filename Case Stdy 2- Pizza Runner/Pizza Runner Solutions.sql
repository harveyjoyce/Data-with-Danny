

-- How many pizzas were ordered?
select 
count(pizza_id)
from customer_orders;


-- How many unique customer orders were made?
select 
count(distinct customer_id)
from customer_orders;


-- How many successful orders were delivered by each runner?
select
runner_id
,count(distinct order_id)
from runner_orders
where duration != 'null' 
group by runner_id
;

select *
from runner_orders
where duration != 'null';

-- How many of each type of pizza was delivered?
select 
pn.pizza_name
,count(order_id)
from customer_orders co
inner join pizza_names pn
on co.pizza_id=pn.pizza_id
group by pn.pizza_name;


select 
pizza_id
,count(co.order_id)
from customer_orders co
inner join runner_orders ro
on co.order_id=ro.order_id
where duration != 'null'
group by pizza_id;

-- How many Vegetarian and Meatlovers were ordered by each customer?
select
co.customer_id
,pn.pizza_name
,count(order_id)
from customer_orders co
inner join pizza_names pn
on co.pizza_id=pn.pizza_id
group by pn.pizza_name, co.customer_id
order by customer_id;

-- What was the maximum number of pizzas delivered in a single order?
select 
order_id
,count(pn.pizza_name) as number_of_pizzas
from customer_orders co
inner join pizza_names pn
on co.pizza_id=pn.pizza_id
group by co.order_id
order by count(pn.pizza_name) desc; 

-- For each customer, how many delivered pizzas had at least 1 change and how many had no changes?

select 
customer_id
, count(co.order_id)
from customer_orders co
inner join runner_orders ro
on co.order_id=ro.order_id
where duration != 'null'
and extras is not null
and extras <> 'null'
and extras <> ''
group by customer_id;

-- How many pizzas were delivered that had both exclusions and extras?

select 
count(pizza_id) as both
from customer_orders co
inner join runner_orders ro
on co.order_id=ro.order_id
where duration != 'null'
and extras is not null
and extras <> 'null'
and extras <> ''
and exclusions <> 'null';

-- What was the total volume of pizzas ordered for each hour of the day?
select
count(*)
,date_part(hour, order_time) as hour
from customer_orders
group by hour;

-- What was the volume of orders for each day of the week?
select
count(*)
,date_part(weekday, order_time) as weekday
from customer_orders
group by weekday