SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--DROP PROCEDURE DBO.uspUpdateCompanyAttributesWithSiebel
CREATE PROCEDURE [customers].[uspUpdateCompanyAttributesWithSiebel]
AS BEGIN 
----------------------------------------------------------------------------------------------------
-- Database  Name    : CUSTOMERS
-- Procedure Name    : uspUpdateCompanyAttributesWithSiebel
-- Description       : This procedure will update company attributes such as following
--                   : 1. primary mail address including 
--				     : phone number, zipcode,city,state .. 
--                   : 2. shipping address information
--                   : 3. billing address information
--                   : 
-- Input Parameters  : none so far
-- 
-- OUTPUT            : none 
-- Code Example      : EXEC CUSTOMERS.DBO.uspUpdateCompanyAttributesWithSiebel
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

--UPDATE PRIMARY MAILING ADDRESS : 
--UPDATE THE CUSTOMER ATTRIBUTES: 
--UNITS IS NOT STORED AT COMPANY LEVEL.
--PPU% IS NOT STORED AT COMPANY LEVEL.

-------------------------------------------------------------
--SELECT DISTINCT 
--	   C.IDSEQ ,
--	   C.[NAME],
--       C.SiebelRowID,
--       C.SiebelID, 
--	   CAD.[AddressLine1],CA.ADDR  , 
--       CAD.[AddressLine2], CA.ADDR_LINE_2   ,
--       CAD.[City] ,CA.CITY  ,      
--       CAD.[County] ,CA.COUNTY ,
--       CAD.[State],CA.STATE,
--       CAD.[Zip] ,CA.ZIPCODE,
--       CAD.[PhoneVoice1],CA.PH_NUM,
--       CAD.[PhoneFax],CA.FAX_PH_NUM,
--       CAD.[CreateDate] ,CA.CREATED,
--       CAD.[ModifiedDate],CA.LAST_UPD,
--       CAD.[AttentionName],CA.PROVINCE,
--	   CAD.[GeoCodeFlag],
--	   CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
--           WHEN 'Y' 
--           THEN 1 
--           ELSE 0 
--        END   , 
--       CAD.[GeoCodeMatch],CA.X_GEOCODE_MATCH,
--       CAD.[Latitude] ,CA.X_LATITUDE,
--       CAD.[Longitude] ,CA.X_LONGITUDE,
--       CAD.[MSANumber],CA.X_MSA_NUMBER,
--       CAD.[Country],CA.COUNTRY
--select count(*) --13 RECORDS WERE UPDATED.

UPDATE C SET 
       C.[SiteMasterID] = SX.ATTRIB_36 
--SELECT DISTINCT C.NAME, O.OU_TYPE_CD,C.SiebelRowID, C.SiebelID,C.[SiteMasterID], SX.ATTRIB_36         
--SELECT DISTINCT O.OU_TYPE_CD
--SELECT COUNT(*)
FROM CUSTOMERS.dbo.[COMPANY] C (NOLOCK)
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
	ON O.ROW_ID = C.SiebelRowID COLLATE SQL_Latin1_General_CP850_CI_AI
INNER JOIN [SourceDB].[dbo].S_ORG_EXT_X  SX (NOLOCK) 
ON O.ROW_ID = SX.PAR_ROW_ID --to get database id 
AND SX.ATTRIB_36 <> C.[SiteMasterID] COLLATE SQL_Latin1_General_CP850_CI_AI
AND SX.ATTRIB_36 IS NOT NULL AND SX.ATTRIB_36 <> ''
WHERE O.OU_TYPE_CD 
IN ('Property Management Company',
'Regional Office',
'Self Managed Site')
--(19 row(s) affected)


UPDATE CAD SET 
       CAD.[AddressLine1] = RTRIM(LTRIM(CA.ADDR)) ,
       CAD.[AddressLine2] = RTRIM(LTRIM(CA.ADDR_LINE_2)), 
       CAD.[City] = RTRIM(LTRIM(CA.CITY)) ,          
       CAD.[County] = RTRIM(LTRIM(CA.COUNTY)),        
       CAD.[State] = RTRIM(LTRIM(CA.STATE)),          
       CAD.[Zip] = RTRIM(LTRIM(CA.ZIPCODE)) ,        
       CAD.[PhoneVoice1] = RTRIM(LTRIM(CA.PH_NUM)),          
       CAD.[PhoneFax] = RTRIM(LTRIM(CA.FAX_PH_NUM)),      
       CAD.[CreateDate]  = RTRIM(LTRIM(CA.CREATED)),       
       CAD.[ModifiedDate] = RTRIM(LTRIM(CA.LAST_UPD)),      
       CAD.[AttentionName] = RTRIM(LTRIM(CA.PROVINCE)) ,     
	   CAD.[GeoCodeFlag] = RTRIM(LTRIM(CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END)),    
       CAD.[GeoCodeMatch] = RTRIM(LTRIM(CA.X_GEOCODE_MATCH)) ,
       CAD.[Latitude]= RTRIM(LTRIM(CA.X_LATITUDE)),       
       CAD.[Longitude] = RTRIM(LTRIM(CA.X_LONGITUDE)),      
       CAD.[MSANumber] = RTRIM(LTRIM(CA.X_MSA_NUMBER)),     
       CAD.[Country] = RTRIM(LTRIM(CA.COUNTRY))       
FROM SourceDB.dbo.S_ADDR_ORG CA (NOLOCK) --siebel snapshot
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
	ON CA.ROW_ID  = O.PR_ADDR_ID --get primary address only for now
INNER JOIN CUSTOMERS.dbo.Company C (NOLOCK)
	ON O.ROW_ID = C.SiebelRowID COLLATE SQL_Latin1_General_CP850_CI_AI
INNER JOIN CUSTOMERS.DBO.ADDRESS CAD (NOLOCK)
ON C.IDSeq = CAD.CompanyIDSeq 
WHERE [AddressTypeCode] = 'COM'
AND O.OU_TYPE_CD IN 
         ('Property Management Company'
          ,'Regional Office'
          ,'Self Managed Site')
--4968
AND ( RTRIM(LTRIM(CA.ADDR))  <> RTRIM(LTRIM(CAD.[AddressLine1]))COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.ADDR_LINE_2))    <> RTRIM(LTRIM(CAD.[AddressLine2])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.CITY))           <> RTRIM(LTRIM(CAD.[City])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.COUNTY))         <> RTRIM(LTRIM(CAD.[County])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.STATE))          <> RTRIM(LTRIM(CAD.[State])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.ZIPCODE))        <> RTRIM(LTRIM(CAD.[Zip])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.PH_NUM))         <> RTRIM(LTRIM(CAD.[PhoneVoice1])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.FAX_PH_NUM))     <> RTRIM(LTRIM(CAD.[PhoneFax])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.CREATED))        <> RTRIM(LTRIM(CAD.[CreateDate]))  
       OR RTRIM(LTRIM(CA.LAST_UPD))       <> RTRIM(LTRIM(CAD.[ModifiedDate])) 
       OR RTRIM(LTRIM(CA.PROVINCE))       <> RTRIM(LTRIM(CAD.[AttentionName])) COLLATE SQL_Latin1_General_CP850_CI_AI
	   OR RTRIM(LTRIM(CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END))   <> RTRIM(LTRIM(CAD.[GeoCodeFlag])) 
       OR RTRIM(LTRIM(CA.X_GEOCODE_MATCH)) <> RTRIM(LTRIM(CAD.[GeoCodeMatch])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.X_LATITUDE))      <> RTRIM(LTRIM(CAD.[Latitude]))
       OR RTRIM(LTRIM(CA.X_LONGITUDE))     <> RTRIM(LTRIM(CAD.[Longitude])) 
       OR RTRIM(LTRIM(CA.X_MSA_NUMBER))    <> RTRIM(LTRIM(CAD.[MSANumber])) COLLATE SQL_Latin1_General_CP850_CI_AI
	   OR RTRIM(LTRIM(CA.COUNTRY))         <> RTRIM(LTRIM(CAD.[Country])) COLLATE SQL_Latin1_General_CP850_CI_AI
)

---------------------------------------------------
--BILLING ADDRESS : 
---------------------------------------------------
--SELECT DISTINCT 
--	   C.IDSEQ ,
--	   C.[NAME],
--       C.SiebelRowID,
--       C.SiebelID, 
--	   CAD.[AddressLine1],CA.ADDR  , 
--       CAD.[AddressLine2], CA.ADDR_LINE_2   ,
--       CAD.[City] ,CA.CITY  ,      
--       CAD.[County] ,CA.COUNTY ,
--       CAD.[State],CA.STATE,
--       CAD.[Zip] ,CA.ZIPCODE,
--       CAD.[PhoneVoice1],CA.PH_NUM,
--       CAD.[PhoneFax],CA.FAX_PH_NUM,
--       CAD.[CreateDate] ,CA.CREATED,
--       CAD.[ModifiedDate],CA.LAST_UPD,
--       CAD.[AttentionName],CA.PROVINCE,
--	   CAD.[GeoCodeFlag],
--	   CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
--           WHEN 'Y' 
--           THEN 1 
--           ELSE 0 
--        END   , 
--       CAD.[GeoCodeMatch],CA.X_GEOCODE_MATCH,
--       CAD.[Latitude] ,CA.X_LATITUDE,
--       CAD.[Longitude] ,CA.X_LONGITUDE,
--       CAD.[MSANumber],CA.X_MSA_NUMBER,
--       CAD.[Country],CA.COUNTRY

UPDATE CAD SET 
       CAD.[AddressLine1] = RTRIM(LTRIM(CA.ADDR)) ,
       CAD.[AddressLine2] = RTRIM(LTRIM(CA.ADDR_LINE_2)), 
       CAD.[City] = RTRIM(LTRIM(CA.CITY)) ,          
       CAD.[County] = RTRIM(LTRIM(CA.COUNTY)),        
       CAD.[State] = RTRIM(LTRIM(CA.STATE)),          
       CAD.[Zip] = RTRIM(LTRIM(CA.ZIPCODE)) ,        
       CAD.[PhoneVoice1] = RTRIM(LTRIM(CA.PH_NUM)),          
       CAD.[PhoneFax] = RTRIM(LTRIM(CA.FAX_PH_NUM)),      
       CAD.[CreateDate]  = RTRIM(LTRIM(CA.CREATED)),       
       CAD.[ModifiedDate] = RTRIM(LTRIM(CA.LAST_UPD)),      
       CAD.[AttentionName] = RTRIM(LTRIM(CA.PROVINCE)) ,     
	   CAD.[GeoCodeFlag] = RTRIM(LTRIM(CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END)),    
       CAD.[GeoCodeMatch] = RTRIM(LTRIM(CA.X_GEOCODE_MATCH)) ,
       CAD.[Latitude]= RTRIM(LTRIM(CA.X_LATITUDE)),       
       CAD.[Longitude] = RTRIM(LTRIM(CA.X_LONGITUDE)),      
       CAD.[MSANumber] = RTRIM(LTRIM(CA.X_MSA_NUMBER)),     
       CAD.[Country] = RTRIM(LTRIM(CA.COUNTRY)) 
--select count(*) --13 RECORDS WERE UPDATED.
FROM SourceDB.dbo.S_ADDR_ORG CA (NOLOCK) --siebel snapshot
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
	ON CA.ROW_ID  = O.PR_BL_ADDR_ID --get billing address only for now
INNER JOIN CUSTOMERS.dbo.Company C (NOLOCK)
	ON O.ROW_ID = C.SiebelRowID COLLATE SQL_Latin1_General_CP850_CI_AI
INNER JOIN CUSTOMERS.DBO.ADDRESS CAD (NOLOCK)
ON C.IDSeq = CAD.CompanyIDSeq  
WHERE [AddressTypeCode] = 'CBT'
AND O.OU_TYPE_CD IN 
         ('Property Management Company'
          ,'Regional Office'
          ,'Self Managed Site')
--4968
AND ( RTRIM(LTRIM(CA.ADDR))  <> RTRIM(LTRIM(CAD.[AddressLine1]))COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.ADDR_LINE_2))    <> RTRIM(LTRIM(CAD.[AddressLine2])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.CITY))           <> RTRIM(LTRIM(CAD.[City])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.COUNTY))         <> RTRIM(LTRIM(CAD.[County])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.STATE))          <> RTRIM(LTRIM(CAD.[State])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.ZIPCODE))        <> RTRIM(LTRIM(CAD.[Zip])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.PH_NUM))         <> RTRIM(LTRIM(CAD.[PhoneVoice1])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.FAX_PH_NUM))     <> RTRIM(LTRIM(CAD.[PhoneFax])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.CREATED))        <> RTRIM(LTRIM(CAD.[CreateDate]))  
       OR RTRIM(LTRIM(CA.LAST_UPD))       <> RTRIM(LTRIM(CAD.[ModifiedDate])) 
       OR RTRIM(LTRIM(CA.PROVINCE))       <> RTRIM(LTRIM(CAD.[AttentionName])) COLLATE SQL_Latin1_General_CP850_CI_AI
	   OR RTRIM(LTRIM(CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END))   <> RTRIM(LTRIM(CAD.[GeoCodeFlag])) 
       OR RTRIM(LTRIM(CA.X_GEOCODE_MATCH)) <> RTRIM(LTRIM(CAD.[GeoCodeMatch])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.X_LATITUDE))      <> RTRIM(LTRIM(CAD.[Latitude]))
       OR RTRIM(LTRIM(CA.X_LONGITUDE))     <> RTRIM(LTRIM(CAD.[Longitude])) 
       OR RTRIM(LTRIM(CA.X_MSA_NUMBER))    <> RTRIM(LTRIM(CAD.[MSANumber])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.COUNTRY))         <> RTRIM(LTRIM(CAD.[Country])) COLLATE SQL_Latin1_General_CP850_CI_AI
)
---------------------------------------------------
--SHIPPING ADDRESS : 
---------------------------------------------------
--SELECT DISTINCT 
--	   C.IDSEQ ,
--	   C.[NAME],
--       C.SiebelRowID,
--       C.SiebelID, 
--	   CAD.[AddressLine1],CA.ADDR  , 
--       CAD.[AddressLine2], CA.ADDR_LINE_2   ,
--       CAD.[City] ,CA.CITY  ,      
--       CAD.[County] ,CA.COUNTY ,
--       CAD.[State],CA.STATE,
--       CAD.[Zip] ,CA.ZIPCODE,
--       CAD.[PhoneVoice1],CA.PH_NUM,
--       CAD.[PhoneFax],CA.FAX_PH_NUM,
--       CAD.[CreateDate] ,CA.CREATED,
--       CAD.[ModifiedDate],CA.LAST_UPD,
--       CAD.[AttentionName],CA.PROVINCE,
--	   CAD.[GeoCodeFlag],
--	   CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
--           WHEN 'Y' 
--           THEN 1 
--           ELSE 0 
--        END   , 
--       CAD.[GeoCodeMatch],CA.X_GEOCODE_MATCH,
--       CAD.[Latitude] ,CA.X_LATITUDE,
--       CAD.[Longitude] ,CA.X_LONGITUDE,
--       CAD.[MSANumber],CA.X_MSA_NUMBER,
--       CAD.[Country],CA.COUNTRY

UPDATE CAD SET 
       CAD.[AddressLine1] = RTRIM(LTRIM(CA.ADDR)) ,
       CAD.[AddressLine2] = RTRIM(LTRIM(CA.ADDR_LINE_2)), 
       CAD.[City] = RTRIM(LTRIM(CA.CITY)) ,          
       CAD.[County] = RTRIM(LTRIM(CA.COUNTY)),        
       CAD.[State] = RTRIM(LTRIM(CA.STATE)),          
       CAD.[Zip] = RTRIM(LTRIM(CA.ZIPCODE)) ,        
       CAD.[PhoneVoice1] = RTRIM(LTRIM(CA.PH_NUM)),          
       CAD.[PhoneFax] = RTRIM(LTRIM(CA.FAX_PH_NUM)),      
       CAD.[CreateDate]  = RTRIM(LTRIM(CA.CREATED)),       
       CAD.[ModifiedDate] = RTRIM(LTRIM(CA.LAST_UPD)),      
       CAD.[AttentionName] = RTRIM(LTRIM(CA.PROVINCE)) ,     
	   CAD.[GeoCodeFlag] = RTRIM(LTRIM(CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END)),    
       CAD.[GeoCodeMatch] = RTRIM(LTRIM(CA.X_GEOCODE_MATCH)) ,
       CAD.[Latitude]= RTRIM(LTRIM(CA.X_LATITUDE)),       
       CAD.[Longitude] = RTRIM(LTRIM(CA.X_LONGITUDE)),      
       CAD.[MSANumber] = RTRIM(LTRIM(CA.X_MSA_NUMBER)),     
       CAD.[Country] = RTRIM(LTRIM(CA.COUNTRY))
--select count(*) --13 RECORDS WERE UPDATED.
FROM SourceDB.dbo.S_ADDR_ORG CA (NOLOCK) --siebel snapshot
INNER JOIN SourceDB.dbo.S_ORG_EXT O (NOLOCK)
	ON CA.ROW_ID  = O.PR_SHIP_ADDR_ID --get SHIPPING address only for now
INNER JOIN CUSTOMERS.dbo.Company C (NOLOCK)
	ON O.ROW_ID = C.SiebelRowID COLLATE SQL_Latin1_General_CP850_CI_AI
INNER JOIN CUSTOMERS.DBO.ADDRESS CAD (NOLOCK)
ON C.IDSeq = CAD.CompanyIDSeq 
WHERE [AddressTypeCode] = 'CST'
AND O.OU_TYPE_CD IN 
         ('Property Management Company'
          ,'Regional Office'
          ,'Self Managed Site')
--4968
AND ( RTRIM(LTRIM(CA.ADDR))  <> RTRIM(LTRIM(CAD.[AddressLine1]))COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.ADDR_LINE_2))    <> RTRIM(LTRIM(CAD.[AddressLine2])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.CITY))           <> RTRIM(LTRIM(CAD.[City])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.COUNTY))         <> RTRIM(LTRIM(CAD.[County])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.STATE))          <> RTRIM(LTRIM(CAD.[State])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.ZIPCODE))        <> RTRIM(LTRIM(CAD.[Zip])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.PH_NUM))         <> RTRIM(LTRIM(CAD.[PhoneVoice1])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.FAX_PH_NUM))     <> RTRIM(LTRIM(CAD.[PhoneFax])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.CREATED))        <> RTRIM(LTRIM(CAD.[CreateDate]))  
       OR RTRIM(LTRIM(CA.LAST_UPD))       <> RTRIM(LTRIM(CAD.[ModifiedDate])) 
       OR RTRIM(LTRIM(CA.PROVINCE))       <> RTRIM(LTRIM(CAD.[AttentionName])) COLLATE SQL_Latin1_General_CP850_CI_AI
	   OR RTRIM(LTRIM(CASE ISNULL(CA.X_GEOCODE_FLG,'N') 
           WHEN 'Y' 
           THEN 1 
           ELSE 0 
        END))   <> RTRIM(LTRIM(CAD.[GeoCodeFlag])) 
       OR RTRIM(LTRIM(CA.X_GEOCODE_MATCH)) <> RTRIM(LTRIM(CAD.[GeoCodeMatch])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.X_LATITUDE))      <> RTRIM(LTRIM(CAD.[Latitude]))
       OR RTRIM(LTRIM(CA.X_LONGITUDE))     <> RTRIM(LTRIM(CAD.[Longitude])) 
       OR RTRIM(LTRIM(CA.X_MSA_NUMBER))    <> RTRIM(LTRIM(CAD.[MSANumber])) COLLATE SQL_Latin1_General_CP850_CI_AI
       OR RTRIM(LTRIM(CA.COUNTRY))         <> RTRIM(LTRIM(CAD.[Country])) COLLATE SQL_Latin1_General_CP850_CI_AI
)

END 

GO
