SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_EOMInvoicingGetOpenBillingCylceDate]
-- Description     : This procedure is called as first step of EOM Invoicing desktop application
-- OutPut          : Open and Active BillingCycleDate
--                   If BillingCycleDate is valid and EOMEngineLockedFlag = 0, then show to user as BillingCycleDate for confirmation.
--                   if BillingCycleDate is not valid or blank OR EOMEngineLockedFlag = 1, exit EOM Invoicing desktop application and do nothing.
-- Input Parameters: No Parameters
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_EOMInvoicingGetOpenBillingCylceDate

--Author           : SRS
--history          : Created 02/09/2010 Defect 7547

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_EOMInvoicingGetOpenBillingCylceDate]
as
BEGIN --: Main Procedure BEGIN
  SET NOCOUNT ON;
  ---------------------------
  begin try
    --BEGIN TRANSACTION;
      Select Top 1 convert(varchar(50),BC.BillingCycleDate,101) as BillingCycleDate,
                   convert(int,EOMEngineLockedFlag)             as EOMEngineLockedFlag 
      from   INVOICES.dbo.InvoiceEOMServiceControl BC with (NOLOCK) 
      where  BC.BillingCycleClosedFlag = 0
    --COMMIT TRANSACTION;
  End Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_EOMInvoicingGetOpenBillingCylceDate. Select Billing Cycle date Failed.'
    return
  end   Catch
END --: Main Procedure END
GO
