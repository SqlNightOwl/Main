SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspCREDITS_GetCreditTransactions
-- Description     : Retrieves Transactions Information based on the CreditID Passed as Input parameter.
-- Input Parameters: @IPVC_CreditMemoID  varchar(50) 
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.dbo.[uspCREDITS_GetCreditTransactions] @IPVC_CreditMemoID = 'R0808000029'
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 05/08/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspCREDITS_GetCreditTransactions] @IPVC_CreditMemoID  varchar(50) 
AS
BEGIN 
	SELECT  P.DisplayName,
           II.TransactionItemName,
--           Quotes.DBO.fn_FormatCurrency(CMI.NetCreditAmount,1,2)                as NetCreditAmount,
           CMI.NetCreditAmount                                                  as NetCreditAmount,
          -------------------------------------------------
--          isnull(
--                 Quotes.DBO.fn_FormatCurrency(
                  (
                    CMI.extcreditamount
                  - CMI.DiscountCreditAmount
                  )
--                ,1,2),0.00)                                                    
                                                                                 as creditamount,
          --------------------------------------------------------------------------------------------------
--           Quotes.DBO.fn_FormatCurrency(CMI.taxamount,1,2)                       as taxamount,
           CMI.taxamount                                                         as taxamount,
--           Quotes.DBO.fn_FormatCurrency(CMI.ShippingAndHandlingCreditAmount,1,2) as shippingandhandlingamount,
           CMI.ShippingAndHandlingCreditAmount                                   as shippingandhandlingamount,
          --------------------------------------------------------------------------------------------------
--          isnull(
--                  Quotes.DBO.fn_FormatCurrency(
                   (
                     CMI.extcreditamount
                   + CMI.taxamount
                   - CMI.DiscountCreditAmount
                   ) 
--                   ,1,2),0.00)                                                
                                                                                 as TotalCreditAmount,
           ------------------------------------------------------------------------------------------------- 
           @IPVC_CreditMemoID                                                    as CreditMemoIDSeq, 
           CMI.IDSeq                                                             as CreditMemoItemIDSeq,
           II.InvoiceIDSeq                                                       as InvoiceIDSeq,
           II.InvoiceGroupIDSeq                                                  as InvoiceGroupIDSeq,
           II.IDSeq                                                              as InvoiceItemIDSeq,
           II.ChargeTypeCode                                                     as ChargeTypeCode,
           0                                                                     as PreconfiguredBundleFlag
           -------------------------------------------------------------------------------------------------
    INTO   #temp_Tran_details         
    FROM   Invoices.dbo.CreditMemoItem CMI WITH (NOLOCK)
    Inner  JOIN Invoices.dbo.InvoiceItem II WITH (NOLOCK)
       ON  CMI.InvoiceIDSeq     = II.InvoiceIDSeq
       AND CMI.InvoiceItemIDSeq = II.IDSeq
       AND II.MeasureCode       = 'TRAN'
       and CMI.CreditMemoIDSeq = @IPVC_CreditMemoID 
    Inner   JOIN Products.dbo.Product P WITH (NOLOCK)
       ON  P.Code          = II.ProductCode 
       AND P.PriceVersion  = II.PriceVersion
    WHERE  CreditMemoIDSeq = @IPVC_CreditMemoID --'R0805000082'
-------------------------------------------------------------------------------------
-- Final Select of the Transactions data
-------------------------------------------------------------------------------------
select * from #temp_Tran_details
--------------------------------------------------------------------------------------     
-- Query for calculating the total amounts for Transaction Items
--------------------------------------------------------------------------------------
select isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(TaxAmount),2,2),'0')     as NetTaxAmount,
       isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(CreditAmount),2,2),'0')  as NetCreditAmount,
       isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(shippingandhandlingamount),2,2),'0')         as Netshippingandhandlingamount,
       isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(TotalCreditAmount),2,2),'0')  as NetTotal
from   #temp_Tran_details
-------------------------------------------------------------------------------------
-- Dropping the temporary table
-------------------------------------------------------------------------------------
drop table #temp_Tran_details 
--------------------------------------------------------------------------------------

/*
------------------------------
--To get the Count of records
------------------------------
	SELECT count(CMI.IDSeq)
    FROM   Invoices.dbo.CreditMemoItem CMI WITH (NOLOCK)
      JOIN Invoices.dbo.InvoiceItem II WITH (NOLOCK)
       ON  CMI.InvoiceIDSeq     = II.InvoiceIDSeq
       AND CMI.InvoiceItemIDSeq = II.IDSeq
       AND II.MeasureCode       = 'TRAN'
      JOIN Products.dbo.Product P WITH (NOLOCK)
       ON  P.Code          = II.ProductCode 
       AND P.PriceVersion  = II.PriceVersion
    WHERE  CreditMemoIDSeq = @IPVC_CreditMemoID --'R0805000082'
*/

END
GO
