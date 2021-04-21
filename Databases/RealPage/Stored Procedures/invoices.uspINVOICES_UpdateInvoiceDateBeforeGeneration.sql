SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_UpdateInvoiceDateBeforeGeneration]
-- Description     : Updates the print flag
-- 
-- Revision History:
-- Author          : DCANNON
-- 5/1/2006        : Stored Procedure Created.
-- 10/26/2007      : Naval Kishore Added OriginalPrintDate,printcount 

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_UpdateInvoiceDateBeforeGeneration] @IPVC_InvoiceID varchar(20)
AS
BEGIN
  update Invoices.dbo.Invoice  
  set    InvoiceDate        = (case when PrintFlag = 0 then Convert(varchar(50),getdate(),101) else InvoiceDate end),
         InvoiceDueDate     = (case when PrintFlag = 0 then Convert(varchar(50),dateadd(mm,1,getdate()),101) else InvoiceDueDate end)
  where InvoiceIDSeq = @IPVC_InvoiceID  
END

GO
