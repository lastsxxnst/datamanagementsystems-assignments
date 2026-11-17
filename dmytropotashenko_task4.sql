-- 1. Add 'discount' column to Subscriber table.
-- Uses DECIMAL(3,2), NOT NULL, and a default value of 0.00.
ALTER TABLE dbo.Subscriber
ADD discount DECIMAL(3,2) NOT NULL
    CONSTRAINT DF_Subscriber_discount DEFAULT 0.00;
GO

-- 2. Add 'email' column to Person table.
-- Allows NULL values as requested.
ALTER TABLE dbo.Person
ADD email VARCHAR(50) NULL;
GO

-- 3. Create the 'Domain' table.
CREATE TABLE dbo.Domain (
    domainID INT IDENTITY(1,1) NOT NULL,
    domainName VARCHAR(15) NOT NULL,
    CONSTRAINT PK_Domain PRIMARY KEY (domainID)
);
GO

-- 4. Insert the specified records into the Domain table.
INSERT INTO dbo.Domain (domainName)
VALUES
    ('gmail.com'),
    ('yahoo.com'),
    ('hotmail.com'),
    ('eif.viko.lt');
GO

-- 5. Update Person table: assign a random domain to each person.
-- Uses a CTE with ROW_NUMBER() to map each person to exactly one random domain.
WITH RandomDomains AS (
    SELECT
        p.personID,
        LOWER(p.firstName + '.' + p.lastName + '@' + d.domainName) AS NewEmail
    FROM dbo.Person p
    CROSS JOIN dbo.Domain d
),
AssignedEmails AS (
    SELECT
        personID,
        NewEmail,
        ROW_NUMBER() OVER(PARTITION BY personID ORDER BY NEWID()) as rn
    FROM RandomDomains
)
UPDATE p
SET p.email = ae.NewEmail
FROM dbo.Person p
JOIN AssignedEmails ae ON p.personID = ae.personID
WHERE ae.rn = 1;
GO

-- 6. Create the 'MobilePhone' table.
CREATE TABLE dbo.MobilePhone (
    mobTelID INT IDENTITY(1,1) NOT NULL,
    manufacturer VARCHAR(15) NOT NULL,
    model VARCHAR(30) NOT NULL,
    price FLOAT  NOT NULL,
    monthlyPrice FLOAT NOT NULL,
    CONSTRAINT PK_MobilePhone PRIMARY KEY (mobTelID)
);
GO

-- 7. Add 'mobTelID' column to Subscriber table.
-- Allows NULL because not all subscribers buy a phone.
ALTER TABLE dbo.Subscriber
ADD mobTelID INT NULL;
GO

-- 8. Add the foreign key relationship.
ALTER TABLE dbo.Subscriber
ADD CONSTRAINT FK_Subscriber_MobilePhone
FOREIGN KEY (mobTelID) REFERENCES dbo.MobilePhone(mobTelID);
GO

-- 9. Import data from a .txt file using BULK INSERT.
-- Assumes the file is comma-separated, has a header row, and is located in the SQL Server Backup folder.
BULK INSERT dbo.MobilePhone
FROM 'C:\Program Files\Microsoft SQL Server\MSSQL17.MSSQLSERVER\MSSQL\Backup\mobile-phones.txt'
WITH (
    FIELDTERMINATOR = ',',
    ROWTERMINATOR = '0x0a',
    FIRSTROW = 2,
    CODEPAGE = '65001',
    KEEPNULLS
);
GO

-- 10. Update Subscriber table: assign a random phone to active subscribers.
-- Only subscribers with NULL contractEndDate get a phone (they purchased one).
WITH RandomPhones AS (
    SELECT
        s.subscriberID,
        mp.mobTelID AS NewMobTelID
    FROM dbo.Subscriber s
    CROSS JOIN dbo.MobilePhone mp
    WHERE s.contractEndDate IS NULL
),
AssignedPhones AS (
    SELECT
        subscriberID,
        NewMobTelID,
        ROW_NUMBER() OVER(PARTITION BY subscriberID ORDER BY NEWID()) as rn
    FROM RandomPhones
)
UPDATE s
SET s.mobTelID = ap.NewMobTelID
FROM dbo.Subscriber s
JOIN AssignedPhones ap ON s.subscriberID = ap.subscriberID
WHERE ap.rn = 1;
GO