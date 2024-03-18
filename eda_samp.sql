create table tmt (date
date,fy
varchar,customer_name
varchar,dia
varchar,dia_group varchar,grade varchar,type varchar, length varchar,quantity numeric,rate numeric);

select * from tmt;

select * from tmt where date is null;
select * from tmt where fy is null;
select * from tmt where customer_name is null;
select * from tmt where dia is null;
select * from tmt where dia_group is null;
select * from tmt where grade is null;
select * from tmt where type is null;
select * from tmt where length is null;
select * from tmt where quantity is null;
select * from tmt where rate is null;

--To check count of rows
select count (*) from tmt;

--to se first 10 rows from table
select * from tmt limit 10;

--to check the null value count
select count (*) from tmt where quantity is null;  --14
select count (*) from tmt where rate is null;   --16

--Maximum value of columns
select max (dia) as highest_dia from tmt; --36MM
select max (dia_group) as highest_dia_group from tmt; --28MM
select max (grade) as highest_grade from tmt; --550D
select max (type) as highest_type from tmt; --Short length
select max (quantity) as highest_quantity from tmt; --41.68
select max (rate) as highest_rate from tmt; -- 83000


--Average(Mean) values
select avg (quantity) as average_quantity from tmt; --5.9
select avg (rate) as average_rate from tmt; --48521

--Minimum value of column
select min(dia) as highest_dia from tmt;
select min (dia_group) as highest_dia_group from tmt;
select min (grade) as highest_grade from tmt;
select min (type) as highest_type from tmt;
select min (quantity) as highest_quantity from tmt;
select min (rate) as highest_rate from tmt;

--shape of data
select count(*) as no_of_rows from tmt;
select count(*) as no_of_column from information_schema.columns where table_name = 'tmt';

--To show schema of data table
select * from information_schema.columns where table_name='tmt';

--To show selected columns
select * from tmt where grade = '500D';
select * from tmt where grade = '550D';
select * from tmt where dia = '36 MM';
select * from tmt where length = '0 METER';



--To show distinct values and there respective count
select distinct customer_name from tmt order by customer_name asc ;
select count (distinct customer_name) from tmt; --1016
select distinct dia from tmt order by dia asc;
select count (distinct dia) from tmt; --10
select distinct type from tmt order by type asc;
select count (distinct type) from tmt; --5
select distinct length from tmt order by length asc;
select count (distinct length) from tmt; --6

--To show 10 max customers by rate & quantity
select distinct customer_name, rate from tmt order by rate   desc limit 10;

--to check mode 
SELECT rate, COUNT(rate) AS mode FROM tmt GROUP BY rate ORDER BY mode DESC LIMIT 5; 
SELECT quantity, COUNT(quantity) AS mode FROM tmt GROUP BY quantity ORDER BY mode DESC LIMIT 5;

--to check median value 
--there is no built in function to calculate median in postgresql, so will calculate median using 50th percentile value
select percentile_cont (0.5) within group (order by rate)from tmt; --45700
select percentile_cont (0.5) within group (order by quantity)from tmt; --3.9

--to find variance in coloumn 
select variance(rate)as var_rate from tmt; --93.0K
select variance(quantity)as var_quantity from tmt; --44.5

--to find standard deviation of column
select stddev(rate)from tmt; --8829
select stddev(quantity)from tmt; --6.67

--to find the range of column
select min(dia) as min_dia, max(dia) as max_dia from tmt; --06MM to 36MM
select min(length) as min_length, max(length) as max_length from tmt; --0Meter to customize
select min(quantity) as min_quantity, max(quantity) as max_quantity from tmt; --32.3 to 41.68
select min(rate) as min_rate, max(rate) as max_rate from tmt; --19590 to 83000


--to check repetation of customers on date 
SELECT 
    date, 
    customer_name, 
    COUNT(*) AS Count
FROM tmt
GROUP BY date, customer_name order by count desc;




--nulll value imputation for quantity column 

select percentile_cont (0.5) within group (order by quantity)as median from tmt;

WITH medians AS (
  SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY quantity) AS median
  FROM tmt
)
UPDATE tmt
SET quantity = medians.median
FROM medians
WHERE quantity IS NULL;

select quantity from tmt where quantity is null;


--nulll value imputation for rate column 

select percentile_cont (0.5) within group (order by rate)as median from tmt;

WITH medians AS (
  SELECT percentile_cont(0.5) WITHIN GROUP (ORDER BY rate) AS median
  FROM tmt
)
UPDATE tmt
SET rate = medians.median
FROM medians
WHERE rate IS NULL;

select rate from tmt where rate is null;


--frequency of diameter
SELECT dia, COUNT(*) AS frequency1
FROM tmt
GROUP BY dia;

--frequency of length
SELECT length, COUNT(*) AS frequency2
FROM tmt
GROUP BY length;

--frequency of grade
SELECT grade, COUNT(*) AS frequency3
FROM tmt
GROUP BY grade;


--Determine IQR, lOWER LIMIT & UPPER LIMIT of Quantity

WITH quartiles AS (
  SELECT 
    percentile_cont(0.25) WITHIN GROUP (ORDER BY quantity) AS q1,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY quantity) AS q3
  FROM tmt
)
SELECT 
  q1 - 1.5 * (q3 - q1) AS lower_limit,
  q3 + 1.5 * (q3 - q1) AS upper_limit,
  q3 - q1 AS iqr
FROM quartiles;

--determine the outlier 

SELECT quantity
FROM tmt
WHERE quantity < -5.53 OR quantity > 14.54;

-- By using winsorization method treating outliers

UPDATE tmt
SET quantity = 
  CASE
    WHEN quantity < (SELECT percentile_cont(0.05) WITHIN GROUP (ORDER BY quantity) FROM tmt) THEN (SELECT percentile_cont(0.05) WITHIN GROUP (ORDER BY quantity) FROM tmt)
    WHEN quantity > (SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY quantity) FROM tmt) THEN (SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY quantity) FROM tmt)
    ELSE quantity
  END;

--After performing winsorization there are still outliers at upper limit in quantity column so replacing those outliers to q3 value

UPDATE tmt SET quantity = LEAST(14.54, GREATEST(-5.53,quantity));


--Determine IQR, lOWER LIMIT & UPPER LIMIT of rate 

WITH quartiles AS (
  SELECT 
    percentile_cont(0.25) WITHIN GROUP (ORDER BY rate) AS q1,
    percentile_cont(0.75) WITHIN GROUP (ORDER BY rate) AS q3
  FROM tmt
)
SELECT 
  q1 - 1.5 * (q3 - q1) AS lower_limit,
  q3 + 1.5 * (q3 - q1) AS upper_limit,
  q3 - q1 AS iqr
FROM quartiles;

--Determine outliers

SELECT rate
FROM tmt
WHERE rate < 20375 OR quantity > 77375;

-- By using winsorization method treating outliers

UPDATE tmt
SET rate = 
  CASE
    WHEN rate < (SELECT percentile_cont(0.05) WITHIN GROUP (ORDER BY rate) FROM tmt) THEN (SELECT percentile_cont(0.05) WITHIN GROUP (ORDER BY rate) FROM tmt)
    WHEN rate > (SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY rate) FROM tmt) THEN (SELECT percentile_cont(0.95) WITHIN GROUP (ORDER BY rate) FROM tmt)
    ELSE rate
  END;


select * from tmt;






















	



