use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Statement_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[Statement_process]
GO
setuser N'osi'
GO
CREATE procedure osi.Statement_process
	@RunId			int
,	@ProcessId		smallint
,	@ScheduleId		tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huner
Created  :	02/01/2008
Purpose  :	Loads the Monthly statement files, creates report for the number of
			pages and statements loaded and exports consolidated reports.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/29/2008	Paul Hunter		Added logic for aggregating and handling quarterly
							statements.
06/09/2008	Paul Hunter		Added logic to produce both EOM and EOQ files even
							for non-quarter ending months.
10/02/2009	Paul Hunter		Changed from an OSI File process to an PRC Integraiton
							process to accomodate times when statements finish on
							a day other than the 1st.  Added second schedule with
							hard coded logic to handle non-first day processing.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@cmd		nvarchar(500)
,	@CRLF		char(2)
,	@detail		varchar(4000)
,	@extension	char(3)
,	@fileName	varchar(50)
,	@ftpFolder	varchar(255)
,	@indexId	int
,	@now		datetime
,	@osiFolder	varchar(255)
,	@period		int
,	@queNbr		int
,	@result		int
,	@switches	varchar(255)
,	@tableId	int
,	@type		char(3)
,	@TYPE_EOM	char(3)
,	@TYPE_EOQ	char(3)
,	@user		varchar(25)

declare	@fileInfo	table
	(	QueNbr		int				not null primary key
	,	Type		char(3)			not null
	,	EffectiveOn	datetime		not null
	,	ApplName	nvarchar(60)	not null
	,	DailyOffset	char(8)			not null
	,	FileName	varchar(50)		not null
	,	BeginOn		datetime		not null
	,	EndOn		datetime		not null
	,	FileDate	datetime		not null default (0)
	,	FileSize	int				not null default (0)
	,	FileCount	int				not null default (0)
	,	Statements	int				not null default (0)
	,	Pages		int				not null default (0)
	);

--	collect/initialize some processing variables...
select	@actionCmd	= db_name() + '.osi.Statement'
	,	@ftpFolder	= p.FTPFolder
	,	@fileName	= rtrim(f.FileName)
	,	@extension	= right(rtrim(f.FileName), 3)
	,	@switches	= '-b100000 -c -f"' + tcu.fn_UNCFileSpec(p.SQLFolder + p.FormatFile) + '" -h"TABLOCK" -T'
	,	@indexId	= cast(tcu.fn_ProcessParameter(f.ProcessId, 'Indexing Process Id') as int)
	,	@CRLF		= char(13) + char(10)
	,	@detail		= ''
	,	@now		= getdate()
	,	@osiFolder	= tcu.fn_OSIFolder()
	,	@queNbr		= 0
	,	@result		= 0
	,	@tableId	= object_id(N'osi.Statement')
	,	@TYPE_EOM	= 'EOM'
	,	@TYPE_EOQ	= 'EOQ'
	,	@user		= tcu.fn_UserAudit()
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	collect the processing status from OSI...
insert	@fileInfo
	(	QueNbr
	,	Type
	,	EffectiveOn
	,	ApplName
	,	DailyOffset
	,	FileName
	,	BeginOn
	,	EndOn
	,	FileCount
	)
select	QueNbr
	,	case charindex(@TYPE_EOQ, QueDesc) when 0 then @TYPE_EOM else @TYPE_EOQ end
	,	EffDate
	,	ApplName
	,	DailyOffset
	,	@fileName
	,	StartDateTime
	,	isnull(CompleteDateTime, 0)
	,	row_number() over (order by QueNbr)
from	openquery(OSI, '
		select	QueNbr
			,	QueDesc
			,	EffDate
			,	ApplName
			,	DailyOffset
			,	StartDateTime
			,	CompleteDateTime
		from	texans.ops_ApplicationStatus_vw
		where	EffDate		= last_day(add_months(trunc(sysdate), -1))
		and		ApplName	= ''MM_STMNT''
		and		DailyOffset	= to_char(last_day(add_months(trunc(sysdate), -1)), ''YYYYMMDD'')
		and		ErrorCount	= 0');

--	proceed if there are exactly two files available, otherwise raise the alert...
if (select	count(QueNbr) from @fileInfo
	where	EndOn > 0	) = 2
begin
	--	get the rest of the file details...
	while exists (	select	top 1 QueNbr from @fileInfo
					where	QueNbr > @queNbr	)
	begin
		select	top 1
				@actionFile = @osiFolder + DailyOffset + '\' + cast(QueNbr as varchar) + '\'
			,	@queNbr		= QueNbr
		from	@fileInfo
		where	QueNbr		> @queNbr
		order by QueNbr;

		--	get the file details...
		exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
								,	@RunId				= @RunId
								,	@uncFolder			= @actionFile
								,	@fileMask			= @fileName
								,	@includeSubFolders	= 0;

		--	...and update @fileInfo...
		update	i
		set		FileDate = f.FileDate
			,	FileSize = f.FileSize
		from	@fileInfo		i
		join	tcu.FileLog		f
				on	cast(i.QueNbr as varchar) = f.SubFolder
		where	f.RunId		= @RunId
		and		f.ProcessId	= @ProcessId;

		--	no need to keep this
		delete	tcu.FileLog
		where	RunId		= @RunId
		and		ProcessId	= @ProcessId;
	end;

	--	drop the indexes before loading (improves load performance)...
	if exists ( select * from sys.indexes where object_id = @tableId and name = N'IX_QueueId' )
		drop index IX_QueueId on osi.Statement;
	if exists ( select * from sys.indexes where object_id = @tableId and name = N'IX_TypeQueueIdRecordId' )
		drop index IX_TypeQueueIdRecordId on osi.Statement;
	if exists (select name from sys.indexes where object_id = @tableId and name = N'IX_Account')
		drop index IX_Account on osi.Statement;
	if exists (select name from sys.indexes where object_id = @tableId and name = N'IX_Member')
		drop index IX_Member on osi.Statement;

	--	make sure the defaults exist...
	if not exists ( select * from sys.objects where parent_object_id = @tableId and name = N'DF_Statement_QueueId' )
		alter table osi.Statement add  constraint DF_Statement_QueueId default ((0)) for QueueId;
	if not exists ( select * from sys.objects where parent_object_id = @tableId and name = N'DF_Statement_Type' )
		alter table osi.Statement add  constraint DF_Statement_Type default ('EOM') for Type;

	--	clear the table and rebuild the indexes before loading...
	truncate table osi.Statement;
	alter index all on osi.Statement rebuild;

	--	add a "dummny" EOQ record at quarter end so a file can be generated for non-EOQ months...
	if not exists ( select	* from @fileInfo
					where	Type = @TYPE_EOQ	)
	begin
		insert	@fileInfo
			(	QueNbr
			,	Type
			,	EffectiveOn
			,	ApplName
			,	DailyOffset
			,	FileName
			,	BeginOn
			,	EndOn
			)
		select	top 1
				-1
			,	@TYPE_EOQ
			,	EffectiveOn
			,	ApplName
			,	DailyOffset
			,	FileName
			,	@now
			,	@now
		from	@fileInfo;
	end;

	--	re-initialize the que number and bind the view to the procedure for dependency checking
	set	@queNbr = 0;

	--	loop thru the files and load each...
	while exists (	select	top 1 * from @fileInfo
					where	QueNbr	> @queNbr	)
	begin
		--	get the next que number and path to the folder
		select	top 1
				@actionFile	= @osiFolder + DailyOffset + '\' + cast(QueNbr as varchar) + '\' + @fileName
			,	@type		= Type
			,	@queNbr		= QueNbr
			,	@period		= cast(convert(char(6), EffectiveOn, 112) as int)
		from	@fileInfo
		where	QueNbr		> @queNbr
		order by QueNbr;

		--	rebuild the defaults for the current que & statement type...
		alter table osi.Statement drop constraint DF_Statement_Type;
		alter table osi.Statement drop constraint DF_Statement_QueueId;
		set	@cmd	= 'alter table osi.Statement add constraint DF_Statement_Type	 default (''' + @type + ''') for Type; '
					+ 'alter table osi.Statement add constraint DF_Statement_QueueId default ((' + cast(@queNbr as varchar) + ')) for QueueId;'
		exec sp_executesql @cmd;

		--	import the file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail output;

		--	report any errors...
		if @result != 0 or len(@detail) > 0
		begin
			select	@result	= 1	--	failure
				,	@detail	= 'There was an error loading the OSI Monthly Statement file ' + @actionFile
							+ ' using "' + db_name() + '.' + object_name(@@procid) +'".' + @CRLF
							+ @detail;
			goto PROC_EXIT;
		end;
	end;	--	while loop for loading files...

	--	export the statement files...
	if @result = 0 and len(@detail) = 0
	begin
		--	rebuild the indexes...
		create nonclustered index IX_QueueId			 on osi.Statement (	QueueId	);
		create nonclustered index IX_TypeQueueIdRecordId on osi.Statement (	Type, QueueId, RecordId	);

		--	export files by statement type...
		set	@type = '';
		while exists (	select	top 1 * from @fileInfo
						where	Type > @type )
		begin
			--	build the command...
			select	top 1
					@type		= i.Type
				,	@actionCmd	= 'select Record from ' + db_name() + '.osi.Statement '
								+ 'where Type = ''' + i.Type + ''' order by RecordId'
				,	@actionFile	= @ftpFolder + replace(@fileName, @extension, Type)
				,	@switches	= '-c -T'
			from	@fileInfo	i
			where	i.Type > @type
			order by i.Type;

			--	export the data...
			exec @result = tcu.File_bcp	@action		= 'queryout'
									,	@actionCmd	= @actionCmd
									,	@actionFile	= @actionFile
									,	@switches	= @switches
									,	@output		= @detail output;

			--	report any errors...
			if @result != 0 or len(@detail) > 0
			begin
				select	@result	= 1	--	failure
					,	@detail	= 'There was an error exporting the OSI Monthly Statement file '
								+ @actionFile + ' using "' + db_name() + '.' 
								+ object_name(@@procid) + '".' + @CRLF + @detail;
				goto PROC_EXIT;
			end;
		end;	--	loop thru the statement files...

		--	record the results and send the summary message...
		if @result = 0 and len(@detail) = 0
		begin
			--	record the Process info
			insert	tcu.ProcessOSILog
				(	RunId
				,	ProcessId
				,	EffectiveOn
				,	ApplName
				,	DailyOffset
				,	QueNbr
				,	FileName
				,	CompletedOn
				,	FileDate
				,	FileSize
				,	FileCount
				,	CreatedBy
				,	CreatedOn
				)
			select	@RunId
				,	@ProcessId
				,	EffectiveOn
				,	ApplName
				,	DailyOffset
				,	QueNbr
				,	FileName
				,	EndOn
				,	FileDate
				,	FileSize
				,	FileCount
				,	@user	-- CreatedBy
				,	@now	-- CreatedOn
			from	@fileInfo
			where	QueNbr > 0;

			--	record the execution stats for this period...
			insert	osi.StatementLog
				(	Period
				,	Type
				,	QueueId
				,	Statements
				,	Pages
				,	FileSize
				,	BeginOn
				,	EndOn
				)
			select	cast(left(i.DailyOffset, 6) as int)
				,	i.Type
				,	i.QueNbr
				,	s.Statements
				,	s.Pages
				,	i.FileSize
				,	i.BeginOn
				,	i.EndOn
			from	@fileInfo			i
			join(	--	count the statements and pages...
					select	a.QueueId
						,	Statements	= sum(a.Account)
						,	Pages		= max(p.Pages)
					from(	--	collect unique accounts...
							select	QueueId, 1 as Account
							from	osi.Statement
							where	Record like '%Number%:%'
							group by QueueId, Record
						)	a
					join(	--	count pages...
							select	QueueId, count(RecordId) as Pages
							from	osi.Statement
							where	Record like '%Page:%'
							group by QueueId
						)	p	on	a.QueueId = p.QueueId
					group by a.QueueId
				)	s	on	i.QueNbr = s.QueueId
			left join
					osi.StatementLog	l
					on	i.QueNbr = l.QueueId
			where	i.QueNbr	> 0		--	exclude any "fake" records
			and		l.QueueId	is null
			order by i.Type, i.QueNbr;

			--	adjust schedule #2 to start the second day of the next month...
			update	tcu.ProcessSchedule
			set		BeginOn		= tcu.fn_FirstDayOfMonth(dateadd(month, 1, @now)) + 1
				,	EndOn		= tcu.fn_LastDayOfMonth(dateadd(month, 1, @now))
				,	UpdatedBy	= @user
				,	UpdatedOn	= @now
			where	ProcessId	= @ProcessId
			and		ScheduleId	= 2;

			--	enabled the statement indexing process...
			update	tcu.Process
			set		IsEnabled	= 1
				,	UpdatedBy	= @user
				,	UpdatedOn	= @now
			where	ProcessId	= @indexId;

			--	report the stats for the TechOps...
			select	@detail	= @detail
							+ '<tr><td align="center">' + Type
							+ '</td><td align="center">'+ cast(QueueId		as varchar(10))
							+ '</td><td align="right">' + cast(Statements	as varchar(10))
							+ '</td><td align="right">' + cast(Pages		as varchar(10))
							+ '</td><td align="right">' + cast(FileSize		as varchar(10))
							+ '</td></tr>'
			from	osi.StatementLog
			where	Period = @period
			order by QueueId;

			--	add a total row...
			select	@detail	= @detail
							+ '<tr><td colspan="2" align="center">Totals'
							+ '</td><td align="right">' + cast(sum(Statements)	as varchar(10))
							+ '</td><td align="right">' + cast(sum(Pages)		as varchar(10))
							+ '</td><td align="right">' + cast(sum(FileSize)	as varchar(10))
							+ '</td></tr>'
			from	osi.StatementLog
			where	Period = @period;

			--	build out the rest of the table.
			set	@detail	= '<p>The monthly statement file(s) have been produced '
						+ 'and may be found in the ' + '<a href="' + @ftpFolder
						+ '">MicroDynamics</a> FTP folder.</p>'
						+ '<table width="80%"><tr valign="middle">'
						+ '<td align="center" width="10%">Type</td>'
						+ '<td align="center" width="10%">Queue</td>'
						+ '<td align="center" width="25%">Statements</td>'
						+ '<td align="center" width="25%">Pages</td>'
						+ '<td align="center" width="30%">File Size</td>'
						+ '</tr>' + @detail + '</table>';
		end;	--	summarizing, recording and producing the result message...
	end;		--	producing the statement files...
end;	--	exactly 2 files were available
else	--	exactly 2 files were not available...
begin
	select	@detail =	'Not all of the OSI Applications have completed generating files for the process Monthly Statements Consolidation".<br/>'
					+	'If you believe that the applications have completed then there may be another issue that needs to be resolved.'
		,	@result	=	case
						when datepart(minute, @now) > 15 then 1	--	failure
						else 2 end;								--	information at the top of the hour...
end;

PROC_EXIT:
--	if there is a message then send out the notifications...
if @result != 0 or len(@detail) > 0
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= @now
						,	@Result		= @result
						,	@Command	= ''
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