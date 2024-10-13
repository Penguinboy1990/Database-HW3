use hw3; -- the database

-- primary and foreign key constraints
alter table merchants add primary key (mid);
alter table products add primary key (pid);
alter table sell add foreign key (mid) references merchants(mid),
	add foreign key (pid) references products(pid);
alter table orders add primary key (oid);
alter table contain add foreign key (oid) references orders(oid),
	add foreign key (pid) references products(pid);
alter table customers add primary key (cid);
alter table place add foreign key (cid) references customers(cid),
	add foreign key (oid) references orders(oid);

-- constraints from "General Guidelines" section
ALTER TABLE products ADD CONSTRAINT chk_name CHECK (name in ('Printer', 'Ethernet Adapter', 'Desktop', 'Hard Drive', 'Laptop', 'Router', 'Network Card', 'Super Drive', 'Monitor'));
ALTER TABLE products ADD CONSTRAINT CHECK (category in ('Peripheral', 'Networking', 'Computer'));
alter table sell add check (0 <= price <= 100000);
alter table sell add check (0 <= quantity_available <= 1000);
ALTER TABLE orders ADD CONSTRAINT CHECK (shipping_method in ('UPS', 'FedEx', 'USPS'));
alter table orders add check (0 <= shipping_cost <= 500);
alter table place add constraint order_date check (order_date < GetDate());


-- Queries HomeWork 3
-- 1) List names and sellers of products that are no longer available (quantity=0)
select distinct merchants.name, products.name, quantity_available
from merchants inner join sell inner join products
on sell.pid = products.pid
where quantity_available = 0;

-- 2) List names and descriptions of products that are not sold.
select distinct quantity_available as qty, products.name, description
from sell inner join products
where quantity_available = 0;

-- 3) How many customers bought SATA drives but not any routers?
select distinct customers.fullname, products.name, contain.oid
from customers inner join place inner join orders inner join contain inner join products
on customers.cid = place.cid and place.oid = orders.oid and orders.oid = contain.oid and contain.pid = products.pid
where products.name = 'Super Drive'
except
select distinct customers.fullname, products.name, contain.oid
from customers inner join place inner join orders inner join contain inner join products
on customers.cid = place.cid and place.oid = orders.oid and orders.oid = contain.oid and contain.pid = products.pid
where products.name = 'Router';

-- sub attempt
/*select oid, contain.pid, products.name
from contain inner join products
on contain.pid = products.pid
where products.name = 'Super Drive'
order by oid asc;
except
select oid
from contain inner join products
on contain.pid = products.pid
where products.name = 'router'
order by oid asc;

-- SATA drive pids 4, 7, 11, 21, 22, 30, 31, 32
-- router oids 8, 18, 19, 20, 23*/

-- 4) HP has a 20% sale on all its Networking products.
select merchants.name, products.name, products.category, sell.price * .8
from merchants inner join sell inner join products
on merchants.mid = sell.mid and sell.pid = products.pid
where category = 'networking' and merchants.name = 'HP';

-- 5) What did Uriel Whitney order from Acer? (make sure to at least retrieve product names and prices).
select distinct products.name, sell.price, merchants.name, fullname
from customers inner join place inner join contain inner join products inner join sell inner join merchants
on customers.cid = place.cid and place.oid = contain.oid and contain.pid = products.pid and products.pid = sell.pid and sell.mid = merchants.mid
where fullname = 'Uriel Whitney' and merchants.name = 'Acer';

-- 6) List the annual total sales for each company (sort the results along the company and the year attributes).
select distinct merchants.name, avg(price)/9.986301 as 'avg price per year', max(order_date), min(order_date)
from merchants inner join sell inner join contain inner join orders inner join place
on merchants.mid = sell.mid and sell.pid = contain.pid and contain.oid = place.oid
group by merchants.name
order by avg(price) desc;
-- generally, the higher quantity_available is a higher price because more items were bought
-- with price variation coming from the markup of each company as below
-- so all we need is the price and no shipping cost, which is extra and paid by customers
/*select max(order_date)
from place;-- 12/24/2020
select min(order_date)
from place;-- 1/2/2011
SELECT datediff(max(order_date), min(order_date)) as datediff
from place;*/
-- actual difference between 12/24/2020 and 1/2/2011 is 9.986301 years

-- 7) Which company had the highest annual revenue and in what year?
select distinct merchants.name, avg(price) as 'avg price per year', year(order_date)
from merchants inner join sell inner join contain inner join orders inner join place
on merchants.mid = sell.mid and sell.pid = contain.pid and contain.oid = place.oid
group by merchants.name, year(order_date)
order by year(order_date), avg(price) desc
limit 1;

-- 8) On average, what was the cheapest shipping method used ever?
select shipping_method, min(shipping_cost)
from orders
group by shipping_method
order by min(shipping_cost) asc
limit 1;

-- 9) What is the best sold ($) category for each company?
select distinct merchants.name, category, price
from merchants inner join sell inner join products
on merchants.mid = sell.mid and sell.pid = products.pid
order by price desc;

-- 10) For each company find out which customers have spent the most and
-- the least amounts.
select fullname, sum(price) as min, sum(price) as max
from customers inner join place inner join orders inner join contain inner join
	sell inner join merchants
on customers.cid = place.cid and place.oid = orders.oid and orders.oid = contain.oid
	and contain.pid = sell.pid and sell.mid = merchants.mid
group by fullname
order by sum(price) asc;