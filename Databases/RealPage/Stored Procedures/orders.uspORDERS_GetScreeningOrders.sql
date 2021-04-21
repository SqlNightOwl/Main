SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------- 
-- procedure   : uspORDERS_GetScreeningOrders
-- server      : OMS
-- Database    : ORDERS
 
-- purpose     : Get all Screening ACCCESS Only Orders
--
-- Input Param: @IPDT_ReportMonthEndDate datetime -- Month end date of reporting month end
--              @IPVC_ScreeningType      varchar(20) -- Credit or Criminal
-- returns     : resultset as below

-- Example of how to call this stored procedure:
-- EXEC ORDERS.dbo.uspORDERS_GetScreeningOrders @IPDT_ReportMonthEndDate = '1/31/2009', @IPVC_ScreeningType = 'CRIMINAL'

-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 2008-Nov-17	Bhavesh Shah  	Initial creation
-- 2008-Nov-17  SRS             Added BL
-- 2008-DEC-05  Bhavesh Shah    Added Order Status
-- 2008-DEC-18  Bhavesh Shah    Added code to remove all Cancelled order because they will be part of
--                              Screening Cancelation report.
-- 2008-DEC-30	Bhavesh Shah    Added Duplicate Rank Column to determine duplicate orders.
-- 20-9-JAN-07  Bhavesh Shah    Added code to select invoice for specified month.
-- 2009-MAR-03  Bhavesh Shah    Remove all reference to Invoice because it was causing duplicate issue since there are two invoices create for order.
--                              Also, added code to get only lowest priority order item if more then one item exists for Screening Type.
--                              For example:  If property has Criminal search and Premium Criminal search then only select Criminal Search order.
-- 2009-MAR-13  Bhavesh Shah    Added PMC and Site Columnts.
-- 2009-MAR-16  Bhavesh Shah    Updated Code to get order Dates in 101 format.
-- 2009-MAR-26  Bhavesh Shah    Added code to pick correct order.  If property has subscription and TRAN order then pick Subscription order.

-- Copyright  : copyright (c) 2008.  RealPage Inc.
-- This module is the confidential & proprietary property of
-- RealPage Inc.
-----------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetScreeningOrders]   (@IPDT_ReportMonthEndDate datetime,
                                                         @IPVC_ScreeningType      varchar(20)='credit'
                                                        ) 
