SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--DROP PROCEDURE uspInsertPropertyAddress
CREATE PROCEDURE [customers].[uspInsertPropertyAddress]
AS BEGIN 
----------------------------------------------------------------------------------------------------
-- Database  Name    : CUSTOMERS
-- Procedure Name    : uspInsertPropertyAddress
-- Description       : This procedure loads following addresses in 
--                   : Customers.dbo.Address table
--                   : step 1 : Get all Properties
--                   : step 2 : Load Primary mailing address of the Property
--                   : step 3 : Load Billing address of the Property
--                   : step 4 : Load Shipping address of the Property
-- Input Parameters  : none so far
-- 
-- OUTPUT            : none 
-- Code Example      : EXEC CUSTOMERS.DBO.uspInsertPropertyAddress
-- Time Estimate     : 15-20 minutes approx
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
DECLARE @LC_PropertyIDSeq         CHAR(11)
DECLARE @LC_PMCIDSeq             CHAR(11)
DECLARE @LVC_SiebelID            VARCHAR(50)
DECLARE @LVC_SiebelRowID         VARCHAR(30)
DECLARE @LBI_SiteMasterID        BIGINT

SET NOCOUNT ON 
----------------------------------------------------------------------------------------------------------------------------------------
--First select all companies 
--This cursor will help load primary mail, shipping and billing addresses. 
----------------------------------------------------------------------------------------------------------------------------------------
DECLARE PropertyCursor SCROLL CURSOR FOR 
SELECT DISTINCT 
       PROP.[IDSeq]                     AS [PropertyIDSeq]
      ,PROP.[PMCIDSeq]                  AS [PMCIDSeq]
      ,PROP.[SiebelID]                  AS [SiebelID]
      ,PROP.[SiebelRowID]               AS [SiebelRowID]
      ,PROP.[SiteMasterID]              AS [SiteMasterID]
--SELECT COUNT(*)--19382
--SELECT DISTINCT O.OU_TYPE_CD,COUNT(*)
FROM CUSTOMERS.dbo.[Property] PROP (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT SITE (NOLOCK)
  ON SITE.ROW_ID = PROP.SiebelRowID 
  COLLATE SQL_Latin1_General_CP1_CI_AS --to get only pmcs 
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.ADDRESS AD (NOLOCK) 
                 WHERE AD.PROPERTYIDSEQ = PROP.IDSEQ)


--Open a cursor :
OPEN PropertyCursor 
FETCH  PropertyCursor INTO
@LC_PropertyIDSeq
,@LC_PMCIDSeq
,@LVC_SiebelID
,@LVC_SiebelRowID
,@LBI_SiteMasterID

WHILE @@FETCH_STATUS = 0
BEGIN
------------------------------------------------------------------
--Insert Primary Mailing Addrss of the Property if it does
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
        @LC_PMCIDSeq                      AS [CompanyIDSeq]
       ,@LC_PropertyIDSeq                 AS [PropertyIDSeq]
       ,'PRO'                             AS [AddressTypeCode]
       ,LTRIM(RTRIM(CA.ADDR))             AS [AddressLine1]
       ,LTRIM(RTRIM(CA.ADDR_LINE_2))               AS [AddressLine2]
       ,LTRIM(RTRIM(CA.CITY))                      AS [City]
       ,LTRIM(RTRIM(CA.COUNTY))                    AS [County]
       ,LTRIM(RTRIM(CA.STATE))                     AS [State]
       ,LTRIM(RTRIM(CA.ZIPCODE))                   AS [Zip]
       ,LTRIM(RTRIM(LEFT(CA.PH_NUM,14)))           AS [PhoneVoice1]
       ,NULL                                       AS [PhoneVoiceExt1]
       ,NULL                                       AS [PhoneVoice2]
       ,NULL                                       AS [PhoneVoiceExt2]
       ,LTRIM(RTRIM(LEFT(CA.FAX_PH_NUM,14)))       AS [PhoneFax]
       ,NULL                              AS [Email]
       ,NULL                              AS [URL]
       ,NULL                              AS [CreatedBy]
       ,NULL                              AS [ModifiedBy]
       ,CA.CREATED                        AS [CreateDate]
       ,CA.LAST_UPD                       AS [ModifiedDate]
       ,LTRIM(RTRIM(CA.PROVINCE))           AS [AttentionName]
       ,LTRIM(RTRIM(
           CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END))                                AS [GeoCodeFlag]
       ,LTRIM(RTRIM(CA.X_GEOCODE_MATCH))     AS [GeoCodeMatch]
       ,LTRIM(RTRIM(CA.X_LATITUDE))          AS [Latitude]
       ,LTRIM(RTRIM(CA.X_LONGITUDE))         AS [Longitude]
       ,LTRIM(RTRIM(CA.X_MSA_NUMBER))        AS [MSANumber]
       ,LTRIM(RTRIM(CA.COUNTRY))             AS [Country]
       ,LTRIM(RTRIM(CA.ROW_ID))              AS [Sieb77AddrID]

--SELECT COUNT(*)--2654
--SELECT DISTINCT O.OU_TYPE_CD
FROM SourceDB.dbo.S_ADDR_ORG CA (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT SITE (NOLOCK)
	ON CA.ROW_ID  = SITE.PR_ADDR_ID --get primary address only for now
INNER JOIN CUSTOMERS.dbo.[Property] PROP (NOLOCK)
	ON SITE.ROW_ID = PROP.SiebelRowID 
    COLLATE SQL_Latin1_General_CP1_CI_AS --to get only pmcs 
AND PROP.SiebelRowID = @LVC_SiebelRowID
AND PROP.SiebelID  = @LVC_SiebelID
AND PROP.IDSeq = @LC_PropertyIDSeq
AND PROP.SiteMasterID = @LBI_SiteMasterID
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.ADDRESS ADDR (NOLOCK)
                WHERE ADDR.[Sieb77AddrID] = CA.ROW_ID
                COLLATE SQL_Latin1_General_CP1_CI_AS
                AND ADDR.PropertyIDSeq = @LC_PropertyIDSeq
                AND [AddressTypeCode] = 'PRO') --do not reinsert the same address for the same account.

------------------------------------------------------------------
--Insert Billing Addrss of the Property if it does
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
        @LC_PMCIDSeq                               AS [CompanyIDSeq]
       ,@LC_PropertyIDSeq                          AS [PropertyIDSeq]
       ,'PBT'                                      AS [AddressTypeCode]
       ,LTRIM(RTRIM(CA.ADDR))                      AS [AddressLine1]
       ,LTRIM(RTRIM(CA.ADDR_LINE_2))               AS [AddressLine2]
       ,LTRIM(RTRIM(CA.CITY))                      AS [City]
       ,LTRIM(RTRIM(CA.COUNTY))                    AS [County]
       ,LTRIM(RTRIM(CA.STATE))                     AS [State]
       ,LTRIM(RTRIM(CA.ZIPCODE))                   AS [Zip]
       ,LTRIM(RTRIM(LEFT(CA.PH_NUM,14)))           AS [PhoneVoice1]
       ,NULL                                                     AS [PhoneVoiceExt1]
       ,NULL                                                     AS [PhoneVoice2]
       ,NULL                                                     AS [PhoneVoiceExt2]
       ,LTRIM(RTRIM(LEFT(CA.FAX_PH_NUM,14)))                     AS [PhoneFax]
       ,NULL                              AS [Email]
       ,NULL                              AS [URL]
       ,NULL                              AS [CreatedBy]
       ,NULL                              AS [ModifiedBy]
       ,CA.CREATED                        AS [CreateDate]
       ,CA.LAST_UPD                       AS [ModifiedDate]
       ,LTRIM(RTRIM(CA.PROVINCE))           AS [AttentionName]
       ,LTRIM(RTRIM(
           CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END))                                AS [GeoCodeFlag]                           
       ,LTRIM(RTRIM(CA.X_GEOCODE_MATCH))     AS [GeoCodeMatch]
       ,LTRIM(RTRIM(CA.X_LATITUDE))          AS [Latitude]
       ,LTRIM(RTRIM(CA.X_LONGITUDE))         AS [Longitude]
       ,LTRIM(RTRIM(CA.X_MSA_NUMBER))        AS [MSANumber]
       ,LTRIM(RTRIM(CA.COUNTRY))             AS [Country]
       ,LTRIM(RTRIM(CA.ROW_ID))              AS [Sieb77AddrID]
--SELECT COUNT(*)--2654
--SELECT DISTINCT O.OU_TYPE_CD
FROM SourceDB.dbo.S_ADDR_ORG CA (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT SITE (NOLOCK)
	ON CA.ROW_ID  = SITE.PR_BL_ADDR_ID --get billing address 
INNER JOIN CUSTOMERS.dbo.[Property] PROP (NOLOCK)
	ON SITE.ROW_ID = PROP.SiebelRowID 
    COLLATE SQL_Latin1_General_CP1_CI_AS --to get only pmcs 
AND PROP.SiebelRowID = @LVC_SiebelRowID
AND PROP.SiebelID  = @LVC_SiebelID
AND PROP.IDSeq = @LC_PropertyIDSeq
AND PROP.SiteMasterID = @LBI_SiteMasterID
--do not reinsert the same address for the same account.
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.ADDRESS ADDR (NOLOCK)
                WHERE ADDR.[Sieb77AddrID] = CA.ROW_ID
                COLLATE SQL_Latin1_General_CP1_CI_AS
                AND ADDR.PropertyIDSeq = @LC_PropertyIDSeq
                AND [AddressTypeCode] = 'PBT') 
------------------------------------------------------------------
--Insert SHIPPING Addrss of the Property if it does
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
        @LC_PMCIDSeq                      AS [CompanyIDSeq]
       ,@LC_PropertyIDSeq                 AS [PropertyIDSeq]
       ,'PST'                             AS [AddressTypeCode]
       ,LTRIM(RTRIM(CA.ADDR))                      AS [AddressLine1]
       ,LTRIM(RTRIM(CA.ADDR_LINE_2))               AS [AddressLine2]
       ,LTRIM(RTRIM(CA.CITY))                      AS [City]
       ,LTRIM(RTRIM(CA.COUNTY))                    AS [County]
       ,LTRIM(RTRIM(CA.STATE))                     AS [State]
       ,LTRIM(RTRIM(CA.ZIPCODE))                   AS [Zip]
       ,LTRIM(RTRIM(LEFT(CA.PH_NUM,14)))           AS [PhoneVoice1]
       ,NULL                                                     AS [PhoneVoiceExt1]
       ,NULL                                                     AS [PhoneVoice2]
       ,NULL                                                     AS [PhoneVoiceExt2]
       ,LTRIM(RTRIM(LEFT(CA.FAX_PH_NUM,14)))                     AS [PhoneFax]
       ,NULL                              AS [Email]
       ,NULL                              AS [URL]
       ,NULL                              AS [CreatedBy]
       ,NULL                              AS [ModifiedBy]
       ,CA.CREATED                        AS [CreateDate]
       ,CA.LAST_UPD                       AS [ModifiedDate]
       ,LTRIM(RTRIM(CA.PROVINCE))           AS [AttentionName]
       ,LTRIM(RTRIM(
           CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END))                                AS [GeoCodeFlag] 
       ,LTRIM(RTRIM(CA.X_GEOCODE_MATCH))     AS [GeoCodeMatch]
       ,LTRIM(RTRIM(CA.X_LATITUDE))          AS [Latitude]
       ,LTRIM(RTRIM(CA.X_LONGITUDE))         AS [Longitude]
       ,LTRIM(RTRIM(CA.X_MSA_NUMBER))        AS [MSANumber]
       ,LTRIM(RTRIM(CA.COUNTRY))             AS [Country]
       ,LTRIM(RTRIM(CA.ROW_ID))              AS [Sieb77AddrID]
--SELECT COUNT(*)--2654
--SELECT DISTINCT O.OU_TYPE_CD
FROM SourceDB.dbo.S_ADDR_ORG CA (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT SITE (NOLOCK)
	ON CA.ROW_ID  = SITE.PR_SHIP_ADDR_ID --Get SHIPPING address 
INNER JOIN CUSTOMERS.dbo.[Property] PROP (NOLOCK)
	ON SITE.ROW_ID = PROP.SiebelRowID 
    COLLATE SQL_Latin1_General_CP1_CI_AS --to get only pmcs 
AND PROP.SiebelRowID = @LVC_SiebelRowID
AND PROP.SiebelID  = @LVC_SiebelID
AND PROP.IDSeq = @LC_PropertyIDSeq
AND PROP.SiteMasterID = @LBI_SiteMasterID
--do not reinsert the same address for the same account.
AND NOT EXISTS (SELECT 1 FROM CUSTOMERS.DBO.ADDRESS ADDR (NOLOCK)
                WHERE ADDR.[Sieb77AddrID] = CA.ROW_ID
                COLLATE SQL_Latin1_General_CP1_CI_AS
                AND ADDR.PropertyIDSeq = @LC_PropertyIDSeq
                AND [AddressTypeCode] = 'PST') 

FETCH NEXT FROM PropertyCursor INTO  
 @LC_PropertyIDSeq
,@LC_PMCIDSeq
,@LVC_SiebelID
,@LVC_SiebelRowID
,@LBI_SiteMasterID

END 
CLOSE PropertyCursor
DEALLOCATE PropertyCursor
END 

GO
