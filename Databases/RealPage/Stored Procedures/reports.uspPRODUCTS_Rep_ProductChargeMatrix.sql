SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************
Exec Products.dbo.uspPRODUCTS_Rep_ProductChargeMatrix @IPVC_SOCFlag = ''   -- Default is bring everything
Exec Products.dbo.uspPRODUCTS_Rep_ProductChargeMatrix @IPVC_SOCFlag = '1'  -- Bring Only SOC Product Charge Matrix
Exec Products.dbo.uspPRODUCTS_Rep_ProductChargeMatrix @IPVC_SOCFlag = '0'  -- Bring Only NON SOC Product Charge Matrix
************/
-- Revision History:
-- 10/10/2011      : Mahaboob Defect #1285 -- New Columns have been added to the Report
CREATE PROCEDURE [reports].[uspPRODUCTS_Rep_ProductChargeMatrix] (@IPVC_SOCFlag     varchar(1)  = '',
                                                        @IPVC_FamilyName  varchar(100)= '',
                                                        @IPVC_ProductName varchar(500)= ''
                                                       )
As
Begin
  set nocount on;
  ------------------------------------------------
  select @IPVC_SOCFlag     = nullif(@IPVC_SOCFlag,'');  
  ------------------------------------------------
  select P.Code                          as ProductCode,
         P.PriceVersion                  as PriceVersion,
         PF.Name                         as Platform,
         FM.Name                         as Family,
         CAT.Name                        as Category,
         PT.Name                         as ProductType,
         P.DisplayName                   as ProductName,
         (Case when P.SOCFLAG = 1 
                then 'SOC'
              else 'NON SOC'
          end)                           as [SOC/NON SOC],        
         CT.Name                         as ChargeType, 
         M.Name                          as Measure,
         FR.Name                         as Frequency,
         C.ChargeAmount                  as ChargeAmount,
         C.MinUnits                      as MinUnits,
         C.MaxUnits                      as MaxUnits,
         (case when C.unitbasis = 1 
                    then ''
               when C.unitbasis = 2 
                    then '50% Discount for units in excess of ' + convert(varchar(20),C.maxunits)
               when (C.unitbasis = 100 and MaxThresholdOverride = 0) 
                    then 'Large Site premium applies for units in excess of ' + convert(varchar(20),C.maxunits)
               else ''
          end)                          as Maxunitrule,
         (case when C.FlatPriceFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as FlatPrice,
         (case when C.DollarMinimumEnabledFlag = 1
                 then 'YES' 
               else 'NO' 
         end)                          as DollarMinimumEnabled,
         C.DollarMinimum               as [DollarMinimum($)],
         (case when C.CreditCardPercentageEnabledFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as CardPercentageEnabled,
         C.CredtCardPricingPercentage  as CardPricingPercentage, 
         (case when C.QuantityEnabledFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as QuantityEnabled, 
         (case when C.PriceByBedEnabledFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as PriceByBedEnabledForStudentLivingPropeties, 
         (case when C.DisplayType = 'BOTH' 
                 then 'Available at PMC & SITE bundle'
               when C.DisplayType = 'PMC'  
                 then 'Available Only PMC bundle'
               when C.DisplayType = 'SITE' 
                 then 'Available Only SITE bundle'
               else 'Not Available for Sale in OMS'
          end)                         as BundleType,  
          RT.Name                      as Reportingtype,
          C.RevenueTierCode            as RevenueTierCode,
          C.RevenueAccountCode         as RevenueAccountCode,
          C.DeferredRevenueAccountCode as DeferredRevenueAccountCode,
          C.TaxwareCode                as TaxwareCode,
          C.RevenueRecognitionCode     as RevenueRecognitionCode ,
        (case when C.RevenueRecognitionCode = 'IRR'  then 'Immediate Recognition'
              when C.RevenueRecognitionCode = 'SRR'  then 'Scheduled Recognition'
              when C.RevenueRecognitionCode = 'MRR'  then 'Manual Recognition'
         else 'N/A'
        end)                           as RevenueRecognitionType,
        ReportCategoryName             as ReportCategoryName,
        ReportSubcategoryName1         as ReportSubcategoryName1,
        ReportSubcategoryName2         as ReportSubcategoryName2,
        ReportSubcategoryName3         as ReportSubcategoryName3,
        ReportOrder                    as ReportOrder,
		(case when FR.Name = 'One-time' then 'Immediate'
			  when FR.Name = 'Initial Fee' then 'Immediate'
			  
		 else cast(C.LeadDays as varchar(10)) end)         as LeadDays,
		 (case when C.ProrateFirstMonthFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as ProrateFirstMonthFlag,
		  (case when C.AllowLongerContractFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as AllowLongerContractFlag,
		  (case when C.DisplayTransactionalProductPriceOnInvoiceFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as DisplayTransactionalProductPriceOnInvoiceFlag,
		  (case when C.SystemAutoCreateEnablerFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as SystemAutoCreateEnablerFlag,
		  (case when C.ValidateSiteMasterIDFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as ValidateSiteMasterIDFlag,
		  (case when C.PriceByPPUPercentageEnabledFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as PriceByPPUPercentage,
		  (case when C.QuantityMultiplierFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as QuantityMultiplier,
		  (case when C.ExplodeQuantityatOrderFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as ExplodeQuantityatOrder,
		  (case when C.SRSDisplayQuantityFlag  = 1 
                 then 'YES' 
               else 'NO'
          end)                         as DisplayQuantityonOrderForm,
		  (case when C.AllowLongerContractFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as 'AllowLongerThan12-monthContract',
		   C.MPFPublicationName              as MPFPublicationName,
		  (case when P.PrePaidFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as PrePaidProduct,
		  (case when P.AutoFulfillFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as 'Auto-Fulfill Access/Ancillary'
		  
  ---------------------------------------------------------------
  from   PRODUCTS.dbo.Product P with (nolock)
  inner  join
         PRODUCTS.dbo.Charge  C with (nolock)
  on     P.Code          = C.productcode
  and    P.Priceversion  = C.Priceversion
  and    P.disabledflag  = C.disabledflag
  and    P.disabledflag  = 0
  and    C.disabledflag  = 0
  and    C.DisplayType   <> 'OTHER'
  and    P.SOCFlag       = coalesce(@IPVC_SOCFlag,P.SOCFlag)
  and    P.Displayname   like '%' + @IPVC_ProductName + '%' 
  inner join
         PRODUCTS.dbo.Platform PF with (nolock)
  on     P.Platformcode  = PF.Code
  inner join
         PRODUCTS.dbo.Family FM with (nolock)
  on     P.Familycode  = FM.Code
  and    FM.Name       like '%' + @IPVC_FamilyName + '%'
  inner join
         PRODUCTS.dbo.Category CAT with (nolock)
  on     P.Categorycode  = CAT.Code
  inner join
         PRODUCTS.dbo.ProductType PT with (nolock)
  on     P.ProductTypecode  = PT.Code
  inner join
         PRODUCTS.dbo.Chargetype CT with (nolock)
  on     C.Chargetypecode  = CT.Code
  inner join
         PRODUCTS.dbo.Measure M with (nolock)
  on     C.Measurecode  = M.Code
  inner join
         PRODUCTS.dbo.Frequency FR with (nolock)
  on     C.Frequencycode  = FR.Code
  inner join
         PRODUCTS.dbo.ReportingType RT with (nolock)
  on     C.ReportingTypecode  = RT.Code
  Where  P.disabledflag  = 0
  and    C.disabledflag  = 0
  and    P.SOCFlag       = coalesce(@IPVC_SOCFlag,P.SOCFlag)
  and    FM.Name         like '%' + @IPVC_FamilyName + '%'
  and    P.Displayname   like '%' + @IPVC_ProductName + '%'   
  order by PF.Name ASC,FM.Name ASC,CAT.Name ASC,PT.Name ASC,
           P.Displayname,CT.Name DESC,M.Name ASC
END
GO
