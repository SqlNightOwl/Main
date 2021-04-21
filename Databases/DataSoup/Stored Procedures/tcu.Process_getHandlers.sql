use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_getHandlers]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_getHandlers]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_getHandlers
	@ProcessType	char(3)
,	@dbName			sysname		= null
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/22/2007
Purpose  :	Returns a list of available objects for use as Process Handlers.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd	nvarchar(4000);

if @ProcessType = 'DTS'
begin
	--	create a table to catch the output from the stored procedures
	declare	@pkg table
		(	object		sysname  
		,	id			uniqueidentifier
		,	description	nvarchar(2048)
		,	createdate	datetime  
		,	folderid	uniqueidentifier
		,	size		int
		,	vermajor	int
		,	verminor	int
		,	verbuild	int
		,	vercomments	nvarchar(2048)
		,	verid		uniqueidentifier
		);

	--	extract the packages...
	insert @pkg exec msdb.dbo.sp_dts_listpackages '00000000-0000-0000-0000-000000000000';

	--	return an orderd list of DTS Packages
	select	distinct object
	from	@pkg
	where	left(object, 2)	!= 'z_'
	and		left(object, 3)	!= 'tmp'
	order by object;

end;

if @ProcessType = 'PRC'
begin
	set	@dbName = isnull(@dbName, rtrim(db_name()));
	if exists (	select	top 1 * from master.sys.databases
				where	name = @dbName	)
	begin
		set	@cmd	= 'select	''' + @dbName + ''' + ''.'' + s.name + ''.'' + p.name as object
from	' + @dbName + '.sys.procedures	p
join	' + @dbName + '.sys.schemas		s
		on	p.schema_id = s.schema_id
where	p.name like ''%process''
order by s.name, p.name;'

		exec sp_executesql @cmd;
	end;
end;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Process_getHandlers]  TO [wa_Process]
GO