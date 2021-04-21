SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [invoices].[uspINVOICES_SelectBillingTransactionLog]
                             ( @BeginRange       datetime	-- beginning date applied to GL
                              ,@EndRange         datetime	-- ending date applied to GL
                              ,@TransactionType  char(1) = NULL -- I for Invoices, C for Credits, or A for All transactions
                              ,@NetBeforeTax     decimal (15,2) = NULL
                              ,@RevTierDesc      varchar (100)  = NULL
                              ,@LineDesc         varchar (100)  = NULL
                              ,@Qty              decimal (15,4) = NULL
                             )
as
BEGIN ---> Main BEGIN
/********************************************************************************************************/
--  database server:  RPIDALEPD001 platinum database server for production; TEST = MISTSTEPD001			
--  database name  :  INVOICES (both production and test)							
--  Purpose        :  This selects a month's transactions from the INVOICES.dbo.BillingTransactionLog table
--		      with detailed data from the INVOICES database		     			
-- 		      on RPIDALEPD001.  This is used by Barbara Kaplan's group (Client Services) and			    	 		
-- 		      F&A to tie the Platinum numbers to the revenue report.					
--  parameters     :  @BeginRange - begin date to use for date_applied criteria (month begin date)		
--  		      @EndRange = end date to use for date_applied criteria (month ending date)			
-- 		      don't need timestamp; Platinum doesn't store time on applied date 		
--		      @TransactionType = I for Invoices, C for Credits, or A for All transactions with DEFAULT OF NULL
-- THIS REPORT SHOULD BE SENT TO DAVID LUNDAY, CATRICIA WILLIAMS, AND GERLINDE SMITH.
-- EXAMPLE OF CALLING THIS PROC:
-- EXEC uspINVOICES_SelectBillingTransactionLog '02/01/2005', '02/28/2005'
-- 1. Pass correct dates, and email the results to recepients listed above. (below parameters)			
-- 2. Save the xls file to U:\MIS\MIS Internal\FinancialReportsMoEnd as YYYYMMRevenueDump.		
-- 		(\\rpidalefs001\groups\MIS\MIS Internal\FinancialReportsMoEnd)			
--  Date		Login		Description	
-----------------------------------------------------------------------------------------								
-- 2007/11/13	Gwen Guidroz	Initial creation to accommodate OMS generated invoices
/********************************************************************************************************/
  set nocount on
--------------------------------------------------------------------------------
  --declare @BeginRangeInt int, @EndRangeInt int
  --set @BeginRangeInt = datediff(dd, '1/1/1753', @BeginRange) + 639906	--Convert beginning date to Platinum's integer date equivalent
  --set @EndRangeInt = datediff(dd, '1/1/1753', @EndRange) + 639906	--Convert ending date to Platinum's integer date equivalent
--------------------------------------------------------------------------------
  IF (@TransactionType IS NULL OR @TransactionType = ' ') 
  begin
    SET @TransactionType = 'A'
  end  
  IF @TransactionType NOT IN ('A', 'I', 'C') 
  begin
    SET @TransactionType = 'A' 
  end
  SET @TransactionType = UPPER(@TransactionType) -- SET the value passed to uppercase
