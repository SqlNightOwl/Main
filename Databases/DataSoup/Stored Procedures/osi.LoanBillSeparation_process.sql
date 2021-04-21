use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[LoanBillSeparation_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[LoanBillSeparation_process]
GO
setuser N'osi'
GO
CREATE procedure osi.LoanBillSeparation_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/16/2008
Purpose  :	Loads and separates Loan Bills file into Consumer, Commercial (CML),
			Mortgagte (MTG) and Small Business (SBL) files for distribution to
			the various business units.
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
,	@effective	datetime
,	@FF			char(1)
,	@fileName	varchar(255)
,	@ftpFolder	varchar(255)
,	@MORTGAGE	char(3)
,	@page		int
,	@reportType	char(3)
,	@result		int
,	@row		int
,	@startedOn	datetime;

--	initialize the variables
select	@detail		= ''
	,	@FF			= char(12)
	,	@ftpFolder	= tcu.fn_FTPFolder(tcu.fn_ProcessParameter(@ProcessId, 'Folder Offset') + '\')
	,	@MORTGAGE	= 'MTG'
	,	@page		= 1
	,	@reportType	= ''
	,	@result		= 0
	,	@row		= 0
	,	@startedOn	= getdate();

--	clear the old loan bills
truncate table osi.LoanBill;

--	load the new file(s)... there should only be one but it may return multiples
while exists (	select	top 1 * from tcu.ProcessOSILog
				where	ProcessOSILogId	> @row
				and		RunId			= @RunId
				and		ProcessId		= @ProcessId )
begin

	--	setup the load command and source file...
	select	top 1
			@actionCmd	= db_name() + '.osi.LoanBill_vLoad'
		,	@actionFile	= FileSpec
		,	@fileName	= replace(FileName, '.', '_' + convert(char(8), EffectiveOn, 112) + '.')
		,	@effective	= EffectiveOn
		,	@row		= ProcessOSILogId
	from	tcu.ProcessOSILog_v
	where	ProcessOSILogId	> @row
	and		RunId			= @RunId
	and		ProcessId		= @ProcessId;

	exec @result = tcu.File_bcp	@action		= 'in'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @actionFile
							,	@switches	= '-c -T'
							,	@output		= @detail	output;

	--	report any load errors and exit
	if @result != 0 or len(@detail) > 0
	begin
		set	@result		= 1;	--	failure
		set	@actionCmd	= 'BCP Error  action: IN'
						+ ' cmd: '	+ @actionCmd 
						+ ' file: ' + @actionFile;

		exec tcu.ProcessLog_sav	@RunId		= @RunId
							,	@ProcessId	= @ProcessId
							,	@ScheduleId	= @ScheduleId
							,	@StartedOn	= @startedOn
							,	@Result		= @result
							,	@Command	= @actionCmd
							,	@Message	= @detail;
		return @result;
	end;
end;

--	bind the view to the procedure for dependency checks and check to see that a file was loaded
if exists (	select top 1 Detail from osi.LoanBill_vLoad )
begin
	--	assing each bill to it's own page number
	while exists (	select	top 1 Page from osi.LoanBill
					where	Page	= 0	)
	begin
		--	find the next form feed (break)
		select	@row	= min(RowId)
		from	osi.LoanBill
		where	Detail	like '%' + @FF + '%'
		and		Page	= 0;

		--	update the bill page number and trim trim trailing spaces
		update	osi.LoanBill
		set		Detail	=	rtrim(Detail)
			,	Page	=	@page
		where	RowId	<=	@row
		and		Page	=	0;

		--	increment the page counter
		set	@page = @page + 1;

		--	each bill will be at least 10 lines long so delete any records less less than that
		if ( select count(1) from osi.LoanBill where Page = 0 ) < 10
		begin
			delete	osi.LoanBill
			where	Page = 0;
		end;
	end; 

	--	update the report type based on the agreed upon strings
	update	lb
	set		ReportType	= pg.ReportType
	from	osi.LoanBill	lb
	join(	select	Page
				,	ReportType	=	case
									when Detail like '%cial Loan/Sm Bus%' then 'SBL'
									when Detail like '%Commercial Loan/%' then 'CML'
									else @MORTGAGE end
			from	osi.LoanBill
			where	Detail like '%Commercial Loan/%'
				or	Detail like '%Mortgage Loan/%'
		)	pg	on	lb.Page = pg.Page;

	--	delete any loan bills where the amount to pay is zero
	delete	osi.LoanBill
	where	Page in (	select	Page from osi.LoanBill
						where	Detail like '%PLEASE PAY:%'
						and		cast(substring(Detail, 12, 55) as money) = 0 );

	--	remove the Mortgage Bills into temporary storage...
	if exists (	select	top 1 RowId from osi.LoanBill
				where	ReportType	= @MORTGAGE	)
	begin
		insert	osi.LoanBillMortgage
			(	Detail	)
		select	Detail
		from	osi.LoanBill
		where	ReportType = @MORTGAGE
		order by RowId;

		delete	osi.LoanBill
		where	ReportType = @MORTGAGE;
	end;

	--	loop thru the different report types and export the file
	while exists (	select	top 1 * from osi.LoanBill
					where	ReportType	> @reportType	)
	begin
			--	setup the command, file name and report type
			select	top 1
					@actionCmd	= 'select Detail from ' + db_name() + '.osi.LoanBill '
								+ 'where ReportType = ''' + ReportType + ''' order by RowId'
				,	@actionFile	= @ftpFolder + ReportType + '_' + @fileName
				,	@reportType	= ReportType
			from	osi.LoanBill
			where	ReportType	> @reportType
			order by ReportType;

		--	export the results...
		exec @result = tcu.File_bcp	@action		= 'queryout'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= '-c -T'
								,	@output		= @detail	output;

		--	report any load errors and exit
		if @result != 0 or len(@detail) > 0
		begin
			set	@result = 1	--	failure
			exec tcu.ProcessLog_sav	@RunId		= @RunId
								,	@ProcessId	= @ProcessId
								,	@ScheduleId	= @ScheduleId
								,	@StartedOn	= @startedOn
								,	@Result		= @result
								,	@Command	= @actionCmd
								,	@Message	= @detail;
			return @result;
		end;
	end;		--	while loop

	if day(@effective)	= 1
	or day(@effective)	= day(tcu.fn_LastDayOfMonth(@effective)) - 20
	begin
		--	setup the command, file name and report type
		select	@actionCmd	= 'select Detail from ' + db_name() + '.osi.LoanBillMortgage '
							+ 'order by RowId'
			,	@actionFile	= @ftpFolder + @MORTGAGE + '_' + @fileName;

		--	export the results...
		exec @result = tcu.File_bcp	@action		= 'queryout'
								,	@actionCmd	= @actionCmd
								,	@actionFile	= @actionFile
								,	@switches	= '-c -T'
								,	@output		= @detail	output;

		--	report any load errors and exit
		if @result != 0 or len(@detail) > 0
		begin
			set	@result = 1	--	failure
			exec tcu.ProcessLog_sav	@RunId		= @RunId
								,	@ProcessId	= @ProcessId
								,	@ScheduleId	= @ScheduleId
								,	@StartedOn	= @startedOn
								,	@Result		= @result
								,	@Command	= @actionCmd
								,	@Message	= @detail
			return @result;
		end;
		else
		begin
			--	the mortgage bills were exported so clear the table for the next batch
			truncate table osi.LoanBillMortgage;
		end;
	end;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO