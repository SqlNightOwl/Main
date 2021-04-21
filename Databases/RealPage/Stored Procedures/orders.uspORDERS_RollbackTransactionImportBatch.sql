SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_RollbackTransactionImportBatch]
-- Description     : This procedure is called to Rollback a Transaction import batch.
--                   This proc should be called by UI when user initiates Batch Rollback and when Eligibility of Rollback is 1
--
-- OUTPUT          : None
--
-- Code Example    : Exec Orders.dbo.[uspORDERS_RollbackTransactionImportBatch] @IPBI_BatchIDSeq=560,@IPVC_ImportSource='Excel',@IPVC_RollbackReasonCode='ETIP',@IPI_UserIDSeq=76

-- Revision History:
-- Author          : SRS
-- 07/29/2010      : Stored Procedure Created.Defect 8143; TFS 574
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_RollbackTransactionImportBatch] (@IPBI_BatchIDSeq            bigint,                 --> This is TransactionImportIDSeq returned by Proc call uspORDERS_ImportTransactionList for UI.
                                                                   @IPVC_ImportSource          varchar(255)='EXCEL',   --> This is ImportSource  returned by Proc call uspORDERS_ImportTransactionList for UI.
                                                                   @IPVC_RollbackReasonCode    varchar(10),            --> This is the code corresponding to Rollback Reasoncode code drop down user selection. Exec ORDERS.dbo.uspORDERS_GetReasonForCategory @IPVC_CategoryCode = 'RTRN', @IPI_ShowAllFlag = 0
                                                                   @IPI_UserIDSeq              bigint                  --> User ID of User initiating the rollback.UI knows this.
                                                                   )

AS
BEGIN 
  set nocount on;
  ----------------------------------------------------------------------------------
  --Declare Local Variables
  declare @LDT_SystemDate        datetime;
  declare @LI_EligibilityFlag    int;  
  declare @LI_ActualImportCount  bigint;
  declare @LVC_ReasonName        varchar(1000);

  declare @LI_Min                bigint,
          @LI_Max                bigint,
          @LVC_InvoiceIDSeq      varchar(50)
  select @LI_Min = 1,@LI_Max=1,@LDT_SystemDate = getdate()
  ----------------------------------------------------------------------------------
  declare  @LT_EligibilityCheck table(EligibilityFlag  int,
                                      Message          varchar(2000)
                                     )

  declare @LT_OpenInvoices  table  (sortseq           int not null identity(1,1),
                                    InvoiceIDSeq      varchar(50)
                                   )
  ----------------------------------------------------------------------------------
  --Step 1 : Intial sanity check to see if the Batch is still eligible for rollback.
  insert into @LT_EligibilityCheck(EligibilityFlag,Message)
  exec ORDERS.dbo.uspORDERS_EligibilityCheckForImportBatchRollback @IPBI_BatchIDSeq=@IPBI_BatchIDSeq,@IPVC_ImportSource=@IPVC_ImportSource;

  select @LI_EligibilityFlag = EligibilityFlag from @LT_EligibilityCheck

  if (@LI_EligibilityFlag=0)
  begin
    return;
  end
  ------------------------------------------------------------------------------------
  --Step 2: Get ActualImported Count from TransactionImportBatchHeader for this batch.
  ------------------------------------------------------------------------------------
  select @LI_ActualImportCount=count(1)
  from   Orders.dbo.[OrderItemTransaction] OIT with (nolock)
  where  OIT.TransactionImportIDSeq = @IPBI_BatchIDSeq
  and    OIT.ImportSource           = @IPVC_ImportSource

  select @LI_Min = 1,@LI_Max = (@LI_ActualImportCount/100)+2

  select Top 1 @LVC_ReasonName = 'with Reason : ' + R.ReasonName
  from   ORDERS.dbo.Reason R with (nolock)
  where  Code = @IPVC_RollbackReasonCode
  ----------------------------------------------------------------------------------
  ---Step 2: Gather all Open Invoices pertaining to Transactions to be rolled back.
  --         This will be used later to Sync Invoices after deleting open records.
  ----------------------------------------------------------------------------------
  insert into @LT_OpenInvoices(InvoiceIDSeq)
  select   I.InvoiceIdSeq 
  from     Invoices.dbo.Invoice     I  with (nolock)
  inner join
           Invoices.dbo.InvoiceItem II with (nolock)
  on       II.InvoiceIDSeq  = I.InvoiceIdSeq
  and      I.PrintFlag      = 0
  and      II.OrderItemTransactionIDSeq is not null
  inner join
           Orders.dbo.[OrderItemTransaction] OIT with (nolock)
  on       OIT.OrderIDSeq             = II.OrderIDSeq
  and      OIT.OrderItemIDSeq         = II.OrderItemIDSeq
  and      OIT.IDSeq                  = II.OrderItemTransactionIDSeq
  and      OIT.TransactionImportIDSeq = @IPBI_BatchIDSeq
  and      OIT.ImportSource           = @IPVC_ImportSource
  and      OIT.InvoicedFlag           = 1
  and      OIT.PrintedOnInvoiceFlag   = 0
  group by I.InvoiceIdSeq
  ------------------------------------------------------------------------------------
  if exists (select top 1 1 from @LT_OpenInvoices)
  begin
    ---------------------------------------------------
    ---Delete corresponding InvoiceitemNotes if any
    Delete   IIN
    from     Invoices.dbo.Invoice     I  with (nolock)
    inner join
             Invoices.dbo.InvoiceItem II with (nolock)
    on       II.InvoiceIDSeq  = I.InvoiceIdSeq
    and      I.PrintFlag      = 0
    and      II.OrderItemTransactionIDSeq is not null
    inner join
             Orders.dbo.[OrderItemTransaction] OIT with (nolock)
    on       OIT.OrderIDSeq             = II.OrderIDSeq
    and      OIT.OrderItemIDSeq         = II.OrderItemIDSeq
    and      OIT.IDSeq                  = II.OrderItemTransactionIDSeq
    and      OIT.TransactionImportIDSeq = @IPBI_BatchIDSeq
    and      OIT.ImportSource           = @IPVC_ImportSource 
    inner join
             INVOICES.dbo.InvoiceItemNote IIN with (nolock)
    on       II.InvoiceIDSeq            = IIN.InvoiceIDSeq
    and      I.InvoiceIDSeq             = IIN.InvoiceIDSeq
    and      II.IDSeq                   = IIN.InvoiceItemIDSeq
    and      OIT.OrderIDSeq             = IIN.OrderIDSeq
    and      OIT.OrderItemIDSeq         = IIN.OrderItemIDSeq
    and      OIT.IDSeq                  = IIN.OrderItemTransactionIDSeq;
    ---------------------------------------------------
    select @LI_Min = 1,@LI_Max = (@LI_ActualImportCount/100)+2 
    --> Delete operation should be done in smaller chunks for performance reasons.
    while @LI_Min  <= @LI_Max
    begin
      SET ROWCOUNT 1000;
      begin try
        ------------------------------------------------------------------------------------
        --Step 3: Delete Open InvoiceItems pertaining to Transactions being rolled back.
        ------------------------------------------------------------------------------------
        Delete   II
        from     Invoices.dbo.Invoice     I  with (nolock)
        inner join
                 Invoices.dbo.InvoiceItem II with (nolock)
        on       II.InvoiceIDSeq  = I.InvoiceIdSeq
        and      I.PrintFlag      = 0
        and      II.OrderItemTransactionIDSeq is not null
        inner join
                 Orders.dbo.[OrderItemTransaction] OIT with (nolock)
        on       OIT.OrderIDSeq             = II.OrderIDSeq
        and      OIT.OrderItemIDSeq         = II.OrderItemIDSeq
        and      OIT.IDSeq                  = II.OrderItemTransactionIDSeq
        and      OIT.TransactionImportIDSeq = @IPBI_BatchIDSeq
        and      OIT.ImportSource           = @IPVC_ImportSource   
      end try
      begin catch
      end catch
      select @LI_Min = @LI_Min + 1
    end
  end
  set ROWCOUNT 0;
  ------------------------------------------------------------------------------------
  select @LI_Min = 1,@LI_Max = (@LI_ActualImportCount/100)+2 
  --> Delete operation should be done in smaller chunks for performance reasons.
  while @LI_Min  <= @LI_Max
  begin
    SET ROWCOUNT 1000;
    begin try
      ------------------------------------------------------------------------------------
      --Step 4: Delete all transactions from OrderItemTransaction for this batch
      ------------------------------------------------------------------------------------
      Delete  Orders.dbo.[OrderItemTransaction] 
      where   TransactionImportIDSeq = @IPBI_BatchIDSeq
      and     ImportSource           = @IPVC_ImportSource
      ------------------------------------------------------------------------------------
    end try
    begin catch
    end catch
    select @LI_Min = @LI_Min + 1
  end
  ------------------------------------------------------------------------------------
  set ROWCOUNT 0;
  select @LI_Min=1,@LI_Max=count(1) from @LT_OpenInvoices
  ------------------------------------------------------------------------------------
  --Step 4: Sync Invoices in Question
  ------------------------------------------------------------------------------------
  while @LI_Min <= @LI_Max
  begin
    select @LVC_InvoiceIDSeq = InvoiceIDSeq
    from   @LT_OpenInvoices
    where  sortseq = @LI_Min

    begin try
      EXEC INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID=@LVC_InvoiceIDSeq;
    end try
    begin catch
    end   catch
    select @LI_Min = @LI_Min + 1
  end
  ------------------------------------------------------------------------------------
  --Step 5 : Update ORDERS.dbo.TransactionImportBatchdetail for Rollback Status
  ------------------------------------------------------------------------------------
  Update ORDERS.dbo.TransactionImportBatchdetail
  set    DetailPostingStatusFlag   = 3,
         DetailPostingErrorMessage = 'User Initiated Online Rollback Operation ' + coalesce(@LVC_ReasonName,''),
         ModifiedByIDSeq           = @IPI_UserIDSeq,
         ModifiedDate              = @LDT_SystemDate,
         SystemLogDate             = @LDT_SystemDate
  where  TransactionImportIDSeq = @IPBI_BatchIDSeq
  ------------------------------------------------------------------------------------
  --Step 6 : Update ORDERS.dbo.TransactionImportBatchHeader for Rollback Status
  ------------------------------------------------------------------------------------
  Update ORDERS.dbo.TransactionImportBatchHeader
  set    ActualImportCount         = 0,
         ErrorCount                = @LI_ActualImportCount,
         BatchPostingStatusFlag    = 3,
         ErrorMessage              = 'User Initiated Online Rollback Operation',
         RollBackReasonCode        = @IPVC_RollbackReasonCode,
         RollBackByIDSeq           = @IPI_UserIDSeq,
         RollBackDate              = @LDT_SystemDate,
         ModifiedByIDSeq           = @IPI_UserIDSeq,
         ModifiedDate              = @LDT_SystemDate,
         SystemLogDate             = @LDT_SystemDate
  where  IDSeq     = @IPBI_BatchIDSeq
END
GO
