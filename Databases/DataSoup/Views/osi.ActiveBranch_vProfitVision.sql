use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranch_vProfitVision]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[ActiveBranch_vProfitVision]
GO
setuser N'osi'
GO
CREATE view osi.ActiveBranch_vProfitVision
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/18/2008
Purpose  :	Used for exporting ActiveBranch data for ProfitVision.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	a.AccountNumber
	,	a.MemberNumber
	,	o.CustId
	,	m.BranchCd
from	osi.ActiveBranchAccount	a
join	osi.ActiveBranchMember	m
		on	a.MemberNumber = m.MemberNumber
join	openquery(OSI, '
		select	MemberAgreeNbr
			,	case
				when PrimaryOrgNbr is null then ''P'' || PrimaryPersNbr
				else ''O'' || PrimaryOrgNbr
				end	as CustId
		from	osiBank.MemberAgreement' )	o
		on	a.MemberNumber = o.MemberAgreeNbr;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO