use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Colonial07Mortgage_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[Colonial07Mortgage_process]
GO
setuser N'osi'
GO
CREATE procedure osi.Colonial07Mortgage_process
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
Purpose  :	Wrapper procedure to find the Colonial07 (PLS0303.DAT) files, loads
			the file if available and updates the process schedule if this runs
			sucessfully.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/06/2008	Paul Hunter		Added logic for creating the OSI Change Report/Script.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@actionFile	varchar(255)
,	@archFile	varchar(255)
,	@detail		varchar(4000)
,	@fileName	varchar(255)
,	@lastOn		datetime
,	@nextOn		datetime
,	@result		int
,	@sqlFolder	varchar(255)
,	@switches	varchar(255)
,	@targetFile	varchar(50)

--	exit if the most recent payment is for the current month
select	@lastOn	= max(cast('20' + right(LastPaymentPosted, 2)
				+ left(LastPaymentPosted, 4) as datetime))
from	osi.Colonial07Mortgage
where	LastPaymentPosted != '000000';

if datediff(month, @lastOn, getdate()) = 0
	return @@error

--	initialize the processing variables
select	@actionCmd	= db_name() + '.osi.Colonial07Mortgage_vLoad'
	,	@actionFile	= p.SQLFolder + f.FileName
	,	@targetFile	= replace(f.TargetFile, '[PERIOD]', convert(char(7), getdate(), 121))
	,	@archFile	= p.SQLFolder + 'archive\' + convert(char(6), getdate(), 112) + ' ' + f.FileName
	,	@fileName	= f.fileName
	,	@sqlFolder	= p.SQLFolder
	,	@switches	= '-T -f"' + p.SQLFolder + p.FormatFile + '"'
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	see if the file is there
exec tcu.FileLog_findFiles	@ProcessId			= @ProcessId
						,	@RunId				= @RunId
						,	@uncFolder			= @sqlFolder
						,	@fileMask			= @fileName
						,	@includeSubFolders	= 0;

--	if the file was found then call the secondary handler
if exists (	select	top 1 * from tcu.FileLog
			where	ProcessId	= @ProcessId
			and		RunId		= @RunId	)
begin
	--	load the new data...
	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= @switches
							,	@output		= @detail output;
	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT
	end;

	--	archive the file...
	exec @result = tcu.File_action	@action		= 'move'
								,	@sourceFile	= @actionFile
								,	@targetFile	= @archFile
								,	@overWrite	= 1
								,	@output		= @detail output;
	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;	--	failure
		goto PROC_EXIT
	end;

	--	the file loaded & archived without any errors
	--	produce the change report and OSI update scripts
	set	@actionFile	= @sqlFolder + @targetFile;
	set	@actionCmd	= 'select Period'
					+ ', Action'
					+ ', UserFieldCd'
					+ ', InvestorNum'
					+ ', LoanNumber'
					+ ', MortgagorTaxId'
					+ ', Mortgagor'
					+ ', CoMortgagorTaxId'
					+ ', CoMortgagor'
					+ ', SQLScript'
					+ ' from ' + db_name() + '.osi.Colonial07Mortgage_vChange'
					+ ' order by Action, Mortgagor';

	--	export the change script...
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;
	--	report any errors...
	if @result != 0 or len(@detail) > 0
	begin
		set	@result = 1;	--	failure
	end;
	else	--	no errors
	begin
		--	remove the prior month data
		delete	osi.Colonial07Mortgage
		where	Period	= (select min(Period) from osi.Colonial07Mortgage);
		
		--	adjust the schedule to begin on the 25th through the end of next month
		set	@nextOn = tcu.fn_FirstDayOfMonth(dateadd(month, 1, getdate())) + 24
		set	@lastOn	= tcu.fn_LastDayOfMonth(@nextOn)
		update	tcu.ProcessSchedule
		set		BeginOn		= @nextOn
			,	EndOn		= @lastOn
		where	ProcessId	= @ProcessId
		and		ScheduleId	= @ScheduleId;

		--	build the success message
		select	@result	= 2	--	information
			,	@detail	= 'The Colonial O7 Mortgage file was sucessfully loaded and the '
						+ 'change report "' + @targetFile + '" was created in the '
						+ '<a href="' + @sqlFolder + '">Colonial 07</a> folder. &nbsp;The '
						+ 'change scripts in this file must be executed prior to month end.';
	end;
end;
else
begin
	select	@result	= 3	--	warning
		,	@detail	= 'The Colonial 07 file (' + @fileName + ') wasn''t available for loading.'
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