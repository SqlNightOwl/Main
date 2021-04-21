SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_BillingCyclePeriodArchive]
-- Description     : This procedure accepts necessary parameters and closes the BillingCycle Period
--                   in the One Record Table INVOICES.dbo.InvoiceEOMServiceControl
-- Input Parameters: None
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_BillingCyclePeriodArchive 

--Author           : SRS
--history          : Created 02/08/2010 Defect 7550

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_BillingCyclePeriodArchive] 
as
BEGIN --: Main Procedure BEGIN
  SET NOCOUNT ON;
  ------------------------------------------------------------------------------
  --Step 1 : Archive the CLOSED Billing Cycle Period record 
  ---        from  INVOICES.dbo.InvoiceEOMServiceControl 
  ---        To    INVOICES.dbo.InvoiceEOMServiceControlArchive
  ------------------------------------------------------------------------------
  Begin Try
    Insert into INVOICES.dbo.InvoiceEOMServiceControlArchive(BillingCycleDate,BillingCycleClosedFlag,BillingCycleOpenedByUserIDSeq,
                                                             BillingCycleOpenedDate,BillingCycleClosedByUserIDSeq,BillingCycleClosedDate,
                                                             ArchiveDate,EOMEngineRunBatchNumber,EOMEngineBatchRunStatus,EOMEngineLockedFlag,
                                                             EOMEngineStartDatetime,EOMEngineEndDatetime
                                                            )
    select A.BillingCycleDate,A.BillingCycleClosedFlag,A.BillingCycleOpenedByUserIDSeq,
           A.BillingCycleOpenedDate,A.BillingCycleClosedByUserIDSeq,A.BillingCycleClosedDate,
           Getdate() as ArchiveDate,A.EOMEngineRunBatchNumber,A.EOMEngineBatchRunStatus,A.EOMEngineLockedFlag,
           A.EOMEngineStartDatetime,A.EOMEngineEndDatetime           
    from   INVOICES.dbo.InvoiceEOMServiceControl A with (nolock)
    where  A.BillingCycleClosedFlag = 1
  End Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingCyclePeriodArchive. InvoiceEOMServiceControlArchive table Archive Failed.'
    return
  end   Catch  
  -----------------------------------------------------------------------------
  --Step 2: Truncate table INVOICES.dbo.InvoiceEOMServiceControl
  --        in preparation for user to OPEN a New Billing Cycle Period.
  -- NOTE : This step is needed as INVOICES.dbo.InvoiceEOMServiceControl can contain
  --        ONLY ONE RECORD AT ANY GIVEN TIME.
  -----------------------------------------------------------------------------
  Begin Try
    DELETE FROM INVOICES.dbo.InvoiceEOMServiceControl
  End   Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingTargetDateMappingArchive. Delete InvoiceEOMServiceControl table Refresh Failed.'
    return
  end   Catch 
  -----------------------------------------------------------------------------
END --: Main Procedure END
GO
