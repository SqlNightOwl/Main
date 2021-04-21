use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[MemberStanding_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[MemberStanding_v]
GO
setuser N'osi'
GO
CREATE view osi.MemberStanding_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	03/10/2009
Purpose  :	Returns a list of Members and their standing.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	o.CustomerType
	,	o.MemberAgreeNbr
	,	o.MemberGroupCd
	,	o.FirstName
	,	o.LastName
	,	o.OrgName
	,	o.Address1
	,	o.Address2
	,	o.CityName
	,	o.StateCd
	,	o.ZipCd
	,	case 
		when isnull(m.BranchCode,'') in ('18', '2402')	then 'Collections'
		when o.Balance < 0	then 'Negative Balance'
		when o.Balance < 25	then 'Low Balance'
		else 'MIGS' end		as StandingType
from	openquery(OSI, '
		select	ma.CustomerType
			,	ma.MemberAgreeNbr
			,	ma.MemberGroupCd
			,	p.FirstName
			,	p.LastName
			,	o.OrgName
			,	ca.Address1
			,	ca.Address2
			,	ca.CityName
			,	ca.StateCd
			,	ca.ZipCd
			,	cast(osiBank.pack_Acct.func_Acct_Bal(a.AcctNbr, ''NOTE'', ''BAL'', trunc(sysdate)) as number(18,2)) as Balance
		from	osiBank.Acct						a
		join	texans.CustomerMemberAgreement_vw	ma
				on	nvl(a.TaxRptForPersNbr, 0)	= nvl(ma.PrimaryPersNbr, 0)
				and nvl(a.TaxRptForOrgNbr , 0)	= nvl(ma.PrimaryOrgNbr , 0)
		join	texans.CustomerAddress_vw			ca
				on	ma.CustomerId	= ca.CustomerId
				and ma.CustomerType	= ca.CustomerType
				and	ca.AddrUseCd	= ''PRI''
		left join	osiBank.Pers					p
				on	p.PersNbr	= a.TaxRptForPersNbr
				and	p.PurgeYN	= ''N''
				and	p.DateBirth < texans.pkg_Date.DateAdd(''year'', -18, trunc(sysdate))
		left join	osiBank.Org						o
				on	o.OrgNbr	= a.TaxRptForOrgNbr
				and	o.PurgeYN	= ''N''
		where	a.MjAcctTypCd		= ''SAV''
		and		a.CurrMiAcctTypCd	in (''BSHS'',''CSHS'')
		and		a.CurrAcctStatCd	in (''ACT'', ''DORM'')
		and		nvl(p.LastName, o.OrgName) is not null
	')	o
left join
		osi.ActiveBranchMember	m
		on	o.MemberAgreeNbr = m.MemberNumber;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO