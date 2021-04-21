SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_ReportingTypeList
-- Description     : This proc returns all Reporting Type for Product Administration 
-- Input Parameters: None
-- Returns         : RecordSet of Code and Name



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_ReportingTypeList 
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Measure Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [reports].[uspPRODUCTS_ReportingTypeList]
as
BEGIN --> Main Begin
  set nocount on; 
  ---------------------------------------
  select  ltrim(rtrim(RT.Code))   as [Code]
         ,RT.[Name]               as [Name]
  from    PRODUCTS.dbo.[ReportingType] RT with (nolock)
  Order by RT.[Name] ASC;
  ---------------------------------------
END--> Main End
GO
