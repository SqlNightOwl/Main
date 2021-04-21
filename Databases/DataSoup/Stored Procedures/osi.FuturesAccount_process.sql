use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[FuturesAccount_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[FuturesAccount_process]
GO
setuser N'osi'
GO
CREATE procedure osi.FuturesAccount_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/09/2008
Purpose  :	Process used to convert Futures accounts to regular checking accounts.
			Phase 1:	Identify and create a mailing list of candidate accounts
						for the prior month.
			Phase 2:	Create the update script to execute on OSI that converts
						the accounts.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@action		varchar(500)
,	@actionCmd	varchar(500)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(255)
,	@fileName	varchar(50)
,	@offset		int
,	@result		int
,	@sqlFolder	varchar(255)
,	@today		datetime
,	@viewName	varchar(50);

--	set the number of months offset to used when calculating the period...
set	@offset	= case @ScheduleId when 1 then -1 else -2 end;

--	initialize the variables
select	@action		= case f.ApplName when 'Mailing' then 'out' else 'queryout' end
	,	@actionCmd	= case f.ApplName when 'Mailing' then db_name() + '.' + f.FileName else '' end
	,	@archFile	= p.SQLFolder + 'archive\'
					+ replace(f.TargetFile, '[PERIOD]', convert(char(7), dateadd(month, @offset, getdate()), 121))
	,	@fileName	= replace(f.TargetFile, '.[PERIOD]', '')
	,	@sqlFolder	= p.SQLFolder
	,	@viewName	= f.FileName
	,	@detail		= ''
	,	@result		= 0
	,	@today		= convert(varchar, getdate(), 101)
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId	= p.ProcessId
where	f.ProcessId		= @ProcessId
and		f.ApplFrequency	= @ScheduleId;	--	ApplFrequency containts the day on which the process should run

--	exist if there's nothing to do...
if @action is null return @result;

set	@actionFile	= @sqlFolder + @fileName;

--	we're in the scripting phase...
if @ScheduleId = 15
begin
	--	build the dynamic command of the individual script columns...
	select	@actionCmd	=	@actionCmd + name + ' + char(13) + char(10) + '
	from	sys.columns
	where	[object_id]	= object_id(@viewName)
	and		name		like '%SQL%';

	--	finish out building the command...
	set	@actionCmd	= 'select script = ' + @actionCmd
					+ '''commit;'' from ' + db_name() + '.' + @viewName;
end

--	execute the command...
exec @result = tcu.File_bcp	@action		= @action
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= '-c -T'
						,	@output		= @detail output;

--	success!
if @result = 0 and len(@detail) = 0
begin

	--	archive the file...
	exec @result = tcu.File_action	@action		= 'copy'
								,	@sourceFile	= @actionFile
								,	@targetFile	= @archFile
								,	@overWrite	= 1
								,	@output		= @detail output;

	--	sucessully archived...
	if @result = 0 and len(@detail) = 0
	begin
		--	report status...
		set	@detail	= 'The subject process has successfully run and the '
					+ case @ScheduleId when 1 then 'Mailing List' else 'SQL Update Script' end
					+ ' file ' + @fileName + ' is available in the <a href="' + @sqlFolder
					+ '">Futures Account</a> folder' +	case @ScheduleId when 1 then ''
														else ' and is ready to be run'
														end + '.';

		if @ScheduleId != 1
		begin
			--	set the result to information so opperaitons gets the message
			set	@result = 2;		-- information

			--	modify this schedule to run next month...
			update	tcu.ProcessSchedule
			set		BeginOn		=	case
									when BeginOn > @today then BeginOn
									else dateadd(month, 1, BeginOn)
									end
				,	EndOn		=	case
									when EndOn > @today then EndOn
									else dateadd(month, 1, EndOn)
									end
				,	UpdatedOn	=	getdate()
				,	UpdatedBy	=	tcu.fn_UserAudit()
			where	ProcessId	=	@ProcessId
			and		ScheduleId	=	@ScheduleId;
		end
	end
	else	--	report the Archive error...
	begin
		set	@result = 1;	--	failure
	end
end
else	--	report the BCP error...
begin
	set	@result = 1;		--	failure
end

--	report the completion...
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