SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec INVOICES.dbo.uspINVOICES_RollbackInvoicesOnError @IPVC_OrderID=141,@IPI_OrderGroupID=141,@IPVC_InvoiceID = 'I0000000108'

----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_RollbackInvoicesOnError
-- Description     : This procedure creates Orders For a given approved quote.
-- Input Parameters: 1. @IPVC_OrderID      as varchar(50)
--                   2. @IPI_OrderGroupID  bigint
--                   3. @IPVC_InvoiceID    varchar(50)
-- OUTPUT          : None
--  
--                   
-- Code Example    : 
/*
exec INVOICES.dbo.uspINVOICES_RollbackInvoicesOnError 
                                   @IPVC_OrderID      ---Mandatory
                                   @IPVC_OrderGroupID ---Mandatory
                                   @IPVC_OrderItemID  --- Optional (If UI operation is granular)
                                   @IPBI_UserIDSeq    --- Mandatory.
*/
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 04/03/2007      : Stored Procedure Created.
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_RollbackInvoicesOnError]  (@IPVC_OrderID       varchar(50),
                                                           @IPVC_OrderGroupID  varchar(50),
                                                           @IPVC_OrderItemID   varchar(50)= '',
                                                           @IPBI_UserIDSeq     bigint = -1
                                                          )
