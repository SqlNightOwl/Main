use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranch_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ActiveBranch_process]
GO
setuser N'osi'
GO
CREATE procedure osi.ActiveBranch_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
,	@overRide	bit			= 0		--	forces a complete reload of all data...
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/18/2008
Purpose  :	Control procedure for the Active Branch process.  There are four parts
			to this process; Clear, Load, Calculate and Export.
				Clearing	--	occurs the 1st day and month of each quarter.
				Loading		--	occurs the 1st day of every month.  On the 1st
								month of each quarter the Members and Accounts
								are completely reloaded, otherwise only Members
								and Accounts setup during the month are added.
				Calculating	--	occurs 1st day of the 1st month of each quarter
								after data is loaded.
				Exporting	--	occurs the 1st day of every month.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
06/05/2009	Paul Hunter		Changed behavior for overRide parameter to recollect
							all data and recalculate the Active Branch.
08/31/2009	Paul Hunter		Changed Accout load to use ActiveBranchNbr instead of
							BranchOrgNbr.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@cmd			varchar(255)
,	@dayOfMth		tinyint
,	@detail			varchar(8000)
,	@excludeList	varchar(50)
,	@lendingDepts	varchar(50)
,	@monthInQtr		tinyint
,	@offset			tinyint
,	@result			int
,	@stepId			tinyint

--	initialize the variables...
select	@dayOfMth		= day(getdate())
	,	@detail			= ''
	,	@excludeList	= '15,30,ET,RA,SB'
	,	@lendingDepts	= '4,15,30,32,300,2692'	--	lending and call center
	,	@monthInQtr		= month(getdate()) % 3
	,	@overRide		= isnull(@overRide, 0)
	,	@result			= 0
	,	@stepId			= 0;

/*
**	PART ONE - CLEARING:	Reset the tables at the change of each quarter
————————————————————————————————————————————————————————————————————————————————
*/
if (@monthInQtr	= 1	and
	@dayOfMth	= 1	)
or (@overRide	= 1	)
begin
	--	remove transactions after 12 months...
	select	@cmd	= 'delete osi.ActiveBranchTransaction where Period <= '
					+ 'cast(convert(char(8), tcu.fn_LastDayOfMonth(dateadd(month, -13, getdate())), 112) as int);'
		,	@detail = 'Clearing ~ ';
	delete	osi.ActiveBranchTransaction
	where	Period	<= cast(convert(char(8), tcu.fn_LastDayOfMonth(dateadd(month, -13, getdate())), 112) as int);

	--	reload the accounts and members to capture members moving in/out of ARFS/Collections...
	set	@cmd	= 'truncate table osi.ActiveBranchAccount;'
	truncate table osi.ActiveBranchAccount;

	set	@cmd	= 'truncate table osi.ActiveBranchMember;'
	truncate table osi.ActiveBranchMember;
end;

/*
**	PART TWO - LOADING:	Load Account, Member & Transaction data every month.
————————————————————————————————————————————————————————————————————————————————
*/
--	Step 1:	load accounts and assign to members to collections...
select	@cmd	= 'exec osi.ActiveBranchAccount_ins;'
	,	@detail = @detail + 'Loading Accounts ~ '
	,	@stepId	= @stepId + 1;
exec osi.ActiveBranchAccount_ins;

--	load transactions if it's the 1st day of the month and they haven't been loaded...
--		NOTE: the value '20001231' is there to handle situations where the table is empty!
if	((	@dayOfMth = 1	) and
	((	select	datediff(day, cast(cast(isnull(max(Period), 0) as varchar) as datetime), getdate())
		from	osi.ActiveBranchTransaction ) > 28 ))
or	(	@overRide = 1 )
begin
	select	@cmd	= 'exec osi.ActiveBranchTransaction_ins'
		,	@detail = @detail + 'Load New Transactions ~ ';
	exec osi.ActiveBranchTransaction_ins;
end;

--	Step 2:	assign them where the've onened an account in the past X months based on the month in the quarter...
select	@offset	= case @monthInQtr when 1 then 3 else 1 end
	,	@cmd	= 'exec osi.ActiveBranch_calcAcctOpen @MonthsOffset = ' + cast(@offset as char(1))
	,	@detail = @detail + 'Assiging Members on Acct Opening ' + cast(@offset as char(1)) + ' ~ '
	,	@stepId	= @stepId + 1;

exec osi.ActiveBranch_calcAcctOpen @MonthsOffset = @offset
								,  @ExcludeList	 = @lendingDepts
								,  @StepId		 = @stepId;

/*
**	PART THREE - CALCULATING:	Calculate Active Branch.
————————————————————————————————————————————————————————————————————————————————
*/
if (@monthInQtr	= 1	and
	@dayOfMth	= 1	)		--	recalculate on the 1st day of 1st month of a quarter...
or (@overRide	= 1	)		--	or if the override option is selected.
begin
	--	Step 3:	if unassigned then assign them where the've done the most transactions in the past 3 months exclude branches 15, 30, ET, RA & SB...
	select	@cmd	= 'exec osi.ActiveBranch_calcTxnHist 3 & excusions'
		,	@detail = @detail + 'Active Branch calc on TxnHist 3 & excusions ~ '
		,	@offset	= 3
		,	@stepId	= @stepId + 1;
	exec osi.ActiveBranch_calcTxnHist @MonthsOffset	= @offset
									, @ExcludeList	= @excludeList
									, @StepId		= @stepId;

	--	Step 4:	if unassigned then assign them where the've done the most transactions in the past 12 months exclude branches 15, 30, ET, RA & SB...
	select	@cmd	= 'exec osi.ActiveBranch_calcTxnHist 12 & excusions'
		,	@detail = @detail + 'Active Branch calc on TxnHist 12 & excusions ~ '
		,	@offset	= 12
		,	@stepId	= @stepId + 1;
	exec osi.ActiveBranch_calcTxnHist @MonthsOffset	= @offset
									, @ExcludeList	= @excludeList
									, @StepId		= @stepId;

	--	Step 5:	if unassigned then assign them where the've onened an account in the past 36 months INCLUDE branches 15, 30, ET, RA & SB...
	select	@cmd			= 'exec osi.ActiveBranch_calcTxnHist 12 & NO excusions'
		,	@detail			= @detail + 'Active Branch calc on TxnHist 12 & NO excusions ~ '
		,	@excludeList	= ''
		,	@offset			= 12
		,	@stepId			= @stepId + 1;
	exec osi.ActiveBranch_calcTxnHist @MonthsOffset	= @offset
									, @ExcludeList	= @excludeList
									, @StepId		= @stepId;

	--	Step 6:	if unassigned then assign them where the've onened an account in the past 36 months...
	select	@cmd			= 'exec osi.ActiveBranch_calcAcctOpen @MonthsOffset 36'
		,	@detail			= @detail + 'Assigning Members on Acct Opening 36 ~ '
		,	@lendingDepts	= ''
		,	@offset			= 36
		,	@stepId			= @stepId + 1;
	--	look at the most recently opened account 
	exec osi.ActiveBranch_calcAcctOpen @MonthsOffset = @offset
									,  @ExcludeList	 = @lendingDepts
									,  @StepId		 = @stepId;
end;

/*
**	PART FOUR - EXPORTING:	Export Files (every month).
————————————————————————————————————————————————————————————————————————————————
*/
if @dayOfMth = 1	--	export on the 1st day of the month...
or @overRide = 1	--	or if the override option is selected.
begin
	select	@cmd	= 'exec @result = osi.ActiveBranch_export @run, @process, @schedule;'
		,	@detail = @detail + 'Export Files';
	exec @result = osi.ActiveBranch_export	@RunId		= @RunId
										,	@ProcessId	= @ProcessId
										,	@ScheduleId	= @ScheduleId;
end;

PROC_EXIT:
if @result != 0
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @cmd
						,	@Message	= @detail;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO