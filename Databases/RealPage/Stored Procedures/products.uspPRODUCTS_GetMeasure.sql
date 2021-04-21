SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetMeasure
-- Description     : This proc returns all measure for Product Administration 
-- Input Parameters: None
-- Returns         : RecordSet of Code and Name



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_GetMeasure 
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Measure Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetMeasure]
as
BEGIN --> Main Begin
  set nocount on; 
  ---------------------------------------
  select  ltrim(rtrim(M.Code))   as [Code]
         ,M.[Name]               as [Name]
  from    PRODUCTS.dbo.[Measure] M with (nolock)
  Order by M.[Name] ASC;
  ---------------------------------------
END--> Main End
GO
