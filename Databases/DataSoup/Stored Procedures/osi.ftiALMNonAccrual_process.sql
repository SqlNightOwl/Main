use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ftiALMNonAccrual_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ftiALMNonAccrual_process]
GO
setuser N'osi'
GO
create procedure osi.ftiALMNonAccrual_process
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
Purpose  :	Loads the OSI FTI/ALM Extract files and the non-accrual corrections
			file from Accounting.  The corrections are applied to the OSI files
			and then those files are re-exported.
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
,	@files		int
,	@fileType	char(3)
,	@FIX_TYPE	char(3)
,	@ftpFolder	varchar(255)
,	@result		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)

--	initialize the variables...
select	@actionCmd	= db_name() + '.osi.ftiALMExtract'
	,	@fileName	= f.FileName
	,	@ftpFolder	= p.FTPFolder
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= '-b100000 -f"' + p.SQLFolder + p.FormatFile + '" -F2 -T'
	,	@actionFile	= ''
	,	@detail		= ''
	,	@FIX_TYPE	= 'FIX'
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	search for the Accounting corrections file...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	load the file if it was found...
if exists (	select	top 1 * from tcu.FileLog
			where	RunId		= @RunId
			and		ProcessId	= @ProcessId )
begin
	--	retrieve the file from the log...
	select	top 1
			@actionFile	= Path + '\' + FileName
	from	tcu.FileLog
	where	RunId		= @RunId
	and		ProcessId	= @ProcessId
	and		FileId		= 1;

	--	import the file...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail out;

	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT;
	end;

	--	archive the Accounting file...
	exec @result = tcu.File_archive	@Action			= 'move'
								,	@SourceFile		= @actionFile
								,	@ArchiveDate	= null
								,	@Detail			= @detail out
								,	@AddDate		= 0
								,	@OverWrite		= 1;

	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT;
	end;

	--	update the account, status and file type for the 
	update	osi.ftiALMExtract
	set		Account	 = cast(Record as bigint)
		,	StatusCd = 'Y'
		,	FileType = @FIX_TYPE
	where	Account = 0;

	--	update the non-accrual flag in the matching records...
	update	u
	set		StatusCd =	f.StatusCd
		,	Record	 =	case u.FileType
						when 'DML' then stuff(Record, 128, 1, f.StatusCd)
						else stuff(Record, 131, 1, f.StatusCd)
						end
	from	osi.ftiALMExtract				u
	join(	select	Account, StatusCd
			from	osi.ftiALMExtract
			where	FileType = @FIX_TYPE)	f
			on	u.Account = f.Account
	where	u.StatusCd != f.StatusCd;

	--	reset the variables and get the base file name
	select	@fileType	= ''
		,	@fileName	= tcu.fn_ProcessParameter(@ProcessId, 'Fix File');
		
	--	retrieve and export each updated file type...
	while exists (	select	top 1 FileType from osi.ftiALMExtract
					where	FileType	>	@fileType
					and		FileType	!=	@FIX_TYPE	)
	begin
		--	retrieve the next file...
		select	top 1
				@actionCmd	= 'select Record from ' + db_name() + '.osi.ftiALMExtract '
							+ 'where FileType = ''' + FileType + ''' order by RecordId'
			,	@actionFile	= @ftpFolder + replace(@fileName, '[TYPE]', FileType)
			,	@fileType	= FileType
			,	@switches	= '-c -T'
		from	osi.ftiALMExtract
		where	FileType	>	@fileType
		and		FileType	!=	@FIX_TYPE
		order by FileType;

		--	export it....
		exec @result = tcu.File_bcp	@action		= 'queryout'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= '-c -T'
								,	@output		= @detail out;

		if @result != 0 or len(@detail) > 0
		begin
			set	@result = 1;	--	failure
			goto PROC_EXIT;
		end;
	end;
end;
else
begin
	select	@detail	= 'The Accounting file for subject Process could not be found.'
		,	@result	= 1;	--	failure...
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