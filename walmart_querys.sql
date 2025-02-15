-- overview of the dataset

SELECT * from walmart;

--counting the number of rows in the dataset

select count(*) from walmart;

-- selecting distinct payments methods 

select distinct payment_method from walmart;

--counting the number of entries for each distinct payment method

select
	payment_method,
	count(*)
	
from walmart
group by payment_method;

--counting the number of distinct branches 

select 
	count(distinct Branch)
from walmart;

--selecting the greatest value in the quantity column

select max(quantity) from walmart;

-- Bussiness problems:

--1. What are the different payment methods, and how many transactions and items were sold with each method?


select
	payment_method,
	count(*) as no_payments,
	sum(quantity) as no_qtd_sold
	
from walmart
group by payment_method;

--2. Which category received the highest average rating in each branch?

select *
from
(
	select
		branch,
		category,
		avg(rating) as avg_rating,
		rank() over(partition by branch order by avg(rating) desc) as rank
	from walmart
	group by 1,2
)

where rank = 1;

--3.What is the busiest day of the week for each branch based on transaction volume?

select 
	date,
	to_char(to_date(date, 'dd/mm/yy'), 'day') as day_name
from walmart;


select *
from
(
	select 
		branch,
		to_char(to_date(date, 'DD/MM/YY'), 'Day') as day_name,
		count(*) as no_transactions,
		rank() over(partition by branch order by count(*) desc) as rank
	from walmart
	group by 1,2
)
where rank=1
;

--4.How many items were sold through each payment method?

select
	payment_method,
	sum(quantity) as no_qtd_sold
	
from walmart
group by payment_method;

--5. What are the average, minimum, and maximum ratings for each category in each city?

select
	city,
	category,
	min(rating) as min_rating,
	max(rating) as max_rating,
	avg(rating) as avg_rating
from walmart
group by 1,2;

--6. What is the total profit for each category, ranked from highest to lowest?

select
	category,
	sum(total) as total_ravenue,
	sum(total * profit_margin) as profit
from walmart
group by 1;
	
--7. What is the most frequently used payment method in each branch?

with cte
as
(
select
	branch,
	payment_method,
	count(*) as total_trans,
	rank() over(partition by branch order by count(*)desc) as rank
from walmart
group by 1,2
)
select *
from cte
where rank = 1;

--8. How many transactions occur in each shift (Morning, Afternoon, Evening) across branches?

select 
	branch,
case
	when extract(hour from(time::time)) < 12 then 'Morning'
	when extract(hour from(time::time)) between 12 and 17 then 'Afternoon'
	else 'Evening'
	end day_time,
	count(*)
from walmart
group by 1,2
order by 1,3 desc;

--9 Which branches experienced the largest decrease in revenue compared to the previous year?

--formula: rdr == last_rev-cr_rev/ls_rev*100


select *,
extract(year from to_date(date, 'DD/MM/YY')) as formated_date
from walmart

--2022 sales
with revenue_2022
as
(
	select
		branch,
		sum(total) as revenue
	from walmart
	where extract(year from to_date(date, 'DD/MM/YY')) = 2022
	group by 1	
),


revenue_2023
as
(
	select
		branch,
		sum(total) as revenue
	from walmart
	where extract(year from to_date(date, 'DD/MM/YY')) = 2023
	group by 1	
)

select 
	ls.branch,
	ls.revenue as last_year_revenue,
	cs.revenue as current_year_revenue,
	round(
		(ls.revenue - cs.revenue)::numeric/
		ls.revenue::numeric * 100,
		2) as revenue_dec_ratio
from revenue_2022 as ls
join
revenue_2023 as cs
on ls.branch = cs.branch
where 
	ls.revenue > cs.revenue
order by 4 desc
limit 5
;
---------------------------