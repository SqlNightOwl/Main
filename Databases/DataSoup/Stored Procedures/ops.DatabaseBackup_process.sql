use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[DatabaseBackup_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[DatabaseBackup_process]
GO
setuser N'ops'
GO
CREATE procedure ops.DatabaseBackup_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	05/15/2009
Purpose  :	Backups the databases.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@backup	sysname
,	@cmd	nvarchar(500)
,	@cycle	int
,	@dbName	sysname
,	@detail	varchar(4000)
,	@folder	varchar(255)
,	@proc	sysname
,	@result	int
,	@row	int
,	@start	datetime

declare	@dbList	table
	(	dbName	sysname
	,	row		int primary key
	);

--	initialize the variables...
select	@proc	= schema_name(schema_id()) + '.' + object_name(@@procid)
	,	@cycle	= isnull(datepart(minute, getdate()) % (60 / cast(tcu.fn_ProcessParameter(@ProcessId, 'Cycles Per Hour') as int)), 1)
	,	@detail	= ''
	,	@folder	= tcu.fn_ProcessParameter(@ProcessId, 'File Share') + '\'
	,	@result	= 0
	,	@row	= 0
	,	@start	= getdate();

if @cycle != 0 --	for produciton @cycle = 0
begin
	--	collect the list of databases to "reorg"
	insert	@dbList
	select	value, row
	from	tcu.fn_split(tcu.fn_ProcessParameter(@ProcessId, 'Database List'), ';')

	--	loop thru the databases and reorgainze the indexes...
	while exists (	select	top 1 * from @dbList
					where	row > @row	)
	begin
		select	top 1
				@dbName	= dbName
			,	@backup	= @folder + dbName
			,	@cmd	= 'backup database [' + dbName + '] '
						+ 'to disk = N''' + @folder + dbName + '\' + dbName + '.bak'' '
						+ 'with noformat, noinit,  name = N''' + dbName + '.bak'''
						+ ', skip, rewind, nounload, stats = 10;'
			,	@row	= row
		from	@dbList
		where	row		> @row
		order by row;

		exec master.dbo.xp_create_subdir @backup;

		exec sp_executesql @cmd;
/*
BACKUP DATABASE [DataSoup] TO  DISK = N'H:\Microsoft SQL Server\MSSQL.1\MSSQL\Backup\DataSoup\DataSoup_backup_200905151150.bak' WITH NOFORMAT, NOINIT,  NAME = N'DataSoup_backup_20090515115047', SKIP, REWIND, NOUNLOAD,  STATS = 10;

declare @backupSetId as int
select @backupSetId = position from msdb..backupset where database_name=N'DataSoup' and backup_set_id=(select max(backup_set_id) from msdb..backupset where database_name=N'DataSoup' )
if @backupSetId is null begin raiserror(N'Verify failed. Backup information for database ''DataSoup'' not found.', 16, 1) end
RESTORE VERIFYONLY FROM  DISK = N'H:\Microsoft SQL Server\MSSQL.1\MSSQL\Backup\DataSoup\DataSoup_backup_200905151150.bak' WITH  FILE = @backupSetId,  NOUNLOAD,  NOREWIND;
*/
	--	add the database to the list if errors occur...
		if @result != 0
		begin
			select	@detail = @detail + '<li>' + @dbName  + ' -- "' + @backup + '"</li>'
				,	@result	= 1;	--	FAILURE
			break;
		end;
	end;
end;

--	record the errors...
if len(@detail) > 0
begin
	set	@result	= 3;	--	warning
	set	@detail = 'The following database(s) returned an error when being backed up '
				+ 'using the ' + @proc + ' stored procedure:'
				+ '<ul>' + @detail + '</ul>';

	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= @start
						,	@Result		= @result
						,	@Command	= @proc
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