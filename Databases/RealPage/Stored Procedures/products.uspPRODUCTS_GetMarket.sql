SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-----------------------------------------------------------------------------------------------
-- purpose    : Get Market Values
--              This proc will return MarketCode for all ProductTypes that have a Market code associated.
--               Else, it will return Category Code as the Market Code.

-- Syntax     : EXEC dbo.[uspPRODUCTS_GetMarket] 
-- Date         Author                  Comments
-- -----------  -------------------     ---------------------------
-- 06-JUL-2010  Satya B		            Initial Creation.
-----------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetMarket] 
AS
BEGIN
  set nocount on;
  --------------------------
  select  Source.MarketCode    as MarketCode,
          Source.MarketName    as MarketName
  from   (
          Select  Coalesce(MKT.Code,FM.Code,PT.Code)                 as MarketCode,
                  Max(Coalesce(MKT.ShortName,FM.Name,PT.Name))       as MarketName,
                  Max(convert(int,PT.ReportPrimaryProductFlag))      as ReportPrimaryProductFlag,
                  Min(Coalesce(MKT.MarketDisplaySortSeq,PT.SortSeq)) as SortSeq
                  From Products.dbo.Producttype PT with (nolock)
                  inner join
                       Products.dbo.Product P with (nolock)
                  on   P.ProducttypeCode = PT.Code
                  inner join
                       Products.dbo.Charge C with (nolock)
                  on   P.Code = C.ProductCode
                  and  P.Priceversion = C.Priceversion
                  and  C.ReportingTypeCode = 'ACSF'                  
                   -->Note: Join to product and Charge is done to weed out Unassigned Producttype 
                   --  and also select the ones that has atleast one Chargerecord ReportingTypeCode = 'ACSF' , which is primary requirement for SiteWalk Through.
                  inner join
                       Products.dbo.Family FM with (nolock)
                  on   P.FamilyCode = FM.Code
                  left outer join
                       Products.dbo.Market MKT with (nolock)
                  on   PT.MarketCode = MKT.Code                 
                  group by Coalesce(MKT.Code,FM.Code,PT.Code)
         ) Source  
  order by ReportPrimaryProductFlag Desc,SortSeq Asc
  --------------------------------------------------------------------------------------------------------------
  --2.6 NOTE: For the Remaining producttype codes that are ReportPrimaryProductFlag=0, 
  --    Since ProductType code and corresponding Category is too detailed, Family will show in drop down for the timebeing.
  --    This is the assumption made.
  --    ie. For CrossFire, LeasingDesk Screening etc.
  --    Cheryl will co-ordinate with EndUsers to get more distinct and appropriate Market Codes for these.
  --    When the new market list for other producttypes are finalized and updated through seed script,
  --     No change will be required on the uspPRODUCTS_GetMarket proc, as First Preference is always to 
  --    Products.dbo.ProductType tables MarketCode association.
  --------------------------------------------------------------------------------------------------------------
END
GO
