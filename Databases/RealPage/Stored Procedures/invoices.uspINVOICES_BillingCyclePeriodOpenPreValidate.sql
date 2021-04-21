SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_BillingCyclePeriodOpenPreValidate]
-- Description     : This procedure accepts necessary parameters and closes the BillingCycle Period
--                   in the One Record Table INVOICES.dbo.InvoiceEOMServiceControl
-- Input Parameters: None
-- Code Example    : EXEC INVOICES.dbo.uspINVOICES_BillingCyclePeriodOpenPreValidate

--Author           : SRS
--history          : Created 02/08/2010 Defect 7550

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_BillingCyclePeriodOpenPreValidate]
as
BEGIN --: Main Procedure BEGIN
  SET NOCOUNT ON;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  ---------------------------
  declare @LI_InvoicesTobeGenerated   bigint;
  declare @LDT_BillingCycleDate       datetime;
  declare @LT_BillingCyclePreValidate table
                                      (CurrentBillingCycleDate             varchar(20),
                                       BillingCycleClosedFlag              int,
                                       EOMEngineLockedFlag                 int,
                                       ---------------------------
                                       NextPossibleBillingCycleDate        varchar(20),
                                       BillingClassification               varchar(50),
                                       InvoicesTobeGenerated               bigint not null default(0),
                                       UIAllowOpenNewBillingCycle          as (case when EOMEngineLockedFlag   = 1
                                                                                     then 'NO'
                                                                                    when BillingCycleClosedFlag= 0
                                                                                     then 'NO' 
                                                                                    when InvoicesTobeGenerated = 0
                                                                                     then 'YES'
                                                                                    when (BillingCycleClosedFlag=1 and InvoicesTobeGenerated > 0)
                                                                                     then 'NO'
                                                                                    when InvoicesTobeGenerated > 0
                                                                                     then 'NO'
                                                                               end),
                                       NewBillingCycleDateRestrictionRule  as (case when EOMEngineLockedFlag    = 1
                                                                                     then 'Billing based on Billing Cycle Period: ' + CurrentBillingCycleDate + ' is in progress. All operations are locked during this time.'
                                                                                    when BillingCycleClosedFlag =0
                                                                                     then 'Billing Cycle Period: ' + CurrentBillingCycleDate + ' is currently Open.'
                                                                                    when InvoicesTobeGenerated = 0
                                                                                     --->then 'Billing Cycle Period can be Re-Opened for ' + CurrentBillingCycleDate + ' (or) for next future period ' + NextPossibleBillingCycleDate + ' ' + BillingClassification + ' as applicable.'
                                                                                     then 'Billing Cycle Period can be Opened for future period ' + NextPossibleBillingCycleDate + ' ' + BillingClassification + ' Only as applicable.'
                                                                                    when (BillingCycleClosedFlag=1 and InvoicesTobeGenerated > 0)
                                                                                     then 'Only Re-opening Billing Cycle Period: ' + CurrentBillingCycleDate + ' is allowed at this time.'
                                                                                    when InvoicesTobeGenerated > 0
                                                                                     then 'Only Re-opening Billing Cycle Period: ' + CurrentBillingCycleDate + ' is allowed at this time.' 
                                                                               end),                                       
                                       NewBillingCycleDateRestriction      as (case when EOMEngineLockedFlag    = 1
                                                                                     then ''
                                                                                    when BillingCycleClosedFlag= 0
                                                                                     then ''
                                                                                    when InvoicesTobeGenerated = 0
                                                                                     then ''
                                                                                    when (BillingCycleClosedFlag=1 and InvoicesTobeGenerated > 0)
                                                                                     then CurrentBillingCycleDate
                                                                                    when InvoicesTobeGenerated > 0
                                                                                     then CurrentBillingCycleDate
                                                                               end),
                                       GeneralMessage                      as   'Invoice(s) pending to be Generated as of Billing Cycle Period: ' + CurrentBillingCycleDate + ' = ' + convert(varchar(100),InvoicesTobeGenerated),
                                       OpenedByUser                        varchar(50),
                                       OpenedOnDate                        varchar(50),
                                       ClosedByUser                        varchar(50),
                                       ClosedOnDate                        varchar(50)
                                    )
  --------------------------------------------------------------------------------------
  --Step 1 : Get the current Billing Cycle Record Invoices.dbo.InvoiceEOMServiceControl
  -- Note  : Invoices.dbo.InvoiceEOMServiceControl table should contain only one record.
  --------------------------------------------------------------------------------------
  Insert into @LT_BillingCyclePreValidate(CurrentBillingCycleDate,BillingCycleClosedFlag,NextPossibleBillingCycleDate,BillingClassification,EOMEngineLockedFlag,
                                          OpenedByUser,OpenedOnDate,ClosedByUser,ClosedOnDate
                                          )
  select Top 1 convert(varchar(50),A.BillingCycleDate,101),A.BillingCycleClosedFlag,
         (Case when day(A.BillingCycleDate) < 15 
                 then convert(varchar(50),Month(A.BillingCycleDate)) + '/15/' + convert(varchar(50),Year(A.BillingCycleDate))
               when day(A.BillingCycleDate) = day(convert(datetime,Invoices.DBO.fn_SetLastDayOfMonth(A.BillingCycleDate)))
                 then   convert(varchar(50),Month(convert(datetime,Invoices.DBO.fn_SetFirstDayOfFollowingMonth(A.BillingCycleDate)))) + '/15/' 
                      + convert(varchar(50),Year(convert(datetime,Invoices.DBO.fn_SetFirstDayOfFollowingMonth(A.BillingCycleDate))))
               else convert(varchar(50),convert(datetime,Invoices.DBO.fn_SetLastDayOfMonth(A.BillingCycleDate)),101)
          end), 
          (Case when day(A.BillingCycleDate) < 15 
                 then 'Mid Month'
                when day(A.BillingCycleDate) = day(convert(datetime,Invoices.DBO.fn_SetLastDayOfMonth(A.BillingCycleDate)))
                 then 'Mid Month'
                else 'End Of Month'
          end),
          convert(int,A.EOMEngineLockedFlag) as EOMEngineLockedFlag,
          coalesce(UO.FirstName + ' ' + UO.LastName,'')   as OpenedByUser,
          A.BillingCycleOpenedDate                        as OpenedOnDate,
          coalesce(UC.FirstName + ' ' + UC.LastName,'')   as ClosedByUser,
          A.BillingCycleClosedDate                        as ClosedOnDate
  from   INVOICES.dbo.InvoiceEOMServiceControl A with (nolock)
  left outer join
         Security.dbo.[User] UO with (nolock)
  on     A.BillingCycleOpenedByUserIDSeq = UO.IDSeq
  left outer join
         Security.dbo.[User] UC with (nolock)
  on     A.BillingCycleClosedByUserIDSeq = UC.IDSeq

  select @LDT_BillingCycleDate = CurrentBillingCycleDate
  from   @LT_BillingCyclePreValidate A 
  --------------------------------------------------------------------------------------
  --Step 3 : Get Count of all Invoices that are waiting to be Generated with PrintFlag = 0
  select @LI_InvoicesTobeGenerated = 0
  select @LI_InvoicesTobeGenerated = count(I.InvoiceIDSeq)
  from   Invoices.dbo.Invoice I with (nolock)
  where  (I.PrintFlag = 0)
  and    coalesce(I.BillingCycleDate,@LDT_BillingCycleDate) <= @LDT_BillingCycleDate

  Update @LT_BillingCyclePreValidate
  set    InvoicesTobeGenerated = @LI_InvoicesTobeGenerated
  -----------------------------------------------------------------------------------
  --Final Select to UI
  select CurrentBillingCycleDate,            ---> This is current Billing CycleDate
         (case when EOMEngineLockedFlag    = 1 
                then 'Locked'
              when BillingCycleClosedFlag=1 
                then 'Closed' 
              else  'Open'
          end) as CurrentBillingCyclePeriodStatus, ---> This is current Billing Cycle Period Status
         InvoicesTobeGenerated,              ---> InvoicesTobeGenerated
         UIAllowOpenNewBillingCycle,         ---> When CurrentBillingCyclePeriodStatus is Open and UIAllowOpenNewBillingCycle NO, UI will not allow opening of new billing Period.
                                             ---- When CurrentBillingCyclePeriodStatus is Closed and UIAllowOpenNewBillingCycle is NO,UI will look for NewBillingCycleDateRestriction 
                                             ----    if it is not blank with a valid date,UI will put a restriction on accepting only "NewBillingCycleDateRestriction" 
                                             ---- When CurrentBillingCyclePeriodStatus is Closed and UIAllowOpenNewBillingCycle is YES,UI will look for NewBillingCycleDateRestriction 
                                             ----    if it blank then User is allowed to key in any date greater than or equal to CurrentBillingCycleDate.                                             
                                             ----         returned by the proc to reopen same billing period, if user had prematurely closed.
         NewBillingCycleDateRestriction,     ---> This is NewBillingCycleDateRestriction (either Blank or valid date) as returned by the proc.
         NewBillingCycleDateRestrictionRule, ---> The message will be displayed on the bottom of the Billing Cycle Open/Close modal.
         GeneralMessage,                     ---> General Message to display in UI Modal Billing Cycle Open/Close modal at the end.
         (case when UIAllowOpenNewBillingCycle = 'NO' then NewBillingCycleDateRestriction
               else NextPossibleBillingCycleDate
          end) as NextPossibleBillingCycleDate, ---> This is Upper End Billing date that UI will validate; user cannot enter a date beyond this NextPossibleBillingCycleDate
                                               ---    only when Currentstatus is closed and User wants to Open a new Billing Cycle Period.
         OpenedByUser              as OpenedByUser, ---> FullName of User who Opened the Billing Period
         coalesce(OpenedOnDate,'') as OpenedOnDate, ---> Datetime of Billing Period Open Operation
         ClosedByUser              as ClosedByUser, ---> FullName of User who Closed the Billing Period
         coalesce(ClosedOnDate,'') as ClosedOnDate  ---> Datetime of Billing Period Close Operation
  from   @LT_BillingCyclePreValidate
  -----------------------------------------------------------------------------------
END --: Main Procedure END
GO
