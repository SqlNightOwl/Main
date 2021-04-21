SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_DeactivateProduct
-- Description     : This procedure is used to Deactive a Product.
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec PRODUCTS.DBO.uspPRODUCTS_DeactivateProduct  Passing Input Parameters
-- Revision History:
-- Author          : Mahaboob Mohammad
-- 2011-06-15      : Defect #319
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_DeactivateProduct](@IPVC_Code         VARCHAR(30),
                                                    @IPN_PriceVersion  NUMERIC(18,0),
                                                    @IPBI_UserIDSeq    bigint  --> This is UserID of person logged on (Mandatory) 
                                                   )
AS
BEGIN
  set nocount on;
  declare @LDT_SystemDate     datetime;

  select @LDT_SystemDate = getdate();
  --Deactivate the product and charge pairs related to the product.
  --------------------------------------------------------------------------------------------
  Update Products.dbo.Product
  set    DisabledFlag       =1,
         PendingApprovalFlag=0,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  Code            = @IPVC_Code and 
         PriceVersion    = @IPN_PriceVersion

  Update Products.dbo.Charge
  set    DisabledFlag       =1,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  ProductCode   =  @IPVC_Code and 
         PriceVersion    = @IPN_PriceVersion

  Update Products.dbo.ProductFootNote
  set    DisabledFlag=1,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  ProductCode   =  @IPVC_Code and 
         PriceVersion    = @IPN_PriceVersion

  Update Products.dbo.ChargeFootNote
  set    DisabledFlag=1,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  ProductCode   =  @IPVC_Code and 
         PriceVersion    = @IPN_PriceVersion
  
--Deny/Reject the newer version of this product
DEClARE @ProductCode VARCHAR(30), @PriceVersion  NUMERIC(18,0)
SELECT @ProductCode = Code, @PriceVersion = PriceVersion FROM Products.dbo.Product 
WHERE  Code   =  @IPVC_Code and PendingApprovalFlag = 1
IF(@@ROWCOUNT > 0 )
BEGIN
DELETE FROM Products.dbo.ProductFootNote WHERE ProductCode=@ProductCode and PriceVersion =@PriceVersion 
DELETE FROM Products.dbo.ChargeFootNote WHERE ProductCode=@ProductCode and PriceVersion =@PriceVersion 
DELETE FROM Products.dbo.ProductInvalidCombo WHERE FirstProductCode=@ProductCode and FirstProductPriceVersion =@PriceVersion 
DELETE FROM Products.dbo.StockProductLookUp WHERE StockProductCode=@ProductCode and StockProductPriceVersion =@PriceVersion 
DELETE FROM Products.dbo.Charge WHERE ProductCode=@ProductCode and PriceVersion =@PriceVersion 
DELETE FROM Products.dbo.Product WHERE Code=@ProductCode and PriceVersion =@PriceVersion 
END  
 
  ------------------------------------------------------------------------------------------
  ---Resorting Product SortSeq correctly.
  begin Try
    Update D
    set    D.SortSeq = S.NewSortSeq
    from   Products.dbo.Product D with (nolock)
    inner Join
          (select distinct Ltrim(rtrim(P.Code)) as ProductCode, 
                  Max(P.DisplayName)   as ProductDisplayName,convert(int,P.StockBundleFlag) as SBF,Max(convert(int,P.SocFlag)) as SOC,   
                  (PT.SortSeq/100 + ROW_NUMBER() over(PARTITION BY PT.SortSeq order by C.SortSeq ASC,PT.SortSeq,convert(int,P.StockBundleFlag) desc,Min(P.Sortseq))) * 10 as NewSortSeq,       
                  C.Name     as CategoryName,
                  PT.Name    as ProductTypeName,
                  C.SortSeq  as CategorySortSeq,
                  PT.SortSeq as ProductTypeSortSeq,
                  Min(P.Sortseq) as existingsortseq                
          from   Products.dbo.Product  P with (nolock)
          Inner Join
                 Products.dbo.Family   F with (nolock)
          on     P.FamilyCode = F.Code
          inner Join
                 Products.dbo.Category C with (nolock)
          on     P.categorycode = C.Code
          inner Join
                Products.dbo.producttype PT
          on    P.ProducttypeCode = PT.Code
          group by Ltrim(rtrim(P.Code)),convert(int,P.StockBundleFlag),C.Name,PT.Name,C.SortSeq,PT.SortSeq
         ) S
    on   Ltrim(rtrim(D.Code)) = S.ProductCode
  end Try
  begin catch
  end   catch
  ------------------------------------------------------------------------------------------   
END 
GO
