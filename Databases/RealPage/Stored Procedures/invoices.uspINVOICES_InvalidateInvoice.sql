SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_InvalidateInvoice]
-- Description     : Updates the Valid flag of Invoice to 0, if Invoice Payment through Payment gateway
--                   did not go through because of system technical error or Credit card or ACH is denied due to want of funds etc.

--                   This proc also Sets Quote status to cancelled.
--                   Invalid Invoices  and all associated Order records of Quote will be cleaned up by a backend process.

--                   This proc call should be made by UI for However many Invoice records of Grid show in UI 
--                     (resultset of which were returned by Exec INVOICES.dbo.uspINVOICES_UnprintedPrePaidInvoiceSelect @IPVC_QuoteIDSeq=)

-- Syntax          : EXEC INVOICES.dbo.uspINVOICES_InvalidateInvoice @IPVC_QuoteIDSeq = 'Q1XXXXXX',@IPVC_InvoiceID = 'I0901000609',@IPBI_UserIDSeq=123
-- Revision History:
-- Author          : SRS
-- 08/06/2011      : TFS 295 SRS - Instant Invoice - To Invalidate Invoice when Invoice Payment fails

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_InvalidateInvoice] (@IPVC_QuoteIDSeq        varchar(50),     ---> MANDATORY : This is the QuoteID pertaining to Prepaid Invoice in Question. UI knows this value.
                                                        @IPVC_InvoiceID         varchar(50),     ---> MANDATORY : This
                                                        @IPBI_UserIDSeq         bigint      =-1  ---> MANDATORY : User ID of the User Logged on and doing the operation.
                                                       )
AS
BEGIN
  set nocount on;
  ---------------------------------
  declare @LDT_SystemDate  datetime
  select  @LDT_SystemDate = Getdate()
  ---------------------------------
  BEGIN TRY
    ------------------------------------------------------------------
    --Step1 : Update for ValidFlag : Invalidate this Invoice for the II @IPVC_QuoteIDSeq
    ------------------------------------------------------------------
    update Invoices.dbo.Invoice 
    set    ValidFlag          = 0,
           printflag          = -1,
           xmlProcessingStatus= 2, 
           sentToEpicorFlag   = 1,
           ModifiedByIDSeq    = @IPBI_UserIDSeq,
           ModifiedDate       = @LDT_SystemDate,
           SystemLogDate      = @LDT_SystemDate
    where  InvoiceIDSeq       = @IPVC_InvoiceID
    and    PrePaidFlag        = 1
    and    ValidFlag          = 1;
    --------------------------------------------------
    --Also Invalidate other related Invoices for the II @IPVC_QuoteIDSeq 
    ;with Orders_CTE (QuoteIDSeq,OrderIDSeq)
     as (select O.QuoteIDSeq				as QuoteIDSeq,
                O.OrderIDSeq				as OrderIDSeq            
         from   ORDERS.dbo.[Order] O with (nolock)
         where  O.QuoteIDSeq  = @IPVC_QuoteIDSeq
        )
    Update Iinner
    set    Iinner.ValidFlag           = 0,
           Iinner.printflag           = -1,
           Iinner.xmlProcessingStatus = 2,
           sentToEpicorFlag           = 1,
           Iinner.ModifiedByIDSeq     = @IPBI_UserIDSeq,
           Iinner.ModifiedDate        = @LDT_SystemDate,
           Iinner.SystemLogDate       = @LDT_SystemDate
    from   INVOICES.dbo.Invoice     Iinner with (nolock)
    inner join 
           INVOICES.DBO.InvoiceItem II     with (nolock) 
    on     II.InvoiceIDSeq    = Iinner.InvoiceIDSeq
    and    Iinner.PrePaidFlag = 1
    and    Iinner.ValidFlag   = 1
    inner join 
           Orders_CTE OCTE 
    on     II.OrderIDSeq      = OCTE.OrderIDSeq
    where  Iinner.PrePaidFlag = 1
    and    Iinner.ValidFlag   = 1;
    --------------------------------------------------    
    ;with Orders_CTE (QuoteIDSeq,OrderIDSeq)
     as (select O.QuoteIDSeq				as QuoteIDSeq,
                O.OrderIDSeq				as OrderIDSeq            
         from   ORDERS.dbo.[Order] O with (nolock)
         where  O.QuoteIDSeq  = @IPVC_QuoteIDSeq
        )
     Update OI
     set    OI.POILastBillingPeriodFromDate = NULL,
            OI.POILastBillingPeriodToDate   = NULL
     from   Orders.dbo.Orderitem OI with (nolock)
     inner join           
            Orders_CTE OCTE 
     on     OI.OrderIDSeq      = OCTE.OrderIDSeq;
    -------------------------------------------------- 
    begin try
      --This is rollback open Invoices,Orders for this Quote.
      Exec QUOTES.dbo.[uspQUOTES_RollbackQuote] @IPVC_QuoteIDSeq = @IPVC_QuoteIDSeq
                                               ,@IPI_UserIDSeq   = @IPBI_UserIDSeq;      
    end try
    begin catch
    end catch
    -------------------------------------------------- 
    --This will Cancel the Quote
    Exec QUOTES.dbo.[uspQUOTES_CancelQuote]   @IPVC_QuoteIDSeq = @IPVC_QuoteIDSeq
                                             ,@IPBI_UserIDSeq  = @IPBI_UserIDSeq; 
    -------------------------------------------------- 
  END TRY
  BEGIN CATCH
    declare @LVC_CodeSection varchar(1000)
    select @LVC_CodeSection = 'Proc:uspINVOICES_InvalidateInvoice. Invalidating Invoice Failed.Invoice:'+ @IPVC_InvoiceID
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  END   CATCH;
  ---------------------------------
END
GO
