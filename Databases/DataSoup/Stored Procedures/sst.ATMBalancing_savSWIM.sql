use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[ATMBalancing_savSWIM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[ATMBalancing_savSWIM]
GO
setuser N'sst'
GO
CREATE procedure sst.ATMBalancing_savSWIM
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/22/2009
Purpose  :	Creates the SWIM Detail records with the just loaded CNS Report file
			(TS10) and exports the SWIM file for loading into OSI.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@now		datetime
,	@reportOn	datetime
,	@return		int
,	@user		varchar(25);

set	@return = 1;

--	collect the monthly fee and transaction description
select	top 1
		@reportOn	= ReportOn
	,	@now		= getdate()
	,	@user		= tcu.fn_UserAudit()
from	sst.ATMBalancing_vDetail;

--	create the transaction details
insert	tcu.ProcessSwimDetail
	(	RunId
	,	ProcessId
	,	EffectiveOn
	,	AccountNumber
	,	Amount
	,	TransactionCode
	,	TransactionDescription
	,	CashBox
	,	IsComplete
	,	CreatedBy
	,	CreatedOn
	)
select	@RunId
	,	ProcessId
	,	EffectiveOn
	,	AccountNumber
	,	Amount
	,	TransactionCode
	,	Description
	,	CashBox
	,	0			as	IsComplete
	,	@user		as	CreatedBy
	,	@now		as	CreatedOn
from(	--	collect the direct ATM Withdrawals...
		select	d.Terminal
			,	ps.ProcessId
			,	d.ReportOn			as EffectiveOn
			,	l.DirectPostAcctNbr	as AccountNumber
			,	d.NetWithdrawal		as Amount
			,	ps.TransactionCode
			,	convert(char(10), d.ReportOn, 101) + ' Withdrawals for ' + d.Terminal	as Description
			,	l.CashBox
		from	sst.ATMBalancingLog	d
		join	tcu.Location		l
				on	d.Terminal = l.LocationCode
		cross apply
				tcu.ProcessSwim		ps
		where	ps.ProcessId	= @ProcessId
		and		d.ReportOn		= @reportOn
		and		d.NetWithdrawal	> 0
	union all
		--	...create the offsetting transaction...
		select	d.Terminal
			,	ps.ProcessId
			,	d.ReportOn			as EffectiveOn
			,	ps.GLOffsetAccount	as AccountNumber
			,	d.NetWithdrawal		as Amount
			,	ps.GLOffsetTransactionCode
			,	convert(char(10), d.ReportOn, 101) + ' Withdrawal Offset for ' + d.Terminal	as Description
			,	l.CashBox
		from	sst.ATMBalancingLog	d
		join	tcu.Location		l
				on	d.Terminal = l.LocationCode
		cross apply
				tcu.ProcessSwim		ps
		where	ps.ProcessId	= @ProcessId
		and		d.ReportOn		= @reportOn
		and		d.NetWithdrawal	> 0
	)	d
order by d.Terminal, d.TransactionCode;

--	NOTE: THIS MUST BE THE FIRTS THING AFTER THE INSERT!!
if @@rowcount > 0 and @@error = 0
begin
	--	build the SWIM file
	exec @return = tcu.ProcessSwimDetail_buildSwimFile	@RunId		= @RunId
													,	@ProcessId	= @ProcessId
													,	@ScheduleId	= @ScheduleId;

	set	@return = isnull(nullif(@return, 0), @@error);
end;

return @return;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO