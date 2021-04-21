use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Holiday_v]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Holiday_v]
GO
setuser N'tcu'
GO
CREATE view tcu.Holiday_v
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-08 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	12/25/2006
Purpose  :	Returns list of holiday dates for the prior, current and next year.
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

select	Holiday
	,	HolidayMonth	= MonthOccurs
	,	HolidayYear		= year(getdate()) - 1
	,	HolidayOn		= tcu.fn_HolidayDate(year(getdate()) - 1, MonthOccurs, Frequency, DayOccurs, IsFloating)
	,	IsCompany
	,	IsFederal
from	tcu.Holiday with (nolock)

union all

select	Holiday
	,	HolidayMonth	= MonthOccurs
	,	HolidayYear		= year(getdate())
	,	HolidayOn		= tcu.fn_HolidayDate(year(getdate()), MonthOccurs, Frequency, DayOccurs, IsFloating)
	,	IsCompany
	,	IsFederal
from	tcu.Holiday with (nolock)

union all

select	Holiday
	,	HolidayMonth	= MonthOccurs
	,	HolidayYear		= year(getdate()) + 1
	,	HolidayOn		= tcu.fn_HolidayDate(year(getdate()) + 1, MonthOccurs, Frequency, DayOccurs, IsFloating)
	,	IsCompany
	,	IsFederal
from	tcu.Holiday with (nolock)
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO