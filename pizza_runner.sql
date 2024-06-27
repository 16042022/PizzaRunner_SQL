/* --------------------
   Case Study Questions
   --------------------*/
   
/*A. Pizza Metrics
    How many pizzas were ordered?
    How many unique customer orders were made?
    How many successful orders were delivered by each runner?
    How many of each type of pizza was delivered?
    How many Vegetarian and Meatlovers were ordered by each customer?
    What was the maximum number of pizzas delivered in a single order?
    For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
    How many pizzas were delivered that had both exclusions and extras?
    What was the total volume of pizzas ordered for each hour of the day?
    What was the volume of orders for each day of the week?*/
USE pizza_runner;
-- Clean data in table --
UPDATE runner_orders
SET duration = replace(duration, substr(duration, 3), '')
WHERE duration is not null;


-- 2. How many unique customer orders were made?
select 
	count(order_id)
from (
select order_id
from customer_orders
group by order_id) x1;

-- 3.How many of each type of pizza was delivered?
with succes_order as
(
	select *
    from runner_orders
    where cancellation is null
)

select 
	pizza_id
    , count(pizza_id)
from succes_order so
join customer_orders co using (order_id)
group by co.pizza_id;

-- 4. What was the maximum number of pizzas delivered in a single order?
/*CREATE VIEW success_order AS 
(
	select *
    from runner_orders
    where cancellation is null
);*/

select MAX(x1.orders)
from 
(
	select count(pizza_id) as orders
    from customer_orders
    group by order_id
) x1;

-- 5.For each customer, how many delivered pizzas had at least 1 change and how many had no changes?
select 
	customer_id
    , sum(no_change) as no_change_item
    , sum(is_change) as changed_item
from (
select 
	*,
    CASE
    WHEN extras IS NULL && exclusions IS NULL THEN 0
    ELSE 1
    END AS is_change
    , CASE
    WHEN extras IS NOT NULL || exclusions IS NOT NULL || 
    (extras IS NOT NULL && exclusions IS NOT NULL) THEN 0
    ELSE 1
    END AS no_change
from customer_orders
join success_order using (order_id)) x1
group by x1.customer_id;

-- 6. What was the total volume of pizzas ordered for each hour of the day?
select 
	time_format(order_time, '%H') as hours
    , count(pizza_id) as total_order
from customer_orders
group by time_format(order_time, '%H')
order by hours;

-- 7.What was the volume of orders for each day of the week?
select 
	date(order_time) as dates
    , weekday(date(order_time)) as dayWeek
    , count(pizza_id) as order_amount
from customer_orders
group by date(order_time), weekday(date(order_time))
order by date(order_time);

