use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[risk].[CompromiseCard_vHolder]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [risk].[CompromiseCard_vHolder]
GO
setuser N'risk'
GO
CREATE view risk.CompromiseCard_vHolder
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/01/2009
Purpose  :	Retrieve the Card Holder information from OSI.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	cast(PersNbr	as int)	as PersNbr
	,	cast(AgreeNbr	as int)	as AgreeNbr
	,	cast(MemberNbr	as int)	as MemberNbr
	,	cast(IssueNbr	as int)	as IssueNbr
	,	IssueDate
	,	ExpireDate
	,	CurrStatusCd
	,	CardHolder
	,	left(Address1	, 50)	as Address1
	,	left(Address2	, 50)	as Address2
	,	left(CityName	, 50)	as City
	,	left(StateCd	, 2)	as State
	,	left(ZipPlus	, 10)	as ZipCode
	,	left(Phone		, 14)	as Phone
	,	left(Mobile		, 14)	as Mobile
from	openquery(OSI, '
		select	cp.PersNbr
			,	cmi.AgreeNbr
			,	cmi.MemberNbr
			,	cmi.IssueNbr
			,	trunc(cmi.IssueDate)	as IssueDate
			,	trunc(cmi.ExpireDate)	as ExpireDate
			,	cmi.CurrStatusCd
			,	p.FirstName ||'' ''|| p.LastName	as CardHolder
			,	ad.Address1
			,	ad.Address2
			,	ad.CityName
			,	ad.StateCd
			,	ad.ZipPlus
			,	nvl(ph.Phone, ph.Business)	as Phone
			,	ph.Mobile
		from	osiBank.CardAgreement		ca
		join	osiBank.CardPers			cp
				on	ca.AgreeNbr	= cp.AgreeNbr
		join	osiBank.Pers				p
				on	cp.PersNbr = p.PersNbr
		join	osiBank.CardMember			cm
				on	cp.AgreeNbr	= cm.AgreeNbr
				and	cp.PersNbr	= cm.PersNbr
		join	osiBank.CardMemberIssue		cmi
				on	cm.AgreeNbr		= cmi.AgreeNbr
				and	cm.MemberNbr	= cmi.MemberNbr
				and	cm.CurrIssueNbr	= cmi.IssueNbr
		left join
				texans.CustomerAddress_vw	ad
				on	nvl(ca.OwnerPersNbr, 0) = nvl(ad.PersNbr, 0)
				and	nvl(ca.OwnerOrgNbr , 0) = nvl(ad.OrgNbr , 0)
				and	ad.AddrUseCd			= ''PRI''
		left join 
			(	select	PersNbr
					,	OrgNbr
					,	max(decode(PhoneUseCd, ''PER'' , FullPhoneNbr, null))	as Phone
					,	max(decode(PhoneUseCd, ''CELL'', FullPhoneNbr, null))	as Mobile
					,	max(decode(PhoneUseCd, ''BUS'' , FullPhoneNbr, null))	as Business
				from	texans.CustomerPhone_vw
				where	PhoneUseCd	in (''BUS'',''CELL'',''PER'')
				and		CustomerId	> 0
				group by PersNbr, OrgNbr
			)	ph	on	nvl(ca.OwnerPersNbr, 0) = nvl(ph.PersNbr, 0)
					and	nvl(ca.OwnerOrgNbr , 0) = nvl(ph.OrgNbr , 0)
		where	ca.AgreeTypCd < ''VRU''');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO