SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetCountry
-- Description     : This proc returns all Countries for Customer and Product Administration 
-- Input Parameters: None
-- Returns         : RecordSet of Code and Name



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspCUSTOMERS_GetCountry 
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxwareCompany Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [customers].[uspCUSTOMERS_GetCountry]
as
BEGIN --> Main Begin
  set nocount on; 
  ---------------------------------------
  select  ltrim(rtrim(CNTRY.Code))              as [Code]
         ,CNTRY.[Name]                          as [Name]
  from    CUSTOMERS.dbo.[Country] CNTRY with (nolock)
  Order by CNTRY.[Name] ASC;
  ---------------------------------------
END--> Main End
GO
