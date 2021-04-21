use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranch_calcTxnHist]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ActiveBranch_calcTxnHist]
GO
setuser N'osi'
GO
CREATE procedure osi.ActiveBranch_calcTxnHist
	@MonthsOffset	tinyint
,	@ExcludeList	varchar(50)
,	@MinimumItems	int
,	@StepId			tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	11/18/2008
Purpose  :	Calculates the Member's ActiveBranch value
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
08/25/2009	Paul Hunter		Changed logic to remove members having less than the
							75% threshold for moving branches.
01/18/2010	Paul Hunter		Chaged to match new logic for Active Branch.
————————————————————————————————————————————————————————————————————————————————
*/

set	nocount on;

declare
	@period	int

declare	@exclusions	table
	(	BranchCd	varchar(6)	primary key
	,	IsDefault	tinyint		not null
	);

create	table #summary
	(	MemberNumber	bigint			not null
	,	Transactions	smallint		not null
	,	LastTxnNbr		int				not null
	,	BranchCd		varchar(6)		not null
	,	Ratio			decimal(6,5)	not null
	,	constraint PK_summary primary key (MemberNumber, BranchCd)
	);

--	always exclude Collecitons/ARFS branches...
insert	@exclusions ( BranchCd, IsDefault ) values ('18'	, 1);
insert	@exclusions ( BranchCd, IsDefault ) values ('2402'	, 1);

--	add any branches from the exclude list...
if len(isnull(rtrim(@ExcludeList), '')) > 0
begin 
	insert	@exclusions ( BranchCd, IsDefault )
	select	distinct ltrim(rtrim(Value)), 0
	from	tcu.fn_split(upper(@ExcludeList), ',');
end;

--	initialize the variables....
set	@period	 = cast(convert(char(8), tcu.fn_FirstDayOfMonth(dateadd(month, -@MonthsOffset, getdate())) - 1, 112) as int)

--	logic to only count 3 or more transactions in steps 3 and 4 otherwise use all transactions...
set	@MinimumItems = case when @MinimumItems < 0 then 0 else @MinimumItems end;

--	collect a summary of the members activity by branch for the past X months...
insert	#summary
select	a.MemberNumber
	,	count(1)					as Transactions
	,	max(t.TransactionNumber)	as LastTxnNbr
	,	t.BranchCd
	,	0							as Ratio
from	osi.ActiveBranchMember		m
join	osi.ActiveBranchAccount		a
		on	m.MemberNumber = a.MemberNumber
join	osi.ActiveBranchTransaction	t
		on	a.AccountNumber = t.AccountNumber
left join
		@exclusions					x
		on	t.BranchCd = x.BranchCd
where	m.BranchCd	= 'XX'
and		t.Period	> @period
and		x.BranchCd	is null
group by
		a.MemberNumber
	,	t.BranchCd
having	count(1) >= @MinimumItems;

--	calculate transaction ratios to the total number transactions...
update	s
set		Ratio	= cast(s.Transactions / cast(t.Total as float) as decimal(6,5))
from	#summary	s
join(	select	MemberNumber
			,	sum(Transactions) as Total
		from	#summary
		group by MemberNumber )	t
		on	s.MemberNumber = t.MemberNumber;

--	if there are only two Branches excluded then assign based on the 100% rule...
if	(select count(1) from @exclusions) = 2
begin
	--	remove records for the Call Center(15/30), Electronic (ET), Remote (RA) or Shared Branching (SB)
	delete	#summary where BranchCd	not in ('15','30','ET','RA','SB');
end;

--	update unassigned members based on the last X months of transactions...
update	m
set		BranchCd	= s.BranchCd
	,	StepId		= @StepId
from	osi.ActiveBranchMember	m
join(	--	collect the last transaction done in cases where the member had
		--	the same number of transactions at multiple branches
		select	b.MemberNumber
			,	b.BranchCd
		from	#summary	b
		join(	--	collect the last transaction number
				select	p.MemberNumber
					,	max(mt.Transactions)	as maxTransactions
					,	max(p.LastTxnNbr)		as maxLastTxnNbr
				from	#summary	p
				join(	-- collect the maximum number of transactions
						select	MemberNumber, max(Transactions) as Transactions
						from	#summary
						group by MemberNumber )	mt
						on	p.MemberNumber	= mt.MemberNumber
						and	p.Transactions	= mt.Transactions
				group by p.MemberNumber )	mp
				on	b.MemberNumber	= mp.MemberNumber
				and	b.Transactions	= mp.maxTransactions
				and	b.LastTxnNbr	= mp.maxLastTxnNbr	)	s
		on	m.MemberNumber	= s.MemberNumber
where	m.BranchCd	= 'XX';	--	they're not assigned to any branch

drop table #summary;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO