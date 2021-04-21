SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetChargeAttributes
-- Description     : This is the Main UI Search Proc to list all product Charge with attributes pertaining to Search Criteria
-- PreRequisites   : 
--                   EXEC PRODUCTS.dbo.uspPRODUCTS_GetProductAttributes -- Returns ProductCode and PriceVersion and its attributes
--                   EXEC PRODUCTS.dbo.uspPRODUCTS_ReportingTypeList    -- Returns ReportingType Code and ReportingType Name for Drop down

-- Input Parameters: As below
-- Returns         : RecordSet

-- Code Example    : 
/*
--Scenario 1: Blind Search (search all) ie All Reporting Type for specific product and priceversion
Exec PRODUCTS.dbo.uspPRODUCTS_GetChargeAttributes 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 999999999
                                  ,@IPVC_ProductCode        = 'DMD-LSD-SCR-SCR-ELDS'
                                  ,@IPN_PriceVersion        = 500
                                  ,@IPVC_ReportingTypeCode  = ''
                                  ,@IPI_UserIDSeq           = -1

--Scenario 2 : Search for specific product and priceversion and ReportingtypeCode
Exec PRODUCTS.dbo.uspPRODUCTS_GetChargeAttributes 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 999999999
                                  ,@IPVC_ProductCode        = 'DMD-OSD-CNV-CNV-RCNV'
                                  ,@IPN_PriceVersion        = 900
                                  ,@IPVC_ReportingTypeCode  = 'ILFF'
                                  ,@IPI_UserIDSeq           = -1

Exec PRODUCTS.dbo.uspPRODUCTS_GetChargeAttributes 
                                   @IPI_PageNumber          = 1
                                  ,@IPI_RowsPerPage         = 999999999
                                  ,@IPVC_ProductCode        = 'DMD-OSD-CNV-CNV-RCNV'
                                  ,@IPN_PriceVersion        = 900
                                  ,@IPVC_ReportingTypeCode  = 'ACSF'
                                  ,@IPI_UserIDSeq           = -1


*/
-- Revision History:
-- Author          : SRS
-- 10/28/2011      : Stored Procedure Created. TFS 1270 (Product Administration Product Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_GetChargeAttributes] (@IPI_PageNumber                  int        =1,          ---> Madatory: This is Page Number. Default is 1 and based on user click on page number.
                                                          @IPI_RowsPerPage                 int        =999999999,  ---> Madatory: This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                          @IPVC_ProductCode                varchar(50),            ---> Madatory : Product Code.
                                                          @IPN_PriceVersion                numeric(30,0),          ---> Mandatory: Product Price Version 
                                                          @IPVC_ReportingTypeCode          varchar(10)='',         ---> Optional: Reporting Type Code 
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
  select @IPVC_ProductCode       = nullif(ltrim(rtrim(@IPVC_ProductCode)),''),
         @IPVC_ReportingTypeCode = nullif(ltrim(rtrim(@IPVC_ReportingTypeCode)),'');
  ----------------------------------------------------
  ;with CTE_Charge (FamilyCode,FamilyName,ProductCode,ProductName,PriceVersion,
                    ReportingTypeCode,ReportingTypeName,ChargeTypeCode,ChargeTypeName,
                    MeasureCode,MeasureName,FrequencyCode,FrequencyName,
                    ChargeDisabledFlag,ChargeDisplayType,ChargeAmount,MinUnits,MaxUnits,UnitBasis,FlatPriceFlag,
                    MinThresholdOverrideFlag,MaxThresholdOverrideFlag,DollarMinimumEnabledFlag,DollarMinimum,
                    QuantityEnabledFlag,QuantityMultiplierFlag,SRSDisplayQuantityFlag,ExplodeQuantityatOrderFlag,
                    PriceByPPUPercentageEnabledFlag,PriceByBedEnabledFlag,BillingCycleLeadDays,
                    RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,TaxwareCode,RevenueRecognitionCode,RevenueRecognitionName,
                    ValidateSiteMasterIDFlag,SeparateInvoiceGroupNumber,BusinessUnit,
                    MarkAsPrintedFlag,ProductMPFPublicationFlag,ChargeMPFPublicationName,
                    DisplayTransactionalProductPriceOnInvoiceFlag,AllowLongerContractFlag,ProrateFirstMonthAccessFlag,
                    SystemAutoCreateEnablerFlag,
                    CreditCardPercentageEnabledFlag,CredtCardPricingPercentage,CrossFireCallPricingEnabledFlag,
                    CreatedBy,CreatedDate,ModifiedBy,ModifiedDate,
                    [RowNumber],TotalBatchCountForPaging
                   )
  as (select   
              ltrim(rtrim(P.FamilyCode))                                as FamilyCode
             ,FM.Name                                                   as FamilyName            
             ,ltrim(rtrim(P.Code))                                      as ProductCode
             ,ltrim(rtrim(P.DisplayName))                               as ProductName
             ,P.PriceVersion                                            as PriceVersion
            -----------------------------------------------
             ,ltrim(rtrim(C.ReportingTypeCode))                         as ReportingTypeCode
             ,ltrim(rtrim(RT.Name))                                     as ReportingTypeName
             ,ltrim(rtrim(C.ChargeTypeCode))                            as ChargeTypeCode 
             ,ltrim(rtrim(CT.Name))                                     as ChargeTypeName
             ,ltrim(rtrim(C.MeasureCode))                               as MeasureCode
             ,ltrim(rtrim(M.Name))                                      as MeasureName
             ,ltrim(rtrim(C.FrequencyCode))                             as FrequencyCode
             ,ltrim(rtrim(FQ.Name))                                     as FrequencyName
             ,convert(int,C.DisabledFlag)                               as ChargeDisabledFlag
             ,C.DisplayType                                             as ChargeDisplayType
             ,C.ChargeAmount                                            as ChargeAmount
             ,C.MinUnits                                                as MinUnits
             ,C.MaxUnits                                                as MaxUnits
             ,C.UnitBasis                                               as UnitBasis
             ,convert(int,C.FlatPriceFlag)                              as FlatPriceFlag
             ,convert(int,C.MinThresholdOverride)                       as MinThresholdOverrideFlag
             ,convert(int,C.MaxThresholdOverride)                       as MaxThresholdOverrideFlag 
             ,convert(int,C.DollarMinimumEnabledFlag)                   as DollarMinimumEnabledFlag
             ,C.DollarMinimum                                           as DollarMinimum
             ,convert(int,C.QuantityEnabledFlag)                        as QuantityEnabledFlag
             ,convert(int,C.QuantityMultiplierFlag)                     as QuantityMultiplierFlag
             ,convert(int,C.SRSDisplayQuantityFlag)                     as SRSDisplayQuantityFlag
             ,convert(int,C.ExplodeQuantityatOrderFlag)                 as ExplodeQuantityatOrderFlag
             ,convert(int,C.PriceByPPUPercentageEnabledFlag)            as PriceByPPUPercentageEnabledFlag 
             ,convert(int,C.PriceByBedEnabledFlag)                      as PriceByBedEnabledFlag
             ,(case when C.LeadDays >= 1000 then 'Immediate'
                    else convert(varchar(50),C.LeadDays)
               end)                                                     as BillingCycleLeadDays
             ,C.RevenueTierCode                                         as RevenueTierCode
             ,C.RevenueAccountCode                                      as RevenueAccountCode
             ,C.DeferredRevenueAccountCode                              as DeferredRevenueAccountCode
             ,C.TaxwareCode                                             as TaxwareCode
             ,C.RevenueRecognitionCode                                  as RevenueRecognitionCode
             ,ltrim(rtrim(RRG.Name))                                    as RevenueRecognitionName  
             ,convert(int,C.ValidateSiteMasterIDFlag)                   as ValidateSiteMasterIDFlag

             ,C.SeparateInvoiceGroupNumber                              as SeparateInvoiceGroupNumber
             ,coalesce(IRM.LogoDefinition,'RealPage')                   as BusinessUnit
             ,convert(int,C.MarkAsPrintedFlag)                          as MarkAsPrintedFlag
             ,convert(int,P.MPFPublicationFlag)                         as ProductMPFPublicationFlag
             ,ltrim(rtrim(C.MPFPublicationName))                        as ChargeMPFPublicationName 
             ,convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag) as DisplayTransactionalProductPriceOnInvoiceFlag
             ,convert(int,C.AllowLongerContractFlag)                    as AllowLongerContractFlag
             ,convert(int,C.ProrateFirstMonthFlag)                      as ProrateFirstMonthAccessFlag
             ,convert(int,C.SystemAutoCreateEnablerFlag)                as SystemAutoCreateEnablerFlag
             ,convert(int,C.CreditCardPercentageEnabledFlag)            as CreditCardPercentageEnabledFlag
             ,C.CredtCardPricingPercentage                              as CredtCardPricingPercentage
             ,convert(int,C.CrossFireCallPricingEnabledFlag)            as CrossFireCallPricingEnabledFlag
            -----------------------------------------------
            ,UC.FirstName + ' ' + UC.LastName                           as CreatedBy
            ,convert(varchar(50),P.CreatedDate)                         as CreatedDate
            ,UM.FirstName + ' ' + UM.LastName                           as ModifiedBy
            ,convert(varchar(50),P.ModifiedDate)                        as ModifiedDate
            ,row_number() OVER(ORDER BY FM.Name       asc,
                                        P.DisplayName asc,
                                        RT.Name       desc
                              )
                                                                        as [RowNumber]
            ,Count(1) OVER()                                            as TotalBatchCountForPaging
            -----------------------------------------------           
       from  Products.dbo.Product  P  with (nolock)
       inner join
             Products.dbo.Family FM with (nolock)
       on    P.FamilyCode   = FM.Code 
       inner join 
             Products.dbo.Charge C with (nolock)
       on    P.Code         = C.ProductCode
       and   P.PriceVersion = C.PriceVersion
       and   P.DisabledFlag = C.DisabledFlag
       and   C.DisplayType  <> 'OTHER'
       and   P.DisabledFlag = 0
       and   C.DisabledFlag = 0
       and   P.Code         = @IPVC_ProductCode
       and   P.PriceVersion = @IPN_PriceVersion
       inner join
             Products.dbo.ChargeType CT with (nolock)
       on    C.ChargeTypeCode = CT.Code 
       inner join
             Products.dbo.Measure M with (nolock)
       on    C.MeasureCode   = M.Code      
       inner join
             Products.dbo.Frequency FQ with (nolock)
       on    C.FrequencyCode   = FQ.Code   
       inner join
             Products.dbo.ReportingType RT with (nolock)
       on    C.ReportingTypeCode = RT.Code
       and   C.ReportingTypeCode           = coalesce(@IPVC_ReportingTypeCode,C.ReportingTypeCode)
       inner join
             Products.dbo.RevenueRecognition RRG with (nolock)
       on    C.RevenueRecognitionCode   = RRG.Code
       left outer join
             Products.dbo.InvoiceReportMapping IRM with (nolock)
       on    IRM.SeparateInvoiceGroupNumber = C.SeparateInvoiceGroupNumber  
       left outer join
             SECURITY.dbo.[User] UC with (nolock)
       on    C.CreatedByIDSeq = UC.IDSeq
       left outer join
             SECURITY.dbo.[User] UM with (nolock)
       on    C.ModifiedByIDSeq = UM.IDSeq
       where P.DisabledFlag = 0
       and   C.DisabledFlag = 0
       and   P.Code         = @IPVC_ProductCode
       and   P.PriceVersion = @IPN_PriceVersion
     )
  select  
         tablefinal.FamilyCode                                           as FamilyCode
        ,tablefinal.FamilyName                                           as FamilyName
        ,tablefinal.ProductCode                                          as ProductCode
        ,tablefinal.ProductName                                          as ProductName
        ,tablefinal.PriceVersion                                         as PriceVersion
        ,tablefinal.ReportingTypeCode                                    as ReportingTypeCode
        ,tablefinal.ReportingTypeName                                    as ReportingTypeName
        ,tablefinal.ChargeTypeCode                                       as ChargeTypeCode
        ,tablefinal.ChargeTypeName                                       as ChargeTypeName
        ,tablefinal.MeasureCode                                          as MeasureCode
        ,tablefinal.MeasureName                                          as MeasureName
        ,tablefinal.FrequencyCode                                        as FrequencyCode
        ,tablefinal.FrequencyName                                        as FrequencyName
        ,tablefinal.ChargeDisabledFlag                                   as ChargeDisabledFlag
        ,tablefinal.ChargeDisplayType                                    as ChargeDisplayType
        ,tablefinal.ChargeAmount                                         as ChargeAmount
        ,tablefinal.MinUnits                                             as MinUnits
        ,tablefinal.MaxUnits                                             as MaxUnits
        ,tablefinal.UnitBasis                                            as UnitBasis
        ,tablefinal.FlatPriceFlag                                        as FlatPriceFlag
        ,tablefinal.MinThresholdOverrideFlag                             as MinThresholdOverrideFlag
        ,tablefinal.MaxThresholdOverrideFlag                             as MaxThresholdOverrideFlag
        ,tablefinal.DollarMinimumEnabledFlag                             as DollarMinimumEnabledFlag
        ,tablefinal.DollarMinimum                                        as DollarMinimum
        ,tablefinal.QuantityEnabledFlag                                  as QuantityEnabledFlag
        ,tablefinal.QuantityMultiplierFlag                               as QuantityMultiplierFlag
        ,tablefinal.SRSDisplayQuantityFlag                               as SRSDisplayQuantityFlag
        ,tablefinal.ExplodeQuantityatOrderFlag                           as ExplodeQuantityatOrderFlag
        ,tablefinal.PriceByPPUPercentageEnabledFlag                      as PriceByPPUPercentageEnabledFlag
        ,tablefinal.PriceByBedEnabledFlag                                as PriceByBedEnabledFlag
        ,tablefinal.BillingCycleLeadDays                                 as BillingCycleLeadDays
        ,tablefinal.RevenueTierCode                                      as RevenueTierCode
        ,tablefinal.RevenueAccountCode                                   as RevenueAccountCode
        ,tablefinal.DeferredRevenueAccountCode                           as DeferredRevenueAccountCode
        ,tablefinal.TaxwareCode                                          as TaxwareCode
        ,tablefinal.RevenueRecognitionCode                               as RevenueRecognitionCode
        ,tablefinal.RevenueRecognitionName                               as RevenueRecognitionName
        ,tablefinal.ValidateSiteMasterIDFlag                             as ValidateSiteMasterIDFlag
        ,tablefinal.SeparateInvoiceGroupNumber                           as SeparateInvoiceGroupNumber
        ,tablefinal.BusinessUnit                                         as BusinessUnit
        ,tablefinal.MarkAsPrintedFlag                                    as MarkAsPrintedFlag
        ,tablefinal.ProductMPFPublicationFlag                            as ProductMPFPublicationFlag
        ,tablefinal.ChargeMPFPublicationName                             as ChargeMPFPublicationName
        ,tablefinal.DisplayTransactionalProductPriceOnInvoiceFlag        as DisplayTransactionalProductPriceOnInvoiceFlag
        ,tablefinal.AllowLongerContractFlag                              as AllowLongerContractFlag
        ,tablefinal.ProrateFirstMonthAccessFlag                          as ProrateFirstMonthAccessFlag
        ,tablefinal.SystemAutoCreateEnablerFlag                          as SystemAutoCreateEnablerFlag
        ,tablefinal.CreditCardPercentageEnabledFlag                      as CreditCardPercentageEnabledFlag
        ,tablefinal.CredtCardPricingPercentage                           as CredtCardPricingPercentage
        ,tablefinal.CrossFireCallPricingEnabledFlag                      as CrossFireCallPricingEnabledFlag
        ,tablefinal.CreatedBy                                            as CreatedBy
        ,tablefinal.CreatedDate                                          as CreatedDate
        ,tablefinal.ModifiedBy                                           as ModifiedBy
        ,tablefinal.ModifiedDate                                         as ModifiedDate
        ,tablefinal.TotalBatchCountForPaging
  from   CTE_Charge as  tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
