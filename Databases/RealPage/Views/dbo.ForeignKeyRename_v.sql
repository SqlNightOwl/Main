SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE view dbo.ForeignKeyRename_v
as
select	'if object_id(N''' + d.KeyName + ''') is not null
	alter table ' + d.ParentObject + ' drop constraint ' + d.name + ';'				as [1 Drop Constraint]
	,	'alter table ' + d.ParentObject + ' with nocheck
	add constraint ' + d.NewName + ' foreign key ( '
	+	stuff((	select	',' + c.name
				from	sys.foreign_key_columns	kc
				join	sys.columns c
						on	c.object_id = kc.parent_object_id
						and c.column_id	= kc.parent_column_id
				where	kc.constraint_object_id = d.object_id
				and		kc.parent_object_id		= d.parent_object_id
				order by kc.constraint_column_id
				for xml path('')), 1, 1, '') + ' )
	references ' + d.ReferencedObject + ' ( '
	+	stuff((	select	',' + c.name
				from	sys.foreign_key_columns	kc
				join	sys.columns c
						on	c.object_id = kc.referenced_object_id
						and c.column_id	= kc.referenced_column_id
				where	kc.constraint_object_id = d.object_id
				and		kc.referenced_object_id	= d.referenced_object_id
				order by kc.constraint_column_id
				for xml path('')), 1, 1, '') + ' );'			as [2 Create Constraint]
	,	'alter table ' + d.ParentObject + ' check constraint ' + d.NewName + ';'	as [3 Check Constraint]
	,	d.*
from(	select	k.*
			,	s.name + '.' + k.name				as KeyName
			,	s.name + '.' + quotename(p.name)	as ParentObject
			,	s.name + '.' + quotename(r.name)	as ReferencedObject
			,	stuff(k.BaseName, charindex('_', k.BaseName), 1, '_has_') as NewName
		from(	select	*, replace(name, 'FK_', '') as BaseName
				from	sys.foreign_keys )	k
		join	sys.schemas			s
				on	k.schema_id = s.schema_id
		join	sys.objects			p
				on	p.object_id = k.parent_object_id
		join	sys.objects			r
				on	r.object_id = k.referenced_object_id ) d;
GO
