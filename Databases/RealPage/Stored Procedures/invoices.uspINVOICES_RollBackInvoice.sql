SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : uspINVOICES_RollBackInvoice   
-- Description     : This procedure Rollbacks Invoice
-- Input Parameters:   @IPBI_OrderItemID 
--					   @IPBI_OrderGroupID
--					   @IPB_IsCustomPackage 
-- OUTPUT          : 
--  
--                     
-- Code Example    : Exec Invoices.dbo.uspINVOICES_RollBackInvoice
-- Revision History:  
-- Author          : Shashi Bhushan  
-- 06/11/2008      : Stored Procedure Created.  
-- 10/18/2011      : TFS 1375 : Performance Issue fix 
-- 11/04/2011      : TFS 1514 : DB Ameliorate performance by taking Taxware out of the Transaction...
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspINVOICES_RollBackInvoice] (@IPVC_Orderid            varchar(50), 
                                                      @IPBI_OrderGroupID       bigint,
                                                      @IPVC_OrderItemIDSeq     varchar(50)=NULL,
                                                      @IPI_IsCustomBundle      int=0,                                                      
                                                      @IPVC_ProductCode        varchar(30)='',
                                                      @IPVC_ChargeTypeCode     varchar(50)=NULL,
                                                      @IPBI_UserIDSeq          bigint
                                                     )
AS 
BEGIN
  set nocount on;
  declare @LDT_SystemDate datetime;

  declare @LVC_CodeSection        varchar(1000),
          @LVC_RollbackReasonCode varchar(10);

  select @IPVC_ChargeTypeCode = nullif(@IPVC_ChargeTypeCode,''),
         @IPVC_OrderItemIDSeq = nullif(@IPVC_OrderItemIDSeq,''),
         @LDT_SystemDate      = getdate();

  select Top 1 @LVC_RollbackReasonCode = R.Code 
  from   ORDERS.dbo.Reason R with (nolock)
  where  R.Code = 'UCNL'
  ----------------------------------------------------------
  declare @LI_Min  int;
  declare @LI_Max  int;   
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
  and    II.Ordergroupidseq = @IPBI_OrderGroupID
  and    II.Orderidseq      = @IPVC_Orderid
  and    II.ChargeTypeCode  = coalesce(@IPVC_ChargeTypeCode,II.ChargeTypeCode)
  and    ((@IPI_IsCustomBundle = 1)
            OR
          ((II.OrderItemIDSeq = @IPVC_OrderItemIDSeq OR II.Productcode= @IPVC_ProductCode) and @IPI_IsCustomBundle = 0 and II.FrequencyCode <> 'OT')
            OR
          ((II.OrderItemIDSeq = @IPVC_OrderItemIDSeq and II.Productcode= @IPVC_ProductCode) and @IPI_IsCustomBundle = 0 and II.FrequencyCode = 'OT')
         )
  and    II.OrderitemTransactionIdSeq is null
  where  II.Ordergroupidseq = @IPBI_OrderGroupID
  and    II.Orderidseq      = @IPVC_Orderid
  and    II.ChargeTypeCode  = coalesce(@IPVC_ChargeTypeCode,II.ChargeTypeCode)
  and    ((@IPI_IsCustomBundle = 1)
            OR
          ((II.OrderItemIDSeq = @IPVC_OrderItemIDSeq OR II.Productcode= @IPVC_ProductCode) and @IPI_IsCustomBundle = 0 and II.FrequencyCode <> 'OT')
            OR
          ((II.OrderItemIDSeq = @IPVC_OrderItemIDSeq and II.Productcode= @IPVC_ProductCode) and @IPI_IsCustomBundle = 0 and II.FrequencyCode = 'OT')
         )
  and    II.OrderitemTransactionIdSeq is null;

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
