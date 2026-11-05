-- 1. Write a query that returns the number of records in the City table
SELECT COUNT(*) AS CityCount
FROM dbo.City;

-- 2. Write a query that returns the plans—their names and prices—from the Plan table that include an internet data plan
SELECT p.planName, p.price
FROM dbo.[Plan] p
WHERE p.internetDataPlanID IS NOT NULL;

-- 3. Extend the result set with: the internet data plan name; the included data allowance in MB; the internet data plan price; the corresponding mobile network operator name.
SELECT 
    p.planName AS PlanName,
    p.price AS PlanPrice,
    idp.internetDataPlanName AS InternetPlanName,
    idp.dataAllowanceMB AS DataAllowanceMB,
    idp.price AS InternetPlanPrice,
    mno.operatorName AS OperatorName
FROM dbo.[Plan] p
JOIN dbo.InternetDataPlan idp ON p.internetDataPlanID = idp.internetDataPlanID
JOIN dbo.MobileNetworkOperator mno ON p.operatorID = mno.operatorID;

-- 4. Write a query that returns all mobile network operators—their names—and the plans they offer—their names and prices—that include at least 100 free minutes for calls within the Lithuanian network.
SELECT 
    mno.operatorName,
    p.planName,
    p.price
FROM dbo.MobileNetworkOperator mno
JOIN dbo.[Plan] p ON mno.operatorID = p.operatorID
WHERE p.planName LIKE '%100%' 
  AND p.planName NOT LIKE '%GB%';

-- 5. Write a query that returns a summary showing the number of users in each city
SELECT 
    c.cityName,
    COUNT(p.personID) AS UserCount
FROM dbo.City c
LEFT JOIN dbo.Person p ON c.cityID = p.cityID
GROUP BY c.cityName;

-- 6. Write a query that returns the cities with no users
SELECT c.cityName
FROM dbo.City c
LEFT JOIN dbo.Person p ON c.cityID = p.cityID
WHERE p.personID IS NULL;

-- 7. Write queries that calculate the average number of users per city: excluding cities with no users
SELECT AVG(UserCount) AS AvgUsersPerCityExcludingEmpty
FROM (
    SELECT c.cityID, COUNT(p.personID) AS UserCount
    FROM dbo.City c
    JOIN dbo.Person p ON c.cityID = p.cityID
    GROUP BY c.cityID
) AS CityCounts;

-- 8. Write queries that calculate the average number of users per city: including cities with no users
SELECT AVG(UserCount) AS AvgUsersPerCityIncludingEmpty
FROM (
    SELECT c.cityID, COUNT(p.personID) AS UserCount
    FROM dbo.City c
    LEFT JOIN dbo.Person p ON c.cityID = p.cityID
    GROUP BY c.cityID
) AS CityCounts;

-- 9. Write a query that returns the name of the operator offering the largest number of plans. If several operators offer the same maximum number of plans, return all of them.
SELECT mno.operatorName, COUNT(p.planID) AS PlanCount
FROM dbo.MobileNetworkOperator mno
JOIN dbo.[Plan] p ON mno.operatorID = p.operatorID
GROUP BY mno.operatorName
HAVING COUNT(p.planID) = (
    SELECT MAX(PlanCount)
    FROM (
        SELECT COUNT(planID) AS PlanCount
        FROM dbo.[Plan]
        GROUP BY operatorID
    ) AS OperatorPlanCounts
);

-- 10. Write a query that returns a list of people who subscribed to any plan between January 3, 2025 and january 10, 2025, inclusive
SELECT 
    p.firstName,
    p.lastName,
    pl.planName,
    s.contractStartDate
FROM dbo.Subscriber s
JOIN dbo.Person p ON s.personID = p.personID
JOIN dbo.[Plan] pl ON s.planID = pl.planID
WHERE s.contractStartDate BETWEEN '2025-01-03' AND '2025-01-10';

-- 11. Write a query that calculates the average price of the plans offered by each operator
SELECT 
    mno.operatorName,
    AVG(p.price) AS AvgPlanPrice
FROM dbo.MobileNetworkOperator mno
JOIN dbo.[Plan] p ON mno.operatorID = p.operatorID
GROUP BY mno.operatorName
ORDER BY AvgPlanPrice DESC;

-- 12. Write a query that determines how many additional services are provided by each operator
SELECT 
    mno.operatorName,
    COUNT(oas.operatorAdditionalServiceID) AS AdditionalServiceCount
FROM dbo.MobileNetworkOperator mno
LEFT JOIN dbo.OperatorAdditionalService oas ON mno.operatorID = oas.operatorID
GROUP BY mno.operatorName;