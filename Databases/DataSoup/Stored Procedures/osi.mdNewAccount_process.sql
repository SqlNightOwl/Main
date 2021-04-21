use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[mdNewAccount_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[mdNewAccount_process]
GO
setuser N'osi'
GO
CREATE procedure osi.mdNewAccount_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/07/2008
Purpose  :	Used to Exports new commercial accounts for MicroDynamics.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@result		int;

--	setup the source command and target file
select	@actionCmd	= 'select Value from ' + db_name() + '.osi.mdNewAccounts_v' 
	,	@actionFile	= p.FTPFolder + f.FileName
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	export any new accounts
if exists (	select top 1 * from osi.mdNewAccounts_v )
begin
	--	execute the command and collect the results
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;
end

if @result != 0 or len(@detail) > 0
begin
	set	@result = 1;
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
						,	@Message	= @detail;
end

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO