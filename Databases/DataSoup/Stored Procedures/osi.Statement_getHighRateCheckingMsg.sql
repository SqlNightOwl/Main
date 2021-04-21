use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[Statement_getHighRateCheckingMsg]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[Statement_getHighRateCheckingMsg]
GO
setuser N'osi'
GO
CREATE procedure osi.Statement_getHighRateCheckingMsg
	@ProcessId	smallint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/23/2008
Purpose  :	Retuns data used for producing the High Rate Checking message for the
			MicroDynamics statements.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
10/16/2008	Paul Hunter		Changed the message to use new item count logic.
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@message	varchar(255);

set	@message	= tcu.fn_ProcessParameter(@ProcessId, 'Statement Message');

truncate table osi.StatementMessage;

create table #account
	(	MemberNbr	bigint
	,	AcctNbr		bigint
	,	PWTH_Items	smallint
	,	XDEP_Items	smallint
	,	XWTH_Items	smallint
	,	constraint pk_accounts primary key (MemberNbr, AcctNbr)
	);

insert	#account
select	MemberAgreeNbr
	,	AcctNbr
	,	PWTH_Items
	,	XDEP_Items
	,	XWTH_Items
from	openquery(OSI, '
		select	ma.MemberAgreeNbr
			,	a.AcctNbr
			,	sum(decode(t.RtxnTypCd, ''PWTH'', 1, 0)) as PWTH_Items
			,	sum(decode(t.RtxnTypCd, ''XDEP'', 1, 0)) as XDEP_Items
			,	sum(decode(t.RtxnTypCd, ''XWTH'', 1, 0)) as XWTH_Items
		from	osiBank.Acct			a
		join	osiBank.MemberAgreement	ma
				on	a.TaxRptForPersNbr = ma.PrimaryPersNbr
		left join	osibank.Rtxn		t
				on	t.AcctNbr			=	a.AcctNbr
				and	t.RtxnTypCd 		in (''PWTH'', ''XWTH'', ''XDEP'')
				and	t.CurrRtxnStatCd 	=	''C''
				and	t.OrigPostDate	between texans.pkg_Date.FirstDay_Months(-1)
										and texans.pkg_Date.LastDay_Months(-1)
		where	a.MjAcctTypCd		=	''CK''
		and		a.CurrMiAcctTypCd	=	''HRCK''
		and		a.CurrAcctStatCd	in (''ACT'', ''DORM'')
		group by ma.MemberAgreeNbr, a.AcctNbr')
order by MemberAgreeNbr, AcctNbr;

insert	osi.StatementMessage
	(	Record	)
select	Record	= tcu.fn_ZeroPad(a.MemberNbr, 22)
				+ tcu.fn_ZeroPad(a.AcctNbr	, 22)
				+ tcu.fn_ZeroPad(m.LineNbr	, 2)
				+ cast(replace(replace(replace(m.Value
									, '[PWTH_Items]', a.PWTH_Items) 
									, '[XWTH_Items]', a.XWTH_Items) 
									, '[XDEP_Items]', a.XDEP_Items) 
					as char(80))
from	#account	a
cross apply
	(	select	LineNbr = msg.Row, msg.Value
		from	tcu.fn_Split(@message, '|') msg
	)	m
order by
		a.MemberNbr
	,	a.AcctNbr
	,	m.LineNbr;

drop table #account;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO