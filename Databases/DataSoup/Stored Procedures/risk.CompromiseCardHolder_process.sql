use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseCardHolder_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [risk].[CompromiseCardHolder_process]
GO
setuser N'risk'
GO
CREATE procedure risk.CompromiseCardHolder_process
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/16/2009
Purpose  :	Updates the card status where the OSI status has changed.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@by		varchar(25)
,	@on		datetime

select	@by	= tcu.fn_UserAudit()
	,	@on	= getdate()

--	update the holder status information
update	h
set		IssueId				= cast(o.IssueNbr as tinyint)
	,	CurrentStatusCode	= o.CardStatCd
	,	EffDateTime			= o.EffDateTime
	,	StatusReason		= o.StatReason
	,	UpdatedBy			= @by
	,	UpdatedOn			= @on
from	risk.CompromiseCardHolder	h
join	openquery(OSI, '
		select	h.AgreeNbr
			,	h.MemberNbr
			,	h.IssueNbr
			,	h.CardStatCd
			,	h.EffDateTime
			,	h.StatReason
		from	osiBank.CardMember			cm
		join	osiBank.CardMemberIssueHist	h
				on	h.AgreeNbr	= cm.AgreeNbr
				and	h.MemberNbr	= cm.MemberNbr
				and	h.IssueNbr	= cm.CurrIssueNbr
		where	h.TimeUniqueExtn	= (	select	max(TimeUniqueExtn)
										from	osiBank.CardMemberIssueHist
										where	AgreeNbr	= h.AgreeNbr
										and		MemberNbr	= h.MemberNbr
										and		IssueNbr	= h.IssueNbr)
		and	(	cm.DateLastMaint	> trunc(sysdate) - 15
			or	h.DateLastMaint		> trunc(sysdate) - 15	)'
	)	o	on	h.AgreeId	= o.AgreeNbr
			and	h.HolderId	= o.MemberNbr
where	h.IssueId			!= o.IssueNbr
	or	isnull(h.CurrentStatusCode
			, h.StatusCode)	!= o.CardStatCd
	or (h.EffDateTime		!= o.EffDateTime
	or	h.EffDateTime		is null	);

--	update the OSI Status Code mismatches for the listed primary holder status codes...
update	c
set		OSIStatusCode	= coalesce(h.CurrentStatusCode, h.StatusCode)
	,	UpdatedBy		= @by
	,	UpdatedOn		= @on
from	risk.CompromiseCard			c
join	risk.CompromiseCardHolder	h
		on	c.CardId			= h.CardId
		and	c.PrimaryHolderId	= h.HolderId
where	c.OSIStatusCode != coalesce(h.CurrentStatusCode, h.StatusCode)
and		coalesce(h.CurrentStatusCode, h.StatusCode) in ('CLOS','EXP','HOT','REST');

--	update the last used date from OSI
update	c
set		LastUsedOn	= o.DateLastTran
	,	UpdatedBy	= @by
	,	UpdatedOn	= @on
from	risk.CompromiseCard	c
join	openquery(OSI, '
		select	AgreeNbr
			,	trunc(max(DateLastTran)) as DateLastTran
		from	osiBank.CardMember
		where	DateLastTran is not null
		group by AgreeNbr'
	)	o	on	c.AgreeId = o.AgreeNbr
where	c.LastUsedOn	< o.DateLastTran
	or(	c.LastUsedOn	is null	and
		o.DateLastTran	is not null);

--	close agreements where all of the Accounts are closed regardless of status
update	c
set		OSIStatusCode	= 'CLOS'
	,	UpdatedBy		= @by
	,	UpdatedOn		= @on
from	risk.CompromiseCard	c
join	openquery(OSI, '
		select	aap.AgreeNbr
		from	osiBank.AcctAgreementPers	aap
		join	osiBank.CardAgreement		ca
				on	aap.AgreeNbr = ca.AgreeNbr
		join	osiBank.Acct				a
				on	aap.AcctNbr = a.AcctNbr
		where	ca.AgreeTypCd < ''VRU''
		group by aap.AgreeNbr, aap.PersNbr
		having sum(decode(a.CurrAcctStatCd, ''ACT'', 1, 0)) = 0'
	)	o	on	c.AgreeId = o.AgreeNbr
where	c.OSIStatusCode != 'CLOS';

--	update non-calculating values on subsequent reports on a card to the initial report
update	s
set		Comments		= left('Initially report on ' + c.Compromise
							+ ' compromise in alert ' + a.Alert + '.' 
							+ isnull('  Notes: ' + i.Comments, '.'), 255)
	,	OSIStatusCode	= i.OSIStatusCode
	,	CNSStatus		= i.CNSStatus
	,	CNSStatusOn		= i.CNSStatusOn
	,	LastUsedOn		= i.LastUsedOn
	,	UpdatedBy		= @by
	,	UpdatedOn		= @on
from	risk.Compromise			c
join	risk.CompromiseAlert	a
		on	c.CompromiseId = a.CompromiseId
join	risk.CompromiseCard		i	--	inital report
		on	a.AlertId = i.AlertId
join	risk.CompromiseCard		s	--	subsequent reports
		on	i.CardNumber	=	s.CardNumber
		and	i.CardId		!=	s.CardId
where	i.IsInitialReport	=	1
and		s.IsInitialReport	=	0
and	(	(i.OSIStatusCode	is not null and i.OSIStatusCode != s.OSIStatusCode)
	or	(i.CNSStatus		is not null	and i.CNSStatus		!= s.CNSStatus)
	or	(i.CNSStatusOn		is not null	and	i.CNSStatusOn	!= s.CNSStatusOn)
	or	(i.LastUsedOn		is not null and i.LastUsedOn	!= s.LastUsedOn	)	)

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO