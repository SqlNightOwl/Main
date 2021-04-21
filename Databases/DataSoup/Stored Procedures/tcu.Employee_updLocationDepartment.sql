use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Employee_updLocationDepartment]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Employee_updLocationDepartment]
GO
setuser N'tcu'
GO
create procedure tcu.Employee_updLocationDepartment
	@ProcessId	smallint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 - Texans Credit Union - All Rights Reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/06/2008
Purpose  :	Updates records in the tcu.LocationDepartment table.
History  :
   Date		Developer		Description
——————————  ——————————————  ————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@error		int
,	@message	varchar(4000)
,	@proc		sysname 
,	@subject	varchar(125);

set	@proc	= db_name() + '.' + schema_name() + '.' + object_name(@@procid);

--	remove any old departments...
delete	tcu.LocationDepartment
where	DepartmentCode in (	select	ld.DepartmentCode
							from	tcu.LocationDepartment	ld
							left join
								(	select	distinct DepartmentCode
									from	tcu.Employee
									where	IsDeleted = 0
								)	ed	on	ld.DepartmentCode = ed.DepartmentCode
							where	ed.DepartmentCode is null	);

--	add new departments...
insert	tcu.LocationDepartment
select	0				as LocationId
	,	ed.DepartmentCode
	,	0				as Sequence 
	,	null			as group_code
from	tcu.LocationDepartment	ld
right join
	(	select	distinct DepartmentCode
		from	tcu.Employee
		where	IsDeleted = 0
	)	ed	on	ld.DepartmentCode = ed.DepartmentCode
where	ld.DepartmentCode is null;

--	report new departments added...
if exists (	select	top 1 * from tcu.LocationDepartment
			where	LocationId = 0	)
begin
	set	@message	= '';
	select	@message = @message + '<tr><td>' + DepartmentCode + '</td><td>' + Department + '</td></tr>'
	from(	select	distinct e.DepartmentCode, e.Department
			from	tcu.LocationDepartment	ld
			join	tcu.Employee			e
					on	ld.DepartmentCode = e.DepartmentCode
			where	ld.LocationId = 0
		)	new;

	set	@message	= '<p>The subject process has added the new Departments listed below to the default Location.  '
					+ 'Please research these and associate them with the correct Location.</p>'
					+ '<p><table><tr><th>Code</th><th>Department</th></tr>' + @message + '</table></p>';
	set	@subject	= 'TOM:' + cast(@ProcessId as varchar) + '-I HR Employee Sync - Phone List Location/Departments';

	exec tcu.Email_send	@subject	= @subject
					,	@message	= @message
					,	@sendTo		= 'tom-processops@texanscu.org'
					,	@asHtml		= 1;
end

set	@error = @@error;

PROC_EXIT:
if @error != 0
begin
	raiserror('An error occured while executing the procedure "%s"', 15, 1, @proc);
end

return @error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO