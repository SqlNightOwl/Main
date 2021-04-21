SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_BillingCyclePeriodClose]
-- Description     : This procedure accepts necessary parameters and closes the BillingCycle Period
--                   in the One Record Table INVOICES.dbo.InvoiceEOMServiceControl
-- Input Parameters: @IPBI_BillingCycleClosedByUserIDSeq
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_BillingCyclePeriodClose @IPBI_BillingCycleClosedByUserIDSeq = 123

--Author           : SRS
--history          : Created 02/08/2010 Defect 7550

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_BillingCyclePeriodClose] (@IPBI_BillingCycleClosedByUserIDSeq  bigint)
as
BEGIN --: Main Procedure BEGIN
  SET NOCOUNT ON;
  ---------------------------
  begin try
    Update INVOICES.dbo.InvoiceEOMServiceControl
    set    BillingCycleClosedFlag        = 1,
           BillingCycleClosedByUserIDSeq = @IPBI_BillingCycleClosedByUserIDSeq,
           BillingCycleClosedDate        = GETDATE()
    where  BillingCycleClosedFlag        = 0
  End Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingCyclePeriodClose. Closing Billing Cycle Failed.'
    return
  end   Catch
END --: Main Procedure END
GO
