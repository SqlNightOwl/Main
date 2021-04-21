SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_DeleteOrderItemTransactionsNotInvoiced
-- Description     : Delete Non Invoiced Orderitem Transaction
-- Input Parameters: @IPVC_OrderIDSeq       varchar(50),
--                   @IPBI_GroupIDSeq       bigint,
--                   @IPBI_OrderItemIDSeq   bigint
--                   @IPBI_TransactionIDSeq bigint
-- OUTPUT          : none
-- Code Example    : Exec ORDERS.dbo.[uspORDERS_DeleteOrderItemTransactionsNotInvoiced] parameters                                     
-- Revision History:
-- Author          : SRS
-- 07/17/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_DeleteOrderItemTransactionsNotInvoiced] (@IPVC_OrderIDSeq                 varchar(50),
                                                                           @IPBI_GroupIDSeq                 bigint,
                                                                           @IPBI_OrderItemIDSeq             bigint,
                                                                           @IPBI_TransactionIDSeq           bigint
                                                                          )
AS
BEGIN
  set nocount on;
  -----------------------------------------------------------
  declare @LI_Min                bigint,
          @LI_Max                bigint,
          @LVC_InvoiceIDSeq      varchar(50)
  select @LI_Min = 1,@LI_Max=1
  -----------------------------------------------------------
  declare @LT_OpenInvoices  table  (sortseq           int not null identity(1,1),
                                    InvoiceIDSeq      varchar(50)
                                   )

  ----------------------------------------------------------------------------------
  ---Step 1: Gather all Open Invoices pertaining to Transactions to be rolled back.
  --         This will be used later to Sync Invoices after deleting open records.
  ----------------------------------------------------------------------------------
  insert into @LT_OpenInvoices(InvoiceIDSeq)
  select   I.InvoiceIdSeq 
  from     Orders.dbo.[OrderItemTransaction] OIT with (nolock)
  inner Join
           Invoices.dbo.InvoiceItem II with (nolock)
  on     OIT.InvoicedFlag           = 1
  and    OIT.PrintedOnInvoiceFlag   = 0
  and    OIT.OrderIDSeq             = II.OrderIDSeq
  and    OIT.OrderItemIDSeq         = II.OrderItemIDSeq
  and    OIT.IDSeq                  = II.OrderItemTransactionIDSeq
  and    II.OrderItemTransactionIDSeq is not null
  and    OIT.IDSeq                  = @IPBI_TransactionIDSeq
  and    OIT.Orderidseq             = @IPVC_OrderIDSeq
  and    OIT.OrderGroupIDSeq        = @IPBI_GroupIDSeq
  and    OIT.OrderItemIDSeq         = @IPBI_OrderItemIDSeq
  and    II.OrderItemTransactionIDSeq = @IPBI_TransactionIDSeq
  and    II.Orderidseq                = @IPVC_OrderIDSeq
  and    II.OrderGroupIDSeq           = @IPBI_GroupIDSeq
  and    II.OrderItemIDSeq            = @IPBI_OrderItemIDSeq
  inner join
         Invoices.dbo.Invoice I with (nolock)
  on     II.InvoiceIDSeq  = I.InvoiceIdSeq
  and    I.PrintFlag      = 0
  where  OIT.IDSeq                  = @IPBI_TransactionIDSeq
  and    OIT.Orderidseq             = @IPVC_OrderIDSeq
  and    OIT.OrderGroupIDSeq        = @IPBI_GroupIDSeq
  and    OIT.OrderItemIDSeq         = @IPBI_OrderItemIDSeq
  and    II.OrderItemTransactionIDSeq = @IPBI_TransactionIDSeq
  and    II.Orderidseq                = @IPVC_OrderIDSeq
  and    II.OrderGroupIDSeq           = @IPBI_GroupIDSeq
  and    II.OrderItemIDSeq            = @IPBI_OrderItemIDSeq
  and    II.OrderItemTransactionIDSeq is not null
  group by I.InvoiceIdSeq
  ------------------------------------------------------------------------------------
  --Step 3: Delete Open InvoiceItems pertaining to Transactions being rolled back.
  ------------------------------------------------------------------------------------
  Delete   II
  from     Orders.dbo.[OrderItemTransaction] OIT with (nolock)
  inner Join
           Invoices.dbo.InvoiceItem II with (nolock)
  on     OIT.InvoicedFlag           = 1
  and    OIT.PrintedOnInvoiceFlag   = 0
  and    OIT.OrderIDSeq             = II.OrderIDSeq
  and    OIT.OrderItemIDSeq         = II.OrderItemIDSeq
  and    OIT.IDSeq                  = II.OrderItemTransactionIDSeq
  and    II.OrderItemTransactionIDSeq is not null
  and    OIT.IDSeq       = @IPBI_TransactionIDSeq
  and    OIT.Orderidseq      = @IPVC_OrderIDSeq
  and    OIT.OrderGroupIDSeq = @IPBI_GroupIDSeq
  and    OIT.OrderItemIDSeq  = @IPBI_OrderItemIDSeq
  and    II.OrderItemTransactionIDSeq = @IPBI_TransactionIDSeq
  and    II.Orderidseq      = @IPVC_OrderIDSeq
  and    II.OrderGroupIDSeq = @IPBI_GroupIDSeq
  and    II.OrderItemIDSeq  = @IPBI_OrderItemIDSeq
  inner join
         Invoices.dbo.Invoice I with (nolock)
  on     II.InvoiceIDSeq  = I.InvoiceIdSeq
  and    I.PrintFlag      = 0
  where  OIT.IDSeq                  = @IPBI_TransactionIDSeq
  and    OIT.Orderidseq             = @IPVC_OrderIDSeq
  and    OIT.OrderGroupIDSeq        = @IPBI_GroupIDSeq
  and    OIT.OrderItemIDSeq         = @IPBI_OrderItemIDSeq
  and    II.OrderItemTransactionIDSeq = @IPBI_TransactionIDSeq
  and    II.Orderidseq                = @IPVC_OrderIDSeq
  and    II.OrderGroupIDSeq           = @IPBI_GroupIDSeq
  and    II.OrderItemIDSeq            = @IPBI_OrderItemIDSeq
  and    II.OrderItemTransactionIDSeq is not null
  select @LI_Min=1,@LI_Max=count(1) from @LT_OpenInvoices
  ------------------------------------------------------------------------------------
  --Step 4: Sync Invoices in Question
  ------------------------------------------------------------------------------------
  select @LI_Min=1,@LI_Max=count(1) from @LT_OpenInvoices
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
  --Step 5: Delete ORDERS.dbo.Orderitemnote
  ------------------------------------------------------------------------------------
  Delete From ORDERS.dbo.Orderitemnote 
  where  Orderidseq      = @IPVC_OrderIDSeq
  and    OrderItemIDSeq  = @IPBI_OrderItemIDSeq
  and    OrderItemTransactionIDSeq = @IPBI_TransactionIDSeq
  and    OrderItemTransactionIDSeq is not null
  ------------------------------------------------------------------------------------------------------
  --Step 6: Delete ORDERS.dbo.OrderitemTransaction
  ------------------------------------------------------------------------------------------------------
  Delete from ORDERS.dbo.OrderitemTransaction
  where  IDSeq           = @IPBI_TransactionIDSeq
  and    Orderidseq      = @IPVC_OrderIDSeq
  and    OrderGroupIDSeq = @IPBI_GroupIDSeq
  and    OrderItemIDSeq  = @IPBI_OrderItemIDSeq
  and    ((InvoicedFlag    = 0 and PrintedOnInvoiceFlag = 0)
             OR 
          (InvoicedFlag    = 1 and PrintedOnInvoiceFlag = 0)
         ) --- Safety check; Either the transaction should be not invoiced at all Or if Invoiced it is on a open NOT Printed Invoice.

  ------------------------------------------------------------------------------------------------------
END
GO
