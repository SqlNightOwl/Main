use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ftiALMExtract_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ftiALMExtract_process]
GO
setuser N'osi'
GO
create procedure osi.ftiALMExtract_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/04/2010
Purpose  :	Loads the OSI FTI/ALM Extract files.
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
,	@fileName	varchar(255)
,	@files		int
,	@fileType	char(3)
,	@result		int
,	@rowId		int
,	@switches	varchar(255)

--	initialize the variables...
select	@actionCmd	= db_name() + '.osi.ftiALMExtract'
	,	@files		= count(f.FileName)
	,	@switches	= '-b100000 -f"' + max(p.SQLFolder + p.FormatFile) + '" -T'
	,	@actionFile	= ''
	,	@detail		= ''
	,	@fileName	= ''
	,	@result		= 0
	,	@rowId		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	check to see if the correct number of files were produced...
if(	select	count(FileName) from tcu.ProcessOSILog_v
	where	RunId		= @RunId
	and		ProcessId	= @ProcessId ) = @files
begin
	--	clear and reset the table for this run...
	truncate table osi.ftiALMExtract;
	alter index all on osi.ftiALMExtract rebuild;

	--	loop thru the log and load each file
	while exists (	select	top 1 FileName from tcu.ProcessOSILog_v
					where	RunId		= @RunId
					and		ProcessId	= @ProcessId
					and		FileName	> @fileName	)
	begin
		--	retrieve the next file from the log...
		select	top 1
				@actionFile	= FileSpec
			,	@fileName	= FileName
			,	@fileType	= left(FileName, 3)
			,	@rowId		= ProcessOSILogId
		from	tcu.ProcessOSILog_v
		where	RunId			= @RunId
		and		ProcessId		= @ProcessId
		and		ProcessOSILogId	> @rowId
		order by ProcessOSILogId;

		--	import the file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail out;

		--	update the relevant fields from data in the file...
		update	osi.ftiALMExtract
		set		Account	 =	cast(left(Record, 22) as bigint)
			,	StatusCd =	case @fileType
							when 'DML' then substring(Record, 128, 1)
							else substring(Record, 131, 1)
							end
			,	FileType =	@fileType
		where	Account = 0;
	end;
end;
else
begin
	select	@detail	= 'The subject OSI Application has completed but produced no files.'
		,	@result	= 3;	--	warning...
end;


PROC_EXIT:
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