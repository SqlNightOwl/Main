use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[DBSmartIndexDefragger]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[DBSmartIndexDefragger]
GO
setuser N'ops'
GO
create procedure ops.DBSmartIndexDefragger
	@databaseName nvarchar(128)
as
/*
**
**	DEPLOYMENT
**	The default posture of the script is to run in debug mode.
**	set @debug = 0; (line #126) to activate the script
**		1. Open the script in the target database's context (ie. PE1)
**
**		2. Replace "<schema>" with the target schema's name (ie. replace "<schema>" with "PE1")
**
**		3. Execute the script.
**			This will a stored procedure called usp_smartIndexDefragger
**			bound to the schema designated in the first step
**
**	AUTOMATED EXECUTION
**	Create a SQL Agent Job for each database to be maintained with:
**		a.	one Job Step
**		b.	type: T-SQL
**		c.	database: target database
**		d.	command: execute <schema>.usp_smartIndexDefragger 'databaseName';
**		e.	on success action: quit the job reporting success
**		f.	a schedule with a frequency appropriate to the environment
**
**	MANUAL EXECUTION
**		execute <schema>.usp_smartIndexDefragger 'databaseName';
**
**
*/
begin
	/*
	*	Version 5.4 (2009.07.09 @ 4:00pm)
	*
	*	This routine selects and defragments indexes based on their page count (size) and
	*	level of fragmentation using the following three steps:
	*		STEP #1	Queue all indexes along with a defragmentation recommendation for each
	*		STEP #2	Remove indexes from the defragmentation queue that do not require defragmentation
	*				unless they are non-clustered indexes on a table having its clustered index defragmented
	*		STEP #3	Defragment the indexes!
	*
	*	NOTES:
	*		1.	SQL Server 2005/2008 Enterprise/Developer Edition required for online,
	*			partitioning and parallel indexing operations
	*		2.	The database's recovery model will be changed to BULK_LOGGED to help minimize impact on 
	*			the transaction log during defragmentation if the database is not involved in mirroring
	*			and uses the FULL recovery model
	*		3.	This routine depends on information stored in various system tables local to the target
	*			database and therefore must be executed in the target database's context. Hence the need
	*			for STEP #1 to be written and executed as dynamic SQL.
	*		4.	An offline rebuild means that the table will be locked during the index's
	*			defragmentation and blocking will likely ensue until the operation is finished.
	*
	*	-----------------------------------------------------------------------------------------------
	*	Techincal References
	*	-----------------------------------------------------------------------------------------------
	*	INDEX PAGE COUNT
	*	http://technet.microsoft.com/sv-se/library/cc966523(en-us).aspx
	*	"Generally, you should not be concerned with fragmentation levels of indexes with
	*	less than 1,000 pages. In the tests, indexes containing more than 10,000 pages
	*	realized performance gains, with the biggest gains on indexes with significantly
	*	more pages (greater than 50,000 pages)."
	*
	*	ONLINE vs OFFLINE
	*	http://technet.microsoft.com/en-us/library/ms188388(SQL.90).aspx
	*	Online indexing is not available for clustered indexes over tables containing text,
	*	ntext, image, varchar(max), nvarchar(max), varbinary(max), xml, or large CLR type columns.
	*	Online indexing is not available for non-clustered indexes containing text, ntext, image,
	*	varchar(max), nvarchar(max), varbinary(max), xml, or large CLR type columns.
	*
	*	REBUILD vs REORGANIZE
	*	http://technet.microsoft.com/en-us/library/ms189858.aspx
	*	If the avg_fragmentation_in_percent is <= %5 then ignore the index.
	*	If the avg_fragmentation_in_percent is > 5% and <= 30% then reorganize the index.
	*	If the avg_fragmentation_in_percent is > 30% then rebuild the index.
	*
	*	The above data points are used to determine whether or not an index should be defragmented
	*	and if so the method to use for deframenting. The results is returned as defragmentationType
	*	from cteEligibleIndexes as one of the following values:
	*
	*	DefragmentationType	Defragmentation Method
	*	===================	======================
	*		0					None
	*		1					Reorganize
	*		2					Rebuild
	*
	*	-----------------------------------------------------------------------------------------------
	*	Acknowledgements... (this script builds on the ideas expressed from the following individuals)
	*	-----------------------------------------------------------------------------------------------
	*		Ola Hallengren	http://ola.hallengren.com
	*		Brian Smyk		http://www.sqlmag.com/Articles/ArticleID/101777/101777.html
	*		Saleem Hakani	http://www.sqlcommunity.com
	*/
	set nocount on;

	declare
		@canBulkLog		bit
	,	@databaseId		int
	,	@isDebug		bit
	,	@rowId			int
	,	@sqlCommand		nvarchar(4000);

	declare	@defragmentationQueue	table	
		 (	rowId				int				identity(1, 1)
		,	[object_id]			int
		,	index_id			int
		,	partition_number	int
		,	tableName			sysname
		,	indexName			sysname
		,	isPartitioned		bit
		,	isClustered			bit
		,	canDefragmentOnline	bit
		,	defragmentationType	tinyint
		,	sqlCommand			nvarchar(4000)	default('')
		);

	-- initialize variables
	-- NOTE: Get the database's correctly cased name so that the generated DDL will execute properly
	select	@databaseName	=	d.[name]
		,	@databaseId		=	d.database_id
		,	@isDebug		=	0
		,	@canBulkLog		=	(	case -- cannot change recovery model for mirrored databases
									when m.mirroring_guid is null
									then 1
									else 0
									end
								)
								*
								(	case -- only change recovery model for FULL recovery databases
									when d.recovery_model = 1
									then 1
									else 0
									end
								)
		,	@rowId			=	0
	from	master.sys.databases		as d
	inner	join sys.database_mirroring	as m
		on	d.database_id = m.database_id
	where	lower([name]) = lower(@databaseName);

	-- if the database cannot be found then abort
	if @databaseId is null
		return 1;

	-- STEP #1	Queue all indexes along with a defragmentation recommendation for each
	--			(with clustered indexes appearing first in their table's list of indexes)
	-- NOTE:	The query's white space has been reduced, by left aligning subqueries,
	--			to allow the expanded SQL to fit within the nvarchar(4000) space restriction
	set @sqlCommand =
'with cteEligibleIndexes as (
select
	ips.[object_id]
,	ips.index_id
,	ips.partition_number
,	tableName			=
	''[' + @databaseName + '].'' +
	(	case
		when exists	(	select	1
						from	' + @databaseName + '.sys.tables as t
						where	t.[object_id] = i.[object_id]
					)
		then	(	select	''['' + s.[Name] + ''].['' + t.[Name] + '']''	-- table
					from	' + @databaseName + '.sys.tables		as t
					inner	join ' + @databaseName + '.sys.schemas	as s
						on	t.[schema_id] = s.[schema_id]
					where	t.[object_id] = i.[object_id]
				)
		else	(	select	''['' + s.[Name] + ''].['' + v.[Name] + '']''	-- indexed view
					from	' + @databaseName + '.sys.views		as v
					inner	join ' + @databaseName + '.sys.schemas	as s
						on	v.[schema_id] = s.[schema_id]
					where	v.[object_id] = i.[object_id]
				)
		end
	)
,	indexName			=	''['' + i.name + '']''
,	isPartitioned		=
	case
	when	(	select	count(1)
				from	' + @databaseName + '.sys.partitions as p
				where	p.[object_id] = ips.[object_id]
					and	p.index_id = ips.index_id
			) > 1
	then	1
	else	0
	end
,	isClustered			=
	case
	when ips.index_type_desc = ''CLUSTERED INDEX''
	then 1
	else 0
	end
,	canDefragmentOnline =
	case
	when	ips.index_type_desc = ''CLUSTERED INDEX''
	then	case
			when exists (	select	1
							from	' + @databaseName + '.sys.columns		as c
							inner	join ' + @databaseName + '.sys.types	as t
								on	c.system_type_id = t.system_type_id
							where	c.[object_id] =	ips.[object_id]
								and	(	t.is_assembly_type = 1					-- CLR type
									or	t.system_type_id in (34, 35, 99, 241)	-- image, text, ntext, xml
									or	(	t.system_type_id in (165, 167, 231)	-- varbinary(max), varchar(max), nvarchar(max)
										and c.max_length = -1
										)
									)
						)
			then 0
			else 1
			end
	else	case
			when exists (	select	1
							from	' + @databaseName + '.sys.index_columns	as ic
							inner	join ' + @databaseName + '.sys.columns	as c
								on	ic.[object_id] = c.[object_id]
								and	ic.column_id = c.column_id
							inner	join sys.types		as t
								on	c.system_type_id = t.system_type_id
							where	ic.[object_id] = ips.[object_id]
								and	ic.index_id = ips.index_id
								and	(	t.is_assembly_type = 1					-- CLR type
									or	t.system_type_id in (34, 35, 99, 241)	-- image, text, ntext, xml
									or	(	t.system_type_id in (165, 167, 231)	-- varbinary(max), varchar(max), nvarchar(max)
										and c.max_length = -1
										)
									)
						)
			then 0
			else 1
			end
	end
,	defragmentationType	=
	(	case	-- defragmentation type
		when ips.avg_fragmentation_in_percent < 5.0
		then 0	-- none
		when ips.avg_fragmentation_in_percent between 5.0 and 30.0
		then 1	-- reorganize
		else 2	-- rebuild
		end
	)
	*
	(	case	-- is the index large enough to defragment?
		when ips.page_count > 1000
		then 1	-- yes
		else 0	-- no
		end
	)
	*
	(	case	-- reorganizing?
		when ips.avg_fragmentation_in_percent between 5.0 and 30.0
		then	case	-- is the index eligible to be reorganize?
				when	(	select	(i.[allow_page_locks] * 1) + (i.is_disabled * 2)	-- (bitmap)
							from	' + @databaseName + '.sys.indexes	as i
							where	i.[object_id] = ips.object_id
								and	i.index_id = ips.index_id
						) = 1
				then 1	-- yes
				else 0	-- no
				end
		else 1	-- N/A
		end
	)
from	sys.dm_db_index_physical_stats(' + cast(@databaseId as varchar) + ', null, null, null, ''limited'')	as ips
inner	join ' + @databaseName + '.sys.indexes																as i
	on	ips.[object_id] = i.[object_id]
	and	ips.index_id = i.index_id
where	ips.index_id > 0	-- non-heap object
	and	ips.alloc_unit_type_desc = ''IN_ROW_DATA''	)	-- cteEligibleIndexes
select	*
from	cteEligibleIndexes
order	by
		[object_id]
	,	index_id
	,	isClustered
	,	partition_number;';

	insert	@defragmentationQueue
		(	[object_id]
		,	index_id
		,	partition_number
		,	tableName
		,	indexName
		,	isPartitioned
		,	isClustered
		,	canDefragmentOnline
		,	defragmentationType
		)
	exec sp_executesql @sqlCommand;

	-- STEP #2	Remove indexes from the defragmentation queue that do not require defragmentation
	--			unless they are non-clustered indexes on a table having its clustered index defragmented

	-- dequeue clustered indexes not needing defragmentation
	-- NOTE:	removing eligible clustered indexes first eliminates the
	--			mandatory rebuild of the table's non-clustered indexes
	delete	@defragmentationQueue
	where	isClustered			= 1
	and		defragmentationType	= 0;

	-- dequeue non-clustered indexes not needing defragmentation
	-- NOTE:	any non-clustered index that does not need defragmentation
	--			and whose table's clustered index is not being defragmented
	--			should also be dequeued
	delete	@defragmentationQueue
	from	@defragmentationQueue as dq
	inner join
		(	select	distinct
					[object_id]
			from	@defragmentationQueue
			where	isClustered = 0
			except
			select	distinct
					[object_id]
			from	@defragmentationQueue
			where	isClustered = 1
		) as dqnc
		on	dq.[object_id] = dqnc.[object_id]
	where	dq.defragmentationType = 0;

	-- STEP #3
	-- Defragment the indexes!
	begin try

		-- change the database's recovery model to bulk logged to help 
		-- reduce the impact on the transaction log during defragmentation
		if @isDebug = 0 and @canBulkLog = 1
		begin
			set @sqlCommand = N'alter database ' + @databaseName + ' set recovery bulk_logged;';
			exec sp_executesql @sqlCommand;
		end;

		while 1 = 1
		begin

			-- get the next row to be processed
			set @rowId = (	select	top 1
									rowId
							from	@defragmentationQueue
							where	rowId > @rowId
							order	by
									rowId
						 );

			if @rowId is null
				break;

			-- build the sql command for each index to be defragmented
			select	@sqlCommand =	N'alter index ' + indexName + ' on ' + tableName + ' '
								+	case
									when defragmentationType = 0
									then 'rebuild '
									when defragmentationType = 1
									then 'reorganize '
									when defragmentationType = 2
									then 'rebuild '
									end
								+	case
									when isPartitioned = 1
									then 'partition = ' + cast(partition_number as varchar) + ' '
									else ''
									end
								+	'with ('
								+	case
									when	serverproperty('EngineEdition') = 3
										and (defragmentationType = 0 or defragmentationType = 2)
										and isPartitioned = 0
									then	case
											when canDefragmentOnline = 1
											then 'online = on, '
											else 'online = off, '
											end
									else	''
									end
								+	case
									when defragmentationType = 1
									then 'lob_compaction = on'
									when defragmentationType = 0 or defragmentationType = 2
									then 'sort_in_tempdb = on, maxdop = 0'
									else ''
									end
								+	');'
			from	@defragmentationQueue
			where	rowId = @rowId;

			-- save the sql command when debugging
			if @isDebug = 1
				update	@defragmentationQueue
					set	sqlCommand = @sqlCommand
				where	rowId = @rowId;

			-- hit it!
			if @isDebug = 0
				exec sp_executesql @sqlCommand;

		end;

	end try
	begin catch
	end catch;

	-- restore the database's recovery model to full if not debugging
	-- otherwise, "How'd we do?"
	if @isDebug = 0 and @canBulkLog = 1
	begin
		set @sqlCommand = N'alter database ' + @databaseName + ' set recovery full;';
		exec sp_executesql @sqlCommand;
	end

	if @isDebug = 1
	begin
		select	*
		from	@defragmentationQueue
		order	by
				rowId;
	end;
end;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO