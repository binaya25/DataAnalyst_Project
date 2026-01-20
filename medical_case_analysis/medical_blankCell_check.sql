--checking null or blank cells
SELECT * FROM dbo.medical_InpatientDBDB
WHERE 
	DRG_CODE IS NULL OR DRG_CODE = '' OR
	DRG_Definition IS NULL OR DRG_Definition = '' OR
	Patient_Name IS NULL OR Patient_Name = '' OR
	District IS NULL OR District = '' OR
	Doctor IS NULL OR Doctor = '' OR
	Admission_Date IS NULL OR Admission_Date = '' OR
	Discharge_date IS NULL OR Discharge_date = '' OR
	Admitted_Days IS NULL OR Admitted_Days = '' OR
	Gender IS NULL OR Gender = '' OR
	Age IS NULL OR
	Charge IS NULL OR
	G_Amount IS NULL OR
	Discount IS NULL OR
	D_Amt IS NULL OR
	G_AMT IS NULL OR
	VAT IS NULL OR
	Net_Amount IS NULL OR
	Has_Cured IS NULL OR Has_Cured = '' OR
	IS_DEAD IS NULL OR IS_DEAD = '' OR
	Year IS NULL OR Year = '' OR
	month IS NULL OR month = '' OR
	Doctor_Rate IS NULL; 

--Validating dates
SELECT * FROM dbo.medical_InpatientDBDB
WHERE Discharge_date < Admission_Date;

--Recheck date differences
SELECT
	CASE 
		WHEN COUNT(CASE
			WHEN Admitted_Days <> DATEDIFF(DAY, Admission_Date, Discharge_Date) THEN 1
			END) > 0 THEN 'NO'
		else 'YES'
	END AS RecheckAdmittedDays
FROM dbo.medical_InpatientDBDB;


--Business problem: Understand the length of stay
--ML Prediction Target: Length of Stay and interval of old patients and new joiners
--Why: To support bed management, staffing and financial/cost planning

-- Average Length of stay (KPIs)
SELECT AVG(Admitted_Days) AS AvgLengthOfStay
FROM dbo.medical_InpatientDBDB
WHERE Discharge_date BETWEEN Admission_Date and Discharge_date;


-- Patient readmission rate by Patient_Name
SELECT
	(SUM(Readmitted) * 100.0/ SUM(TotalAdmitted)) AS OverallReadmissionRate
FROM (
SELECT 
	COUNT(*) AS TotalAdmitted,
	COUNT(*) - 1 AS Readmitted
FROM dbo.medical_InpatientDBDB
GROUP BY Patient_Name
HAVING COUNT(*) > 1
) AS ReadmissionData;


-----Average daily admissions + patients counts
SELECT 
    AVG(PatientCount) AS AveragePatientCount
FROM (
    SELECT 
        COUNT(*) AS PatientCount
    FROM dbo.medical_InpatientDBDB
    GROUP BY Admission_Date
) AS DailyPatientCounts;


-- Clinical/operational
-----Top 5 Admitted and followed-up cases
SELECT TOP 5 DRG_Code, DRG_Definition, COUNT(DRG_Definition) AS TotalCount
FROM dbo.medical_InpatientDBDB
GROUP BY DRG_CODE, DRG_Definition
ORDER BY TotalCount DESC;





-----Time series Analysis
SELECT 
    CAST(Admission_Date AS DATE) AS AdmissionDate,
    COUNT(*) AS DailyAdmissions
FROM dbo.medical_InpatientDBDB
GROUP BY CAST(Admission_Date AS DATE)
ORDER BY AdmissionDate;

--Demographic
-----Admission by Gender
SELECT
	COUNT(CASE WHEN Gender = 'M' THEN 1 END) AS TotalMen,
	COUNT(CASE WHEN Gender = 'F' THEN 1 END) AS TotalFemale
FROM dbo.medical_InpatientDBDB


-----Total Admission by Age
SELECT 
	COUNT(CASE WHEN Age < 20 THEN 1 END) AS '<20',
	COUNT(CASE WHEN Age BETWEEN 20 AND 35 THEN 1 END) AS '20-34',
	COUNT(CASE WHEN Age BETWEEN 35 AND 50 THEN 1 END) AS '35-49',
	COUNT(CASE WHEN Age >= 50 THEN 1 END) AS '>=50'
FROM dbo.medical_InpatientDBDB

--Geographic
-----District
SELECT District, COUNT(*) AS AdmissionByDistrict
FROM dbo.medical_InpatientDBDB
GROUP BY District
ORDER BY AdmissionByDistrict DESC;

-----Net amount by district
SELECT District, SUM(Net_Amount) AS NetAmountByDistrict
FROM dbo.medical_InpatientDBDB
GROUP BY District
ORDER BY NetAmountByDistrict DESC;

-----Patient Name
SELECT Patient_Name, COUNT(*) AS PatientNameAdmission
FROM dbo.medical_InpatientDBDB
GROUP BY Patient_Name
ORDER BY PatientNameAdmission DESC;

--Provider
-----Doctor, Doctor Rate
SELECT DISTINCT TOP 5 Doctor, Doctor_Rate
FROM dbo.medical_InpatientDBDB
ORDER BY Doctor_Rate DESC;


--Doctor, monthly, attendance. 
SELECT DISTINCT TOP 5 Doctor, 
	YEAR(Admission_Date) as year, 
	MONTH(Discharge_date) AS month,
	COUNT(*) as TotalAttendance
FROM dbo.medical_InpatientDBDB
GROUP BY Doctor,YEAR(Admission_Date), MONTH(Discharge_date)
ORDER BY year DESC, month DESC



--Financial
-----Charge
SELECT DRG_CODE, DRG_Definition, SUM(Charge) AS TotalCharge
FROM dbo.medical_InpatientDBDB
GROUP BY DRG_CODE, DRG_Definition
ORDER BY TotalCharge DESC;

------Discount
SELECT DRG_CODE, DRG_Definition, SUM(Discount) AS TotalDiscount
FROM dbo.medical_InpatientDBDB
GROUP BY DRG_CODE, DRG_Definition
ORDER BY TotalDiscount DESC;

------VAT
SELECT DRG_CODE, DRG_Definition, SUM(VAT) AS TotalVAT
FROM dbo.medical_InpatientDBDB
GROUP BY DRG_CODE, DRG_Definition
ORDER BY TotalVAT DESC;

-------Net_Amount
SELECT DRG_CODE, DRG_Definition, SUM(Net_Amount) AS Net_Amount
FROM dbo.medical_InpatientDBDB
GROUP BY DRG_CODE, DRG_Definition
ORDER BY Net_Amount DESC;


----Revenue vs expenses


--Time
---Year-over-Year revenue and yearly growth rate
WITH YearlyRevenue AS (
    SELECT 
        Year, 
        SUM(Net_Amount) AS Revenue
    FROM dbo.medical_InpatientDBDB
    GROUP BY Year
)
SELECT 
    Year, 
    Revenue,
    ((Revenue - LAG(Revenue) OVER (ORDER BY Year)) * 100.0 / NULLIF(LAG(Revenue) OVER (ORDER BY Year), 0)) AS YearlyGrowthRate
FROM YearlyRevenue
ORDER BY Year DESC
OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;


---Year-over-year admission
SELECT 
    YEAR(Admission_Date) AS Year,
    COUNT(*) AS TotalAdmissions
FROM dbo.medical_InpatientDBDB
GROUP BY YEAR(Admission_Date)
ORDER BY Year DESC;

--PowerBI DAX Measure---Total Bed‑Days = SUM(Admitted_Days)
--AvgTotalLOS
--PATIENTRATEADMISSION








SELECT * FROM dbo.medical_InpatientDBDB