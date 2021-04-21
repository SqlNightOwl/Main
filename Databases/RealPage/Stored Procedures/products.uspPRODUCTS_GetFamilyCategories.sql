SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
--------------------------------
-- procedure  : dbo.uspPRODUCTS_GetFamilyCategories
-- purpose    : acquire list of all Category that relate to one specific Family
-- parameters : FamilyCode
-- returns    : List of Category (Code/Name)
--
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2011-01-28   Larry Wilson             initial implementation. PCR 7915-Multiple Billing Addresses and invoice delivery options
--
-- Copyright  : copyright (c) 2011.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetFamilyCategories] (@FamilyCode varchar(8))
AS
BEGIN
  set nocount on;
  ----------------------------------------------
  DECLARE @LVC_CodeSection varchar(1000) 
  select @FamilyCode = nullif(@FamilyCode,'')
  ----------------------------------------------
  IF (@FamilyCode is null)
  BEGIN
    SELECT @LVC_CodeSection='Proc: uspPRODUCTS_GetFamilyCategories - @FamilyCode parameter must be provided.'   
    EXEC [CUSTOMERS].[dbo].[uspCUSTOMERS_RaiseError]  @IPVC_CodeSection = @LVC_CodeSection
    RETURN(1)
  END
  ----------------------------------------------
  IF NOT EXISTS(SELECT TOP 1 1 FROM [dbo].[Family] with (nolock) WHERE [Code]=@FamilyCode )
  BEGIN
    SELECT @LVC_CodeSection='Proc: uspPRODUCTS_GetFamilyCategories - @FamilyCode parameter is not valid'   
    EXEC [CUSTOMERS].[dbo].[uspCUSTOMERS_RaiseError]  @IPVC_CodeSection = @LVC_CodeSection
    RETURN(2)
  END
  ----------------------------------------------
  SELECT  CAT.[Code]      AS [CategoryCode],
          MAX(CAT.[Name]) AS [CategoryName],
          FM.[Code]       AS [FamilyCode],
          MAX(FM.[Name])  AS [FamilyName]
  from    Products.dbo.Product P with (nolock)
  inner join
          Products.dbo.Family FM with (nolock)
  on      P.FamilyCode   = FM.Code
  and     FM.Code        = coalesce(@FamilyCode,FM.Code)
  and     P.FamilyCode   = coalesce(@FamilyCode,P.FamilyCode)
  and     P.DisabledFlag = 0
  inner join
          Products.dbo.Category CAT with (nolock)
  on      P.CategoryCode = CAT.Code
  where   FM.Code        = coalesce(@FamilyCode,FM.Code)
  and     P.FamilyCode   = coalesce(@FamilyCode,P.FamilyCode)
  and     P.DisabledFlag = 0
  group by CAT.[Code],FM.[Code]
  Order by [CategoryName] ASC,[FamilyName] ASC

  RETURN(0)
  ----------------------------------------------
END
GO
