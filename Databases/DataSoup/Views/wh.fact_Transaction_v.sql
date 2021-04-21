use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[fact_Transaction_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [wh].[fact_Transaction_v]
GO
setuser N'wh'
GO
CREATE view wh.fact_Transaction_v
as

--	05/16/2009	Paul Hunter		Compiled against the DNA schema.

select	cast(AcctNbr		as decimal(22,0))	as AcctNbr
	,	cast(CustNbr		as decimal(22,0))	as CustNbr
	,	cast(CustTypCd		as char(1))			as CustTypCd
	,	cast(MajorTypCd		as varchar(4))		as MajorTypCd
	,	cast(MinorTypCd		as varchar(4))		as MinorTypCd
	,	cast(AcctStatCd		as varchar(4))		as AcctStatCd
	,	cast(TxnNbr			as decimal(22,0))	as TxnNbr
	,	cast(TxnAmt			as money)			as TxnAmt
	,	cast(TxnTypCd		as varchar(4))		as TxnTypCd
	,	cast(TxnSourceCd	as varchar(4))		as TxnSourceCd
	,	cast(ApplNbr		as decimal(22,0))	as ApplNbr
	,	cast(TraceNbr		as decimal(22,0))	as TraceNbr
	,	cast(TxnDescNbr		as decimal(22,0))	as TxnDescNbr
	,	cast(BranchNbr		as decimal(22,0))	as BranchNbr
	,	cast(NetworkNodeNbr	as decimal(22,0))	as NetworkNodeNbr
	,	cast(OrigPostDate	as datetime)		as OrigPostDate
	,	cast(PostDate		as datetime)		as PostDate
	,	cast(EffDate		as datetime)		as EffDate
	,	cast(ActDateTime	as datetime)		as ActDateTime
	,	cast(TimeUniqueExtn	as decimal(22,0))	as TimeUniqueExtn
	,	cast(CashBoxNbr		as decimal(22,0))	as CashBoxNbr
	,	cast(TellerNbr		as decimal(22,0))	as TellerNbr
	,	cast(CardTxnNbr		as decimal(22,0))	as CardTxnNbr
	,	cast(AgreeNbr		as decimal(22,0))	as AgreeNbr
	,	cast(MemberNbr		as decimal(22,0))	as MemberNbr
	,	cast(ISOTxnCd		as decimal(22,0))	as ISOTxnCd
	,	cast(NetworkCd		as char(1))			as NetworkCd
	,	cast(TerminalId		as varchar(16))		as TerminalId
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
				and c.ResponseCd	 =''00''
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

		and		h.EffDate >		to_date(''04/01/2009'', ''MM/DD/YYYY'')
		and		h.EffDate <=	trunc(sysdate - 2)');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO