-- MySql Assigment Questions

-- 1. SELECT clause with WHERE, AND, DISTINCT, Wild Card (LIKE)

-- a. Fetch the employee number, first name and last name of those employees who are working as Sales Rep reporting to employee with employeenumber 1102
select * from employees;
select employeeNumber, firstName, lastName from employees where jobTitle = "Sales Rep" and reportsTo = 1102;

-- b.	Show the unique productline values containing the word cars at the end from the products table.
select * from products;
select distinct productLine from products where productLine like "%Cars";

-- ___________________________________________________________________________________________________________________________________________________________

-- 2. CASE STATEMENTS for Segmentation

-- a. Using a CASE statement, segment customers into three categories based on their country
select * from customers;
select customerNumber, customerName, case 
when country = "USA" or country = "Canada" then "North America" 
when country = "UK" or country = "France" or country = "Germany" then "Europe"
else "Others"
end as "CustomerSegment" from customers;

-- ___________________________________________________________________________________________________________________________________________________________

-- 3. Group By with Aggregation functions and Having clause, Date and Time functions

-- a. Using the OrderDetails table, identify the top 10 products (by productCode) with the highest total order quantity across all orders.
select * from orderdetails;
select productCode, sum(quantityOrdered) as total_ordered from orderdetails group by productCode order by sum(quantityOrdered) desc limit 10;

-- b.	Company wants to analyse payment frequency by month. Extract the month name from the payment date to count the total number of payments for each month
-- and include only those months with a payment count exceeding 20. Sort the results by total number of payments in descending order.  
select * from payments limit 5;
select monthname(paymentDate) as payment_month, count(*) as num_payments from payments group by payment_month having num_payments > 20 order by num_payments desc;

-- ___________________________________________________________________________________________________________________________________________________________

-- 4. CONSTRAINTS: Primary, key, foreign key, Unique, check, not null, default

create database if not exists Customers_Orders;
use Customers_Orders;

-- a. Create a table named Customers to store customer information. Include the following columns.
create table Customers( customer_id int primary key auto_increment, first_name varchar(50) not null, last_name varchar(50) not null, email varchar(255) unique, phone_number varchar(20));
describe Customers;

-- b.	Create a table named Orders to store information about customer orders. Include the following columns:
create table Orders ( order_id int primary key auto_increment, customer_id int, order_date date, total_amount decimal(10, 2), 
constraint FK_CustomerOrder foreign key (customer_id) references Customers(customer_id),
constraint CHK_TotalAmountPositive check (total_amount > 0));
describe Orders;

-- ___________________________________________________________________________________________________________________________________________________________

-- 5. Joins

-- a. List the top 5 countries (by order count) that Classic Models ships to.
use classicmodels;
select c.country, count(o.orderNumber) as order_count from customers c join orders o on c.customerNumber = o.customerNumber group by c.country order by order_count desc limit 5;

-- ___________________________________________________________________________________________________________________________________________________________

-- 6. Self Joins

-- a. Create a table project with below fields.
create table project( EmployeeID int primary key auto_increment, FullName varchar(50) not null, Gender varchar(10) check (Gender in ('Male', 'Female')), ManagerID int);
describe project;

insert into project (FullName, Gender, ManagerID) values 
('Pranaya', 'Male', 3), 
('Priyanka', 'Female', 1), 
('Preety', 'Female', null), 
('Anurag', 'Male', 1), 
('Sambit', 'Male', 1), 
('Rajesh', 'Male', 3), 
('Hina', 'Female', 3);
select * from project;

select m.FullName as ManagerName, e.FullName as EmpName from project e left join project m on e.ManagerID = m.EmployeeID where m.FullName is not null order by ManagerName;

-- ___________________________________________________________________________________________________________________________________________________________

-- 7. DDL Commands: Create, Alter, Rename

-- a.  Create table facility. Add the below fields into it.
create table facility ( Facility_ID int, Name varchar(255), State varchar(100), Country varchar(100));
describe facility;

-- i) Alter the table by adding the primary key and auto increment to Facility_ID column.
alter table facility modify column Facility_ID int not null auto_increment primary key;

-- ii) Add a new column city after name with data type as varchar which should not accept any null values.
alter table facility add column city varchar(100) not null after Name;
describe facility;

-- ___________________________________________________________________________________________________________________________________________________________

-- 8. Views in SQL

-- a. Create a view named product_category_sales that provides insights into sales performance by product category. This view should include the following information:
create view product_category_sales as select pl.productLine, sum(od.quantityOrdered * od.priceEach) as total_sales, count(distinct o.orderNumber) as number_of_orders from ProductLines pl 
join Products p on pl.productLine = p.productLine
join OrderDetails od on p.productCode = od.productCode
join orders o on od.orderNumber = o.orderNumber group by pl.productLine;

select * from product_category_sales order by productLine;

-- ___________________________________________________________________________________________________________________________________________________________

-- 9. Stored Procedures in SQL with parameters

-- a. Create a stored procedure Get_country_payments which takes in year and country as inputs and gives year wise, country wise total amount as an output. Format the total amount to nearest thousand unit (K)
DELIMITER //
create procedure get_country_payments ( in input_year int, in input_country varchar(50))
begin
select year(p.paymentDate) as PaymentYear, c.country as Country, concat(format(sum(p.amount) / 1000, 0), 'K') as TotalAmount from Payments p
join Customers c on p.customerNumber = c.customerNumber where year(p.paymentDate) = input_year and c.country = input_country group by PaymentYear, Country;
end //
DELIMITER ;

call get_country_payments(2003, 'France');

-- ___________________________________________________________________________________________________________________________________________________________

-- 10. Window functions - Rank, dense_rank, lead and lag

-- a. Using customers and orders tables, rank the customers based on their order frequency
select c.customername, count(o.orderNumber) as Order_count, dense_rank() over (order by count(o.orderNumber) desc) as order_frequency_rnk from customers c
join orders o on c.customerNumber = o.customerNumber group by c.customerNumber, c.customerName order by order_frequency_rnk;

-- b. Calculate year wise, month name wise count of orders and year over year (YoY) percentage change. Format the YoY values in no decimals and show in % sign.
with monthlyorders as (select year(orderdate) as year, month(orderdate) as monthnumber, count(ordernumber) as totalorders from orders group by year, monthnumber), 
laggedorders as (select mo.year, mo.monthnumber, monthname(makedate(mo.year, 1) + interval mo.monthnumber - 1 month) as month, mo.totalorders,
lag(mo.totalorders, 1, 0) over (order by mo.year, mo.monthnumber) as previousmonthorders from monthlyorders mo)
select year, month, totalorders, 
case
when previousmonthorders = 0 then null
else concat(format(((totalorders - previousmonthorders) * 100.0 / previousmonthorders), 0), '%') 
end as "%momchange" from laggedorders order by year, monthnumber;

-- ___________________________________________________________________________________________________________________________________________________________

-- 11. Subqueries and their applications

-- a. Find out how many product lines are there for which the buy price value is greater than the average of buy price value. Show the output as product line and its count.
select productLine, count(*) as Total from products where buyPrice > (select avg(buyPrice) from products) group by productLine order by Total desc;

-- ___________________________________________________________________________________________________________________________________________________________

-- 12. ERROR HANDLING in SQL

-- Create the table Emp_EH
create table Emp_EH ( EmpID int primary key, EmpName varchar(100), EmailAddress varchar(100));

-- Create a procedure to accept the values for the columns in Emp_EH. Handle the error using exception handling concept. Show the message as “Error occurred” in case of anything wrong.
DELIMITER //
create procedure InsertEmp_EH( in p_EmpID int, in p_EmpName varchar(100), p_EmailAddress varchar(100))
begin declare exit handler for sqlexception
begin select 'Error Occurred' as ErrorMessage;
end;
insert into Emp_EH( EmpID, EmpName, EmailAddress) values (p_EmpID, p_EmpName, p_EmailAddress);
select 'Employee added Successfully.' as StatusMessage; 
end //
DELIMITER ;

-- Testing addition
call insertEmp_EH(1, 'Phillip', 'phillip.g@gmail.com');
select * from Emp_EH;

-- Testing Duplicate data
call InsertEmp_EH(1, 'Carl', 'carl.gh@gmail.com');

-- ___________________________________________________________________________________________________________________________________________________________

-- 13. TRIGGERS.

-- Create the table Emp_BIT.
create table Emp_BIT( Name varchar(100), Occupation varchar(100), Working_date Date, Working_hours int);

-- Create before insert trigger to make sure any new value of Working_hours, if it is negative, then it should be inserted as positive.
DELIMITER //

create trigger trg_Before_Emp_BIT_Insert before insert on Emp_BIT for each row
begin if new.Working_hours < 0 then set new.Working_hours = abs(new.Working_hours);
end if;
end //

DELIMITER ;

-- Insert the data as shown in below query.
insert into Emp_BIT ( Name, Occupation, Working_date, Working_hours) values 
('Robin', 'Scientist', '2020-10-04', 12),  
('Warner', 'Engineer', '2020-10-04', 10),  
('Peter', 'Actor', '2020-10-04', 13),  
('Marco', 'Doctor', '2020-10-04', 14),  
('Brayden', 'Teacher', '2020-10-04', 12),  
('Antonio', 'Business', '2020-10-04', 11);

-- Verify initial data
select * from Emp_BIT;

-- Test the trigger: Insert a row with negative working hours
insert into Emp_BIT ( Name, Occupation, Working_date, Working_hours) values ('TestingNegative', 'Tester', '2023-01-01', -5);

-- Verify the data for the new tester (Working_hours should be positive)
select * from Emp_BIT where Name = 'TestingNegative';

-- Test the trigger: Insert a row with positive working hours (should remain positive)
insert into Emp_BIT ( Name, Occupation, Working_date, Working_hours) values ('TestingPositive', 'Tester P', '2023-01-02', 5);

-- Verify the data for the new tester
select * from Emp_BIT where Name = "TestingPositive";

-- ___________________________________________________________________________________________________________________________________________________________