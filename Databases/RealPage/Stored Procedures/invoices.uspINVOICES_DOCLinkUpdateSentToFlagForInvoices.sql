SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_DOCLinkUpdateSentToFlagForInvoices]
-- Description     : Updates the SentToDocLinkFlag
-- 
-- Revision History:
-- Author          : SRS
-- 01/19/2009        : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_DOCLinkUpdateSentToFlagForInvoices] (@IPVC_InvoicePrintBatchIDSeq varchar(50),
                                                                         @IPVC_InvoiceIDString        varchar(8000))
AS
BEGIN
  update Invoices.dbo.Invoice  
  set    SentToDocLinkFlag   = 1,    
         DocLinkPrintBatchID = @IPVC_InvoicePrintBatchIDSeq
  Where
         InvoiceIDSeq in (select SplitString from INVOICES.dbo.[fnGenericSplitString] (@IPVC_InvoiceIDString))

END
GO
