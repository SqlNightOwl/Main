use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[StatementHighRateChecking_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[StatementHighRateChecking_process]
GO
setuser N'osi'
GO
CREATE procedure osi.StatementHighRateChecking_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/23/2008
Purpose  :	Process to export the High Rate Checking message for the MicroDynamics
			statements.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@ftpFolder	varchar(255)
,	@result		int

--	this runs the first day of the month...
if day(tcu.fn_OSIPostDate()) = 1
begin
	--	initialize the variables
	select	@actionCmd	= 'select Record from ' + db_name() + '.' + f.FileName
						+ ' order by RowId'
		,	@actionFile	= p.FTPFolder + f.TargetFile
		,	@fileName	= f.TargetFile
		,	@ftpFolder	= p.FTPFolder
		,	@detail		= ''
		,	@result		= 0
	from	tcu.ProcessFile			f
	join	tcu.ProcessParameter_v	p
			on	f.ProcessId = p.ProcessId
	where	f.ProcessId	= @ProcessId;

	--	build the message...
	exec osi.Statement_getHighRateCheckingMsg @ProcessId;

	--	export the file...
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;

	if @result = 0 and len(@detail) = 0
	begin
		set	@detail = 'The subject file has been produced and is available as '
					+ '<a href="' + @ftpFolder + '">' + @fileName + '</a>';
	end;
	else
	begin
		--	report any errors
		set	@result = 1;	--	failure
	end;
end;
else
begin
	select	@result		= 2	--	information
		,	@actionCmd	= 'day(tcu.fn_OSIPostDate()) != 1'
		,	@detail		= 'The OSI Post Date has not been advanced to the 1st.';
end;

--	report any errors...
if @result != 0 or len(@detail) > 0
begin
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