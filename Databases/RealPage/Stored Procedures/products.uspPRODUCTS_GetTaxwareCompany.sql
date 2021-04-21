SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetTaxwareCompany
-- Description     : This proc returns all TaxwareCompany for Product Administration 
-- Input Parameters: None
-- Returns         : RecordSet of Code and Name



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_GetTaxwareCompany 
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxwareCompany Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetTaxwareCompany]
as
BEGIN --> Main Begin
  set nocount on; 
  ---------------------------------------
  select  ltrim(rtrim(TC.TaxwareCompanyCode))   as [Code]
         ,TC.[Name]                             as [Name]
  from    PRODUCTS.dbo.[TaxwareCompany] TC with (nolock)
  Order by TC.[Name] ASC;
  ---------------------------------------
END--> Main End
GO
