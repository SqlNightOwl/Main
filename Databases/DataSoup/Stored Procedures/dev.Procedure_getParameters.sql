use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dev].[Procedure_getParameters]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dev].[Procedure_getParameters]
GO
setuser N'dev'
GO
CREATE procedure dev.Procedure_getParameters
	@procedure	sysname
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 - Texans Credit Union - All Rights Reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huner
Created  :	04/19/2008
Purpose  :	Returns the parameter definitions needed to create an ADO Parameters
			collection for the stored procedure specified.
Input	 :		@procedure	[database].[schema].ProcedureName.  If the database
							isn't provided then the current one is assumed. If
							the schema isn't provided then dbo is assumed.
History  :
   Date     Developer       Description
——————————  ——————————————  ————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@cmd	nvarchar(4000)
,	@code	nvarchar(max)
,	@dbName	sysname
,	@FF		char(1)
,	@id		int
,	@len	int
,	@name	sysname
,	@schema	sysname
,	@start	int

create table #defaults
	(	parameter	sysname
	,	value		sysname	null
	);

--	extract the object name parts...
select	@name	= parsename(@procedure, 1)
	,	@schema	= isnull(parsename(@procedure, 2), 'dbo')
	,	@dbName	= isnull(parsename(@procedure, 3), db_name())
	,	@FF		= char(12)

--	setup the command to collect the ObjectId and SQL code
set	@cmd	= 'use ' + @dbName + ';
select	@code	= isnull(object_definition(object_id(@procedure)), '''')
	,	@id		= object_id(@procedure);'

exec sp_executesql	@cmd
				,	N'@procedure sysname, @id int output, @code nvarchar(4000) output'
				,	@procedure
				,	@id		output
				,	@code	output;

--	parse the code to get default values
--	standardize the row delimeter to a form feed
set	@code = replace(@code, char(10), @FF);	--	replace cariage return
set	@code = replace(@code, char(13), @FF);	--	replace line feed

--	replace duplicates...
while charindex(@FF + @FF, @code) > 0
begin
	set	@code = replace(@code, @FF + @FF, @FF);
end

--	remove any inline comments
while (charindex('--', @code) > 0 and charindex(@FF, @code) > 0)
begin
	set	@start	= charindex('--', @code);
	set	@len	= charindex(@FF, @code, @start) - @start;
	if @len < 0 break;
	set	@code	= replace(@code, substring(@code, @start, @len), '');
end

--	remove any block comments
while (charindex('/*', @code) > 0 and charindex('*/', @code) > 0)
begin
	set	@start	= charindex('/*', @code);
	set	@len	= (charindex('*/', @code, @start) + 2) - @start;
	if @len < 0 break;
	set	@code	= replace(@code, substring(@code, @start, @len), '');
end

--	remove Tab, CR and LF characters
set	@code	= replace(replace(replace(replace(@code, char(9), ' '), @FF, ' '), '[', ''), ']', '');

--	remove out and output directives
set	@code	= replace(replace(@code, ' out ', ' '), ' output ', ' ');

--	find the end of the procedure "header"
set	@code	= left(@code, charindex(' as ', @code));
set	@code	= ltrim(rtrim(substring(@code, charindex(@name, @code) + len(@name) + 1 ,len(@code))));

--	remove procedure options for recompile, execute as or encryption...
if charindex(' with ', @code) > 0
begin
	set	@code = rtrim(left(@code, charindex(' with ', @code)));
end

--	remove double spaces with single spaces...
while charindex('  ', @code) > 0
begin
	set @code = replace(@code, '  ', ' ');
end
--	collect the parameters and defaults
insert	#defaults
select	parameter		=	'@' + rtrim(left(value, charindex(' ', value)))
	,	default_value	=	case charindex('=', value)
							when 0 then null
							else ltrim(rtrim(substring(value, charindex('=', value) + 1, 255))) end
from	tcu.fn_split(@code, '@')

--	remove any trailing spaces...
update	#defaults
set		value = rtrim(left(value, len(value) -1))
where	charindex(',', value) > 0

--	return the parameters
set	@cmd = 'use ' + @dbName + ';
select	procName		= db_name() + ''.'' + schema_name(schema_id) + ''.'' + name
	,	numberOfParams	= (select count(1) + 1 from sys.parameters where object_id = @id)
	,	isEncrypted		= case len(@code) when 0 then 1 else 0 end
from	sys.procedures	o
where	o.object_id		= @id
and		o.type			= ''p''
and		o.is_ms_shipped	= 0;'

exec sp_executesql	@cmd
				,	N'@id int, @code nvarchar(4000)'
				,	@id
				,	@code;

set	@cmd = 'use ' + @dbName + ';
select	name		= ''return_value''
	,	t.dbType
	,	type		= t.dataType
	,	direction	= 6
	,	size		= 4
	,	precision	= 10
	,	scale		= 0
	,	value		= null
	,	sequence	= 0
from	sys.procedures			o
	,	' + db_name() + '.dev.DataType	t
where	o.object_id		= @id
and		o.type			= ''p''
and		o.is_ms_shipped	= 0
and		t.dataType		= ''int''

union all

select	p.name
	,	t.dbType
	,	type		= t.dataType
	,	direction	= case p.is_output when 1 then 3 else 1 end
	,	size		= p.max_length / case when st.name in (''nvarchar'',''nchar'',''ntext'') then 2 else 1 end
	,	p.precision
	,	p.scale
	,	d.value
	,	sequence	= p.parameter_id
from	sys.procedures	o
join	sys.parameters	p
		on	o.object_id = p.object_id
join	sys.types		st	
		on	p.system_type_id = st.user_type_id
left join
		' + db_name() + '.dev.DataType	t
		on	st.name	= t.dataType
left join	#defaults	d
		on	p.name = d.parameter
where	o.object_id		= @id
and		o.is_ms_shipped	= 0
and		o.type			= ''P''
order by 9;'

exec sp_executesql	@cmd
				,	N'@id int'
				,	@id;

drop table #defaults;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [dev].[Procedure_getParameters]  TO [public]
GO
GRANT  EXECUTE  ON [dev].[Procedure_getParameters]  TO [wa_WWW]
GO
GRANT  EXECUTE  ON [dev].[Procedure_getParameters]  TO [wa_Services]
GO