use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[ProcessOSILog_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[ProcessOSILog_ins]
GO
setuser N'tcu'
GO
CREATE procedure tcu.ProcessOSILog_ins
	@RunId			int
,	@ProcessId		smallint
,	@ScheduleId		tinyint
,	@IsReady		bit		= 0	output
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/02/2007
Purpose  :	Records the OSI Application, Que and File details for the Run, Process
			and Schedule provided.  If all of the Applications have not completed
			then no data will be recorded.  This procedure also behaves like a
			trigger for further Process execution via the IsReady output parameter.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/01/2008	Paul Hunter		Added the daily offset column to accomodate files
							which are produced in a daily folder that is different
							from the effective date.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
02/01/2010	Paul Hunter		Added QueDesc to the extracted data.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@applList	nvarchar(1000)
,	@applName	nvarchar(60)
,	@bitWiseDay	int
,	@cmd		nvarchar(4000)
,	@effDate	datetime
,	@fileName	varchar(50)
,	@newestFile	bit
,	@osiFolder	varchar(255)
,	@osiPath	varchar(255)
,	@queNbr		int
,	@priorDay	tinyint;

declare	@applFiles	table
	(	applName	nvarchar(60) not null primary key
	,	isRequired	bit	not null
	);
declare	@files		table
	(	applName	nvarchar(60)	not null	
	,	queNbr		int				not null
	,	fileId		int				not null
	,	path		varchar(255)	not null
	,	fileName	varchar(255)	not null
	,	fileDate	datetime		not null
	,	fileSize	int				not null
	,	fileCount	int				not null
	);
create table #osiStatus
	(	applName	nvarchar(60)	not null
	,	queNbr		int				not null
	,	queDesc		varchar(60)		null
	,	dailyOffset	char(8)			not null
	,	effectiveOn	datetime		not null
	,	completedOn	datetime		null
	,	errorCount	int				not null
	);

--	retrieve information about the scheudle, clean up the list and initialize the rows affected
select	@effDate	= convert(char(10), dateadd(day, -cast(s.UsePriorDay as int), getdate()), 101)
	,	@priorDay	= isnull(s.UsePriorDay, 0)
	,	@newestFile	= s.UseNewestFile
	,	@IsReady	= 0
	,	@applList	= ''
	,	@fileName	= ''
	,	@osiFolder	= tcu.fn_OSIFolder() 
from	tcu.ProcessSchedule	s
join	tcu.Process			p
		on	p.ProcessId = s.ProcessId
where	s.ProcessId		= @ProcessId				--	use the process linked to any chain
and		s.ScheduleId	= @ScheduleId;

set	@bitWiseDay	= power(2, datepart(weekday, @effDate));

--	collect the application to be executed and if it's "required"
insert	@applFiles
select	distinct
		upper(ApplName)
	,	IsRequired
from	tcu.ProcessFile
where	ProcessId	= @ProcessId
and		ApplName	is not null
and	(	case
		when ApplFrequency	= 0 then 1
		when ApplFrequency	= 256 and day(@effDate) = 1 then 1
		when ApplFrequency	= 512 and day(@effDate) = day(tcu.fn_LastDayOfMonth(@effDate)) then 1
		when @bitWiseDay	= (ApplFrequency & @bitWiseDay) then 1
		else 0 end ) = 1;

--	no records returned...
if @@rowcount = 0
begin
	select	@applList	= 'The Process "' + Process + '" has no OSI Applications to be run.'
	from	tcu.Process
	where	ProcessId	= @ProcessId;

	raiserror(@applList, 15, 1) with log;

	return 3;	--	Warning
end;

--	put the list into a contiguous string
select	@applList = @applList + '''''' + applName + ''''','
from	@applFiles;

set	@applList = left(@applList, len(@applList) - 1);

--	collect the status of the OSI Applications for this Process
set	@cmd = '
insert	#osiStatus
select	ApplName
	,	QueNbr
	,	QueDesc
	,	DailyOffset
	,	EffDate
	,	CompleteDateTime
	,	ErrorCount
from	openquery(OSI, ''
		select	ApplName
			,	QueNbr
			,	QueDesc
			,	DailyOffset
			,	EffDate
			,	CompleteDateTime
			,	ErrorCount
		from	texans.ops_ApplicationStatus_vw
		where	EffDate		= trunc(sysdate) - ' + cast(@priorDay as char(1)) + '
		and		ApplName	in (' + @applList + ')
		and		DailyOffset	is not null'')';

exec sp_executesql @cmd;

/*
**	If any records match the criteria below then the process isn't complete because
**	a required OSI application hasn't completed, a required one is missing or there
**	was an error in running the application.
*/
if not exists (	select	f.applName	from @applFiles f
				left join	#osiStatus s on f.applName = s.applName
				where	1 =	case
							when s.completedOn	is null		--	Not complete...
							 and f.isRequired	= 1			--	...is required
								then 1						--	...so, not ready!
							when s.completedOn	is null		--	Not complete...
							 and isnull(s.queNbr, -1) > 0	--	...not required but is running
								then 1						--	...so, not ready!
							else 0 end
					or	0 != s.errorCount	)				--	There are no errors
begin
	-- if you're here then the applicaitons have completed and we're finding files
	while exists (	select	top 1 ProcessId from tcu.ProcessFile
					where	ProcessId	= @ProcessId
					and 	FileName	> @fileName	)
	begin
		select	top 1
				@applName	= ApplName
			,	@fileName	= FileName
			,	@queNbr		= 0
		from	tcu.ProcessFile
		where	ProcessId	= @ProcessId
		and 	FileName	> @fileName
		order by FileName;

		--	files for a given effective date and application may be created in different daily folders so, collect them all...
		while exists (	select	top 1 queNbr from #osiStatus
						where	queNbr > @queNbr	)
		begin
			select	top 1
					@osiPath	= tcu.fn_UNCFileSpec(@osiFolder + dailyOffset + '\')
				,	@queNbr		= queNbr
			from	#osiStatus
			where	queNbr		> @queNbr;

			--	find the file(s)...
			exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
									,	@RunId				= @RunId
									,	@uncFolder			= @osiPath
									,	@fileMask			= @fileName
									,	@includeSubFolders	= 1;

			--	...add them to the temp table...
			insert	@files
				(	applName
				,	queNbr
				,	fileId
				,	path
				,	fileName
				,	fileDate
				,	fileSize
				,	fileCount
				)
			select	@applName
				,	cast(SubFolder as int)
				,	FileId
				,	Path
				,	FileName
				,	FileDate
				,	FileSize
				,	FileCount
			from	tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId
					-- use all files when @newestFile equals zero
			and		IsNewest	= isnull(nullif(@newestFile, 0), IsNewest);

			--	... and remove them from the source table
			delete	tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId;
		end;
	end;

	--	log the information...
	insert	tcu.ProcessOSILog
		(	RunId
		,	ProcessId
		,	EffectiveOn
		,	ApplName
		,	DailyOffset
		,	QueNbr
		,	QueDesc
		,	CompletedOn
		,	FileName
		,	FileDate
		,	FileSize
		,	FileCount
		,	CreatedBy
		,	CreatedOn
		)
	select	distinct
			@RunId
		,	@ProcessId
		,	@effDate
		,	f.applName
		,	isnull(s.dailyOffset, convert(char(8), @effDate, 112))
		,	f.queNbr
		,	s.queDesc
		,	isnull(s.completedOn, f.fileDate)
		,	f.fileName
		,	f.fileDate
		,	f.fileSize
		,	f.fileCount
		,	tcu.fn_UserAudit()
		,	getdate()
	from	@files		f
	left join
			#osiStatus	s
			on	f.applName	= s.applName
			and	f.queNbr	= s.queNbr;

	--	return the number of files
	set	@IsReady = case when @@rowcount > 0 then 1 else 0 end;
end;

drop table #osiStatus;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO