SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_BillingTargetDateMappingArchive]
-- Description     : This procedure Archives records 
--                       from INVOICES.dbo.BillingTargetDateMapping table 
--                       To   INVOICES.dbo.BillingTargetDateMappingArchive
-- Purpose         : This procedure is called as part of BillingCycle Close Process
--                   to archive active BillingTargetDateMapping records as soon as BillingCycle is Closed.
--                   Archival is to triggered as part of first step of subsequent Open Billing cycle Period process.
-- Input Parameters: None
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_BillingTargetDateMappingArchive

--Author           : SRS
--history          : Created 02/08/2010 Defect #7546

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_BillingTargetDateMappingArchive]
as
BEGIN --: Main Procedure BEGIN
  SET NOCOUNT ON;
  ------------------------------------------------------------------------------
  --Step 1 : Archive BillingTargetDateMapping records 
  ---        from  INVOICES.dbo.BillingTargetDateMappingArchive
  ---        To    INVOICES.dbo.BillingTargetDateMapping
  ---        This is triggered as part of first step of subsequent Open Billing cycle Period process.
  ------------------------------------------------------------------------------
  Begin Try
    Insert into INVOICES.dbo.BillingTargetDateMappingArchive(BillingCycleDate,LeadDays,TargetDate,ArchiveDate)
    select distinct BTDM.BillingCycleDate,BTDM.LeadDays,BTDM.TargetDate,Getdate() as ArchiveDate
    from   INVOICES.dbo.BillingTargetDateMapping BTDM with (nolock)
    where  not exists (select top 1 1 
                       from   INVOICES.dbo.BillingTargetDateMappingArchive XBTDM with (nolock)
                       where  XBTDM.BillingCycleDate = BTDM.BillingCycleDate
                       and    XBTDM.LeadDays         = BTDM.LeadDays
                      )
  End Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingTargetDateMappingArchive. BillingTargetDateMappingArchive table Archive Failed.'
    return
  end   Catch  
  -----------------------------------------------------------------------------
  --Step 2: Truncate table INVOICES.dbo.BillingTargetDateMapping
  --        in preparation for user to OPEN a New Billing Cycle Period.  
  -----------------------------------------------------------------------------
  Begin Try
    DELETE FROM INVOICES.dbo.BillingTargetDateMapping
  End   Try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspINVOICES_BillingTargetDateMappingArchive. Delete BillingTargetDateMapping table Refresh Failed.'
    return
  end   Catch  

  -----------------------------------------------------------------------------
END --: Main Procedure END
GO
