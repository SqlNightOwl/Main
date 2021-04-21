use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromisedCardOnyx_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[CompromisedCardOnyx_process]
GO
setuser N'risk'
GO
CREATE procedure risk.CompromisedCardOnyx_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/28/2008
Purpose  :	Loads the returned Compromised Cards to be statused and calls the
			stored procedure to create incidents.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
12/22/2008	Paul Hunter		Changed to handle new Onyx procedure
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on

declare
	@actionCmd		varchar(500)
,	@actionFile		varchar(255)
,	@archFile		varchar(255)
,	@cmd			nvarchar(500)
,	@detail			varchar(4000)
,	@fileId			int
,	@fileName		varchar(50)
,	@handler		sysname
,	@handlerType	varchar(255)
,	@result			int
,	@sqlFolder		varchar(255)
,	@switches		varchar(255)

--	initialize the processing variables...
select	@actionCmd	= f.TargetFile
	,	@fileName	= f.FileName
	,	@handler	= tcu.fn_ProcessParameter(p.ProcessId, 'Secondary Handler')
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= '-T -F2 -f"'+ p.SQLFolder + p.FormatFile + '"'
	,	@detail		= ''
	,	@fileId		= 0
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId	= @ProcessId;

--	determine the process type and if handler is a valid type the ...
exec tcu.Process_checkProcessType @handler, @handlerType output;

if @handlerType != 'n/a'
begin
	set	@handler = N'exec @result = ' + @handler;
end
else
begin
	set	@result	= 1;	--	failure
	set	@detail	= 'The Process Type could not be determined for the handler ' + @handler + '.';
	goto PROC_EXIT;
end

--	see if a file is there...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	loop thru the files were and call the secondary handler to create the incidents...
while exists (	select	top 1 * from tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileId		> @fileId	)
begin
	--	retrieve the next file...
	select	top 1
			@actionFile	= Path + '\' + FileName
		,	@archFile	= Path + '\archive\' + FileName
		,	@fileId		= FileId
	from	tcu.FileLog
	where	ProcessId	= @ProcessId
	and		RunId		= @RunId
	and		FileId		> @fileId
	order by FileId;

	--	clear the old data...
	set	@cmd = N'truncate table ' + @actionCmd;
	exec sp_executesql @cmd;

	--	load the new data...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail output;

	--	the file loaded sucessfully...
	if @result = 0 and len(@detail) = 0
	begin
		--	execute the process to create the incidents...
		--	this should be Onyx6_0.cs.CompromisedCard_savIncident...
		exec @result = sp_executesql @handler
								,	N'@result int out'
								,	@result out;

		--	the handler appears to have run sucessfully...
		if @result = 0
		begin
			--	archive the file...
			exec @result = tcu.File_action	@action		= 'move'
										,	@sourceFile	= @actionFile
										,	@targetFile	= @archFile
										,	@overWrite	= 1
										,	@output		= @detail output;

			--	report any errors...
			if @result > 0 or len(@detail) > 0
			begin
				set	@result	= 1;	--	failure
			end	--	error
		end
		else	--	report any errors...
		begin
			set	@result		= 1;	--	failure
			set	@actionCmd	= 'Handler Error cmd: ' + @handler;
			goto PROC_EXIT;
		end
	end		--	handler success...
	else	--	report any errors...
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT;
	end		--	load error...
end			--	loop

PROC_EXIT:
if @result != 0 or len(@detail) > 0
begin
	--	the process failed or a message was generated.
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