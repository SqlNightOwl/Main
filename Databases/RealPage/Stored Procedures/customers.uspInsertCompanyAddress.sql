SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--DROP PROCEDURE uspInsertCompanyAddress
CREATE PROCEDURE [customers].[uspInsertCompanyAddress]
AS BEGIN 
----------------------------------------------------------------------------------------------------
-- Database  Name    : CUSTOMERS
-- Procedure Name    : uspInsertCompanyAddress
-- Description       : This procedure loads following addresses in Customers.dbo.Address table
--                   : step 1 : Get all companies
--                   : step 2 : Load Primary mailing address of the company
--                   : step 3 : Load Billing address of the company
--                   : step 4 : Load Shipping address of the company
-- Input Parameters  : none so far
-- 
-- OUTPUT            : none 
-- Code Example      : EXEC CUSTOMERS.DBO.uspInsertCompanyAddress
-- Time Estimate     : 5 minutes approx
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
DECLARE @LC_CompanyIDSeq         CHAR(11)
DECLARE @LVC_SiebelID             VARCHAR(50)
DECLARE @LVC_SiebelRowID          VARCHAR(15)
DECLARE @LBI_SiteMasterID           BIGINT

SET NOCOUNT ON 
----------------------------------------------------------------------------------------------------------------------------------------
--First select all companies 
--This cursor will help load primary mail, shipping and billing addresses. 
----------------------------------------------------------------------------------------------------------------------------------------
DECLARE CompanyCursor SCROLL CURSOR FOR 
SELECT DISTINCT 
       C.[IDSeq]                     AS [CompanyIDSeq]
      ,C.[SiebelID]                  AS [SiebelID]
      ,C.[SiebelRowID]               AS [SiebelRowID]
      ,C.[SiteMasterID]              AS [SiteMasterID]
--SELECT COUNT(*)--4995
--SELECT DISTINCT O.OU_TYPE_CD,COUNT(*)
FROM CUSTOMERS.dbo.Company C (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
  ON O.ROW_ID = C.SiebelRowID 
  COLLATE SQL_Latin1_General_CP1_CI_AS --to get only pmcs 
AND O.OU_TYPE_CD 
    IN ('Property Management Company'
         ,'Regional Office'
         ,'Self Managed Site')
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.ADDRESS AD (NOLOCK) 
                 WHERE AD.COMPANYIDSEQ = C.IDSEQ)

--Open a cursor :
OPEN CompanyCursor 
FETCH  CompanyCursor INTO
@LC_CompanyIDSeq
,@LVC_SiebelID
,@LVC_SiebelRowID
,@LBI_SiteMasterID

WHILE @@FETCH_STATUS = 0
BEGIN
------------------------------------------------------------------
--Insert Primary Mailing Addrss of the Company if it does
--not already exist in CUSTOMERS.DBO.ADDRESS table: 
------------------------------------------------------------------
INSERT INTO [CUSTOMERS].[dbo].[Address]
           ([CompanyIDSeq]
           ,[PropertyIDSeq]
           ,[AddressTypeCode]
           ,[AddressLine1]
           ,[AddressLine2]
           ,[City]
           ,[County]
           ,[State]
           ,[Zip]
           ,[PhoneVoice1]
           ,[PhoneVoiceExt1]
           ,[PhoneVoice2]
           ,[PhoneVoiceExt2]
           ,[PhoneFax]
           ,[Email]
           ,[URL]
           ,[CreatedBy]
           ,[ModifiedBy]
           ,[CreateDate]
           ,[ModifiedDate]
           ,[AttentionName]
           ,[GeoCodeFlag]
           ,[GeoCodeMatch]
           ,[Latitude]
           ,[Longitude]
           ,[MSANumber]
           ,[Country]
           ,[Sieb77AddrID]
)

SELECT 
       @LC_CompanyIDSeq                 AS [CompanyIDSeq]
       ,NULL                              AS [PropertyIDSeq]
       ,'COM'                             AS [AddressTypeCode]
       ,CA.ADDR                           AS [AddressLine1]
       ,CA.ADDR_LINE_2                    AS [AddressLine2]
       ,CA.CITY                           AS [City]
       ,CA.COUNTY                         AS [County]
       ,CA.STATE                          AS [State]
       ,CA.ZIPCODE                        AS [Zip]
       ,CA.PH_NUM                         AS [PhoneVoice1]
       ,NULL                              AS [PhoneVoiceExt1]
       ,NULL                              AS [PhoneVoice2]
       ,NULL                              AS [PhoneVoiceExt2]
       ,CA.FAX_PH_NUM                     AS [PhoneFax]
       ,NULL                              AS [Email]
       ,NULL                              AS [URL]
       ,NULL                              AS [CreatedBy]
       ,NULL                              AS [ModifiedBy]
       ,CA.CREATED                        AS [CreateDate]
       ,CA.LAST_UPD                       AS [ModifiedDate]
       ,CA.PROVINCE                       AS [AttentionName]
       ,CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END                               AS [GeoCodeFlag]
       ,CA.X_GEOCODE_MATCH                AS [GeoCodeMatch]
       ,CA.X_LATITUDE                     AS [Latitude]
       ,CA.X_LONGITUDE                    AS [Longitude]
       ,CA.X_MSA_NUMBER                   AS [MSANumber]
       ,CA.COUNTRY                        AS [Country]
       ,CA.ROW_ID                         AS [Sieb77AddrID]

--SELECT COUNT(*)--2654
--SELECT DISTINCT O.OU_TYPE_CD
FROM SourceDB.dbo.S_ADDR_ORG CA (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
	ON CA.ROW_ID  = O.PR_ADDR_ID --get primary address only for now
INNER JOIN CUSTOMERS.dbo.Company C (NOLOCK)
	ON O.ROW_ID = C.SiebelRowID 
    COLLATE SQL_Latin1_General_CP1_CI_AS --to get only pmcs 
WHERE O.OU_TYPE_CD IN 
         ('Property Management Company'
          ,'Regional Office'
          ,'Self Managed Site')
AND C.SiebelRowID = @LVC_SiebelRowID
AND C.SiebelID  = @LVC_SiebelID
AND C.IDSeq = @LC_CompanyIDSeq
AND C.SiteMasterID = @LBI_SiteMasterID
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.ADDRESS ADDR (NOLOCK)
                WHERE ADDR.[Sieb77AddrID] = CA.ROW_ID
                COLLATE SQL_Latin1_General_CP1_CI_AS
                AND ADDR.CompanyIDSeq = @LC_CompanyIDSeq
                AND [AddressTypeCode] = 'COM') --do not reinsert the same address for the same account.
------------------------------------------------------------------
--Insert Billing Addrss of the Company if it does
--not already exist in CUSTOMERS.DBO.ADDRESS table: 
------------------------------------------------------------------
INSERT INTO [CUSTOMERS].[dbo].[Address]
           ([CompanyIDSeq]
           ,[PropertyIDSeq]
           ,[AddressTypeCode]
           ,[AddressLine1]
           ,[AddressLine2]
           ,[City]
           ,[County]
           ,[State]
           ,[Zip]
           ,[PhoneVoice1]
           ,[PhoneVoiceExt1]
           ,[PhoneVoice2]
           ,[PhoneVoiceExt2]
           ,[PhoneFax]
           ,[Email]
           ,[URL]
           ,[CreatedBy]
           ,[ModifiedBy]
           ,[CreateDate]
           ,[ModifiedDate]
           ,[AttentionName]
           ,[GeoCodeFlag]
           ,[GeoCodeMatch]
           ,[Latitude]
           ,[Longitude]
           ,[MSANumber]
           ,[Country]
           ,[Sieb77AddrID]
)
SELECT 
       @LC_CompanyIDSeq                 AS [CompanyIDSeq]
       ,NULL                              AS [PropertyIDSeq]
       ,'CBT'                             AS [AddressTypeCode]
       ,CA.ADDR                           AS [AddressLine1]
       ,CA.ADDR_LINE_2                    AS [AddressLine2]
       ,CA.CITY                           AS [City]
       ,CA.COUNTY                         AS [County]
       ,CA.STATE                          AS [State]
       ,CA.ZIPCODE                        AS [Zip]
       ,CA.PH_NUM                         AS [PhoneVoice1]
       ,NULL                              AS [PhoneVoiceExt1]
       ,NULL                              AS [PhoneVoice2]
       ,NULL                              AS [PhoneVoiceExt2]
       ,CA.FAX_PH_NUM                     AS [PhoneFax]
       ,NULL                              AS [Email]
       ,NULL                              AS [URL]
       ,NULL                              AS [CreatedBy]
       ,NULL                              AS [ModifiedBy]
       ,CA.CREATED                        AS [CreateDate]
       ,CA.LAST_UPD                       AS [ModifiedDate]
       ,CA.PROVINCE                       AS [AttentionName]
       ,CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END                               AS [GeoCodeFlag]
       ,CA.X_GEOCODE_MATCH                AS [GeoCodeMatch]
       ,CA.X_LATITUDE                     AS [Latitude]
       ,CA.X_LONGITUDE                    AS [Longitude]
       ,CA.X_MSA_NUMBER                   AS [MSANumber]
       ,CA.COUNTRY                        AS [Country]
       ,CA.ROW_ID                         AS [Sieb77AddrID]
--SELECT COUNT(*)--2654
--SELECT DISTINCT O.OU_TYPE_CD
FROM SourceDB.dbo.S_ADDR_ORG CA (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
	ON CA.ROW_ID  = O.PR_BL_ADDR_ID --get billing address 
INNER JOIN CUSTOMERS.dbo.Company C (NOLOCK)
	ON O.ROW_ID = C.SiebelRowID 
    COLLATE SQL_Latin1_General_CP1_CI_AS --to get only pmcs 
WHERE O.OU_TYPE_CD IN 
           ('Property Management Company', 
            'Regional Office',
            'Self Managed Site')
AND C.SiebelRowID = @LVC_SiebelRowID
AND C.SiebelID  = @LVC_SiebelID
AND C.IDSeq = @LC_CompanyIDSeq
AND C.SiteMasterID = @LBI_SiteMasterID
--do not reinsert the same address for the same account.
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.ADDRESS ADDR (NOLOCK)
                WHERE ADDR.[Sieb77AddrID] = CA.ROW_ID
                COLLATE SQL_Latin1_General_CP1_CI_AS
                AND ADDR.CompanyIDSeq = @LC_CompanyIDSeq
                AND [AddressTypeCode] = 'CBT') 
------------------------------------------------------------------
--Insert SHIPPING Addrss of the Company if it does
--not already exist in CUSTOMERS.DBO.ADDRESS table 
------------------------------------------------------------------
INSERT INTO [CUSTOMERS].[dbo].[Address]
           ([CompanyIDSeq]
           ,[PropertyIDSeq]
           ,[AddressTypeCode]
           ,[AddressLine1]
           ,[AddressLine2]
           ,[City]
           ,[County]
           ,[State]
           ,[Zip]
           ,[PhoneVoice1]
           ,[PhoneVoiceExt1]
           ,[PhoneVoice2]
           ,[PhoneVoiceExt2]
           ,[PhoneFax]
           ,[Email]
           ,[URL]
           ,[CreatedBy]
           ,[ModifiedBy]
           ,[CreateDate]
           ,[ModifiedDate]
           ,[AttentionName]
           ,[GeoCodeFlag]
           ,[GeoCodeMatch]
           ,[Latitude]
           ,[Longitude]
           ,[MSANumber]
           ,[Country]
           ,[Sieb77AddrID]
)
SELECT 
       @LC_CompanyIDSeq                 AS [CompanyIDSeq]
       ,NULL                              AS [PropertyIDSeq]
       ,'CST'                             AS [AddressTypeCode]
       ,CA.ADDR                           AS [AddressLine1]
       ,CA.ADDR_LINE_2                    AS [AddressLine2]
       ,CA.CITY                           AS [City]
       ,CA.COUNTY                         AS [County]
       ,CA.STATE                          AS [State]
       ,CA.ZIPCODE                        AS [Zip]
       ,CA.PH_NUM                         AS [PhoneVoice1]
       ,NULL                              AS [PhoneVoiceExt1]
       ,NULL                              AS [PhoneVoice2]
       ,NULL                              AS [PhoneVoiceExt2]
       ,CA.FAX_PH_NUM                     AS [PhoneFax]
       ,NULL                              AS [Email]
       ,NULL                              AS [URL]
       ,NULL                              AS [CreatedBy]
       ,NULL                              AS [ModifiedBy]
       ,CA.CREATED                        AS [CreateDate]
       ,CA.LAST_UPD                       AS [ModifiedDate]
       ,CA.PROVINCE                       AS [AttentionName]
       ,CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END                               AS [GeoCodeFlag]
       ,CA.X_GEOCODE_MATCH                AS [GeoCodeMatch]
       ,CA.X_LATITUDE                     AS [Latitude]
       ,CA.X_LONGITUDE                    AS [Longitude]
       ,CA.X_MSA_NUMBER                   AS [MSANumber]
       ,CA.COUNTRY                        AS [Country]
       ,CA.ROW_ID                         AS [Sieb77AddrID]
--SELECT COUNT(*)--2654
--SELECT DISTINCT O.OU_TYPE_CD
FROM SourceDB.dbo.S_ADDR_ORG CA (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
	ON CA.ROW_ID  = O.PR_SHIP_ADDR_ID --Get SHIPPING address 
INNER JOIN CUSTOMERS.dbo.Company C (NOLOCK)
	ON O.ROW_ID = C.SiebelRowID 
    COLLATE SQL_Latin1_General_CP1_CI_AS --to get only pmcs 
WHERE O.OU_TYPE_CD IN 
           ('Property Management Company', 
            'Regional Office',
            'Self Managed Site')
AND C.SiebelRowID = @LVC_SiebelRowID
AND C.SiebelID  = @LVC_SiebelID
AND C.IDSeq = @LC_CompanyIDSeq
AND C.SiteMasterID = @LBI_SiteMasterID
--do not reinsert the same address for the same account.
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.ADDRESS ADDR (NOLOCK)
                WHERE ADDR.[Sieb77AddrID] = CA.ROW_ID
                COLLATE SQL_Latin1_General_CP1_CI_AS
                AND ADDR.CompanyIDSeq = @LC_CompanyIDSeq
                AND [AddressTypeCode] = 'CST') 

FETCH NEXT FROM CompanyCursor INTO  
@LC_CompanyIDSeq
,@LVC_SiebelID
,@LVC_SiebelRowID
,@LBI_SiteMasterID

END 
CLOSE CompanyCursor
DEALLOCATE CompanyCursor
END 

GO
