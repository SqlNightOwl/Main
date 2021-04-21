use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessSwimDetail_buildSwimFile]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessSwimDetail_buildSwimFile]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessSwimDetail_buildSwimFile
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
,	@overRide	bit			= 0
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/24/2007
Purpose  :	Process for creating the SWIM output file and based on the use of
			Process_runSwM loading data into the ProcessSwimDetail table by
			calling the Process Handler.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
12/06/2007	Paul Hunter		Added the order by clause to the query.
05/21/2009	Paul Hunter		Added "date logic" to the file name.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@actionCmd	nvarchar(255)
,	@actionFile	varchar(255)
,	@CRLF		char(2)
,	@detail		varchar(4000)
,	@fileDate	char(12)
,	@message	varchar(4000)
,	@recipients	varchar(255)
,	@result		smallint
,	@subject	varchar(500)
,	@swimFile	varchar(50)
,	@swimFolder	varchar(255);

set	@CRLF		= char(13) + char(10);
set	@detail		= '';
set	@result		= 0;

--	indicate any overrides
if @overRide = 1
	set	@detail = 'Process override was enabled.' + @CRLF;

--	check to see if there is anything to do...
--	the process may be overridden but there still must be something for the run and process
if exists (	select	top 1 RunId from tcu.ProcessSwimDetail_v
			where	RunId		= @RunId
			and		ProcessId	= @ProcessId
			and	(	IsComplete	= 0
				or	@overRide	= 1	)	)
begin

	select	@fileDate	= '-' + convert(char(10), max(EffectiveOn), 121) + '.'
	from	tcu.ProcessSwimDetail
	where	RunId		= @RunId
	and		ProcessId	= @ProcessId;

	--	create the SWIM file path/name and BCP export command
	select	@actionCmd	=	'select Record from '	+ db_name() + '.tcu.ProcessSwimDetail_v '
						+	'where RunId = '		+ cast(@RunId as varchar)		+ ' '
						+	'and ProcessId = '		+ cast(@ProcessId as varchar)	+ ' '
						+	'and ((IsComplete = 0) or (1 = ' + cast(@overRide as varchar) + ')) '
						+	'order by ProcessSwimDetailId'
		,	@actionFile	=	tcu.fn_SWIMFolder('')
		,	@swimFile	=	case AddDate
							when 0 then isnull(TargetFile, FileName)
							else replace(isnull(TargetFile, FileName), '.', @fileDate)
							end
		,	@swimFolder	= tcu.fn_SWIMFolder('')
	from	tcu.ProcessFile
	where	ProcessId	= @ProcessId
	and		ApplName	= 'SWIM_FILE';

	--	setup the action file variable...
	set	@actionFile = @actionFile + @swimFile;

	--	execute the command and collect the results...
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail	output;

	if @result = 0 and len(@detail) = 0
	begin
		--	indicate that the process is sucessfully completed or...
		update	tcu.ProcessSwimDetail
		set		IsComplete	= 1
		where	RunId		= @RunId
		and		ProcessId	= @ProcessId;

		--	send notification to the Batch Operators...
		select	@detail	= 'The Extended SWIM II File ' + @swimFile + ' for the '
						+ Process + ' Process has been produced and is ready to '
						+ 'be loaded. &nbsp;The file is located in the <a href="'
						+ @swimFolder + '">SWIM folder</a>.'
		from	tcu.Process
		where	ProcessId = @ProcessId;

	end;
	else
	begin
		set	@result = 1;
	end;

	--	Log the execution of this process.
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@result		= @result
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