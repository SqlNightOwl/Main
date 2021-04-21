use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[AccountAudit_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [audit].[AccountAudit_process]
GO
setuser N'audit'
GO
CREATE procedure audit.AccountAudit_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/10/2008
Purpose  :	Process to export the Account Audit file for Audits & Compliance.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(1000)
,	@actionFile	varchar(255)
,	@detail		varchar(8000)
,	@fileName	varchar(50)
,	@sqlFolder	varchar(255)
,	@result		int

--	initialized the process variables.
select	@actionCmd = db_name() + '.audit.AccountAudit_v'
	,	@actionFile	= p.SQLFolder + f.FileName
	,	@fileName	= f.FileName
	,	@sqlFolder	= p.SQLFolder
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	export the file
exec @result = tcu.File_bcp	@action		= 'out'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= '-c -t, -T'
						,	@output		= @detail output;

if @result = 0 and len(@detail) = 0
begin
	--	indicate where the file can be picked up...
	set	@detail = 'the Account Audit file ' + @fileName +  ' has been produced in the <a href="'
				+ @sqlFolder + '">Compliance folder</a>.';
end;
else
begin
	--	log the failure
	set	@result = 1;	--	failure
end;

exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= @actionCmd
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO