use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[SingleServiceFeeClosing_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[SingleServiceFeeClosing_process]
GO
setuser N'osi'
GO
CREATE procedure osi.SingleServiceFeeClosing_process
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
Purpose  :	Load the final account closing list, produces the OSI Closing scripts
			and sends a notification message for the Single Service Fee account
			closing process.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@period		varchar(10)
,	@result		int
,	@sqlFolder	varchar(255)

--	collect the source information
select	@actionCmd	= db_name() + '.' + f.FileName
	,	@actionFile	= p.SQLFolder + f.TargetFile
	,	@archFile	= p.SQLFolder + 'archive\' + f.TargetFile
	,	@period		= '_' + convert(char(7), dateadd(month, -1, getdate()), 121) + '.'
	,	@fileName	= f.TargetFile
	,	@sqlFolder	= p.SQLFolder
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId	= p.ProcessId
where	f.ProcessId = @ProcessId
and		f.ApplName	= 'Source';

--	check to see if there is a file to load...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	if there is a file then load and process...
if exists (	select	* from tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId	)
begin
	--	load the file...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;

	--	no errors...
	if @result = 0 and len(@detail) = 0
	begin
		--	archive the file...
		set	@archFile = replace(@archFile, '.', @period);
		exec @result = tcu.File_action	@action		= 'move'
									,	@sourceFile	= @actionFile
									,	@targetFile	= @archFile
									,	@overWrite	= 1
									,	@output		= @detail output;

		--	no errors...
		if @result = 0 and len(@detail) = 0
		begin
			--	collect the target script parameters
			select	@actionCmd	= 'select Script from ' + db_name() + '.' + f.FileName + ' '
								+ 'where CloseOn = ''' + convert(char(10), getdate(), 121) + ''' '
								+ 'order by ScriptType, AccountNumber'
				,	@actionFile	= p.SQLFolder
								+ replace(f.TargetFile, '.', @period)
				,	@fileName	= replace(f.TargetFile, '.', @period)
			from	tcu.ProcessFile			f
			join	tcu.ProcessParameter_v	p
					on	f.ProcessId	= p.ProcessId
			where	f.ProcessId = @ProcessId
			and		f.ApplName	= 'Target';

			--	export the script file...
			exec @result = tcu.File_bcp	@action		= 'queryout'
									,	@actionCmd	= @actionCmd
									,	@actionFile	= @actionFile
									,	@switches	= '-c -T'
									,	@output		= @detail output;

			--	no errors...
			if @result = 0 and len(@detail) = 0
			begin
				--	build the success message...
				set	@detail	= 'An OSI SQL script for the Single Service Fee closing allotment '
							+ 'named <a href="' + @SQLFolder + '">' + @fileName + '</a> '
							+ 'has been created and is ready to be executed in production OSI.';
			end;
			else
			begin
				--	report errors from exporting the script file...
				set	@result = 1;	--	failure
				goto PROC_EXIT;
			end;
		end;
		else
		begin
			--	report errors from archiving the source file...
			set	@result = 1;	--	failure
			goto PROC_EXIT;
		end;
	end;
	else	--	report errors from loading the closing list file...
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT;
	end;
end;

PROC_EXIT:
if @result != 0 or len(@detail) > 0
begin
	--	report the results...
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