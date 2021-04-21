use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[FuturesAccount_vMailing]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[FuturesAccount_vMailing]
GO
setuser N'osi'
GO
CREATE view osi.FuturesAccount_vMailing
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	09/08/2008
Purpose  :	Provides BCP exportable mailing list results for conversion from
			Future Account to regular checking based on:
			•	Member has an "Active" "Futures Account" minor
			•	Member is over 24 years old at the end of the preceeding month
					(12 * 24) + 1 = 289 months
			•	Member is not purged
			•	Member mail type code is not "Hold"
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	'Account'		as AcctNbr
	,	'DOB'			as DateOfBirth
	,	'Member Name'	as MemberName
	,	'Address 1'		as Address1
	,	'Address 2'		as Address2
	,	'City'			as CityName
	,	'State'			as StateCd
	,	'Zip'			as ZipPlus
	,	0				as RowType

union all

select	cast(AcctNbr as varchar(22))		as AcctNbr
	,	convert(char(10), DateBirth, 101)	as DateOfBirth
	,	MemberName
	,	Address1
	,	Address2
	,	CityName
	,	StateCd
	,	ZipPlus
	,	1									as RowType
from	openquery(OSI, '
		select	a.AcctNbr
			,	p.DateBirth
			,	p.FirstName || '' ''
			||	case
				when p.MdlInit is null then null
				else p.MdlInit || ''. '' end
			||	p.LastName		as MemberName
			,	ca.Address1
			,	ca.Address2
			,	ca.CityName
			,	ca.StateCd
			,	ca.ZipPlus
		from	osiBank.Pers				p
		inner join
				osiBank.Acct				a
				on	p.PersNbr = a.TaxRptForPersNbr
		inner join
				texans.CustomerAddress_vw	ca
				on	p.PersNbr = ca.PersNbr
		where	a.CurrAcctStatCd	=	''ACT''
		and		a.MjAcctTypCd		=	''CK''
		and		a.CurrMiAcctTypCd	=	''CFY''
		and		a.MailTypCd			!=	''HOLD''
		and		p.PurgeYN			=	''N''
		and		p.DateBirth			<=	last_day(add_months(trunc(sysdate), (25 * -12) - 1)) --	25 years old at last month end
		and		ca.AddrUseCd		=	''PRI''
		and		ca.ZipCd			!=	''99999''');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO