SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_Rep_GetInvoicePaymentInfo
-- Description     : This procedure gets Invoice Payment Details pertaining to passed InvoiceID
--                   Applicable only for PrePaid Instant Invoice.
--                   Call of Main Header Proc returns Exec INVOICES.dbo.uspINVOICES_Rep_GetAccountInfo @IPVC_InvoiceID =
--                   PrePaidFlag.

--                   Only when PrePaidFlag is 1, the call of Exec INVOICES.dbo.uspINVOICES_Rep_GetInvoicePaymentInfo @IPVC_InvoiceID =
--                   is to be made to get Invoice Payment Info to be shown in SRS Invoice RDL.
--                   For Normal Invoices where PrePaidFlag = 0, this proc call can be skipped.

-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(50)
--      
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_Rep_GetInvoicePaymentInfo @IPVC_InvoiceID ='I0000000019'
    
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 08/06/2011      : TFS 295 SRS - Instant Invoice - To Get Invoice Payment Details to display in Payment Stud in Invoice RDL.
--                 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspINVOICES_Rep_GetInvoicePaymentInfo] (@IPVC_InvoiceID  varchar(50)  
                                                               )
AS
BEGIN 
  set nocount on;
  select Top 1 InvoiceIDSeq,QuoteIDSeq,
               PaymentTransactionAuthorizationCode,PaymentTransactionNumber,PaymentTransactionDate,PaymentMethod,
               PaymentGatewayResponseCode
  from   INVOICES.[dbo].InvoicePayment IP with (nolock) 
  where  IP.InvoiceIDSeq = @IPVC_InvoiceID
end
GO
