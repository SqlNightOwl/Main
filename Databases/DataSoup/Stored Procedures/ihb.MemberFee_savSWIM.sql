use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[MemberFee_savSWIM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[MemberFee_savSWIM]
GO
setuser N'ihb'
GO
CREATE procedure ihb.MemberFee_savSWIM
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/30/2007
Purpose  :	Creates the Process SWIM Detail records with the just loaded IHB
			Member Fee file and exports the SWIM file for loading into OSI.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
12/06/2007	Paul Hunter		Added the GL Offset Transaction to the Detail table.
09/02/2008	Paul Hunter		Added the period (month and year) to the transaction
							description.
09/18/2008	Vivian Liu		Define MjAcctTypCd when the type of MiAcctTypCd is defined.  
02/11/2009	Paul Hunter		Removed CIC as a Minor Type assessed the fee.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@effective		datetime
,	@fee			money
,	@now			datetime
,	@period			varchar(15)
,	@description	char(45)
,	@return			int
,	@user			varchar(25);

set	@return = 1;

if exists (	select	top 1 * from ihb.MemberFee	)
begin
	--	collect the monthly fee and transaction description
	select	@description	= TransactionDescription
		,	@fee			= cast(tcu.fn_ProcessParameter(ProcessId, 'Monthly Fee') as money)
		,	@effective		= convert(char(10), getdate(), 121)
		,	@now			= getdate()
		,	@period			= datename(month, getdate()) + ' ' + cast(year(getdate()) as varchar)
		,	@user			= tcu.fn_UserAudit()
	from	tcu.ProcessSwim
	where	ProcessId = @ProcessId;

	--	create the transaction details
	insert	tcu.ProcessSwimDetail
		(	RunId
		,	ProcessId
		,	EffectiveOn
		,	AccountNumber
		,	Amount
		,	TransactionDescription
		,	IsComplete
		,	CreatedBy
		,	CreatedOn
		)
	select	@RunId
		,	@ProcessId
		,	@effective
		,	cast(oa.AcctNbr as bigint)
		,	@fee
		,	left(@period + ' ' + @description, 45)
		,	IsComplete	= 0
		,	CreatedBy	= @user
		,	CreatedOn	= @now
	from	ihb.MemberFee	mf
	join	openquery(OSI, '
			select	a.MemberAgreeNbr
				,	a.AcctNbr
			from	osiBank.Acct a
			join(	select	MemberAgreeNbr
						,	min(CurrMiAcctTypCd) as MiAcctTypCd
					from	osiBank.Acct
					where	CurrAcctStatCd	= ''ACT''
					and		MjAcctTypCd		= ''CK''
					and		CurrMiAcctTypCd in (''CBA'')
					group by MemberAgreeNbr
				) t	on	a.MemberAgreeNbr	= t.MemberAgreeNbr
					and	a.CurrMiAcctTypCd	= t.MiAcctTypCd
			where	CurrAcctStatCd = ''ACT'''
		)	oa	on	mf.MemberNumber = oa.MemberAgreeNbr;

	--	create a the GL Offset and SWIM file if records were inserted...
	--	NOTE: THIS MUST BE THE FIRTS THING AFTER THE INSERT!!
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
			,	left(@period + ' ' + ps.GLOffsetDescription, 45)
			,	IsComplete	= 0
			,	CreatedBy	= @user
			,	CreatedOn	= @now
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

		--	build the SWIM file
		exec @return = tcu.ProcessSwimDetail_buildSwimFile	@RunId		= @RunId
														,	@ProcessId	= @ProcessId
														,	@ScheduleId	= @ScheduleId;

		set	@return = isnull(nullif(@return, 0), @@error);
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