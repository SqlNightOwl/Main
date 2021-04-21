use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseCard_vOwner]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[CompromiseCard_vOwner]
GO
setuser N'risk'
GO
CREATE view risk.CompromiseCard_vOwner
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/01/2009
Purpose  :	Retrieve the Card Owner and Member information from OSI.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	cast(ExtCardNbr		as bigint)	as ExtCardNbr
	,	cast(AgreeNbr		as int)		as AgreeNbr
	,	AgreeTypCd
	,	MemberGroupCd
	,	cast(MemberAgreeNbr	as bigint)	as MemberAgreeNbr
	,	Member
	,	cast(OwnerId		as int)		as OwnerId
	,	OwnerType
	,	Owner
	,	DateLastTran
from	openquery(OSI, '
		select	ca.ExtCardNbr
			,	max(ca.AgreeNbr)										as AgreeNbr
			,	max(ca.AgreeTypCd)										as AgreeTypCd
			,	min(coalesce(ca.OwnerPersNbr, ca.OwnerOrgNbr, 0))		as OwnerId
			,	min(decode(ca.OwnerOrgNbr, null,''PERS'',''ORG''))		as OwnerType
			,	min(nvl(o.OrgName, p.FirstName ||'' ''|| p.LastName))	as Owner
			,	min(nvl(ma.MemberAgreeNbr, oma.MemberAgreeNbr))			as MemberAgreeNbr
			,	min(c.Customer)											as Member
			,	min(coalesce( e.EmplType
							, ma.MemberGroupCd
							, oma.MemberGroupCd))						as MemberGroupCd
			,	max(lu.DateLastTran)									as DateLastTran
		from	osiBank.CardAgreement			ca
		left join	osiBank.Pers				p
				on	ca.OwnerPersNbr	= p.PersNbr
		left join	osiBank.Org					o
				on	ca.OwnerOrgNbr	= o.OrgNbr
		left join
			(	select	AgreeNbr, trunc(max(DateLastTran)) as DateLastTran
				from	osiBank.CardMember
				group by AgreeNbr
			)	lu	on	ca.AgreeNbr = lu.AgreeNbr
		left join	osiBank.MemberAgreement		ma
				on	nvl(ca.OwnerPersNbr, 0) = nvl(ma.PrimaryPersNbr, 0)
				and	nvl(ca.OwnerOrgNbr , 0) = nvl(ma.PrimaryOrgNbr , 0)
		--	this handles the non-member owners
		left join	osiBank.CardPers			cp
					on	ca.AgreeNbr = cp.AgreeNbr
		left join	osiBank.AcctAgreementPers	aap
					on	cp.AgreeNbr	= aap.AgreeNbr
					and	cp.PersNbr	= aap.PersNbr
		left join	osiBank.Acct				a
					on	a.AcctNbr =	coalesce(cp.PrimaryChecking
											,cp.PrimarySavings
											,cp.PrimaryLoan)
		left join	osiBank.MemberAgreement		oma
				on	nvl(a.TaxRptForPersNbr, 0) = nvl(oma.PrimaryPersNbr, 0)
				and	nvl(a.TaxRptForOrgNbr , 0) = nvl(oma.PrimaryOrgNbr , 0)
		left join	texans.Customer_vw			c
				on	coalesce(ma.PrimaryPersNbr, oma.PrimaryPersNbr, 0) = nvl(c.PersNbr, 0)
				and	coalesce(ma.PrimaryOrgNbr , oma.PrimaryOrgNbr , 0) = nvl(c.OrgNbr , 0)
		left join
			(	select	PersNbr, ''EMP'' as EmplType
				from	osiBank.PersEmpl
				where	InactiveDate is null
			)	e	on	p.PersNbr = e.PersNbr
		where	ca.AgreeTypCd < ''VRU''
		group by ca.ExtCardNbr');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO