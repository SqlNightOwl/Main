SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetProductTypeByInput
-- Description     : This proc returns all Categories based on input Parameters
-- Input Parameters: None
-- Returns         : RecordSet of Code and Name



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_GetProductTypeByInput  @IPVC_PlatformCode = '',@IPVC_FamilyCode = '',,@IPVC_CategoryCode =''
Exec PRODUCTS.dbo.uspPRODUCTS_GetProductTypeByInput  @IPVC_PlatformCode = 'DMD',@IPVC_FamilyCode = '',@IPVC_CategoryCode =''
Exec PRODUCTS.dbo.uspPRODUCTS_GetProductTypeByInput  @IPVC_PlatformCode = 'DMD',@IPVC_FamilyCode = 'OSD',@IPVC_CategoryCode = 'CNV'
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1270 (Product Administration Product Form)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetProductTypeByInput]  ( @IPVC_PlatformCode   varchar(5) = ''  ---> Optional : Platform Code
                                                             ,@IPVC_FamilyCode     varchar(5) = ''  ---> Optional : Family Code
                                                             ,@IPVC_CategoryCode   varchar(5) = ''  ---> Optional : Family Code
                                                            )
as
BEGIN --> Main Begin
  set nocount on; 
  select  @IPVC_PlatformCode = nullif(ltrim(rtrim(@IPVC_PlatformCode)),'')
         ,@IPVC_FamilyCode   = nullif(ltrim(rtrim(@IPVC_FamilyCode)),'')
         ,@IPVC_CategoryCode = nullif(ltrim(rtrim(@IPVC_CategoryCode)),'');
  ---------------------------------------
  if (checksum(coalesce(@IPVC_PlatformCode,''),coalesce(@IPVC_FamilyCode,''),coalesce(@IPVC_CategoryCode,''))) = 0
  begin    
    select  ltrim(rtrim(PT.Code))   as [Code]
           ,PT.[Name]               as [Name]
    from    PRODUCTS.dbo.[ProductType] PT with (nolock)
    Order by PT.[Name] ASC;
  end
  else
  begin
    select
            PT.[Code]      AS [Code]
           ,MAX(PT.[Name]) AS [Name]          
    from    Products.dbo.Product P with (nolock)    
    inner join
            Products.dbo.ProductType PT with (nolock)
    on      P.ProductTypeCode = PT.Code
    and     P.PlatFormCode   = coalesce(@IPVC_PlatformCode,P.PlatFormCode)
    and     P.FamilyCode     = coalesce(@IPVC_FamilyCode,P.FamilyCode)
    and     P.CategoryCode   = coalesce(@IPVC_CategoryCode,P.CategoryCode)
    and     P.DisabledFlag   = 0
    group by PT.[Code]
    Order by [Name] ASC
  end
END--> Main End
GO
