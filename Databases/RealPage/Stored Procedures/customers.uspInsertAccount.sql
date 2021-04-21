SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--DROP PROCEDURE uspInsertAccount
CREATE PROCEDURE [customers].[uspInsertAccount]
AS BEGIN 
----------------------------------------------------------------------------------------------------
-- Database  Name    : CUSTOMERS
-- Procedure Name    : uspInsertAccount
-- Description       : This procedure loads accounts(could be either a site or a pmc)
--                   : into the CUSTOMERS.dbo.Accounts table.
--                   : step 1 : load all properties as accounts. 
--                   : step 2 : load all companies as accounts.
-- Input Parameters  : none so far
-- 
-- OUTPUT            : none 
-- Code Example      : EXEC CUSTOMERS.DBO.uspInsertAccount
-- Time Estimate     : 6-7 minutes approx
----------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : MIS
--------------------------------------------------------------------------------
--BEFORE (PRIOR TO 11-JAN-2007): 
--A WAS FOR COMPANY
--B WAS FOR PROPERTY
--C WAS FOR ACCOUNT. 
--------------------------------------------------------------------------------
--NOW AS OF 11-JAN-2007
--C IS FOR COMPANY
--P IS FOR PROPERTY
--A IS FOR ACCOUNT
--------------------------------------------------------------------------------
--Modifications : 
--29-JAN-2007 - added a query to load sites of pmcs that have 
-- valid active contracts (site do not have contracts). 
--29-JAN-2007 - added a join to siebelordersetup table to ensure
--that accounts get created for sites that have active contracts.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------
--DECLARE VARIABLES TO STORE IDGENERATOR VALUES : 
DECLARE @LBI_AccountIDSeq                BIGINT
DECLARE @LC_TypeIndicator         CHAR(1)
DECLARE @LVC_SiebelRowID          VARCHAR(15)

--DECLARE VARIABLES TO STORE Account NFORMATION : 
DECLARE @LC_PMCIDSeq              CHAR(11)
DECLARE @LVC_PropertyName          VARCHAR(100)
DECLARE @LBI_DatabaseID           BIGINT
DECLARE @LVC_SiebelID             VARCHAR(50)
DECLARE @LDT_PropertyCreatedDate   DATETIME
DECLARE @LDT_PropertyModifiedDate  DATETIME
DECLARE @LBI_UnitCount             BIGINT
DECLARE @LN_PPUPercent             NUMERIC(22,7)
DECLARE @LVC_AccountTypeCode       VARCHAR(5)
DECLARE @LBT_BillToParentFlag      BIT 
DECLARE @LBT_ShipToParentFlag      BIT
DECLARE @LVC_EpicorCustomerCode    VARCHAR(8)
DECLARE @LDT_StartDate             DATETIME
DECLARE @LDT_EndDate               DATETIME
DECLARE @LC_PropertyIDSeq         CHAR(11)
DECLARE @BT_ActiveFlag            BIT
SET NOCOUNT ON 
----------------------------------------------------------------------------------------------------------------------------------------
--LOAD ALL COMPANIES(PMCS) 
--where the company exists as an 'Account' on the siebel order.

--SELECT * FROM CUSTOMERS.DBO.COMPANY (NOLOCK) 
----------------------------------------------------------------------------------------------------------------------------------------
DECLARE AccountCursor_ToLoadProperties SCROLL CURSOR FOR 
SELECT DISTINCT
       'A'                              AS [TypeIndicator] --P for Property
      ,PROP.IDSeq                       AS [PropertyIDSeq]
      ,PROP.[SiebelRowID]               AS [SiebelRowID]
      ,PROP.[SiebelID]                  AS [SiebelID]
      ,PROP.[Name]                      AS [PropertyName]
      ,PROP.[SiteMasterID]              AS [DatabaseID]
      ,PROP.[CreatedDate]               AS [PropertyCreateDate]
      ,PROP.[ModifiedDate]              AS [PropertyModifiedDate]
      ,PROP.PMCIDSeq                    AS [PMCIDSeq] 
      ,PROP.Units                       AS [UnitCount] 
      ,PROP.[PPUPercentage]             AS [PPUPercentage]
      ,'APROP'                          AS [AccountTypeCode]
     ,CASE O.X_BILL_TO_PARENT_FLG 
         WHEN 'Y' 
         THEN 1 
         ELSE 0 
      END                              AS [BillToPMCFlag]
     ,CASE O.X_SHIP_TO_PARENT_FLG 
         WHEN 'Y' 
         THEN 1 
         ELSE 0 
         END                           AS [ShipToPMCFlag]
        ,ACCTTRANS.PLATINUM_NUMBER     AS [EpicorCustomerCode]
        ,ACCTTRANS.ACCOUNT_START_DATE  AS [StartDate]
        ,ACCTTRANS.ACCOUNT_END_DATE    AS [EndDate]
     ,CASE O.CUST_STAT_CD 
        WHEN 'Active' 
        THEN 1 
        ELSE 0 
        END                            AS [ActiveFlag]
FROM CUSTOMERS.dbo.[Property] PROP (NOLOCK) --sites that have been billed 
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
  ON PROP.SiebelRowID = O.ROW_ID --to get flags
  COLLATE SQL_Latin1_General_CP1_CI_AS
INNER JOIN  SourceDB.dbo.ACCOUNT_TRANSLATION  ACCTTRANS (NOLOCK)
        ON ACCTTRANS.ONE_SITE_NUMBER = PROP.SiebelID
        COLLATE SQL_Latin1_General_CP1_CI_AS
AND ACCTTRANS.ACCOUNT_END_DATE IS NULL -- TO GET THE LATEST PROPERTY-COMPANY RELATIONSHIP 
--INNER JOIN SourceDB.dbo.[SiebelOrderSetup] BILLEDSITES (NOLOCK) --added on 29-JAN-07
--    ON BILLEDSITES.Sieb77SiteRowID COLLATE SQL_Latin1_General_CP1_CI_AS = O.ROW_ID
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.[Account] ACCT (NOLOCK) 
                WHERE PROP.SiebelRowID = ACCT.SiebelRowID)

--Open a cursor :
OPEN AccountCursor_ToLoadProperties 
FETCH  AccountCursor_ToLoadProperties INTO
 @LC_TypeIndicator
,@LC_PropertyIDSeq
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_PropertyName
,@LBI_DatabaseID
,@LDT_PropertyCreatedDate
,@LDT_PropertyModifiedDate
,@LC_PMCIDSeq
,@LBI_UnitCount
,@LN_PPUPercent
,@LVC_AccountTypeCode
,@LBT_BillToParentFlag
,@LBT_ShipToParentFlag
,@LVC_EpicorCustomerCode
,@LDT_StartDate
,@LDT_EndDate
,@BT_ActiveFlag

WHILE @@FETCH_STATUS = 0
BEGIN
--GET A NEW ID : 
SELECT @LBI_AccountIDSeq = 
                  MAX(IDSeq)+1 FROM CUSTOMERS.DBO.IDGenerator
                  WHERE TypeIndicator = @LC_TypeIndicator
UPDATE G
SET IDSeq = @LBI_AccountIDSeq
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

--NOW LOAD [Property]TABLE :
INSERT INTO [CUSTOMERS].[dbo].[Account]
           ([IDSeq]
           ,[AccountTypeCode]
           ,[CompanyIDSeq]
           ,[PropertyIDSeq]
           ,[SiteMasterID]
           ,[SiebelRowID]
           ,[EpicorCustomerCode]
           ,[StartDate]
           ,[EndDate]
           ,[ActiveFlag]
           ,[BillToPMCFlag]
           ,[ShipToPMCFlag]
           ,[CreatedBy]
           ,[ModifiedBy]
           ,[CreatedDate]
           ,[ModifiedDate]
           ,[SiebelID])
SELECT DISTINCT 
          (SELECT [IDGeneratorSeq] 
            FROM CUSTOMERS.DBO.IDGenerator G
            WHERE IDSeq = @LBI_AccountIDSeq
            AND TypeIndicator = @LC_TypeIndicator
           ) AS [IDSeq]
           ,@LVC_AccountTypeCode                   AS [AccountTypeCode]
           ,@LC_PMCIDSeq                           AS [CompanyIDSeq]
           ,@LC_PropertyIDSeq                      AS [PropertyIDSeq]
           ,@LBI_DatabaseID                        AS [SiteMasterID]
           ,@LVC_SiebelRowID                       AS [SiebelRowID]
           ,@LVC_EpicorCustomerCode                AS [EpicorCustomerCode]
           ,@LDT_StartDate                         AS [StartDate]
           ,@LDT_EndDate                           AS [EndDate]
           ,@BT_ActiveFlag                         AS [ActiveFlag]
           ,@LBT_BillToParentFlag                  AS [BillToPMCFlag]
           ,@LBT_ShipToParentFlag                  AS [ShipToPMCFlag]
           ,NULL                                   AS [CreatedBy]
           ,NULL                                   AS [ModifiedBy]
           ,@LDT_PropertyCreatedDate               AS [CreatedDate]
           ,@LDT_PropertyModifiedDate              AS [ModifiedDate]
           ,@LVC_SiebelID                          AS [SiebelID]
WHERE NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.[Account] ACCT (NOLOCK)
                  WHERE ACCT.[SiebelRowID]= @LVC_SiebelRowID) --don't reinsert the same company again.

FETCH NEXT FROM AccountCursor_ToLoadProperties INTO  
 @LC_TypeIndicator
,@LC_PropertyIDSeq
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_PropertyName
,@LBI_DatabaseID
,@LDT_PropertyCreatedDate
,@LDT_PropertyModifiedDate
,@LC_PMCIDSeq
,@LBI_UnitCount
,@LN_PPUPercent
,@LVC_AccountTypeCode
,@LBT_BillToParentFlag
,@LBT_ShipToParentFlag
,@LVC_EpicorCustomerCode
,@LDT_StartDate
,@LDT_EndDate
,@BT_ActiveFlag

END 
CLOSE AccountCursor_ToLoadProperties
DEALLOCATE AccountCursor_ToLoadProperties
--***********************************************************************************
---DECLARE ANOTHER CURSOR TO Companies in the account table
--***********************************************************************************
DECLARE AccountCursor_ToLoadCompanies SCROLL CURSOR FOR 
SELECT DISTINCT
       'A'                              AS [TypeIndicator] --P for Property
      ,COM.IDSeq                        AS [CompanyIDSeq]
      ,COM.[SiebelRowID]                AS [SiebelRowID]
      ,COM.[SiebelID]                   AS [SiebelID]
      ,COM.[Name]                       AS [CompanyName]
      ,COM.[SiteMasterID]               AS [DatabaseID]
      ,COM.[CreatedDate]                AS [CompanyCreateDate]
      ,COM.[ModifiedDate]               AS [CompanyModifiedDate]
      ,NULL                             AS [PMCIDSeq] 
      ,NULL                             AS [UnitCount] --?? units of a pmc
      ,NULL                             AS [PPUPercentage]--??
      ,'AHOFF'                          AS [AccountTypeCode]
     ,CASE O.X_BILL_TO_PARENT_FLG 
         WHEN 'Y' 
         THEN 1 
         ELSE 0 
      END                              AS [BillToPMCFlag]
     ,CASE O.X_SHIP_TO_PARENT_FLG 
         WHEN 'Y' 
         THEN 1 
         ELSE 0 
         END                           AS [ShipToPMCFlag]
        ,ACCTTRANS.PLATINUM_NUMBER     AS [EpicorCustomerCode]
        ,ACCTTRANS.ACCOUNT_START_DATE  AS [StartDate]
        ,ACCTTRANS.ACCOUNT_END_DATE    AS [EndDate]
     ,CASE O.CUST_STAT_CD 
        WHEN 'Active' 
        THEN 1 
        ELSE 0 
        END                            AS [ActiveFlag]
FROM CUSTOMERS.dbo.[Company] COM (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
  ON COM.SiebelRowID = O.ROW_ID --to get flags
  COLLATE SQL_Latin1_General_CP1_CI_AS
INNER JOIN  SourceDB.dbo.ACCOUNT_TRANSLATION  ACCTTRANS (NOLOCK)
        ON ACCTTRANS.ONE_SITE_NUMBER = COM.SiebelID
        COLLATE SQL_Latin1_General_CP1_CI_AS
AND ACCTTRANS.ACCOUNT_END_DATE IS NULL -- TO GET THE LATEST PROPERTY-COMPANY RELATIONSHIP 
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.[Account] ACCT (NOLOCK) 
                   WHERE COM.SiebelRowID = ACCT.SiebelRowID
                   AND ACCT.AccountTypeCode = 'AHOFF')

--Open a cursor :
OPEN AccountCursor_ToLoadCompanies 
FETCH  AccountCursor_ToLoadCompanies INTO
 @LC_TypeIndicator
,@LC_PropertyIDSeq --THIS IS ACTUALLY COMPANY.IDSEQ
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_PropertyName
,@LBI_DatabaseID
,@LDT_PropertyCreatedDate
,@LDT_PropertyModifiedDate
,@LC_PMCIDSeq --IT WILL BE NULL HERE FOR COMPANY 
,@LBI_UnitCount
,@LN_PPUPercent
,@LVC_AccountTypeCode
,@LBT_BillToParentFlag
,@LBT_ShipToParentFlag
,@LVC_EpicorCustomerCode
,@LDT_StartDate
,@LDT_EndDate
,@BT_ActiveFlag

