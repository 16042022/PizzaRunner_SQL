/*
B. Runner and Customer Experience

    How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)
    What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
    Is there any relationship between the number of pizzas and how long the order takes to prepare?
    What was the average distance travelled for each customer?
    What was the difference between the longest and shortest delivery times for all orders?
    What was the average speed for each runner for each delivery and do you notice any trend for these values?
    What is the successful delivery percentage for each runner?

*/

use pizza_runner;

/*CREATE VIEW _split_recipes AS (
with recursive number_ as 
(
	select 1 as n
    UNION ALL
    select n+1
    from number_
    where n < 9
)

SELECT 
		pizza_id, 
       SUBSTRING_INDEX(SUBSTRING_INDEX(toppings, ', ', nb_.n), ', ', -1) AS SplitData
FROM pizza_recipes
JOIN number_ nb_ ON LENGTH(toppings) - LENGTH(REPLACE(toppings, ',', '')) >= nb_.n - 1
ORDER BY pizza_id)*/

-- How many runners signed up for each 1 week period? (i.e. week starts 2021-01-01)--
SELECT 
	date_add('2021-01-01', INTERVAL FLOOR(DATEDIFF(registration_date, '2021-01-01')/7)*7 DAY) week_start
    , count(runner_id) as total_registered
FROM runners
group by week_start
order by week_start;

-- Is there any relationship between the number of pizzas and how long the order takes to prepare?
select 
	co.order_id
    , count(co.pizza_id) as total_order
    , sum(timestampdiff(MINUTE, co.order_time ,ro.pickup_time)) as total_diff_time
from customer_orders co 
join success_order ro using (order_id)
group by order_id;

-- What was the average time in minutes it took for each runner to arrive at the Pizza Runner HQ to pickup the order?
select 
	so.runner_id
    , avg(timestampdiff(MINUTE, co.order_time ,so.pickup_time)) as avg_pickup_time
from customer_orders co
join success_order so using(order_id)
group by runner_id;
 -- What was the average distance travelled for each customer?
 select 
	customer_id
    , round(avg(distance), 2) as aver_dist
 from success_order so
 join customer_orders co using(order_id)
 group by customer_id;
 
-- What was the difference between the longest and shortest delivery times for all orders?
select 
	MAX(duration) - MIN(duration) as diff_time
from success_order;

-- What was the average speed for each runner for each delivery and do you notice any trend for these values?
select 
	runner_id
    , order_id
    , round(avg(distance/(duration/60)), 2) as avg_speed
from success_order
group by runner_id, order_id
order by runner_id;

-- What is the successful delivery percentage for each runner?
with missing_order as (
select 
	x1.runner_id
    , count(*) as missing_order
from (
(select * from runner_orders)
EXCEPT
(select * from success_order)) x1
group by x1.runner_id),

full_order as (
	select 
		runner_id
        , count(1) as total_order
    from runner_orders
    group by runner_id
)

select 
	m.runner_id
    , (1 - (missing_order/total_order))*100 as succesful_percent
from missing_order m, full_order f
where m.runner_id = f.runner_id
UNION
select 
	f.runner_id
    , 100 as succesful_percent
from full_order f
where not exists (
	select *
    from missing_order m
    where m.runner_id = f.runner_id
)
order by runner_id;

/*
	C. Ingredient Optimisation
    What are the standard ingredients for each pizza?
    What was the most commonly added extra?
    What was the most common exclusion?
    Generate an order item for each record in the customers_orders table in the format of one of the following:
        Meat Lovers
        Meat Lovers - Exclude Beef
        Meat Lovers - Extra Bacon
        Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
    Generate an alphabetically ordered comma separated ingredient list for each pizza order from the customer_orders table and add a 2x in front of any relevant ingredients
        For example: "Meat Lovers: 2xBacon, Beef, ... , Salami"
    What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
*/
select 
	x1.pizza_id
    , group_concat(topping_name order by topping_name asc separator ', ') as standard_indigre
from (
select 
	pizza_id
    , topping_name
from _split_recipes _s
join pizza_toppings pt on _s.SplitData = pt.topping_id) x1
group by x1.pizza_id;

-- What was the most commonly added extra?
/*CREATE VIEW split_topping AS (
with recursive number_ as 
(
	select 1 as n
    UNION ALL
    select n+1
    from number_
    where n < 3
),

mod_1 as (
select 
	order_id
    , customer_id
    , pizza_id
    , CASE
    WHEN exclusions < 0 THEN NULL
    ELSE exclusions
    END AS exclusions
    , CASE
    WHEN extras < 0 THEN NULL
    ELSE extras
    END AS extras
    , order_time
from (
select 
	order_id
    , customer_id
    , pizza_id
    , SUBSTRING_INDEX(SUBSTRING_INDEX(exclusions, ', ', nb_.n), ', ', -1) AS exclusions
    , SUBSTRING_INDEX(SUBSTRING_INDEX(extras, ', ', nb_.n), ', ', -1) AS extras
    , order_time
from 
(
select 
	order_id
    , customer_id
    , pizza_id
    , CASE
    WHEN length(exclusions) < length(extras) THEN concat_ws(', ', exclusions, -1)
    ELSE exclusions
    END AS exclusions
    , CASE
    WHEN length(exclusions) > length(extras) THEN concat_ws(', ', extras, -1)
    ELSE extras
    END AS extras
    , order_time
from (
SELECT * 
FROM pizza_runner.customer_orders
where exclusions IS NOT NULL and extras IS NOT NULL) x1) x2
JOIN number_ nb_ on LENGTH(extras) - LENGTH(REPLACE(extras, ',', '')) >= nb_.n - 1) x3)

select *
from mod_1 sv 
UNION ALL
select *
from customer_orders co
where not exists 
(
	select *
    from mod_1 sv1
    where sv1.order_id = co.order_id
)
order by order_id);*/

select 
	extras
    , count(extras) as freq
from split_topping
where extras IS NOT NULL
group by extras
order by freq DESC
limit 1;

/*
Generate an order item for each record in the customers_orders table in the format of one of the following:
        Meat Lovers
        Meat Lovers - Exclude Beef
        Meat Lovers - Extra Bacon
        Meat Lovers - Exclude Cheese, Bacon - Extra Mushroom, Peppers
*/
with exclusions as (
select
	x2.order_id
    , x2.pizza_name
    , ' - Exclude' as holder_
	, group_concat(topping_name separator ', ') as decribe_
from (
select *
from split_topping sp
left join pizza_toppings ptp on sp.exclusions = ptp.topping_id
natural join pizza_names p_) x2
group by x2.order_id, x2.pizza_name),

extras_ as (select
	x2.order_id
    , x2.pizza_name
    , ' - Extras' as holder_
	, group_concat(topping_name separator ', ') as decribe_
from (
select *
from split_topping sp
left join pizza_toppings ptp on sp.extras = ptp.topping_id
natural join pizza_names p_) x2
group by x2.order_id, x2.pizza_name)

select 
	CASE
    WHEN ext.decribe_ IS NULL && ex.decribe_ IS NULL THEN ex.pizza_name
	WHEN ex.decribe_ IS NOT NULL
		&& ext.decribe_ IS NOT NULL THEN concat(ex.pizza_name, ex.holder_,' ',ex.decribe_,ext.holder_,' ',ext.decribe_)
    WHEN ext.holder_ = ' - Extras' && ext.decribe_ IS NOT NULL THEN concat(ext.pizza_name, ext.holder_, ' ', ext.decribe_)
    WHEN ex.holder_ = ' - Exclude' && ex.decribe_ IS NOT NULL THEN concat(ex.pizza_name, ex.holder_, ' ', ex.decribe_)
    END AS description_
from exclusions ex
join extras_ ext 
on ex.order_id = ext.order_id
and ex.pizza_name = ext.pizza_name;

/*
What is the total quantity of each ingredient used in all delivered pizzas sorted by most frequent first?
*/

with count_extras as 
(
	select 
		co.extras as topping_id
        , count(co.extras) as q_
    from success_order so
    natural join split_topping co
    where co.extras IS NOT NULL
    group by co.extras
),

count_exclude as
(
	select 
		co.exclusions as topping_id
        , count(co.exclusions) as q_
    from success_order so
    natural join split_topping co
    where co.exclusions IS NOT NULL
    group by co.exclusions
),

orin_quantlty as 
(
	select 
		SplitData as topping_id
        , count(SplitData) as q_
    from _split_recipes
    group by SplitData
)

select 
	xA1.topping_id
    , sum(xA1.q_) as total
from (
select *
from count_extras c1
UNION ALL
select *
from count_exclude c2
UNION ALL
select *
from orin_quantlty c3) xA1
group by xA1.topping_id
order by total DESC;
