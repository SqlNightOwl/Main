use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[CardTransaction_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[CardTransaction_process]
GO
setuser N'osi'
GO
CREATE procedure osi.CardTransaction_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/18/2008
Purpose  :	This procedure performs two checks:
			1.	Reports when the number of minutes since the last transaction 
				exceeds the parameter threshold.  This answers the question
					"Are we receiving transactions?"
			2.	Reports when there are any "un-settled" transactions since the
				last run.  This answers the question:
					"Are transactions being posted in OSI?"
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/05/2008	Paul Hunter		Added the second check.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@breakPoint	int
,	@cmd		nvarchar(750)
,	@detail		varchar(4000)
,	@items		int
,	@lastRun	datetime
,	@lastTxn	int
,	@maxAge		int
,	@MSG_INFO	int
,	@MSG_WARN	int
,	@result		int
,	@time		varchar(10);

--	initialize the result variable
select	@breakPoint	= cast(tcu.fn_ProcessParameter(@ProcessId, 'Warning Breakpoint' ) as int)
	,	@maxAge		= cast(tcu.fn_ProcessParameter(@ProcessId, 'Max Transaction Age') as int)
	,	@MSG_INFO	= 2		--	information message type
	,	@MSG_WARN	= 3		--	warning message type
	,	@result		= 0;

/*
————————————————————————————————————————————————————————————————————————————————
	CHECK # 1:
	Collect the age of the last posted transaction.
————————————————————————————————————————————————————————————————————————————————
*/
--	set the result and message detail value
select	@detail	= 'Check 1 - CRITICAL ISSUE:<br/>It has been ' + cast(t.lastTxnAge as varchar)
				+ ' minutes since the last Card Transaction was received '
				+ 'from CNS.  We are possibly offline.  Immediate attention is required.'
	,	@cmd	= 'select trunc((86400 * (sysdate - DateLastMaint)) / 60) - 60 * '
				+ '( trunc(((86400 * (sysdate - DateLastMaint)) / 60) / 60) ) as LastTxnAge '
				+ 'from CardTxn where CardTxnNbr = (select max(CardTxnNbr) from CardTxn)'
	,	@result	= @MSG_WARN	--	warning
from	openquery(OSI, '
		select	trunc(( 86400 * (sysdate - DateLastMaint)) / 60) - 60
			* (	trunc(((86400 * (sysdate - DateLastMaint)) / 60) / 60) ) as LastTxnAge
		from	CardTxn
		where	CardTxnNbr = (select max(CardTxnNbr) from CardTxn)'
	)	t
where	LastTxnAge >= @maxAge;

--	send this notice if the result isn't zero
if @result > 0
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @cmd
						,	@Message	= @detail;
end;

/*
————————————————————————————————————————————————————————————————————————————————
	CHECK # 2:
	Collect the age of un-settled transaction since
	the last run.
————————————————————————————————————————————————————————————————————————————————
*/
--	retrieve the number of un-settled items since the last successfull run of this process...
select	@cmd	= 'select @lastRun = LastDate'
				+ ', @lastTxn = LastTime'
				+ ', @items = Items '
				+ 'from openquery(OSI, '
				+ '''select min(ct.LocalTxnDate) as LastDate'
				+ ', cast(min(ct.LocalTxnTime) as int) as LastTime'
				+ ', cast(count(1) as int) as Items '
				+ 'from CardTxn ct '
				+ 'where ResponseCd = ''''00'''' '
				+ 'and IsoTxnCd in (200, 220) '
				+ 'and ProcessTypCd not in (31, 50) '
				+ 'and SettleDate > to_date('''''
				+ convert(char(10), max(StartedOn), 101) + ''''', ''''MM/DD/YYYY'''') '
				+ 'and LocalTxnTime >= '
				+ replace(convert(varchar, max(StartedOn), 8), ':', '') + ' '
				+ 'and not exists (select CardTxnNbr from RtxnAgreement '
				+ 'where CardTxnNbr = ct.CardTxnNbr)'')'
from	tcu.ProcessLog
where	ProcessId	= @ProcessId
and		Result		in (0, @MSG_INFO);

--	execute the command and retrieve the results
exec sp_executesql	@cmd
				,	N'@lastRun datetime output, @lastTxn int output, @items int output'
				,	@lastRun	output
				,	@lastTxn	output
				,	@items		output;
/*
--	this retrieves the missing transactions...
select	*
from	openquery(OSI, '
		select	min(ct.LocalTxnDate)	as LastDate
			,	min(ct.LocalTxnTime)	as LastTime
			,	count(1)				as Items
		from	osiBank.CardTxn		ct
		where	ct.ResponseCd		= ''''00''''
		and		ct.IsoTxnCd			in (200, 220)
		and		ct.ProcessTypCd		not in (31, 50)
		and		ct.SettleDate		> trunc(sysdate)
		and		ct.LocalTxnTime		>= to_number(to_char(sysdate - (15 / 1440), ''''hh24mi'')) * 100
		and	not exists	(	select	CardTxnNbr from osiBank.RtxnAgreement
							where	CardTxnNbr = ct.CardTxnNbr )');
*/
--	send a message if any items haven't posted
if @items > 0
begin
	set	@time	= tcu.fn_LPadC(@lastTxn, 6, '0');
	set	@time	= left(@time, 2) + ':' + substring(@time, 3, 2) + ':' + right(@time, 2);

	--	if there are fewer than 10 transactions then it's a processing issue otherwise it's critical issue...
	select	@detail	=	'Check 2 - '
					+	case
						when @items <= @breakPoint then 'Processing Information'
						else 'CRITICAL WARNING' end
					+	':<br/>There are ' + cast(@items as varchar)
					+	' Card Transactions that have not yet posted to Member accounts since '
					+	convert(char(10), @lastRun, 101) + ' at ' + @time + '.'
		,	@result	=	case
						when @items <= @breakPoint then @MSG_INFO
						else @MSG_WARN end;	--	information vs warning type

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