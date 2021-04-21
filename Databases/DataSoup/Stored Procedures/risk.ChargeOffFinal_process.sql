use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[ChargeOffFinal_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[ChargeOffFinal_process]
GO
setuser N'risk'
GO
CREATE procedure risk.ChargeOffFinal_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/23/2009
Purpose  :	Loads the board approved Final Charge Off list of accounts, produces and
			OSI update script, archives the source file & update script.
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
,	@fileName	varchar(50)
,	@lastDate	varchar(10)
,	@result		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)
,	@targetFile	varchar(255)

--	initialize the working variables...
select	@actionCmd	= db_name() + '.risk.ChargeOffFinal'
	,	@actionFile	= p.SQLFolder + f.FileName
	,	@fileName	= f.TargetFile
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= '-f"' + p.SQLFolder + p.FormatFile + '" -T'
	,	@targetFile	= p.SQLFolder + f.TargetFile
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	if the file exists then load it...
if tcu.fn_FileExists(@actionFile) = 1
begin
	--	initialize the last date loans were charged off...
	select	@lastDate = isnull(convert(varchar(10), max(LoadedOn), 121), '2000-01-01')
	from	risk.ChargeOffFinal;

	--	load the file...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail out;
	--	no errors so proceed...
	if @result = 0 and len(@detail) = 0
	begin
		--	continue if there are account that haven't been charged off...
		if exists (	select	top 1 AccountNumber from risk.ChargeOffFinal
					where	LoadedOn > cast(@lastDate as datetime)	)
		begin
			--	get the "new" Load date...
			select	@lastDate = convert(varchar(10), max(LoadedOn), 121)
			from	risk.ChargeOffFinal;

			--	archive the file...
			exec tcu.File_archive	@Action			= 'move'
								,	@SourceFile		= @actionFile
								,	@ArchiveDate	= @lastDate
								,	@Detail			= @detail out
								,	@AddDate		= 1
								,	@OverWrite		= 1;

			select	@actionCmd	= 'select Script from ' + db_name()
								+ '.risk.ChargeOffFinal_vScript '
								+ 'where LoadedOn = cast(''' + @lastDate + ''' as datetime) ' 
								+ 'order by AccountNumber, StatementLine'
				,	@actionFile	= @targetFile
				,	@switches	= '-c -T';

			--	export the OSI update script...
			exec @result = tcu.File_bcp	@action		= 'queryout'
									,	@actionCmd	= @actionCmd
									,	@actionFile	= @actionFile
									,	@switches	= @switches
									,	@output		= @detail out;	

			--	archive the OSI update script...
			exec tcu.File_archive	@Action			= 'copy'
								,	@SourceFile		= @actionFile
								,	@ArchiveDate	= @lastDate
								,	@Detail			= @detail out
								,	@AddDate		= 1
								,	@OverWrite		= 1;

			if @result = 0 and len(@detail) = 0
			begin
				--	set the result and build the return message....
				select	@result	=	case len(@detail) when 0 then 0 else 2 end	--	success or information
					,	@detail	=	'<p>The subject process has completed and the OSI update script "'
								+	@fileName + '" is available in the <a href="' + @sqlFolder
								+	'">working folder</a>.</p>';
			end;
		end;
	end;	--	records loaded
	else
	begin
		set @result = 1;	--	failure
	end;	--	
end;		--	file exists

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