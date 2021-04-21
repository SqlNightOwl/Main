use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[audit].[OFAC_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [audit].[OFAC_process]
GO
setuser N'audit'
GO
CREATE procedure audit.OFAC_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/04/2008
Purpose  :	Process to export the OFAC data for Audits & Compliance.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
06/23/2008	Paul Hunter		Removed Process update code to disable the process
							as this is a feature of the Process_run based on a
							ProcessCategory of "On Demand".
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(50)
,	@message	varchar(255)
,	@result		int
,	@sqlFolder	varchar(255)

--	initialize the variables...
select	@sqlFolder	= SQLFolder
	,	@message	= replace(MessageBody, '#SQL_FOLDER#', SQLFolder)
	,	@detail		= ''
	,	@fileName	= ''
	,	@result		= 0
from	tcu.ProcessParameter_v
where	ProcessId = @ProcessId;

while exists (	select	top 1 FileName from tcu.ProcessFile
				where	ProcessId	= @ProcessId
				and		FileName	> @FileName	)
begin
	--	retrieve the bcp command information...
	select top 1
			@actionCmd	= db_name() + '.' + FileName
		,	@actionFile	= @sqlFolder + TargetFile
		,	@fileName	= FileName
	from	tcu.ProcessFile
	where	ProcessId	= @ProcessId
	and		FileName	> @FileName
	order by FileName;

	--	export the file...
	exec @result = tcu.File_bcp	@action		= 'out'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;

	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result	= 3;	--	warning
		break;				--	break out of the while loop
	end;
end;

--	set @detail to @message if no errors occur...
if @result = 0 and len(@detail) = 0
begin
	set	@detail = @message;
end

--	save the results.
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