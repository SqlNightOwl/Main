SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_EligibilityCheckForImportBatchRollback]
-- Description     : This procedure returns 1 or 0 for Eligibility.
--                    1 is eligible for Batch Rollback.
--                    0 is NOT ELIGIBLE for Batch Rollback.

--                   This proc should be called by UI when user initiates Batch Rollback and that BatchPostingStatusFlag is 1.
--                   If BatchPostingStatusFlag is already 2 (Failure) or 3 (Previously rolled back), UI can make the determination
--                   to Not allow user to rollback the batch at all.
--
-- OUTPUT          : RecordSet of EligibilityFlag
--
-- Code Example    : Exec Orders.dbo.[uspORDERS_EligibilityCheckForImportBatchRollback] @IPBI_BatchIDSeq=560,@IPVC_ImportSource='Excel'
-- Revision History:
-- Author          : SRS
-- 2010-08-11      : LWW modified message text strings as requested by QA team-(8143)
-- 2010-07-29      : Stored Procedure Created.Defect 8143
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_EligibilityCheckForImportBatchRollback] (@IPBI_BatchIDSeq            bigint,        --> This is TransactionImportIDSeq returned by Proc call uspORDERS_ImportTransactionList for UI.
                                                                           @IPVC_ImportSource          varchar(255)   --> This is ImportSource  returned by Proc call uspORDERS_ImportTransactionList for UI.
                                                                          )

AS
BEGIN 
  set nocount on;
  declare @LI_EligibilityFlag  int,
          @LVC_Message         varchar(2000)

  select  @LI_EligibilityFlag = 1,
          @LVC_Message        = 'This batch is Eligible for Rollback.' + char(13) + char(13)+
                                'Reason: Transaction(s) of this Batch have not been Invoiced or Pending to be Printed.'
  -----------------------------------------------------------------------------------
  --Step 0 : At this time Rollback is limited only to Excel imported Batch
  -----------------------------------------------------------------------------------
  if (@IPVC_ImportSource <> 'Excel')
  begin
    select @LI_EligibilityFlag = 0,
           @LVC_Message        = 'This batch is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+
                                 'Reason: This batch is not Imported from Excel.' + char(13)+
                                 'Only Excel imported batch(s) are Eligible for Rollback.'
    select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
    return
  end
  -----------------------------------------------------------------------------------
  --Step 0.1 : If input @IPBI_BatchIDSeq is bogus, return 0
  -----------------------------------------------------------------------------------
  if not exists (select top 1 1
                 from   ORDERS.dbo.TransactionImportBatchHeader TBH with (nolock) 
                 where  TBH.IDSeq                  = @IPBI_BatchIDSeq
                )
  begin
    select @LI_EligibilityFlag = 0,
           @LVC_Message        = 'This batch is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+ 
                                 'Reason: This is not a valid imported batch.'
    select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
    return
  end
  -----------------------------------------------------------------------------------
  --Step 1 : Check if the Batch is already in failed Status or Previously Rolledback
  -----------------------------------------------------------------------------------
  If exists (select top 1 1
             from   ORDERS.dbo.TransactionImportBatchHeader TBH with (nolock) 
             where  TBH.IDSeq                  = @IPBI_BatchIDSeq
             and    TBH.ImportSource           = @IPVC_ImportSource
             and    TBH.BatchPostingStatusFlag = 2
             )
  begin
    select @LI_EligibilityFlag = 0,
           @LVC_Message        = 'This batch is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+ 
                                 'Reason: This is an Errored batch.' + char(13) + 
                                 'No Transaction(s) for this batch are available to rollback.'
    select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
    return
  end 

   If exists (select top 1 1
             from   ORDERS.dbo.TransactionImportBatchHeader TBH with (nolock) 
             where  TBH.IDSeq                  = @IPBI_BatchIDSeq
             and    TBH.ImportSource           = @IPVC_ImportSource
             and    TBH.BatchPostingStatusFlag = 3
             )
  begin
    select @LI_EligibilityFlag = 0,
           @LVC_Message        = 'This batch is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+ 
                                 'Reason: This batch was previously rolled back.'
    select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
    return
  end 
  -----------------------------------------------------------------------------------
  --Step 2 : Check if atleast one transaction of this batch is not Invoiced and printed
  --         and sent to client.
  -----------------------------------------------------------------------------------
  if exists (select top 1 1
             from   Orders.dbo.OrderitemTransaction OIT with (nolock)
             where  OIT.TransactionImportIDSeq = @IPBI_BatchIDSeq
             and    OIT.ImportSource           = @IPVC_ImportSource
             and    OIT.Transactionalflag      = 1
             and    OIT.PrintedOnInvoiceFlag   = 1
            )
  begin
    select @LI_EligibilityFlag = 0,
           @LVC_Message        = 'This batch is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+
                                 'Reason: Transaction(s) in this batch have been previously Invoiced, Printed and Sent to Client.'
    select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
    return
  end
  else
  begin
    select  @LI_EligibilityFlag = 1,
            @LVC_Message        = 'This batch is Eligible for Rollback.' + char(13) + char(13)+
                                  'Reason: Transaction(s) of this Batch have not been Invoiced or Pending to be Printed.'
  end
  -----------------------------------------------------------------------------------
  --Final Select
  -----------------------------------------------------------------------------------
  select @LI_EligibilityFlag as EligibilityFlag,@LVC_Message as Message
  -----------------------------------------------------------------------------------
END
GO
