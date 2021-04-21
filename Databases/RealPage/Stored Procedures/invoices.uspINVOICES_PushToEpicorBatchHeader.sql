SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_PushToEpicorBatchHeader @IPVC_EpicorBatchCode=100, @IPVC_GetInvoiceIDs = 'NO'
exec INVOICES.dbo.uspINVOICES_PushToEpicorBatchHeader @IPVC_EpicorBatchCode=100,@IPVC_GetInvoiceIDs = 'YES'
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_PushToEpicorBatchHeader
-- Description     : This procedure Selects Batch Header total of all printed invoices to push to epicor
-- Input Parameters: @IPVC_EpicorBatchCode
--                   @IPVC_GetInvoiceIDs -- Default is 'NO'. This will get Batch Header total alone.
--                                       -- If 'YES', returns InvoiceIDs that are to be pushed to Epicor.
-- OUTPUT          : Rowset.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_PushToEpicorBatchHeader
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_PushToEpicorBatchHeader] (@IPVC_EpicorBatchCode         varchar(50),
                                                          @IPVC_GetInvoiceIDs           varchar(10) = 'NO'                                    
                                                         )
AS
BEGIN
  set nocount on 
  ----------------------------------------------------------------------------
  if (@IPVC_GetInvoiceIDs = 'NO')
  begin   
    select @IPVC_EpicorBatchCode                           as EpicorBatchCode,
           'I'                                             as TransactionType,
           count(I.InvoiceIDSeq)                           as TransactionCount,
           coalesce(sum((I.ILFChargeAmount        +
                         I.AccessChargeAmount     +
                         I.TransactionChargeAmount+                         
                         I.ShippingAndHandlingAmount+
                         I.TaxAmount)),0)  as TransactionTotalAmount 
    from   INVOICES.DBO.INVOICE I with (nolock)
    where  I.EpicorBatchCode    = @IPVC_EpicorBatchCode
    and    I.SentToEpicorStatus = 'COMPLETED'
    and    I.PrintFlag          = 1
    and    I.SentToEpicorFlag   = 1
    ------------------------------------------------------
    --Update status for the Batch in BatchProcess Table
    Update BP
    set    BP.Status  = 'EPICOR PUSH COMPLETED',
           BP.EndDate = getdate()
    from   INVOICES.dbo.BatchProcess BP with (nolock)
    where  BP.EpicorBatchCode=@IPVC_EpicorBatchCode 
    ------------------------------------------------------        
  end
  else 
  begin
    select @IPVC_EpicorBatchCode       as EpicorBatchCode,
           I.InvoiceIDSeq              as InvoiceID
    from   INVOICES.DBO.INVOICE I with (nolock)
    where  I.EpicorBatchCode    = @IPVC_EpicorBatchCode
    and    I.SentToEpicorStatus = 'EPICOR PUSH PENDING'
    and    I.PrintFlag          = 1
    and    I.SentToEpicorFlag   = 0 
    ------------------------------------------------------
    --Update status for the Batch in BatchProcess Table
    Update BP
    set    BP.Status    = 'EPICOR PUSH STARTED',
           BP.StartDate = getdate()
    from   INVOICES.dbo.BatchProcess BP with (nolock)
    where  BP.EpicorBatchCode=@IPVC_EpicorBatchCode 
    ------------------------------------------------------    
  end
END


GO
