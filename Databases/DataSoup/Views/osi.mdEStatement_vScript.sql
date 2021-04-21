use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[mdEStatement_vScript]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[mdEStatement_vScript]
GO
setuser N'osi'
GO
CREATE view osi.mdEStatement_vScript
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/10/2009
Purpose  :	Generates the insert/delete SQL script for the OSI [CUST]UserField
			tables to support the enrolling/un-enrolling for eStatements.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	case isnull(s.MemberNumber, 0)
		when 0 then	'delete ' + o.Type + 'UserField where ' + o.Type + 'Nbr = '
				+	cast(o.CustNbr as varchar(22)) + ' and UserFieldCd = ''EST'';'
		when o.MemberAgreeNbr then	'update ' + o.Type + 'UserField set Value = ''Y'' where '
								+	o.Type + 'Nbr = ' + cast(c.CustNbr as varchar(22))
								+	' and UserFieldCd = ''EST'';'
		when c.MemberAgreeNbr then	'insert into ' + c.Type + 'UserField (' + c.Type
								+	'Nbr, UserFieldCd, Value, DateLastMaint) ' + 'values ('
								+	cast(c.CustNbr as varchar(22)) + ',''EST'', ''Y'',sysdate);'
		else '' end	as Script
		--	members that have the eStatements User Field...
from	openquery(OSI, '
		select	/*+CHOOSE*/
				a.MemberAgreeNbr
			,	f.PersNbr	as CustNbr
			,	f.Value
			,	''Pers''	as Type
		from	PersUserField	f
			,	MemberAgreement	a
		where	f.PersNbr		= a.PrimaryPersNbr
		and		f.UserFieldCd	= ''EST''
			UNION ALL
		select	a.MemberAgreeNbr
			,	f.OrgNbr	as CustNbr
			,	f.Value
			,	''Org''	as Type
		from	OrgUserField	f
			,	MemberAgreement	a
		where	f.OrgNbr		= a.PrimaryOrgNbr
		and		f.UserFieldCd	= ''EST''')	o
full outer join
		osi.mdEStatement		s	--	members in the file
		on	o.MemberAgreeNbr = s.MemberNumber
left join	--	all members in OSI...
		openquery(OSI, '
		select	/*+CHOOSE*/
				MemberAgreeNbr
			,	nvl(PrimaryPersNbr,
					PrimaryOrgNbr)	as CustNbr
			,	case nvl(PrimaryPersNbr, 0)
				when PrimaryPersNbr then ''Pers''
				else ''Org'' end	as Type
		from MemberAgreement')	c
		on	s.MemberNumber = c.MemberAgreeNbr
where	s.MemberNumber		is null				--	they dropped eStatements
or	(	o.MemberAgreeNbr	is null				--	they signed up for eStatements
	and	c.MemberAgreeNbr	is not null	)
or	(	o.MemberAgreeNbr	= s.MemberNumber	--	in both but the flag is N
	and	o.Value				= 'N' );
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO