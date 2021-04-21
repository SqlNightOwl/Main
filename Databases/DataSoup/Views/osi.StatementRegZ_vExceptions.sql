use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[osi].[StatementRegZ_vExceptions]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [osi].[StatementRegZ_vExceptions]
GO
setuser N'osi'
GO
CREATE view osi.StatementRegZ_vExceptions
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-09 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	10/08/2009
Purpose  :	Standardized list of data exceptions for the Statement Credit Card Act
			supplement file.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	'Member Number' as Reason
	,	MemberNumber
	,	AccountNumber
	,	MajorType
	,	MinorType
	,	AccruedInterest
	,	CourtesyPeriod
from	osi.StatementRegZ
where	MemberNumber = 0

union all

select	'Payment Info' as Reason
	,	MemberNumber
	,	AccountNumber
	,	MajorType
	,	MinorType
	,	AccruedInterest
	,	CourtesyPeriod
from	osi.StatementRegZ
where	AccruedInterest	< 0
	or	CourtesyPeriod	= 0
	or	DailyRate		< 0;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO