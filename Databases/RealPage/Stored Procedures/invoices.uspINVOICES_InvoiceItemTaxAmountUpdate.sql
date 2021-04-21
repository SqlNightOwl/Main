SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_InvoiceItemTaxAmountUpdate]
-- Description     : Updates the tax amount for a single item
-- Revision History:
-- Author          : DC
-- 4/11/2007        : Stored Procedure Created.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [invoices].[uspINVOICES_InvoiceItemTaxAmountUpdate] (@IPVC_InvoiceItemID varchar(20),
  @IPN_TaxPercent numeric(30, 5), @IPN_TaxAmount money)
AS
BEGIN
  update Invoices..InvoiceItem
  set TaxPercent = @IPN_TaxPercent,
      TaxAmount = @IPN_TaxAmount
  where IDSeq = @IPVC_InvoiceItemID


  declare @IPVC_InvoiceID varchar(22)
  select @IPVC_InvoiceID = ii.InvoiceIDSeq from InvoiceGroup ig, InvoiceItem ii
  where ii.IDSeq = @IPVC_InvoiceItemID
  and ig.IDSeq = ii.InvoiceGroupIDSeq

  update Invoice
  set TaxAmount = (select sum(TaxAmount) from InvoiceGroup ig, InvoiceItem ii where ig.InvoiceIDSeq = @IPVC_InvoiceID and ig.IDSeq = ii.InvoiceGroupIDSeq)
  where InvoiceIDSeq = @IPVC_InvoiceID
END




GO
