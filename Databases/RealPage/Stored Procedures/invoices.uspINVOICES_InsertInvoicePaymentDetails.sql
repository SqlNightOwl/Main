SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_InsertInvoicePaymentDetails]
-- Description     : When the Total Row of Call EXEC INVOICES.dbo.uspINVOICES_UnprintedPrePaidInvoiceSelect @IPVC_QuoteIDSeq,@IPBI_UserIDSeq
--                    goes through successfull through Payment Gateway and that Confirmation is recieved back, this proc will be called from UI
--                    for each of InvoiceIDSeq rows of the (Grid displayed in UI) to record Invoice payment transactions

-- Syntax          : EXEC INVOICES.dbo.uspINVOICES_InsertInvoicePaymentDetails @IPVC_InvoiceID = 'I0901000609',@IPBI_UserIDSeq=123
-- Revision History:
-- Author          : SRS
-- 08/06/2011      : TFS 295 SRS - Instant Invoice - To Record Invoice Payment Details.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_InsertInvoicePaymentDetails] (@IPVC_QuoteIDSeq                             varchar(50),
                                                                  @IPVC_InvoiceID                              varchar(50),
                                                                  @IPVC_PaymentTransactionAuthorizationCode    varchar(100),
                                                                  @IPVC_PaymentTransactionNumber               varchar(100),
                                                                  @IPVC_PaymentTransactionDate                 datetime,
                                                                  @IPVC_PaymentMethod                          varchar(100),
                                                                  @IPVC_PaymentGatewayResponseCode             varchar(100),
                                                                  @IPM_TotalPaidAmount                         Money,
                                                                  @IPBI_UserIDSeq                              bigint      =-1  ---> MANDATORY : User ID of the User Logged on and doing the operation.
                                                                 )
AS
BEGIN
  set nocount on;
  ---------------------------------
  declare @LDT_SystemDate        datetime,
          @LM_InvoiceTotalAmount money,
          @LI_PrePaidFlag        int
  select  @LDT_SystemDate = Getdate()
  ---------------------------------
  select @LM_InvoiceTotalAmount = (I.ILFChargeAmount + I.AccessChargeAmount + I.TransactionChargeAmount + I.ShippingandHandlingAmount + I.TaxAmount),
         @LI_PrePaidFlag        = I.PrePaidFlag 
  from   Invoices.dbo.Invoice I with (nolock)
  where  I.InvoiceIDSeq = @IPVC_InvoiceID

  BEGIN TRY
    If ( (@LI_PrePaidFlag = 1)
          and
         not exists (select top 1 1
                     from   INVOICES.[dbo].[InvoicePayment] IP with (nolock)
                     where  IP.InvoiceIDSeq = @IPVC_InvoiceID     
                     )
       )
    begin
      insert into INVOICES.[dbo].[InvoicePayment](InvoiceIDSeq,QuoteIDSeq,
                                                  PaymentTransactionAuthorizationCode,PaymentTransactionNumber,PaymentTransactionDate,PaymentMethod,
                                                  InvoiceTotalAmount,TotalPaidAmount,PaymentGatewayResponseCode,CreatedByIDSeq,CreatedDate,SystemLogDate
                                                 )
      select @IPVC_InvoiceID                           as InvoiceIDSeq,
             @IPVC_QuoteIDSeq                          as QuoteIDSeq,
             @IPVC_PaymentTransactionAuthorizationCode as PaymentTransactionAuthorizationCode,
             @IPVC_PaymentTransactionNumber            as PaymentTransactionNumber,
             @IPVC_PaymentTransactionDate              as PaymentTransactionDate,
             @IPVC_PaymentMethod                       as PaymentMethod,
             @LM_InvoiceTotalAmount                    as InvoiceTotalAmount,
             @LM_InvoiceTotalAmount                    as TotalPaidAmount,
             @IPVC_PaymentGatewayResponseCode          as PaymentGatewayResponseCode,  
             @IPBI_UserIDSeq                           as CreatedByIDSeq,
             @LDT_SystemDate                           as CreatedDate,
             @LDT_SystemDate                           as SystemLogDate
    end
  END TRY
  BEGIN CATCH
    declare @LVC_CodeSection varchar(1000)
    select @LVC_CodeSection = 'Proc:uspINVOICES_InsertInvoicePaymentDetails. Inserting Payment Details Failed.Quote:' + @IPVC_QuoteIDSeq+ '.:Invoice:'+ @IPVC_InvoiceID
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  END   CATCH;
  ---------------------------------
END
GO
