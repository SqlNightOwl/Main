use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[BusinessFee_savSWIM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[BusinessFee_savSWIM]
GO
setuser N'ihb'
GO
CREATE procedure ihb.BusinessFee_savSWIM
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/12/2007
Purpose  :	Creates the Process SWIM Detail records with the just loaded Business
			Billing Report file and exports the SWIM file for loading into OSI.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@effective	datetime
,	@return		int
,	@STATUS		varchar(10)

select	@return = 0
	,	@STATUS	= 'Loaded';

if exists (	select	top 1 * from ihb.BusinessFee
			where	RunId	= @RunId
			and		Status	= @STATUS	)
begin

	--	initialize the effective date
	set	@effective	= convert(char(10), getdate(), 121);

	update	ihb.BusinessFee
	set		Fee	=	case left(Service, 3)
					when 'ACH'	then .15
					when 'Sto'	then 30
					else 0 end
	where	RunId	= @RunId
	and		Status	= @STATUS;

	--	load the transaction details
	insert	tcu.ProcessSwimDetail
		(	RunId
		,	ProcessId
		,	EffectiveOn
		,	AccountNumber
		,	TransactionDescription
		,	Amount
		,	IsComplete
		,	CreatedBy
		,	CreatedOn
		)
	select	@RunId
		,	@ProcessId
		,	@effective
		,	mf.AccountNumber
		,	Description		= left(mf.Service + ' ' + cast(mf.Items as varchar) + ' @ ' + cast(mf.Fee as varchar), 45)
		,	Amount			= mf.Items * mf.Fee
		,	IsComplete		= 0
		,	CreatedBy		= tcu.fn_UserAudit()
		,	CreatedOn		= getdate()
	from	tcu.ibb_MonthlyFee	mf
	join	openquery(OSI, '
			select	AcctNbr from osiBank.Acct
			where	CurrAcctStatCd = ''ACT'''
		)	o	on	mf.AccountNumber = o.AcctNbr
	where	mf.RunId	= @RunId
	and		mf.Status	= @STATUS
	and		mf.Fee		> 0
	and		mf.Items	> 0;

	--	create a the GL Offset and SWIM file if records were inserted...
	if @@rowcount > 0
	begin
		--	create the GL offset record
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
			,	ps.GLOffsetAccount	--	Account
			,	uf.Amount
			,	ps.GLOffsetTransactionCd
			,	ps.GLOffsetDescription
			,	IsComplete	= 0
			,	CreatedBy	= tcu.fn_UserAudit()
			,	CreatedOn	= getdate()
		from	tcu.ProcessSwim		ps
		cross join
			(	--	--	calculate the total fees loaded in the step above
				select	Amount = sum(Amount)
				from	tcu.ProcessSwimDetail
				where	RunId		= @RunId
				and		ProcessId	= @ProcessId
			)	uf
		where	ps.ProcessId		= @ProcessId
		and		ps.GLOffsetAccount	> 0;

		exec @return = tcu.ProcessSwimDetail_buildSwimFile	@RunId		= @RunId
														,	@ProcessId	= @ProcessId
														,	@ScheduleId	= @ScheduleId;

		--	update the status of the process.
		if @return = 0
		begin
			update	ihb.BusinessFee
			set		Status	= 'Completed'
			where	RunId	= @RunId
			and		Status	= @STATUS;
		end;
	end;
end;

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO