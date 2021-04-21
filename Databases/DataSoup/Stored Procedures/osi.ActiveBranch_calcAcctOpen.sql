use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranch_calcAcctOpen]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ActiveBranch_calcAcctOpen]
GO
setuser N'osi'
GO
create procedure osi.ActiveBranch_calcAcctOpen
	@MonthsOffset	tinyint
,	@ExcludeList	varchar(50)
,	@StepId			tinyint
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/20/2010
Purpose  :	Assigns Members based on account openings for the monthly offset.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@openedOn	datetime


declare	@exclusions	table
	(	BranchCd varchar(6) primary key );

declare	@members	table
	(	MemberNumber	bigint		primary key
	,	BranchCd		varchar(6)	not null
	);

--	add any branches from the exclude list...
if len(isnull(rtrim(@ExcludeList), '')) > 0
begin 
	insert	@exclusions ( BranchCd )
	select	distinct ltrim(rtrim(Value))
	from	tcu.fn_split(upper(@ExcludeList), ',');
end;
else
begin
	insert	@exclusions ( BranchCd ) values ( 'none' );
end;

--	set the date range based on the month offset...
set	@openedOn = tcu.fn_LastDayOfMonth(dateadd(month, -(@MonthsOffset + 1), getdate()));

--	extract "qualified" members to the table variable...
insert	@members
select	isnull(a.MemberNumber, m.MemberNumber)
	,	coalesce(nullif(a.BranchCd, '0'), m.BranchCd, 'XX')
from	osi.ActiveBranchMember	m
join(	--	return the maximum branch associated with their newest account opening,,
		select	a.MemberNumber
			,	max(case
					when n.OpenedOn > @openedOn then a.BranchCd
					else '0' end)	as BranchCd
		from	osi.ActiveBranchAccount	a
		left join
			(	--	retrieve the newest opening date for all accounts within the past X months...
				select	MemberNumber
					,	max(OpenedOn) as OpenedOn
				from	osi.ActiveBranchAccount
				where	OpenedOn > @openedOn
				group by MemberNumber
			)	n	on	a.MemberNumber	= n.MemberNumber
					and	a.OpenedOn		= n.OpenedOn
		where	a.BranchCd not in ( select BranchCd from @exclusions )
		group by a.MemberNumber
	)	a	on	m.MemberNumber = a.MemberNumber;

--	update existing members that opened an account this cycle...
update	m
set		BranchCd	= t.BranchCd
	,	StepId		= @StepId
from	osi.ActiveBranchMember	m
join	@members				t
		on	m.MemberNumber = t.MemberNumber
where	m.BranchCd	!= t.BranchCd
and		m.BranchCd	= 'XX';

--	assign members to Collections if any Account is in ARFS/Collections
update	m
set		BranchCd	= a.BranchCd
	,	StepId		= 1	--	this is always step 1
from	osi.ActiveBranchMember	m
join(	select	MemberNumber, max(BranchCd) as BranchCd
		from	osi.ActiveBranchAccount
		where	BranchCd in ('18','2402')
		group by MemberNumber )	a
		on	m.MemberNumber = a.MemberNumber
where	m.BranchCd	!= a.BranchCd
and		m.BranchCd	= 'XX';

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO