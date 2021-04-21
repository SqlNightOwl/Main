use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[dev].[FindText]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [dev].[FindText]
GO
setuser N'dev'
GO
CREATE procedure dev.FindText
	@Value1		varchar(255)
,	@Value2		varchar(255)	= null
,	@Value3		varchar(255)	= null
,	@Value4		varchar(255)	= null
,	@Value5		varchar(255)	= null
,	@Value6		varchar(255)	= null
as

set nocount on

declare
	@astext	int
,	@proc	varchar(255)
,	@row	int
,	@rows	int
,	@sql	nvarchar(510)
,	@type	varchar(20)

declare @list	table
	(	name		varchar(255)
	,	[schema]	varchar(50)
	,	type		varchar(20)
	,	row			int identity	)

if isnumeric(isnull(@Value1, '')) = 1
begin
	set	@astext	= case when cast(@Value1 as int) != 0 then 1 end
	set	@Value1	= '%'
end
else
begin
	set	@astext = 0
end

if nullif(rtrim(@Value1),'') is not null
	set @Value1 = '%' + @Value1 + '%'
else
	return 1

set @Value2 = '%' + isnull(@Value2,'') + '%'
set @Value3 = '%' + isnull(@Value3,'') + '%'
set @Value4 = '%' + isnull(@Value4,'') + '%'
set @Value5 = '%' + isnull(@Value5,'') + '%'
set @Value6 = '%' + isnull(@Value6,'') + '%'

--	tables
insert	@list 
select	distinct
		o.name
	,	schema_name(o.[schema_id])
	,	o.type
from	sys.objects	o
where	o.is_ms_shipped	= 0
and		o.type	=	'u'
and		o.name	like @value1
and		o.name	like @value2
and		o.name 	like @value3
and		o.name	like @value4
and		o.name	like @value5
and		o.name	like @value6

--	table columns
insert	@list 
select	distinct
		o.name + '.' + c.name
	,	schema_name(o.[schema_id])
	,	'c'
from	sys.columns	c
join	sys.objects	o
		on	c.object_id = o.object_id
where	o.is_ms_shipped	= 0
and		o.type	=	'u'
and		c.name	like @value1
and		c.name	like @value2
and		c.name	like @value3
and		c.name	like @value4
and		c.name	like @value5
and		c.name	like @value6

--	scriptable objects
insert	@list 
select	distinct
		o.name
	,	schema_name(o.[schema_id])
	,	o.type
from	dbo.syscomments	c
join	sys.objects		o
		on	c.id = o.object_id
where	o.is_ms_shipped	= 0
and		o.type	in	('p','tr','v','fn','if','tf')
and		c.text	like @value1
and		c.text	like @value2
and		c.text	like @value3
and		c.text	like @value4
and		c.text	like @value5
and		c.text	like @value6

if @astext = 0
begin
	select	[schema]
		,	name
		,	type =	case type 
					when 'u'	then 'Table'
					when 'c'	then 'Column'
					when 'p'	then 'Procedure'
					when 'tr'	then 'Trigger'
					when 'v'	then 'View'
					when 'fn'	then 'Function'
					when 'if'	then 'Function'
					when 'tf'	then 'Function'
					else 'Unknown'
					end
	from	@list
	order by [schema], name

end
else if exists (select 1 from @list)
begin

	select	@row	= 1
		,	@rows	= count(1)
	from	@list

	create table #text
		(	id		int identity
		,	text	varchar(255))

	while @row <= @rows
	begin

		select	@proc =	[schema] + '.' + name
			,	@type =	case type
						when 'u'	then 'Table'
						when 'c'	then 'Column'
						when 'p'	then 'Procedure'
						when 'tr'	then 'Trigger'
						when 'v'	then 'View'
						when 'fn'	then 'Function'
						when 'if'	then 'Function'
						when 'tf'	then 'Function'
						else 'Unknown' end
		from	@list
		where	@row = row

		insert #text(text) select '--	BEGIN OBJECT:	' + @proc + '	-	' + @type
		insert #text(text) select replicate('-',80)
		insert #text(text) values ('')

		if @type not in ('Table', 'Column')
		begin

			set @sql = 'insert #text(text) exec sp_helptext ''' + @proc + ''''
			exec sp_executesql @sql

			insert #text(text) values ('')
			insert #text(text) select '--	END OBJECT:	' + @proc
			insert #text(text) select replicate('-',80)
			insert #text(text) values ('')

		end

		set @row = @row + 1

	end

	select text	as 'Search Results'
	from 	#text
	order by id

	drop table #text

end -- if exists

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO