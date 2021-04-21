use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[DatabaseIndex_reorganize]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[DatabaseIndex_reorganize]
GO
setuser N'ops'
GO
CREATE procedure ops.DatabaseIndex_reorganize
	@dbName	sysname	= null
,	@debug	bit		= 0
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 - Texans Credit Union - All Rights Reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huner
Created  :	08/27/2008
Purpose  :	Reorganizes indexes in the specified database having more than 10
			data pages and with an avg fragmentation percent > 10.
Input	 :		@dbName	- name of the database to reorg.
				@debug	- indicates if the status messages will be printed.
History  :
   Date     Developer       Description
——————————  ——————————————  ————————————————————————————————————————————————————
05/11/2009	Paul Hunter		Added the DBCC CHECKDB (@dbName); command on Sundays.
							Added the DBCC DBREINDEX (@tbl); command on Sundays.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(max)
,	@dbId	smallint
,	@row	int
,	@tbl	sysname;

create table #indexList
	(	row				int identity primary key
	,	dbName			sysname
	,	schemaName		sysname
	,	objectName		sysname
	,	indexName		sysname
	,	indexFill		int
	,	partitionNbr	int
	,	partitionCnt	int
	);

set	@dbName	= isnull(@dbName, db_name());
set	@dbId	= db_id(@dbName);
set	@debug	= isnull(@debug, 0);
set	@row	= 0;

--	get index stats
set	@cmd = '
insert	#indexList
	(	dbName
	,	objectName
	,	schemaName
	,	indexName
	,	indexFill
	,	partitionNbr
	,	partitionCnt
	)
select	db_name(@dbId)
	,	o.name
	,	s.name
	,	i.name
	,	i.fill_factor
	,	ips.partition_number
	,	p.partitions
from	sys.dm_db_index_physical_stats
		(@dbId, null, null, null, ''LIMITED'')	ips
join	' + @dbName + '.sys.objects	o
		on	ips.object_id	= o.object_id
join	' + @dbName + '.sys.schemas	s
		on	o.schema_id	= s.schema_id
join	' + @dbName + '.sys.indexes	i
		on	ips.object_id	= i.object_id
		and	ips.index_id	= i.index_id
join(	select	object_id, index_id, partitions	= count(1)
		from	' + @dbName + '.sys.partitions
		group by object_id, index_id
	)	p	on	i.object_id	= p.object_id
			and	i.index_id	= p.index_id
where	ips.page_count	> 10
and		ips.index_id	> 0
and		ips.avg_fragmentation_in_percent > 10
and		ips.index_type_desc	not like ''%XML%''
order by s.name, o.name, i.index_id;';

if @debug = 1
begin
	print @cmd;
	print '';
end;

exec sp_executesql	@cmd
				,	N'@dbId smallint'
				,	@dbId;
if datename(weekday, getdate()) = 'sunday'
begin
	set @cmd = 'DBCC CHECKDB (''' + @dbName + ''') with no_infomsgs;'
	if @debug = 1
	begin
		print @cmd;
		print '';
	end;
	exec sp_executesql	@cmd;

	set	@tbl = '';
	while exists ( select top 1 row from #indexList where schemaName + '.' + objectName > @tbl )
	begin
		select	top 1
				@cmd = 'DBCC DBREINDEX (''' + schemaName + '.' + objectName + ''') with no_infomsgs;'
			,	@tbl = schemaName + '.' + objectName
		from	#indexList
		where	schemaName + '.' + objectName > @tbl
		order by schemaName, objectName

		if len(@cmd) > 0
		begin
			if @debug = 1 print	@cmd;
			exec sp_executesql	@cmd;
		end;		
	end;
end;
else
begin
	while exists ( select top 1 row from #indexList where row > @row )
	begin
		select	top 1
				@cmd	= 'alter index ' + indexName + ' on '+ dbName + '.' + schemaName + '.' + objectName
						+ ' rebuild  with( sort_in_tempdb = on, statistics_norecompute = off )'
						+ case partitionCnt when 1 then '' else ' partition = ' + cast(partitionNbr as varchar) end
						+ ';'
			,	@row	= row
		from	#indexList
		where	row		> @row
		order by row;

		if len(@cmd) > 0
		begin
			if @debug = 1 print @cmd;
			exec sp_executesql	@cmd;
		end;
	end;
end;

drop table #indexList;

if @debug = 1 
begin
	print '';
	print 'The above listed indexes have been reorganized for the ' + @dbName + ' database.';
end

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO