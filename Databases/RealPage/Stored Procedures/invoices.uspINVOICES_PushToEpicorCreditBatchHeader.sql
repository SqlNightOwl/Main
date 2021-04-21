SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec INVOICES.dbo.uspINVOICES_PushToEpicorCreditBatchHeader @IPVC_EpicorBatchCode=100, @IPVC_GetCreditMemoIDs = 'NO'
exec INVOICES.dbo.uspINVOICES_PushToEpicorCreditBatchHeader @IPVC_EpicorBatchCode=100,@IPVC_GetCreditMemoIDs = 'YES'
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_PushToEpicorCreditBatchHeader
-- Description     : This procedure Selects Batch Header total of all printed invoices to push to epicor
-- Input Parameters: @IPVC_EpicorBatchCode
--                   @IPVC_GetCreditMemoIDs -- Default is 'NO'. This will get Batch Header total alone.
--                                       -- If 'YES', returns InvoiceIDs that are to be pushed to Epicor.
-- OUTPUT          : Rowset.
--  
--                   
-- Code Example    : exec INVOICES.dbo.uspINVOICES_PushToEpicorCreditBatchHeader
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_PushToEpicorCreditBatchHeader] (@IPVC_EpicorBatchCode         varchar(50),
                                                                @IPVC_GetCreditMemoIDs        varchar(10) = 'NO'                                    
                                                               )
AS
BEGIN
  set nocount on 
  ----------------------------------------------------------------------------
  if (@IPVC_GetCreditMemoIDs = 'NO')
  begin   
    select @IPVC_EpicorBatchCode                            as EpicorBatchCode,
           'C'                                              as TransactionType,
           count(CM.InvoiceIDSeq)                           as TransactionCount,
           /*coalesce(sum((CM.ILFChargeAmount      +
                         CM.AccessChargeAmount     +
                         CM.TransactionChargeAmount+                         
                         CM.ShippingAndHandlingAmount)),0)  as TransactionTotalAmount 
           */
           coalesce(sum((CM.TotalNetCreditAmount +                         
                         CM.ShippingAndHandlingCreditAmount+
                         CM.TaxAmount)),0)  as TransactionTotalAmount 
    from   INVOICES.DBO.CreditMemo CM with (nolock)
    where  CM.EpicorBatchCode    = @IPVC_EpicorBatchCode
    and    CM.SentToEpicorStatus = 'COMPLETED'    
    and    CM.SentToEpicorFlag   = 1
    and    CM.CreditMemoReversalFlag = 0 --> This denotes it is CreditMemo
    and    CM.CreditStatusCode   = 'APPR'
    ------------------------------------------------------
    --Update status for the Batch in BatchProcess Table
    Update BP
    set    BP.Status  = 'EPICOR PUSH COMPLETED',
           BP.EndDate = getdate()
    from   INVOICES.dbo.BatchProcess BP with (nolock)
    where  BP.EpicorBatchCode=@IPVC_EpicorBatchCode 
    and    BP.BatchType      = 'CREDIT'
    ------------------------------------------------------        
  end
  else 
  begin
    select @IPVC_EpicorBatchCode       as EpicorBatchCode,
           CM.InvoiceIDSeq             as InvoiceID,
           CM.CreditMemoIDSeq          as CreditMemoID
    from   INVOICES.DBO.CreditMemo CM with (nolock)
    where  CM.EpicorBatchCode    = @IPVC_EpicorBatchCode
    and    CM.SentToEpicorStatus = 'EPICOR PUSH PENDING'    
    and    CM.SentToEpicorFlag   = 0 
    and    CM.CreditMemoReversalFlag = 0 --> This denotes it is CreditMemo
    and    CM.CreditStatusCode   = 'APPR'
    ------------------------------------------------------
    --Update status for the Batch in BatchProcess Table
    Update BP
    set    BP.Status    = 'EPICOR PUSH STARTED',
           BP.StartDate = getdate()
    from   INVOICES.dbo.BatchProcess BP with (nolock)
    where  BP.EpicorBatchCode=@IPVC_EpicorBatchCode 
    and    BP.BatchType      = 'CREDIT'
    ------------------------------------------------------    
  end
END
GO
