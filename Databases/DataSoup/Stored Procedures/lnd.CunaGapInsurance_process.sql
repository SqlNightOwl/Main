use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[CunaGapInsurance_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[CunaGapInsurance_process]
GO
setuser N'lnd'
GO
CREATE procedure lnd.CunaGapInsurance_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/23/2009
Purpose  :	Exports loans for which CUNA Gap Insurance has been purchased.  This
			assumes that the process is run on the 1st/16th and coordinates with
			the source view (lnd.CunaGapInsurance_v) that pulls data from both
			StreamLend and OSI.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

--	turn off ansi_warnings...
exec sp_executesql N'set ansi_warnings off;'

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@nextRun	datetime
,	@result		int

--	initialize the variables...
select	@actionCmd	=	db_name() + '.lnd.CunaGapInsurance_v'
	,	@actionFile	=	p.FTPFolder
					+	replace(
						replace(f.FileName
								, '[DATE]', convert(char(8), getdate(), 112))
								, '[TIME]', replace(convert(varchar(5), getdate() ,8), ':', ''))
	,	@detail		=	''
	,	@result		=	0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	p.ProcessId	= @ProcessId;

--	export the CUNA file...
exec @result = tcu.File_bcp	@action		= 'out'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= '-c -t, -T'
						,	@output		= @detail out;

--	archive the file if no errors occured...
if @result = 0 and len(@detail) = 0
begin
	exec @result = tcu.File_archive	@Action			= 'copy'
								,	@SourceFile		= @actionFile
								,	@ArchiveDate	= null
								,	@Detail			= @detail out
								,	@AddDate		= 0
								,	@OverWrite		= 1;
end;

--	adjust the schedule to the next date (15th/EOM) if successful...
if @result = 0 and len(@detail) = 0
begin
	--	it's supposed to run on the 1st and 16th...
	set	@nextRun =	case
					when day(getdate()) > 15 then tcu.fn_LastDayOfMonth(null) + 1	--	move to the 1st
					else tcu.fn_FirstDayOfMonth(null) + 15 end;						--	move to the 16th

	update	tcu.ProcessSchedule
	set		BeginOn	= @nextRun
		,	EndOn	= @nextRun
	where	ProcessId	= @ProcessId
	and		ScheduleId	= @ScheduleId;
end;
else	--	log the failure...
begin
	set	@result = 1;	--	failure...
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
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