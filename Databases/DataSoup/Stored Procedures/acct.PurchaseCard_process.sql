use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[acct].[PurchaseCard_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [acct].[PurchaseCard_process]
GO
setuser N'acct'
GO
CREATE procedure acct.PurchaseCard_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/07/2009
Purpose  :	Loads the Pruchase Card data file so that Accounting can create the
			file for importing into FTI.
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
,	@fileName	varchar(50)
,	@loadedOn	char(10)
,	@result		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)

--	initialize the variables...
select	@actionCmd	= db_name() + '.acct.PurchaseCard'
	,	@fileName	= f.FileName
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= '-f"' + tcu.fn_UNCFileSpec(p.SQLFolder + p.FormatFile) + '" -T'
	,	@detail		= ''
	,	@fileId		= 0
	,	@loadedOn	= convert(char(10), getdate(), 121)
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

begin try
	--	search for available files....
	exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
							,	@RunId				= @RunId
							,	@uncFolder			= @sqlFolder
							,	@fileMask			= @fileName
							,	@includeSubFolders	= 0;

	--	load the files....
	while exists (	select	top 1 FileId from tcu.FileLog
					where	ProcessId	= @ProcessId
					and		RunId		= @RunId
					and		FileId		> @FileId	)
	begin
		--	retrieve the next available file...
		select	top 1
				@actionFile	= Path + '\' + FileName
			,	@fileId		= FileId
		from	tcu.FileLog
		where	ProcessId	= @ProcessId
		and		RunId		= @RunId
		and		FileId		> @FileId
		order by FileId;

		--	load the file...
		exec @result = tcu.File_bcp	@action		= 'in'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= @switches
								,	@output		= @detail output;

		--	archive if no errors...
		if @result = 0 and len(@detail) = 0
			exec tcu.File_archive	@Action			= 'move'
								,	@SourceFile		= @actionFile
								,	@ArchiveDate	= @loadedOn
								,	@Detail			= @detail output
								,	@AddDate		= 0
								,	@OverWrite		= 1;
		else	--	report any errors...
		begin
			set	@result = 1;	--	failure
			break;
		end;
	end;	--	retrieve the next file...

	--	reset the variable for reporting purposes...
	if @result = 0
		select	@actionCmd	= ''
			,	@detail		= 'A new Purchase card file is available for loading.'
			,	@result		= 2;	--	information
end try
begin catch
	--	collect the standard error message...
	exec tcu.ErrorDetail_get @detail out;
	set @result = 1;	--	failure
end catch;

PROC_EXIT:
if @result != 0
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