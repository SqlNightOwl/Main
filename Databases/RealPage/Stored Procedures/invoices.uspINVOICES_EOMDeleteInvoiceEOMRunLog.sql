SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_EOMDeleteInvoiceEOMRunLog]
-- Description     : This procedure is after EOMInvoicingLockAndStartProcess to clear old Log Records
--                   pertaining to previous billing CycleDate Run.
-- Input Parameters: @IPDT_BillingCycleDate,@IPI_EOMRunBatchNumber
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_EOMDeleteInvoiceEOMRunLog @IPDT_BillingCycleDate = '02/15/2010',@IPI_EOMRunBatchNumber = 1

--Author           : SRS
--history          : Created 02/09/2010 Defect 7547

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_EOMDeleteInvoiceEOMRunLog]  (@IPDT_BillingCycleDate  datetime,
                                                           @IPI_EOMRunBatchNumber  bigint
                                                          )
As
Begin
  SET NOCOUNT ON;
  ---------------------------
  begin try
    Delete from INVOICES.dbo.InvoiceEOMRunLog
    Where  (BillingCycleDate   <>  @IPDT_BillingCycleDate
            AND
            EOMRunBatchNumber  <>  @IPI_EOMRunBatchNumber
           )
  End Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_EOMDeleteInvoiceEOMRunLog. Delete old InvoiceEOMRunLog records Failed.'
    return
  end   Catch
END --: Main Procedure END
GO
