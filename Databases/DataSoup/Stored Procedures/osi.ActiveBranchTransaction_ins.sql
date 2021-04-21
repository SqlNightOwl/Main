use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranchTransaction_ins]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[ActiveBranchTransaction_ins]
GO
setuser N'osi'
GO
create procedure osi.ActiveBranchTransaction_ins
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huter
Created  :	01/20/2010
Purpose  :	Loads transactions for Active Branch.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare @remoteUsers	table
	(	BranchNumber	int not null primary key
	,	BranchCd		varchar(6)	not null
	);

--	identify specific non-branch remote user "branches"
insert	@remoteUsers values( 0, 'SB');	--	shared branch
insert	@remoteUsers values( 2, 'ET');	--	WWW/VRU

insert	osi.ActiveBranchTransaction
	(	Period
	,	AccountNumber
	,	TransactionNumber
	,	SourceCd
	,	TypeCd
	,	BranchCd
	)
select	cast(n.Period as int)
	,	n.AcctNbr
	,	n.RtxnNbr
	,	n.RtxnSourceCd
	,	n.RtxnTypCd
	,	case n.ActiveBranchNbr
		when 41 then isnull(a.ActiveBranch, '--')	--	ATM Active Branch (OrgNbr/"RA")
		else isnull(r.BranchCd, cast(n.ActiveBranchNbr as varchar(6))) 
		end
from	openquery(OSI, '
		select	/*+CHOOSE*/
				to_char(OrigPostDate,''YYYYMMDD'') as Period
			,	AcctNbr
			,	RtxnNbr
			,	RtxnSourceCd
			,	RtxnTypCd
			,	ActiveBranchNbr
			,	NtwkNodeNbr
		from	texans.ActiveBranch_Rtxn_vw' )	n	--	new
left join
		osi.ActiveBranchTransaction				c	--	current
		on	n.AcctNbr	= c.AccountNumber
		and	n.RtxnNbr	= c.TransactionNumber
left join
		tcu.Location_vATM						a	--	amt's
		on	a.NetworkNodeNbr		= n.NtwkNodeNbr
		and	a.IncludeInActiveBranch	= 1
left join	@remoteUsers						r	--	remote locations
		on n.ActiveBranchNbr = r.BranchNumber
where	c.AccountNumber is null;

--	remove atm transactions that were assigned to "--" or came thru 3097 (Surcharge Free ATM)
delete	osi.ActiveBranchTransaction
where	BranchCd in ('--', '3097');

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO