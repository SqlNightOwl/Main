use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[crm].[owner_campaign_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [crm].[owner_campaign_process]
GO
setuser N'crm'
GO
CREATE procedure crm.owner_campaign_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	08/26/2009
Purpose  :	Loads the campaign files and creates the owner_campaign records in
			Onyx/TTS.
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
,	@fileId		int
,	@fileMask	varchar(50)
,	@result		int
,	@uncFolder	varchar(255)
,	@switches	varchar(255)

--	initialize the variables...
select	@actionCmd	= 'Onyx6_0.sync.owner_campaign'
	,	@actionFile	= f.FileName
	,	@fileMask	= f.FileName
	,	@uncFolder	= p.SQLFolder
	,	@switches	= '-f"' + tcu.fn_UNCFileSpec(p.SQLFolder + p.FormatFile) + '" -T'
	,	@detail		= ''
	,	@fileId		= 0
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId	= p.ProcessId
where	f.ProcessId	= @ProcessId;

--	search for the files...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @uncFolder
						,	@fileMask			= @fileMask
						,	@includeSubFolders	= 0;

--	load any files that are found...
if exists (	select	top 1 * from tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId
			and		FileId		> @fileId	)
begin
	--	clear old data and reset the identity column...
	truncate table Onyx6_0.sync.owner_campaign;

	--	loop thru the files found and load each individually...
	while exists (	select	top 1 * from tcu.FileLog
					where	ProcessId	= @ProcessId
					and		RunId		= @RunId
					and		FileId		> @fileId	)
	begin
		--	get the next file to load...
		select	top 1
				@actionFile	= Path + '\' + FileName
			,	@fileId		= FileId
		from	tcu.FileLog
		where	ProcessId	= @ProcessId
		and		RunId		= @RunId
		and		FileId		> @fileId
		order by FileId;

		--	load the file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail output;

		if @result = 0 and len(@detail) = 0
		begin
			--	archive the file...
			exec tcu.File_archive	@Action			= 'move'
								,	@SourceFile		= @actionFile
								,	@ArchiveDate	= null
								,	@Detail			= @detail output
								,	@OverWrite		= 1
		end;
		else
		begin
			--	set the result to failure...
			set	@result = 1;	--	failure
			break;
		end;
	end;

	--	load the campaigns if no errors...
	if @result = 0
	begin
		--	reset the variables...
		select	@detail		= ''
			,	@result		= 0
			,	@actionCmd	= 'exec Onyx6_0.sync.owner_campaign_load'

		--	load the members into the campaign...
		exec Onyx6_0.sync.owner_campaign_load	@detail = @detail out
											,	@result = @result out;

	end;
end;

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