use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[RewardsNow_vAddressVerification]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[RewardsNow_vAddressVerification]
GO
setuser N'osi'
GO
CREATE view osi.RewardsNow_vAddressVerification
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	04/09/2008
Purpose  :	Used by RewardsNow for re-verification of addresses associated with
			the Account (DDA)
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
05/16/2009	Paul Hunter		Compiled against the DNA schema.
————————————————————————————————————————————————————————————————————————————————
*/

select	cast(AcctNbr as varchar(22))	as DDA
	,	Name1
	,	Address1
	,	Address2
	,	CityName						as City
	,	StateCd							as State
	,	ZipPlus							as Zip
from	openquery(OSI, '
		select	distinct
				a.AcctNbr
			,	p.FirstName ||'' ''|| p.LastName as Name1
			,	ca.Address1
			,	ca.Address2
			,	ca.CityName
			,	ca.StateCd
			,	ca.ZipPlus
		from	osiBank.Acct				a
		join	osiBank.Pers				p
				on	a.TaxRptForPersNbr = p.PersNbr
		join	texans.CustomerAddress_vw	ca
				on	ca.PersNbr		= p.PersNbr
				and	ca.AddrUseCd	= ''PRI''
		where	a.MjAcctTypCd		= ''CK''
		and		a.CurrAcctStatCd	not in (''APPR'',''ORIG'')
		and		p.PurgeYN			= ''N''');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO