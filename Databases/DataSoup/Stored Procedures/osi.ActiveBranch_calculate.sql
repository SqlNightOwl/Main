use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranch_calculate]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ActiveBranch_calculate]
GO
setuser N'osi'
GO
CREATE procedure osi.ActiveBranch_calculate
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	11/18/2008
Purpose  :	Calculates the Member's ActiveBranch value
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
08/25/2009	Paul Hunter		Changed logic to remove members having less than the
							75% threshold for moving branches.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

create table #summary
	(	MemberNumber	bigint			not null
	,	Transactions	smallint		not null
	,	BranchCd		varchar(6)		not null
	,	Ratio			decimal(6,5)	not null
	,	Period			int				not null
	,	constraint PK_summary primary key (MemberNumber, BranchCd)
	);

declare @remoteUsers	table
	(	BranchNumber	smallint	not null primary key
	,	ActiveBranch	varchar(6)	not null
	);

--	identify specific non-branch remote user "branches"
insert	@remoteUsers values( 0, 'SB');	-- shared branch
insert	@remoteUsers values( 2, 'ET');	-- WWW/VRU

insert	#summary
select	a.MemberNumber
	,	Transactions	=	count(t.TransactionId)
	,	BranchCd		=	case t.BranchNumber
							when 41 then isnull(l.ActiveBranch, '--')	--	ATM Active Branch (OrgNbr/"RA")
							else isnull(r.ActiveBranch, cast(t.BranchNumber as varchar(6)))
							end
	,	Ratio			=	0
	,	Period			=	max(t.Period)
from	osi.ActiveBranchMember		m
join	osi.ActiveBranchAccount		a
		on	m.MemberNumber = a.MemberNumber
join	osi.ActiveBranchTransaction	t
		on	a.AccountNumber = t.AccountNumber
left join	tcu.Location_vATM		l	--	get the atm Active Branch
		on	t.NetworkNode = l.NetworkNodeNbr
left join	@remoteUsers			r
		on t.BranchNumber = r.BranchNumber
where	a.BranchCd not in ('18','2402')
group by
		a.MemberNumber
	,	case t.BranchNumber
		when 41 then isnull(l.ActiveBranch, '--')	--	ATM Active Branch (OrgNbr/"RA")
		else isnull(r.ActiveBranch, cast(t.BranchNumber as varchar(6)))
		end;

--	update the total number of transactions for this period and calculate transaction ratios
update	s
set		Ratio	= cast(s.Transactions / cast(t.Total as float) as decimal(6,5))
from	#summary	s
join(	select	MemberNumber, Total = sum(Transactions)
		from	#summary
		group by MemberNumber
	)	t	on	s.MemberNumber = t.MemberNumber;

--	update members having no activity that are not in Collecitons/ARFS
update	m
set		BranchCd		= 'XX'
	,	Transactions	= 0
from	osi.ActiveBranchMember	m
left join #summary				s
		on	m.MemberNumber = s.MemberNumber
where	m.BranchCd		not in ('18','2402', 'XX')
and		s.MemberNumber	is null;

--	delete records that doesn't meet the requiemts for ET, RA and SB branches
delete	#summary
where	(BranchCd =	'ET'			and Ratio < .75)
	or	(BranchCd in ('RA','SB')	and Ratio < 1);

--	only change the members branch when they're listed above
update	m
set		BranchCd		= s.BranchCd
	,	Transactions	= s.Transactions
from	osi.ActiveBranchMember	m
join	#summary				s
		on	m.MemberNumber = s.MemberNumber
join(	/*	all of this is to collect the max Branch in case the member did:
		**		1.	the same maximum number of transactions...
		**		2.	at multiple branches...
		**		3.	on the same day...
		*/
		select	b.MemberNumber, BranchCd = max(b.BranchCd)
		from	#summary	b
		join(	--	collect the last transaction date
				select	p.MemberNumber, maxTransactions = max(mt.Transactions), maxPeriod = max(p.Period)
				from	#summary	p
				join(	-- collect the maximum number of transactions
						select	MemberNumber, Transactions = max(Transactions)
						from	#summary	group by MemberNumber
					)	mt	on	p.MemberNumber	= mt.MemberNumber
							and	p.Transactions	= mt.Transactions
				group by p.MemberNumber
			)	mp	on	b.MemberNumber	= mp.MemberNumber
					and	b.Transactions	= mp.maxTransactions
					and	b.Period		= mp.maxPeriod
		group by b.MemberNumber
	)	mb	on	s.MemberNumber	= mb.MemberNumber
			and	s.BranchCd		= mb.BranchCd
where	m.BranchCd		!=	s.BranchCd
and		m.BranchCd		not	in ('18','2402')
and	(	s.Ratio			>=	.75		--	they did 75% of their transactions at this location
	or	m.BranchCd		=	'XX');	--	or they were not assigned to any branch 
--and		s.Transactions	>= (m.Transactions * .75)

drop table #summary;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO