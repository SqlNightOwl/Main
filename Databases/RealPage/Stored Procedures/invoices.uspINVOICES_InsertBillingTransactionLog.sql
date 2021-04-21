SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [invoices].[uspINVOICES_InsertBillingTransactionLog]
                                                             (@BeginRange datetime,
                                                              @EndRange   datetime
                                                             )
as
BEGIN
/********************************************************************************************************/
--  database name:  INVOICES						
--  Purpose:  This populates the INVOICES.dbo.BillingTransactionLog table with detailed data from the INVOICES database		     			
-- 	      on RPIDALEPD001.  	
--  parameters: @BeginRange - begin date to use for date_applied criteria (month begin date)		
--  		@EndRange = end date to use for date_applied criteria (month ending date)			
-- 			don't need timestamp; Platinum doesn't store time on applied date 		
-- example of calling the stored procedure:
-- EXEC uspINVOICES_InsertBillingTransactionLog '12/1/2005', '12/31/2005'
-- Instructions:
-- 1. Pass correct dates					
-- 2. Save the xls file to U:\MIS\MIS Internal\FinancialReportsMoEnd as YYYYMMRevenueDump.		
-- 		(\\rpidalefs001\groups\MIS\MIS Internal\FinancialReportsMoEnd)			
-- ------------------------ Modifications ------------------------------------------
--  Date			Author			Description	
-----------------------------------------------------------------------------------
-- 2007/11/12		Gwen Guidroz	Initial creation		
/********************************************************************************************************/
  set nocount on
  declare @BeginRangeInt bigint, @EndRangeInt bigint, @CountBillingLog bigint
  --set @BeginRangeInt = datediff(dd, '1/1/1753', @BeginRange) + 639906	--Convert beginning date to Platinum's integer date equivalent
  --set @EndRangeInt = datediff(dd, '1/1/1753', @EndRange) + 639906		--Convert ending date to Platinum's integer date equivalent
  SET @CountBillingLog = 0

  select @CountBillingLog = count(1)
  FROM   INVOICES.dbo.BillingTransactionLog with (nolock)
  WHERE  [Invoice Date] between @BeginRange and @EndRange
  -----------------------------------------------------------------
  IF @CountBillingLog IS NOT NULL AND @CountBillingLog > 0 
  BEGIN
    PRINT 'Billing transactions have already been inserted into the INVOICES.dbo.BillingTransactionLog table for this period.'
    PRINT 'Run stored procedure, Invoices.dbo.[uspINVOICES_GetBillingTransactionLog], to extract the data directly from Epicor or run stored procedure, uspSelectBillingTransactions, to select the previously saved data from the table.'
    RETURN
  END
  -----------------------------------------------------------------
  Insert into INVOICES.dbo.BillingTransactionLog
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
                            ,[PPU_Adjustment]
                            ,[Net Before Tax]
                            ,[Tax]
                            ,[RevTierCode]
                            ,[RevTierDescription]
                            ,[Line Description]
                            ,[Pricing Method]
                            ,[Invoice Date]
                            ,[Apply Date]
                            ,[Contract Status]
                            ,[Billing Period Start]                              
                            ,[Billing Period End]                                
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
  EXECUTE INVOICES.dbo.uspINVOICES_GetBillingTransactionLog @BeginRange, @EndRange
  ---------------------------------------------------------------------------------
END

GO
