use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[NoticeConsolidation_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[NoticeConsolidation_process]
GO
setuser N'osi'
GO
CREATE procedure osi.NoticeConsolidation_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/15/2008
Purpose  :	Consolidates the Notices from OSI and splits the results into separate
			files for each "line-of-business".  The majority of the Notices are
			sent to MicroDynamics.  Other departments receive the files with the 
			following extension:
			CML	- Commercial Loans
			SBL	- Small Business Loans
			MTG	- Mortgage Loans
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@address	varchar(255)
,	@applName	nvarchar(60)
,	@archDate	char(11)
,	@detail		varchar(4000)
,	@exportFile	varchar(50)
,	@extension	varchar(4)
,	@FF			char(1)
,	@fileName	varchar(255)
,	@ftpFolder	varchar(255)
,	@page		int
,	@reportType	varchar(3)
,	@result		int
,	@row		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)
,	@targetFile	varchar(255)

--	initialize the variables...
select	top 1
		@actionCmd	= db_name() + '.osi.Notice'
	,	@ftpFolder	= p.FTPFolder
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= '-f"' + tcu.fn_UNCFileSpec(p.SQLFolder + '\' + p.FormatFile ) + '" -T'
	,	@exportFile	= f.TargetFile
	,	@address	= ' Texans Credit Union| 777 E. Campbell Road| Richardson  TX  75081'
	,	@detail		= ''
	,	@FF			= char(12)	-- form feed character
	,	@page		= 1
	,	@reportType	= ''
	,	@result		= 0
	,	@row		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	clear the table for the new notices
truncate table osi.Notice;
alter index all on osi.Notice rebuild;

--	load all of the files...
while exists (	select	top 1 ProcessOSILogId
				from	tcu.ProcessOSILog
				where	ProcessOSILogId	> @row
				and		RunId			= @RunId
				and		ProcessId		= @ProcessId )
begin
	--	retrive the next file...
	select	top 1
			@actionFile	= FileSpec
		,	@applName	= ApplName
		,	@archDate	= '.' + convert(char(10), EffectiveOn, 112)
		,	@fileName	= FileName
		,	@row		= ProcessOSILogId
	from	tcu.ProcessOSILog_v
	where	ProcessOSILogId	> @row
	and		RunId			= @RunId
	and		ProcessId		= @ProcessId
	order by ProcessOSILogId;

	--	load the file...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail output;

	--	handle any post load conditions
	if @result != 0 or len(@detail) > 1
	begin
		--	loading the file failed so log the error and exit
		set	@result	= 1;
		exec tcu.ProcessLog_sav	@RunId		= @RunId
							,	@ProcessId	= @ProcessId
							,	@ScheduleId	= @ScheduleId
							,	@StartedOn	= null
							,	@Result		= @result
							,	@Command	= @actionCmd
							,	@Message	= @detail;
		return @result;
	end;
	else if exists(	select	top 1 * from osi.Notice
					where	Detail	like '%There is no activity for report:%'
					and		ReportType is null	)
	begin
		--	delete the notice if there's no activity
		delete	osi.Notice
		where	ReportType is null;
	end;
	else
	begin
		--	remove the trailing spaces, update the application and file name from which the report is generated
		update	osi.Notice
		set		Detail		= rtrim(Detail)
			,	ApplName	= @applName
			,	FileName	= @fileName
		where	ApplName	is null;
	end;
end;

--	if notices were loaded then proceed...
if exists (	select	top 1 RowId from osi.Notice )
begin
	--	places each notice on a separate pages...
	--	a cursor is being used becasue the set-based operation was failing= 
	declare cNotice cursor fast_forward
	for	select	RowId, Detail
		from	osi.Notice
		order by RowId;

	open cNotice;

	fetch next from cNotice into @row, @detail;
	while @@fetch_status = 0
	begin
		--	pages are separated by form feed
		if charindex(@FF, @detail) > 0
			set	@page = @page + 1;

		update	osi.Notice
		set		Page	= @page
		where	RowId	= @row;

		fetch next from cNotice into @row, @detail;
	end;

	close cNotice;
	deallocate cNotice;

	--	remove any report headers...
	delete	osi.Notice
	where	Page in (	select	Page from osi.Notice
						where	Detail like '%Report:  ' + ApplName + '%'	);

	--	"blank out" the Texans Credit Union address for SDB Bills...
	update	n
	set		Detail	= replace(n.Detail, ad.Value, space(len(ad.Value)))
	from	osi.Notice	n
	join	tcu.fn_split(@address, '|')	ad
			on	n.Detail like ad.Value + '%'
	where	n.ApplName = 'SDBBILLS';

	/*	Match the notice to the appropriate type based on the "RE:" line of the noitice
	**	This is the most convoluted part of the process.  Notices are excluded for a
	**	number of reasons:
	**		1)	Mortgage notices produced from LN_LATE are excluded
	**		2)	HELOC notices produced from LN_POANT are excluded
	**		3)	Consumer loans are excluded all the time
	**		4)	Mortgage loans are re-cast as Consumer loand and not excluded
	**	Like I said -- convoluted!
	*/
	update	n
	set		ReportType	=	case n.ApplName
							when 'LN_LATE'	then case o.ReportType
												 when 'MTG' then 'DEL'
												 else o.ReportType end
							when 'LN_POANT'	then case o.MiCustDesc
												 when 'Home Equity Line of Credit' then 'DEL'
												 else o.ReportType end
							else	case o.ReportType
									when 'CNS' then 'DEL' 
									when 'MTG' then 'CNS'
									else o.ReportType end
							end
	from	osi.Notice	n
	join(	--	collect page number and description from the notice on the "Re:" line for these applications
			select	Page, Subject = ltrim(rtrim(replace(Detail, 'RE:', '')))
			from	osi.Notice
			where	ApplName	in	('LN_LATE', 'LN_LCHG', 'LN_POANT', 'LN_RPCHG')
			and		Detail		like '%RE:%'
		)	pg	on	n.Page = pg.Page
			--	get the OSI Custom Description for the Minor Account Type
	join	openquery(OSI,'
			select	distinct
 					case
 					when lower(MiCustDesc) like ''sm bus%'' then ''SBL''
 					when MjAcctTypCd = ''MLN'' then ''CML''
 					else MjAcctTypCd end	as ReportType
				,	MjAcctTypCd
				,	trim(MiCustDesc)		as MiCustDesc
			from	MjMiAcctTyp
			where	MjAcctTypCd in (''CML'', ''CNS'', ''MLN'', ''MTG'')'
		)	o	on	charindex(o.MiCustDesc, pg.Subject) > 0;
		/*	The joina above is the stragest criteria I've ever used -- but it works!!!
		**	The Subject is "stripped" and trimmed from the Notice however, sometimes a
		**	trailing space will remain that cannot be trimmed off.
		*/

	--	delete notices that are to be excluded...
	delete	osi.Notice
	where	ReportType = 'DEL';

	--	now the reports can be exported
	while exists (	select	top 1 ReportType from osi.Notice
					where	ReportType > @reportType	)
	begin
		--	retrieve the each Report Type, build the select query and any extension
		select	top 1
				@actionCmd	= 'select rtrim(Detail) from ' + db_name() + '.osi.Notice_vExport '
							+ 'where ReportType  = ''' + ReportType + ''' order by RowId'
			,	@extension	= isnull('.' + nullif(ReportType, 'CNS'), '')
			,	@switches	= '-T -c'
			,	@detail		= ''
			,	@reportType	= ReportType
		from	osi.Notice
		where	ReportType	> @reportType
		order by ReportType;

		--	update the action and target file name for the output and archive files...
		select	@actionFile	= @ftpFolder + @exportFile + @extension
			,	@targetFile	= @sqlFolder + 'archive\' + @exportFile + @extension + @archDate;

		--	export the query to the action file
		exec @result = tcu.File_bcp	@action		= 'queryout'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail output;
		if @result = 0 and len(@detail) = 0
		begin
			--	copy the action file to the archive location...
			exec @result = tcu.File_action	@action		= 'copy'
										,	@sourceFile	= @actionFile
										,	@targetFile	= @targetFile
										,	@overWrite	= 1
										,	@output		= @detail output;
			--	report any errors and exit...
			if @result != 0 or len(@detail) > 0
			begin
				set	@result = 1
				exec tcu.ProcessLog_sav	@RunId		= @RunId
									,	@ProcessId	= @ProcessId
									,	@ScheduleId	= @ScheduleId
									,	@StartedOn	= null
									,	@Result		= @result
									,	@Command	= @actionCmd
									,	@Message	= @detail;
				return @result;
			end;
		end;
		else
		begin
			--	report any errors and exit...
			set	@result = 1;
			exec tcu.ProcessLog_sav	@RunId		= @RunId
								,	@ProcessId	= @ProcessId
								,	@ScheduleId	= @ScheduleId
								,	@StartedOn	= null
								,	@Result		= @result
								,	@Command	= @actionCmd
								,	@Message	= @detail;
			return @result;
		end;
	end;	--	while loop
end;

--	dump the data...
truncate table osi.Notice;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO