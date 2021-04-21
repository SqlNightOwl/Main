SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  Products
-- Procedure Name  :  [uspPRODUCTS_ProductListDollarThreshold]
-- Description     :  This procedure gets the Price Cap Details 
--                    for the specified Price Cap ID.
-- Input Parameters: 	1. @IPBI_PriceCapIDSeq bigint 
-- 
-- OUTPUT          :  A record set of IDSeq, CompanyIDSeq, FamilyCode, 
--                    PriceCapBasisCode, PriceCapPercent, PriceCapTerm, 
--                    PriceCapStartDate, PriceCapEndDate
--
-- Code Example    : Exec Products.dbo.uspPRODUCTS_ProductListDollarThreshold '|DMD-OSD-OLR-CNV-RCNV|DMD-OSD-OLR-LOL-RONL|DMD-PSR-ADM-ADM-AMTF|'
-- 
-- Revision History:
-- Author          : Kiran Kusumba
-- 08/31/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE  [products].[uspPRODUCTS_ProductListDollarThreshold] (@IPVC_ProductCodes varchar(8000)
                                                            )
AS
BEGIN
  select prod.DisplayName as ProductDisplayName,
         prod.Name        as ProductName, 
         prod.Code        as ProductCode, 
         coalesce(convert(numeric(10,0),(select TOP 1 S.DollarMinimum
                   from   Products.dbo.Charge S (nolock)
                   where  S.ProductCode    = prod.Code
                   and    S.PriceVersion   = prod.PriceVersion
                   and    S.MeasureCode    = prodcodes.ilfMeasureCode
                   and    S.FrequencyCode  = prodcodes.ilfFrequencyCode
                   and    S.ChargeTypeCode = 'ILF'
                  )),                  
                  0)         as ILFDollarMinimum,
          
         coalesce((select TOP 1 S.DollarMinimumEnabledFlag
                   from   Products.dbo.Charge S (nolock)
                   where  S.ProductCode    = prod.Code
                   and    S.PriceVersion   = prod.PriceVersion
                   and    S.MeasureCode    = prodcodes.ilfMeasureCode
                   and    S.FrequencyCode  = prodcodes.ilfFrequencyCode
                   and    S.ChargeTypeCode = 'ILF'
                  ),0)         as ILFDollarMinimumEnabledFlag,

          coalesce(convert(numeric(10,0),(select TOP 1 S.DollarMaximum
                    from   Products.dbo.Charge S (nolock)
                    where  S.ProductCode    = prod.Code
                    and    S.PriceVersion   = prod.PriceVersion
                    and    S.MeasureCode    = prodcodes.ilfMeasureCode
                    and    S.FrequencyCode  = prodcodes.ilfFrequencyCode
                    and    S.ChargeTypeCode = 'ILF'                                                                                                                            
                    )),                   
                   0)       as ILFDollarMaximum,

          coalesce((select TOP 1 S.DollarMaximumEnabledFlag
                   from   Products.dbo.Charge S (nolock)
                   where  S.ProductCode    = prod.Code
                   and    S.PriceVersion   = prod.PriceVersion
                   and    S.MeasureCode    = prodcodes.ilfMeasureCode
                   and    S.FrequencyCode  = prodcodes.ilfFrequencyCode
                   and    S.ChargeTypeCode = 'ILF'
                  ),0)         as ILFDollarMaximumEnabledFlag,

          coalesce(convert(numeric(10,0),(select TOP 1 S.DollarMinimum
                   from   Products.dbo.Charge S (nolock)
                   where  S.ProductCode    = prod.Code
                   and    S.PriceVersion   = prod.PriceVersion
                   and    S.MeasureCode    = prodcodes.acsMeasureCode
                   and    S.FrequencyCode  = prodcodes.acsFrequencyCode
                   and    S.ChargeTypeCode = 'ACS'
                  )),                  
                  0)         as ACSDollarMinimum,

           coalesce((select TOP 1 S.DollarMinimumEnabledFlag
                    from   Products.dbo.Charge S (nolock)
                    where  S.ProductCode    = prod.Code
                    and    S.PriceVersion   = prod.PriceVersion
                    and    S.MeasureCode    = prodcodes.acsMeasureCode
                    and    S.FrequencyCode  = prodcodes.acsFrequencyCode
                    and    S.ChargeTypeCode = 'ACS'                                                                                                                            
                    ),0)       as ACSDollarMinimumEnabledFlag,

          coalesce(convert(numeric(10,0),(select TOP 1 S.DollarMaximum
                    from   Products.dbo.Charge S (nolock)
                    where  S.ProductCode    = prod.Code
                    and    S.PriceVersion   = prod.PriceVersion
                    and    S.MeasureCode    = prodcodes.acsMeasureCode
                    and    S.FrequencyCode  = prodcodes.acsFrequencyCode
                    and    S.ChargeTypeCode = 'ACS'                                                                                                                            
                    )),                   
                   0)       as ACSDollarMaximum,

          coalesce((select TOP 1 S.DollarMaximumEnabledFlag
                    from   Products.dbo.Charge S (nolock)
                    where  S.ProductCode    = prod.Code
                    and    S.PriceVersion   = prod.PriceVersion
                    and    S.MeasureCode    = prodcodes.acsMeasureCode
                    and    S.FrequencyCode  = prodcodes.acsFrequencyCode
                    and    S.ChargeTypeCode = 'ACS'                                                                                                                            
                    ),0)       as ACSDollarMaximumEnabledFlag
      from   Products.dbo.product prod with (nolock)    
      inner join 
      (        
        select ProductCode, ilfMeasureCode, ilfFrequencyCode, acsMeasureCode,
               acsFrequencyCode from Products.dbo.fnSplitProduct_Measure_FrequencyCodes(@IPVC_ProductCodes)
      )prodcodes
      on  prodcodes.ProductCode = prod.Code
      and prod.DisabledFlag = 0
      where prod.DisabledFlag = 0

END
--The proc QUTOES.dbo.uspQUOTES_ProductListDollarThreshold replaces this proc uspPRODUCTS_ProductListDollarThreshold
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[uspPRODUCTS_ProductListDollarThreshold]') AND type in (N'P', N'PC'))
DROP PROCEDURE [dbo].[uspPRODUCTS_ProductListDollarThreshold]

GO
