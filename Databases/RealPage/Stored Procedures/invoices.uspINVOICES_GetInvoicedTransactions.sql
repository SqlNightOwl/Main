SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_GetInvoicedTransactions
-- Description     : Retrieves Transactions Information based on the Invoice Passed as Input parameter.
-- Input Parameters: @IPVC_InvoiceID  varchar(50) 
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.dbo.[uspINVOICES_GetInvoicedTransactions] @IPVC_InvoiceID = 'I0805000194'
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 12/13/2007      : Stored Procedure Created.
-- Author          : Raghavender Reddy.
-- 30/05/2008	   : Modified procedure for handling paging.
-- 08/03/2008      : Defect #5448 Removed pagenation and to display totals

------------------------------------------------------------------------------------------------------
 
CREATE PROCEDURE [invoices].[uspINVOICES_GetInvoicedTransactions](
							     @IPVC_InvoiceID  varchar(50)
                                                            )
AS
BEGIN 
  set nocount on;
  ----------------------------------------------
   Select  Prod.DisplayName                            as [Name],
           II.TransactionItemName,
           convert(NUMERIC(30,2),II.ExtChargeAmount)   as ExtChargeAmount, 
           II.Discountamount,
           II.CreditAmount                             as InvoiceCreditAmount, 
           convert(NUMERIC(30,2),II.NetChargeAmount)   as NetChargeAmount, 
           convert(varchar(20),II.TransactionDate,101) as ReportDate,
           II.Quantity,
           II.OrderIDSeq,
           II.OrderGroupIDSeq,
           II.OrderItemTransactionIDSeq,
           II.IDSeq                                    as InvoiceItemIDSeq,
           II.BillingPeriodFromDate,
           II.BillingPeriodToDate,
           II.TaxAmount                                as TaxAmount,
           isnull(Credits.Amount,0)                    as CreditAmount,
           (
            (convert(numeric(30,2),isnull(II.NetChargeAmount,0))) 
            +
            (convert(numeric(30,2),isnull(II.ShippingAndHandlingAmount,0))) 
            + 
            (isnull(II.TaxAmount,0)) 
            - 
            (isnull(Credits.Amount,0))
           )                                           as Total,
           -------------------------------------------------------------------------
           II.InvoiceIDSeq                                                       as InvoiceIDSeq,
           II.InvoiceGroupIDSeq                                                  as InvoiceGroupIDSeq,         
           II.ChargeTypeCode                                                     as ChargeTypeCode,
           0                                                                     as PreconfiguredBundleFlag          
           -------------------------------------------------------------------------
   INTO    #temp_Tran_details
   From    Invoices.dbo.InvoiceItem II  with (nolock)  
   Inner Join 
           Products.dbo.Product Prod  with (nolock) 
   On      II.ProductCode    = Prod.Code
   and     II.PriceVersion   = Prod.PriceVersion
   and     II.InvoiceIDSeq   = @IPVC_InvoiceID
   and     II.OrderitemTransactionIDSeq is not null
   left outer join 
          (select isnull((sum(convert(numeric(30,2),cmi.ExtCreditAmount))
                          +
                          sum(convert(numeric(30,2),cmi.TaxAmount))
                          + 
                          sum(convert(numeric(30,2),cmi.ShippingAndHandlingCreditAmount))
                          -
                          sum(convert(numeric(30,2),cmi.discountcreditamount))),0)  AS Amount,                                       
                  InvoiceItemIDSeq
           from   Invoices.dbo.CreditMemoItem cmi with (nolock), 
                  Invoices.dbo.CreditMemo cm with (nolock)
           where  cm.InvoiceIDSeq     = @IPVC_InvoiceID
              and cmi.InvoiceIDSeq    = @IPVC_InvoiceID
              and cmi.CreditMemoIDSeq = cm.CreditMemoIDSeq 
              and CreditStatusCode    = 'APPR'
           Group by InvoiceItemIDSeq
           ) AS Credits
   on    Credits.InvoiceItemIDSeq = II.IDSeq 
   Where II.InvoiceIDSeq  = @IPVC_InvoiceID
   Order By Prod.DisplayName desc,II.TransactionDate asc
-------------------------------------------------------------------------------------
-- Final Select of the Transactions data
-------------------------------------------------------------------------------------
select * from #temp_Tran_details with (nolock)
--------------------------------------------------------------------------------------     
-- Query for calculating the total amounts for Transaction Items
--------------------------------------------------------------------------------------
select isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(TaxAmount),2,2),'0')     as NetTaxAmount,
       isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(CreditAmount),2,2),'0')  as NetCreditAmount,
       isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(Total),2,2),'0')         as NetTotal
from   #temp_Tran_details with (nolock)
-------------------------------------------------------------------------------------
-- Dropping the temporary table
-------------------------------------------------------------------------------------
drop table #temp_Tran_details 
--------------------------------------------------------------------------------------
END
GO
