SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------- 
-- procedure   : uspORDERS_ScreeningGetOrders
-- server      : OMS
-- Database    : ORDERS
 
-- purpose     : Get all Screening ACCCESS Only Orders
--
-- Input Param: @IPDT_ReportMonthEndDate datetime -- Month end date of reporting month end
--              
-- returns     : resultset as below

-- Example of how to call this stored procedure:
-- EXEC ORDERS.dbo.uspORDERS_ScreeningGetOrders @IPDT_ReportMonthEndDate = '1/31/2009'

-- Date         Author          Comments
-- -----------  -------------   ---------------------------
-- 2009-MAR-30	Bhavesh Shah  	Initial creation
-- 2009-MAY-04	Bhavesh Shah		Added code to make Combo products high priority.

-- Copyright  : copyright (c) 2008.  RealPage Inc.
-- This module is the confidential & proprietary property of
-- RealPage Inc.
-----------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_ScreeningGetOrders] 
(
	@IPDT_ReportMonthEndDate datetime
) 
AS
BEGIN
  set nocount on;

	IF OBJECT_ID('tempdb.dbo.#TEMP_SELECT') IS NOT NULL 
	BEGIN
		DROP TABLE #TEMP_SELECT
	END

	SELECT	
		O.CompanyIDSeq
		, O.PropertyIDSeq
		, O.OrderIDSeq
		, OI.IDSeq
		, OI.ProductCode
		, OI.StatusCode
		, OI.Measurecode
		, OI.ActivationStartDate
		, OI.StartDate
		, O.ApprovedDate
		, OI.CreatedDate
		, SPM.CreditUsedFlag
		, SPM.CriminalUsedFlag
		--, OI.*
		, 0 AS IsCombo
		, convert(int, prd.stockbundleflag) as stockbundleflag
	INTO #TEMP_SELECT
	FROM  ORDERS.dbo.[Order] O WITH (NOLOCK)
	INNER JOIN 
				Orders.dbo.OrderItem OI WITH (NOLOCK)
	ON    O.OrderIDSeq = OI.OrderIDSeq  
	and   OI.Familycode     = 'LSD'
	and   OI.Chargetypecode = 'ACS'
	and   isdate(OI.ActivationStartDate) = 1
	and   (
					@IPDT_ReportMonthEndDate >= OI.ActivationStartDate 
										AND
					@IPDT_ReportMonthEndDate <= DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,Coalesce(OI.CancelDate,OI.ActivationEndDate))+1,0))
				)
	INNER JOIN 
				Products.dbo.ScreeningProductMapping SPM WITH (NOLOCK)
	ON    OI.ProductCode = SPM.ProductCode
	AND   SPM.Priority   = (Select MIN(SM.Priority) 
													FROM   Products.dbo.ScreeningProductMapping SM WITH (NOLOCK) 
													WHERE  SM.ProductCode = OI.ProductCode
													)
    Inner Join Products.dbo.Product PRD with (nolock)
	on oi.productcode = prd.code and oi.priceversion = prd.priceversion
	WHERE OI.Familycode     = 'LSD'
	and   OI.Chargetypecode = 'ACS'
	and   isdate(OI.ActivationStartDate) = 1
	and   (
					@IPDT_ReportMonthEndDate >= OI.ActivationStartDate 
										AND
					@IPDT_ReportMonthEndDate <= DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,Coalesce(OI.CancelDate,OI.ActivationEndDate))+1,0))
				)
	-------------------------------------------------------------------
	---Generate Split Records for CreditUsed=1 and CriminalUsed=1
	INSERT INTO #TEMP_SELECT
				 (CompanyIDSeq,PropertyIDSeq,OrderIDSeq,IDSeq,ProductCode,StatusCode,Measurecode,ActivationStartDate,StartDate,ApprovedDate,CreatedDate,stockbundleflag,CreditUsedFlag,CriminalUsedFlag,IsCombo)
	SELECT 
		CompanyIDSeq,PropertyIDSeq,OrderIDSeq,IDSeq,ProductCode,StatusCode,Measurecode,ActivationStartDate,StartDate,ApprovedDate,CreatedDate,stockbundleflag,CreditUsedFlag,0,1
	FROM #TEMP_SELECT WITH (NOLOCK) WHERE CreditUsedFlag = 1 AND CriminalUsedFlag = 1
	UNION
	SELECT 
		CompanyIDSeq,PropertyIDSeq,OrderIDSeq,IDSeq,ProductCode,StatusCode,Measurecode,ActivationStartDate,StartDate,ApprovedDate,CreatedDate,stockbundleflag,0,CriminalUsedFlag,1
	FROM #TEMP_SELECT WITH (NOLOCK) WHERE CreditUsedFlag = 1 AND CriminalUsedFlag = 1
	-------------------------------------------------------------------
	---Delete CreditUsed=1 and CriminalUsed=1
	DELETE FROM #TEMP_SELECT WHERE CreditUsedFlag = 1 AND CriminalUsedFlag = 1;
	-------------------------------------------------------------------
	---Final Select
	; WITH TEMP_SELECT AS
		(
		 SELECT 
				 RANK() OVER (Partition BY CompanyIDSeq, PropertyIDSeq,CreditUsedFlag,CriminalUsedFlag 
											ORDER BY (CASE WHEN MeasureCode != 'TRAN' THEN 0 ELSE 1 END)    ASC,stockbundleflag DESC,
																IsCombo ASC,
																Coalesce(ActivationStartDate, StartDate, CreatedDate) DESC,
																IDSeq DESC
											)  AS dupRank -- Added IsCombo to pick Combo Products first.
			, * 
		 FROM #TEMP_SELECT WITH (NOLOCK)
		)

		SELECT 
		 COUNT(1) OVER ( Partition BY TS.CompanyIDSeq, TS.PropertyIDSeq) AS OrderCount,
     TS.CompanyIDSeq                                       as CustomerIDSeq,
     CMP.SiteMasterID                                      AS PMCID,
		 CMP.StatusTypecode																		 AS CompanyStatusCode,
     TS.PropertyIDSeq                                      as PropertyIDSeq,
		 O.AccountIDSeq																		     AS AccountIDSeq,
     PRP.SiteMasterID                                      as SiteID,
     PRP.StatusTypeCode																		 AS PropertyStatusCode,
     TS.OrderIDSeq                                         as OrderIDSeq,
     TS.IDSeq                                              as OrderItemIDSeq, 
		 OI.OrderGroupIDSeq																		 AS OrderGroupIDSeq,
     OI.ProductCode																				 AS ProductCode,
		 OI.PriceVersion																			 AS PriceVersion,
		 OI.ExtChargeAmount																		 AS ExtChargeAmount,
		 OI.DiscountAmount																		 AS DiscountAmount,
		 OI.NetChargeAmount																		 AS NetChargeAmount,
     cmp.Name                                              AS PMCName,
     prp.Name                                              AS SiteName,
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
		 OI.Measurecode																												AS Measurecode,
     OI.Frequencycode                                                     as FrequencyCode,
		 OI.ChargeTypeCode																										AS ChargeTypeCode,
     TS.CreditUsedFlag																					          as CreditUsed,
     TS.CriminalUsedFlag																					        as CriminalUsed,
		 CASE WHEN TS.CreditUsedFlag = 1 THEN 'CREDIT' ELSE 'CRIMINAL' END    AS [Type],
     CAST(Addr.AddressLine1 AS varchar(255))                              as AddressLine1,
     cast(Addr.AddressLine2 AS varchar(255))                              as AddressLine2,
     Addr.City                                                            as City,
     Addr.State                                                           as State,
     Addr.Zip                                                             as Zip,
     substring(Addr.Countrycode,1,2)                                      as Country,
		 Addr.PhoneVoice1																											as Phone,
     cAddr.AddressLine1																	                  as PMCAddressLine1,
     cAddr.AddressLine2																	                  as PMCAddressLine2,
     cAddr.City												                                    as PMCCity,
     cAddr.State												                                  as PMCState,
     cAddr.Zip												                                    as PMCZip,
     cAddr.Countrycode								                                    as PMCCountry,
     cAddr.PhoneVoice1																										as PMCPhone,
		 @IPDT_ReportMonthEndDate																							AS ReportMonthEndDate
		--INTO ScreeningTransactions.dbo.OMSOrderTranslation
		FROM  TEMP_SELECT TS
			INNER JOIN Orders.dbo.[Order] O WITH (NOLOCK)
				ON O.OrderIDSeq = TS.OrderIDSeq
			INNER JOIN Orders.dbo.OrderItem OI WITH (NOLOCK)
				ON OI.IDSeq = TS.IDSeq
			INNER JOIN CUSTOMERS.dbo.Company cmp WITH (NOLOCK)
			on cmp.IDSeq = TS.CompanyIDSeq
			INNER JOIN CUSTOMERS.dbo.Property prp WITH (NOLOCK)
			on prp.IDSeq = TS.PropertyIDSeq
			inner join
						CUSTOMERS.dbo.Address Addr with (nolock)
			on    TS.Propertyidseq = Addr.Propertyidseq
			and   Addr.Addresstypecode = 'PRO'
			inner join
						CUSTOMERS.dbo.Address cAddr with (nolock)
			on    TS.CompanyIDSeq = cAddr.CompanyIDSeq AND cAddr.PropertyIDSeq IS NULL
			and   cAddr.Addresstypecode = 'COM'

		WHERE dupRank = 1
		ORDER BY TS.CompanyIDSeq, TS.PropertyIDSeq, substring(Addr.Countrycode,1,2)  ASC,dupRank ASC
	-------------------------------------------------------------------

END

GO
