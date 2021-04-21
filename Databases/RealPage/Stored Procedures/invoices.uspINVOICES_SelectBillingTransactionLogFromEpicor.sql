SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [invoices].[uspINVOICES_SelectBillingTransactionLogFromEpicor]
@BeginRange datetime	-- beginning date applied to GL
, @EndRange Datetime	-- ending date applied to GL
, @TransactionType CHAR(1) = NULL	-- I for Invoices, C for Credits, or A for All transactions
, @NetBeforeTax decimal (15,2) = NULL
, @RevTierDesc varchar (100) = NULL
, @LineDesc varchar (100) = NULL
, @Qty decimal (15,4) = NULL

as
BEGIN
/********************************************************************************************************/
--  database server:  RPIDALEPD001 platinum database server for production; TEST = MISTSTEPD001			
--  database name:  INVOICES (both production and test)							
--  Purpose:  This selects a month's transactions from the INVOICES.dbo.BillingTransactionLog table
--		with detailed data from the INVOICES database		     			
-- 		on RPIDALEPD001.  This is used by Barbara Kaplan's group (Client Services) and			    	 		
-- 		F&A to tie the Platinum numbers to the revenue report.					
--  parameters:  @BeginRange - begin date to use for date_applied criteria (month begin date)		
--  		@EndRange = end date to use for date_applied criteria (month ending date)			
-- 			don't need timestamp; Platinum doesn't store time on applied date 		
--		@TransactionType = I for Invoices, C for Credits, or A for All transactions with DEFAULT OF NULL
---- THIS REPORT SHOULD BE SENT TO DAVID LUNDAY, CATRICIA WILLIAMS, AND GERLINDE SMITH.
-- EXAMPLE OF CALLING THIS PROC:
-- EXEC uspINVOICES_SelectBillingTransactionLogFromEpicor '02/01/2005', '02/28/2005'
-- 1. Pass correct dates, and email the results to recepients listed above. (below parameters)			
-- 2. Save the xls file to U:\MIS\MIS Internal\FinancialReportsMoEnd as YYYYMMRevenueDump.		
-- 		(\\rpidalefs001\groups\MIS\MIS Internal\FinancialReportsMoEnd)			
--  Date		Login		Description	
-----------------------------------------------------------------------------------------								
-- 2007/11/13	Gwen Guidroz	Initial creation to accommodate OMS generated invoices
/********************************************************************************************************/
set nocount on

--declare @BeginRangeInt int, @EndRangeInt int
--set @BeginRangeInt = datediff(dd, '1/1/1753', @BeginRange) + 639906	--Convert beginning date to Platinum's integer date equivalent
--set @EndRangeInt = datediff(dd, '1/1/1753', @EndRange) + 639906		--Convert ending date to Platinum's integer date equivalent
IF (@TransactionType IS NULL OR @TransactionType = ' ') SET @TransactionType = 'A'
IF @TransactionType NOT IN ('A', 'I', 'C') SET @TransactionType = 'A' 
SET @TransactionType = UPPER(@TransactionType)	-- SET the value passed to uppercase

-- select data
SELECT [Invoice],
EpicorBatchCode,
o.Sieb77OrderID [Siebel Order ID] ,
[TranType] AS 'Trans Type',
[New Existing Code],
[freight code] AS 'Freight Code',
btl.AccountIDSeq as [Account ID],
[SITE ID] AS 'Site ID',
[SITE NAME] AS 'Site Name',
CAST([UnitCount] AS INT) AS 'Unit Count',
[PMC ID],
[PMC NAME] AS 'PMC Name',
[Qty],
[ActualUnitsAffected] AS 'Actual Units Affected',
[GLRevenueAcct] AS 'GL Account',		-- renamed from GL Revenue Account
[GrossAmt] AS 'Gross Amount',
[Discount],
[Deferred Discount],
[Freight],
--[PPU_Adjustment] AS 'PPU Adj',		-- do we need this?
[Net Before Tax],
[Tax],
[RevTierCode] AS 'Revenue Tier Code',
[RevTierDescription] AS 'Revenue Tier Description',
[Line Description],
ct.[Name] AS [Charge Type],
f.[Name] AS [Frequency],
[Pricing Method],
CONVERT(CHAR(10),[Invoice Date],101)'Invoice Date',
CONVERT(CHAR(10),[Apply Date],101) 'Apply Date',
isnull(os.[name],[Contract Status]) AS [Order Item Status],
CONVERT(CHAR(10),[Billing Period Start],101) AS [Billing Period Start], --td# 2738 on 01-Dec-2006
CONVERT(CHAR(10),[Billing Period End],101) AS [Billing Period End], --td# 2738 on 01-Dec-2006
[ShipToState] AS 'Ship To State',
[Platinum_Number] AS 'Epicor Customer Code',
[Reg Code],				-- DON'T HAVE THIS YET
--[OrderItem_RowId] AS 'Order Item Row ID',
--[InvoiceItemIDSeq] AS [Invoice Item ID]
--[PPU_3996_Flag] AS 'PPU 3996 Flag',
[Apply To Invoice],
CONVERT(CHAR(10),[Apply Date Of Invoice],101) 'Apply Date Of Invoice',
btl.ApplyToInvoiceDate AS [Apply To Invoice Date],		-- CHANGE DATA SOURCE TO NOT POPULATE FOR INVOICES
[Credit Reason],
[Invoice PriceList Name],
PriceVersion AS [Schedule of Charges Version],
--[Siebel Contract#],
--[Invoice Comment],
--[Internal Comment],
[Current PMC ID],
[Current PMC Name]
-- ,[ShipToAccountNum] --Gwen Guidroz 2006-2-3 commented the ship to address columns and SequenceID.  We were not reporting on these
-- ,[ShipToAddress]	-- in previous months.  If we add them, we need to strip carriage returns from the [ShipToAddress] column
-- ,[ShipToCity]	-- or modify the insert proc to strip the carriage returns
-- ,[ShipToZip]
-- ,[ShipToCounty]
-- ,[SequenceID]
,[CurrentDatabaseID] AS 'Current Database ID'
--,[Master OrderID] AS 'Master Order ID'
--,CONVERT(CHAR(10),[Master OrderStartDate],101) AS 'Master Order Start Date'
--,CONVERT(CHAR(10),[Master OrderEnd Date],101) AS 'Master Order End Date'
--,[OrderHeaderComments] AS 'Order Header Comments',
,btl.QuoteIDSeq [Quote ID]
-- ,[RunDateTime] ---this helps to know when it was actually run - we may not need to display in the final report 
,CONVERT(CHAR(10),[Contract SDate],101) AS 'Contract Start Date', --td# 2738 on 01-Dec-2006
CONVERT(CHAR(10),[Contract EDate],101) AS 'Contract End Date' --td# 2738 on 01-Dec-2006
,p.[Name] AS [Platform]
,pf.[Name] AS [Family]
,c.[Name] AS [Category]
,btl.ProductCode [Product Code]
--,pt.[Name] AS [Product Type]			--WHY IS THIS SHOWING AS NULL
FROM  INVOICES.dbo.BillingTransactionLog btl with (nolock)
LEFT OUTER JOIN orders.dbo.[order] o with (nolock) on btl.orderidseq=o.orderidseq
LEFT OUTER JOIN PRODUCTS.dbo.ChargeType ct with (nolock) on btl.ChargeTypeCode=ct.Code
LEFT OUTER JOIN PRODUCTS.dbo.Frequency f with (nolock) on btl.FrequencyCode=f.Code
LEFT OUTER JOIN PRODUCTS.dbo.Platform p with (nolock) on btl.PlatformCode=p.Code
left outer join PRODUCTS.dbo.Family pf with (nolock) on btl.FamilyCode=pf.Code
LEFT OUTER JOIN PRODUCTS.dbo.Category c with (nolock) ON btl.CategoryCode=c.Code
left outer join products.dbo.ProductType pt with (nolock) on btl.producttypecode=pt.Code
LEFT OUTER JOIN orders.dbo.orderstatustype os with (nolock) on btl.[Contract Status]=os.Code
where [Apply Date] BETWEEN @BeginRange AND @EndRange
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
@TransactionType = 'A' 
OR (@TransactionType = 'I' and [TranType] = 2031)
OR (@TransactionType = 'C' and [TranType] = 2032)
)
order by Invoice,RevTierCode, [Line Description]


END

GO
