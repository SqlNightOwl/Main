use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[ATMBalancing_savWithdrawalSWIM]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[ATMBalancing_savWithdrawalSWIM]
GO
setuser N'sst'
GO
CREATE procedure sst.ATMBalancing_savWithdrawalSWIM
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/22/2009
Purpose  :	Creates the SWIM Detail records with the just loaded CNS Report file
			(TS10) and exports the SWIM file for loading into OSI.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
02/26/2010	Paul Hunter		Added exclusion criteria for "retired" ATMs 
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@now		datetime
,	@reportOn	datetime
,	@return		int
,	@user		varchar(25)

set	@return = 1;

--	initialize the variables...
select	top 1
		@reportOn	= ReportOn
	,	@now		= getdate()
	,	@user		= tcu.fn_UserAudit()
from	sst.ATMBalancing_vDetail
order by ReportOn;

--	collect the direct ATM Withdrawals...
insert	tcu.ProcessSwimDetail
	(	RunId
	,	ProcessId
	,	EffectiveOn
	,	AccountNumber
	,	Amount
	,	TransactionCd
	,	TransactionDescription
	,	CashBox
	,	IsComplete
	,	CreatedBy
	,	CreatedOn
	)
select	@RunId
	,	ps.ProcessId
	,	d.ReportOn
	,	l.DirectPostAcctNbr
	,	d.NetWithdrawal
	,	ps.TransactionCd
	,	d.Terminal + ' for ' + convert(char(10), d.ReportOn, 101)
	,	l.CashBox
	,	0
	,	@user
	,	@now
from	sst.ATMBalancingLog	d
join	tcu.Location		l
		on	d.Terminal = l.LocationCode
cross apply
		tcu.ProcessSwim		ps
where	ps.ProcessId		= @ProcessId
and		d.ReportOn			= @reportOn
and		d.NetWithdrawal		> 0
and		l.LocationSubType	!= 'Retired'
order by d.Terminal;

--	NOTE: THIS MUST BE THE FIRST THING AFTER THE INSERT !!
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