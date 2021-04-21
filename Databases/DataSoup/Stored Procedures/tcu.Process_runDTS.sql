use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Process_runDTS]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [tcu].[Process_runDTS]
GO
setuser N'tcu'
GO
CREATE procedure tcu.Process_runDTS
	@RunId				int
,	@ProcessId			smallint
,	@ScheduleId			tinyint
,	@AlternateHandler	sysname		= null	--	handler to use if not from the process
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul unter
Created  :	09/24/2007
Purpose  :	Detail execution of DTS handler process called from stored procedure
			Process_run
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/23/2009	Paul Hunter		Removed calls to sp_configure to toggle xp_cmdshell.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@cmd			varchar(4000)
,	@detail		varchar(4000)
,	@handler		sysname
,	@parameters		varchar(255)
,	@processType	char(3)
,	@result			int
,	@started		datetime;

create table #processDTS
	(	record	varchar(500)
	,	row		int identity
	);

--	collect the handler and initialize variables
select	@handler	=	isnull(@AlternateHandler, ProcessHandler)
	,	@result		=	0
	,	@started	=	getdate()
	,	@parameters	=	case IncludeRunInfo
						when 1 then ' /A"RunId":"3"="'		+ cast(@RunId		as varchar) + '"'
								+	' /A"ProcessId":"2"="'	+ cast(@ProcessId	as varchar) + '"'
								+	' /A"ScheduleId":"16"="'+ cast(@ScheduleId	as varchar) + '"'
						else '' end
from	tcu.Process
where	ProcessId = @ProcessId;

--	check on the process type
exec tcu.Process_checkProcessType	@handler
								,	@processType out;

if @processType = 'DTS'
begin
	set	@cmd = 'dtsrun /E /S' + @@servername + ' /N"' + @handler + '" /Wtrue' + @parameters;

	--	turn xp_cmdshell on...
	--exec sp_configure	N'show advanced options', 1;	--	allow advanced options to be changed.
	--exec sp_executesql	N'reconfigure;'					--	update the configured values.
	--exec sp_configure	N'xp_cmdshell', 1;				--	enable the feature.
	--exec sp_executesql	N'reconfigure;'					--	update the configured values.

	insert #processDTS exec @result	= master.sys.xp_cmdShell @cmd;

	--	turn xp_cmdshell back off...
	--exec sp_configure	N'xp_cmdshell', 0;				--	disable the feature.
	--exec sp_configure	N'show advanced options', 0;	--	disable advanced options to be changed.
	--exec sp_executesql	N'reconfigure;'					--	apply the configured values.

	select	@result	= isnull(max(
						case
						when charindex('error', record)				> 0	then 1	--	Error
						when charindex('information only', record)	> 0	then 2	--	Information
						when charindex('warn', record)				> 0	then 3	--	Warning
						else 0 end), 0)											--	Success
	from	#processDTS;

	if @result > 0
	begin
		select	@detail = isnull(@detail, '') + isnull(Record, '') + char(13) + char(10)
		from 	#processDTS;
	end;
end
else	-- didn't find the DTS package with the specified name
begin
	set	@result	= 1;
	set	@detail	= 'The specified DTS package "' + @handler + '" does not exist in the database.';
end;

--	log the completion
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= @started
					,	@Result		= @result
					,	@Command	= @cmd
					,	@Message	= @detail;

drop table #processDTS;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO