SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_ApplyMBADOExceptionRules
-- Description     : This procedure gets Applicable MBA Applicable Exception Rules for a Given CompanyID 
--                    from call of uspORDERS_MBADOExceptionRulesEngine
--                    and Applies to Orders. It also takes care of rolling back open Invoiceitems that has different MBA and DO rule
--                    for Re-Invoicing.
-- Input Parameters: @IPVC_CompanyIDSeq      as varchar(50)
-- Syntax          : 
/*
EXEC ORDERS.dbo.uspORDERS_ApplyMBADOExceptionRules  @IPVC_CompanyIDSeq='C0901010086',@IPBI_UserIDSeq=123  
EXEC ORDERS.dbo.uspORDERS_ApplyMBADOExceptionRules  @IPVC_CompanyIDSeq='C0901000061',@IPBI_UserIDSeq=123  
*/
-- Revision History:
-- Author          : SRS
-- 02/14/2010      : SRS (Defect 7915) Multiple Billing Address enhancement. SP Created.
-----------------------------------------------------------------------------------------------------------------------------
Create PROCEDURE [orders].[uspORDERS_ApplyMBADOExceptionRules] (@IPVC_CompanyIDSeq   varchar(50),   --> This is the CompanyID
                                                             @IPBI_UserIDSeq      bigint         --> This is UserID of person logged on (Mandatory)  
                                                            )
as
BEGIN
  set nocount on;
  ------------------------------------------
  --Local Variables.
  declare @LDT_SystemDate         datetime,
          @LVC_CodeSection        varchar(1000),
          @LVC_RollbackReasonCode varchar(10),
          @LVC_InvoiceID          varchar(50), 
          @LI_Min                 int,
          @LI_Max                 int;
  select  @LDT_SystemDate = Getdate(),
          @LI_Min         = 1,
          @LI_Max         = 0;

  select Top 1 @LVC_RollbackReasonCode = R.Code 
  from   ORDERS.dbo.Reason R with (nolock)
  where  R.Code = 'MBAC'
  ------------------------------------------
  Create Table #LT_MBADOEROrderData (Seq                             bigint  not null identity(1,1) primary Key,
                                     companyidseq                    varchar(50),
                                     propertyidseq                   varchar(50),
                                     accountidseq                    varchar(50),
                                     productcode                     varchar(50),
                                     custombundlenameenabledflag     int,
                                     orderidseq                      varchar(50),
                                     ordergroupidseq                 bigint,
                                     orderitemidseq                  bigint,
                                     currentbilltoaddresstypecode    varchar(20),
                                     currentbilltodeliveryoptioncode varchar(20),
                                     newbilltoaddresstypecode        varchar(20),
                                     newbilltodeliveryoptioncode     varchar(20)
                                    );

  Create table #LT_InvoicestoSyncup (Seq       int not null identity(1,1)  Primary Key,
                                     InvoiceID varchar(50)
                                    );  

  create table #LT_CurrentOpenOrderItems(Seq                       int not null identity(1,1)  Primary Key,
                                         companyidseq              varchar(50),
                                         accountidseq              varchar(50),
                                         invoiceidseq              varchar(50),
                                         invoicegroupidseq         bigint,
                                         invoiceitemidseq          bigint,
                                         orderidseq                varchar(50),
                                         ordergroupidseq           bigint,
                                         orderitemidseq            bigint,
                                         orderitemtransactionidseq bigint,
                                         productcode               varchar(50)
                                        );  
  
  -----------------------------------------------------------------------------------
  --Step 1 : Call uspORDERS_MBADOExceptionRulesEngine for input @IPVC_CompanyIDSeq 
  --         and store Current Vs New data in #LT_MBADOEROrderData
  -----------------------------------------------------------------------------------
  Insert into #LT_MBADOEROrderData(companyidseq,propertyidseq,accountidseq,productcode,custombundlenameenabledflag,
                                   orderidseq,ordergroupidseq,orderitemidseq,
                                   currentbilltoaddresstypecode,currentbilltodeliveryoptioncode,
                                   newbilltoaddresstypecode,newbilltodeliveryoptioncode
                                  )
  Exec ORDERS.dbo.uspORDERS_MBADOExceptionRulesEngine  @IPVC_CompanyIDSeq=@IPVC_CompanyIDSeq;
  -----------------------------------------------------------------------------------
  --Step2 : If there exists atleast one record where Current Vs New is different
  --        Proceed with Synchronizing that to Order Item and also Rollback
  --        Open InvoiceItems if any for Re-Invoicing.
  -----------------------------------------------------------------------------------
  Update OI
  set    OI.billtoaddresstypecode = (Case when O.PropertyIDSeq is not null then 'PBT'
                                          else 'CBT'
                                     end),
         OI.ModifiedByUserIDSeq       = @IPBI_UserIDSeq,
         OI.SystemLogDate             = @LDT_SystemDate 
  from   Orders.dbo.[Order]       O     with (nolock) 
  inner join
         ORDERS.DBO.OrderItem     OI    with (nolock)
  on     O.OrderIDSeq   = OI.OrderIDSeq
  and    O.CompanyIDSeq = @IPVC_CompanyIDSeq
  and    OI.billtoaddresstypecode is null;

  Update OI
  set    OI.billtodeliveryoptioncode  =  'SMAIL',
         OI.ModifiedByUserIDSeq       = @IPBI_UserIDSeq,
         OI.SystemLogDate             = @LDT_SystemDate 
  from   Orders.dbo.[Order]       O     with (nolock) 
  inner join
         ORDERS.DBO.OrderItem     OI    with (nolock)
  on     O.OrderIDSeq   = OI.OrderIDSeq
  and    O.CompanyIDSeq = @IPVC_CompanyIDSeq
  and    OI.billtodeliveryoptioncode is null;


  if exists (select top 1 1
             from   #LT_MBADOEROrderData MBADO with (nolock)
             where ((MBADO.currentbilltoaddresstypecode    <> MBADO.newbilltoaddresstypecode)
                       OR
                    (MBADO.currentbilltodeliveryoptioncode <> MBADO.newbilltodeliveryoptioncode)
                   )
            )
  begin --> Begin for MBADO if
    ------------------------------------------------------------------
    --Step 2.1 : Apply Latest and Greatest MBA DO Rules
    ------------------------------------------------------------------
    Update OI
    set    OI.billtoaddresstypecode     = MBADO.newbilltoaddresstypecode,
           OI.billtodeliveryoptioncode  = MBADO.newbilltodeliveryoptioncode,
           OI.ModifiedByUserIDSeq       = @IPBI_UserIDSeq,
           OI.SystemLogDate             = @LDT_SystemDate 
    from   ORDERS.DBO.OrderItem     OI    with (nolock)
    inner join
           #LT_MBADOEROrderData     MBADO with (nolock) 
    on    OI.IDSeq           = MBADO.orderitemidseq
    and   OI.orderidseq      = MBADO.orderidseq
    and   OI.ordergroupidseq = MBADO.ordergroupidseq       
    and   OI.productcode     = MBADO.productcode 
    and    ((MBADO.currentbilltoaddresstypecode    <> MBADO.newbilltoaddresstypecode)
                        OR
            (MBADO.currentbilltodeliveryoptioncode <> MBADO.newbilltodeliveryoptioncode)
                        OR
            (OI.billtoaddresstypecode    <> MBADO.newbilltoaddresstypecode)
                        OR
            (OI.billtodeliveryoptioncode <> MBADO.newbilltodeliveryoptioncode)
           )
    where OI.orderidseq      = MBADO.orderidseq
    and   OI.ordergroupidseq = MBADO.ordergroupidseq
    and   OI.IDSeq           = MBADO.orderitemidseq
    and   OI.productcode     = MBADO.productcode 
    and    ((MBADO.currentbilltoaddresstypecode    <> MBADO.newbilltoaddresstypecode)
                        OR
            (MBADO.currentbilltodeliveryoptioncode <> MBADO.newbilltodeliveryoptioncode)
                        OR
            (OI.billtoaddresstypecode    <> MBADO.newbilltoaddresstypecode)
                        OR
            (OI.billtodeliveryoptioncode <> MBADO.newbilltodeliveryoptioncode)
           );
    ------------------------------------------------------------------
    --Step 2.2 : Get Open invoiceitems to Roll back for Re-Invoicing.
    ------------------------------------------------------------------
    insert into #LT_CurrentOpenOrderItems(companyidseq,accountidseq,invoiceidseq,invoicegroupidseq,invoiceitemidseq,
                                          orderidseq,ordergroupidseq,orderitemidseq,orderitemtransactionidseq,productcode)
    select I.companyidseq,I.accountidseq,I.invoiceidseq,II.invoicegroupidseq,II.IDSeq as invoiceitemidseq,
           II.orderidseq,II.ordergroupidseq,II.orderitemidseq,II.orderitemtransactionidseq,II.productcode
    from   Invoices.dbo.Invoice I with (nolock)
    inner join
           Invoices.dbo.Invoiceitem II with (nolock)
    on     II.InvoiceIDSeq    = I.InvoiceIDSeq
    and    I.Printflag        = 0
    and    I.PrePaidFlag      = 0
    and    I.CompanyIDSeq     = @IPVC_CompanyIDSeq
    inner join
           #LT_MBADOEROrderData MBADO with (nolock)
    on     I.companyidseq     = MBADO.companyidseq
    and    I.accountidseq     = MBADO.accountidseq
    and    I.CompanyIDSeq     = @IPVC_CompanyIDSeq
    and    MBADO.CompanyIDSeq = @IPVC_CompanyIDSeq
    and    II.orderidseq      = MBADO.orderidseq
    and    II.ordergroupidseq = MBADO.ordergroupidseq
    and    II.orderitemidseq  = MBADO.orderitemidseq
    and    II.productcode     = MBADO.productcode
    and    ((MBADO.currentbilltoaddresstypecode    <> MBADO.newbilltoaddresstypecode)
                        OR
            (MBADO.currentbilltodeliveryoptioncode <> MBADO.newbilltodeliveryoptioncode)
                        OR
            (II.billtoaddresstypecode    <> MBADO.newbilltoaddresstypecode)
                        OR
            (II.billtodeliveryoptioncode <> MBADO.newbilltodeliveryoptioncode)
                        OR
            (II.billtoaddresstypecode    <> MBADO.newbilltoaddresstypecode)
                        OR
            (II.billtodeliveryoptioncode <> MBADO.newbilltodeliveryoptioncode)
           )
    where  I.Printflag        = 0
    and    I.PrePaidFlag      = 0 
    and    I.CompanyIDSeq     = @IPVC_CompanyIDSeq;

    insert into #LT_InvoicestoSyncup(invoiceid)
    select invoiceidseq
    from   #LT_CurrentOpenOrderItems LT with (nolock)
    group by invoiceidseq;
    ------------------------------------------------------------------
    --Step 2.3: Do Rollback of Open InvoiceItems
    ------------------------------------------------------------------
    select @LI_Min=1,@LI_Max =count(InvoiceID)
    from   #LT_InvoicestoSyncup with (nolock);
    if (@LI_Max > 0)
    begin --> Begin for Open InvoiceItems if
      BEGIN TRY        
          Delete D
          from  Invoices.dbo.InvoiceitemNote D  with (nolock)
          inner join
                #LT_CurrentOpenOrderItems    LT with (nolock)
          on    D.InvoiceIDSeq     = LT.InvoiceIDSeq
          and   D.invoiceitemidseq = LT.invoiceitemidseq
          and   D.Orderidseq       = LT.Orderidseq
          and   D.OrderItemIDSeq   = LT.OrderItemIDSeq
          and   coalesce(D.orderitemtransactionidseq,-999) = coalesce(LT.orderitemtransactionidseq,-999);

          Delete D
          from   Invoices.dbo.Invoiceitem    D  with (nolock)
          inner join
                #LT_CurrentOpenOrderItems    LT with (nolock)
          on    D.InvoiceIDSeq      = LT.InvoiceIDSeq
          and   D.invoicegroupidseq = LT.invoicegroupidseq
          and   D.IDSeq             = LT.invoiceitemidseq
          and   D.Orderidseq        = LT.Orderidseq
          and   D.OrderItemIDSeq    = LT.OrderItemIDSeq
          and   coalesce(D.orderitemtransactionidseq,-999) = coalesce(LT.orderitemtransactionidseq,-999)
          and   D.Productcode   = LT.ProductCode
 
          Update OI
          set    OI.LastBillingPeriodFromDate = OI.POILastBillingPeriodFromDate,
                 OI.LastBillingPeriodToDate   = OI.POILastBillingPeriodToDate,
                 OI.ModifiedByUserIDSeq       = @IPBI_UserIDSeq,
                 OI.RollbackReasonCode        = @LVC_RollbackReasonCode, 
                 OI.RollbackByIDSeq           = @IPBI_UserIDSeq,
                 OI.RollbackDate              = @LDT_SystemDate,         
                 OI.SystemLogDate             = @LDT_SystemDate 
          from   ORDERS.DBO.OrderItem     OI with (nolock)
          inner join
                 #LT_CurrentOpenOrderItems S with (nolock) 
          on    OI.Orderidseq      = S.Orderidseq
          and   OI.OrderGroupIDSeq = S.OrderGroupIDSeq
          and   OI.IDSeq           = S.OrderItemIDSeq
          and   OI.Productcode     = S.ProductCode 

          Update OIT
          set    OIT.InvoicedFlag = 0,
                 OIT.SystemLogDate = @LDT_SystemDate 
          from   ORDERS.DBO.OrderItemTransaction  OIT with (nolock)
          inner join
                 #LT_CurrentOpenOrderItems S with (nolock) 
          on    OIT.IDSeq           = S.orderitemtransactionidseq
          and   OIT.Orderidseq      = S.Orderidseq
          and   OIT.OrderGroupIDSeq = S.OrderGroupIDSeq
          and   OIT.OrderItemIDSeq  = S.OrderItemIDSeq
          and   OIT.InvoicedFlag    = 1
          and   OIT.PrintedOnInvoiceFlag = 0        
      END TRY
      BEGIN CATCH        
        ------------------------      
        select @LVC_CodeSection =  'Proc: uspORDERS_ApplyMBADOExceptionRules;Error Rolling back open invoiceitems For Company: '+ @IPVC_CompanyIDSeq
        ------------------------    
        Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
        return;                  
      END CATCH;
    end --> end for Open InvoiceItems if
    ------------------------------------------------------------------
    --Step 2.3: Do Rollback of Open InvoiceItems
    ------------------------------------------------------------------
    while @LI_Min <= @LI_Max
    begin
      select @LVC_InvoiceID = Invoiceid 
      from #LT_InvoicestoSyncup with (nolock)
      where Seq = @LI_Min
      Exec Invoices.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID = @LVC_Invoiceid;
      select @LI_Min = @LI_Min + 1
    end
  end --> End for MBADO if
  ----------------------------------------------------------------------------
  --Final Cleanup
  ----------------------------------------------------------------------------
  if (object_id('tempdb.dbo.#LT_CurrentOpenOrderItems') is not null) 
  begin
    drop table #LT_CurrentOpenOrderItems;
  end 
  if (object_id('tempdb.dbo.#LT_InvoicestoSyncup') is not null) 
  begin
    drop table #LT_InvoicestoSyncup;
  end 
  if (object_id('tempdb.dbo.#LT_MBADOEROrderData') is not null) 
  begin
    drop table #LT_MBADOEROrderData;
  end 
  -----------------------------------------------------------------------------   
END
GO
