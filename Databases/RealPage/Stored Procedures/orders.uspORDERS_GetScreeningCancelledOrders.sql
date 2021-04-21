SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------- 
-- procedure   : uspORDERS_GetScreeningCancelledOrders
-- server      : OMS
-- Database    : ORDERS
 
-- purpose     : Get all cancelled Screening ACCCESS Orders
--
-- Input Param: @IPDT_ReportMonthEndDate datetime -- Month end date of reporting month end
-- returns     : resultset as below

-- Example of how to call this stored procedure:
-- EXEC ORDERS.dbo.uspORDERS_GetScreeningCancelledOrders @IPDT_ReportMonthEndDate = '08/31/2008'

-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 2008-DEC-18	Bhavesh Shah  	Initial creation
-- 2008-DEC-19	Bhavesh Shah		Added IntervalMonth parameter to get data from last x months.
-- 2008-DEC-30	Bhavesh Shah    Added Duplicate Rank Column to determine duplicate orders.
-- 20-9-JAN-07  Bhavesh Shah    Added code to select invoice for specified month.

-- Copyright  : copyright (c) 2008.  RealPage Inc.
-- This module is the confidential & proprietary property of
-- RealPage Inc.
-----------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetScreeningCancelledOrders]   (
	@IPDT_ReportMonthEndDate	datetime
	, @IPVC_ScreeningType     varchar(20)='credit'
	, @IPI_IntervalMonth			int = NULL
) 
AS
BEGIN
  
	SET nocount ON;

	DECLARE @_reportDate DATETIME;
	SET @_reportDate = @IPDT_ReportMonthEndDate
	IF ( NULLIF(@IPI_IntervalMonth, 0) IS NOT NULL )
	BEGIN
		SET @_reportDate = DATEADD(mm, @IPI_IntervalMonth, @IPDT_ReportMonthEndDate );
	END

  ----------------------------------------------------------
  Select 
        -- Added Rank to get Duplicate orders.  So we can pick the latest activated order for screening purpose.
        -- Get one Row for each order so unique CompanyID, PropertyID, CriminalUsed, CreditUsed.
        -- Ordering by ActivationStartdate so we can get lastes order as ranked first.
         rank() over (Partition by coalesce(I.CompanyIDSeq,O.CompanyIDSeq), 
                                   coalesce(I.PropertyIDSeq,O.PropertyIDSeq), 
                                   (case when @IPVC_ScreeningType='credit' then 1 else 0 end), 
                                   (case when @IPVC_ScreeningType='criminal' then 1 else 0 end) 
                      ORDER BY OI.ActivationStartDate DESC) as Duplicate_Rank,
         coalesce(I.CompanyIDSeq,O.CompanyIDSeq)               as OMSCustomerIDSeq,
         coalesce(I.PropertyIDSeq,O.PropertyIDSeq)             as OMSPropertyIDSeq,
         coalesce(II.OrderIDSeq,OI.OrderIDSeq)                 as OrderIDSeq,
         coalesce(II.OrderItemIDSeq,OI.IDSeq)                  as OrderItemIDSeq, 
         II.Invoiceidseq                                       as Invoiceidseq,
         II.IDSeq                                              as InvoiceItemIDSeq,
         (SELECT [Name] FROM ORDERS.dbo.OrderStatusType WHERE Code = O.StatusCode )  AS OrderStatus,
         (SELECT [Name] FROM ORDERS.dbo.OrderStatusType WHERE Code = OI.StatusCode )  AS OrderItemStatus,
         coalesce(II.Units,OI.Units)                           as Units,
         coalesce(II.Beds,OI.Beds)                             as Beds,
         coalesce(II.PPUPercentage,OI.PPUPercentage)           as PPUPercent,
         coalesce(II.EffectiveQuantity,OI.EffectiveQuantity)   as ProratedScreens,
         convert(numeric(30,2),
                        (
                         (case WHEN OI.Frequencycode = 'MN' THEN convert(float,coalesce(II.Netchargeamount,OI.Netchargeamount,0)*12)
                               ELSE convert(float,coalesce(II.Netchargeamount,OI.Netchargeamount,0))
                          end)
                          /
                         (case when coalesce(II.EffectiveQuantity,OI.EffectiveQuantity)=0 then 1
                               else convert(float,coalesce(II.EffectiveQuantity,OI.EffectiveQuantity))
                          end)
                         ) 
                 )                                             as Price,
         OI.ActivationStartDate                                as OrderStartDate,
         OI.ActivationEndDate													         as OrderEndDate,
				 OI.CancelDate																				 AS OrderCancelDate,
         (case when day(OI.ActivationStartDate)=1 then datediff(mm,OI.ActivationStartDate,Coalesce(OI.CancelDate,OI.ActivationEndDate))+1
               else datediff(mm,OI.ActivationStartDate,Coalesce(OI.CancelDate,OI.ActivationEndDate))
          end)                                                                 as ContractLength,
         datediff(mm,OI.ActivationStartDate,@IPDT_ReportMonthEndDate)+1        as ContractMonth,
         (
           (case when day(OI.ActivationStartDate)=1 then datediff(mm,OI.ActivationStartDate,OI.ActivationEndDate)+1
                 else datediff(mm,OI.ActivationStartDate,OI.ActivationEndDate)
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
         substring(coalesce(II.TaxableCountryCode,Addr.Countrycode),1,2)      as Country,
         (case when @IPVC_ScreeningType='credit' then 1 else 0 end)           as CreditUsed,
         (case when @IPVC_ScreeningType='criminal' then 1 else 0 end)         as CriminalUsed,
         coalesce(II.TaxableAddressLine1,Addr.AddressLine1)                   as AddressLine1,
         coalesce(II.TaxableAddressLine2,Addr.AddressLine2)                   as AddressLine2,
         coalesce(II.TaxableCity,Addr.City)                                   as City,
         coalesce(II.TaxableState,Addr.State)                                 as State,
         coalesce(II.TaxableZip,Addr.Zip)                                     as Zip,
				 Addr.PhoneVoice1																											as Phone,
         cAddr.AddressLine1																	                  as PMCAddressLine1,
         cAddr.AddressLine2																	                  as PMCAddressLine2,
         cAddr.City												                                    as PMCCity,
         cAddr.State												                                  as PMCState,
         cAddr.Zip												                                    as PMCZip,
				 cAddr.Countrycode								                                    as PMCCountry,
				 cAddr.PhoneVoice1																										as PMCPhone
  ----------------------------------------------------------
  from   ORDERS.dbo.[Order]     O with (nolock)
  inner join
         ORDERS.dbo.[Orderitem] OI with (nolock) 
  on     OI.Orderidseq = O.Orderidseq
  and    OI.Statuscode    IN ('CNCL','EXPD')
	AND		 coalesce(OI.CancelDate,OI.ActivationEndDate) > @_reportDate
  and    OI.Familycode     = 'LSD' 
  and    OI.Chargetypecode = 'ACS'   
  
  and  exists (select top 1 1 
               from   PRODUCTS.dbo.ScreeningProductMapping SPM	with (nolock)
               where  OI.Productcode = SPM.ProductCode
               and    (
                       (@IPVC_ScreeningType='credit'   and SPM.CreditUsedFlag=1)
                         OR
                       (@IPVC_ScreeningType='criminal' and SPM.CriminalUsedFlag=1)
                      ) 
              )  
  AND NOT exists (select TOP 1 1 
                  FROM   ORDERS.dbo.[Order]     O1 with (nolock)
                  INNER JOIN 
                        Orders.dbo.orderitem   OI1 with (nolock)
                  ON    OI1.Orderidseq = O1.Orderidseq
                  AND   O1.PropertyIDSeq = O.PropertyIDSeq and OI1.ProductCode = OI.productCode 
									and   OI1.Familycode = 'LSD' and OI1.Chargetypecode = 'ACS'                           
									AND   coalesce(OI1.ActivationStartDate,O1.ApprovedDate) > coalesce(OI.CancelDate,OI.ActivationEndDate)
                  AND   OI1.IDSeq <> OI.IDSeq									 
                )
  inner join
        CUSTOMERS.dbo.Address Addr with (nolock)
  on    O.Propertyidseq = Addr.Propertyidseq
  and   Addr.Addresstypecode = 'PRO'
  inner join
        CUSTOMERS.dbo.Address cAddr with (nolock)
  on    O.CompanyIDSeq = cAddr.CompanyIDSeq AND cAddr.PropertyIDSeq IS NULL
  and   cAddr.Addresstypecode = 'COM'
  left outer join
        Invoices.dbo.Invoice I with (nolock)
  on    O.Accountidseq = I.Accountidseq
				AND MONTH(I.InvoiceDate) = MONTH(@IPDT_ReportMonthEndDate)
				AND YEAR(I.InvoiceDate) = YEAR(@IPDT_ReportMonthEndDate)
  left outer join
        Invoices.dbo.Invoiceitem II with (nolock)
  on    OI.Orderidseq = II.Orderidseq
  and   OI.IDSeq      = II.Orderitemidseq
  and   OI.LastBillingPeriodToDate = II.BillingPeriodToDate  
	AND   I.InvoiceIDSeq = II.InvoiceIDSeq
  ----------------------------------------------------------
  ORDER BY  OrderCancelDate, OMSCustomerIDSeq,OMSPropertyIDSeq
END

GO
