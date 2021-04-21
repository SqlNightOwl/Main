use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[EscrowPayoff_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[EscrowPayoff_process]
GO
setuser N'osi'
GO
CREATE procedure osi.EscrowPayoff_process
	@RunId		int	
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/24/2007
Purpose  :	Produces the reconfigured Escrow Payoff Statement from the OSI file
			LN_EAPAY.STM by only including pages where the total of lines is greater
			than zero.
			NOTE:	This will be called from the Process_runOSI so the file will
					already have been verified to exist.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/01/2008	Paul Hunter		Changed to use File_bulkCopy so that the DTS package
							could be eliminated.
03/05/2009	Paul Hunter		Changed the BeginOn date to the 1st/15th and the EndOn
							date to BeginOn + 10
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(500)
,	@detail		varchar(4000)
,	@nextRun	datetime
,	@page		int
,	@range		int
,	@result		int
,	@row		int
,	@sourceFile	varchar(255)
,	@switches	varchar(255)
,	@targetFile	varchar(255)
,	@today		datetime;

--	intialize the variables and retrieve the 
select	@actionCmd	= db_name() + '.osi.EscrowPayoff'
	,	@sourceFile	= l.FileSpec
	,	@targetFile	= p.FTPFolder + l.FileName + '.' + convert(char(10), l.EffectiveOn, 121)
	,	@range		= cast(tcu.fn_ProcessParameter(l.ProcessId, 'Schedule Date Range') as int)
	,	@switches	= '-f"' + tcu.fn_UNCFileSpec(p.SQLFolder + '\' + p.FormatFile ) + '" -T'
	,	@detail		= ''
	,	@page		= 1
	,	@result		= 0
	,	@row		= 0
	,	@today		= convert(char(10), getdate(), 121)
from	tcu.ProcessOSILog_v		l
join	tcu.ProcessParameter_v	p
		on	l.ProcessId = p.ProcessId
where	l.RunId		= @RunId
and		l.ProcessId	= @ProcessId;

--	clear prior data
truncate table osi.EscrowPayoff;

--	load the file using the file from the ProcessOSILog table for this run/process
exec @result = tcu.File_bcp	@action		= 'in'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @sourceFile
						,	@switches	= @switches
						,	@output		= @detail output;

if exists (	select top 1 * from osi.EscrowPayoff )
begin
	--	remove any unwanted records from the table
	delete	osi.EscrowPayoff
	where	ltrim(Record)	like '..%';

	delete	osi.EscrowPayoff
	where	Record like '%For Customer Inquiries Call:%';

	--	update the page numbers for the file
	while exists (	select	top 1 * from osi.EscrowPayoff
					where	Page = 0	)
	begin
		select	top 1
				@row	= Row
		from	osi.EscrowPayoff
		where	record	like '%' + char(12) + '%'
		and		Row		> @row
		order by Row;

		update	osi.EscrowPayoff
		set		Page	=	@page
		where	Row		<=	@row
		and		Page	=	0;

		set	@page = @page + 1;
	end;

	--	there may not be any records to export...
	if exists (	select	top 1 * from osi.EscrowPayoff_vFile )
	begin
		--	build the export command, execute it and capture the results
		select	@actionCmd	= 'select Record from ' + db_name() + '.osi.EscrowPayoff_vFile order by Row'
			,	@switches	= '-c -T';
		exec @result = tcu.File_bcp	@action		= 'queryout'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @targetFile
								,	@switches	= @switches
								,	@output		= @detail output;

		--	report any errors...
		if @result != 0
		begin
			select	@detail	= 'The following error occured while producing the subject report:' + char(13) + char(10)
							+ isnull(@detail, 'No detail returned!')
				,	@result	= 3;	--	warning
		end;
	end;
	else if exists(	select	top 1 * from osi.EscrowPayoff
					where	Record like '%There is no activity for report:%' )
	begin		
		select	@detail	= 'A file was found and loaded but there was no activity for the Escrow Payoff Statement.'
			,	@result	= 0;	--	success
	end;

	if @result = 0	--	a file was found, loaded and nothing went wrong, so adjust the schedule...
	begin
		--	this process should be run on the 2nd and 16th of the month so set the next scheduled run...
		if day(@today) > 14
			set	@nextRun = tcu.fn_FirstDayOfMonth(dateadd(month, 1, @today));	--	1st of next month
		else
			set	@nextRun = dateadd(day, 14, tcu.fn_FirstDayOfMonth(@today));	--	15th of current month

		set @nextRun = convert(char(10), @nextRun, 121);

		--	update the next run dates for the process...
		update	tcu.ProcessSchedule
		set		BeginOn	= @nextRun
			,	EndOn	= dateadd(day, @range, @nextRun)
		where	ProcessId	= @ProcessId;
	end;
end;
else
begin
	select	@detail	= 'The source file "' + @sourceFile
					+ '" either could not be loaded or contained no data.'
		,	@result	= 2;	--	informaiton
end;

if @result != 0 or len(@detail) > 0
begin
	--	send any error notificaitons
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
						,	@Message	= @detail;
end;

--	dump the old data....
truncate table osi.EscrowPayoff;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO