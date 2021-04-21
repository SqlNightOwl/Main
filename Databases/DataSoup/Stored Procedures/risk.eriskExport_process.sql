use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[eriskExport_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[eriskExport_process]
GO
setuser N'risk'
GO
CREATE procedure risk.eriskExport_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/30/2007
Purpose  :	Create account output files for eRisk.
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
,	@result		int
,	@sqlFolder	varchar(255)
,	@viewName	varchar(255)

--	extract the account information from OSI...
exec risk.eriskAccount_extract;

--	export the risk rating update script and update the existing risk ratings...
exec @result = risk.eriskRiskRating_process	@RunId		= @RunId
										,	@ProcessId	= @ProcessId
										,	@ScheduleId	= @ScheduleId;

--	retrieve process parameter values
select	top 1 
		@sqlFolder	= SQLFolder
	,	@result		= 0
	,	@viewName	= ''
	,	@detail		= ''
from	tcu.ProcessParameter_v
where	ProcessId	= @ProcessId;

--	loop through each row in ProcessFile table
while exists (	select	top 1 * from tcu.ProcessFile
				where	ProcessId	= @ProcessId
				and		FileName	> @viewName
				and		TargetFile	!= 'SQL Script'	)
begin
	--	retrieve the next view to export as stored in the FileName column
	select	top 1
			@actionCmd	= db_name() + '.' + FileName
		,	@actionFile	= @sqlFolder + TargetFile
		,	@viewName	= FileName
	from	tcu.ProcessFile
	where	ProcessId	= @ProcessId
	and		FileName	> @viewName
	order by FileName;

	--	execute the command and collect the results
	exec @result = tcu.File_bcp	@action		= 'out'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;
	--	report any errors
	if @result != 0 or len(@detail) > 0 
	begin
		set	@result = 1;
		break;	--	stop producing the rest of the files.
	end;
end;	--	while loop through files in ProcessFile table

if @result != 0 or len(@detail) > 0 
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= @actionCmd
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