AS
BEGIN
  set nocount on;
  declare @LDT_SystemDate datetime;

  declare @LVC_CodeSection        varchar(1000),
          @LVC_RollbackReasonCode varchar(10);

  select @IPVC_OrderID        = nullif(ltrim(rtrim(@IPVC_OrderID)),''),
         @IPVC_OrderGroupID   = nullif(ltrim(rtrim(@IPVC_OrderGroupID)),''),
         @IPVC_OrderItemID    = nullif(ltrim(rtrim(@IPVC_OrderItemID)),''),
         @LDT_SystemDate      = getdate();

  select Top 1 @LVC_RollbackReasonCode = R.Code 
  from   ORDERS.dbo.Reason R with (nolock)
  where  R.Code = 'IVER'
  ----------------------------------------------------------
  declare @LI_Min  int,@LI_Max  int;   
  declare @LVC_Invoiceid  varchar(50);
 
  Create table #LT_InvoicestoSyncup (Seq       int not null identity(1,1)  Primary Key,
                                     InvoiceID varchar(50)
                                    );  

  create table #LT_CurrentOpenOrderItems(Seq                    int not null identity(1,1)  Primary Key,
                                         invoiceidseq           varchar(50),
                                         invoicegroupidseq      bigint,
                                         invoiceitemidseq       bigint,
                                         Orderidseq             varchar(50),
                                         OrderGroupIDSeq        bigint,
                                         OrderItemIDSeq         bigint,
                                         ProductCode            varchar(50)
                                        );  
  --------------------------------------------------------------
  --Step 1 : Determine if there is an eligibility to rollback
  --         ie. The Invoice should not be printed.
  ---------------------------------------------------------------
  Insert into #LT_CurrentOpenOrderItems(invoiceidseq,invoicegroupidseq,invoiceitemidseq,
                                        Orderidseq,OrderGroupIDSeq,OrderItemIDSeq,ProductCode)

  Select II.invoiceidseq,II.invoicegroupidseq,II.IDSeq as invoiceitemidseq,
         II.Orderidseq,II.OrderGroupIDSeq,II.OrderItemIDSeq,II.ProductCode
  from   Invoices.dbo.Invoiceitem II with (nolock)
  inner join
         Invoices.dbo.Invoice I with (nolock)
  on     II.InvoiceIDSeq = I.InvoiceIDSeq
  and    I.Printflag     in (0,-1)
  and    II.OrderitemTransactionIdSeq is null
  inner join
         Invoices.dbo.InvoiceGroup IG with (nolock)
  on     II.InvoiceIDSeq      = IG.InvoiceIDSeq
  and    I.InvoiceIDSeq       = IG.InvoiceIDSeq
  and    II.InvoiceGroupIDSeq = IG.IDSeq
  and    II.OrderIDSeq        = IG.Orderidseq
  and    II.OrderGroupIDSeq   = IG.OrderGroupIDSeq
  and    II.OrderIDSeq        = @IPVC_OrderID
  and    II.OrderGroupIDSeq   = @IPVC_OrderGroupID
  and    (
           (IG.CustomBundlenameEnabledflag = 1)
               OR
           (II.OrderItemIDSeq = coalesce(@IPVC_OrderItemID,II.OrderItemIDSeq))
         )

  insert into #LT_InvoicestoSyncup(InvoiceID)
  select LT.invoiceidseq
  from   #LT_CurrentOpenOrderItems LT with (nolock)
  group by invoiceidseq;


  select @LI_Min=1,@LI_Max =count(InvoiceID)
  from #LT_InvoicestoSyncup with (nolock);  
  -----------------------------------------------------------------------------
  if (@LI_Max > 0)
  begin 
    BEGIN TRY      
         ---roll back Invoiceitemnote, Invoiceitem
        Delete D
        from  Invoices.dbo.InvoiceitemNote D  with (nolock)
        inner join
              #LT_CurrentOpenOrderItems    LT with (nolock)
        on    D.InvoiceIDSeq      = LT.InvoiceIDSeq
        and   D.invoiceitemidseq  = LT.invoiceitemidseq
        and   D.Orderidseq        = LT.Orderidseq
        and   D.OrderItemIDSeq    = LT.OrderItemIDSeq
        and   D.orderitemtransactionidseq is null;

        Delete D
        from   Invoices.dbo.Invoiceitem    D  with (nolock)
        inner join
              #LT_CurrentOpenOrderItems    LT with (nolock)
        on    D.InvoiceIDSeq      = LT.InvoiceIDSeq
        and   D.invoicegroupidseq = LT.invoicegroupidseq
        and   D.IDSeq             = LT.invoiceitemidseq
        and   D.Orderidseq        = LT.Orderidseq
        and   D.ordergroupidseq   = LT.ordergroupidseq
        and   D.OrderItemIDSeq    = LT.OrderItemIDSeq
        and   D.Productcode       = LT.ProductCode;
 
        Update OI
        set    OI.LastBillingPeriodFromDate = OI.POILastBillingPeriodFromDate,
               OI.LastBillingPeriodToDate   = OI.POILastBillingPeriodToDate,
               OI.ModifiedByUserIDSeq       = @IPBI_UserIDSeq,
               OI.RollbackReasonCode        = @LVC_RollbackReasonCode, 
               OI.RollbackByIDSeq           = @IPBI_UserIDSeq,
               OI.RollbackDate              = @LDT_SystemDate,
               OI.ModifiedDate              = @LDT_SystemDate,         
               OI.SystemLogDate             = @LDT_SystemDate 
        from   ORDERS.DBO.OrderItem     OI with (nolock)
        inner join
               #LT_CurrentOpenOrderItems S with (nolock) 
        on    OI.Orderidseq      = S.Orderidseq
        and   OI.OrderGroupIDSeq = S.OrderGroupIDSeq
        and   OI.IDSeq           = S.OrderItemIDSeq
        and   OI.Productcode     = S.ProductCode;            
    END TRY
    BEGIN CATCH      
    END CATCH;  
  
    ---Finally Synch up Invoices with Deleted Invoiceitems for amounts.
    while @LI_Min <= @LI_Max
    begin
      select @LVC_Invoiceid = Invoiceid 
      from #LT_InvoicestoSyncup with (nolock)
      where Seq = @LI_Min
      Exec Invoices.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID = @LVC_Invoiceid;
      select @LI_Min = @LI_Min + 1
    end
  end  
  ----------------------------------------------------------------------------
  ---select Orderidseq,Ordergroupidseq,OrderItemIDSeq from  #LT_CurrentOpenOrderItems with (nolock)
  ----------------------------------------------------------------------------
  --Final Cleanup
  if (object_id('tempdb.dbo.#LT_CurrentOpenOrderItems') is not null) 
  begin
    drop table #LT_CurrentOpenOrderItems;
  end 
  if (object_id('tempdb.dbo.#LT_InvoicestoSyncup') is not null) 
  begin
    drop table #LT_InvoicestoSyncup;
  end  
  -----------------------------------------------------------------------------    
END
GO
