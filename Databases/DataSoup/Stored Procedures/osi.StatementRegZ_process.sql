use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[StatementRegZ_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[StatementRegZ_process]
GO
setuser N'osi'
GO
CREATE procedure osi.StatementRegZ_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/09/2009
Purpose  :	Creates the supplemental Statement file for compliance with the Credit
			Card Act.
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
,	@detailPay	varchar(1000)
,	@detailType	varchar(1000)
,	@exceptFile	varchar(255)
,	@result		int
,	@sqlFolder	varchar(255)

--	initialize the variables...
select	@actionCmd	= db_name() + '.osi.StatementRegZ_vStatement'
	,	@actionFile	= p.FTPFolder + f.FileName
	,	@exceptFile	= p.SQLFolder + f.TargetFile
	,	@sqlFolder	= p.SQLFolder
	,	@detail		= ''
	,	@result		= 0
from	tcu.ProcessFile			f
join	tcu.ProcessParameter_v	p
		on	f.ProcessId = p.ProcessId
where	f.ProcessId = @ProcessId;

--	clear out the old and load the new data...
truncate table osi.StatementRegZ;

insert	osi.StatementRegZ
	(	MemberNumber
	,	AccountNumber
	,	MajorType
	,	MinorType
	,	DailyRate
	,	AccruedInterest
	,	CourtesyPeriod
	)
select	isnull(MemberAgreeNbr	, 0)		as MemberNumber
	,	AcctNbr								as AccountNumber
	,	MjAcctTypCd							as MajorType
	,	CurrMiAcctTypCd						as MinorType
	,	isnull(InterestRate/3.65,-.1)		as DailyRate
	,	case	--	per Craig Thomas
		when isnull(cast(PmtAmt				as money), 0) < 0	
		 and isnull(cast(AccruedInterest	as money), 0) < 0	then 0
		else isnull(cast(AccruedInterest	as money), 0) end	as AccruedInterest
	,	isnull(GraceDays		, 0)		as CourtesyPeriod
from	openquery(OSI, '
		select	AcctNbr
			,	MemberAgreeNbr
			,	MjAcctTypCd
			,	CurrMiAcctTypCd
			,	PmtAmt
			,	GraceDays
			,	InterestRate
			,	AccruedInterest
		from	texans.CreditCardActLoan_vw
		order by AcctNbr');

--	rebuild the indexes...
alter index all on osi.StatementRegZ rebuild;

--	export the supplemental statement file...
exec @result = tcu.File_bcp	@action		= 'out'
						,	@actionCmd	= @actionCmd
						,	@actionFile	= @actionFile
						,	@switches	= '-c -t, -T'
						,	@output		= @detail output;


if @result = 0 and len(@detail) = 0
begin
	--	export the exceptions file...
	set	@actionCmd = db_name() + '.osi.StatementRegZ_vExceptions'
	exec @result = tcu.File_bcp	@action		= 'out'
							,	@actionCmd	= @actionCmd
							,	@actionFile	= @exceptFile
							,	@switches	= '-c -t, -T'
							,	@output		= @detail output;

	if @result = 0 and len(@detail) = 0
	begin
		--	report success...
		--	build the detail summary on loan types...
		select	@detailType	= isnull(@detailType, '')
			+	'<tr><td'	+ class + '>' + MajorType
			+	'</td><td'	+ class + '>' + MinorType
			+	'</td><td'	+ case MinorType
							  when 'Total' then ' class="ttl"'
							  else ' class="num"' end + '>'
			+	cast(Accounts as varchar) + '</td></tr>'
		from(	select	MajorType, MinorType, count(1) as Accounts, 1 as row, '' as class
				from	osi.StatementRegZ
				group by MajorType, MinorType
			union all
				select	'&nbsp;', 'Total', count(1), 2, ' class="ttl"'
				from	osi.StatementRegZ
			)	t
		order by row, MajorType, MinorType;

		--	put the whole message together...
		select	@detail	= '<style type="text/css">'
						+ 'table{width:250px;padding:2px;} '
						+ 'th{border-bottom:1px solid;font-weight:bold;text-align:center;vertical-align:middle;} '
						+ '.num{text-align:right;} '
						+ '.sum{font-style:italic;font-weight:bold;} '
						+ '.ttl{border-bottom:1px solid;border-top:1px solid;text-align:right;} '
						+ '</style>'
						+ '<p>Below is a summary of the loans for the Credit Card Act Statement information '
						+ 'and a link to the detailed <a href="' + @sqlFolder + '">exception report</a>.</p>'
						+ '<p class="sum">Count of Loans by Loan Type:</p>'
						+ '<table><tr><th>Major</th><th>Minor</th><th>Accounts</th></tr>'
						+ @detailType + '</table>'
						+ '<p class="sum">Count of Loans by Payment Frequency:</p>'
						+ '<table><tr><th>Frequency</th><th>Accounts</th></tr>'
						+ @detailPay + '</table>'
	end;
	else
	begin
		--	report error...
		select	@detail	= 'Unable to produce the Card Act exceptions file.<br/>'
						+ @detail
			,	@result	= 3;	--	warning
	end;
end;
else
begin
	--	report error...
	select	@detail	= 'Unable to produce the Card Act Statement file.<br/>'
					+ @detail
		,	@result	= 1;	--	failure
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