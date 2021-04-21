use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[IrsDetail_vMailMerge]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[IrsDetail_vMailMerge]
GO
setuser N'osi'
GO
CREATE view osi.IrsDetail_vMailMerge
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/13/2008
Purpose  :	Used as the basis for creating Mail Merge extracts.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	d.RowId
	,	d.IrsReportId
	,	d.TaxId
	,	d.AccountNumber
	,	d.MemberNumber
	,	rtrim(replace(substring(d.Detail, 248, 40), ',', ', '))	as FirstPayee
	,	rtrim(replace(substring(d.Detail, 288, 40), ',', ', '))	as SecondPayee
	,	d.Address
	,	d.City
	,	d.State
	,	d.Zip
	,	substring(d.Detail, 2, 4)			as TaxYear
	,	rtrim(substring(d.Detail, 247, 1))	as IsForeignCountry
	,	cast(d.Amount1 / 100.0 as money)	as Amount1
	,	cast(d.Amount2 / 100.0 as money)	as Amount2
	,	cast(d.Amount3 / 100.0 as money)	as Amount3
	,	cast(d.Amount4 / 100.0 as money)	as Amount4
	,	cast(d.Amount5 / 100.0 as money)	as Amount5
	,	cast(d.Amount6 / 100.0 as money)	as Amount6
	,	cast(d.Amount7 / 100.0 as money)	as Amount7
	,	cast(d.Amount8 / 100.0 as money)	as Amount8
	,	cast(d.Amount9 / 100.0 as money)	as Amount9
	,	cast(d.AmountA / 100.0 as money)	as AmountA
	,	cast(d.AmountB / 100.0 as money)	as AmountB
	,	cast(d.AmountC / 100.0 as money)	as AmountC
	,	d.Detail
from	osi.IrsDetail	d
where	d.RowType = 'B';
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO