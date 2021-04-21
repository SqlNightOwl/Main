use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dev].[Procedure_getScript]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dev].[Procedure_getScript]
GO
setuser N'dev'
GO
create procedure dev.Procedure_getScript
	@table	sysname
,	@type	char(3)
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul D. Hunter
Created  :	03/16/2008
Purpose  :	Generate standard boiler plate CRUD DML procedure script. The input
			parameters are a valid table/schema name and the type of script you
			need to create.  The name of the procedure will be TableName_type.
			Values for the type parameter are:
			  •	del[ete]	- builds delete procedure base on primay key
			  •	get			- builds select procedure base on primay key
			  •	ins[ert]	- builds insert procedure base on primay key
			  •	upd[ate]	- builds update procedure base on primay key
			  •	sav[e]		- builds an combo update/insert procedure
			Identity and GUID values will be returned as output parameters.
			Calculated columns will not be included as input parameters. 
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@id			int			--	object id
,	@object		sysname		--	standardized name for the procedure
--	constants
,	@ACTION		varchar(6)	--	action to create/alter procedure
,	@CREATED	char(10)	--	create date for procedure header
,	@COMPANY	varchar(80)	--	company name
,	@DASH		char(1)		--	dash character
,	@TAB		char(1)		--	tab character
,	@UPS		varchar(1)	--	include a tab if this is an upsert (update/insert)

declare	@columns	table
	(	columnId		smallint primary key
	,	columnName		sysname
	,	dataType		varchar(20)
	,	isNullable		bit
	,	isIdentity		bit
	,	isAutoGuid		bit
	,	isComputed		bit
	,	keyId			smallint
	,	columnTabs		tinyint
	,	paramTabs		tinyint
	,	dataTypeTabs	tinyint
	,	identOrder		smallint
	,	nonKeyId		smallint	)

declare @auditCols	table
	(	action		varchar(10)
	,	columnName	sysname	primary key
	,	defaultVal	sysname	)

declare	@script		table
	(	script	sysname
	,	row	int identity primary key	)

select	@id			= o.object_id
	,	@object		= s.name + '.' + o.name + '_' + lower(@type)
	,	@table		= s.name + '.' + o.name
	,	@ACTION		= 'create'
	,	@COMPANY	= 'Texans Credit Union'
	,	@CREATED	= convert(char(10), getdate(), 101)
	,	@DASH		= char(151)
	,	@TAB		= char(9)
	,	@UPS		= case @type when 'sav' then char(9) else '' end
from	sys.tables	o
join	sys.schemas	s
		on	o.schema_id	= s.schema_id
where	o.name			= parsename(@table, 1)	--	table name
and		s.name			= parsename(@table, 2)	--	schema name
and		s.schema_id		between 4 and 15000		--	non "system" schema
and		o.type			= 'U'
and		o.is_ms_shipped	= 0;

--	exit if the table wasn't found or an incorrect type was provided
if @id is null or charindex(@type, 'delgetupdinsav') = 0
begin
	print 'The ' + @table + ' table wasn''t found or isn''t available for scripting - OR - the type provided isn''t supported.';
	return -1;
end

--	determine if this is a new or existing stored procedure
select	@ACTION		= 'alter'
	,	@CREATED	= convert(char(10), create_date, 101)
from	sys.procedures
where	object_id = object_id(@object);

--	add audit columns to exclude from insert/update statements...
insert	@auditCols select 'ins', 'CreatedBy', 'tcu.fn_UserAudit()';
insert	@auditCols select 'ins', 'CreatedOn', 'getdate()';
insert	@auditCols select 'upd', 'UpdatedBy', 'tcu.fn_UserAudit()';
insert	@auditCols select 'upd', 'UpdatedOn', 'getdate()';

--	collect the column details use for scripting the parameters...
insert	@columns
select	t.columnId
	,	t.columnName
	,	t.dataType
	,	t.isNullable
	,	t.isIdentity
	,	t.isAutoGuid
	,	t.isComputed
	,	t.keyId
	,	t.columnTabs
	,	t.paramTabs
	,	dataTypeTabs	= (len(t.dataType) + (4 - (len(t.dataType) % 4))) / 4
	,	identOrder		= t.columnId
	,	nonKeyId		= t.columnId
from(	select	columnId	= c.column_id
			,	columnName	= c.name
			,	dataType	= t.name
							+	case right(t.name, 4)	--	peel off the last 4 characters an base the format on that
								--	strings ([n]varCHAR or [n]CHAR)
								when 'CHAR' then replace('(|)', '|', isnull(nullif(cast(c.max_length as varchar), '-1'), 'max'))
								--	biNARY
								when 'NARY' then replace('(|)', '|', isnull(nullif(cast(c.max_length as varchar), '-1'), 'max'))
								--	decIMAL
								when 'imal' then replace(replace('(|,^)', '|', c.precision), '^', c.scale)
								--	numERIC
								when 'ERIC' then replace(replace('(|,^)', '|', c.precision), '^', c.scale)
								--	all others
								else '' end
			,	isNullable	= c.is_nullable
			,	isIdentity	= c.is_identity
			,	isAutoGuid	= case when c.is_rowguidcol = 1 and c.default_object_id > 0 then 1 else 0 end
			,	isComputed	= c.is_computed
			,	keyId		= isnull(i.key_ordinal, 0)
			,	columnTabs	= (len(c.name) + (4 - (len(c.name) % 4))) / 4
			,	paramTabs	= (len(c.name) + 1 + (4 - ((len(c.name) + 1) % 4))) / 4
		from	sys.columns	c
		join	sys.types	t
				on	c.system_type_id = t.user_type_id
		left join	--	connect to the primary key
			(	select	c.object_id, c.column_id, c.key_ordinal
				from	sys.indexes i
				join	sys.index_columns c
						on	i.object_id	= c.object_id
						and	i.index_id	= c.index_id
				where	i.object_id			= @id
				and		i.is_primary_key	= 1
			)	i	on	c.object_id	= i.object_id
					and	c.column_id	= i.column_id
		where	c.object_id = @id
	)	t;

--	adjust the number of tabs so that things line up...
update	c
set		columnTabs	 = maxCols - columnTabs
	,	paramTabs	 = maxParm - paramTabs
	,	dataTypeTabs = maxType - dataTypeTabs
from	@columns c
cross apply
	(	select	maxCols = 1 + ((max(len(columnName))	 + (4 - (max(len(columnName)) % 4)))	 / 4)
			,	maxParm = 1 + ((max(len(columnName) + 1) + (4 - (max(len(columnName) + 1) % 4))) / 4)
			,	maxType = 1 + ((max(len(dataType))		 + (4 - (max(len(dataType)) % 4)))		 / 4)
		from	@columns ) l;

--	update the column order less any identity column...
update	c
set		identOrder = identOrder + case when identOrder >= i.id then -1 else 0 end
from	@columns	c
cross apply
	(	select	id = columnId from @columns
		where	isIdentity = 1	) i;

--	update the column order less any identity column...
update	c
set		nonKeyId = c.nonKeyId - isnull(i.id, 0)
from	@columns	c
left join
	(	select	id = keyId from @columns
		where	keyId > 0
	)	i	on	c.columnId = i.id;

update	@columns
set		nonKeyId = nonKeyId - ( select max(keyId) from @columns )
where	nonKeyId > 0;

/*******************************************************************************
****		BUILD THE PROCEDURE DECLARATION
*******************************************************************************/
--	begin creating the procedure script
insert	@script	select	@ACTION + ' procedure ' + @object;

--	get the key columns as parameters for delete and select proceudres
insert	@script
select	case keyId when 1 then '' else	',' end + @TAB + '@' + columnName
	+	replicate(@TAB, paramTabs) + dataType
	+	case isNullable when 1 then replicate(@TAB, dataTypeTabs) + 'null' else '' end
from	@columns
where	@type	in ('del', 'get')
and		keyId	>	0
order by keyId;

--	get all columns as parameters for save, insert and update proceudres
insert	@script
select	case columnId when 1 then '	@' else	',	@' end + columnName
	+	replicate(@TAB, paramTabs) + dataType
	+	case isNullable when 1 then replicate(@TAB, dataTypeTabs) + '= null' else '' end
	+	case when isIdentity = 1 or isAutoGuid = 1 then replicate(@TAB, dataTypeTabs) + 'output' else '' end
from	@columns
where	@type		in ('ins', 'sav', 'upd')
and		columnName	not in ( select columnName from @auditCols )
order by columnId;

--	build the header...
insert	@script select	'as';
insert	@script select	'/*';
insert	@script select	replicate(@DASH, 80);
insert	@script select	replicate(@TAB, 3) + '© 2000-'
					+	right(cast(year(getdate()) as char(4)), 2)
					+	' • ' + @COMPANY + ' • All rights reserved.';
insert	@script select	replicate(@DASH, 80);
insert	@script select	'Developer:	' + substring(suser_name(), charindex('\', suser_name()) + 1, 50);
insert	@script select	'Created  :	' + @CREATED;
insert	@script select	'Purpose  :	';
insert	@script select	'History  :';
insert	@script select	'   Date		'
					+	'Developer		'
					+	'Description';
insert	@script select	replicate(@DASH, 10) + @TAB
					+	replicate(@DASH, 14) + @TAB
					+	replicate(@DASH, 52)
insert	@script select	replicate(@DASH, 80);
insert	@script select	'*/';
insert	@script select	'';
insert	@script select	'set nocount on;';
insert	@script select	'';
insert	@script select	'declare';
insert	@script select	'	@return	int';
insert	@script select	',	@rows	int' where @type = 'sav';
insert	@script select	'';

/*******************************************************************************
****		HANDLE SELECT/DELETE PROCEDURES
*******************************************************************************/
--	return columns for a get...
insert	@script
select	case columnId when 1 then 'select	' else '	,	' end + columnName
from	@columns
where	@type = 'get'
order by columnId;

--	build the from/delete clause...
insert	@script
select	case @type when 'del' then 'delete	' else 'from	' end + @table
where	@type in ('del', 'get');

--	build the where condition...
insert	@script
select	case keyId when 1 then 'where	' else 'and		' end + columnName
	+	replicate(@TAB, columnTabs) + '= @' + columnName
from	@columns
where	@type	in ('del', 'get')
and		keyId	>	0
order by keyId;

/*******************************************************************************
****		HANDLE INSERT, UPDATE AND UPSERT PROCEDURES
*******************************************************************************/
--	try the update first...
insert	@script select	'update	' + @table where @type in ('upd', 'sav');

--	build the update columns...
insert	@script
select	case c.nonKeyId when 1 then 'set		' else '	,	' end + c.columnName
	+	replicate(@TAB, c.columnTabs) + '= ' + isnull(a.defaultVal, '@' + c.columnName)
from	@columns	c
left join
		@auditCols	a
		on	c.columnName = a.columnName
where	@type			in ('upd', 'sav')
and		c.keyId			=	0
and		c.isComputed	=	0
and		isnull(a.action, 'upd') = 'upd'
order by c.columnId;

--	build the where condition...
insert	@script
select	case keyId when 1 then 'where	' else 'and		' end + columnName
	+	replicate(@TAB, columnTabs) + '= @' + columnName 
from	@columns
where	@type	in ('upd', 'sav')
and		keyId	>	0
order by keyId;

/*******************************************************************************
****		HANDLE INSERT/SAVE PROCEDURES
*******************************************************************************/
--	handle the upsert [were updated? did errors occur?]
insert	@script select	''								where @type	= 'sav';
insert	@script select 'select	@return	= @@error'		where @type = 'sav';
insert	@script select '	,	@rows	= @@rowcount;'	where @type = 'sav';
insert	@script select ''								where @type = 'sav';

--	begin the update block for an upsert...
insert	@script select	'--	insert if nothing updated and no errors'	where @type = 'sav';
insert	@script select	'if	@rows	= 0'								where @type = 'sav';
insert	@script select	'and	@return	= 0'							where @type = 'sav';
insert	@script select	'begin'											where @type = 'sav';

--	set any GUID values...
insert	@script
select	@UPS + 'set	@' + columnName + '	= newid();'
from	@columns
where	@type		in ('ins', 'sav')
and		isAutoGuid	=	1;

--	add a blank line if there's a GUID...
if @@rowcount > 0	insert	@script select	''		where @type in ('ins', 'sav');

--	build the insert statement...
insert	@script select	@UPS + 'insert	' + @table	where @type in ('ins', 'sav');

--	build the inserted columns...
insert	@script
select	@UPS + case c.identOrder when 1 then '	(	' else '	,	' end + c.columnName
from	@columns	c
left join
		@auditCols	a
		on	c.columnName = a.columnName
where	@type			in ('ins', 'sav')
and		c.identOrder	>	0
and		c.isComputed	=	0
and		isnull(a.action, 'ins') = 'ins'
order by c.identOrder;

--	finish out the insert part...
update	@script
set		script	= script + '	)'
where	row		= (select max(row) from @script )
and		@type	in ('ins', 'sav');

--	begin the values section...
insert	@script select	@UPS + 'values' where @type in ('ins', 'sav');

--	begin the parameter values...
insert	@script
select	@UPS + case c.identOrder when 1 then '	(	' else '	,	' end
	+	isnull(a.defaultVal, '@' + c.columnName)
from	@columns		c
left join @auditCols	a
		on	c.columnName = a.columnName
where	@type			in ('ins', 'sav')
and		c.identOrder	>	0
and		c.isComputed	=	0
and		isnull(a.action, 'ins') = 'ins'
order by c.identOrder;

--	finish out the parameters part...
update	@script
set		script	= script + '	)'
where	row		= (select max(row) from @script )
and		@type	in ('ins', 'sav');

insert	@script select '' where @type = 'sav';

if exists (	select	top 1 * from @columns
			where	isIdentity = 1 )
begin
	--	collect the return and identity values...
	insert	@script
	select	@UPS + 'select	@return	= @@error'
	from	@columns
	where	@type		in ('ins', 'sav')
	and		isIdentity	=	1;

	insert	@script
	select	@UPS + '	,	@' + columnName + '	= scope_identity();'
	from	@columns
	where	@type		in ('ins', 'sav')
	and		isIdentity	=	1;
end
else
begin
	--	set the return value...
	insert	@script select @UPS + 'set @return	= @@error;' where @type = 'sav';
end

--	close the update block for an upsert...
insert	@script select 'end' where	@type = 'sav';

/*******************************************************************************
****		CLOSE THE PROCEDURE SCRIPT AND RETURN THE RESULTS
*******************************************************************************/
--
insert	@script select ''						where @type != 'sav';
insert	@script select 'set @return = @@error;'	where @type != 'sav';

--	finish it out the script
insert	@script select	''
insert	@script select	'PROC_EXIT:'
insert	@script select	'if @return != 0'
insert	@script select	'begin'
insert	@script select	'	declare	@errorProc sysname;'
insert	@script select	'	set	@errorProc = object_schema_name(@@procid) + ''.'' + object_name(@@procid);'
insert	@script select	'	raiserror(N''An error occured while executing the procedure "%s"'', 15, 1, @errorProc) with log;'
insert	@script select	'end'
insert	@script select	''
insert	@script select	'return @return;'
insert	@script select	'go'

--	return the script...
select	script as script
from	@script
order by row;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO