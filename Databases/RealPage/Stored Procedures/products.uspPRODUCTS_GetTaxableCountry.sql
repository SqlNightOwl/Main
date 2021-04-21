SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetTaxableCountry
-- Description     : This proc returns all TaxableCountry for Product Administration 
-- Input Parameters: None
-- Returns         : RecordSet of Code and Name



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_GetTaxableCountry 
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxableCountry Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetTaxableCountry]
as
BEGIN --> Main Begin
  set nocount on; 
  ---------------------------------------
  select  ltrim(rtrim(TAXC.TaxableCountryCode))             as [TaxableCountryCode]
         ,Max(coalesce(ltrim(rtrim(CTRY.NAME)),'Unknown'))  as [TaxableCountryName]
  from    PRODUCTS.dbo.[TaxableCountry] TAXC with (nolock)
  left outer Join
          CUSTOMERS.dbo.Country CTRY with (nolock)
  on      TAXC.TaxableCountryCode = CTRY.Code
  group by ltrim(rtrim(TAXC.TaxableCountryCode))
  Order by [TaxableCountryName] ASC;
  ---------------------------------------
END--> Main End
GO
