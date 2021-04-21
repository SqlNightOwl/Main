SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create procedure dbo.ProcedureRename_getScript
as

set nocount on;

declare @FrontToBack	table
	(	row		smallint identity primary key
	,	prefix	varchar(50)
	,	suffix	varchar(25)
	);

insert	@FrontToBack
values	('Delete'			, 'del')
	,	('Drop'				, 'del')
	,	('Create'			, 'ins')
	,	('GetActive'		, 'getActive')
	,	('GetChild'			, 'getChild')
	,	('List'				, 'getList')
	,	('Retrieve'			, 'get')
	,	('Export'			, 'getForExport')
	,	('Information'		, 'getInformation')
	,	('For'				, 'getFor')
	,	('GetAll'			, 'getAll')
	,	('GetAvailable'		, 'getAvailable')
	,	('Available'		, 'getAvailable')
	,	('Get'				, 'get')
	,	('Reset'			, 'updReset')
	,	('Update'			, 'upd')
	,	('Set'				, 'upd')
	,	('By'				, 'getBy')
	,	('Details'			, 'getDetails')
	,	('Count'			, 'getCount')
	,	('Insert'			, 'ins')
	,	('Select'			, 'get')
	,	('Activate'			, 'activate')
	,	('Check'			, 'validate')
	,	('Copy'				, 'insCopy')
	,	('Add'				, 'ins')
	,	('Save'				, 'save')
	,	('Lookup'			, 'lookup')
	,	('Begin'			, 'begin')

select	b.OriginalName
	,	b.SchemaName
	,	b.OMSName
	,	b.BaseName
	,	case isnull(charindex(s.Prefix, b.BaseName), 0)
		when 0 then b.BaseName
		when 1 then replace(b.BaseName, s.prefix, '') + '_' + s.suffix
		else replace(b.BaseName, s.prefix, '_' + s.suffix)
		end			as New_Name
	,	isnull(s.suffix, '')	as RuleApplied
--into	dbo.ObjectNameMap
from(	--	basic standardization (806 objects)
		select	s.name					as SchemaName
			,	'dbo.' + o.name			as OriginalName
			,	s.name + '.' + o.name	as OMSName
			,	replace(
				replace(
				replace(
				replace(
				replace(
				replace(
				replace(
				replace(o.name	, 'usp'	+ s.name + '_', '')
								, 'sp'	+ s.name + '_', '')
								, 'Rep_', 'rpt_')
								, 'report_', 'rpt_')
								, 'CUSTOMERSREPORTS', 'rpt_')
								, 'CREDITS_', 'credits_')
								, '__', '')
								, 'usp', '')
					as BaseName
		from	sys.procedures	o
		join	sys.schemas		s
				on	o.schema_id = s.schema_id
		where	o.name not in ('usp_syncusers','usp_syncusers','usp_RebuildIndexes')
		and		o.name not like 'temp_usp_%'
		and		s.name not in ('OMS', 'Reports') 
		)	b
left
join	@FrontToBack				s
		on	charindex(s.Prefix	, b.BaseName) > 0
where(	s.row	= (	select	min(row) from @FrontToBack
					where	charindex(Prefix, b.BaseName) > 0 )
	or	s.row	is null )
order by 4, 3;

return;
GO
