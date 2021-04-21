use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_checkProcessType]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_checkProcessType]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_checkProcessType
	@ProcessName	sysname
,	@ProcessType	char(3)		out
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/20/2007
Purpose  :	Returns the type of object connected with the specified process name.
History	 :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
08/28/2008	Paul Hunter		Changed proceudre to use sys.objects/schemas tables
							instead of the information_schema views.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on
set	ansi_warnings off

declare
	@cmd	nvarchar(4000)

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
	)

--	intialize the default return type
set	@ProcessType = 'n/a'

--	extract the packages
insert @pkg exec msdb.dbo.sp_dts_listpackages '00000000-0000-0000-0000-000000000000'
/*
--	return an orderd list of DTS Packages
select	distinct object
from	@pkg
where	left(object, 2)	!= 'z_'
and		left(object, 3)	!= 'tmp'
order by object
*/
--	check if it's a DTS Package first.
if exists ( select	top 1 object from @pkg
			where	object = @ProcessName )
begin
	set	@ProcessType = 'DTS'
end
else
begin
	--	pull out the database, owner and procedure name
	set	@cmd	= 'select	@ProcessType = ''PRC'' '
				+ 'from	' + parsename(@ProcessName, 3) + '.sys.objects o '
				+ 'join	' + parsename(@ProcessName, 3) + '.sys.schemas s '
				+ 'on o.schema_id = s.schema_id '
				+ 'where	o.name	= ''' + parsename(@ProcessName, 1) + ''' '
				+ 'and		s.name	= ''' + parsename(@ProcessName, 2) + ''' '
				+ 'and		o.type	= ''p'' '
				+ 'and		o.is_ms_shipped = 0';

	exec sp_executesql @cmd
					, N'@ProcessType char(3) out'
					, @ProcessType out;
end

return @@error
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO
GRANT  EXECUTE  ON [tcu].[Process_checkProcessType]  TO [wa_Process]
GO