AS
BEGIN
  set nocount on;
  set @IPDT_ReportMonthEndDate = convert(datetime,convert(varchar(20),@IPDT_ReportMonthEndDate,101))
  SET @IPVC_ScreeningType = upper(@IPVC_ScreeningType);

  IF ( OBJECT_ID('tempdb.dbo.#TEMP_SELECT') > 0 )
  BEGIN
    DROP TABLE #TEMP_SELECT
  END
  ----------------------------------------------------------
  SELECT 
				-- Added to get Subscription orders first.
				rank() OVER ( Partition BY O.CompanyIDSeq, O.PropertyIDSeq 
							ORDER BY (CASE OI.MeasureCode WHEN 'Site' THEN 0 WHEN 'UNIT' THEN 0 ELSE 1 END ),convert(int,PRD.Stockbundleflag) DESC,ActivationStartDate desc) AS _Rank,
        -- Added code to find number of criminal order.  So, we can pick the lowest priority order.
         COUNT(1) over (Partition by O.CompanyIDSeq, 
                                   O.PropertyIDSeq, 
                                   (case when @IPVC_ScreeningType='CREDIT' then 1 else 0 end), 
                                   (case when @IPVC_ScreeningType='CRIMINAL' then 1 else 0 end) 
                      ) as Order_Count,
         O.CompanyIDSeq                                        as OMSCustomerIDSeq,
         CMP.SiteMasterID                                      AS PMCID,
         O.PropertyIDSeq                                       as OMSPropertyIDSeq,
         PRP.SiteMasterID                                      as SiteID,
         OI.OrderIDSeq                                         as OrderIDSeq,
         OI.IDSeq                                              as OrderItemIDSeq, 
         cmp.Name                                              AS PMCName,
         prp.Name                                              AS SiteName,
         cast(NULL AS varchar(22))                             as Invoiceidseq,
         cast(NULL AS bigint )                                 as InvoiceItemIDSeq,
         (SELECT [Name] FROM ORDERS.dbo.OrderStatusType WHERE Code = O.StatusCode )  AS OrderStatus,
         (SELECT [Name] FROM ORDERS.dbo.OrderStatusType WHERE Code = OI.StatusCode )  AS OrderItemStatus,
         OI.Units                                              as Units,
         OI.Beds                                               as Beds, 
         OI.PPUPercentage                                      as PPUPercent,
         OI.EffectiveQuantity                                  as ProratedScreens,
         convert(numeric(30,2),
                        (
                         (case WHEN OI.Frequencycode = 'MN' THEN convert(float,coalesce(OI.Netchargeamount,0)*12)
                               ELSE convert(float,coalesce(OI.Netchargeamount,0))
                          end)
                          /
                         (case when OI.EffectiveQuantity=0 then 1
                               else convert(float,OI.EffectiveQuantity)
                          end)
                         ) 
                 )                                             as Price,
         CAST(CONVERT(varchar(10), OI.ActivationStartDate, 101) AS datetime)     as OrderStartDate,
         CAST(CONVERT(varchar(10), Coalesce(OI.CancelDate,OI.ActivationEndDate), 101) AS datetime)          as OrderEndDate,
         (case when day(OI.ActivationStartDate)=1 then datediff(mm,OI.ActivationStartDate,Coalesce(OI.CancelDate,OI.ActivationEndDate))+1
               else datediff(mm,OI.ActivationStartDate,Coalesce(OI.CancelDate,OI.ActivationEndDate))
          end)                                                                 as ContractLength,
         datediff(mm,OI.ActivationStartDate,@IPDT_ReportMonthEndDate)+1        as ContractMonth,
         (
           (case when day(OI.ActivationStartDate)=1 then datediff(mm,OI.ActivationStartDate,Coalesce(OI.CancelDate,OI.ActivationEndDate))+1
                 else datediff(mm,OI.ActivationStartDate,Coalesce(OI.CancelDate,OI.ActivationEndDate))
            end) -
           (case when datediff(mm,OI.ActivationStartDate,@IPDT_ReportMonthEndDate)+1 < 0 then 0
                 else datediff(mm,OI.ActivationStartDate,@IPDT_ReportMonthEndDate)+1
            end)
         )                                                                    as RemainMonth,
         (case when OI.Measurecode = 'TRAN' then 'TRN'
               else 'ACS'
          end)                                                                as OrderType,
         OI.Frequencycode                                                     as FrequencyCode,
         0                                                                    as PaidForScreens,----Temporary : To be removed later
         substring(Addr.Countrycode,1,2)                                      as Country,
         (case when @IPVC_ScreeningType='CREDIT' then 1 else 0 end)           as CreditUsed,
         (case when @IPVC_ScreeningType='CRIMINAL' then 1 else 0 end)         as CriminalUsed,
         CAST(Addr.AddressLine1 AS varchar(255))                              as AddressLine1,
         cast(Addr.AddressLine2 AS varchar(255))                              as AddressLine2,
         Addr.City                                                            as City,
         Addr.State                                                           as State,
         Addr.Zip                                                             as Zip,
				 Addr.PhoneVoice1																											as Phone,
         cAddr.AddressLine1																	                  as PMCAddressLine1,
         cAddr.AddressLine2																	                  as PMCAddressLine2,
         cAddr.City												                                    as PMCCity,
         cAddr.State												                                  as PMCState,
         cAddr.Zip												                                    as PMCZip,
         cAddr.Countrycode								                                    as PMCCountry,
         cAddr.PhoneVoice1																										as PMCPhone,
         (select top 1 SPM.Priority
               from   PRODUCTS.dbo.ScreeningProductMapping SPM with (nolock)
               where  OI.Productcode = SPM.ProductCode
               and    (
                       (@IPVC_ScreeningType='CREDIT'   and SPM.CreditUsedFlag=1)
                         OR
                       (@IPVC_ScreeningType='CRIMINAL' and SPM.CriminalUsedFlag=1)
                      ) 
              )  AS ProductPriority,
          OI.ProductCode,
          convert(int,PRD.Stockbundleflag) as Stockbundleflag
  ----------------------------------------------------------
  INTO #TEMP_SELECT
  from   ORDERS.dbo.[Order]     O with (nolock)
  inner join
         ORDERS.dbo.[Orderitem] OI with (nolock) 
  on     OI.Orderidseq = O.Orderidseq  
  and    OI.Statuscode    <> 'CNCL'
  and    OI.Familycode     = 'LSD'
  and    OI.Chargetypecode = 'ACS'  
  and    isdate(OI.ActivationStartDate) = 1
  
     and   (
            @IPDT_ReportMonthEndDate >= OI.ActivationStartDate  and
            @IPDT_ReportMonthEndDate <= DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,Coalesce(OI.CancelDate,OI.ActivationEndDate))+1,0))
           )
  
  and  exists (select top 1 1 
               from   PRODUCTS.dbo.ScreeningProductMapping SPM with (nolock)
               where  OI.Productcode = SPM.ProductCode
               and    (
                       (@IPVC_ScreeningType='CREDIT'   and SPM.CreditUsedFlag=1)
                         OR
                       (@IPVC_ScreeningType='CRIMINAL' and SPM.CriminalUsedFlag=1)
                      ) 
              )  
  INNER JOIN PRODUCTS.dbo.Product  PRD WITH (NOLOCK)
  on    OI.Productcode = PRD.Code
  and   OI.Priceversion= PRD.Priceversion
  INNER JOIN CUSTOMERS.dbo.Company cmp WITH (NOLOCK)
  on cmp.IDSeq = O.CompanyIDSeq
  INNER JOIN CUSTOMERS.dbo.Property prp WITH (NOLOCK)
  on prp.IDSeq = O.PropertyIDSeq
  inner join
        CUSTOMERS.dbo.Address Addr with (nolock)
  on    O.Propertyidseq = Addr.Propertyidseq
  and   Addr.Addresstypecode = 'PRO'
  inner join
        CUSTOMERS.dbo.Address cAddr with (nolock)
  on    O.CompanyIDSeq = cAddr.CompanyIDSeq AND cAddr.PropertyIDSeq IS NULL
  and   cAddr.Addresstypecode = 'COM'
  ----------------------------------------------------------
  SELECT 
      -- Added Rank to get Duplicate orders.  So we can pick the latest activated order for screening purpose.
      -- Get one Row for each order so unique CompanyID, PropertyID, CriminalUsed, CreditUsed, ProductCode.
      -- Ordering by ActivationStartdate so we can get lastes order as ranked first.
     rank() over (Partition by TS.OMSCustomerIDSeq, 
                               TS.OMSPropertyIDSeq, 
                               (case when @IPVC_ScreeningType='CREDIT' then 1 else 0 end), 
                               (case when @IPVC_ScreeningType='CRIMINAL' then 1 else 0 end)
                  ORDER BY TS.ProductPriority ASC,TS.Stockbundleflag DESC, TS.OrderStartDate DESC) as Duplicate_Rank,
    * 
  FROM 
    #TEMP_SELECT TS
  WHERE 
		TS._Rank = 1
    AND 
		(
			TS.Order_Count = 1 -- Select if only one order exists.
				-- more then one order found for this property.  Find min Priorityand select that order.
			OR ( TS.Order_Count > 1 AND TS.ProductPriority = (Select MIN(TSS.ProductPriority)
																												FROM #TEMP_SELECT TSS 
																												WHERE TSS.OMSCustomerIDSeq = TS.OMSCustomerIDSeq 
																															AND TSS.OMSPropertyIDSeq = TS.OMSPropertyIDSeq
																															AND TS._Rank = 1
																												)
				)
		)    
    ORDER BY  TS.OMSCustomerIDSeq,TS.OMSPropertyIDSeq,
            TS.Country,TS.CreditUsed,TS.CriminalUsed

  IF ( OBJECT_ID('tempdb.dbo.#TEMP_SELECT') > 0 )
  BEGIN
    DROP TABLE #TEMP_SELECT
  END

END
GO
