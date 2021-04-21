use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[tf_AccountExtract_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[tf_AccountExtract_process]
GO
setuser N'osi'
GO
CREATE procedure osi.tf_AccountExtract_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/10/2008
Purpose  :	Extracts data files which are sent to Texans Financial.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;
set ansi_warnings off;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@period		char(7)
,	@result		int
,	@retention	int
,	@sqlFolder	varchar(255);

--	initialize the parameters...
select	@sqlFolder	= SQLFolder
	,	@retention	= RetentionPeriod * -1
	,	@fileName	= ''
	,	@detail		= ''
	,	@period		= convert(char(7), dateadd(month, -1, getdate()), 121)
	,	@result		= 0
from	tcu.ProcessParameter_v
where	ProcessId = @ProcessId;

while exists (	select	FileName from tcu.ProcessFile
				where	ProcessId	= @ProcessId
				and		FileName	> @fileName	)
begin
	select	top 1
			@actionCmd	= db_name()	+ '.' + FileName
		,	@actionFile	= @sqlFolder + replace(TargetFile, '[DATE]', @period)
		,	@archFile	= @sqlFolder + 'archive\' + replace(TargetFile, '[DATE]', @period)
		,	@fileName	= FileName
	from	tcu.ProcessFile
	where	ProcessId	= @ProcessId
	and		FileName	> @fileName
	order by FileName;

	--	export the file.
	exec @result = tcu.File_bcp	@action		= 'out'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -t, -T'
							,	@output		= @detail output;


	if @result = 0 and len(@detail) = 0
	begin
		--	archive the files...
		exec @result = tcu.File_action	@action		= 'copy'
									,	@sourceFile	= @actionFile
									,	@targetFile	= @archFile
									,	@overWrite	= 1
									,	@output		= @detail output;

		if @result != 0 or len(@detail) > 0
		begin
			set	@result = 3;	--	warning
			break;
		end;
	end;
	else	--	report any errors and break out of the loop...
	begin
		set	@result = 3;	--	warning
		break;
	end;

end;

--	report any errors...
if @result = 0 and len(@detail) = 0
begin
	--	set the success message...	
	select	@detail	= '<p>The monthly Texans Financial extracts for '
					+ datename(month, dt.LastMonth) + ' ' + cast(year(dt.LastMonth) as varchar)
					+ ' have completed and may be retrieved from the <a href="'+ @sqlFolder
					+ '">Texans Financial</a> folder.</p>'
		,	@result	= 0
	from	( select LastMonth = dateadd(month, -1, getdate()) ) dt;
end;

--	record the results...
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

--	dump old data...
delete	tcu.ProcessLog
where	ProcessId	= @ProcessId
and		ScheduleId	= @ScheduleId
and		StartedOn	< dateadd(day, @retention, getdate())

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO