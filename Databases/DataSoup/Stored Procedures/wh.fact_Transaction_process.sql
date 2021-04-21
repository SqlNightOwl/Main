use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[fact_Transaction_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [wh].[fact_Transaction_process]
GO
setuser N'wh'
GO
CREATE procedure wh.fact_Transaction_process
	@RunId		int
,	@ProcessId	smallint
,	@ScheduleId	tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/06/2009
Purpose  :	Add new OSI transactions to the Warehouse Transaciton fact table.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@cmd		sysname
,	@detail		varchar(4000)
,	@lastId		int
,	@result		int
,	@row		tinyint

--	initialize variables...
select	@detail	= ''
	,	@result	= 0
	,	@row	= 0;

--	try to add records to the staging table
begin try

	--	first, empty the staging table...
	truncate table wh.fact_Transaction_stage;

	--	add transactions for yesterday
	insert	wh.fact_Transaction_stage
		(	AcctNbr
		,	CustNbr
		,	CustTypCd
		,	MajorTypCd
		,	MinorTypCd
		,	AcctStatCd
		,	TxnNbr
		,	TxnAmt
		,	TxnTypCd
		,	TxnSourceCd
		,	ApplNbr
		,	TraceNbr
		,	TxnDescNbr
		,	BranchNbr
		,	NetworkNodeNbr
		,	OrigPostDate
		,	PostDate
		,	EffDate
		,	ActDateTime
		,	TimeUniqueExtn
		,	CashBoxNbr
		,	TellerNbr
		,	CardTxnNbr
		,	AgreeNbr
		,	MemberNbr
		,	ISOTxnCd
		,	NetworkCd
		,	TerminalId
		)
	select	AcctNbr
		,	CustNbr
		,	CustTypCd
		,	MajorTypCd
		,	MinorTypCd
		,	AcctStatCd
		,	TxnNbr
		,	TxnAmt
		,	TxnTypCd
		,	TxnSourceCd
		,	ApplNbr
		,	TraceNbr
		,	TxnDescNbr
		,	BranchNbr
		,	NetworkNodeNbr
		,	OrigPostDate
		,	PostDate
		,	EffDate
		,	ActDateTime
		,	TimeUniqueExtn
		,	CashBoxNbr
		,	TellerNbr
		,	CardTxnNbr
		,	AgreeNbr
		,	MemberNbr
		,	ISOTxnCd
		,	NetworkCd
		,	TerminalId
	from	openquery(OSI, '
			select	a.AcctNbr
				,	coalesce( a.TaxRptForPersNbr
							, a.TaxRptForOrgNbr
							, 0)							as CustNbr
				,	decode(nvl(	a.TaxRptForPersNbr, a.TaxRptForOrgNbr)
							,	a.TaxRptForPersNbr, ''P''
							,	a.TaxRptForOrgNbr,  ''O''
							,	''X''	)					as CustTypCd
				,	a.MjAcctTypCd							as MajorTypCd
				, 	a.CurrMiAcctTypCd						as MinorTypCd
				,	a.CurrAcctStatCd						as AcctStatCd

				,	t.RtxnNbr								as TxnNbr
				,	t.TranAmt								as TxnAmt
				,	t.RtxnTypCd								as TxnTypCd
				,	t.RtxnSourceCd							as TxnSourceCd
				,	nvl(t.ApplNbr, 0)						as ApplNbr
				,	nvl(t.TraceNbr, 0)						as TraceNbr 
				,	nvl(t.ExtRtxnDescNbr, 0)				as TxnDescNbr
				,	coalesce( b.LocOrgNbr
							, n.LocOrgNbr
							, 0)							as BranchNbr
				,	coalesce( h.OrigNtwkNodeNbr
							, n.NtwkNodeNbr
							, 0)							as NetworkNodeNbr
				,	t.OrigPostDate

				,	h.PostDate
				,	h.EffDate
				,	h.ActDateTime
				,	h.TimeUniqueExtn
				,	nvl(h.CashBoxNbr, 0)					as CashBoxNbr
				,	nvl(h.OrigPersNbr, 0)					as TellerNbr

				,	nvl(c.CardTxnNbr, 0)					as CardTxnNbr
				,	c.AgreeNbr
				,	c.MemberNbr
				,	c.ISOTxnCd
				,	decode(c.NetworkId
						, null	, null
						, ''ONUS'', ''O''
						, ''F'')							as NetworkCd
				,	c.TerminalId
			from	osiBank.Acct			a
			join	osiBank.Rtxn			t
					on	a.AcctNbr	= t.AcctNbr
			join	osiBank.RtxnStatHist	h
					on	t.AcctNbr	= h.AcctNbr
					and	t.RtxnNbr	= h.RtxnNbr
			left join 
					osiBank.CardTxn			c
					on	t.AcctNbr		= c.FromAcctNbr
					and t.TraceNbr		= c.RetRefNbr
					and t.RtxnSourceCd	= c.RtxnSourceTypCd
					and t.OrigPostDate	= c.ActivityDate
					and c.ResponseCd	= ''00''
					and c.ISOTxnCd		in (200, 220)
			left join
					osiBank.NtwkNode		b
					on	h.OrigNtwkNodeNbr	= b.NtwkNodeNbr
			left join
					osiBank.NtwkNode		n
					on	c.TerminalId	= n.PhysAddr
			where	t.CurrRtxnStatCd	= ''C''
			and		h.TimeUniqueExtn	= (	select	max(TimeUniqueExtn)
											from	osiBank.RtxnStatHist
											where	AcctNbr			= h.AcctNbr
                            				and		RtxnNbr			= h.RtxnNbr
                            				and		CurrRtxnStatCd	= ''C'' )

			and		h.EffDate = trunc(sysdate - 2)');
end try
begin catch
	select	@result	= 1	--	failure
		,	@detail	= 'The following error occured in the procedure ' + error_procedure()
					+ ':<ul><li>Effective Date: '	+ convert(char(10), getdate() - 2, 101)
					+ '</li><li>Line Number: '		+ cast(error_line() as varchar(10))
					+ '</li><li>Error Number: '		+ cast(error_number() as varchar(10))
					+ '</li><li>Severity: '			+ cast(error_severity() as varchar(10))
					+ '</li><li>Error Message: '	+ error_message() + '</li></ul>'
end catch

if len(@detail) = 0 and @result = 0
begin
	--	execute the dimension maintenance handlers...
	while exists (	select	top 1 l.row
					from	tcu.ProcessParameter	p
					cross apply tcu.fn_split(p.Value, ';')	l
					where	p.ProcessId	= @ProcessId
					and		p.Parameter	= 'Secondary Handler'
					and		l.Row		> @row	)
	begin
		select	top 1
				@cmd	= 'exec ' + l.Value
			,	@row	= l.Row
		from	tcu.ProcessParameter	p
		cross apply tcu.fn_split(p.Value, ';')	l
		where	p.ProcessId	= @ProcessId
		and		p.Parameter	= 'Secondary Handler'
		and		l.Row		> @row

		exec sp_executesql @cmd;

	end;

	--	collect the last inserted transacion id before addding new data
	select	@lastId	= max(TransactionId)
	from	wh.fact_Transaction;

	--	load the data into the permanent table...
	insert	wh.fact_Transaction
		(	CustomerTypeCd
		,	CustomerNbr
		,	AccountNbr
		,	AccountTypeId
		,	TransactionTypeId
		,	TransactionSourceId
		,	AccountStatusId
		,	MerchantId
		,	TransactionNumber
		,	TransactionAmount
		,	ApplicationNbr
		,	TraceNbr
		,	BranchNbr
		,	CashBoxNbr
		,	NetworkNodeNbr
		,	TellerNbr
		,	NetworkCd
		,	TerminalId
		,	OriginalPostDateId
		,	PostDateId
		,	EffectiveDateId
		,	ActivityDateTimeId
		,	TimeUniqueExtn
		,	CardTxnNbr
		,	AgreeNbr
		,	MemberNbr
		,	ISOTxnCd
		)
	select	r.CustTypCd
		,	cast(r.CustNbr as int)
		,	r.AcctNbr
		,	at.AccountTypeId
		,	tt.TransactionTypeId
		,	isnull(ts.TransactionSourceId, 0) as TransactionSourceId
		,	s.AccountStatusId
		,	isnull(m.MerchantId, 0)
		,	r.TxnNbr
		,	r.TxnAmt
		,	r.ApplNbr
		,	r.TraceNbr
		,	r.BranchNbr
		,	r.CashBoxNbr
		,	r.NetworkNodeNbr
		,	r.TellerNbr
		,	r.NetworkCd
		,	r.TerminalId
		,	cast(convert(char(8), r.OrigPostDate, 112) as int)
		,	cast(convert(char(8), r.PostDate	, 112) as int)
		,	cast(convert(char(8), r.EffDate		, 112) as int)
		,	cast(convert(char(8), r.ActDateTime	, 112) as int)
		,	r.TimeUniqueExtn
		,	r.CardTxnNbr
		,	r.AgreeNbr
		,	case when r.MemberNbr < 255 then r.MemberNbr else 0 end
		,	case when r.ISOTxnCd < 5000 then r.ISOTxnCd else 0 end
	from	wh.fact_Transaction_stage	r
	join	wh.dim_AccountType			at
			on	r.MajorTypCd	= at.MajorTypeCd
			and	r.MinorTypCd	= at.MinorTypeCd
	join	wh.dim_TransactionType		tt
			on	r.TxnTypCd		= tt.TransactionTypeCd
	left join
			wh.dim_TransactionSource	ts
			on	r.TxnSourceCd	= ts.TransactionSourceCd
	left join
			wh.dim_AccountStatus		s
			on	r.AcctStatCd	= s.AccountStatusCd
	left join	openquery(OSI, '
				select	ExtRtxnDescNbr
					,	ExtRtxnDescText
				from	osiBank.ExtRtxnDesc'
			)	ed	on	r.TxnDescNbr = ed.ExtRtxnDescNbr
					and	r.CardTxnNbr > 0
	left join
			wh.dim_Merchant				m
			on	ed.ExtRtxnDescText = m.MerchantCd;

	--	update the Merchants transaction count
	update	m
	set		TransactionCount = m.TransactionCount + n.NewTransactions
	from	wh.dim_Merchant	m
	join(	select	MerchantId, count(1) as NewTransactions
			from	wh.fact_Transaction
			where	TransactionId	> @lastId
			and		MerchantId		> 0
			group by MerchantId
		)	n	on	m.MerchantId = n.MerchantId;

	--	clean out the staging table
	truncate table wh.fact_Transaction_stage;

end;
else	--	report all errors...
begin
	exec tcu.ProcessLog_sav	@RunId		= @RunId
						,	@ProcessId	= @ProcessId
						,	@ScheduleId	= @ScheduleId
						,	@StartedOn	= null
						,	@Result		= @result
						,	@Command	= 'insert wh.fact_Transaction_stage select records from TCCUS.'
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