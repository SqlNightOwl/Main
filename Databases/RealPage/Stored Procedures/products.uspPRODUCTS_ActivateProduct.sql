SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ActivateProduct] (@IPVC_Code         VARCHAR(30),
                                                    @IPN_PriceVersion  NUMERIC(18,0),
                                                    @IPBI_UserIDSeq    bigint  --> This is UserID of person logged on (Mandatory) 
                                                   )
AS
BEGIN
  set nocount on;
  declare @LDT_SystemDate     datetime;

  select @LDT_SystemDate = getdate();
  ------------------------------------------------------------------------------------------
  --Step 2: Deactivate Previous Version of the product and charge pairs other than current @IPN_PriceVersion
  --        for @MaxOldVersion which is immediate previous version record modifydate as getdate()
  --        while deactivating.
  ------------------------------------------------------------------------------------------
  Update Products.dbo.Product
  set    DisabledFlag       =1,
         PendingApprovalFlag=0,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  Code         =  @IPVC_Code 
  and    PriceVersion <> @IPN_PriceVersion

  Update Products.dbo.Charge
  set    DisabledFlag       =1,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  ProductCode   =  @IPVC_Code 
  and    PriceVersion  <> @IPN_PriceVersion

  Update Products.dbo.ProductFootNote
  set    DisabledFlag=1,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  ProductCode   =  @IPVC_Code 
  and    PriceVersion  <> @IPN_PriceVersion

  Update Products.dbo.ChargeFootNote
  set    DisabledFlag=1,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  ProductCode   =  @IPVC_Code 
  and    PriceVersion  <> @IPN_PriceVersion
  ------------------------------------------------------------------------------------------
  --Step 3: Activate Current Version of the product and charge pairs for current @IPN_PriceVersion  
  ------------------------------------------------------------------------------------------
  Update Products.dbo.Product
  set    DisabledFlag       =0,
         PendingApprovalFlag=0,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  Code         =  @IPVC_Code 
  and    PriceVersion =  @IPN_PriceVersion

  Update Products.dbo.Charge
  set    DisabledFlag       =0,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  ProductCode   = @IPVC_Code 
  and    PriceVersion  = @IPN_PriceVersion

  Update Products.dbo.ProductFootNote
  set    DisabledFlag=0,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  ProductCode   =  @IPVC_Code 
  and    PriceVersion  =  @IPN_PriceVersion

  Update Products.dbo.ChargeFootNote
  set    DisabledFlag=0,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  where  ProductCode   =  @IPVC_Code 
  and    PriceVersion  =  @IPN_PriceVersion
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
