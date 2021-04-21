SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_EOMInvoicingUnLockAndEndProcess]
-- Description     : This procedure is called to increment the batchnumber and record the run status of EOMinvoicing Desktop run
-- OutPut          : Open and Active BillingCycleDate,EOMRunBatchNumber,EOMBatchRunStatus
-- Input Parameters: No Parameters
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_EOMInvoicingUnLockAndEndProcess

--Author           : SRS
--history          : Created 02/09/2010 Defect 7547

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_EOMInvoicingUnLockAndEndProcess] 
As
Begin
  set nocount on;
  set nocount on;
  begin try
    UPDATE [INVOICES].dbo.[InvoiceEOMServiceControl] 
    Set    EOMEngineBatchRunStatus   = 1,        
           EOMEngineLockedFlag       = 0,
           EOMEngineEndDatetime      = Getdate()
    where  BillingCycleClosedFlag    = 0
    and    EOMEngineLockedFlag       = 1
  End Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_EOMInvoicingSetRunBatchNumber. UnLock and EndProcess Failed.'
    return
  end   Catch 
End
GO
