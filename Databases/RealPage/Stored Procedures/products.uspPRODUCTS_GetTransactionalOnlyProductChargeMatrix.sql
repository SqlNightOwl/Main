SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/**************
Exec Products.dbo.uspPRODUCTS_GetTransactionalOnlyProductChargeMatrix 
************/
CREATE PROCEDURE [products].[uspPRODUCTS_GetTransactionalOnlyProductChargeMatrix] 
As
Begin
  set nocount on;  
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
         (case when C.FlatPriceFlag = 1 
                 then 'YES' 
               else 'NO'
          end)                         as FlatPrice,         
         (case when C.DisplayType = 'BOTH' 
                 then 'Available at PMC & SITE bundle'
               when C.DisplayType = 'PMC'  
                 then 'Available Only PMC bundle'
               when C.DisplayType = 'SITE' 
                 then 'Available Only SITE bundle'
               else 'Not Available for Sale in OMS'
          end)                         as BundleType,
          (Case when C.DisplayTransactionalProductPriceOnInvoiceFlag = 0
                 then 'Display at Product Level on Invoice'
                else  'Display at Individual Transaction Level on Invoice'
          end)                         as DisplayItemChargeOnInvoice,   
          RT.Name                      as Reportingtype,
          Nullif(C.RevenueTierCode,'')            as RevenueTierCode,
          Nullif(C.RevenueAccountCode,'')         as RevenueAccountCode,
          Nullif(C.DeferredRevenueAccountCode,'') as DeferredRevenueAccountCode,
          Nullif(C.TaxwareCode,'')                as TaxwareCode,
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
		(case when C.DisplayTransactionalProductPriceOnInvoiceFlag = 1   
                 then 'YES'   
               else 'NO'  
          end)                         as [Display Transactional Product Price On Invoice Flag],  
		(case when C.SystemAutoCreateEnablerFlag = 1   
                 then 'YES'   
               else 'NO'  
          end)                         as [System Auto Create Enabler Flag],  
		(case when C.ValidateSiteMasterIDFlag = 1   
                 then 'YES'   
               else 'NO'  
          end)                         as [Validate SiteMaster ID Flag] 
  ---------------------------------------------------------------
  from   PRODUCTS.dbo.Product P with (nolock)
  inner  join
         PRODUCTS.dbo.Charge  C with (nolock)
  on     P.Code          = C.productcode
  and    P.Priceversion  = C.Priceversion
  and    P.disabledflag  = C.disabledflag
  and    P.disabledflag  = 0
  and    C.disabledflag  = 0  
  and    C.MeasureCode   = 'TRAN'
  and    C.FrequencyCode = 'OT'
  and    C.DisplayType  <> 'OTHER'
  inner join
         PRODUCTS.dbo.Platform PF with (nolock)
  on     P.Platformcode  = PF.Code
  inner join
         PRODUCTS.dbo.Family FM with (nolock)
  on     P.Familycode  = FM.Code
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
  Where  P.Code          = C.productcode
  and    P.Priceversion  = C.Priceversion
  and    P.disabledflag  = C.disabledflag
  and    P.disabledflag  = 0
  and    C.disabledflag  = 0  
  and    C.MeasureCode   = 'TRAN'
  and    C.FrequencyCode = 'OT'
  and    C.DisplayType  <> 'OTHER'
  order by PF.Name ASC,FM.Name ASC,CAT.SortSeq ASC,PT.SortSeq ASC,
           P.Displayname,CT.Name DESC,M.Name ASC
END
GO