--------------------------------------------------------------------------------
-- select data
  SELECT [Invoice]                                           as [Invoice]
         ,o.Sieb77OrderID                                    as [Siebel Order ID]
         ,[TranType]                                         as [Trans Type]
         ,[New Existing Code]                                as [New Existing Code]
         ,[freight code]                                     as [Freight Code]
         ,[SITE ID]                                          as [Site ID]
         ,[SITE NAME]                                        as [Site Name]
         ,CAST([UnitCount] as INT)                           as [Unit Count]
         ,[PMC ID]                                           as [PMC ID]
         ,[PMC NAME]                                         as [PMC Name]
         ,[Qty]                                              as [Qty]
         ,[ActualUnitsAffected]                              as [Actual Units Affected]
         ,[GLRevenueAcct]                                    as [GL Account] -- renamed from GL Revenue Account
         ,[GrossAmt]                                         as [Gross Amount]
         ,[Discount]                                         as [Discount]
         ,[Deferred Discount]                                as [Deferred Discount]
         ,[Freight]                                          as [Freight]
         --,[PPU_Adjustment]                                 as [PPU Adj] -- do we need this?
         ,[Net Before Tax]                                   as [Net Before Tax]
         ,[Tax]                                              as [Tax]
         ,[RevTierCode]                                      as [Revenue Tier Code]
         ,[RevTierDescription]                               as [Revenue Tier Description]
         ,[Line Description]                                 as [Line Description]
         ,ct.[Name]                                          as [Charge Type]
         ,f.[Name]                                           as [Frequency]
         ,[Pricing Method]                                   as [Pricing Method]
         ,CONVERT(CHAR(10),[Invoice Date],101)               as [Invoice Date]
         ,CONVERT(CHAR(10),[Apply Date],101)                 as [Apply Date]
         ,isnull(os.[name],[Contract Status])                as [Order Item Status]
         ,CONVERT(CHAR(10),[Billing Period Start],101)       as [Billing Period Start] --td# 2738 on 01-Dec-2006
         ,CONVERT(CHAR(10),[Billing Period End],101)         as [Billing Period End] --td# 2738 on 01-Dec-2006
         ,[ShipToState]                                      as [Ship To State]
         ,[Platinum_Number]                                  as [Epicor Customer Code]
         ,[Reg Code]			                     as [Reg Code] -- DON'T HAVE THIS YET
         --,[OrderItem_RowId]                                as [Order Item Row ID]
         --,[InvoiceItemIDSeq]                               as [Invoice Item ID]
         --,[PPU_3996_Flag]                                  as [PPU 3996 Flag]
         ,[Apply To Invoice]                                 as [Apply To Invoice] 
         ,CONVERT(CHAR(10),[Apply Date Of Invoice],101)      as [Apply Date Of Invoice]
         ,btl.ApplyToInvoiceDate                             as [Apply To Invoice Date]-- CHANGE DATA SOURCE TO NOT POPULATE FOR INVOICES
         ,[Credit Reason]                                    as [Credit Reason]
         ,[Invoice PriceList Name]                           as [Invoice PriceList Name]
         ,PriceVersion                                       as [Schedule of Charges Version]
         --,[Siebel Contract#]                               as [Siebel Contract#] 
         --,[Invoice Comment]                                as [Invoice Comment]
         --,[Internal Comment]                               as [Internal Comment]
         ,[Current PMC ID]                                   as [Current PMC ID]
         ,[Current PMC Name]                                 as [Current PMC Name]
         --,[ShipToAccountNum]                               as [ShipToAccountNum]--Gwen Guidroz 2006-2-3 commented the ship to address columns and SequenceID.  We were not reporting on these
         --,[ShipToAddress]                                  as [ShipToAddress]   -- in previous months.  If we add them, we need to strip carriage returns from the [ShipToAddress] column
         --,[ShipToCity]	                             as [ShipToCity]      -- or modify the insert proc to strip the carriage returns
         --,[ShipToZip]                                      as [ShipToZip]
         --,[ShipToCounty]                                   as [ShipToCounty]
         --,[SequenceID]                                     as [SequenceID]
         ,[CurrentDatabaseID]                                as [Current Database ID]
         --,[Master OrderID]                                 as [Master Order ID]
         --,CONVERT(CHAR(10),[Master OrderStartDate],101)    as [Master Order Start Date]
         --,CONVERT(CHAR(10),[Master OrderEnd Date],101)     as [Master Order End Date]
         --,[OrderHeaderComments]                            as [Order Header Comments]
         ,btl.QuoteIDSeq                                     as [Quote ID]
         --,[RunDateTime]                                    as [RunDateTime] ---this helps to know when it was actually run - we may not need to display in the final report 
         ,CONVERT(CHAR(10),[Contract SDate],101)             as [Contract Start Date] --td# 2738 on 01-Dec-2006
         ,CONVERT(CHAR(10),[Contract EDate],101)             as [Contract End Date] --td# 2738 on 01-Dec-2006
         ,p.[Name]                                           as [Platform]
         ,pf.[Name]                                          as [Family]
         ,c.[Name]                                           as [Category]
         ,btl.ProductCode                                    as [Product Code]
         --,pt.[Name]                                        as [Product Type]  --WHY IS THIS SHOWING as NULL
  FROM  INVOICES.dbo.BillingTransactionLog   btl  with (nolock)
  left outer join orders.dbo.[order]         o    with (nolock) on btl.orderidseq       =o.orderidseq
  left outer join PRODUCTS.dbo.ChargeType    ct   with (nolock) on btl.ChargeTypeCode   =ct.Code
  left outer join PRODUCTS.dbo.Frequency     f    with (nolock) on btl.FrequencyCode    =f.Code
  left outer join PRODUCTS.dbo.Platform      p    with (nolock) on btl.PlatformCode     =p.Code
  left outer join PRODUCTS.dbo.Family        pf   with (nolock) on btl.FamilyCode       =pf.Code
  left outer join PRODUCTS.dbo.Category      c    with (nolock) ON btl.CategoryCode     =c.Code
  left outer join products.dbo.ProductType   pt   with (nolock) on btl.producttypecode  =pt.Code
  left outer join orders.dbo.orderstatustype os   with (nolock) on btl.[Contract Status]=os.Code
  where [Invoice Date] BETWEEN @BeginRange AND @EndRange
  AND
  (
   @NetBeforeTax IS NULL
   OR (@NetBeforeTax = [Net Before Tax])
  )
  AND
  (
   @RevTierDesc IS NULL
   OR (@RevTierDesc = [RevTierDescription])
  )
  AND
  (
   @LineDesc IS NULL
  OR (@LineDesc = [Line Description])
  )
  AND
  (
   @Qty IS NULL
  OR (@Qty = [Qty])
  )
  AND 
  (
   @TransactionType    = 'A' 
  OR (@TransactionType = 'I' and [TranType] = 2031)
  OR (@TransactionType = 'C' and [TranType] = 2032)
  )
  order by [Invoice],[RevTierCode],[Line Description]
END---> Main END

GO
