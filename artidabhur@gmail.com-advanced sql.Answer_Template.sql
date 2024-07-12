--SQL Advance Case Study
SELECT * FROM  FACT_TRANSACTIONS 
SELECT * FROM DIM_MANUFACTURER
SELECT * FROM DIM_MODEL 
SELECT * FROM DIM_CUSTOMER
SELECT * FROM DIM_LOCATION 
SELECT * FROM DIM_DATE


--Q1--BEGIN . 
--List all the states in which we have customers who have bought cellphones from 2005 till today.
		
	Select DISTINCT State from
	FACT_TRANSACTIONS as F
	JOIN DIM_LOCATION as L
	ON F.IDLocation = L.IDLocation
	where F.Date BETWEEN '2005-01-01' AND GETDATE()

	
--Q1--END

--Q2--BEGIN . 
--What state in the US is buying the most 'Samsung' cell phones?

	SELECT TOP 1 T1.State, SUM (T1.QUANTITY) AS TOTAL_QTY FROM 
	(Select F.IDModel,L.Country,L.State,F.Quantity from
	FACT_TRANSACTIONS as F
	JOIN DIM_LOCATION as L
	ON F.IDLocation = L.IDLocation
	WHERE L.COUNTRY ='US') AS T1
    JOIN
	(select Model_Name,Manufacturer_Name,M.IDModel from
	DIM_MANUFACTURER as MA
	join DIM_MODEL as M
	ON M.IDManufacturer=MA.IDManufacturer
	WHERE MA.Manufacturer_Name='SAMSUNG')AS T2
	
	ON T1.IDModel=T2.IDModel
	GROUP BY T1.State
	ORDER BY SUM (T1.QUANTITY) DESC
	 	

--Q2--END

--Q3--BEGIN . 
--Show the number of transactions for each model per zip code per state.     

	SELECT T1.IDModel,L.ZipCode,L.State, COUNT(T1.IDModel)AS COUNT_OF_TRANSACTIONS FROM 
	(SELECT F.IDModel,F.IDLocation,M.Model_Name FROM
	FACT_TRANSACTIONS as F
	JOIN DIM_MODEL as M
	ON F.IDModel=M.IDModel) AS T1
	JOIN
	DIM_LOCATION as L
	ON T1.IDLocation = L.IDLocation
	GROUP BY T1.IDModel,L.ZipCode,L.State 

	

--Q3--END

--Q4--BEGIN. 
--Show the cheapest cellphone (Output should contain the price)

	SELECT TOP 1 Model_Name,Unit_price FROM
	DIM_MODEL 
	ORDER BY UNIT_PRICE ASC
	


--Q4--END

--Q5--BEGIN
--Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.

	SELECT mo.Model_Name,sum (TotalPrice)/sum (Quantity) as average_price FROM 
	FACT_TRANSACTIONS as F
	JOIN DIM_MODEL as MO
	ON F.IDMODEL = MO.IDMODEL
	JOIN DIM_MANUFACTURER AS MA
	on MO.IDManufacturer= MA.IDManufacturer
	where ma.Manufacturer_Name in 
	(
	SELECT  TOP 5  ma.Manufacturer_Name FROM   --top5 manufacturers in terms of sales quantity
	FACT_TRANSACTIONS as F
	JOIN DIM_MODEL as MO
	ON F.IDMODEL = MO.IDMODEL
	JOIN DIM_MANUFACTURER AS MA
	on MO.IDManufacturer= MA.IDManufacturer
	group by ma.Manufacturer_Name
	ORDER BY sum (F.Quantity) DESC
	
	)
	group by mo.Model_Name
	order by average_price desc

	
--Q5--END

--Q6--BEGIN 
--List the names of the customers and the average amount spent in 2009,	where the average is higher than 500

	SELECT Customer_Name, AVG(TotalPrice) AS AVERAGE_AMOUNT_SPENT from 
	FACT_TRANSACTIONS AS F
	JOIN DIM_CUSTOMER AS C
	ON F.IDCustomer=C.IDCustomer
	WHERE YEAR(F.Date)= '2009'
	GROUP BY Customer_Name
	HAVING AVG(TotalPrice)>500


--Q6--END
	
--Q7--BEGIN 
-- List if there is any model that was in the top 5 in terms of quantity,simultaneously in 2008, 2009 and 2010
    SELECT MO.Model_Name FROM   
	FACT_TRANSACTIONS as F
	JOIN DIM_MODEL as MO
	ON F.IDMODEL = MO.IDMODEL
	WHERE  F.IDModel IN(SELECT TOP 5 IDMODEL
								FROM FACT_TRANSACTIONS 
								WHERE YEAR(Date) = '2008'  
								GROUP BY IDMODEL 
								ORDER BY SUM(QUANTITY) DESC)
       AND 
			F.IDModel IN (		SELECT TOP 5 IDMODEL
								FROM FACT_TRANSACTIONS 
								WHERE YEAR(Date) = '2009'  
								GROUP BY IDMODEL 
								ORDER BY  SUM(QUANTITY) DESC)
		AND 
			F.IDModel IN (		SELECT TOP 5  IDMODEL
								FROM FACT_TRANSACTIONS 
								WHERE YEAR(Date) = '2010'  
								GROUP BY IDMODEL 
								ORDER BY  SUM(QUANTITY) DESC)
		GROUP BY MO.Model_Name

--Q7--END	
--Q8--BEGIN. 
--Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.
	

	 SELECT manufacture,YEAR_,price from 
	(SELECT manufacture,YEAR_,price,
	
	dense_rank() over (PARTITION BY YEAR_ order by price desc) as rank_ FROM   
	(
	SELECT ma.Manufacturer_Name AS manufacture ,year(date)AS YEAR_ , sum(totalprice) as price FROM 
	FACT_TRANSACTIONS as F
	JOIN DIM_MODEL as MO
	ON F.IDMODEL = MO.IDMODEL
	JOIN DIM_MANUFACTURER AS MA
	on MO.IDManufacturer= MA.IDManufacturer
	where year(date)IN ('2009','2010')
	group by ma.Manufacturer_Name,year(date)
	) T
	) x
	where rank_ = 2
	
	


--Q8--END
--Q9--BEGIN . 
--Show the manufacturers that sold cellphones in 2010 but did not in 2009.
	SELECT DISTINCT  ma.Manufacturer_Name AS manufacture  FROM 
	FACT_TRANSACTIONS as F
	JOIN DIM_MODEL as MO
	ON F.IDMODEL = MO.IDMODEL
	JOIN DIM_MANUFACTURER AS MA
	on MO.IDManufacturer= MA.IDManufacturer
	where year(date)='2010'
	
	 EXCEPT
	(SELECT DISTINCT ma.Manufacturer_Name AS manufacture  FROM 
	FACT_TRANSACTIONS as F
	JOIN DIM_MODEL as MO
	ON F.IDMODEL = MO.IDMODEL
	JOIN DIM_MANUFACTURER AS MA
	on MO.IDManufacturer= MA.IDManufacturer
	where year(date)='2009')
	





--Q9--END

--Q10--BEGIN 
--Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend.
		
	SELECT X.* ,
	CASE
	WHEN Y.YEAR_ IS NOT NULL THEN ((X.AVERAGE_AMOUNT_SPENT-Y.AVERAGE_AMOUNT_SPENT)/Y.AVERAGE_AMOUNT_SPENT)*100 ELSE NULL
	END AS YOY_PERCENTAGE_CHANGE
	FROM
	(
	SELECT Customer_Name,YEAR(DATE) AS YEAR_, AVG(TotalPrice) AS AVERAGE_AMOUNT_SPENT, AVG(Quantity) AS AVERAGE_QUANTITY from 
	FACT_TRANSACTIONS AS F
	JOIN DIM_CUSTOMER AS C
	ON F.IDCustomer=C.IDCustomer
	WHERE F.IDCustomer IN (SELECT TOP 100 IDCustomer FROM FACT_TRANSACTIONS GROUP BY IDCustomer ORDER BY SUM(TOTALPRICE) DESC)
	GROUP BY Customer_Name, YEAR(DATE)
	) AS X
	left join
	(
	SELECT Customer_Name,YEAR(DATE) AS YEAR_, AVG(TotalPrice) AS AVERAGE_AMOUNT_SPENT, AVG(Quantity) AS AVERAGE_QUANTITY from 
	FACT_TRANSACTIONS AS F
	JOIN DIM_CUSTOMER AS C
	ON F.IDCustomer=C.IDCustomer
	WHERE F.IDCustomer IN (SELECT TOP 100 IDCustomer FROM FACT_TRANSACTIONS GROUP BY IDCustomer ORDER BY SUM(TOTALPRICE) DESC)
	GROUP BY Customer_Name, YEAR(DATE)
	) AS Y
	ON X.Customer_Name=Y.Customer_Name AND Y.YEAR_=X.YEAR_-1

	
--Q10--END