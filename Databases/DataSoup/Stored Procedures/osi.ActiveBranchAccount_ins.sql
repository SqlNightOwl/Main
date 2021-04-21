use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranchAccount_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ActiveBranchAccount_ins]
GO
setuser N'osi'
GO
CREATE procedure osi.ActiveBranchAccount_ins
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	01/20/2010
Purpose  :	Loads Accounts and Members from OSI for Active Branch processing.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

insert	osi.ActiveBranchAccount
	(	MemberNumber
	,	AccountNumber
	,	BranchCd
	,	OpenedOn
	)	
select	o.MemberAgreeNbr
	,	o.AcctNbr
	,	o.ActiveBranchNbr
	,	o.ContractDate
from	osi.ActiveBranchAccount	a
right join
		openquery(OSI, '
		select	MemberAgreeNbr
			,	AcctNbr
			,	ActiveBranchNbr
			,	ContractDate
		from	texans.ActiveBranch_Acct_vw')
		o	on	a.AccountNumber = o.AcctNbr
where	a.AccountNumber is null;

--	load any new or missing members...
insert	osi.ActiveBranchMember
	(	MemberNumber
	,	BranchCd
	,	StepId
	)
select	a.MemberNumber
	,	'XX'	--	they are assigned by a later procedure...
	,	0		--	initial/unassigned
from	osi.ActiveBranchAccount	a
left join
		osi.ActiveBranchMember	m
		on	m.MemberNumber = a.MemberNumber
where	m.MemberNumber  is null
group by a.MemberNumber;

--	assign members to ARFS/Collecitons...
update	m
set		BranchCd	= c.BranchCd
	,	StepId		= 1
from	osi.ActiveBranchMember	m
join(	select	MemberNumber, max(BranchCd) as BranchCd
		from	osi.ActiveBranchAccount
		where	BranchCd in ('18','2402')
		group by MemberNumber )	c
		on	m.MemberNumber = c.MemberNumber
where	m.BranchCd != c.BranchCd;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO