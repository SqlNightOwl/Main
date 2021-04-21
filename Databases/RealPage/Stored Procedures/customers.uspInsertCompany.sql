SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--DROP PROCEDURE uspInsertCompany
CREATE PROCEDURE [customers].[uspInsertCompany]
AS BEGIN 
----------------------------------------------------------------------------------------------------
-- Database  Name    : CUSTOMERS
-- Procedure Name    : uspInsertCompany
-- Description       : This procedure loads customers into Company Table
--                   : scenario 1 : when an order is billed to a pmc and pmc is saved
--                   : as the 'account' on the order. 
--                   : scenario 2 : when an order is billed to a pmc and pmc is saved 
--                   : as the pmc on the order.
-- Input Parameters  : none so far
-- 
-- OUTPUT            : none 
-- Code Example      : EXEC CUSTOMERS.DBO.uspInsertCompany
-- Time Estimate     : 2-3 minutes
----------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : MIS
-------------------------------------------------------------
--BEFORE (PRIOR TO 11-JAN-2007): 
--A WAS FOR COMPANY
--B WAS FOR PROPERTY
--C WAS FOR ACCOUNT. 
-------------------------------------------------------------
--NOW AS OF 11-JAN-2007
--C IS FOR COMPANY
--P IS FOR PROPERTY
--A IS FOR ACCOUNT
-------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--DECLARE VARIABLES TO STORE IDGENERATOR VALUES : 
DECLARE @LBI_IDSeq                BIGINT
DECLARE @LC_TypeIndicator         CHAR(1)
DECLARE @LVC_SiebelRowID          VARCHAR(15)

--DECLARE VARIABLES TO STORE COMPANY INFORMATION : 
DECLARE @LC_CompanyIDSeq          CHAR(11)
DECLARE @LVC_CompanyName          VARCHAR(100)
DECLARE @LBI_DatabaseID           BIGINT
DECLARE @LVC_EpicorCustomerCode   VARCHAR(8)
DECLARE @LVC_SiebelID             VARCHAR(50)
DECLARE @LDT_CompanyCreatedDate   DATETIME
DECLARE @LDT_CompanyModifiedDate  DATETIME

SET NOCOUNT ON 
----------------------------------------------------------------------------------------------------------------------------------------
--LOAD ALL COMPANIES(PMCS) 
--where the company exists as an 'Account' on the siebel order.

--SELECT * FROM CUSTOMERS.DBO.COMPANY (NOLOCK) 
----------------------------------------------------------------------------------------------------------------------------------------
DECLARE CompanyCursor SCROLL CURSOR FOR 
SELECT DISTINCT
       'C'            AS [TypeIndicator] --C for Company
      ,SITE.ROW_ID    AS [SiebelRowID]
      ,SITE.LOC       AS [SiebelID]
      ,SITE.NAME      AS [CompanyName]
      ,SX.ATTRIB_36 AS [DatabaseID]
      ,SITE.CREATED   AS [CompanyCreateDate]
      ,SITE.LAST_UPD  AS [CompanyModifiedDate]
--SELECT COUNT(*)
FROM SourceDB.dbo.S_ORG_EXT AS SITE (NOLOCK)
INNER JOIN SourceDB.dbo.[SiebelOrderSetup] BILLEDSITES (NOLOCK)
ON BILLEDSITES.Sieb77SiteRowID COLLATE SQL_Latin1_General_CP1_CI_AS = SITE.ROW_ID 
LEFT OUTER JOIN [SourceDB].[dbo].S_ORG_EXT_X  SX (NOLOCK) 
ON SITE.ROW_ID = SX.PAR_ROW_ID --to get database id
WHERE SITE.OU_TYPE_CD IN ('Property Management Company', 'Regional Office')
--WHERE SITE.LOC = '1055210'

--Open a cursor :
OPEN CompanyCursor 
FETCH  CompanyCursor INTO
 @LC_TypeIndicator
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_CompanyName
,@LBI_DatabaseID
,@LDT_CompanyCreatedDate
,@LDT_CompanyModifiedDate

WHILE @@FETCH_STATUS = 0
BEGIN
--GET A NEW ID : 
SELECT @LBI_IDSeq = MAX(IDSeq)+1 FROM CUSTOMERS.DBO.IDGenerator
UPDATE G
SET IDSeq = @LBI_IDSeq
--SiebelRowID = @LVC_SiebelRowID,
--SiebelID  = @LVC_SiebelID
FROM CUSTOMERS.DBO.IDGenerator G 
WHERE TypeIndicator = @LC_TypeIndicator

/*
DECLARE @LBI_IDGenSeq INT 
DECLARE @LVC_UniqueInvoiceIDSeq VARCHAR(22)
select @LBI_IDGenSeq = max(IDSeq)+1 from CUSTOMERS.DBO.IDGenerator
update CUSTOMERS.DBO.IDGenerator set IDSeq = @LBI_IDGenSeq
*/
--NOW LOAD COMPANY TABLE :
INSERT INTO [CUSTOMERS].[dbo].[Company]
           ([IDSeq]
           ,[SiteMasterID]
           ,[Name]
           ,[PMCFlag]
           ,[OwnerFlag]
           ,[CreatedBy]
           ,[ModifiedBy]
           ,[CreatedDate]
           ,[ModifiedDate]
           ,[SiebelRowID]
           ,[EpicorCustomerCode]
           ,[PriceTerm]
           ,[SiebelID])

SELECT 
          (SELECT [IDGeneratorSeq] 
            FROM CUSTOMERS.DBO.IDGenerator G
            WHERE IDSeq = @LBI_IDSeq
            AND TypeIndicator = @LC_TypeIndicator
--			AND G.SiebelRowID = @LVC_SiebelRowID 
           ) AS [IDSeq]
           ,@LBI_DatabaseID              AS [SiteMasterID]
           ,@LVC_CompanyName             AS [Name]
           ,1                            AS [PMCFlag]
           ,0                            AS [OwnerFlag]
           ,NULL                         AS [CreatedBy]
           ,NULL                         AS [ModifiedBy]
           ,@LDT_CompanyCreatedDate      AS [CreatedDate]
           ,@LDT_CompanyModifiedDate     AS [ModifiedDate]
           ,@LVC_SiebelRowID             AS [SiebelRowID]
           ,NULL                         AS [EpicorCustomerCode]
           ,NULL                         AS [PriceTerm]
           ,@LVC_SiebelID                AS [SiebelID]
FROM CUSTOMERS.DBO.IDGenerator G (NOLOCK)
--WHERE G.SiebelRowID = @LVC_SiebelRowID
WHERE G.TypeIndicator = @LC_TypeIndicator
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.Company C (NOLOCK)
                  WHERE C.[SiebelRowID]= @LVC_SiebelRowID) --don't reinsert the same company again.


FETCH NEXT FROM CompanyCursor INTO  
@LC_TypeIndicator
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_CompanyName
,@LBI_DatabaseID
,@LDT_CompanyCreatedDate
,@LDT_CompanyModifiedDate

END 
CLOSE CompanyCursor
DEALLOCATE CompanyCursor
--***********************************************************************************
---DECLARE ANOTHER CURSOR TO LOAD REMAINING COMPANIES
--When the orders are sold to a PMC and it is the "pmc" in Siebel OrderSetup 
--***********************************************************************************
DECLARE PMCCursor SCROLL CURSOR FOR 
SELECT DISTINCT
       'C'            AS [TypeIndicator] --C for Company
      ,SITE.ROW_ID    AS [SiebelRowID]
      ,SITE.LOC       AS [SiebelID]
      ,SITE.NAME      AS [CompanyName]
      ,SX.ATTRIB_36 AS [DatabaseID]
      ,SITE.CREATED   AS [CompanyCreateDate]
      ,SITE.LAST_UPD  AS [CompanyModifiedDate]
--SELECT COUNT(*)
FROM SourceDB.dbo.[SiebelOrderSetup] BILLEDTOPMC (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT SITE (NOLOCK) 
ON BILLEDTOPMC.Sieb77PMCRowID = SITE.ROW_ID COLLATE SQL_Latin1_General_CP1_CI_AS
LEFT OUTER JOIN [SourceDB].[dbo].S_ORG_EXT_X  SX (NOLOCK) 
ON SITE.ROW_ID = SX.PAR_ROW_ID --to get database id
LEFT OUTER JOIN CUSTOMERS.DBO.COMPANY C (NOLOCK)
ON C.SiebelRowID = BILLEDTOPMC.Sieb77PMCRowID COLLATE SQL_Latin1_General_CP1_CI_AS
WHERE SITE.OU_TYPE_CD IN ('Property Management Company', 'Regional Office')
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.COMPANY C (NOLOCK)
               WHERE C.SiebelRowID = BILLEDTOPMC.Sieb77PMCRowID COLLATE SQL_Latin1_General_CP1_CI_AS)
--and BILLEDTOPMC.Sieb77PMCRowID = '1+12+1005'

--Open a cursor :
OPEN PMCCursor 
FETCH  PMCCursor INTO
 @LC_TypeIndicator
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_CompanyName
,@LBI_DatabaseID
,@LDT_CompanyCreatedDate
,@LDT_CompanyModifiedDate

WHILE @@FETCH_STATUS = 0
BEGIN
--GET A NEW ID : 
SELECT @LBI_IDSeq = MAX(IDSeq)+1 FROM CUSTOMERS.DBO.IDGenerator
UPDATE G
SET IDSeq = @LBI_IDSeq
--SiebelRowID = @LVC_SiebelRowID,
--SiebelID  = @LVC_SiebelID
FROM CUSTOMERS.DBO.IDGenerator G 
WHERE TypeIndicator = @LC_TypeIndicator

--PRINT @LBI_IDSeq
/*
DECLARE @LBI_IDGenSeq INT 
DECLARE @LVC_UniqueInvoiceIDSeq VARCHAR(22)
select @LBI_IDGenSeq = max(IDSeq)+1 from CUSTOMERS.DBO.IDGenerator
update CUSTOMERS.DBO.IDGenerator set IDSeq = @LBI_IDGenSeq
*/
----NOW LOAD COMPANY TABLE :
INSERT INTO [CUSTOMERS].[dbo].[Company]
           ([IDSeq]
           ,[SiteMasterID]
           ,[Name]
           ,[PMCFlag]
           ,[OwnerFlag]
           ,[CreatedBy]
           ,[ModifiedBy]
           ,[CreatedDate]
           ,[ModifiedDate]
           ,[SiebelRowID]
           ,[EpicorCustomerCode]
           ,[PriceTerm]
           ,[SiebelID])

SELECT 
          (SELECT [IDGeneratorSeq] 
            FROM CUSTOMERS.DBO.IDGenerator G
            WHERE IDSeq = @LBI_IDSeq
            AND TypeIndicator = @LC_TypeIndicator
--			AND G.SiebelRowID = @LVC_SiebelRowID 
           ) AS [IDSeq]
           ,@LBI_DatabaseID              AS [SiteMasterID]
           ,@LVC_CompanyName             AS [Name]
           ,1                            AS [PMCFlag]
           ,0                            AS [OwnerFlag]
           ,NULL                         AS [CreatedBy]
           ,NULL                         AS [ModifiedBy]
           ,@LDT_CompanyCreatedDate      AS [CreatedDate]
           ,@LDT_CompanyModifiedDate     AS [ModifiedDate]
           ,@LVC_SiebelRowID             AS [SiebelRowID]
           ,NULL                         AS [EpicorCustomerCode]
           ,NULL                         AS [PriceTerm]
           ,@LVC_SiebelID                AS [SiebelID]
FROM CUSTOMERS.DBO.IDGenerator G (NOLOCK)
--WHERE G.SiebelRowID = @LVC_SiebelRowID
WHERE G.TypeIndicator = @LC_TypeIndicator
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.Company C (NOLOCK)
                  WHERE C.[SiebelRowID]= @LVC_SiebelRowID) --don't reinsert the same company again.


FETCH NEXT FROM PMCCursor INTO  
@LC_TypeIndicator
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_CompanyName
,@LBI_DatabaseID
,@LDT_CompanyCreatedDate
,@LDT_CompanyModifiedDate

END 
CLOSE PMCCursor
DEALLOCATE PMCCursor

--***********************************************************************************
---DECLARE ANOTHER CURSOR TO LOAD Self Managed Sites
--There will be one record in Company table.
--***********************************************************************************
DECLARE SelfManagedSiteCursor SCROLL CURSOR FOR 
SELECT DISTINCT
       'C'            AS [TypeIndicator] --C for Company
      ,SITE.ROW_ID    AS [SiebelRowID]
      ,SITE.LOC       AS [SiebelID]
      ,SITE.NAME      AS [CompanyName]
      ,SX.ATTRIB_36 AS [DatabaseID]
      ,SITE.CREATED   AS [CompanyCreateDate]
      ,SITE.LAST_UPD  AS [CompanyModifiedDate]
