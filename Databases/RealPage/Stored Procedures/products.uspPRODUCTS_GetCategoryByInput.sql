SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetCategoryByInput
-- Description     : This proc returns all Categories based on input Parameters
-- Input Parameters: None
-- Returns         : RecordSet of Code and Name



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_GetCategoryByInput  @IPVC_PlatformCode = '',@IPVC_FamilyCode = ''
Exec PRODUCTS.dbo.uspPRODUCTS_GetCategoryByInput  @IPVC_PlatformCode = 'DMD',@IPVC_FamilyCode = ''
Exec PRODUCTS.dbo.uspPRODUCTS_GetCategoryByInput  @IPVC_PlatformCode = 'DMD',@IPVC_FamilyCode = 'OSD'
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1270 (Product Administration Product Form)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetCategoryByInput]  ( @IPVC_PlatformCode   varchar(5) = ''  ---> Optional : Platform Code
                                                          ,@IPVC_FamilyCode     varchar(5) = ''  ---> Optional : Family Code
                                                         )
as
BEGIN --> Main Begin
  set nocount on; 
  select  @IPVC_PlatformCode = nullif(ltrim(rtrim(@IPVC_PlatformCode)),'')
         ,@IPVC_FamilyCode   = nullif(ltrim(rtrim(@IPVC_FamilyCode)),'');
  ---------------------------------------
  if (checksum(coalesce(@IPVC_PlatformCode,''),coalesce(@IPVC_FamilyCode,''))) = 0
  begin    
    select  ltrim(rtrim(C.Code))   as [Code]
           ,C.[Name]               as [Name]
    from    PRODUCTS.dbo.[Category] C with (nolock)
    Order by C.[Name] ASC;
  end
  else
  begin
    select
            CAT.[Code]      AS [Code]
           ,MAX(CAT.[Name]) AS [Name]          
    from    Products.dbo.Product P with (nolock)    
    inner join
            Products.dbo.Category CAT with (nolock)
    on      P.CategoryCode = CAT.Code
    and     P.PlatFormCode   = coalesce(@IPVC_PlatformCode,P.PlatFormCode)
    and     P.FamilyCode     = coalesce(@IPVC_FamilyCode,P.FamilyCode)
    and     P.DisabledFlag   = 0
    group by CAT.[Code]
    Order by [Name] ASC
  end
END--> Main End
GO
