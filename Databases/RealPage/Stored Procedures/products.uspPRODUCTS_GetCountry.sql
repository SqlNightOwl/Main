SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetCountry
-- Description     : This proc returns all Countries for Customer and Product Administration 
-- Input Parameters: None
-- Returns         : RecordSet of Code and Name



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_GetCountry 
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxwareCompany Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetCountry]
as
BEGIN --> Main Begin
  set nocount on; 
  ---------------------------------------
  select  ltrim(rtrim(CNTRY.Code))              as [Code]
         ,ltrim(rtrim(CNTRY.[Name]))            as [Name]
  from    CUSTOMERS.dbo.[Country] CNTRY with (nolock)
  Order by (case when ltrim(rtrim(CNTRY.Code)) = 'USA' then '001'
                 when ltrim(rtrim(CNTRY.Code)) = 'CAN' then '002'
                 else [Name]
            end) ASC;
  ---------------------------------------
END--> Main End
GO
