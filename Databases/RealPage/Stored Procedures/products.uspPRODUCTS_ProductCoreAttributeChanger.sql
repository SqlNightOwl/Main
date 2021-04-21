SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_ProductCoreAttributeChanger
-- Description     : This procedure is called to change preestablished Platform,Family,Category,ProductType of a product.
-- Input Parameters: as below
-- Syntax          : 
/*
EXEC PRODUCTS.dbo.uspPRODUCTS_ProductCoreAttributeChanger  @IPVC_CurrentProductCode='DMD-ALW-ALW-ALW-ALBM',@IPVC_NewProductTypeCode='ALW',@IPBI_UserIDSeq=123  
*/

--Note : don;t forget to update 2 Epicor Tables as part of Datafix.
/*
Update [Proddata].dbo.[rrctrdet] 
set    [user_varchar3]  = @LVC_NewProductCode
where  [user_varchar3]  = @IPVC_CurrentProductCode
and    [user_varchar3] is not null;

Update [ReportDB].dbo.[DeferredRevenueDetailHistory]
set    [OMSProductCode] = @LVC_NewProductCode
where  [OMSProductCode]  = @IPVC_CurrentProductCode
and    [OMSProductCode] is not null;
*/


-- Revision History:
-- Author          : SRS
-- 05/06/2011      : SRS (Defect TFS 525). SP Created.
-----------------------------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_ProductCoreAttributeChanger] (@IPVC_CurrentProductCode   varchar(50),    --> This is the Current Pre established ProductCode
                                                                  @IPVC_NewPlatFormCode      varchar(20)='', --> New platformCode that @IPVC_CurrentProductCode moves to. If not change, pass blank ''.
                                                                  @IPVC_NewFamilyCode        varchar(20)='', --> New FamilyCode that @IPVC_CurrentProductCode moves to. If not change, pass blank ''.
                                                                  @IPVC_NewCategoryCode      varchar(20)='', --> New CategoryCode that @IPVC_CurrentProductCode moves to. If not change, pass blank ''.
                                                                  @IPVC_NewProductTypeCode   varchar(20)='', --> New ProductTypeCode that @IPVC_CurrentProductCode moves to. If not change, pass blank ''.                                                                  
                                                                  @IPBI_UserIDSeq            bigint          --> This is UserID of person making the change.
                                                                 )
as
BEGIN
  set nocount on;
  ------------------------------------------
  --Local Variables
  declare @LDT_SystemDate               datetime,
          @LVC_ErrorMessage             varchar(1000),
          ------------------
          @LVC_CurrentPlatFormCode      varchar(20),
          @LVC_CurrentFamilyCode        varchar(20),
          @LVC_CurrentCategoryCode      varchar(20),
          @LVC_CurrentProductTypeCode   varchar(20),
          @LVC_CurrentitemCode          varchar(20),
          ------------------
          @LVC_NewProductCode           varchar(50),
          @LVC_NewPlatFormName          varchar(255),
          @LVC_NewFamilyName            varchar(255),
          @LVC_NewCategoryName          varchar(255),
          @LVC_NewProductTypeName       varchar(255)
  
  declare @LDT_MinRptDate datetime, @LDTMaxRptDate datetime
  --------------------------------------------------------------------------------------
  --Validation 1: Check if @IPVC_CurrentProductCode exists in the Product Master System.
  --------------------------------------------------------------------------------------
  if not exists(select top 1 1
                from   Products.dbo.Product P with (nolock)
                where  ltrim(rtrim(P.Code)) = ltrim(rtrim(@IPVC_CurrentProductCode))
               )
  begin
    select @LVC_ErrorMessage = 'Product for ' + ltrim(rtrim(@IPVC_CurrentProductCode)) + ' does not exists in the system. Aborting...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorMessage
    return
  end
  --------------------------------------------------------------------------------------
  ---Initial steps
  select @LDT_SystemDate             = getdate(),
         @IPVC_CurrentProductCode    = ltrim(rtrim(@IPVC_CurrentProductCode)),
         @IPVC_NewPlatFormCode       = nullif(ltrim(rtrim(@IPVC_NewPlatFormCode)),''),
         @IPVC_NewFamilyCode         = nullif(ltrim(rtrim(@IPVC_NewFamilyCode)),''),
         @IPVC_NewCategoryCode       = nullif(ltrim(rtrim(@IPVC_NewCategoryCode)),''),
         @IPVC_NewProductTypeCode    = nullif(ltrim(rtrim(@IPVC_NewProductTypeCode)),'');
  ---------------------------------------------------------------------------------------
  ;with Prod_CTE (ProductCode,Priceversion)
  as (select ltrim(rtrim(P1.Code)) as ProductCode,Max(P1.Priceversion) as Priceversion
      from   Products.dbo.Product P1 with (nolock)
      where  ltrim(rtrim(P1.Code)) = @IPVC_CurrentProductCode
      group by ltrim(rtrim(P1.Code))
     )
  select @LVC_CurrentPlatFormCode      = ltrim(rtrim(P.PlatFormCode)),
         @LVC_CurrentFamilyCode        = ltrim(rtrim(P.FamilyCode)),
         @LVC_CurrentCategoryCode      = ltrim(rtrim(P.CategoryCode)),
         @LVC_CurrentProductTypeCode   = ltrim(rtrim(P.ProductTypeCode)),
         @LVC_CurrentitemCode          = ltrim(rtrim(P.ItemCode)),
         -------------------------------------
         @IPVC_NewPlatFormCode         = coalesce(@IPVC_NewPlatFormCode,ltrim(rtrim(P.PlatFormCode))),
         @IPVC_NewFamilyCode           = coalesce(@IPVC_NewFamilyCode,ltrim(rtrim(P.FamilyCode))),
         @IPVC_NewCategoryCode         = coalesce(@IPVC_NewCategoryCode,ltrim(rtrim(P.CategoryCode))),
         @IPVC_NewProductTypeCode      = coalesce(@IPVC_NewProductTypeCode,ltrim(rtrim(P.ProductTypeCode))),
         @LVC_NewProductCode           = 
                                         coalesce(@IPVC_NewPlatFormCode,ltrim(rtrim(P.PlatFormCode)))           + '-' +
                                         coalesce(@IPVC_NewFamilyCode,ltrim(rtrim(P.FamilyCode)))               + '-' +   
                                         coalesce(@IPVC_NewCategoryCode,ltrim(rtrim(P.CategoryCode)))           + '-' +
                                         coalesce(@IPVC_NewProductTypeCode,ltrim(rtrim(P.ProductTypeCode)))     + '-' +
                                         ltrim(rtrim(P.ItemCode))
         -------------------------------------
  from   Products.dbo.Product  P with (nolock)
  inner join
         Prod_CTE
  on     P.Code         = Prod_CTE.ProductCode
  and    P.PriceVersion = Prod_CTE.PriceVersion
  and    P.Code         = @IPVC_CurrentProductCode
  --------------------------------------------------------------------------------------
  --Validation 2 : If @IPVC_CurrentProductCode and @LVC_NewProductCode are the same,
  --               then no changes are needed. Abort.
  --------------------------------------------------------------------------------------
  if (ltrim(rtrim(@IPVC_CurrentProductCode)) = ltrim(rtrim(@LVC_NewProductCode)))
  begin
    select @LVC_ErrorMessage = 'Both Existing Product code :' + ltrim(rtrim(@IPVC_CurrentProductCode)) + ' and to be changed Product Code : ' +  + ltrim(rtrim(@LVC_NewProductCode)) + ' are same. Aborting...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorMessage
    return
  end
  if ( len(ltrim(rtrim(@LVC_NewProductCode))) <> 20)
  begin
    select @LVC_ErrorMessage = 'To be changed Product Code : ' +  + ltrim(rtrim(@LVC_NewProductCode)) + ' is not correct and Length is not 20 characters long. Aborting...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorMessage
    return
  end
  -------------------------------------------------------------------------------------- 
  --Select attributes pertaining to new values
  -------------------------------------------------------------------------------------- 
  --Validation 3 and Select for NewPlatFormCode
  if not exists (select top 1 1 
                 from Products.dbo.PlatForm X with (nolock)
                 where  X.Code =  @IPVC_NewPlatFormCode
                )
  begin
    select @LVC_ErrorMessage = 'Change to Platform code :' + ltrim(rtrim(@IPVC_NewPlatFormCode)) +  ' does not exists in the system. Aborting...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorMessage
    return
  end
  else
  begin
    select @LVC_NewPlatFormName = X.Name
    from   Products.dbo.PlatForm X with (nolock)
    where  X.Code =  @IPVC_NewPlatFormCode;
  end
  ---------------------------------------------
  --Validation 4 and Select for NewFamilyCode
  if not exists (select top 1 1 
                 from Products.dbo.Family X with (nolock)
                 where  X.Code =  @IPVC_NewFamilyCode
                )
  begin
    select @LVC_ErrorMessage = 'Change to Family code :' + ltrim(rtrim(@IPVC_NewFamilyCode)) +  ' does not exists in the system. Aborting...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorMessage
    return
  end
  else
  begin
    select @LVC_NewFamilyName = X.Name
    from   Products.dbo.Family X with (nolock)
    where  X.Code =  @IPVC_NewFamilyCode;
  end
  ---------------------------------------------
  --Validation 5 and Select for NewCategoryCode
  if not exists (select top 1 1 
                 from Products.dbo.Category X with (nolock)
                 where  X.Code =  @IPVC_NewCategoryCode
                )
  begin
    select @LVC_ErrorMessage = 'Change to Category code :' + ltrim(rtrim(@IPVC_NewCategoryCode)) +  ' does not exists in the system. Aborting...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorMessage
    return
  end
  else
  begin
    select @LVC_NewCategoryName = X.Name
    from   Products.dbo.Category X with (nolock)
    where  X.Code =  @IPVC_NewCategoryCode;
  end
  ---------------------------------------------
  --Validation 6 and Select for NewProductTypeCode
  if not exists (select top 1 1 
                 from Products.dbo.ProductType X with (nolock)
                 where  X.Code =  @IPVC_NewProductTypeCode
                )
  begin
    select @LVC_ErrorMessage = 'Change to ProductType code :' + ltrim(rtrim(@IPVC_NewProductTypeCode)) +  ' does not exists in the system. Aborting...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorMessage
    return
  end
  else
  begin
    select @LVC_NewProductTypeName = X.Name
    from   Products.dbo.ProductType X with (nolock)
    where  X.Code =  @IPVC_NewProductTypeCode;
  end  
  -------------------------------------------------------------------------------------- 
  --Start of Update Processes
  --------------------------------------------------------------------------------------
  --PRODUCTS : Table Charge
  alter table Products.dbo.Charge nocheck constraint ALL; --->[FK_Charge_Product];
  Update Products.dbo.Charge
  set    Productcode     = @LVC_NewProductCode,
         ModifiedDate    = @LDT_SystemDate,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         SystemLogDate   = @LDT_SystemDate
  where  ProductCode = @IPVC_CurrentProductCode;
  --------------------------------
  --PRODUCTS : Table Product
  Update Products.dbo.Product 
  set    code            = @LVC_NewProductCode,
         PlatFormCode    = @IPVC_NewPlatFormCode,
         FamilyCode      = @IPVC_NewFamilyCode,
         CategoryCode    = @IPVC_NewCategoryCode,
         ProductTypeCode = @IPVC_NewProductTypeCode,
         ModifiedDate    = @LDT_SystemDate,
         ModifiedByIDSeq = @IPBI_UserIDSeq,
         SystemLogDate   = @LDT_SystemDate
  where  Code = @IPVC_CurrentProductCode;  
  alter table Products.dbo.Charge check constraint ALL; --->[FK_Charge_Product];
  --------------------------------
  --PRODUCTS : Table ProductFootNote
  update Products.dbo.ProductFootNote
  set    Productcode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    Productcode is not null;
  --------------------------------
  --PRODUCTS : Table ChargeFootNote
  update Products.dbo.ChargeFootNote
  set    Productcode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    Productcode is not null;
  --------------------------------
  --PRODUCTS : Table ProductInvalidCombo
  update Products.dbo.ProductInvalidCombo
  set    FirstProductCode = @LVC_NewProductCode
  where  FirstProductCode = @IPVC_CurrentProductCode;

  update Products.dbo.ProductInvalidCombo
  set    SecondProductCode = @LVC_NewProductCode
  where  SecondProductCode = @IPVC_CurrentProductCode
  and    SecondProductCode is not null;
  --------------------------------
  --PRODUCTS : Table StockProductLookUp
  update Products.dbo.StockProductLookUp
  set    StockProductCode = @LVC_NewProductCode
  where  StockProductCode = @IPVC_CurrentProductCode
  and    StockProductCode is not null;

  update Products.dbo.StockProductLookUp
  set    AssociatedProductCode = @LVC_NewProductCode
  where  AssociatedProductCode = @IPVC_CurrentProductCode
  and    AssociatedProductCode is not null;
  --------------------------------
  --PRODUCTS : Table ProductTranslation
  update Products.dbo.ProductTranslation
  set    NewProductCode = @LVC_NewProductCode
  where  NewProductCode = @IPVC_CurrentProductCode
  and    NewProductCode is not null;
  --------------------------------
  --PRODUCTS : Table ScreeningProductMapping
  update Products.dbo.ScreeningProductMapping
  set    ProductCode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
  --CUSTOMERS: Table InvoiceDeliveryExceptionRuleDetail
  update CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail
  set    ApplyToProductCode = @LVC_NewProductCode
  where  ApplyToProductCode = @IPVC_CurrentProductCode
  and    ApplyToProductCode is not null;
  --------------------------------
  --CUSTOMERS: Table InvoiceDeliveryExceptionRuleDetailHistory
  update CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetailHistory
  set    ApplyToProductCode = @LVC_NewProductCode
  where  ApplyToProductCode = @IPVC_CurrentProductCode
  and    ApplyToProductCode is not null;
  --------------------------------
  --CUSTOMERS: Table PriceCapProductsHistory
  update CUSTOMERS.dbo.PriceCapProductsHistory
  set    ProductCode = @LVC_NewProductCode,
         Familycode  = @IPVC_NewFamilyCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------
  --CUSTOMERS: Table PriceCapProducts
  update CUSTOMERS.dbo.PriceCapProducts
  set    ProductCode = @LVC_NewProductCode,
         Familycode  = @IPVC_NewFamilyCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
  --DOCS   : Contract
  update DOCS.dbo.Contract
  set    ProductCode = @LVC_NewProductCode,
         Familycode  = @IPVC_NewFamilyCode
  where  ProductCode = @IPVC_CurrentProductCode  
  and    ProductCode is not null;
  --------------------------------
  --DOCS   : RequiredTemplate
  update DOCS.dbo.RequiredTemplate
  set    ProductCode = @LVC_NewProductCode,
         Familycode  = @IPVC_NewFamilyCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------
  --DOCS   : Template
  update DOCS.dbo.Template
  set    ProductCode = @LVC_NewProductCode,
         Familycode  = @IPVC_NewFamilyCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------
  --DOCS   : TemplateHistory
  update DOCS.dbo.TemplateHistory
  set    ProductCode = @LVC_NewProductCode,
         Familycode  = @IPVC_NewFamilyCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
  --DOCUMENTS : Agreement
  update DOCUMENTS.dbo.Agreement
  set    ProductCode = @LVC_NewProductCode,
         Familycode  = @IPVC_NewFamilyCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
  --QUOTES : QuoteItem
  update QUOTES.dbo.QuoteItem
  set    ProductCode = @LVC_NewProductCode,
         Familycode  = @IPVC_NewFamilyCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------
  --QUOTES : QuoteSaleAgent
  update QUOTES.dbo.QuoteSaleAgent
  set    ProductCode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
  --ORDERS : OrderItem
  update ORDERS.dbo.OrderItem
  set    ProductCode = @LVC_NewProductCode,
         Familycode  = @IPVC_NewFamilyCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------
  --ORDERS : OrderItem
  update ORDERS.dbo.OrderItemTransaction
  set    ProductCode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------
  --ORDERS : TransactionImportBatchDetail
  update ORDERS.dbo.TransactionImportBatchDetail
  set    ProductCode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
  --INVOICES : InvoiceItem
  update INVOICES.dbo.InvoiceItem
  set    ProductCode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
  --SCREENINGTRANSACTIONS : OMSOrderTranslation
  update SCREENINGTRANSACTIONS.dbo.OMSOrderTranslation
  set    ProductCode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------
  --SCREENINGTRANSACTIONS : OrdersDuplicateTransactions
  update SCREENINGTRANSACTIONS.dbo.OrdersDuplicateTransactions
  set    ProductCode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------
  --SCREENINGTRANSACTIONS : ScreeningOrderValidation
  update SCREENINGTRANSACTIONS.dbo.ScreeningOrderValidation
  set    ProductCode = @LVC_NewProductCode
  where  ProductCode = @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
  --SALESFORCESTAGING : Asset
  update SALESFORCESTAGING.dbo.[Asset]
  set    [Product_Code__c]         = @LVC_NewProductCode,
         [Product_Family_Code__c]  = @IPVC_NewFamilyCode
  where  [Product_Code__c] = @IPVC_CurrentProductCode
  and    [Product_Code__c] is not null;
  --------------------------------
  --SALESFORCESTAGING : Asset_Load
  update SALESFORCESTAGING.dbo.[Asset_Load]
  set    [Product_Code__c]         = @LVC_NewProductCode,
         [Product_Family_Code__c]  = @IPVC_NewFamilyCode
  where  [Product_Code__c] = @IPVC_CurrentProductCode
  and    [Product_Code__c] is not null;
  --------------------------------
  --SALESFORCESTAGING : Support_Product__c
  update SALESFORCESTAGING.dbo.[Support_Product__c]
  set    [Legacy_Product_code__c]  = @LVC_NewProductCode
  where  [Legacy_Product_code__c]  = @IPVC_CurrentProductCode
  and    [Legacy_Product_code__c] is not null;
  --------------------------------
  --SALESFORCESTAGING : SalesForceImport
  update SALESFORCESTAGING.dbo.[SalesForceImport]
  set    [Product Code]         = @LVC_NewProductCode,
         [Product family code]  = @IPVC_NewFamilyCode
  where  [Product Code] = @IPVC_CurrentProductCode
  and    [Product Code] is not null;
  --------------------------------------------------------------------------------------
  --OMSREPORTS : SiteproductDetails (For Primary Product attributes)
  select @LDT_MinRptDate=Min(ReportMonthEndDate),@LDTMaxRptDate = Max(ReportMonthEndDate)
  from   OMSReports.dbo.SiteProductDetails with (nolock)

  while @LDT_MinRptDate <= @LDTMaxRptDate
  begin
    ;with CTE(InitialActiveID,ReportMonthEndDate,ReportingYear,ReportingMonth)
     as (select D.InitialActiveID,D.ReportMonthEndDate,D.ReportingYear,D.ReportingMonth
         from   OMSReports.dbo.SiteProductDetails D with (nolock)
         where  D.ReportMonthEndDate = @LDT_MinRptDate
         and    ((D.prod_id = @IPVC_CurrentProductCode and D.prod_id is not null)
                   or
                 (D.ProductCode = @IPVC_CurrentProductCode and D.ProductCode is not null)
                )         
         )
      Update S
      set    S.[ProductCode]       = @LVC_NewProductCode,
             S.[prod_id]           = @LVC_NewProductCode,
             S.Platformcode        = @IPVC_NewPlatformCode,
             S.PlatformName        = @LVC_NewPlatformName,
             S.Familycode          = @IPVC_NewFamilyCode,
             S.FamilyName          = @LVC_NewFamilyName,
             S.CategoryCode        = @IPVC_NewCategoryCode,
             S.categoryName        = @LVC_NewCategoryName,
             S.ProductTypeCode     = @IPVC_NewProductTypeCode,
             S.ProductTypeName     = @LVC_NewProductTypeName            
      from   OMSReports.dbo.SiteProductDetails S with (nolock)
      inner join
             CTE   
      on     S.InitialActiveID       = CTE.InitialActiveID
      and    S.ReportingYear         = CTE.ReportingYear
      and    S.ReportingMonth        = CTE.ReportingMonth
      and    S.ReportMonthEndDate    = CTE.ReportMonthEndDate 
      and    CTE.ReportMonthEndDate  = @LDT_MinRptDate   
      and    S.ReportMonthEndDate    = @LDT_MinRptDate
      and    ((S.prod_id = @IPVC_CurrentProductCode and S.prod_id is not null)
                or
              (S.ProductCode = @IPVC_CurrentProductCode and S.ProductCode is not null)
             );            

    select @LDT_MinRptDate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,(dateadd(m,1,@LDT_MinRptDate)))+1,0))   
  end;
  --------------------------------------------------------------------------------------
  --OMSREPORTS : SiteproductDetails (For Associated Product attributes)
  select @LDT_MinRptDate=Min(ReportMonthEndDate),@LDTMaxRptDate = Max(ReportMonthEndDate) 
  from   OMSReports.dbo.SiteProductDetails with (nolock)

  while @LDT_MinRptDate <= @LDTMaxRptDate
  begin
    ;with CTE(InitialActiveID,ReportMonthEndDate,ReportingYear,ReportingMonth)
     as (select D.InitialActiveID,D.ReportMonthEndDate,D.ReportingYear,D.ReportingMonth
         from   OMSReports.dbo.SiteProductDetails D with (nolock)
         where  D.ReportMonthEndDate    = @LDT_MinRptDate
         and    D.AssociatedProductCode = @IPVC_CurrentProductCode
         and    D.AssociatedProductCode is not null
         )
      Update S
      set    S.[AssociatedProductCode]              = @LVC_NewProductCode,
             S.AssociatedProductPlatformCode        = @IPVC_NewPlatformCode,
             S.AssociatedProductFamilyCode          = @IPVC_NewFamilyCode,
             S.AssociatedProductCategoryCode        = @IPVC_NewCategoryCode,
             S.AssociatedProductCategoryName        = @LVC_NewCategoryName,
             S.AssociatedProductProductTypeCode     = @IPVC_NewProductTypeCode,
             S.AssociatedProductProductTypeName     = @LVC_NewProductTypeName            
      from   OMSReports.dbo.SiteProductDetails S with (nolock)
      inner join
             CTE   
      on     S.InitialActiveID       = CTE.InitialActiveID
      and    S.ReportingYear         = CTE.ReportingYear
      and    S.ReportingMonth        = CTE.ReportingMonth
      and    S.ReportMonthEndDate    = CTE.ReportMonthEndDate
      and    CTE.ReportMonthEndDate  = @LDT_MinRptDate
      and    S.ReportMonthEndDate    = @LDT_MinRptDate
      and    S.AssociatedProductCode = @IPVC_CurrentProductCode
      and    S.AssociatedProductCode is not null;         

    select @LDT_MinRptDate = DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,(dateadd(m,1,@LDT_MinRptDate)))+1,0))   
  end;
  --------------------------------------------------------------------------------------
  --OMSREPORTS : ProductCenterActivatedDeactivatedDetail (Primary Product Attributes)
  Update OMSREPORTS.dbo.ProductCenterActivatedDeactivatedDetail
  set    ProductCode           =  @LVC_NewProductCode,
         PlatformCode          =  @IPVC_NewPlatformCode,
         PlatformName          =  @LVC_NewPlatformName,
         FamilyCode            =  @IPVC_NewFamilyCode,
         FamilyName            =  @LVC_NewFamilyName,
         CategoryCode          =  @IPVC_NewCategoryCode,
         CategoryName          =  @LVC_NewCategoryName,
         ProductTypeCode       =  @IPVC_NewProductTypeCode,
         ProductTypeName       =  @LVC_NewProductTypeName
  where  ProductCode           =  @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
 --OMSREPORTS : ProductCenterActivatedDeactivatedDetail (Associated Product Attributes)
  Update OMSREPORTS.dbo.ProductCenterActivatedDeactivatedDetail
  set    AssociatedProductCode                  =  @LVC_NewProductCode,
         AssociatedProductPlatformCode          =  @IPVC_NewPlatformCode,
         AssociatedProductFamilyCode            =  @IPVC_NewFamilyCode,       
         AssociatedProductCategoryCode          =  @IPVC_NewCategoryCode,
         AssociatedProductCategoryName          =  @LVC_NewCategoryName,
         AssociatedProductProductTypeCode       =  @IPVC_NewProductTypeCode,
         AssociatedProductProductTypeName       =  @LVC_NewProductTypeName
  where  AssociatedProductCode =  @IPVC_CurrentProductCode
  and    AssociatedProductCode is not null;
  --------------------------------------------------------------------------------------
  --OMSREPORTS : OMSBillingTransactionLog
  Update OMSREPORTS.dbo.OMSBillingTransactionLog
  set    ProductCode           =  @LVC_NewProductCode,
         PlatformCode          =  @IPVC_NewPlatformCode,
         FamilyCode            =  @IPVC_NewFamilyCode,
         CategoryCode          =  @IPVC_NewCategoryCode,
         ProductTypeCode       =  @IPVC_NewProductTypeCode
  where  ProductCode           =  @IPVC_CurrentProductCode
  and    ProductCode is not null;
  --------------------------------------------------------------------------------------
  --OMSREPORTS : ActiveCustomerDetail
  Update OMSREPORTS.dbo.ActiveCustomerDetail
  set    DeterminingProductCode           =  @LVC_NewProductCode,
         DeterminingPlatformCode          =  @IPVC_NewPlatformCode,
         DeterminingPlatformName          =  @LVC_NewPlatformName,
         DeterminingFamilyCode            =  @IPVC_NewFamilyCode,
         DeterminingFamilyName            =  @LVC_NewFamilyName,
         DeterminingCategoryCode          =  @IPVC_NewCategoryCode,
         DeterminingCategoryName          =  @LVC_NewCategoryName,
         DeterminingProductTypeCode       =  @IPVC_NewProductTypeCode,
         DeterminingProductTypeName       =  @LVC_NewProductTypeName
  where  DeterminingProductCode           =  @IPVC_CurrentProductCode
  and    DeterminingProductCode is not null;
  --------------------------------------------------------------------------------------
  --OMSREPORTS : ActiveCustomerSummary
  Update OMSREPORTS.dbo.ActiveCustomerSummary
  set    MainProductCode                  =  @LVC_NewProductCode,
         DeterminingPlatformCode          =  @IPVC_NewPlatformCode,
         DeterminingPlatformName          =  @LVC_NewPlatformName,
         PlatformName                     =  @LVC_NewPlatformName, 
         DeterminingFamilyCode            =  @IPVC_NewFamilyCode,
         DeterminingFamilyName            =  @LVC_NewFamilyName,
         DeterminingCategoryCode          =  @IPVC_NewCategoryCode,
         DeterminingCategoryName          =  @LVC_NewCategoryName         
  where  MainProductCode                  =  @IPVC_CurrentProductCode
  and    MainProductCode is not null;
  --------------------------------------------------------------------------------------
  --OMSREPORTS : LagTransactionDetails
  Update OMSREPORTS.dbo.LagTransactionDetails
  set    ProductCode           =  @LVC_NewProductCode,
         PlatformCode          =  @IPVC_NewPlatformCode,
         PlatformName          =  @LVC_NewPlatformName,         
         FamilyCode            =  @IPVC_NewFamilyCode,
         FamilyName            =  @LVC_NewFamilyName,
         CategoryCode          =  @IPVC_NewCategoryCode,
         CategoryName          =  @LVC_NewCategoryName,
         ProductTypeCode       =  @IPVC_NewProductTypeCode,
         ProductTypeName       =  @LVC_NewProductTypeName
  where  ProductCode           =  @IPVC_CurrentProductCode
  and    ProductCode is not null;
  -------------------------------------------------------------------------------------- 
  select 'Existing Product code :' + ltrim(rtrim(@IPVC_CurrentProductCode)) + ' is now changed to Product Code : ' +  + ltrim(rtrim(@LVC_NewProductCode)) 
END
GO
