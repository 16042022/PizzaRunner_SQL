/*
D. Pricing and Ratings
    If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes - how much money has Pizza Runner made so far if there are no delivery fees?
    What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
    The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
    how would you design an additional table for this new dataset 
    - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
    Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
        customer_id
        order_id
        runner_id
        rating
        order_time
        pickup_time
        Time between order and pickup
        Delivery duration
        Average speed
        Total number of pizzas
    If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
    - how much money does Pizza Runner have left over after these deliveries?

E. Bonus Questions

If Danny wants to expand his range of pizzas - 
how would this impact the existing data design? 
Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
*/
use pizza_runner;
-- If a Meat Lovers pizza costs $12 and Vegetarian costs $10 and there were no charges for changes 
-- how much money has Pizza Runner made so far if there are no delivery fees?
select 
	pizza_id
    , sum(pizza_price) as total_rev
from (
select 
	pizza_id, 
	CASE
    When pizza_id = 1 THEN 12
    ELSE 10
    END AS pizza_price
from success_order so
natural join split_topping) x1
group by pizza_id;

-- What if there was an additional $1 charge for any pizza extras? Add cheese is $1 extra
with charge_fee as
(select 
	*
    , CASE
    WHEN extras = 4 THEN 1
    ELSE 0 
    END AS charge_fee
    , CASE
    When pizza_id = 1 THEN 12
    ELSE 10
    END AS pizza_price
from split_topping
natural join success_order)

select 
	pizza_id
    , sum(charge_fee + pizza_price) as total_price
from charge_fee
group by pizza_id;

/*
The Pizza Runner team now wants to add an additional ratings system that allows customers to rate their runner, 
    how would you design an additional table for this new dataset 
    - generate a schema for this new table and insert your own data for ratings for each successful customer order between 1 to 5.
*/
drop table if exists rating_runner;
create table rating_runner
(
	customer_id INT NOT NULL,
    order_id INT NOT NULL,
    runner_id INT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 and rating <= 5),
    rating_date DATETIME
);

INSERT INTO rating_runner 
VALUES (104, 10, 1, 5, now());

/*select   
customer_id     
, order_id     
, runner_id     
, MAX(rate_point) as rating 
from ( 
select   
	customer_id     
    , order_id     
    , runner_id     
    , cancellation     
    , CASE     
    WHEN cancellation IS NOT NULL THEN 1     
    ELSE 5     
    END AS rate_point 
    from customer_orders natural join runner_orders) x1 
GROUP BY order_id, customer_id, runner_id 
ORDER BY customer_id, order_id*/

/*
Using your newly generated table - can you join all of the information together to form a table which has the following information for successful deliveries?
        customer_id
        order_id
        runner_id
        rating
        order_time
        pickup_time
        Time between order and pickup
        Delivery duration
        Average speed
        Total number of pizzas
*/
/*CREATE VIEW success_order_info as (
select 
	customer_id
    , order_id
    , runner_id
    , rating
    , order_time
    , pickup_time
    , SUM(timestampdiff(minute, order_time, pickup_time)) as time_diff
    , duration as del_duration
    , round(avg(distance/(duration/60)), 2) as avg_speed
    , count(pizza_id) as total_pizza
from customer_orders co
natural join success_order so
natural join rating_runner rat_run
group by co.customer_id, co.order_id, so.runner_id, rating, order_time, pickup_time, duration, distance)*/

/*If a Meat Lovers pizza was $12 and Vegetarian $10 fixed prices with no cost for extras and each runner is paid $0.30 per kilometre traveled 
    - how much money does Pizza Runner have left over after these deliveries?*/
with out_fee as (
select sum(deliver_fee) as outfee
from (
select 
	*
    , distance * 0.3 as deliver_fee
from success_order) x1),

income as (
	select sum(pizza_fee) as infee
    from (
    select 
		*,
        CASE 
        WHEN pizza_id = 1 THEN 12
        ELSE 10
        END AS pizza_fee
    from customer_orders
    natural join success_order) x2
)

select 
	infee - (select * from out_fee) as rev
from income;

/*
Write an INSERT statement to demonstrate what would happen if a new Supreme pizza with all the toppings was added to the Pizza Runner menu?
*/

INSERT INTO pizza_runner.pizza_names
VALUES (3, 'Supreme');

INSERT INTO pizza_runner.pizza_recipes
SELECT *
FROM (
select 
	'3' as pizza_id
    , group_concat(topping_id separator ', ') as ingredient
from pizza_runner.pizza_toppings
group by pizza_id) X1