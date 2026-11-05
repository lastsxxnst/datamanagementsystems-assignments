-- 1. Find additional services for operator TELE2 (name and price).
-- Joining OperatorAdditionalService with AdditionalService and filtering by operator name.
SELECT
    ads.additionalServiceName AS AdditionalServiceName,
    oas.price AS Price
FROM dbo.OperatorAdditionalService oas
JOIN dbo.MobileNetworkOperator mno ON oas.operatorID = mno.operatorID
JOIN dbo.AdditionalService ads ON oas.additionalServiceID = ads.additionalServiceID
WHERE mno.operatorName = 'TELE2';

-- 2. List all additional services across all operators (operator, service, price).
-- Simple join between three tables to get readable names instead of IDs.
SELECT
    mno.operatorName AS OperatorName,
    ads.additionalServiceName AS AdditionalServiceName,
    oas.price AS Price
FROM dbo.OperatorAdditionalService oas
JOIN dbo.MobileNetworkOperator mno ON oas.operatorID = mno.operatorID
JOIN dbo.AdditionalService ads ON oas.additionalServiceID = ads.additionalServiceID
ORDER BY mno.operatorName, ads.additionalServiceName;

-- 3. Count how many countries are in each zone.
-- LEFT JOIN ensures we see zones even if they have 0 countries.
SELECT
    z.zoneName AS ZoneName,
    COUNT(c.countryCode) AS CountryCount
FROM dbo.Zone z
LEFT JOIN dbo.Country c ON z.zoneID = c.zoneID
GROUP BY z.zoneName;

-- 4. Find the operator with the most expensive calls to Mexico.
-- Note: The country is spelled 'Meksika' in the DB.
-- We filter by the service name for international calls and sort by price descending.
SELECT TOP 1
    mno.operatorName AS OperatorName
FROM dbo.ServicePriceInZone spz
JOIN dbo.MobileNetworkOperator mno ON spz.operatorID = mno.operatorID
JOIN dbo.Country c ON spz.zoneID = c.zoneID
JOIN dbo.Service s ON spz.serviceID = s.serviceID
WHERE c.countryName = 'Meksika'
  AND s.serviceName LIKE '%uzsienio tinklus%'
ORDER BY spz.price DESC;

-- 5. Find an internet data plan NOT included in any mobile plan, with the lowest price per 1 MB.
-- We use a subquery with NOT IN to exclude plans that are already linked to a main Plan.
SELECT
    mno.operatorName AS OperatorName,
    idp.internetDataPlanName AS InternetDataPlanName,
    (idp.price / idp.dataAllowanceMB) AS PricePerMB
FROM dbo.InternetDataPlan idp
JOIN dbo.MobileNetworkOperator mno ON idp.operatorID = mno.operatorID
WHERE idp.internetDataPlanID NOT IN (
    SELECT internetDataPlanID
    FROM dbo.[Plan]
    WHERE internetDataPlanID IS NOT NULL
)
ORDER BY PricePerMB ASC;

-- 6. Calculate the percentage distribution of subscribers across operators.
-- Subquery (SELECT COUNT(*) FROM Subscriber) gets the total number of subscribers to calculate the percentage.
SELECT
    mno.operatorName AS OperatorName,
    COUNT(s.subscriberID) AS SubscriberCount,
    (COUNT(s.subscriberID) * 100.0 / (SELECT COUNT(*) FROM dbo.Subscriber)) AS Percentage
FROM dbo.MobileNetworkOperator mno
JOIN dbo.[Plan] p ON mno.operatorID = p.operatorID
JOIN dbo.Subscriber s ON p.planID = s.planID
GROUP BY mno.operatorName;

-- 7. Find the top 3 most popular plans, including ties at the cutoff point.
-- The HAVING clause with MIN() ensures that if the 3rd and 4th places have the same count, both are returned.
SELECT
    p.planName AS PlanName,
    COUNT(s.subscriberID) AS SubscriberCount
FROM dbo.[Plan] p
JOIN dbo.Subscriber s ON p.planID = s.planID
GROUP BY p.planName
HAVING COUNT(s.subscriberID) >= (
    SELECT MIN(SubscriberCount)
    FROM (
        SELECT TOP 3 COUNT(s2.subscriberID) AS SubscriberCount
        FROM dbo.[Plan] p2
        JOIN dbo.Subscriber s2 ON p2.planID = s2.planID
        GROUP BY p2.planName
        ORDER BY SubscriberCount DESC
    ) AS Top3Counts
)
ORDER BY SubscriberCount DESC;

-- 8. Get 10 random subscribers with full details.
-- ORDER BY NEWID() is used to select random rows.
-- CASE WHEN checks if the subscriber has additional internet or extra services (returns 'Yes' or 'No').
SELECT TOP 10
    p.firstName + ' ' + p.lastName AS FullName,
    c.cityName AS City,
    s.phoneNumber AS PhoneNumber,
    s.contractStartDate AS ContractStartDate,
    s.contractEndDate AS ContractEndDate,
    mno.operatorName AS OperatorName,
    pl.planName AS PlanName,
    CASE WHEN idp.internetDataPlanID IS NOT NULL THEN 'Yes' ELSE 'No' END AS HasAdditionalInternet,
    CASE WHEN EXISTS (
        SELECT 1 FROM dbo.OrderedAdditionalService oas
        WHERE oas.subscriberID = s.subscriberID
    ) THEN 'Yes' ELSE 'No' END AS HasAdditionalServices
FROM dbo.Subscriber s
JOIN dbo.Person p ON s.personID = p.personID
JOIN dbo.City c ON p.cityID = c.cityID
JOIN dbo.[Plan] pl ON s.planID = pl.planID
JOIN dbo.MobileNetworkOperator mno ON pl.operatorID = mno.operatorID
LEFT JOIN dbo.InternetDataPlan idp ON pl.internetDataPlanID = idp.internetDataPlanID
ORDER BY NEWID();

-- 9. Top 5 subscribers by number of calls made within Lithuania in October 2025.
-- We assume internal calls have no 'recipientCountry' (IS NULL).
-- We filter by the specific date range for October 2025.
SELECT TOP 5
    p.firstName + ' ' + p.lastName AS FullName,
    COUNT(p2p.connectionStart) AS CallCount
FROM dbo.P2PConnection p2p
JOIN dbo.Subscriber s ON p2p.subscriberID = s.subscriberID
JOIN dbo.Person p ON s.personID = p.personID
WHERE p2p.recipientCountry IS NULL
  AND p2p.connectionStart >= '2025-10-01'
  AND p2p.connectionStart < '2025-11-01'
GROUP BY p.firstName, p.lastName
ORDER BY CallCount DESC;

-- 10. Find the most popular foreign country by number of calls.
-- TOP 1 WITH TIES means if multiple countries have the same max number of calls, all of them are returned.
SELECT TOP 1 WITH TIES
    c.countryName AS CountryName,
    COUNT(p2p.recipientCountry) AS CallCount
FROM dbo.P2PConnection p2p
JOIN dbo.Country c ON p2p.recipientCountry = c.countryCode
GROUP BY c.countryName
ORDER BY CallCount DESC;