WHILE @@FETCH_STATUS = 0
BEGIN
--GET A NEW ID : 
SELECT @LBI_AccountIDSeq = 
                  MAX(IDSeq)+1 FROM CUSTOMERS.DBO.IDGenerator
                  WHERE TypeIndicator = @LC_TypeIndicator
UPDATE G
SET IDSeq = @LBI_AccountIDSeq
FROM CUSTOMERS.DBO.IDGenerator G 
WHERE TypeIndicator = @LC_TypeIndicator

--NOW LOAD [Property]TABLE :
INSERT INTO [CUSTOMERS].[dbo].[Account]
           ([IDSeq]
           ,[AccountTypeCode]
           ,[CompanyIDSeq]
           ,[PropertyIDSeq]
           ,[SiteMasterID]
           ,[SiebelRowID]
           ,[EpicorCustomerCode]
           ,[StartDate]
           ,[EndDate]
           ,[ActiveFlag]
           ,[BillToPMCFlag]
           ,[ShipToPMCFlag]
           ,[CreatedBy]
           ,[ModifiedBy]
           ,[CreatedDate]
           ,[ModifiedDate]
           ,[SiebelID])
SELECT DISTINCT 
          (SELECT [IDGeneratorSeq] 
            FROM CUSTOMERS.DBO.IDGenerator G
            WHERE IDSeq = @LBI_AccountIDSeq
            AND TypeIndicator = @LC_TypeIndicator
           ) AS [IDSeq]
           ,'AHOFF'                                AS [AccountTypeCode]
           ,@LC_PropertyIDSeq                      AS [CompanyIDSeq]
           ,NULL                                   AS [PropertyIDSeq] --SHOULD BE NULL BECAUSE WE ARE ONLY INSERTING COMPANY HERE
           ,@LBI_DatabaseID                        AS [SiteMasterID]
           ,@LVC_SiebelRowID                       AS [SiebelRowID]
           ,@LVC_EpicorCustomerCode                AS [EpicorCustomerCode]
           ,@LDT_StartDate                         AS [StartDate]
           ,@LDT_EndDate                           AS [EndDate]
           ,@BT_ActiveFlag                         AS [ActiveFlag]
           ,@LBT_BillToParentFlag                  AS [BillToPMCFlag]
           ,@LBT_ShipToParentFlag                  AS [ShipToPMCFlag]
           ,NULL                                   AS [CreatedBy]
           ,NULL                                   AS [ModifiedBy]
           ,@LDT_PropertyCreatedDate               AS [CreatedDate]
           ,@LDT_PropertyModifiedDate              AS [ModifiedDate]
           ,@LVC_SiebelID                          AS [SiebelID]
FROM CUSTOMERS.dbo.[Company] COM (NOLOCK) --sites that have been billed 
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
  ON COM.SiebelRowID = O.ROW_ID --to get flags
  COLLATE SQL_Latin1_General_CP1_CI_AS
INNER JOIN  SourceDB.dbo.ACCOUNT_TRANSLATION  ACCTTRANS (NOLOCK)
        ON ACCTTRANS.ONE_SITE_NUMBER = COM.SiebelID
        COLLATE SQL_Latin1_General_CP1_CI_AS
AND ACCTTRANS.ACCOUNT_END_DATE IS NULL  --get the latest pmc-site relationship.
WHERE COM.SiebelRowID = @LVC_SiebelRowID 
   AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.[Account] ACCT (NOLOCK) 
                   WHERE COM.SiebelRowID = ACCT.SiebelRowID
                   AND ACCT.AccountTypeCode = 'AHOFF')

FETCH NEXT FROM AccountCursor_ToLoadCompanies INTO  
 @LC_TypeIndicator
,@LC_PropertyIDSeq
,@LVC_SiebelRowID
,@LVC_SiebelID
,@LVC_PropertyName
,@LBI_DatabaseID
,@LDT_PropertyCreatedDate
,@LDT_PropertyModifiedDate
,@LC_PMCIDSeq
,@LBI_UnitCount
,@LN_PPUPercent
,@LVC_AccountTypeCode
,@LBT_BillToParentFlag
,@LBT_ShipToParentFlag
,@LVC_EpicorCustomerCode
,@LDT_StartDate
,@LDT_EndDate
,@BT_ActiveFlag

END 
CLOSE AccountCursor_ToLoadCompanies
DEALLOCATE AccountCursor_ToLoadCompanies
END 

GO
