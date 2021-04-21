use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[CunaSimpleInsurance_vSummary]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[CunaSimpleInsurance_vSummary]
GO
setuser N'osi'
GO
CREATE view osi.CunaSimpleInsurance_vSummary
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/12/2007
Purpose  :	Extracts Loan Summary records from the CUNASINS file so the totals
			can be updated.
History  :
   Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Row
	,	MinorCode		= isnull(nullif(rtrim(left(Record, 5)), ''), 'TOTAL')
	,	InsuranceType	= substring(Record, 10, 24)
	,	TypeCount		= cast(rtrim(substring(Record, 55, 9)) as int)
	,	TypeAmount		= cast(rtrim(substring(Record, 65, 17)) as money)
	,	Record
from	osi.CunaSimpleInsurance	with (nolock)
where	Row	> (select min(Row) from osi.CunaSimpleInsurance (nolock) where Record = 'Report Totals:')
and		1	= isnumeric(substring(Record, 55, 9))
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO