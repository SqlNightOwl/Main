SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ChargeSelect] (@ChargeIDSeq BIGINT)

AS 
BEGIN 
 set nocount on;
 --------------------------------
 SELECT     C.ProductCode, 
            C.PriceVersion,
            C.ChargeTypeCode,
            C.MeasureCode,
            C.FrequencyCode,
            C.DisplayType,   
            C.ChargeAmount, 
            C.MinUnits ,
            C.MaxUnits, 
            C.MinThresholdOverride,
            C.MaxThresholdOverride,
            convert(varchar(12),C.StartDate,101)   as StartDate,
            convert(varchar(12),C.EndDate,101)     as EndDate,
            C.RevenueTierCode,
            C.RevenueAccountCode,
			C.DeferredRevenueAccountCode,
            C.TaxwareCode,
            C.QuantityEnabledFlag,
            C.QuantityMultiplierFlag,
            C.SiebelProductID, 
            C.UnitBasis,
            C.FlatPriceFlag, 
            C.DollarMinimum,         
            C.DollarMinimumEnabledFlag, 
            C.DollarMaximum,         
            C.DollarMaximumEnabledFlag,
            C.DiscountMaxPercent,
            C.CommissionMaxPercent,
            C.PriceByPPUPercentageEnabledFlag, 
            C.PriceByBedEnabledFlag, 
            C.DisabledFlag,    
            C.CreatedBy,                    
            C.ModifiedBy,                   
            C.CreateDate,             
            C.ModifyDate,  
            C.RevenueRecognitionCode, 
            C.SRSDisplayQuantityFlag, 
            C.CreditCardPercentageEnabledFlag, 
            C.CredtCardPricingPercentage,              
            C.ReportingTypeCode, 
            C.SeparateInvoiceGroupNumber, 
            C.ExplodeQuantityatOrderFlag, 
            C.MarkAsPrintedFlag, 
            C.CrossFireCallPricingEnabledFlag, 
            C.MPFPublicationName,             
            C.ReportCategoryName,                 
            C.ReportSubcategoryName1,             
            C.ReportSubcategoryName2,             
            C.ReportSubcategoryName3,
            C.DisplayTransactionalProductPriceOnInvoiceFlag,
            C.AllowLongerContractFlag,
            C.ProrateFirstMonthFlag,
            C.LeadDays,
            C.SystemAutoCreateEnablerFlag as CreateEnabler,
            C.ValidateSiteMasterIDFlag    as ValidateSiteMasterIDFlag,
			F.EpicorPostingCode as PostingCode
  FROM   Products.dbo.Charge C with (nolock)
  inner join Products.dbo.Product P with (nolock)
  on C.ProductCode = P.Code and C.PriceVersion = P.PriceVersion and C.ChargeIDSeq=@ChargeIDSeq
  inner join Products.dbo.Family  F with (nolock)
  on P.FamilyCode = F.Code
END -- Main END starts at Col 01
GO
