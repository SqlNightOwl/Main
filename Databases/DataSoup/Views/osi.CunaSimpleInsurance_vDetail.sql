use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[CunaSimpleInsurance_vDetail]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[CunaSimpleInsurance_vDetail]
GO
setuser N'osi'
GO
CREATE view osi.CunaSimpleInsurance_vDetail
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/12/2007
Purpose  :	Extracts Loan Detail records from the CUNASINS file so they can be
			either removed or recounted.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	a.Row
	,	MemberNumber	= cast(rtrim(substring(b.Record, 1, 17)) as bigint)
	,	a.AccountNumber
	,	a.MajorCode
	,	MinorCode		= rtrim(substring(b.Record, 18, 4))
	,	InsuranceType	= rtrim(substring(b.Record, 24, 31))
	,	IntRate			= cast(rtrim(substring(b.Record, 69, 11)) as decimal(6, 3))
	,	Payment			= cast(rtrim(substring(b.Record, 80, 12)) as smallmoney)
	,	a.LoanBal
	,	a.CDPremium
	,	a.CLPremium
from(	select	Row
			,	AccountNumber	= cast(rtrim(substring(Record, 1, 17)) as bigint)
			,	MajorCode		= rtrim(substring(Record, 18, 5))
			,	LoanBal			= cast(nullif(rtrim(substring(Record, 92, 12)), '') as smallmoney)
			,	CDPremium		= cast(nullif(rtrim(substring(Record, 104, 11)), '') as smallmoney)
			,	CLPremium		= cast(nullif(rtrim(substring(Record, 115, 11)), '') as smallmoney)
		from	osi.CunaSimpleInsurance
		where	isnumeric(substring(Record, 92, 12))	= 1
		and		isnumeric(left(Record, 17))				= 1
	)	a
join	osi.CunaSimpleInsurance	b
		on	a.Row + 1 = b.Row
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO