use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[pcsATMFeeRefund_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[pcsATMFeeRefund_process]
GO
setuser N'osi'
GO
CREATE procedure osi.pcsATMFeeRefund_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/21/2008
Purpose  :	Loads PCS foreign AMT fees and produces an offsetting SWIM file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/08/2010	Paul Hunter		Added record retention policy.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@detail		varchar(4000)
,	@effective	datetime
,	@now		datetime
,	@postOn		datetime
,	@result		int
,	@user		varchar(25)

--	initialize the variables...
select	@detail		= ''
	,	@effective	= convert(char(10), getdate(), 121)
	,	@now		= getdate()
	,	@postOn		= convert(char(10), getdate() - 1, 121)
	,	@result		= 0
	,	@user		= tcu.fn_UserAudit()

--	load the ATM Fees and calculate the Refund amount...
exec @result = osi.pcsATMFeeRefund_load @ProcessId;

--	The above process will return a zero (success) if any fees are loaded...
--	...otherwise it returns a 2 (informational message)
if @result = 0
begin
	--	fees were assessed by may not be refundable...
	if exists (	select	top 1 PostOn from osi.pcs_ATMFeeRefund
				where	PostOn		= @postOn
				and		FeeRefunded	> 0	)
	begin
		--	generate the SWIM file...
		insert	tcu.ProcessSwimDetail
			(	RunId
			,	ProcessId
			,	EffectiveOn
			,	AccountNumber
			,	Amount
			,	IsComplete
			,	CreatedBy
			,	CreatedOn
			)
		select	@RunId
			,	@ProcessId
			,	@effective
			,	AccountNumber
			,	sum(FeeRefunded)
			,	IsComplete	= 0
			,	CreatedBy	= @user
			,	CreatedOn	= @now
		from	osi.pcs_ATMFeeRefund
		where	PostOn		= @PostOn
		and		FeeRefunded	> 0
		group by AccountNumber
		order by AccountNumber;

		--	build the fee offset...
		insert	tcu.ProcessSwimDetail
			(	RunId
			,	ProcessId
			,	EffectiveOn
			,	AccountNumber
			,	Amount
			,	TransactionCd
			,	TransactionDescription
			,	IsComplete
			,	CreatedBy
			,	CreatedOn
			)
		select	@RunId
			,	@ProcessId
			,	@effective
			,	GLOffsetAccount	--	Account
			,	(	--	total fees loaded from the step above...
					select	sum(Amount)	from tcu.ProcessSwimDetail
					where	RunId		= @RunId
					and		ProcessId	= @ProcessId
				)
			,	GLOffsetTransactionCd
			,	GLOffsetDescription
			,	IsComplete	= 0
			,	CreatedBy	= @user
			,	CreatedOn	= @now
		from	tcu.ProcessSwim
		where	ProcessId		= @ProcessId
		and		GLOffsetAccount	> 0;

		--	build the SWIM file
		exec @result = tcu.ProcessSwimDetail_buildSwimFile	@RunId		= @RunId
														,	@ProcessId	= @ProcessId
														,	@ScheduleId	= @ScheduleId;

		set	@result = isnull(nullif(@result, 0), @@error);

	end;	--	generate a SWIM File
	else
	begin
		select	@detail	= 'No PCS Accounts had any ATM Fees to be refunded for '
						+ convert(char(10), @postOn, 101) + ' therefore no SWIM file will be produced.'
			,	@result	= 2;	--	informational
	end;	--	no PCS ATM fees need to be refunded...
end;
else
begin
	select	@detail	= 'No PCS Accounts had any ATM Fees for '
					+ convert(char(10), @postOn, 101) + ' therefore no SWIM file will be produced.'
		,	@result	= 2;	--	informational
end;	--	no PCS ATM fees were assessed...

PROC_EXIT:
if @result > 0 or len(@detail) > 0
begin
	set	@result = isnull(nullif(@result, 0), 2)	--	information if not something other than zero
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= ''
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