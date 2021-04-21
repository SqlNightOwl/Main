use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[ActiveBranch_vRaddon]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[ActiveBranch_vRaddon]
GO
setuser N'osi'
GO
CREATE view osi.ActiveBranch_vRaddon
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	11/18/2008
Purpose  :	Used for exporting ActiveBranch data for Raddon.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
01/20/2009	Paul Hunter		Added the OSI Branch to the results.
05/16/2009	Paul Hunter		Compiled against the DNA schema
02/08/2010	Paul Hunter		Removed IsActiveBranch criteria from the OSI select
							to limit the number of "Unknown Branch" records.
————————————————————————————————————————————————————————————————————————————————
*/

select	m.MemberNumber
	,	o.TaxId
	,	m.BranchCd
	,	isnull(b.Branch, 'Unknown Branch')	as Branch
from	osi.ActiveBranchMember	m
join	openquery(OSI, '
				select	MemberAgreeNbr
			,	case nvl(PrimaryPersNbr, 0)
				when PrimaryPersNbr then cast(osiBank.pack_TaxId.func_GetTaxId(PrimaryPersNbr,''P'',''N'',null) as char(9))
				else cast(osiBank.pack_TaxId.func_GetTaxId(PrimaryOrgNbr,''O'',''N'',''FEIN'') as char(9))
				end	as TaxId
		from	MemberAgreement' )	o
		on	m.MemberNumber = o.MemberAgreeNbr
left join
	(	--	return the branch names from OSI
		select	BranchCd, Branch
		from	openquery(OSI, '
		select	cast(OrgNbr as varchar(6))	as BranchCd
			,	OrgName						as Branch
		from	texans.Branch_vw')
			union all
		select	'ET', N'Electronic'
			union all
		select	'RA', N'Remote Access'
			union all
		select	'SB', N'Shared Branch'
			union all
		select	'XX', N'Inactive'
	)	b	on m.BranchCd = b.BranchCd;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO