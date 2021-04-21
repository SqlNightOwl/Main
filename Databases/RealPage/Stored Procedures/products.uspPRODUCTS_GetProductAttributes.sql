SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetProductAttributes
-- Description     : This is the Main UI Search Proc to list all product with attributes pertaining to Search Criteria
-- PreRequisites   : 
--                   EXEC PRODUCTS.dbo.uspPRODUCTS_PlatformList   -- Returns PlatForm Code and PlatForm Name for Drop down
--                   EXEC PRODUCTS.dbo.uspPRODUCTS_FamilyList     -- Returns Family Code and Family Name for Drop down
--                   EXEC PRODUCTS.dbo.uspPRODUCTS_GetCategory    -- Returns Category Code and Category Name for Drop down
--                   EXEC PRODUCTS.dbo.uspPRODUCTS_GetProductType -- Returns ProductType Code and ProductType Name for Drop down
-- Input Parameters: As below
-- Returns         : RecordSet

-- Code Example    : 
/*
--Scenario 1: Blind Search (search all) ie All Text boxes is blank
Exec PRODUCTS.dbo.uspPRODUCTS_GetProductAttributes 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 999999999
                                  ,@IPVC_PlatFormCode       = ''
                                  ,@IPVC_FamilyCode         = ''                        
                                  ,@IPVC_CategoryCode       = ''
                                  ,@IPVC_ProductTypeCode    = ''
                                  ,@IPVC_ProductCode        = ''
                                  ,@IPI_UserIDSeq           = -1

--Scenario 2 : Search Based on Specific Input Parameters
Exec PRODUCTS.dbo.uspPRODUCTS_GetProductAttributes 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 999999999
                                  ,@IPVC_PlatFormCode       = ''
                                  ,@IPVC_FamilyCode         = 'OSD'                        
                                  ,@IPVC_CategoryCode       = ''
                                  ,@IPVC_ProductTypeCode    = ''
                                  ,@IPVC_ProductCode        = ''
                                  ,@IPI_UserIDSeq           = -1


*/
-- Revision History:
-- Author          : SRS
-- 10/28/2011      : Stored Procedure Created. TFS 1270 (Product Administration Product Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetProductAttributes] (@IPI_PageNumber                  int        =1,          ---> Madatory: This is Page Number. Default is 1 and based on user click on page number.
                                                           @IPI_RowsPerPage                 int        =999999999,  ---> Madatory: This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                           @IPVC_PlatFormCode               varchar(10)='',         ---> Optional: Platform Code. Default is blank
                                                           @IPVC_FamilyCode                 varchar(10)='',         ---> Optional: Family Code. Default is blank
                                                           @IPVC_CategoryCode               varchar(10)='',         ---> Optional: Category Code. Default is blank
                                                           @IPVC_ProductTypeCode            varchar(10)='',         ---> Optional: Product Type Code. Default is blank
                                                           @IPVC_ProductCode                varchar(50)='',         ---> Optional: Product Code. Default is blank
                                                           @IPI_UserIDSeq                   bigint     =-1          ---> Madatory: UI will pass UserId of the person doing the operation
                                                          )
as
BEGIN --> Main Begin
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  -----------------------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)* @IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  -----------------------------------------------------
  select @IPVC_PlatFormCode    = nullif(ltrim(rtrim(@IPVC_PlatFormCode)),'')
        ,@IPVC_FamilyCode      = nullif(ltrim(rtrim(@IPVC_FamilyCode)),'')
        ,@IPVC_CategoryCode    = nullif(ltrim(rtrim(@IPVC_CategoryCode)),'')
        ,@IPVC_ProductTypeCode = nullif(ltrim(rtrim(@IPVC_ProductTypeCode)),'')
        ,@IPVC_ProductCode     = nullif(ltrim(rtrim(@IPVC_ProductCode)),'');
  ----------------------------------------------------
  ;with CTE_Product(PlatformCode,PlatFormName,FamilyCode,FamilyName,CategoryCode,CategoryName,ProductTypeCode,ProductTypeName,
                    ProductCode,ProductName,ProductDescription,PriceVersion,
                    ProductDisabledFlag,ProductOptionalFlag,ProductSOCFlagFlag,ProductPriceCapEnabledFlag,ProductPendingApprovalFlag,
                    ProductExcludeForBookingsFlag,Productstockbundleflag,ProductStockBundleIdentifierCode,
                    LegacyProductCode,ProductRegAdminProductFlag,ProductMPFPublicationFlag,ProductAutoFulfillFlag,ProductPrePaidFlag,
                    CreatedBy,CreatedDate,ModifiedBy,ModifiedDate,
                    [RowNumber],TotalBatchCountForPaging
                   )
  as (select               
              ltrim(rtrim(P.PlatformCode))                              as PlatformCode
             ,PF.Name                                                   as PlatFormName
             ,ltrim(rtrim(P.FamilyCode))                                as FamilyCode
             ,FM.Name                                                   as FamilyName
             ,ltrim(rtrim(P.CategoryCode))                              as CategoryCode
             ,CAT.Name                                                  as CategoryName
             ,ltrim(rtrim(P.ProductTypeCode))                           as ProductTypeCode
             ,PT.Name                                                   as ProductTypeName
             ---------------------------------------
             ,ltrim(rtrim(P.Code))                                      as ProductCode
             ,ltrim(rtrim(P.DisplayName))                               as ProductName
             ,ltrim(rtrim(P.Description))                               as ProductDescription
             ,P.PriceVersion                                            as PriceVersion
             ,convert(int,P.DisabledFlag)                               as ProductDisabledFlag
             ,convert(int,P.OptionFlag)                                 as ProductOptionalFlag
             ,convert(int,P.SOCFlag)                                    as ProductSOCFlagFlag
             ,convert(int,P.PriceCapEnabledFlag)                        as ProductPriceCapEnabledFlag
             ,convert(int,P.PendingApprovalFlag)                        as ProductPendingApprovalFlag
             ,convert(int,P.ExcludeForBookingsFlag)                     as ProductExcludeForBookingsFlag
             ,convert(int,P.stockbundleflag)                            as Productstockbundleflag
             ,ltrim(rtrim(P.StockBundleIdentifierCode))                 as ProductStockBundleIdentifierCode
             ,ltrim(rtrim(P.LegacyProductCode))                         as LegacyProductCode
             ,convert(int,P.RegAdminProductFlag)                        as ProductRegAdminProductFlag
             ,convert(int,P.MPFPublicationFlag)                         as ProductMPFPublicationFlag
             ,convert(int,P.AutoFulfillFlag)                            as ProductAutoFulfillFlag
             ,convert(int,P.PrePaidFlag)                                as ProductPrePaidFlag
            -----------------------------------------------
            ,UC.FirstName + ' ' + UC.LastName                           as CreatedBy
            ,convert(varchar(50),P.CreatedDate)                         as CreatedDate
            ,UM.FirstName + ' ' + UM.LastName                           as ModifiedBy
            ,convert(varchar(50),P.ModifiedDate)                        as ModifiedDate
            ,row_number() OVER(ORDER BY P.DisplayName asc,
                                        PF.Name       asc,
                                        FM.Name       asc,
                                        CAT.Name      asc,
                                        PT.Name       asc                                        
                              )
                                                                        as [RowNumber]
            ,Count(1) OVER()                                            as TotalBatchCountForPaging
            -----------------------------------------------           
       from  Products.dbo.Product  P  with (nolock)
       inner join
             Products.dbo.PlatForm PF with (nolock)
       on    P.PlatformCode = PF.Code
       and   P.Code         = coalesce(@IPVC_ProductCode,P.Code)
       and   P.PlatformCode = coalesce(@IPVC_PlatFormCode,P.PlatformCode)
       inner join
             Products.dbo.Family FM with (nolock)
       on    P.FamilyCode   = FM.Code
       and   P.Code         = coalesce(@IPVC_ProductCode,P.Code)
       and   P.FamilyCode   = coalesce(@IPVC_FamilyCode,P.FamilyCode)
       inner join
             Products.dbo.Category CAT with (nolock)
       on    P.CategoryCode   = CAT.Code
       and   P.Code           = coalesce(@IPVC_ProductCode,P.Code)
       and   P.CategoryCode   = coalesce(@IPVC_CategoryCode,P.CategoryCode)
       inner join
             Products.dbo.ProductType PT with (nolock)
       on    P.ProductTypeCode= PT.Code
       and   P.Code             = coalesce(@IPVC_ProductCode,P.Code)
       and   P.ProductTypeCode  = coalesce(@IPVC_ProductTypeCode,P.ProductTypeCode)
       left outer join
             SECURITY.dbo.[User] UC with (nolock)
       on    P.CreatedByIDSeq = UC.IDSeq
       left outer join
             SECURITY.dbo.[User] UM with (nolock)
       on    P.ModifiedByIDSeq = UM.IDSeq
       where P.DisabledFlag = 0
       and   Exists (select Top 1 1
                     from   Products.dbo.Charge C with (nolock)
                     where  P.Code         = C.ProductCode
                     and    P.PriceVersion = C.PriceVersion
                    )
     )
  select tablefinal.PlatformCode                                         as PlatformCode
        ,tablefinal.PlatFormName                                         as PlatFormName 
        ,tablefinal.FamilyCode                                           as FamilyCode
        ,tablefinal.FamilyName                                           as FamilyName
        ,tablefinal.CategoryCode                                         as CategoryCode
        ,tablefinal.CategoryName                                         as CategoryName
        ,tablefinal.ProductTypeCode                                      as ProductTypeCode
        ,tablefinal.ProductTypeName                                      as ProductTypeName
        ,tablefinal.ProductCode                                          as ProductCode
        ,tablefinal.ProductName                                          as ProductName
        ,tablefinal.ProductDescription                                   as ProductDescription
        ,tablefinal.PriceVersion                                         as PriceVersion
        ,tablefinal.ProductDisabledFlag                                  as ProductDisabledFlag
        ,tablefinal.ProductOptionalFlag                                  as ProductOptionalFlag
        ,tablefinal.ProductSOCFlagFlag                                   as ProductSOCFlagFlag
        ,tablefinal.ProductPriceCapEnabledFlag                           as ProductPriceCapEnabledFlag 
        ,tablefinal.ProductExcludeForBookingsFlag                        as ProductExcludeForBookingsFlag
        ,tablefinal.Productstockbundleflag                               as Productstockbundleflag
        ,tablefinal.ProductStockBundleIdentifierCode                     as ProductStockBundleIdentifierCode
        ,tablefinal.LegacyProductCode                                    as LegacyProductCode
        ,tablefinal.ProductRegAdminProductFlag                           as ProductRegAdminProductFlag
        ,tablefinal.ProductMPFPublicationFlag                            as ProductMPFPublicationFlag
        ,tablefinal.ProductAutoFulfillFlag                               as ProductAutoFulfillFlag
        ,tablefinal.ProductPrePaidFlag                                   as ProductPrePaidFlag
        ,tablefinal.CreatedBy                                            as CreatedBy
        ,tablefinal.CreatedDate                                          as CreatedDate
        ,tablefinal.ModifiedBy                                           as ModifiedBy
        ,tablefinal.ModifiedDate                                         as ModifiedDate
        ,tablefinal.TotalBatchCountForPaging
  from   CTE_Product as  tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
