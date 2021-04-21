use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[mdEStatement_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[mdEStatement_process]
GO
setuser N'osi'
GO
CREATE procedure osi.mdEStatement_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/25/2008
Purpose  :	Wrapper procedure to find new MicroDynamics e-Statement files and then
			generate the appropriate OSI update script to add/remove the user field.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/26/2009	Paul Hunter		Changed to run for the current month and handle the
							daily files sent from MicroDynamics.
10/10/2009	Paul Hunter		Changes the process to handle daily runs and generate
							a full sync script from the newest file...
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@fileId		int
,	@fileName	varchar(50)
,	@result		int
,	@sqlFolder	varchar(255)
,	@STAT_FAIL	int
,	@STAT_GOOD	int
,	@STAT_INFO	int
,	@STAT_WARN	int
,	@targetFile	varchar(50)

--	initialize the variables...
select	@fileName	= f.fileName
	,	@targetFile	= f.TargetFile
	,	@sqlFolder	= p.SQLFolder
	,	@detail		= ''
	,	@fileId		= 0
	,	@result		= 0
	,	@STAT_GOOD	= 0
	,	@STAT_FAIL	= 1
	,	@STAT_INFO	= 2
	,	@STAT_WARN	= 3
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	see if any files are there...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	if files were found then load the newest files
if exists (	select	top 1 FileId from tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId	)
begin
	--	clear the old data...
	truncate table osi.mdEStatement;
	truncate table osi.mdEStatementScript;

	--	retrieve the newest file, load it and create a SQL update script...
	select	top 1
			@actionCmd	= db_name() + '.osi.mdEStatement'
		,	@actionFile	= Path + '\' + FileName
	from	tcu.FileLog
	where	RunId		= @RunId
	and		ProcessId	= @ProcessId
	order by FileDate desc;

	--	load the file...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;

	--	no errors, so test and create the SQL update scripts...
	if @result = 0 and len(@detail) = 0
	begin
		--	therer should be at least 25K members...
		if (select count(1) from osi.mdEStatement ) < 25000
		begin
			select	top 1
					@detail	= 'The newest MicroDynamics file "' + value + '" doesn''t appear to contain an appropriate number of member records. '
							+ 'Please check the <a href="' + @sqlFolder + '">source file</a> and contact the appropriate people.'
				,	@result	= @STAT_WARN
			from	tcu.fn_split(@actionFile, '\')
			order by row desc;
		end;
		else
		begin
			--	build the SQL update scripts...
			insert	osi.mdEStatementScript
				(	Script	)
			select	Script
			from	osi.mdEStatement_vScript;

			--	produce the SQL update script if there are changes...
			if exists (	select top 1 ScriptId from osi.mdEStatementScript )
			begin
				--	create the appropriate output actions...
				select	@actionCmd	= 'select Script from ' + db_name() + '.osi.mdEStatementScript'
					,	@actionFile	= @sqlFolder + @targetFile;

				exec @result = tcu.File_bcp	@action		= 'queryout'
										,	@actionCmd	= @actionCmd
										,	@actionFile	= @actionFile
										,	@switches	= '-c -T'
										,	@output		= @detail output;

				--	build info message...
				if @result = 0 and len(@detail) = 0
				begin
					--	build the "success" info message...
					select	@detail	= 'The subject process sucessfully ran and an OSI update script "'
									+ @targetFile + '" is available in the <a href="' + @sqlFolder
									+ '">SQL Files OSI MicroDynamics</a> folder.  Please validate that the '
									+ 'files contents are within expected boundaries and, if acceptable, execute '
									+ 'against the production OSI database to maintain the e-Statement user field.'
						,	@result	= @STAT_GOOD;
				end;
			end;		--	build SQL update script file...
			else		--	file received but no changes...
			begin
				--	there are no update to be made to OSI so report that...
				select	@detail	= 'The MicroDynamics file received contained no new information.'
					,	@result	= @STAT_INFO;
			end;

			--	delete all files AFTER it's safe to do so....
			while exists (	select	top 1 FileId from tcu.FileLog
							where	ProcessId	= @ProcessId
							and		RunId		= @RunId
							and		FileId		> @fileId	)
			begin
				--	retrieve the next file...
				select	top 1
						@actionFile	= Path  + '\' + FileName
					,	@fileId		= FileId
				from	tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileId		> @fileId
				order by FileId

				--	delete the file...
				exec tcu.File_action	@action		= 'erase'
									,	@sourceFile	= @actionFile
									,	@targetFile	= null
									,	@overWrite	= 0;
			end;
		end;
	end;
	else	--	report any errors...
	begin
		set	@result = @STAT_FAIL;
	end;
end;	--	have file(s)
else	--	no file(s)
begin
	select	@detail	= 'No MicroDynamics files could not be found.'
		,	@result	= @STAT_INFO;
end;

PROC_EXIT:
if len(@detail) > 0 or @result > 0
begin
	--	the process failed or a message was generated.
	exec tcu.Processlog_sav	@RunId		= @RunId
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