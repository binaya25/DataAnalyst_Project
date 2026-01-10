CREATE VIEW vw_churnData as
	SELECT * FROM dbo.production_churn 
	WHERE Customer_Status IN ('Churned', 'Stayed')


CREATE VIEW vw_JoinData as
	SELECT * FROM dbo.production_churn 
	WHERE Customer_Status = 'Joined'