--SELECT COUNT(*)
FROM SourceDB.dbo.[SiebelOrderSetup] BILLEDSITES (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT SITE (NOLOCK) 
ON BILLEDSITES.Sieb77PMCRowID = SITE.ROW_ID COLLATE SQL_Latin1_General_CP1_CI_AS
LEFT OUTER JOIN [SourceDB].[dbo].S_ORG_EXT_X  SX (NOLOCK) 
ON SITE.ROW_ID = SX.PAR_ROW_ID --to get database id
LEFT OUTER JOIN CUSTOMERS.DBO.COMPANY C (NOLOCK)
ON C.SiebelRowID = BILLEDSITES.Sieb77PMCRowID COLLATE SQL_Latin1_General_CP1_CI_AS
WHERE SITE.OU_TYPE_CD IN ('Self Managed Site')--1683
AND SITE.PAR_OU_ID IS NULL 
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.COMPANY C (NOLOCK)
               WHERE C.SiebelRowID = BILLEDSITES.Sieb77PMCRowID 
COLLATE SQL_Latin1_General_CP1_CI_AS)
--and BILLEDSITES.PMCID = '1054992'
--1464

--Open a cursor :
OPEN SelfManagedSiteCursor 
FETCH  SelfManagedSiteCursor INTO
 @LC_TypeIndicator
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_CompanyName
,@LBI_DatabaseID
,@LDT_CompanyCreatedDate
,@LDT_CompanyModifiedDate

WHILE @@FETCH_STATUS = 0
BEGIN
--GET A NEW ID : 
SELECT @LBI_IDSeq = MAX(IDSeq)+1 FROM CUSTOMERS.DBO.IDGenerator
UPDATE G
SET IDSeq = @LBI_IDSeq
--SiebelRowID = @LVC_SiebelRowID,
--SiebelID  = @LVC_SiebelID
FROM CUSTOMERS.DBO.IDGenerator G 
WHERE TypeIndicator = @LC_TypeIndicator

--PRINT @LBI_IDSeq
/*
DECLARE @LBI_IDGenSeq INT 
DECLARE @LVC_UniqueInvoiceIDSeq VARCHAR(22)
select @LBI_IDGenSeq = max(IDSeq)+1 from CUSTOMERS.DBO.IDGenerator
update CUSTOMERS.DBO.IDGenerator set IDSeq = @LBI_IDGenSeq
*/
----NOW LOAD COMPANY TABLE :
INSERT INTO [CUSTOMERS].[dbo].[Company]
           ([IDSeq]
           ,[SiteMasterID]
           ,[Name]
           ,[PMCFlag]
           ,[OwnerFlag]
           ,[CreatedBy]
           ,[ModifiedBy]
           ,[CreatedDate]
           ,[ModifiedDate]
           ,[SiebelRowID]
           ,[EpicorCustomerCode]
           ,[PriceTerm]
           ,[SiebelID])

SELECT 
          (SELECT [IDGeneratorSeq] 
            FROM CUSTOMERS.DBO.IDGenerator G
            WHERE IDSeq = @LBI_IDSeq
            AND TypeIndicator = @LC_TypeIndicator
--			AND G.SiebelRowID = @LVC_SiebelRowID 
           ) AS [IDSeq]
           ,@LBI_DatabaseID              AS [SiteMasterID]
           ,@LVC_CompanyName             AS [Name]
           ,1                            AS [PMCFlag]
           ,0                            AS [OwnerFlag]
           ,NULL                         AS [CreatedBy]
           ,NULL                         AS [ModifiedBy]
           ,@LDT_CompanyCreatedDate      AS [CreatedDate]
           ,@LDT_CompanyModifiedDate     AS [ModifiedDate]
           ,@LVC_SiebelRowID             AS [SiebelRowID]
           ,NULL                         AS [EpicorCustomerCode]
           ,NULL                         AS [PriceTerm]
           ,@LVC_SiebelID                AS [SiebelID]
FROM CUSTOMERS.DBO.IDGenerator G (NOLOCK)
--WHERE G.SiebelRowID = @LVC_SiebelRowID
WHERE G.TypeIndicator = @LC_TypeIndicator
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.Company C (NOLOCK)
                  WHERE C.[SiebelRowID]= @LVC_SiebelRowID) --don't reinsert the same company again.

FETCH NEXT FROM SelfManagedSiteCursor INTO  
@LC_TypeIndicator
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_CompanyName
,@LBI_DatabaseID
,@LDT_CompanyCreatedDate
,@LDT_CompanyModifiedDate

END 
CLOSE SelfManagedSiteCursor
DEALLOCATE SelfManagedSiteCursor
END 

GO
