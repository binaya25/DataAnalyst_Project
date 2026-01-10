-- Gender percentage
SELECT Gender, COUNT(Gender) as TotalNumGender,
(COUNT(Gender) * 100.0/ (SELECT COUNT(*) FROM dbo.stage_churn)) as Percentage
FROM dbo.stage_churn
Group by Gender

--Contract percentage
SELECT Contract, COUNT(Contract) as TotalContract,
COUNT(Contract) * 100.0/(SELECT COUNT(*) FROM dbo.stage_churn) as Percentage
FROM dbo.stage_churn
GROUP by Contract

--Customer_status revenue percentage
SELECT Customer_Status, COUNT(Customer_Status) as TotalCustomer_Status, SUM(Total_Revenue) as Total_Revenue,
SUM(Total_Revenue) * 100.0/ (SELECT SUM(Total_Revenue) FROM dbo.stage_churn) AS Percentage
FROM dbo.stage_churn
GROUP by Customer_Status

--Highest-lowest Customer contribution by state
SELECT State, COUNT(State) as TotalNumState,
COUNT(State) * 100.0/(SELECT COUNT(*) FROM dbo.stage_churn) as Percentage
FROM dbo.stage_churn
GROUP by State
ORDER BY Percentage DESC;



