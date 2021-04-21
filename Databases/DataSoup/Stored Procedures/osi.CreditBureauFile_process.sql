use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[CreditBureauFile_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[CreditBureauFile_process]
GO
setuser N'osi'
GO
CREATE procedure osi.CreditBureauFile_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/14/2008
Purpose  :	Copies the Credit Bureau file from the OSI "online" folder so that it
			may be ziped and/or encrypted and sent to credit reporting agencies.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd		varchar(255)
,	@detail		varchar(4000)
,	@lastRun	datetime
,	@nextFBD	datetime
,	@result		tinyint
,	@sourceFile	varchar(255)
,	@StartedOn	datetime
,	@targetFile	varchar(255)

select	@lastRun	= p.LastRun
	,	@sourceFile	= tcu.fn_OSIFolder()
					+ convert(char(8), dateadd(day, cast(s.UsePriorDay as int) * -1, getdate()), 112)
					+ '\ONLINE\' + f.FileName
	,	@targetFile	= p.FTPFolder + f.FileName
	,	@detail		= ''
	,	@result		= 0
	,	@StartedOn	= getdate()
from	tcu.ProcessSchedule		s
join	tcu.ProcessFile			f
		on	s.ProcessId = f.ProcessId
join	tcu.ProcessParameter_v	p
		on	s.ProcessId = p.ProcessId
where	s.ProcessId		= @ProcessId
and		s.ScheduleId	= @ScheduleId;

--	run if it's been more than an hour since the last run
if datediff(hour, @lastRun, getdate()) > 0
or @lastRun is null
begin
	--	check to see if the file exists and copy it to the target folder if it does
	if tcu.fn_fileExists(@sourceFile) = 1
	begin
		exec @result = tcu.File_action	@action		= 'copy'
									,	@sourceFile	= @sourceFile
									,	@targetFile	= @targetFile
									,	@overWrite	= 1
									,	@output		= @detail output;

		--	report the reuslt of the copy process...
		if @result = 0
		begin
			--	update schedule to run the first week of the next month beginning
			--	on the first business day of next month.
			set	@nextFBD = tcu.fn_FirstBusinessDay(dateadd(month, 1, getdate()));
			update	tcu.ProcessSchedule
			set		BeginOn		= convert(char(10), @nextFBD, 101)
				,	EndOn		= convert(char(10), @nextFBD + 7, 101)
			where	ProcessId	= @ProcessId
			and		ScheduleId	= @ScheduleId;
		end;
		else
		begin
			select	@result	= 3	--	warning
				,	@detail	= 'The procedure ' + db_name() + '.' + object_name(@@procid)
							+ ' was not able to complete moving the file "' + @sourceFile
							+ '" to "' + @targetFile + '" for the reasons listed below.'
							+ @detail;
		end;
	end;
	else
	begin
		select	@result	= 2	--	information
			,	@detail	= 'The procedure ' + db_name() + '.' + object_name(@@procid)
						+ ' was unable to find the source file "' + @sourceFile
						+ '" so that it could be copied to "' + @targetFile + '".';
	end;
end;

--	send out any notifications
if @result != 0 or len(@detail) > 0
begin
	--	log the execution
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= @startedOn
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