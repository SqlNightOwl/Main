SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_BillingCyclePeriodOpen]
-- Description     : This procedure accepts necessary parameters and Opens the BillingCycle Period
--                   in the One Record Table INVOICES.dbo.InvoiceEOMServiceControl
-- Input Parameters: @IPBI_BillingCycleOpenedByUserIDSeq
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_BillingCyclePeriodOpen @IPVC_BillingCycleDate = '02/15/2010',@IPBI_BillingCycleOpenedByUserIDSeq = 123

--Author           : SRS
--history          : Created 02/08/2010 Defect 7550

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_BillingCyclePeriodOpen] (@IPVC_BillingCycleDate               varchar(20),
                                                             @IPBI_BillingCycleOpenedByUserIDSeq  bigint
                                                            )
as
BEGIN --: Main Procedure BEGIN
  SET NOCOUNT ON;
  declare @LBI_RunBatchNumber  bigint;
  ------------------------------------------------------------------------
  --Step 0 : If record already exists for open period, 
  --         new billing cycle period cannot be opened. Hence Do Nothing.
  ------------------------------------------------------------------------
  if exists (select top 1 1 
             from   INVOICES.dbo.InvoiceEOMServiceControl with (nolock)
             where  BillingCycleClosedFlag = 0 --> open billing cycle status
            )
  begin
    return
  end
  ------------------
  if isdate(@IPVC_BillingCycleDate) = 0
  begin
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingCyclePeriodOpen. @IPVC_BillingCycleDate parameter passed is not a date datatype'
    return
  end
  else if isdate(@IPVC_BillingCycleDate) = 1
  begin
    select @IPVC_BillingCycleDate = convert(varchar(20),convert(datetime,@IPVC_BillingCycleDate),101)
  end
  ------------------------------------------------------------------------
  --Step1 : Pre-requisite1 : Archive INVOICES.dbo.BillingTargetDateMapping
  ------------------------------------------------------------------------
  Begin Try
     EXEC INVOICES.dbo.uspINVOICES_BillingTargetDateMappingArchive;
  End  Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingCyclePeriodOpen. Proc call uspINVOICES_BillingTargetDateMappingArchive Failed.'
    EXEC INVOICES.dbo.uspINVOICES_BillingTargetDateMappingRefresh;
    return
  end   Catch  
  ------------------------------------------------------------------------
  --Step2 : Pre-requisite2 : Archive INVOICES.dbo.InvoiceEOMServiceControl
  ------------------------------------------------------------------------
  Begin Try
     select @LBI_RunBatchNumber = EOMEngineRunBatchNumber 
     from   Invoices.dbo.InvoiceEOMServiceControl with (nolock)

     EXEC INVOICES.dbo.uspINVOICES_BillingCyclePeriodArchive; 
  End  Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingCyclePeriodOpen. Proc call uspINVOICES_BillingCyclePeriodArchive Failed.'
    EXEC INVOICES.dbo.uspINVOICES_BillingTargetDateMappingRefresh;
    return
  end   Catch
  ------------------------------------------------------------------------
  --Step 3: Open New Billing Cycle Period based on passed Parameters.
  ------------------------------------------------------------------------
  Begin Try
    Insert into INVOICES.dbo.InvoiceEOMServiceControl(BillingCycleDate,BillingCycleClosedFlag,
                                                      BillingCycleOpenedByUserIDSeq,BillingCycleOpenedDate,
                                                      EOMEngineRunBatchNumber,EOMEngineBatchRunStatus
                                                     )
    select @IPVC_BillingCycleDate as BillingCycleDate,0 as BillingCycleClosedFlag,
           @IPBI_BillingCycleOpenedByUserIDSeq as BillingCycleOpenedByUserIDSeq,Getdate() as BillingCycleOpenedDate,
           coalesce(@LBI_RunBatchNumber,0)     as EOMEngineRunBatchNumber,0 as EOMEngineBatchRunStatus

    Update Invoices.dbo.Invoice 
    set    BillingCycleDate = @IPVC_BillingCycleDate
    where  PrintFlag = 0
  end Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingCyclePeriodOpen. Opening New Billing Cycle Period Failed.'
    EXEC INVOICES.dbo.uspINVOICES_BillingTargetDateMappingRefresh;
    return
  end   Catch
  ------------------------------------------------------------------------
  --Step 4 : Refresh INVOICES.dbo.BillingTargetDateMapping
  Begin Try
     EXEC INVOICES.dbo.uspINVOICES_BillingTargetDateMappingRefresh;
  End  Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingCyclePeriodOpen. Proc call uspINVOICES_BillingTargetDateMappingRefresh Failed.'
    return
  end   Catch  
  ------------------------------------------------------------------------
END --: Main Procedure END
GO
