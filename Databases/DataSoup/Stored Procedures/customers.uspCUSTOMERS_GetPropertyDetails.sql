SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetPropertyDetails
-- Description     : This procedure gets the list of Properties for the specified Company.
-- Input Parameters: 1. @IPI_AccountID   as integer
-- 
-- OUTPUT          : RecordSet of OwnerName, PropertyName, NoofUnits, NoofBeds, 
--                    PPUPercentage, PAddressLine1, PAddressLine2, PCity, PState,
--                    PZip, PEmail, PPhone, PExt, PFax, PURL, PSameasPMC, BAddressLine1,
--                    BAddressLine2, BCity, BState, BZip, BSameasPMC, SAddressLine1,
--                    SAddressLine2, SCity, SState, SZip, OAddressLine1, OAddressLine2,
--                    OCity, OState, OZip, Conventional, HUD, TaxCredit, StudentLiving,
--                    RHS, SubProperty
-- Code Example    : Exec CUSTOMERS.DBO.[uspCUSTOMERS_GetPropertyDetails] @IPVC_CompanyIDSeq = 'C0000023669'
-- 
-- 
-- Revision History:
-- Author          : STA, SRA Systems Limited.
-- 2010-07-13      : Larry. remove obsolete columns (pcr7948)
-- 2008-11-19      : Naval Kishore Modified to get Owner Country Code  
-- 2007-04-27      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetPropertyDetails] @IPVC_CompanyIDSeq varchar(11)
	
AS
BEGIN

  /*******************************************************/
  SELECT      
              O.[Name] as OwnerName,
              P.[Name] as PropertyName,       
              P.Units as NoofUnits,
              P.Beds as NoofBeds,   
			  P.OwnerIDSeq as OwnerIDSeq,	     
              P.PPUPercentage as PPUPercentage,
	          PRO.AddressLine1 as PAddressLine1,
              PRO.AddressLine2 as PAddressLine2,
              PRO.City as PCity,
              PRO.State as PState,
              PRO.Zip as PZip,
              PRO.Country as PCountry,
              PRO.EMail as PEmail,
              PRO.PhoneVoice1 as PPhone,
              PRO.PhoneVoiceExt1 as PExt,
              PRO.PhoneFax as PFax,
              PRO.URL as PURL,
              dbo.[fnChangeBoolean](PBT.SameAsPMCAddressFlag) as PSameasPMC,
              PBT.AddressLine1 as BAddressLine1,
              PBT.AddressLine2 as BAddressLine2,
              PBT.City as BCity,
              PBT.State as BState,
              PBT.Zip as BZip,
              PBT.Country as BCountry,   
              dbo.[fnChangeBoolean](PST.SameAsPMCAddressFlag) as BSameasPMC,
              PST.AddressLine1 as SAddressLine1,
              PST.AddressLine2 as SAddressLine2,
              PST.City as SCity,
              PST.State as SState,
              PST.Zip as SZip,
              PST.Country as SCountry,
              OWN.AddressLine1 as OAddressLine1,
              OWN.AddressLine2 as OAddressLine2,
              OWN.City as OCity,
              OWN.State as OState,
              OWN.Zip as OZip,
			  OWN.Country as OCountry,  
              dbo.[fnChangeBoolean](P.ConventionalFlag) as Conventional,
              dbo.[fnChangeBoolean](P.HUDFlag) as HUD,
              dbo.[fnChangeBoolean](P.TaxCreditFlag) as TaxCredit,
              dbo.[fnChangeBoolean](P.StudentLivingFlag) as StudentLiving,
              dbo.[fnChangeBoolean](P.RHSFlag) as RHS,
              dbo.[fnChangeBoolean](P.VendorFlag) as Vendor,
              dbo.[fnChangeBoolean](P.SubPropertyFlag) as SubProperty,
              P.Phase as Phase
             -- PRO.TimeZone as TimeZone  
           

  FROM        Customers..[Property] P

  INNER JOIN  Customers..Company C
    ON        C.IDSeq = P.PMCIDSeq

  LEFT OUTER JOIN  Customers..Company O
    ON        P.OwnerIDSeq = O.IDSeq    

  INNER JOIN  Customers..Address PRO
    ON        PRO.PropertyIDSeq = P.IDSeq
    AND       PRO.AddressTypeCode = 'PRO'

  LEFT OUTER JOIN  Customers..Address PST
    ON        PST.PropertyIDSeq = P.IDSeq
    AND       PST.AddressTypeCode = 'PST'

  LEFT OUTER JOIN  Customers..Address PBT
    ON        PBT.PropertyIDSeq = P.IDSeq
    AND       PBT.AddressTypeCode = 'PBT'

  LEFT OUTER JOIN  Customers..Address OWN
    ON        OWN.CompanyIDSeq = O.IDSeq
    AND       OWN.AddressTypeCode = 'COM'

  WHERE       P.PMCIDSeq = @IPVC_CompanyIDSeq
  /*******************************************************/

END

-- exec [dbo].[uspCUSTOMERS_GetPropertyDetails] 'C0000024974'

-- select * from Customers.dbo.CustomerOwner

-- select * from Customers.dbo.Company where IDSeq = '' 

GO
