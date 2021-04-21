use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranch_export]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ActiveBranch_export]
GO
setuser N'osi'
GO
CREATE procedure osi.ActiveBranch_export
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	11/18/2008
Purpose  :	Exports the Active Branch files.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@period		char(8)
,	@result		int
,	@sqlFolder	varchar(255)

--	initialize the variables
select	@sqlFolder	= SQLFolder
	,	@detail		= ''
	,	@fileName	= ''
	,	@period		= '.' + convert(char(7), dateadd(month, -1, getdate()), 121)
	,	@result		= 0
from	tcu.ProcessParameter_v
where	ProcessId = @ProcessId;

while exists (	select	top 1 FileName from tcu.ProcessFile
				where	ProcessId	= @ProcessId
				and		FileName	> @fileName	)
begin
	--	retrieve the next file...
	select	top 1
			@actionCmd	= 'select * from ' + db_name() + '.' + FileName
		,	@actionFile	= @sqlFolder + TargetFile
		,	@archFile	= @sqlFolder + 'archive\' + TargetFile + @period
		,	@fileName	= FileName
	from	tcu.ProcessFile
	where	ProcessId	= @ProcessId
	and		FileName	> @fileName
	order by FileName;

	--	export the file...
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -t, -T'
							,	@output		= @detail output;
	--	report any errors
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT;
	end;
	else
	begin
		--	archive the files...
		exec @result = tcu.File_action	@action		= 'copy'
									,	@sourceFile	= @actionFile
									,	@targetFile	= @archFile
									,	@overWrite	= 1
									,	@output		= @detail output;
	end;
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