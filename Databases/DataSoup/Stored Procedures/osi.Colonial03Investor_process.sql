use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Colonial03Investor_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[Colonial03Investor_process]
GO
setuser N'osi'
GO
CREATE procedure osi.Colonial03Investor_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/25/2008
Purpose  :	Wrapper procedure to find the Colonial 03 (INV3614.DAT) files, calls 
			the load process (DTS/PRC) if a file is found and updates the process
			scheduel if the handler runs sucessfully.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/22/2008	Paul Hunter		Added file export logic of the target files (ALM, PV
							and Raddon).
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@crlf		char(2)
,	@detail		varchar(4000)
,	@detailGood	varchar(4000)
,	@fileName	varchar(255)
,	@lastOn		datetime
,	@nextOn		datetime
,	@result		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)
,	@type		char(3)

--	exit if the most recent payment is for the prior month
select	@lastOn	= max(cast('20' + right(LastPaymentPosted, 2)
				+ left(LastPaymentPosted, 4) as datetime))
from	osi.Colonial03Investor
where	LastPaymentPosted != '000000';

--	no new data is available...
if datediff(month, @lastOn, getdate()) = 1
 	return @@error;

--	initialize the processing variables
select	@actionCmd	= db_name() + '.osi.Colonial03Investor'
	,	@actionFile	= p.SQLFolder + f.FileName
	,	@archFile	= p.SQLFolder + 'archive\'
					+ convert(char(6), dateadd(month, -1, getdate()), 112) + ' ' + f.FileName
	,	@fileName	= f.FileName
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= '-T -f"' + p.SQLFolder + p.FormatFile + '"'
	,	@crlf		= char(13) + char(10)
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId		= @ProcessId
and		f.TargetFile	is null;

--	see if the file is there
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	if the file was found then call the secondary handler
if exists (	select	top 1 FileId from tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId	)
begin

	--	clear the old data...
	truncate table osi.Colonial03Investor;

	--	load the new data
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail output;

	--	the file loaded sucessfully...
	if @result = 0 and len(@detail) = 0
	begin
		--	archive the file...
		exec @result = tcu.File_action	@action		= 'move'
									,	@sourceFile	= @actionFile
									,	@targetFile	= @archFile
									,	@overWrite	= 1
									,	@output		= @detail output;
		--	the file was archived without any errors
		if @result = 0 and len(@detail) = 0
		begin
			--	extract their member numbers...
			exec osi.Colonial03Investor_upd;

			--	loop thru the Target Files and export the data...
			set	@fileName	= '';
			while exists (	select	top 1 * from tcu.ProcessFile
							where	ProcessId	= @ProcessId
							and 	FileName	like 'Target%'
							and		TargetFile	> @fileName	)
			begin
				select	@actionCmd	=	db_name() + '.osi.Colonial03Investor_v' + FileType
					,	@actionFile	=	tcu.fn_SQLFolder(TargetFile)
					,	@switches	=	case FileType
										when 'ALM'			then ''
										when 'ProfitVision'	then '-t, '
										when 'Raddon' 		then '-t, '
										else '' end + '-c -T'
					,	@fileName	=	TargetFile
				from(	select	top 1
								TargetFile
							,	FileName
							,	FileType	= replace(substring(FileName, 8, 50), ' File', '')
						from	tcu.ProcessFile
						where	ProcessId	= @ProcessId
						and 	FileName	like 'Target%'
						and		TargetFile	> @fileName	) f
				order by FileName;

				--	export the new data...
				exec @result = tcu.File_bcp	@action		= 'out'
										,	@actionCmd	= @actionCmd
										,	@actionFile	= @actionFile
										,	@switches	= @switches
										,	@output		= @detail output;
				--	report any errors...
				if @result != 0 or len(@detail) > 0
				begin
					set	@result	= 1;	--	failure
					goto PROC_EXIT;
				end;
				else
				begin
					set	@detailGood = isnull(@detailGood, '')
									+ 'The ' + @fileName + ' is available in <a href="'
									+ replace(@actionFile, @fileName, '') +'">this folder</a>.'
									+ @crlf;
				end;
			end;	--	keep looping until done...

			--	adjust the schedule to begin on the 1st business day of next month and for next 5 days.
			set	@nextOn = tcu.fn_FirstBusinessDay(dateadd(month, 1, getdate()));
			set	@lastOn	= dateadd(day, 4, @nextOn);

			update	tcu.ProcessSchedule
			set		BeginOn		= @nextOn
				,	EndOn		= @lastOn
			where	ProcessId	= @ProcessId
			and		ScheduleId	= @ScheduleId
			set	@detail = 'The Colonial file has loaded and the following files are now available.'
						+ @crlf + @detailGood;
		end;
		else	--	report errors from the archive operation...
		begin
			set	@result = 1;	--	failure
			goto PROC_EXIT;
		end;
	end;
	else	--	report any errors...
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT;
	end;
end;
else	--	no file was found
begin
	set	@result	= 2;	--	information
	set	@detail	= 'The Colonial O3 file (' + @fileName 
				+ ') wasn''t available for loading.';
end;

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
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO