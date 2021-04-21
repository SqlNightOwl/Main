SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ReviseProduct] (
                                                    @IPVC_Code                          varchar(30),
                                                    @IPN_PriceVersion			NUMERIC(18,0), 
                                                    @IPBI_UserIDSeq                     bigint  --> This is UserID of person logged on (Mandatory) 
                                                  )
AS
BEGIN
  set nocount on;
  -------------------------------
  DECLARE @LN_NewPriceVersion numeric(18,0)
  declare @LDT_SystemDate     datetime;

  select @LDT_SystemDate = getdate();   
  -------------------------------  
  SELECT @LN_NewPriceVersion = max(PriceVersion)+100  
  FROM   Products.dbo.Product with (nolock)
  WHERE  Code = @IPVC_Code
  and    disabledflag        = 0
  and    PendingApprovalFlag = 0
  ---------------------------------------------------------------------------------------------------------------------------- 
  --Step 1 : Revise Product Record in Disabled and Pending Approval State for @LN_NewPriceVersion and @IPVC_Code
  ----------------------------------------------------------------------------------------------------------------------------
  Insert into Products.dbo.Product (Code,PriceVersion,DisabledFlag,PendingApprovalFlag,
                                    PlatformCode,FamilyCode,CategoryCode,ProductTypeCode,ItemCode,SortSeq,Name,DisplayName,Description,
                                    OptionFlag,SOCFlag,StartDate,EndDate,PriceCapEnabledFlag,
                                    ExcludeForBookingsFlag,stockbundleflag,LegacyProductCode,RegAdminProductFlag,ReportPrimaryProductFlag,MPFPublicationFlag,
                                    StockBundleIdentifierCode,AutoFulfillFlag,PrePaidFlag,
                                    CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate
                                   ) 
  select P.Code,@LN_NewPriceVersion as PriceVersion,1 as DisabledFlag,1 as PendingApprovalFlag,
         P.PlatformCode,P.FamilyCode,P.CategoryCode,P.ProductTypeCode,P.ItemCode,P.SortSeq,P.Name,P.DisplayName,P.Description,
         P.OptionFlag,P.SOCFlag,P.StartDate,P.EndDate,
         P.PriceCapEnabledFlag,
         P.ExcludeForBookingsFlag,P.stockbundleflag,P.LegacyProductCode,P.RegAdminProductFlag,P.ReportPrimaryProductFlag,P.MPFPublicationFlag,
         P.StockBundleIdentifierCode,P.AutoFulfillFlag,P.PrePaidFlag,
         @IPBI_UserIDSeq as  CreatedByIDSeq,NULL as ModifiedByIDSeq,@LDT_SystemDate as CreatedDate,NULL as ModifiedDate
  from   Products.dbo.Product P with (nolock)
  where  P.Code = @IPVC_Code
  and    P.disabledflag        = 0
  and    P.PendingApprovalFlag = 0
  and    Not exists (select top 1 1 
                     from   Products.dbo.Product X with (nolock)
                     where  X.Code = P.Code
                     and    X.Code = @IPVC_Code
                     and    ((X.PriceVersion = @LN_NewPriceVersion)
                                 OR
                             (X.PendingApprovalFlag = 1)
                            )
                    );
  ---------------------------------------------------------------------------------------------------------------------------- 
  --Step 2 : Revise Charge Record in Disabled and Pending Approval State for @LN_NewPriceVersion and @IPVC_Code
  ----------------------------------------------------------------------------------------------------------------------------
  Insert into Products.dbo.Charge (ProductCode,PriceVersion,DisabledFlag,
                                     ChargeTypeCode,MeasureCode,FrequencyCode,SiebelProductID,
                                     ChargeAmount,MinUnits,MaxUnits,UnitBasis,FlatPriceFlag,
                                     DollarMinimum,DollarMinimumEnabledFlag,DollarMaximum,DollarMaximumEnabledFlag,
                                     MinThresholdOverride,MaxThresholdOverride,DiscountMaxPercent,CommissionMaxPercent,
                                     QuantityEnabledFlag,QuantityMultiplierFlag,PriceByPPUPercentageEnabledFlag,PriceByBedEnabledFlag,
                                     DisplayType,StartDate,EndDate,
                                     RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,TaxwareCode,RevenueRecognitionCode,
                                     SRSDisplayQuantityFlag,CreditCardPercentageEnabledFlag,CredtCardPricingPercentage,ReportingTypeCode,
                                     SeparateInvoiceGroupNumber,ExplodeQuantityatOrderFlag,MarkAsPrintedFlag,CrossFireCallPricingEnabledFlag,
                                     MPFPublicationName,ReportCategoryName,ReportSubcategoryName1,ReportSubcategoryName2,ReportSubcategoryName3,ReportOrder,
                                     DisplayTransactionalProductPriceOnInvoiceFlag,AllowLongerContractFlag,ProrateFirstMonthFlag,
                                     LeadDays,SystemAutoCreateEnablerFlag,ValidateSiteMasterIDFlag,
                                     CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate)
  select C.ProductCode,@LN_NewPriceVersion as PriceVersion,1 as DisabledFlag,
         C.ChargeTypeCode,C.MeasureCode,C.FrequencyCode,C.SiebelProductID,
         C.ChargeAmount,C.MinUnits,C.MaxUnits,C.UnitBasis,C.FlatPriceFlag,
         C.DollarMinimum,C.DollarMinimumEnabledFlag,C.DollarMaximum,C.DollarMaximumEnabledFlag,
         C.MinThresholdOverride,C.MaxThresholdOverride,C.DiscountMaxPercent,C.CommissionMaxPercent,
         C.QuantityEnabledFlag,C.QuantityMultiplierFlag,C.PriceByPPUPercentageEnabledFlag,C.PriceByBedEnabledFlag,
         C.DisplayType,C.StartDate,C.EndDate,
         C.RevenueTierCode,C.RevenueAccountCode,C.DeferredRevenueAccountCode,C.TaxwareCode,C.RevenueRecognitionCode,
         C.SRSDisplayQuantityFlag,C.CreditCardPercentageEnabledFlag,C.CredtCardPricingPercentage,C.ReportingTypeCode,
         C.SeparateInvoiceGroupNumber,C.ExplodeQuantityatOrderFlag,C.MarkAsPrintedFlag,C.CrossFireCallPricingEnabledFlag,
         C.MPFPublicationName,C.ReportCategoryName,C.ReportSubcategoryName1,C.ReportSubcategoryName2,C.ReportSubcategoryName3,C.ReportOrder,
         C.DisplayTransactionalProductPriceOnInvoiceFlag,C.AllowLongerContractFlag,C.ProrateFirstMonthFlag,
         C.LeadDays,C.SystemAutoCreateEnablerFlag,C.ValidateSiteMasterIDFlag,
         @IPBI_UserIDSeq as  CreatedByIDSeq,NULL as ModifiedByIDSeq,@LDT_SystemDate as CreatedDate,NULL as ModifiedDate
  from   Products.dbo.Charge C with (nolock)
  inner join
         Products.dbo.Product P with (nolock)
  on     C.Productcode = P.Code
  and    C.Priceversion= P.Priceversion
  and    P.Code = @IPVC_Code
  and    P.disabledflag        = 0
  and    P.PendingApprovalFlag = 0
  and    Not exists (select top 1 1
                     from   Products.dbo.Charge XC with (nolock)
                     where  XC.ProductCode = C.ProductCode
                     and    XC.ProductCode = P.Code
                     and    XC.PriceVersion= @LN_NewPriceVersion
                     and    XC.ChargetypeCode = C.ChargetypeCode
                     and    XC.MeasureCode    = C.MeasureCode
                     and    XC.FrequencyCode  = C.FrequencyCode
                    );  
  ---------------------------------------------------------------------------------------------------------------------------- 
  --Step 3 : Revise Products.dbo.StockProductLookUp for @LN_NewPriceVersion and @IPVC_Code
  ----------------------------------------------------------------------------------------------------------------------------  
  Insert into Products.dbo.StockProductLookUp(StockProductCode,StockProductPriceVersion,AssociatedProductCode,AssociatedProductPriceVersion,
                                              CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate)
  select SLP.StockProductCode,@LN_NewPriceVersion as StockProductPriceVersion,SLP.AssociatedProductCode,SLP.AssociatedProductPriceVersion,
         @IPBI_UserIDSeq as  CreatedByIDSeq,NULL as ModifiedByIDSeq,@LDT_SystemDate as CreatedDate,NULL as ModifiedDate
  from   Products.dbo.StockProductLookUp SLP with (nolock)
  where  SLP.StockProductCode         = @IPVC_Code
  and    SLP.StockProductPriceVersion = @IPN_PriceVersion
  and    not exists (select top 1 1
                     from   Products.dbo.StockProductLookUp XSLP with (nolock)
                     where  XSLP.StockProductCode              = SLP.StockProductCode
                     and    XSLP.StockProductPriceVersion      = @LN_NewPriceVersion
                     and    XSLP.AssociatedProductCode         = SLP.AssociatedProductCode
                     and    XSLP.AssociatedProductPriceVersion = SLP.AssociatedProductPriceVersion
                    )
  ---------------------------------------------------------------------------------------------------------------------------- 
  --Step 4 : Revise Products.dbo.ProductInvalidCombo for @LN_NewPriceVersion and @IPVC_Code
  ----------------------------------------------------------------------------------------------------------------------------  
  insert into Products.dbo.ProductInvalidCombo(FirstProductCode,FirstProductPriceVersion,SecondProductCode,SecondProductPriceVersion,
                                               CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate)
  select PIC.FirstProductCode,@LN_NewPriceVersion as FirstProductPriceVersion,PIC.SecondProductCode,PIC.SecondProductPriceVersion,
         @IPBI_UserIDSeq as  CreatedByIDSeq,NULL as ModifiedByIDSeq,@LDT_SystemDate as CreatedDate,NULL as ModifiedDate
  from   Products.dbo.ProductInvalidCombo PIC with (nolock)
  where  PIC.FirstProductCode         = @IPVC_Code
  and    PIC.FirstProductPriceVersion = @IPN_PriceVersion
  and    not exists (select top 1 1
                     from   Products.dbo.ProductInvalidCombo XPIC with (nolock)
                     where  XPIC.FirstProductCode              = PIC.FirstProductCode
                     and    XPIC.FirstProductPriceVersion      = @LN_NewPriceVersion
                     and    XPIC.SecondProductCode             = PIC.SecondProductCode
                     and    XPIC.SecondProductPriceVersion     = PIC.SecondProductPriceVersion
                    )
  ---------------------------------------------------------------------------------------------------------------------------- 
  --Step 5 : Revise Products.dbo.ProductFootNote for @LN_NewPriceVersion and @IPVC_Code
  ----------------------------------------------------------------------------------------------------------------------------  
  Insert into Products.dbo.ProductFootNote(ProductCode,PriceVersion,FootNote,DisabledFlag,
                                           CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate)
  select PFN.ProductCode,@LN_NewPriceVersion as PriceVersion,PFN.FootNote,1 as DisabledFlag,
         @IPBI_UserIDSeq as  CreatedByIDSeq,NULL as ModifiedByIDSeq,@LDT_SystemDate as CreatedDate,NULL as ModifiedDate
  from   Products.dbo.ProductFootNote PFN with (nolock)
  where  PFN.ProductCode         = @IPVC_Code
  and    PFN.PriceVersion        = @IPN_PriceVersion
  and    PFN.Disabledflag        = 0
  and    not exists (select top 1 1
                     from   Products.dbo.ProductFootNote XPFN with (nolock)
                     where  XPFN.ProductCode  = PFN.ProductCode
                     and    XPFN.ProductCode  = @IPVC_Code
                     and    XPFN.PriceVersion = @LN_NewPriceVersion
                     and    XPFN.FootNote     = PFN.FootNote
                     ) 
  ---------------------------------------------------------------------------------------------------------------------------- 
  --Step 6 : Revise Products.dbo.ChargeFootNote for @LN_NewPriceVersion and @IPVC_Code
  ----------------------------------------------------------------------------------------------------------------------------  
  Insert into Products.dbo.ChargeFootNote(ChargeIDSeq,ProductCode,PriceVersion,ChargeTypeCode,MeasureCode,FrequencyCode,FootNote,DisabledFlag,
                                          CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate)
  select C.ChargeIDSeq,C.ProductCode,@LN_NewPriceVersion as PriceVersion,
         C.ChargeTypeCode,C.MeasureCode,C.FrequencyCode,
         CFN.FootNote,1 as DisabledFlag,
         @IPBI_UserIDSeq as  CreatedByIDSeq,NULL as ModifiedByIDSeq,@LDT_SystemDate as CreatedDate,NULL as ModifiedDate
  from   Products.dbo.Charge C with (nolock)
  inner join
         Products.dbo.ChargeFootNote CFN with (nolock)
  on     C.ProductCode    = CFN.ProductCode
  and    C.ProductCode    = @IPVC_Code
  and    CFN.ProductCode  = @IPVC_Code
  and    C.ChargetypeCode = CFN.ChargetypeCode
  and    C.MeasureCode    = CFN.MeasureCode
  and    C.FrequencyCode  = CFN.FrequencyCode
  and    C.PriceVersion   = @LN_NewPriceVersion
  and    CFN.PriceVersion = @IPN_PriceVersion
  and    not exists (select top 1 1
                     from   Products.dbo.ChargeFootNote XCFN with (nolock)
                     where  XCFN.ProductCode    = CFN.ProductCode
                     and    XCFN.ProductCode    = C.ProductCode
                     and    XCFN.ProductCode    = @IPVC_Code
                     and    XCFN.PriceVersion   = @LN_NewPriceVersion
                     and    XCFN.ChargetypeCode = CFN.ChargetypeCode
                     and    XCFN.MeasureCode    = CFN.MeasureCode
                     and    XCFN.FrequencyCode  = CFN.FrequencyCode
                     and    XCFN.FootNote       = CFN.FootNote
                    );

  ----------------------------------------------------------------------------------------------------------------------------
    --Interim solution Domin-8 PrePaid
    Update P
    Set    P.PrePaidFlag = 1
          ,P.AutoFulFillFlag = 1
    from   Products.dbo.Product P with (nolock)
    where  P.FamilyCode in ('DMN','DCN')
    and   (  
           (P.DisplayName like '%PREPAID%')
             OR
           exists (select top 1 1
                   from   Products.dbo.Product X with (nolock) 
                   where  X.FamilyCode in ('DMN','DCN') 
                   and    X.DisplayName like '%PREPAID%'
                   and    X.Code = P.Code
                   )  
           );
    --Interim solution Domin-8 PrePaid
    Update  C
    set     C.LeadDays = (Case when C.ChargeTypecode = 'ILF' then 1000 else 2000 end)
           ,C.QuantityEnabledFlag = (Case when C.MeasureCode = 'TRAN' then 0
                                          when C.MeasureCode <> 'TRAN' and C.FrequencyCode = 'OT' then 1
                                          else 1
                                     end)
           ,C.SRSDisplayQuantityFlag = 1
           ,C.QuantityMultiplierFlag = 1
           ,C.MarkAsPrintedFlag      = 1
    from   Products.dbo.Charge C with (nolock) 
    inner join
           Products.dbo.Product P with (nolock)
    on     C.Productcode =P.Code
    and    C.Priceversion=P.Priceversion
    and    P.FamilyCode in ('DMN','DCN')
    where  P.FamilyCode in ('DMN','DCN')
    and    P.PrePaidFlag = 1;
  ---------------------------------------------------------------------------------------------------------------------------- 
  --Finally return the newly created product code along with new price version
  ----------------------------------------------------------------------------------------------------------------------------
  select ltrim(rtrim(P.Code)) as [Code],P.Priceversion as [Priceversion]
  from   Products.dbo.Product P with (nolock)
  where  P.Code                = @IPVC_Code
  and    P.PriceVersion        = @LN_NewPriceVersion
  and    P.disabledflag        = 1
  and    P.PendingApprovalFlag = 1
  ----------------------------------------------------------------------------------------------------------------------------
END 
GO
