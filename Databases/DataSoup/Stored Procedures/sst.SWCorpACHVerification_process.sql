use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[sst].[SWCorpACHVerification_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [sst].[SWCorpACHVerification_process]
GO
setuser N'sst'
GO
CREATE procedure sst.SWCorpACHVerification_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	06/12/2008
Purpose  :	Loads the Corillian Business Banking ACH file which is sent to SW Corp
			for reporting purposes.
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
,	@fileDate	datetime
,	@fileId		int
,	@fileName	varchar(50)
,	@ftpFolder	varchar(255)
,	@result		int
,	@retention	int
,	@targetFile	varchar(255)

--	initialize the variables...
select	@actionCmd	= db_name() + '.sst.SWCorpACHVerification_load'
	,	@fileName	= '*.*'
	,	@ftpFolder	= FTPFolder
	,	@retention	= RetentionPeriod
	,	@detail		= ''
	,	@fileId		= 0
	,	@result		= 0
from	tcu.ProcessParameter_v
where	ProcessId = @ProcessId;

--	remove old records...
delete	sst.SWCorpACHVerification
where	FileDate < cast(convert(char(8), dateadd(day, @retention, getdate()), 112) as int);

--	search for any files...
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @ftpFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	load any files that were found...
while exists (	select	top 1 FileId from tcu.FileLog
				where	ProcessId	= @ProcessId
				and		RunId		= @RunId
				and		FileId		> @fileId	)
begin
	--	clear any old data
	truncate table sst.SWCorpACHVerification_load;

	--	refresh the view
	exec sp_refreshview N'sst.SWCorpACHVerification_vDetail';

	--	get the next specific file...
	select	top 1
			@actionFile = Path + '\' + FileName
		,	@fileDate	= FileDate
		,	@fileId		= FileId
		,	@fileName	= FileName
		,	@detail		= ''
		,	@result		= 0
	from	tcu.FileLog
	where	ProcessId	= @ProcessId
	and		RunId		= @RunId
	and		FileId		> @fileId
	order by FileId;

	--	load the file...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;

	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result	= 3;	--	warning
		--	report the error...
		exec tcu.ProcessLog_sav	@RunId		= @RunId
							,	@ProcessId	= @ProcessId
							,	@ScheduleId	= @ScheduleId
							,	@StartedOn	= null
							,	@Result		= @result
							,	@Command	= @actionCmd
							,	@Message	= @detail;
	end;
	else
	begin
		--	if the file balances (credits = debits all around)... 
		if(		select	case when max(TotalCredit)
								- sum(case when TxnCode in (22, 32) then Amount else 0 end) = 0
							 and  max(TotalDebit)
								- sum(case when TxnCode in (27, 37) then Amount else 0 end) = 0
							 and  max(TotalCredit) - max(TotalDebit) = 0
						then 1 else 0 end as value
				from	sst.SWCorpACHVerification_vDetail
			) = 1
		begin
			--	...then load it...
			insert	sst.SWCorpACHVerification
				(	FileName
				,	FileDate
				,	FileType
				,	TransactionCode
				,	RTN
				,	AccountNumber
				,	TaxId
				,	CompanyName
				,	Amount
				,	LoadedOn
				)
			select	@fileName
				,	FileDate
				,	FileType
				,	TxnCode
				,	RTN
				,	Account
				,	TaxId
				,	Company
				,	Amount
				,	@fileDate
			from	sst.SWCorpACHVerification_vDetail;
		end;
		else
		begin
			--	...it doesn't balance so report it...
			set	@result		= 3;	--	warning
			set	@detail	= 'The Corillian ACH file "' + @fileName
						+ '" did not balance and has been moved to the '
						+ '<a href="' + @ftpFolder + 'error">Corillian ACH error</a> folder.';
			--	report the error...
			exec tcu.ProcessLog_sav	@RunId		= @RunId
								,	@ProcessId	= @ProcessId
								,	@ScheduleId	= @ScheduleId
								,	@StartedOn	= null
								,	@Result		= @result
								,	@Command	= @actionCmd
								,	@Message	= @detail;
		end;

		--	move the file out of the load folder and keep loading...
		set	@targetFile	= @ftpFolder +	case @result
										when 0  then 'archive\' 
										else 'error\'
										end + @fileName;

		exec tcu.File_action	@action		= 'move'
							,	@sourceFile	= @actionFile
							,	@targetFile	= @targetFile
							,	@overWrite	= 1;
	end;	--	no errors during the loading
end;		--	while loop

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO