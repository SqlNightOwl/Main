SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_Rep_GetInvoiceInfo
-- Description     : This procedure gets Invoice Details pertaining to passed InvoiceID
-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(15)
--      
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_Rep_GetInvoiceInfo @IPVC_InvoiceID ='I0000000019'
    
-- 
-- 
-- Revision History:
-- Author          : Vinod Krishnan
-- 12/01/2006      : Stored Procedure Created.
--                 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetInvoiceInfoAsXML] ( @InvoiceInfo XML output,
                                                           @IPVC_InvoiceID  varchar(22)  
                                                         )
AS
BEGIN 
set nocount on;
declare @LVC_AccountID varchar(15)
declare @LN_TotalInvoiceAmtExcludingCurrent numeric(30,2)
declare @LN_TotalInvoiceAmtPaid numeric(30,2)
declare @LN_LastInvoiceDate varchar(12)
declare @LN_LastInvoiceamt numeric(30,2)
declare @LN_LastInvoiceDueDate varchar(12)
declare @LN_LastInvoice varchar(12)
declare @ErrorMessage   varchar(1000)
declare @ErrorSeverity Int
declare @ErrorState Int

  declare @LTBL_RESULTSET table
                          (
                            InvoiceNo varchar(22),
                            PastDue numeric(30,2),
                            CurrentILF numeric(30,2),
                            CurrentAccess numeric(30,2),
                            CurrentTransaction numeric(30,2),
                            CurrentSubTotal numeric(30,2),
                            CurrentTaxAmount numeric(30,2),
                            CurrentTotalCharges numeric(30,2),
                            CurrentCreditAmount numeric(30,2),
                            CurrentGrossCharges numeric(30,2),
                            TotalOutstandingCharges numeric(30,2),
                            LastInvoiceDate varchar(20),
                            LastInvoiceCharges numeric(30,2),
                            LastInvoiceDueDate varchar(20),
                            LastPaymentDate varchar(20),
                            LastPaymentAmount numeric(30,2),
                            NextInvoiceDate varchar(20)
                          )


BEGIN TRY

  insert into @LTBL_RESULTSET (InvoiceNo,NextInvoiceDate,CurrentILF,CurrentAccess,CurrentTransaction,CurrentSubTotal,CurrentTaxAmount,CurrentCreditAmount)
	select InvoiceIDSeq, '*****', ILFChargeAmount, AccessChargeAmount, TransactionChargeAmount,
	(isnull(ILFChargeAmount,0) + isnull(AccessChargeAmount,0) + isnull(TransactionChargeAmount,0)
	+ isnull(ShippingandHandlingAmount,0)), TaxAmount, CreditAmount
	from Invoices.dbo.Invoice with (nolock)	where InvoiceIDSeq = @IPVC_InvoiceID

select @LVC_AccountID = AccountIDSeq from Invoices.dbo.Invoice with (nolock) where InvoiceIDSeq = @IPVC_InvoiceID

update T set T.CurrentTotalCharges = isnull(T.CurrentSubTotal,0) + isnull(T.CurrentTaxAmount,0),
	T.CurrentGrossCharges = isnull(T.CurrentSubTotal,0) + isnull(T.CurrentTaxAmount,0) - isnull(T.CurrentCreditAmount,0)
	from @LTBL_RESULTSET T

Select @LN_LastInvoice = max(InvoiceIDSeq) From Invoices.dbo.Invoice with (nolock)Where AccountIDSeq = @LVC_AccountID and InvoiceIDSeq <> @IPVC_InvoiceID

if (@LN_LastInvoice<>'')
	Begin
	  Select @LN_LastInvoiceDate = InvoiceDate, @LN_LastInvoiceDueDate=InvoiceDueDate,
		 @LN_LastInvoiceamt=(isnull(ILFChargeAmount,0) + isnull(AccessChargeAmount,0) + 
                                    isnull(TransactionChargeAmount,0) + isnull(ShippingandHandlingAmount,0)+
                                    isnull(TaxAmount,0) - isnull(CreditAmount,0))
	  From Invoices.dbo.Invoice with (nolock)
	  Where AccountIDSeq = @LVC_AccountID
		and InvoiceIDSeq <> @IPVC_InvoiceID
		and InvoiceIDSeq = @LN_LastInvoice
	End

	select @LN_TotalInvoiceAmtExcludingCurrent = isnull(sum(isnull(ILFChargeAmount,0) + isnull(AccessChargeAmount,0) + isnull(TransactionChargeAmount,0) 
	+ isnull(ShippingandHandlingAmount,0) + isnull(TaxAmount,0) - isnull(CreditAmount,0)), 0)
	from Invoices.dbo.Invoice with (nolock) where AccountIDSeq = @LVC_AccountID and InvoiceIDSeq <> @IPVC_InvoiceID
	
       
       /*;with CTE_IP(TotalInvoiceAmtPaid)
        as (select sum(IP.InvoiceTotalAmount) as TotalInvoiceAmtPaid
            from   Invoices.dbo.InvoicePayment IP with (nolock)
            inner join
                   Invoices.dbo.Invoice I with (nolock)
            on     I.InvoiceIDSeq = IP.InvoiceIDSeq
            and    I.AccountIDSeq = @LVC_AccountID
            and    IP.PaymentGatewayResponseCode = 'Success'
            where  I.AccountIDSeq = @LVC_AccountID
           )
       select  @LN_TotalInvoiceAmtPaid = coalesce(CTE_IP.TotalInvoiceAmtPaid,0)
       from    CTE_IP;
       */

       --> OMS does not deal with Payments. For PrePaid II invoices, Payment info is records for reporting purposes only.
       -- Hence @LN_TotalInvoiceAmtPaid will have to be 0
       select  @LN_TotalInvoiceAmtPaid = 0 



	update @LTBL_RESULTSET set PastDue = @LN_TotalInvoiceAmtExcludingCurrent - @LN_TotalInvoiceAmtPaid
  
	update @LTBL_RESULTSET set TotalOutstandingCharges = PastDue + CurrentGrossCharges

	update @LTBL_RESULTSET set LastInvoiceDate = @LN_LastInvoiceDate,LastInvoiceCharges = @LN_LastInvoiceamt,LastInvoiceDueDate = @LN_LastInvoiceDueDate,LastPaymentDate = '',LastPaymentAmount = '0.00'

	Set @InvoiceInfo = (  
		select 
			InvoiceNo,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(PastDue,1,2)) as PastDue,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(CurrentILF,1,2)) as CurrentILF,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(CurrentAccess,1,2)) as CurrentAccess,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(CurrentTransaction,1,2)) as CurrentTransaction,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(CurrentSubTotal,1,2)) as CurrentSubTotal,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(CurrentTaxAmount,1,2)) as CurrentTaxAmount,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(CurrentTotalCharges,1,2)) as CurrentTotalCharges,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(CurrentCreditAmount,1,2)) as CurrentCreditAmount,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(CurrentGrossCharges,1,2)) as CurrentGrossCharges,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(TotalOutstandingCharges,1,2)) as TotalOutstandingCharges,
			LastInvoiceDate,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(LastInvoiceCharges,1,2)) as LastInvoiceCharges,
			LastInvoiceDueDate,LastPaymentDate,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(LastPaymentAmount,1,2)) as LastPaymentAmount,
			NextInvoiceDate,
			'$' + Convert(varchar(15), Invoices.dbo.fn_FormatCurrency(
			(CurrentTotalCharges),1,2)) as EndingBalance
			from @LTBL_RESULTSET for XML Path)
END TRY
BEGIN CATCH
        Set @ErrorMessage = 'GetInvoiceInfoAsXML '+ ERROR_MESSAGE();
        Set @ErrorSeverity = ERROR_SEVERITY();
        Set @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	    return;
end CATCH; 

END
GO
