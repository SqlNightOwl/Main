use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[CunaSimpleInsurance_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[CunaSimpleInsurance_process]
GO
setuser N'osi'
GO
CREATE procedure osi.CunaSimpleInsurance_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/15/2007
Purpose  :	Updates the data loaded from the file by removing zero-balance loans
			and updating the summary loan counts.
			can be updated.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/09/2008	Paul Hunter		Moved the load and export logic into this procedure.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@actionCmd	varchar(255)
,	@detail		varchar(4000)
,	@DO_NOT_USE	char(16)
,	@lastMonth	char(10)
,	@result		int
,	@sourceFile	varchar(255)
,	@targetFile	varchar(255)

declare	@records	table
(	Row				int			primary key
,	MinorCode		varchar(4)	not null
,	InsuranceType	varchar(24)	not null
,	LoanBal			money		not null
)

set	@lastMonth	= convert(char(10), dateadd(day, -day(getdate()), getdate()), 121);

--	clear out any old data
truncate table osi.CunaSimpleInsurance;

--	setup the bulk insert command and target file
select	@actionCmd	= db_name() + '.osi.CunaSimpleInsurance_vLoad'
	,	@sourceFile	= l.fileSpec
	,	@targetFile	= p.ftpFolder + replace(l.fileName, '.LIS', '-' + @lastMonth + '.LIS')
	,	@DO_NOT_USE	= '** DO NOT USE **'
	,	@result		= 0
	,	@detail		= ''
from	tcu.ProcessOSILog_v		l
join	tcu.ProcessParameter_v	p
		on	l.ProcessId = p.ProcessId
where	l.RunId		= @RunId
and		l.ProcessId	= @ProcessId;

--	load the file...
exec @result = tcu.File_bcp	@action		= 'in'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @sourceFile
						,	@switches	= '-c -T'
						,	@output		= @detail output;
--	report any errors...
if @result != 0 or len(@detail) > 0
begin
	set	@result = 1;
end;
else if exists ( select top 1 * from osi.CunaSimpleInsurance_vLoad )
begin
	--	collect the details about the loans
	insert	@records
	select	Row
		,	MinorCode
		,	left(InsuranceType, 24)
		,	LoanBal
	from	osi.CunaSimpleInsurance_vDetail;

	--	update (blank out) records where the loan balance equals zero
	update	data
	set		Record = @DO_NOT_USE
	from	osi.CunaSimpleInsurance	data
	join	@records				dtl
			on	data.row between dtl.row and dtl.row + 2
	where	dtl.LoanBal = 0;

	--	remove records where the loan balance equals zero
	delete	@records
	where	LoanBal = 0;

	--	update the summary data with the new counts
	update	data
	set		Record	= left(s.Record, 54) + tcu.fn_lpad(t.Loans, 9) + substring(s.Record, 64, 255)
	from	osi.CunaSimpleInsurance				data
	join	osi.CunaSimpleInsurance_vSummary	s
			on	data.Row = s.Row
	join(				/*	count by MinorCode & InsuranceType
						*/
			select	MinorCode
				,	InsuranceType
				,	Loans			= count(1)
			from	@records
			group by MinorCode
				,	InsuranceType
			union all	/*	count by InsuranceType
						*/
			select	MinorCode		= 'TOTAL'
				,	InsuranceType
				,	Loans			= count(1)
			from	@records
			group by InsuranceType
			union all	/*	count entier file
						*/
			select	MinorCode		= 'TOTAL'
				,	InsuranceType	= cast('Report Totals' as char(24))
				,	Loans			= count(1)
			from	@records
		)	t	on	s.MinorCode		=	t.MinorCode
				and	s.InsuranceType	=	t.InsuranceType
				and	s.TypeCount		!=	t.Loans;

	--	setup the bcp export command
	set	@actionCmd	= 'select Record from ' + db_name() 
					+ '.osi.CunaSimpleInsurance '
					+ 'where Record != ''' + @DO_NOT_USE + ''' ' 
					+ 'order by Row';

	--	export the data and captire the results
	exec @result = tcu.File_bcp	@action		= 'queryout'
							,	@actionCmd	= @actionCmd
							,	@actionFile = @targetFile
							,	@switches	= '-c -T'
							,	@output		= @detail output;

	--	report any errors...
	if @result != 0 or len(isnull(@detail, '')) > 0
	begin
		set	@result = 3	--	warning
		exec tcu.ProcessLog_sav	@RunId		= @RunId
							,	@ProcessId	= @ProcessId
							,	@ScheduleId	= @ScheduleId
							,	@StartedOn	= null
							,	@Result		= @result
							,	@Command	= @actionCmd
							,	@Message	= @detail;
	end;

	truncate table osi.CunaSimpleInsurance;
end;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO