use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ihb].[BusinessFee_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ihb].[BusinessFee_process]
GO
setuser N'ihb'
GO
CREATE procedure ihb.BusinessFee_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	05/06/2008
Purpose  :	Process for loading the monthly Business Fee file and generating the
			SWIM file.
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
,	@fileName	varchar(50)
,	@sqlFolder	varchar(255)
,	@detail		varchar(4000)
,	@result		smallint

select	@actionCmd	= db_name() + '.ihb.BusinessFee_vLoad'
	,	@actionFile	= p.sqlFolder + f.fileName
	,	@archFile	= p.sqlFolder + 'archive\'
					+ replace(f.fileName, '.', '.' + convert(char(7), getdate(), 121) + '.')
	,	@fileName	= f.fileName
	,	@sqlFolder	= p.sqlFolder
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	see if the file is available...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

if exists (	select	top 1 * from tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId	)
begin
	--	load the file...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '–c –t, -r\n -T'
							,	@output		= @detail output;
	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;
		goto PROC_EXIT;
	end

	update	ihb.BusinessFee
	set		RunId	= @RunId
	where	RunId	= 0;

	--	archive the file...
	exec @result = tcu.File_action	@action		= 'move'
								,	@sourceCmd	= @actionFile
								,	@targetFile	= @archFile
								,	@overWrite	= 1
								,	@output		= @detail output;
	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;
		goto PROC_EXIT;
	end

	--	create the SWIM file
	exec @result = ihb.BusinessFee_savSWIM	@RunId		= @RunId
										,	@ProcessId	= @ProcessId
										,	@ScheduleId	= @ScheduleId;
end;
else
begin
	set	@result	= 3;	--	warning
	set	@detail	= 'An IHB Business Fee source file "' + @fileName
				+ '" was not available in the <a href="' + @sqlFolder + '">SQL Folder</a>.';
end;

PROC_EXIT:
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