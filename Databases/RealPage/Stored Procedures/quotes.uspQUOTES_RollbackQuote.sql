SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_RollbackQuote]
-- Description     : This procedure is called to Rollback a Quote
--                   This proc should be called by UI when user initiates Quote Rollback and when Eligibility of Rollback is 1
--
-- OUTPUT          : None
--
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_RollbackQuote] @IPVC_QuoteIDSeq = 'Q1010000005',@IPI_UserIDSeq = '76'

-- Revision History:
-- Author          : SRS
-- 07/29/2010      : Stored Procedure Created.Defect 7745
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_RollbackQuote] (@IPVC_QuoteIDSeq    varchar(50), --> This is QuoteID participating in Rollback from Approved State.
                                                  @IPI_UserIDSeq      bigint       --> User ID of User initiating the rollback.UI knows this.
                                                 )

AS
BEGIN 
  set nocount on;
  ----------------------------------------------------------------------------------
  --Declare Local Variables
  declare @LDT_SystemDate         datetime,
          @LI_EligibilityFlag     int,
          @LVC_RollbackReasonCode varchar(10);

  declare @LVC_CodeSection        varchar(2000)

  select  @LDT_SystemDate    = getdate(),
          @LI_EligibilityFlag=0,
          @IPI_UserIDSeq     =nullif(ltrim(rtrim(@IPI_UserIDSeq)),'');

  select @IPI_UserIDSeq = (case when @IPI_UserIDSeq is null or @IPI_UserIDSeq in (0,-1) 
                                  then NULL          
                                else  @IPI_UserIDSeq
                           end);
  ----------------------------------------------------------------------------------
  declare  @LT_EligibilityCheck table(EligibilityFlag  int,
                                      Message          varchar(2000)
                                     )
  ----------------------------------------------------------------------------------
  --Step 1 : Intial sanity check to see if the Quote is still eligible for rollback.
  insert into @LT_EligibilityCheck(EligibilityFlag,Message)
  Exec QUOTES.dbo.[uspQUOTES_EligibilityCheckForRollback] @IPVC_QuoteIDSeq = @IPVC_QuoteIDSeq

  select @LI_EligibilityFlag = EligibilityFlag from @LT_EligibilityCheck

  if (@LI_EligibilityFlag=0)
  begin
    ------------------------      
    select @LVC_CodeSection =  'Proc: uspQUOTES_RollbackQuote;This Quote has lost its eligibility for Rollback at the current moment --> QuoteID : '+ @IPVC_QuoteIDSeq
    ------------------------    
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  ----------------------------------------------------------------------------------
  begin try
    ---Step 1 : Rollback all Pertinent Orders from Invoiceitems and sync
    declare @LI_Min         int,
            @LI_Max         int,   
            @LVC_Invoiceid  varchar(50);

    Create table #LT_InvoicestoSyncup (Seq       int not null identity(1,1)  Primary Key,
                                       InvoiceID varchar(50)
                                       );

    Create table #LT_OrderstoRollBack (Seq        int not null identity(1,1)  Primary Key,
                                       QuoteIDSeq varchar(22),
                                       OrderIDSeq varchar(22)
                                       );

    Insert into #LT_OrderstoRollBack(QuoteIDSeq,OrderIDSeq)
    select O.QuoteIDSeq				as QuoteIDSeq,
           O.OrderIDSeq				as OrderIDSeq            
    from   ORDERS.dbo.[Order] O with (nolock)
    where  O.QuoteIDSeq  = @IPVC_QuoteIDSeq

    
    insert into #LT_InvoicestoSyncup(InvoiceID)
    select Iinner.InvoiceIDSeq
    from   INVOICES.dbo.Invoice     Iinner with (nolock)
    inner join 
           INVOICES.DBO.InvoiceItem II     with (nolock) 
    on     II.InvoiceIDSeq    = Iinner.InvoiceIDSeq
    and    Iinner.PrintFlag   in (0,-1)
    inner join 
           #LT_OrderstoRollBack OCTE 
    on     II.OrderIDSeq      = OCTE.OrderIDSeq
    where  Iinner.PrintFlag   in (0,-1)
    group by Iinner.InvoiceIDSeq;

    select @LI_Min=1,@LI_Max =count(InvoiceID)
    from #LT_InvoicestoSyncup with (nolock);  
    -------------------
    if (@LI_Max > 0)
    begin       
      Delete D
      from   Invoices.dbo.InvoiceitemNote D with (nolock)          
      inner join 
             #LT_OrderstoRollBack OCTE 
      on     D.OrderIDSeq      = OCTE.OrderIDSeq;
      
      Delete D
      from   Invoices.dbo.Invoiceitem D with (nolock)          
      inner join 
             #LT_OrderstoRollBack OCTE 
      on     D.OrderIDSeq         = OCTE.OrderIDSeq;
 
      ---Finally Synch up Invoices
      while @LI_Min <= @LI_Max
      begin
        select @LVC_Invoiceid = Invoiceid 
        from #LT_InvoicestoSyncup with (nolock)
        where Seq = @LI_Min;

        Exec Invoices.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID = @LVC_Invoiceid;

        select @LI_Min = @LI_Min + 1
      end
    end
    -------------------
    ---Step 2 : Rollback all Pertinent Orders 
    delete D 
    from   ORDERS.dbo.RegAdminQueue D with (nolock)
    inner join
           #LT_OrderstoRollBack     S with (nolock)
    on     D.OrderIDSeq = S.OrderIDSeq;

    delete D 
    from   ORDERS.dbo.OrderItemNote D with (nolock)
    inner join
           #LT_OrderstoRollBack     S with (nolock)
    on     D.OrderIDSeq = S.OrderIDSeq;

    delete D 
    from   ORDERS.dbo.OrderItemTransaction D with (nolock)
    inner join
           #LT_OrderstoRollBack            S with (nolock)
    on     D.OrderIDSeq = S.OrderIDSeq;

    delete D 
    from   ORDERS.dbo.OrderItem            D with (nolock)
    inner join
           #LT_OrderstoRollBack            S with (nolock)
    on     D.OrderIDSeq = S.OrderIDSeq;

    delete D 
    from   ORDERS.dbo.OrderGroupProperties D with (nolock)
    inner join
           #LT_OrderstoRollBack            S with (nolock)
    on     D.OrderIDSeq = S.OrderIDSeq;

    delete D 
    from   ORDERS.dbo.OrderGroup           D with (nolock)
    inner join
           #LT_OrderstoRollBack            S with (nolock)
    on     D.OrderIDSeq = S.OrderIDSeq;

    delete D 
    from   ORDERS.dbo.[Order]              D with (nolock)
    inner join
           #LT_OrderstoRollBack            S with (nolock)
    on     D.OrderIDSeq = S.OrderIDSeq
    and    D.QuoteIDSeq = S.QuoteIDSeq;      
  
    Delete from DOCUMENTS.dbo.DocumentLog where QuoteIDSeq = @IPVC_QuoteIDSeq;
    Delete from DOCUMENTS.dbo.Document    where QuoteIDSeq = @IPVC_QuoteIDSeq;
    -------------------
    select Top 1 @LVC_RollbackReasonCode = R.Code 
    from   ORDERS.dbo.Reason R with (nolock)
    where  R.Code = 'EAPQ'

    ---Step 3 : Put the Quote back to Submitted state.
    Update QUOTES.dbo.QUOTE
    set    QuoteStatusCode = 'SUB',
           ApprovalDate    = NULL, 
           AcceptanceDate  = NULL,           
           ModifiedByIdSeq    = @IPI_UserIDSeq,
           RollbackReasonCode = @LVC_RollbackReasonCode, 
           RollbackByIDSeq    = @IPI_UserIDSeq,
           RollbackDate       = @LDT_SystemDate,
           ModifiedDate       = @LDT_SystemDate,
           SystemLogDate      = @LDT_SystemDate
    where  QuoteIDSeq = @IPVC_QuoteIDSeq;

    exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID= @IPVC_QuoteIDSeq;
  end try
  begin catch
    ------------------------      
    select @LVC_CodeSection =  'Proc: uspQUOTES_RollbackQuote;Internal Fatal Error Rolling back this Quote. Aborting Rollback operation. --> QuoteID : '+ @IPVC_QuoteIDSeq
    ------------------------    
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end  catch

  ----------------------------------------------------------------------------
  --Final Cleanup
  if (object_id('tempdb.dbo.#LT_InvoicestoSyncup') is not null) 
  begin
    drop table #LT_InvoicestoSyncup;
  end 
  if (object_id('tempdb.dbo.#LT_OrderstoRollBack') is not null) 
  begin
    drop table #LT_OrderstoRollBack;
  end  
  -----------------------------------------------------------------------------  
END
GO
