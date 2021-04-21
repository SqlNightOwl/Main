SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_BatchProcessResetItems]
-- Description     : Resets the items to allow resend to epicor
-- 
-- Revision History:
-- Author          : DCANNON
-- 5/1/2006        : Stored Procedure Created.
-- 4/6/2009		   : Naval Kishore Modified the SP to correct object name reference, defect#6259  
 ------------------------------------------------------------------------------------------------------
-- exec INVOICES.dbo.uspINVOICES_BatchProcessResetItems ',29,'
CREATE PROCEDURE [invoices].[uspINVOICES_BatchProcessResetItems] (@IPVC_EpicorBatchCode varchar(20), @IPVC_IDS varchar(max)) 
AS
BEGIN
  if @IPVC_IDS is null
  begin
    update INVOICES.dbo.Invoice
    set    SentToEpicorStatus = null, 
           EpicorBatchCode    = null,
           senttoepicorflag   = 0
    where EpicorBatchCode     = @IPVC_EpicorBatchCode
    and   SentToEpicorFlag    = 0

    update INVOICES.dbo.CreditMemo
    set    SentToEpicorStatus = null, 
           EpicorBatchCode    = null,
           senttoepicorflag   = 0
    where EpicorBatchCode     = @IPVC_EpicorBatchCode
    and   SentToEpicorFlag    = 0
  end
  else
  begin
    update INVOICES.dbo.Invoice
    set    SentToEpicorStatus = null, 
           EpicorBatchCode    = null,
           senttoepicorflag   = 0
    where  charindex(',' + convert(varchar(11),InvoiceIDSeq) + ',', @IPVC_IDS) > 0
    and    SentToEpicorFlag    = 0


    update INVOICES.dbo.CreditMemo
    set    SentToEpicorStatus = null, 
           EpicorBatchCode    = null,
           senttoepicorflag   = 0
    where charindex(',' + convert(varchar(11),CreditMemoIDSeq) + ',', @IPVC_IDS) > 0
    and    SentToEpicorFlag    = 0
  end
END


GO
