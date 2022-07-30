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


-- Customer details who ordered more than thrice in Aug 2021
select o.customerID, c.FirstName, round(sum(o.Total_order_amount),2) Total_order_amount
from orders o
join customers c
on o.customerID = c.customerid
where monthname(orderdate) = 'August' and year(orderdate) = 2021
group by o.customerID, c.FirstName
having count(o.Total_order_amount) > 3;


-- Suppliers information with total number of orders shipped
select s.supplierID, s.companyName, concat(s.city,', ', s.state,', ', s.country,', ', s.PostalCode) SupplierLocation, s.email as SupplierEmail, o.Total_order_supplied
from suppliers s
join 
	(select distinct SupplierId, count(distinct OrderID) Total_order_supplied
	from orderdetails
	group by SupplierID) as O
on s.SupplierID = o.SupplierID
group by supplierID, companyName
order by s.SupplierID;


-- Customer details who ordered more than thrice and recieved their orders within seven days
select c.customerId, c.FirstName, c.LastName, count(o.Total_order_amount) Total_orders, round(sum(o.Total_order_amount),2) Total_spent
from customers c
join orders o
on c.CustomerID = o.CustomerID
where datediff(o.deliverydate , o.orderdate) <= 7
group by c.customerId, c.FirstName, c.LastName
having count(o.Total_order_amount) > 3
order by c.CustomerID;


-- Costomers with their top two favourite brands on the basis of quantity they ordered
select c.customerid, c.firstname, c.lastname, group_concat(t.brand, ',') favourite_brands
from customers c
join 
	(select o.orderid, o.customerid, od.productid, p.brand, dense_rank() over(partition by o.orderid order by od.quantity desc) fav_product
	from orders o
	join orderdetails od
	on o.orderid = od.orderid
	join products p
	on od.ProductID = p.ProductID) as t
on c.customerid = t.customerid
where t.fav_product in (1,2)
group by c.customerid, c.firstname, c.lastname;

-- Get the numbers of brands, products and sub-category in each category
select c.categoryid, c.Categoryname, count(distinct p.brand) Num_brands, count(distinct p.product) Num_products, count(distinct p.sub_category) Num_subcategory
from category c
join products p
on c.CategoryID = p.Category_ID
group by c.categoryid, c.Categoryname
order by c.categoryid;


-- Which mode of transaction has what value of transaction amount
select p.PaymentType, case
						when p.allowed = 'Yes' then 1
                        when p.allowed = 'No' then 0
                        end Allowed,
round(sum(o.total_order_amount),2) Total_Transaction_Value
from orders o
right join payments p
on o.paymentID =  p.paymentID
group by p.PaymentType
order by round(sum(o.total_order_amount),2) desc;


-- Which mode of transaction has what value of transaction amount in year 2020 and 2021
select p.PaymentType, case
						when p.allowed = 'Yes' then 1
                        when p.allowed = 'No' then 0
                        end Allowed,
round(sum(case when year(o.orderdate)=2020 then o.total_order_amount end),2) Total_Transaction_Value_2020,
round(sum(case when year(o.orderdate)=2021 then o.total_order_amount end),2) Total_Transaction_Value_2021
from orders o
right join payments p
on o.paymentID =  p.paymentID
group by p.PaymentType
order by round(sum(o.total_order_amount),2) desc;


-- Customers who orderd in both the years 2020 and 2021
select * from
			(select c.customerid, c.firstname, c.lastname,
			round(sum(case when year(o.orderdate)=2020 then o.total_order_amount end),2) Total_Transaction_Value_2020,
			round(sum(case when year(o.orderdate)=2021 then o.total_order_amount end),2) Total_Transaction_Value_2021
			from customers c
			join orders o
			on c.CustomerID = o.CustomerID
			group by c.customerid, c.firstname, c.lastname
			order by c.CustomerID) as tbl
where Total_Transaction_Value_2020 is not null and Total_Transaction_Value_2021 is not null;


-- Cities which generated revenue in both years 2020 and 2021
select * from 
			(select c.city, c.state, c.country,
			round(sum(case when year(o.orderdate)=2020 then o.total_order_amount end),2) Total_Transaction_Value_2020,
			round(sum(case when year(o.orderdate)=2021 then o.total_order_amount end),2) Total_Transaction_Value_2021
			from customers c
			join orders o
			on c.CustomerID = o.CustomerID
			group by c.city, c.state, c.country
			order by c.country) as tbl
where Total_Transaction_Value_2020 is not null and Total_Transaction_Value_2021 is not null;


-- Get Transaction amount on year and quarter
select year(o.orderdate) Year, quarter(o.orderdate) Quarter, round(sum(o.total_order_amount),2) Total_Transaction_Amount, sum(od.Quantity) Total_quantity_shipped
from orders o
join orderdetails od
on o.OrderID = od.OrderID
group by year(o.orderdate), quarter(o.orderdate)
order by year(o.orderdate), quarter(o.orderdate)


