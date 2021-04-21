use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[util_ListIndexesColumns]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [ops].[util_ListIndexesColumns]
GO
setuser N'ops'
GO
CREATE view ops.util_ListIndexesColumns
as

select	s.schema_id
	,	schema_name		= s.name
	,	o.object_id
	,	object_name		= o.name
	,	i.index_id
	,	index_name		= i.name
	,	i.type
	,	i.type_desc
	,	p.rows
	,	p.size_mb
	,	i.is_unique
	,	i.is_primary_key
	,	i.is_unique_constraint
	,	ic.index_column_id
	,	ic.key_ordinal
	,	ic.partition_ordinal
	,	c.column_id
	,	column_name		= c.name
	,	ic.is_included_column
	,	ic.is_descending_key
	,	c.system_type_id
	,	data_type		= t.name
	,	c.max_length
	,	c.precision
	,	c.scale
	,	c.is_nullable
	,	c.is_identity
	,	c.is_computed
from	sys.objects		o
join	sys.schemas		s
		on	o.schema_id = s.schema_id
join	sys.indexes		i
		on	o.object_id = i.object_id
join(	select	object_id
			,	index_id
			,	rows	= sum(row_count)
			,	size_mb	= convert(numeric(19,3), sum(in_row_reserved_page_count + lob_reserved_page_count + row_overflow_reserved_page_count) / 128.000)
		from	sys.dm_db_partition_stats
		group by object_id, index_id
	)	p	on	i.object_id	= p.object_id
			and	i.index_id	= p.index_id
join	sys.index_columns	ic
		on	i.object_id	= ic.object_id
		and	i.index_id	= ic.index_id
join	sys.columns		c
		on	ic.column_id = c.column_id
		and	ic.object_id = c.object_id
join	sys.types		t
		on	c.system_type_id = t.user_type_id
where	s.name	!= N'sys';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO