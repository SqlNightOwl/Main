use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[ops].[SysMailCleanup_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [ops].[SysMailCleanup_process]
GO
setuser N'ops'
GO
CREATE procedure ops.SysMailCleanup_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/16/2008
Purpose  :	Cleans up the Datadase Mail mail items history.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cutOff		datetime
,	@retention	int

set	@retention = cast(tcu.fn_ProcessParameter(@ProcessId, 'Retention Period') as int) * -1;

set	@cutOff = convert(char(10), dateadd(day, @retention, getdate()), 121);

--	delete the mail items...
exec msdb.dbo.sysmail_delete_mailitems_sp @sent_before = @cutOff;

--	delete the log...
exec msdb.dbo.sysmail_delete_log_sp @cutOff;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO