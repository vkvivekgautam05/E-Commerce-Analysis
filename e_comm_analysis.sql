use practice;

-- Count of customers whose day of birth is even and month of birth is odd
select city, state, country, count(*) count_of_customers
from customers
where day(Date_of_Birth)%2=0 and year(Date_of_Birth)%2!=0
group by city, state, country
order by country;


-- Number of customers whose number of orders are greater than 10
select c.Firstname, c.LastName, count(*) no_of_orders, round(sum(o.Total_order_amount),2) Total_spent
from customers c
join orders o
on c.CustomerID = o.CustomerID
group by c.Firstname, c.LastName
having count(*) > 10
order by count(*) desc, round(sum(o.Total_order_amount),2) desc;


/*
Number of customers whose number of orders are greater than 10 and last_name has 'm' in it and
Number of customers whose number of orders are equal to 5 only.
*/
select FirstName, LastName, No_of_Orders, Total_spent
from
	(select c.Firstname, c.LastName, count(*) no_of_orders, round(sum(o.Total_order_amount),2) Total_spent
	from customers c
	join orders o
	on c.CustomerID = o.CustomerID
	where c.LastName like '%m%'
	group by c.Firstname, c.LastName
	having count(*) > 10
	union
	select c.Firstname, c.LastName, count(*) no_of_orders, round(sum(o.Total_order_amount),2) Total_spent
	from customers c
	join orders o
	on c.CustomerID = o.CustomerID
	group by c.Firstname, c.LastName
	having count(*) = 5) as A
order by no_of_orders desc, Total_spent;


-- The name of product which is 3rd popular in customers shopping lists.
select FirstName, LastName, Product
from 
	(select c.FirstName, c.LastName, p.Product, count(p.Product) over(partition by c.FirstName, c.LastName) as rnk
	from customers c
	left join orders o1
	on c.CustomerID = o1.CustomerID
	left join orderdetails o2
	on o1.orderid = o2.orderid
	left join products p
	on o2.productid = p.productid) as A
where rnk = 3;


-- Rank the records from orderdetail on the basis of descending order quantity where orderdate is Tuesday and Shipdate is Wednesday.
select *, dense_rank() over(order by Quantity desc) as Ranking
from
	(select o1.orderdetailid, o1.orderid, o1.productId, o1.quantity, o1.supplierid
	from orderdetails o1
	join orders o2
	on o1.OrderID = o2.OrderID
    where dayname(o2.orderdate) like 'Tuesday' and
    dayname(o2.shipdate) like 'Wednesday') as A
order by orderid desc, ranking;


-- Quarter wise ranking in terms of revenue generated in each category in each year
select c.categoryID, c.CategoryName, year(o2.OrderDate) Year, QUARTER(o2.OrderDate) Qtr,
dense_rank() over(partition by QUARTER(o2.OrderDate), c.categoryID, QUARTER(o2.OrderDate) order by o2.Total_order_amount) rnk
from category c
join products p
on c.categoryID = p.Category_ID
join orderdetails o1
on o1.productID = p.productID
join orders o2
on o2.orderID = o1.OrderID
order by year(o2.OrderDate) desc, QUARTER(o2.OrderDate) desc;


-- Top 10 customers who spent the most
select c.CustomerID, c.Firstname, c.LastName, round(sum(o.Total_order_amount),2) TotalOrderAmount
from customers c
join orders o
on c.CustomerID = o.CustomerID
group by c.CustomerID, c.Firstname, c.LastName
order by c.Firstname, c.LastName
limit 10;


-- Segment the customers into 'Young' and 'Old' categories. Tag the customer 'Old' whose age is greater than 45.
select CustomerID, FirstName, LastName, Date_of_Birth, round(datediff(curdate(), Date_of_birth)/365,0) Age, case
when round(datediff(curdate(), Date_of_birth)/365,0) > 45 then 'Old'
when round(datediff(curdate(), Date_of_birth)/365,0) <= 45 then 'Young'
end as Tag
from customers;


-- Count the 'Young' and 'Old' customers.
select tag, count(tag) count
from
	(select CustomerID, FirstName, LastName, Date_of_Birth, round(datediff(curdate(), Date_of_birth)/365,0) Age, case
	when round(datediff(curdate(), Date_of_birth)/365,0) > 45 then 'Old'
	when round(datediff(curdate(), Date_of_birth)/365,0) <= 45 then 'Young'
	end as Tag
	from customers) as A
group by tag;


-- Count of brands in each sale category
select c.CategoryID, c.CategoryName, count(p.brand)
from category c
join products p
on c.CategoryID = p.Category_ID
group by c.CategoryID, c.CategoryName;