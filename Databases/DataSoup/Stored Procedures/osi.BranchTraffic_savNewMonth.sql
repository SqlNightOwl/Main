use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[BranchTraffic_savNewMonth]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [osi].[BranchTraffic_savNewMonth]
GO
setuser N'osi'
GO
CREATE procedure osi.BranchTraffic_savNewMonth
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	07/31/2007
Purpose  :	Loads the Branch Traffic at the desired detail level for the prior
			month.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

insert	osi.BranchTraffic
	(	PostedOn
	,	BranchNbr
	,	CategoryCd
	,	Items
	,	Amount
	)
select	PostDate
	,	LocOrgNbr
	,	RtxnTypCatCd
	,	Items
	,	Amount
from	openquery(OSI, '
		select	t.LocOrgNbr
			,	t.RtxnTypCatCd
			,	t.PostDate
			,	count(1)		Items
			,	sum(t.TranAmt)	Amount
		from	osiBank.rw_Transaction_view t
		where	t.CurrRtxnStatCd	= ''C''
		and		t.PostDate			between	pkg_Date.FirstDay_Months(-1)
										and	pkg_Date.LastDay_Months(-1)
		and		t.LocOrgNbr			in (select OrgNbr from texans.Branch_vw where IsBranch = 1)
		and		t.RtxnTypCatCd		not in (''BYDN'', ''CHRG'', ''FINT'', ''LFC'', ''LINS'', ''LIP'', ''LOAN'', ''NGAM'', ''NPFM'')
		group by t.PostDate, t.LocOrgNbr, t.RtxnTypCatCd
		order by t.PostDate, t.LocOrgNbr, t.RtxnTypCatCd');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO