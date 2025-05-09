--SQL Advance Case Study


--Q1--  List all the states in which we have customers who have bought cellphones from 2005 till today.   
	
SELECT DISTINCT [State] 
FROM DIM_LOCATION AS L
INNER JOIN FACT_TRANSACTIONS AS T
ON L.IDLocation = T.IDLocation
INNER JOIN DIM_MODEL AS M
ON T.IDModel = M.IDModel 
WHERE YEAR(Date) >= 2005
	 
--Q1--END

--Q2-- What state in the US is buying the most 'Samsung' cell phones?
	
SELECT  TOP 1 [State]
FROM DIM_LOCATION AS L
INNER JOIN FACT_TRANSACTIONS AS T
ON L.IDLocation = T.IDLocation
INNER JOIN DIM_MODEL AS M
ON T.IDModel = M.IDModel
INNER JOIN DIM_MANUFACTURER AS MN
ON MN.IDManufacturer = M.IDManufacturer
WHERE Country = 'US'
		AND 
	Manufacturer_Name = 'SAMSUNG'
GROUP BY [State]
ORDER BY SUM(Quantity) DESC

--Q2--END

--Q3-- Show the number of transactions for each model per zip code per state.     

SELECT Model_Name, ZipCode, [State] ,COUNT(IDCustomer) AS TRANS_COUNT
FROM FACT_TRANSACTIONS AS T
INNER JOIN DIM_LOCATION AS L
ON T.IDLocation = L.IDLocation 
INNER JOIN DIM_MODEL AS M
ON M.IDModel = T.IDModel
GROUP BY ZipCode, [State] , Model_Name

--Q3--END

--Q4-- Show the cheapest cellphone (Output should contain the price also)

SELECT TOP 1  Manufacturer_Name, Model_Name, Unit_price
FROM DIM_MODEL as M
INNER JOIN DIM_MANUFACTURER AS MN
ON M.IDManufacturer = MN.IDManufacturer 
ORDER BY Unit_price

--Q4--END

--Q5-- Find out the average price for each model in the top5 manufacturers in terms of sales quantity and order by average price.  
 
SELECT Manufacturer_Name, Model_Name, SUM(TotalPrice) / SUM(Quantity) AS AVG_PRICE
FROM FACT_TRANSACTIONS AS T 
INNER JOIN DIM_MODEL AS M 
ON M.IDModel = T.IDModel 
INNER JOIN DIM_MANUFACTURER AS MN
ON MN.IDManufacturer = M.IDManufacturer
WHERE M.IDManufacturer IN (
							SELECT  TOP 5 IDManufacturer FROM FACT_TRANSACTIONS AS T
							INNER JOIN DIM_MODEL AS M
							ON T.IDModel = M.IDModel
							GROUP BY IDManufacturer
							ORDER BY SUM(Quantity) DESC)
GROUP BY Manufacturer_Name, Model_Name 
ORDER BY  AVG_PRICE 

--Q5--END

--Q6-- List the names of the customers and the average amount spent in 2009, where the average is higher than 500  

SELECT Customer_Name, AVG(TotalPrice) AS AVG_AMT FROM DIM_CUSTOMER AS C 
INNER JOIN FACT_TRANSACTIONS AS T
ON C.IDCustomer = T.IDCustomer
WHERE YEAR(Date) = 2009
GROUP BY Customer_Name 
HAVING AVG(TotalPrice) > 500 

--Q6--END

--Q7-- List if there is any model that was in the top 5 in terms of quantity, simultaneously in 2008, 2009 and 2010   

WITH TOP_5_MODELS_2008 
AS (
		SELECT TOP 5 M.Model_Name,T.IDModel,  SUM(Quantity) AS TOT_QTY 
		FROM FACT_TRANSACTIONS AS T
		INNER JOIN DIM_MODEL AS M
		ON T.IDModel = M.IDModel
		WHERE YEAR(Date) = 2008
		GROUP BY T.IDModel,Model_Name
		ORDER BY TOT_QTY DESC
),
TOP_5_MODELS_2009
AS (
		SELECT TOP 5 M.Model_Name,T.IDModel,  SUM(Quantity) AS TOT_QTY 
		FROM FACT_TRANSACTIONS AS T
		INNER JOIN DIM_MODEL AS M
		ON T.IDModel = M.IDModel
		WHERE YEAR(Date) = 2009
		GROUP BY T.IDModel,Model_Name
		ORDER BY TOT_QTY DESC
),
TOP_5_MODELS_2010
AS (
		SELECT TOP 5 M.Model_Name,T.IDModel,  SUM(Quantity) AS TOT_QTY 
		FROM FACT_TRANSACTIONS AS T
		INNER JOIN DIM_MODEL AS M
		ON T.IDModel = M.IDModel
		WHERE YEAR(Date) = 2010
		GROUP BY T.IDModel,Model_Name
		ORDER BY TOT_QTY DESC
)
SELECT IDModel,Model_Name FROM TOP_5_MODELS_2008
INTERSECT
SELECT IDModel,Model_Name FROM TOP_5_MODELS_2009
INTERSECT
SELECT IDModel, Model_Name FROM TOP_5_MODELS_2010

--Q7--END	


--Q8-- Show the manufacturer with the 2nd top sales in the year of 2009 and the manufacturer with the 2nd top sales in the year of 2010.  

SELECT * 
FROM ( 
		SELECT MN.IDManufacturer,Manufacturer_Name, SUM(TotalPrice) AS TOT_PRICE, 
		DENSE_RANK () OVER(ORDER BY SUM(TotalPrice)DESC) AS RANK_NO
		FROM FACT_TRANSACTIONS AS T
		INNER JOIN DIM_MODEL AS M
		ON T.IDModel = M.IDModel
		INNER JOIN DIM_MANUFACTURER AS MN
		ON M.IDManufacturer = MN.IDManufacturer
		WHERE YEAR(Date) = 2009
		GROUP BY Manufacturer_Name, MN.IDManufacturer
) AS X
WHERE RANK_NO = 2 
UNION
SELECT * 
FROM ( 
		SELECT  MN.IDManufacturer, Manufacturer_Name, SUM(TotalPrice) AS TOT_PRICE, 
		DENSE_RANK () OVER(ORDER BY SUM(TotalPrice)DESC) AS RANK_NO
		FROM FACT_TRANSACTIONS AS T
		INNER JOIN DIM_MODEL AS M
		ON T.IDModel = M.IDModel
		INNER JOIN DIM_MANUFACTURER AS MN
		ON M.IDManufacturer = MN.IDManufacturer
		WHERE YEAR(Date) = 2010
		GROUP BY Manufacturer_Name, MN.IDManufacturer
) AS Y 
WHERE RANK_NO = 2 


--Q8--END


--Q9-- Show the manufacturers that sold cellphones in 2010 but did not in 2009.  

SELECT DISTINCT M.IDManufacturer, Manufacturer_Name  FROM DIM_MANUFACTURER AS M
INNER JOIN DIM_MODEL AS MO
ON M.IDManufacturer = MO.IDManufacturer 
INNER JOIN FACT_TRANSACTIONS AS T
ON T. IDModel = MO.IDModel
WHERE YEAR(DATE) = 2010 
EXCEPT
SELECT DISTINCT M.IDManufacturer,Manufacturer_Name FROM DIM_MANUFACTURER AS M
INNER JOIN DIM_MODEL AS MO
ON M.IDManufacturer = MO.IDManufacturer
INNER JOIN FACT_TRANSACTIONS AS T
ON T. IDModel = MO.IDModel
WHERE YEAR(Date) = 2009	


--Q9--END

--Q10-- Find top 100 customers and their average spend, average quantity by each year. Also find the percentage of change in their spend. 

WITH TOP_10 
AS (
		SELECT TOP 10 C.IDCustomer, SUM(TotalPrice) AS TOT_PRICE FROM DIM_CUSTOMER AS C
		INNER JOIN FACT_TRANSACTIONS AS T
		ON C.IDCustomer = T.IDCustomer 
		GROUP BY C.IDCustomer
		ORDER BY TOT_PRICE DESC
), 
YEARLY_SPEND
AS ( 
		SELECT C.IDCustomer, YEAR(Date) AS YEARS, AVG(TotalPrice) AS AVG_AMT, AVG(Quantity) AS AVG_QTY
		FROM DIM_CUSTOMER AS C
		INNER JOIN FACT_TRANSACTIONS AS T
		ON C.IDCustomer = T.IDCustomer
		WHERE C.IDCustomer IN (SELECT IDCustomer FROM TOP_10)
		GROUP BY C.IDCustomer,YEAR(Date)
),
PERVIOUS_SPEND
AS (
		SELECT * , LAG(AVG_AMT) OVER (PARTITION BY IDCustomer ORDER BY YEARS) AS PREV_SPEND
		FROM YEARLY_SPEND
)

SELECT  *, ((AVG_AMT - PREV_SPEND) / PREV_SPEND )* 100 AS '%_CHANGE_SPEND'
FROM PERVIOUS_SPEND	

--Q10--END
	