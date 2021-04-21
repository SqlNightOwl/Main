use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[cnsReport_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[cnsReport_process]
GO
setuser N'osi'
GO
CREATE procedure osi.cnsReport_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/31/2008
Purpose  :	Used by the CNS Report production process for bulk loading.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(500)
,	@fileName	varchar(255)
,	@ftpFolder	varchar(255)
,	@detail		varchar(4000)
,	@result		int
,	@rowId		int
,	@separator	varchar(75)
,	@sqlFolder	varchar(255)
,	@sourceFile	varchar(255)
,	@targetFile	varchar(255)

declare	@reports	table
	(	ReportStart	int				not null primary key
	,	ReportEnd	int				not null
	,	ReportName	varchar(255)	not null
	,	Result		int				null
	,	Detail		varchar(4000)	null
	);

select	@fileName	= f.FileName
	,	@ftpFolder	= p.FTPFolder
	,	@sqlFolder	= p.SQLFolder
	,	@rowId		= 0
	,	@separator	= '1                                                                E%'
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	p.ProcessId = @ProcessId;

--	search the folder for the files
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

if not exists (	select	top 1 * from tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileName	not like '%0CD10%'	)
begin
	select	@result		= 3		--	warning
		,	@actionCmd	= 'DIR ' + @sqlFolder + @fileName
		,	@detail		= 'The CNS Reports have not been received today.';
end;
else
begin
	--	remove the old data
	truncate table osi.cnsReport;

	set	@fileName = '';
	--	attempt to load all of the the files that are present
	while exists (	select	top 1 * from tcu.FileLog
					where	ProcessId	= @ProcessId
					and		RunId		= @RunId
					and		FileName	> @fileName	
					and		FileName	not like '%0CD10%'	)
	begin

		select	top 1
				@actionCmd	= db_name() + '.osi.cnsReport_vLoad' 
			,	@fileName	= FileName
			,	@sourceFile	= @SQLFolder + fileName
			,	@targetFile	= @SQLFolder + 'archive\' + fileName
			,	@detail		= ''
		from	tcu.FileLog
		where	ProcessId	= @ProcessId
		and		RunId		= @RunId
		and		FileName	> @fileName	
		and		FileName	not like '%0CD10%';

		--	load the file
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @sourceFile
								,	@switches	= '-c -T'
								,	@output		= @detail output;
		--	report any errors...
		if @result != 0 or len(@detail) > 0
		begin
			set	@result = 3;	--	warning
			goto PROC_EXIT;
		end;

		--	archive the file
		exec @result = tcu.File_action	@action		= 'move'
									,	@sourceFile	= @sourceFile
									,	@targetFile	= @targetFile
									,	@overwrite	= 1
									,	@output		= @detail output;

		if @result != 0 or len(@detail) > 0
		begin
			set	@result = 3;	--	warning
			goto PROC_EXIT;
		end;

	end;

	--	the files are loaded and they can now be separated...
	if exists (	select top 1 * from osi.cnsReport_vLoad )
	begin
		--	collect the start/end rows for each report
		insert	@reports
			(	ReportStart
			,	ReportEnd
			,	ReportName
			)
		select	min(v.PageStart)
			,	max(v.PageEnd)
			,	@ftpFolder + 'RPT' + replace(convert(varchar(8), getdate() -1 , 1), '/', '') + '_' + v.ReportName + '.TXT'
		from(	select	PageStart	= a.RowId
				 	,	PageEnd		= isnull((	select	min(RowId) - 1 from osi.cnsReport
				 								where	Record like @separator
				 								and		RowId	> a.RowId )
											,	(select	max(RowId) from osi.cnsReport))
					,	ReportName	= (	select	rtrim(left(Record, 10)) from osi.cnsReport
										where	RowId = a.RowId + 1)
				from	osi.cnsReport	a
				where	a.Record like @separator
			)	v
		group by v.ReportName;

		--	export all of the files making a single report if the process fails
		while exists (	select	top 1 * from @reports
						where	ReportStart > @rowId	)
		begin

			select	top 1
					@rowId		= ReportStart
				,	@actionCmd	= 'select Record from ' + db_name() + '.osi.cnsReport where RowId between ' 
								+ cast(ReportStart as varchar) + ' and ' + cast(ReportEnd as varchar)
								+ ' order by RowId'
				,	@targetFile	= ReportName
			from	@reports
			where	ReportStart > @rowId
			order by ReportStart;

			exec @result = tcu.File_bcp	@action		= 'queryout'
									,	@actionCmd	= @actionCmd
									,	@actionFile	= @targetFile
									,	@switches	= '-c -T'
									,	@output		= @detail output;

			update	@reports
			set		Result	= @result
				,	Detail	= @detail
			where	ReportStart = @rowId;

		end;

		if exists (	select	top 1 * from @reports
					where	Result != 0	)
		begin
			set	@detail = '';
			select	@detail	= @detail + 'Errors generating the report: ' + ReportName
							+ char(13) + char(10) + Detail + char(13) + char(10)
				,	@result	= 1
			from	@reports
			where	Result != 0;
		end;
	end;
end;

PROC_EXIT:
if @result > 0 or len(@detail) > 0
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
						,	@Message	= @detail;
end;
else
begin
	truncate table osi.cnsReport;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO