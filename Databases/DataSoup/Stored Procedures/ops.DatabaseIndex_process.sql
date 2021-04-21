use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[DatabaseIndex_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[DatabaseIndex_process]
GO
setuser N'ops'
GO
CREATE procedure ops.DatabaseIndex_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	03/10/2009
Purpose  :	Reorganizes the database indexes associated with this process.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@dbName	sysname
,	@detail	varchar(4000)
,	@proc	sysname
,	@result	int
,	@row	int
,	@start	datetime

declare	@dbList	table
	(	dbName	sysname
	,	row		int primary key
	);

--	initialize the variables...
select	@proc	= 'ops.' + object_name(@@procid)
	,	@detail	= ''
	,	@row	= 0
	,	@start	= getdate();

--	collect the list of databases to "reorg"
insert	@dbList
select	value, row
from	tcu.fn_split(tcu.fn_ProcessParameter(@ProcessId, 'Database List'), ';')

--	loop thru the databases and reorgainze the indexes...
while exists (	select	top 1 * from @dbList
				where	row > @row	)
begin
	select	top 1
			@dbName	= dbName
		,	@row	= row
	from	@dbList
	where	row > @row
	order by row

	exec @result = ops.DatabaseIndex_reorganize	@dbName	= @dbName
											,	@debug	= 0;

	--	add the database to the list if errors occur...
	if @result != 0
	begin
		set	@detail = @detail + '<li>' + @dbName + '</li>'
	end;
break;
end;

--	record the errors...
if len(@detail) > 0
begin
	set	@result	= 3;	--	warning
	set	@detail = 'The following database(s) returned an error when reorganizing indexes using '
				+ 'the [ops].[DatabaseIndex_reorganize] stored procedure:'
				+ '<ul>' + @detail + '</ul>';

	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= @start
						,	@Result		= @result
						,	@Command	= @proc
						,	@Message	= @detail;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO