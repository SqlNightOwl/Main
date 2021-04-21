SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view dbo.OMSDupicateObjects
as
select	schema_name(schema_id) +'.'+ o.name as FQON
	,	o.*
from	sys.objects o
join(	--	duplicate object names
		select	name, count(1) as items
		from	sys.objects
		where	is_ms_shipped	 = 0
		and		type			!= 'X'
		group by name
		having count(1) > 1 ) d 
		on	o.name = d.name
where	type in ('U','FN','TF','P');
GO
