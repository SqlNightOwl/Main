use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessQue_check]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessQue_check]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessQue_check
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/01/2009
Purpose  :	Checks on the progress of the Texans Process and sends an email if
			they appear to be hung.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/07/2010	Paul Hunter		Added the check on the number of minutes since the
							last time the Processes were scheduled.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@body		varchar(max)
,	@lastRun	datetime
,	@minutes	int
,	@recipients	varchar(255)
,	@return		int
,	@runOn		varchar(30)
,	@subject	varchar(125)

declare	@warnings	table
	(	ProcessQueId	int			primary key
	,	ProcessSchedule	varchar(10)	not null
	,	Process			varchar(50)	not null
	,	StartedOn		varchar(16)	not null
	,	Warnings		tinyint		not null
	,	RunOn			varchar(30)	not null
	);

--	initialize the variables...
select	@return		= 0
	,	@subject	= 'TOM:0-W - Texans Processes ';

--	retrieve the last run time and calculate the number of minutes since the last run...
select	@lastRun = cast(tcu.fn_Dictionary('Process','Last Run Time') as datetime)
	,	@minutes = datediff(minute, @lastRun, getdate());

--	PART 1:	send warning if it's been over 15 minutes since last scheduled run...
if @minutes > 14
begin
	--	initialize the message and recipients...
	select	@body		= 'It has been ' + cast(@minutes as varchar(10))
						+ ' minutes since the last run of Texans Processes were scheduled.<br/>'
						+ 'The Processes below were scheduled to run at ' + convert(char(5), @lastRun, 14)
						+ ' and have not yet completed.<ol>'
		,	@recipients	= tcu.fn_Dictionary('Process', 'Process Monitoring Notification')
		,	@subject	= @subject + 'Scheduling Notification';

	--	add the list of processes
	select	@body	=	@body
					+	'<li>' + case when StartedOn is not null then '<b>' else '' end
					+	cast(ProcessId as varchar(5)) + '&nbsp; - ' + Process
					+	case
						when StartedOn is null then ' - (waiting)'
						else ' - (running)</b>'
						end + '</li>'
	from	tcu.ProcessQue
	where	RunId = (select min(RunId) from tcu.ProcessQue where IsManualRun = 0 and StartedOn is null)
	order by ProcessQueId;

	--	add the closing html tag...
	set	@body = @body + '</ol>';

	--	send the email...
	exec tcu.Email_send	@subject	= @subject
					,	@message	= @body
					,	@sendTo		= @recipients
					,	@asHtml		= 1;

	--	reset the body variable...
	set	@body = null;
end;

--	PART 2:	send a warning if there is and overly long running Process...
if exists ( select	top 1 ProcessQueId from tcu.ProcessQue )
begin
	--	collect any processes where warnings need to be issued...
	insert	@warnings
	select	q.ProcessQueId
		,	cast(q.ProcessId as varchar(10)) + '.' + cast(q.ScheduleId as varchar(10))
		,	q.Process
		,	convert(varchar(16), q.StartedOn, 20)
		,	isnull(q.Warnings, 0) + 1
		,	convert(varchar(30), RunOn, 0)
	from	tcu.ProcessQue		q
	join	tcu.ProcessSchedule	s
			on	q.ProcessId	 = s.ProcessId
			and	q.ScheduleId = s.ScheduleId
	where	q.StartedOn		is not null
	and		q.Warnings		< 16
	--	the current run time is less than the median + 2 standard deviations (96% of all runs)
	and		datediff(second, q.StartedOn, getdate()) > (s.RunTimeMedian + (s.RunTimeStdDev * 2)) * 60;

	--	send warnings and update the ProcessQue table...
	if @@rowcount > 0
	begin
		--	update the number of warnings issued...
		update	q
		set		Warnings  = case q.Warnings
							when 255 then 255	--	max number
							else q.Warnings + 1
							end
		from	tcu.ProcessQue	q
		join	@warnings		w
				on	q.ProcessQueId = w.ProcessQueId;

		--	update the warnings to count the number of warnings issued (every 5th cycle)...
		update	@warnings
		set		Warnings =	case Warnings % 5
							when 1 then (Warnings / 5) + 1
							else 0 end;

		--	collect the Run On date and initialiaxe a few other variables...
		select	top 1
				@runOn		= convert(varchar(30), RunOn, 0)
			,	@recipients	= tcu.fn_Dictionary('All Applications', 'Process Operations email')
			,	@subject	= @subject + 'Check'
		from	@warnings;

		--	build a message for everything that's "stalled" in the queue...
		select	@body	= isnull(@body, '')
						+	'<tr>'
						+	'<td class="r">' + ProcessSchedule			+ '&nbsp;</td>'
						+	'<td>'			 + Process					+ '</td>'
						+	'<td class="c">' + StartedOn				+ '</td>'
						+	'<td class="c">' + cast(Warnings as char(3))+ '</td>'
						+	'</tr>'
		from	@warnings
		where	Warnings > 0;

		--	add the rest of the message body...
		set	@body	=	'<html><head><style type="text/css">'
					+	'p,td{font:10pt tahoma;} '
					+	'th{font:italic bold 10pt tahoma;} '
					+	'table{border:0px;width:800px;} '
					+	'.c{padding:2px;text-align:center;}'
					+	'.r{padding:2px;text-align:right;}'
					+	'</style></head><body>'
					+	'<p>The Texans Processes scheduled for the Run on ' + @runOn
					+	' have exceeded their normal run time by a significant amount of time. &nbsp;'
					+	'Please review the Texans Processes listed below to determine if corrective '
					+	'actions needs to be taken.</p>'
					+	'<center><table><tr>'
						+ '<th>Process</th>'
						+ '<th>Name</th>'
						+ '<th>Started On</th>'
						+ '<th>Warnings</th>'
					+	'</tr>' + @body + '</table><center></body></html>';

		exec tcu.Email_send	@subject	= @subject
						,	@message	= @body
						,	@sendTo		= @recipients
						,	@asHtml		= 1;

		--	set the return value to anything other than zero...
		set @return = 1;
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