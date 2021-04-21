use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[FileLog_findFiles]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[FileLog_findFiles]
GO
setuser N'tcu'
GO
CREATE procedure tcu.FileLog_findFiles
	@ProcessId			int
,	@RunId				int
,	@uncFolder			varchar(255)
,	@fileMask			varchar(255)
,	@includeSubFolders	bit				= 1
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/29/2007
Purpose  :	Returns the details from scanning the specified folder for the file
			mask provided.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
03/14/2008	Paul Hunter		Added the option to include subfolders which had
							always been done. 
04/23/2009	Paul Hunter		Removed calls to sp_configure to toggle xp_cmdshell.
03/10/2010	Paul Hunter		Added table clean up routine.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd		nvarchar(2000)
,	@retention	int

declare	@cmdOutput	table
	(	record		varchar(255)
	,	row			int identity primary key
	);

declare	@procOutput	table
	(	fileId		int		identity
	,	path		varchar(255)	null
	,	fileName	varchar(255)	null
	,	fileDate	smalldatetime	null
	,	fileSize	int				null
	,	fileCount	int				null
	,	isNewest	tinyint			null
	);

--	build the OS search command
set	@uncFolder	= tcu.fn_UNCFileSpec(@uncFolder + '\');
set	@cmd		= 'dir "' + @uncFolder + @fileMask + '"'
				+ case isnull(@includeSubFolders, 0) when 1 then ' /s' else '' end;

--	run the DOS command...
insert @cmdOutput exec master.sys.xp_cmdshell @cmd;

insert	@procOutput
select	p.path
	,	f.fileName
	,	f.fileDate
	,	f.fileSize
	,	c.fileCount
	,	isNewest = case f.fileDate when c.maxDate then 1 else 0 end
from(	--	return the path, queue folder and row number
		select	path	= rtrim(substring(p.record, 15, 255))
			,	p.row
			,	next	= isnull((	select	top 1 row from @cmdOutput
									where	charindex('Directory of', record) > 1
									and		row > p.row	)
								, (	select	max(row) from @cmdOutput))
		from	@cmdOutput p
		where	charindex('Directory of', p.record) > 0
	)	p
	--	collect the filenames and dates
join(	select	fileName = rtrim(substring(record, 40, 255)), row
			,	fileDate = cast(left(record, 20) as smalldatetime)
			,	fileSize = cast(replace(ltrim(substring(record, 25, 14)) , ',', '') as bigint)
		from	@cmdOutput
		where	record	like '%' + replace(replace(@fileMask, '*', '%'), '?', '_') + '%'
		and		1	=	isdate(left(record, 20))
		and		1	=	isnumeric(ltrim(substring(record, 25, 14)))
	)	f	on	f.row	between p.row and p.next
	--	count the files and get the newest file date
join(	select	fileName	= rtrim(substring(record, 40, 255))
			,	fileCount	= count(1)
			,	maxDate		= max(cast(left(record, 20) as smalldatetime))
		from	@cmdOutput
		where	record like '%' + replace(replace(@fileMask, '*', '%'), '?', '_') + '%'
		group by rtrim(substring(record, 40, 255))
	)	c	on	f.fileName = c.fileName;

insert	tcu.FileLog
	(	ProcessId
	,	RunId
	,	FileId
	,	Path
	,	SubFolder
	,	FileName
	,	FileDate
	,	FileSize
	,	FileCount
	,	IsNewest
	,	CreatedOn
	)
select	@ProcessId
	,	@RunId
	,	FileId
	,	Path
	,	SubFolder = reverse(left(reverse(Path), charindex('\', reverse(Path)) -1))
	,	FileName
	,	FileDate
	,	FileSize
	,	FileCount
	,	IsNewest
	,	getdate()
from	@procOutput;

set	@retention = isnull(cast(tcu.fn_ProcessParameter(@ProcessId, 'Retention Period') as int), 30) * -1;

--	clean the log table based on the retention period
delete	tcu.FileLog
where	ProcessId	= @ProcessId
and		FileDate	< dateadd(day, @retention, convert(char(10), getdate(), 101));

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO