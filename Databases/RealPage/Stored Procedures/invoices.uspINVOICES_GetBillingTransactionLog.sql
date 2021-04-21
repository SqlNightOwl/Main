SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [invoices].[uspINVOICES_GetBillingTransactionLog]
                                                        (@BeginInvoiceDate datetime,
                                                         @EndInvoiceDate   datetime
                                                        )
as
BEGIN ---> Main Begin
  --declare @BeginRange datetime, @EndRange Datetime
  --SELECT @BeginRange='10/01/2004', @EndRange='10/31/2004 23:59:59'
/************************************************************************************************************/
--  database server:  dal5 platinum database server for production; TEST = DEVSQL7			
--  database name  :  Invoice (both production and test)							
--  created stored procedure invoice.dbo.uspINVOICES_GetBillingTransactionLog. gguidroz 11/2/2004			
--  Purpose        :  This creates a "revenue dump" with detailed data from the Invoice database		     			
-- 		      on DAL5.  This is used by Barbara Kaplan's group (Client Services) and			    	 		
-- 		      F&A to tie the Platinum numbers to the revenue report.					
--  parameters     :  @BeginRange - begin date to use for date_applied criteria (month begin date)		
--  		      @EndRange = end date to use for date_applied criteria (month ending date)			
-- 		      don't need timestamp; Platinum doesn't store time on applied date 		
-- THIS REPORT SHOULD BE SENT TO DAVID LUNDAY, CATRICIA WILLIAMS, AND GERLINDE SMITH.
-- EXAMPLE OF CALLING THIS PROC:
-- EXEC uspINVOICES_GetBillingTransactionLog '02/01/2005', '02/28/2005'
--  1. Pass correct dates, and email the results to recepients listed above.					
--  2. Save the xls file to U:\MIS\MIS Internal\FinancialReportsMoEnd as YYYYMMRevenueDump.		
-- 		(\\rpidalefs001\groups\MIS\MIS Internal\FinancialReportsMoEnd)			
------------------------ MODIFICATION HISTORY ------------------------------------------
--  Date		Login			Description									
--  ------------------------------------------------------------------------------------
-- 2007/11/12	gWEN GUIDROZ	initial creation.
/**************************************************************************************************************/
  set nocount on
  ----------------------------------------------------
  declare @RunDateTime DATETIME
  --declare @BeginRangeInt int, @EndRangeInt int, @RunDateTime DATETIME
  --set @BeginRangeInt = datediff(dd, '1/1/1753', @BeginRange) + 639906	--Convert beginning date to Platinum's integer date equivalent
  --set @EndRangeInt = datediff(dd, '1/1/1753', @EndRange) + 639906	--Convert ending date to Platinum's integer date equivalent
  SET @RunDateTime = GETDATE()
  ----------------------------------------------------
  -- Create Temp Table for billing transaction data
  Create Table #LT_BillingTransactionLog
                        (Invoice                       varchar(16)
                         ,TranType                     smallint 
                         ,[New Existing Code]          varchar(16) 
                         ,[freight code]               varchar(8) 
                         ,[SITE NAME]                  varchar(100) -- [SITE NAME] is declared first in the table definition but 2nd in the INSERT and SELECT statements
                         ,[SITE ID]                    varchar(50)  -- because [SITE NAME] is first in the BillingTransactionLog table but the report has historically
                         ,UnitCount                    decimal (22,7)-- included [SITE ID] first.  Gwen Guidroz 1/18/2006
                         ,[PMC ID]                     varchar(50)
                         ,[PMC NAME]                   varchar(100) 
                         ,Qty                          decimal(15,4) 
                         ,[ActualUnitsAffected]        decimal (15,4)
                         ,GLRevenueAcct                varchar(32) 
                         ,GrossAmt                     decimal(15,2)
                         ,Discount                     decimal(15,2)
                         ,[Deferred Discount]          decimal(15,2) 
                         ,Freight                      decimal(15,2) 
                         ,PPU_Adjustment               decimal(15,2)
                         ,[Net Before Tax]             decimal(15,2)
                         ,Tax                          decimal(15,2)
                         ,RevTierCode                  varchar(30)
                         ,RevTierDescription           varchar(100)
                         ,[Line Description]           varchar(120)
                         ,[Pricing Method]             varchar(30)
                         ,[Invoice Date]               smalldatetime
                         ,[Apply Date]                 datetime
                         ,[Contract Status]            varchar(30)
                         ,[Billing Period Start]       datetime --td# 2738
                         ,[Billing Period End]         datetime --td# 2738
                         ,[ShipToState]                varchar(40)
                         ,[Platinum_Number]            varchar(30)
                         ,[Reg Code]                   varchar(30)
                         ,[OrderItem_RowId]            varchar(15)
                         ,[PPU_3996_Flag]              varchar(1)
                         ,[Apply To Invoice]           varchar(16) --defect#1946
                         ,[Apply Date Of Invoice]      datetime --defect#1946
                         ,[Credit Reason]              varchar(250)
                         ,[Invoice PriceList Name]     varchar(50)
                         ,[Siebel Contract#]           varchar(16) --defect#1996
                         ,[Invoice Comment]            varchar(250)
                         ,[Internal Comment]           varchar(250)
                         ,[Current PMC ID]             varchar(50)
                         ,[Current PMC Name]           varchar(100)
                         ,ShipToAccountNum             varchar(50)
                         ,ShipToAddress                varchar(40) --Epicor table only holds 40 characters for address line1
                         ,ShipToCity                   varchar(40) --Epicor table only holds 40 characters for city
                         ,ShipToZip                    varchar(40)	
                         ,ShipToCounty                 varchar(50)
                         ,CurrentDatabaseID            varchar(15)
                         ,[Master OrderID]             varchar(15)
                         ,[Master OrderStartDate]      datetime
                         ,[Master OrderEnd Date]       datetime
                         ,[OrderHeaderComments]        varchar(255)
                         ,[SiebelProductID]            varchar(15)
                         ,[Rundatetime]                datetime
                         ,[Contract SDate]             datetime
                         ,[Contract EDate]             datetime
                         ,[InvoiceIDSeq]               varchar(22) NULL
                         ,[InvoiceItemIDSeq]           bigint      NULL
	                 ,[CreditMemoIDSeq]            varchar(22) NULL
                  	 ,[CreditMemoItemIDSeq]        bigint NULL
                   	 ,[OrderIDSeq]                 varchar(22) NULL
	                 ,[OrderItemIDSeq]             bigint NULL
	                 ,[OrderGroupIDSeq]            bigint NULL
	                 ,[CreditReasonTypeCode]       varchar(6) 
	                 ,[ProductCode]                varchar(30) 
	                 ,[ChargeTypeCode]             char(3) 
	                 ,[FrequencyCode]              char(6) 
	                 ,[MeasureCode]                char(6) 
	                 ,[PriceVersion]               numeric(18,0) NULL
	                 ,[ApplyToInvoiceDate]         datetime NULL
	                 ,[QuoteIDSeq]                 varchar(22) 
	                 ,[PlatformCode]               char(3) 
	                 ,[FamilyCode]                 char(3) 
	                 ,[CategoryCode]               char(3) 
	                 ,[ProductTypeCode]            char(3)
                        )
  ----------------------------------------------------
  Insert into #LT_BillingTransactionLog
                   ([Invoice]
                    ,[TranType]
                    ,[New Existing Code]
                    ,[freight code]
                    ,[SITE ID]
                    ,[SITE NAME]
                    ,[UnitCount]
                    ,[PMC ID]
                    ,[PMC NAME]
                    ,[Qty]
                    ,[ActualUnitsAffected]
                    ,[GLRevenueAcct]
                    ,[GrossAmt]
                    ,[Discount]
                    ,[Deferred Discount]
                    ,[Freight]
                    --,[PPU_Adjustment]
                    ,[Net Before Tax]
                    ,[Tax]
                    ,[RevTierCode]
                    ,[RevTierDescription]
                    ,[Line Description]
                    ,[Pricing Method]
                    ,[Invoice Date]
                    ,[Apply Date]
                    ,[Contract Status]
                    ,[Billing Period Start] --td# 2738 on 01-Dec-2006
                    ,[Billing Period End]   --td#2738 on 01-Dec-2006
                    ,[ShipToState]
                    ,[Platinum_Number]
                    ,[Reg Code]
                    ,[OrderItem_RowId]
                    ,[PPU_3996_Flag]
                    ,[Apply To Invoice]
                    ,[Apply Date Of Invoice]
                    ,[Credit Reason]
                    ,[Invoice PriceList Name]
                    ,[Siebel Contract#]
                    ,[Invoice Comment]
                    ,[Internal Comment]
                    ,[Current PMC ID]
                    ,[Current PMC Name]
                    ,[ShipToAccountNum]
                    ,[ShipToAddress]
                    ,[ShipToCity]
                    ,[ShipToZip]
                    ,[ShipToCounty] 
                    ,[CurrentDatabaseID]
                    ,[Master OrderID]
                    ,[Master OrderStartDate] 
                    ,[Master OrderEnd Date] 
                    ,[OrderHeaderComments] 
                    ,[SiebelProductID] 
                    ,[RunDateTime]
                    ,[Contract SDate]
                    ,[Contract EDate]
                    ,[InvoiceIDSeq] 
                    ,[InvoiceItemIDSeq] 
	            ,[CreditMemoIDSeq] 
                    ,[CreditMemoItemIDSeq] 
	            ,[OrderIDSeq] 
            	    ,[OrderItemIDSeq] 
	            ,[OrderGroupIDSeq]
	            ,[CreditReasonTypeCode]  
	            ,[ProductCode]  
	            ,[ChargeTypeCode]  
	            ,[FrequencyCode]  
	            ,[MeasureCode] 
	            ,[PriceVersion] 
	            ,[ApplyToInvoiceDate] 
	            ,[QuoteIDSeq]
	            ,[PlatformCode]  
	            ,[FamilyCode]  
	            ,[CategoryCode] 
	            ,[ProductTypeCode] 
                    )
    ------------- THIS INSERT IS FOR INVOICES ONLY.  CREDITS NEED TO BE REVIEWED.
   SELECT    ii.InvoiceIDSeq        as [Invoice]
	     ,2031                   as [TranType]        -- this is only invoices
	     ,''                     as [New Existing Code]  -- added a new column on 23/01/03 - Sadeqa
	     ,'Sales'                as [freight code] 
	     ,i.PropertyIDSeq        as [SITE ID] 
	     ,i.PropertyName         as [SITE NAME]
	     ,i.Units                as [UnitCount] --changed this from S.X_NUMBER_OF_UNITS to h.num_units - 26-Aug-2005(SA)
	     ,i.CompanyIDSeq         as [PMC ID]
	     ,i.CompanyName          as [PMC NAME]
	     ,cdt.qty_shipped        as [Qty]
	     ,ii.EffectiveQuantity   as [ActualUnitsAffected] --added 03-MAR-2005
	     ,(CASE when ii.RevenueRecognitionCode IN ('SRR','MRR') THEN ii.DeferredRevenueAccountCode 
                  else ii.RevenueAccountCode end) as [GLRevenueAcct]
             ,cast(cdt.qty_shipped * cdt.unit_price as decimal(27,2)) as [GrossAmt]
	     ,sum(CASE when LEFT(cdt.gl_rev_acct,4)='3375' THEN cdt.extended_price else 0 END) as [Discount] -- tax only credits should display 0
	     ,sum(CASE when cdt.gl_rev_acct = '2375000001000' THEN (cdt.extended_price*-1) ELSE 0 END) as [Deferred Discount]	-- tax only credits should display 0
	     ,ii.ShippingandHandlingAmount  as [Freight]	-- tax only credits should display 0
	     --,0                           as [PPU_Adjustment]
	     ,extended_price                as [Net Before Tax]
	     ,ii.TaxAmount                  as [Tax]
	     ,ii.RevenueTierCode            as [RevTierCode]
	     ,r.product_name                as [RevTierDescription]
	     ,p.DisplayName                 as [Line Description]
	     ,m.[Name]                      as [Pricing Method]
	     ,convert(char(10),i.InvoiceDate,101) as [Invoice Date]
	     ,null                          as [Apply Date]
	     ,oi.StatusCode                 as [Contract Status]
             ,ii.BillingPeriodFromDate      as [Billing Period Start]
             ,ii.BillingPeriodToDate        as [Billing Period End]
	     ,i.ShipToState                 as [ShipToState]
	     ,a.EpicorCustomerCode          as [Platinum_Number]
	     ,NULL                          as [Reg Code]
	     ,NULL                          as [OrderItem_RowId]
	     ,''                            as [PPU_3996_Flag]
	     ,NULL                          as [Apply To Invoice]
	     ,NULL                          as [Apply Date Of Invoice]
	     ,NULL                          as [Credit Reason]
	     ,NULL                          as [Invoice PriceList Name]
	     ,NULL                          as [Siebel Contract#]
	     ,NULL                          as [Invoice Comment]
	     ,NULL                          as [Internal Comment]
	     ,i.CompanyIDSeq                as [Current PMC ID]
	     ,comp.[Name]                   as [Current PMC Name]
	     ,NULL                          as [ShipToAccountNum]
	     ,LEFT(i.ShipToAddressLine1,40) as [ShipToAddress]
	     ,LEFT(i.ShipToCity,40)         as [ShipToCity]
	     ,LEFT(i.ShipToZip,40)          as [ShipToZip]
	     ,LEFT(i.ShipToCounty,50)       as [ShipToCounty] 
	     ,a.SiteMasterID                as [CurrentDatabaseID]
	     ,null                          as [Master OrderID]
	     ,null                          as [Master OrderStartDate]
	     ,null                          as [Master OrderEnd Date] 
	     ,null                          as [OrderHeaderComments] 
	     ,null                          as [SiebelProductID] 
	     ,@RunDateTime                  as [RunDateTime]
             ,(CASE ii.ChargeTypeCode WHEN 'ILF' THEN oi.ILFStartDate
							WHEN 'ACS' THEN oi.ActivationStartDate
							ELSE NULL END) as [Contract SDate]
             ,(CASE ii.ChargeTypeCode WHEN 'ILF' THEN oi.ILFEndDate
							WHEN 'ACS' THEN oi.ActivationEndDate
							ELSE NULL END) as [Contract EDate]
	     ,ii.[InvoiceIDSeq]             as [InvoiceIDSeq]  
	     ,ii.IDSeq                      as [InvoiceItemIDSeq] 
	     ,NULL                          as [CreditMemoIDSeq] 
	     ,NULL                          as [CreditMemoItemIDSeq] 
	     ,ii.[OrderIDSeq]               as [OrderIDSeq]  
	     ,ii.[OrderItemIDSeq]           as [OrderItemIDSeq]  
	     ,ii.[OrderGroupIDSeq]          as [OrderGroupIDSeq]
	     ,NULL                          as [CreditReasonTypeCode]
	     ,ii.[ProductCode]              as [ProductCode]  
	     ,ii.[ChargeTypeCode]           as [ChargeTypeCode]  
	     ,ii.[FrequencyCode]            as [FrequencyCode]  
	     ,ii.[MeasureCode]              as [MeasureCode] 
	     ,ii.[PriceVersion]             as [PriceVersion] 
	     ,i.InvoiceDate                 as [ApplyToInvoiceDate]
	     ,o.[QuoteIDSeq]                as [QuoteIDSeq]
	     ,p.[PlatformCode]              as [PlatformCode]
	     ,p.[FamilyCode]                as [FamilyCode]
	     ,p.[CategoryCode]              as [CategoryCode] 
   	     ,p.ProductTypeCode             as [ProductTypeCode]
  FROM INVOICES.dbo.Invoice                     i   with (nolock)
  --INNER JOIN Proddata.dbo.artrx               ph  with (nolock) on h.trx_ctrl_num = ph.trx_ctrl_num
  INNER JOIN INVOICES.dbo.InvoiceItem           ii  with (nolock) on i.InvoiceIDSeq = ii.InvoiceIDSeq 
  and   (i.InvoiceDate BETWEEN @BeginInvoiceDate AND @EndInvoiceDate)                                                    
  INNER JOIN proddata.dbo.artrxcdt              cdt with (nolock) on ii.IDSeq=weight
  LEFT OUTER JOIN ORDERS.dbo.OrderItem          oi  with (nolock) on ii.OrderItemIDSeq=oi.IDSeq
  LEFT OUTER JOIN ORDERS.dbo.[Order]            o   with (nolock) on ii.OrderIDSeq=o.OrderIDSeq
  LEFT OUTER JOIN products.dbo.REVENUE_TIER_TRANSLATION r with (nolock) ON ii.RevenueTierCode = r.revenue_tier_code
  --below join is used to retrieve ApplyToInvoice# of a credit memo.
  --LEFT OUTER JOIN Proddata.dbo.artrx          INVOICE with (nolock) on h.apply_to_num = INVOICE.trx_ctrl_num ---changed from invoice..arinpchg INVOICE -->to --> Proddata..artrx INVOICE to get ApplyToInvoice - 26-Aug-2005(asadeqa)
  --  and h.trx_type = '2032' --2032 for credit memos
  LEFT OUTER JOIN CUSTOMERS.dbo.Account         a    with(nolock) on i.AccountIDSeq=a.IDSeq
  LEFT OUTER JOIN CUSTOMERS.dbo.[Property]      prop with(nolock) on i.PropertyIDSeq=prop.IDSeq
  LEFT OUTER JOIN CUSTOMERS.dbo.Company         comp with(nolock) on i.CompanyIDSeq=comp.IDSeq
  LEFT OUTER JOIN products.dbo.product          p    with(nolock) on ii.ProductCode=p.code and ii.priceversion=p.priceversion
  left outer join products.dbo.measure          m    with(nolock) on ii.measurecode=m.code
  WHERE (i.InvoiceDate BETWEEN @BeginInvoiceDate AND @EndInvoiceDate)
 
  ----------------------------------------------------
  --FINAL SELECT
  ---Please generate the FINAL report (for inserting into ReportDB.dbo.BillingTransactionLog if this proc is called from 
  -- Invoice.dbo.uspInsertBillingTransactions or selecting data from Epicor/Invoicing directly if this proc is called standalone. 
  SELECT [Invoice]
         ,[TranType]               AS 'Trans Type'
         ,[New Existing Code]
         ,[freight code]           AS 'Freight Code'
         ,[SITE ID]                AS 'Site ID'
         ,[SITE NAME]              AS 'Site Name'
         ,[UnitCount]              AS 'Unit Count'
         ,[PMC ID]
         ,[PMC NAME]               AS 'PMC Name'
         ,[Qty]
         ,[ActualUnitsAffected]    AS 'Actual Units Affected'
         ,[GLRevenueAcct]          AS 'GL Revenue Account'
         ,[GrossAmt]               AS 'Gross Amount'
         ,[Discount]
         ,[Deferred Discount]
         ,[Freight]
         ,[PPU_Adjustment]         AS 'PPU Adj'
         ,[Net Before Tax]
         ,[Tax]
         ,[RevTierCode]            AS 'Revenue Tier Code'
         ,[RevTierDescription]     AS 'Revenue Tier Description'
         ,[Line Description]
         ,[Pricing Method]
         ,[Invoice Date]
         ,[Apply Date]
         ,[Contract Status]        
         ,[Billing Period Start]
         ,[Billing Period End]
         ,[ShipToState]            AS 'Ship To State'
         ,[Platinum_Number]        AS 'Platinum Number'
         ,[Reg Code]
         ,[OrderItem_RowId]        AS 'Order Item Row ID'
         ,[PPU_3996_Flag]          AS 'PPU 3996 Flag'
         ,[Apply To Invoice]
         ,[Apply Date Of Invoice]
         ,[Credit Reason]
         ,[Invoice PriceList Name]
         ,[Siebel Contract#]
         ,[Invoice Comment]
         ,[Internal Comment]
         ,[Current PMC ID]
         ,[Current PMC Name]
         ,[ShipToAccountNum]
         ,[ShipToAddress]
         ,[ShipToCity]
         ,[ShipToZip]  
         ,[ShipToCounty] 
         ,[CurrentDatabaseID]
         ,[Master OrderID]
         ,[Master OrderStartDate] 
         ,[Master OrderEnd Date] 
         ,[OrderHeaderComments]		--03-Apr-2006 - see defect 2251
         ,[SiebelProductID]			--7/30/2006 
         ,[RunDateTime]			--To save the RunDateTime incase it is run multiple times 
         ,[Contract SDate]         as 'Contract Start Date'
         ,[Contract EDate]         AS 'Contract End Date'
         ,[InvoiceIDSeq] 
         ,[InvoiceItemIDSeq] 
         ,[CreditMemoIDSeq] 
         ,[CreditMemoItemIDSeq] 
         ,[OrderIDSeq] 
         ,[OrderItemIDSeq] 
         ,[OrderGroupIDSeq]
         ,[CreditReasonTypeCode]  
         ,[ProductCode]  
         ,[ChargeTypeCode]  
         ,[FrequencyCode]  
         ,[MeasureCode] 
         ,[PriceVersion] 
         ,[ApplyToInvoiceDate] 
         ,[QuoteIDSeq]
         ,[PlatformCode]  
         ,[FamilyCode]  
         ,[CategoryCode] 
         ,[ProductTypeCode] 
  FROM  #LT_BillingTransactionLog with (nolock)
  -----------------------------------------------------------------
  --Final Clean up
  Drop table #LT_BillingTransactionLog
  -----------------------------------------------------------------
END

GO
