use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[lnd].[LoanQualityAudit_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [lnd].[LoanQualityAudit_process]
GO
setuser N'lnd'
GO
CREATE procedure lnd.LoanQualityAudit_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Deeksha Mediratta
Created  :	11/27/2009
Purpose  :	Loads lnd.AuditWeeklyData with information for Lending Audit Reports.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/08/2010	Paul Hunter		Added record retention policy.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd		varchar(50)
,	@detail		varchar(4000)
,	@loadOn		datetime
,	@retention	int
,	@result		int

--	initialize the variables...
select	@cmd		= ''
	,	@detail		= ''
	,	@loadOn		= convert(char(10), getdate(), 121)
	,	@retention	= cast(tcu.fn_ProcessParameter(@ProcessId, 'Retention Period') as int) * -1
	,	@result		= 0;

if not exists (	select	top 1 LoadOn from lnd.LoanQualityAudit
				where	LoadOn = @loadOn	)
begin
	begin try
		set	@cmd = 'delete old data'
		delete	lnd.LoanQualityAudit
		where	LoadOn < dateadd(day, @retention, @loadOn);

		set	@cmd = 'load the audit data'
		insert	lnd.LoanQualityAudit
			(	OwnCd
			,	AcctNbr
			,	MjAcctTypCd
			,	CurrMiAcctTypCd
			,	Product
			,	ContractDate
			,	CurrAcctStatCd
			,	LoanLimitYN
			,	CallDate
			,	CreditScore
			,	RiskRatingCd
			,	TaxOwnerNbr
			,	TaxOwnerCd
			,	PrimaryOwnerZipCd
			,	NoteOpenAmt
			,	NoteIntRate
			,	NoteBal
			,	OwnerName
			,	OwnerSortName
			,	OriginatingPerson
			,	LoanOfficersNbr
			,	LoanOfficer
			,	OEMPRole
			,	SIGNRole
			,	MemberAgreeNbr
			,	IsEmployee
			,	LoadOn
			)
		select	*
			,	@loadOn
		from	openquery(OSI, '
				select	/*+CHOOSE*/
						OwnCd
					,	AcctNbr
					,	MjAcctTypCd
					,	CurrMiAcctTypCd
					,	Product
					,	ContractDate
					,	CurrAcctStatCd
					,	LoanLimitYN
					,	CallDate
					,	CreditScore
					,	RiskRatingCd
					,	TaxOwnerNbr
					,	TaxOwnerCd
					,	PrimaryOwnerZipCd
					,	NoteOpenAmt
					,	NoteIntRate
					,	NoteBal
					,	OwnerName
					,	OwnerSortName
					,	OriginatingPerson
					,	LoanOfficersNbr
					,	LoanOfficer
					,	OEMPRole
					,	SIGNRole
					,	MemberAgreeNbr
					,	IsEmployee
				from	lnd_LoanQualityAudit_vw');

		set	@cmd = 'update data from the wh_AcctLoan table'
		update	a
		set		TotalPi			= l.TotalPi
			,	PmtMethCd		= l.PmtMethCd
			,	CreditLimitAmt	= l.CreditLimitAmt
		from	lnd.LoanQualityAudit	a
		join	openquery(OSI, '
				select	/*+CHOOSE*/
						l.AcctNbr
					,	l.TotalPi
					,	l.PmtMethCd
					,	l.CreditLimitAmt
				from	wh_AcctLoan	l
				join	Acct		a
						on	l.AcctNbr = a.AcctNbr
				where	l.EffDate		= (	select	max(EffDate)
											from	wh_AcctLoan
											where	AcctNbr = l.AcctNbr )
				and		a.ContractDate	> trunc(sysdate) - 8' )	l
				on	a.AcctNbr = l.AcctNbr
		where	a.LoadOn = @loadOn;

		--	set the results for notification
		select	@cmd	= ''
			,	@detail	= ''
			,	@result	= 2;	--	information

	end try
	begin catch
		--	collect the standard error message...
		exec tcu.ErrorDetail_get @detail out;
		set @result = 1;	--	failure
	end catch;
end;

--	save the results...
exec tcu.ProcessLog_sav	@RunId		= @RunId
					,	@ProcessId	= @ProcessId
					,	@ScheduleId	= @ScheduleId
					,	@StartedOn	= null
					,	@Result		= @result
					,	@Command	= @cmd
					,	@Message	= @detail;

return @result;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO