SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_EOMInvoicingLockAndStartProcess]
-- Description     : This procedure is called to increment the batchnumber and record the run status of EOMinvoicing Desktop run
-- OutPut          : Open and Active BillingCycleDate,EOMRunBatchNumber,EOMBatchRunStatus
-- Input Parameters: No Parameters
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_EOMInvoicingLockAndStartProcess

--Author           : SRS
--history          : Created 02/09/2010 Defect 7547

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_EOMInvoicingLockAndStartProcess] 
As
Begin
  set nocount on;
  --------------------------------
  declare @LT_InvoiceEOMServiceControl table(
                                             BillingCycleDate      varchar(50),
                                             EOMRunBatchNumber     bigint,
                                             EOMEngineLockedFlag   int                                       
                                            );
  -------------------------------
  begin try
    --Step 1 : Refresh BillingTargetDateMapping
    EXEC INVOICES.dbo.uspINVOICES_BillingTargetDateMappingRefresh;

    BEGIN TRANSACTION
      UPDATE [INVOICES].dbo.[InvoiceEOMServiceControl] with (TABLOCKX,XLOCK,HOLDLOCK)      
      Set   EOMEngineBatchRunStatus   = 5,
            EOMEngineStartDatetime    = Getdate(),
            EOMEngineRunBatchNumber   = EOMEngineRunBatchNumber + 1,
            EOMEngineLockedFlag       = 1
      OUTPUT convert(varchar(50),inserted.BillingCycleDate,101), 
             inserted.EOMEngineRunBatchNumber,
             convert(int,deleted.EOMEngineLockedFlag)
      into  @LT_InvoiceEOMServiceControl(BillingCycleDate,EOMRunBatchNumber,EOMEngineLockedFlag)
      where BillingCycleClosedFlag  = 0
      and   EOMEngineLockedFlag     = 0
    COMMIT TRANSACTION
  End Try
  Begin Catch
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
    end 
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_EOMInvoicingLockAndStartProcess. Lock and Start Process Failed.'
    return
  end   Catch 
  ----------------------------------------------
  if not exists (select top 1 1 from @LT_InvoiceEOMServiceControl)
  begin
    Insert into @LT_InvoiceEOMServiceControl(BillingCycleDate,EOMRunBatchNumber,EOMEngineLockedFlag)
    select Top 1 convert(varchar(50),BC.BillingCycleDate,101) as BillingCycleDate,
                 BC.EOMEngineRunBatchNumber                   as EOMRunBatchNumber,
                 convert(int,BC.EOMEngineLockedFlag)          as EOMEngineLockedFlag 
    from   INVOICES.dbo.InvoiceEOMServiceControl BC with (NOLOCK) 
    where  BillingCycleClosedFlag  = 0 
  end
  ----------------------------------------------
  --Final Select to UI DeskTop Application
  ----------------------------------------------  
  select BillingCycleDate,EOMRunBatchNumber,EOMEngineLockedFlag 
  from   @LT_InvoiceEOMServiceControl
  ----------------------------------------------
End
GO
