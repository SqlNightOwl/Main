use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[tfInsuranceMarketing_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[tfInsuranceMarketing_v]
GO
setuser N'osi'
GO
CREATE view osi.tfInsuranceMarketing_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/14/2007
Purpose  :	Provides ISI Insurance Marketing file for Texans Financial.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
04/21/2008	Paul Hunter		Replaced columns for Average Balance and Date of Birth
							and with Balance >= 100 and Age.  Removed the Tax Id
							completely.
05/01/2009	Paul Hunter		Changed Transaciton Activity to Y if count > 4.
							Replaced PurgeYN hard-coded value with OptOut flag.
05/28/2009	Paul Hunter		Added PersNbr column.
————————————————————————————————————————————————————————————————————————————————
*/

select	a.FirstName
	,	a.LastName
	,	rtrim(a.Address1 +
		isnull(' ' + a.Address2, ''))			as Address
	,	a.City
	,	a.State
	,	a.Zip
	,	a.Email
	,	a.MjAcct
	,	a.MiAcct
	,	a.AcctNbr
	,	'311987786'								as RTN
	,	a.Age
	,	a.BalanceGTE100
	,	case
		when isnull(t.Transactions, 0) > 4 then 'Y'
		else 'Y' end							as TransactionActivity
	,	a.OptOut
	,	'REG'									as MailType
	,	convert(char(10), a.ContractDate, 101)	as ContractDate
	,	a.PersNbr
from	osi.tfIsiAccount		a
left join
	(	select	PersNbr, AcctNbr, count(1) as Transactions
		from	osi.tfIsiTransaction
		group by PersNbr, AcctNbr )	t
		on	a.PersNbr	= t.PersNbr
		and	a.AcctNbr	= t.AcctNbr
where	left(a.Zip, 3) not in ('000','111','999');
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO