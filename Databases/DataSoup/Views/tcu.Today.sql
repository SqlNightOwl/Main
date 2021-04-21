use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[tcu].[Today]') and OBJECTPROPERTY(id, N'IsView') = 1)
drop view [tcu].[Today]
GO
setuser N'tcu'
GO
CREATE view tcu.Today
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 • Texans Credit Union • All rights reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Hunter
Created  :	02/23/2007
Purpose  :	Statistics about current date and time (Today).
History  :
  Date		Developer		Description
——————————	——————————————	————————————————————————————————————————————————————
09/06/2007	Paul Hunter		Added Week Of Month calculation
10/05/2007	Paul Hunter		Set filesAreLoaded to false as the Access Advantage
							files are no longer received.
01/07/2010	Paul Hunter		Changed to use the tcu.Calendar table.
————————————————————————————————————————————————————————————————————————————————
*/

select	currentDate			=	cast(convert(char(10), getdate(), 101) as datetime)
	,	currentTime			=	cast(convert(char(8), getdate(), 14) as datetime)
	,	dayName				=	datename(weekday, getdate())
	,	dayOfMonth			=	day(getdate())
	,	dayOfWeek			=	datepart(weekday, getdate())
	,	theDay				=	day(getdate())
	,	bitwise				=	power(2, datepart(weekday, getdate()))
	,	bitwiseDay			=	power(2, datepart(weekday, getdate()))
	,	lastDayOfMonth		=	tcu.fn_LastDayOfMonth(getdate())
	,	lastDay				=	day(tcu.fn_LastDayOfMonth(getdate()))
	,	businessDayFirst	=	day(tcu.fn_FirstBusinessDay(getdate()))
	,	businessDayLast		=	day(tcu.fn_LastBusinessDay(getdate()))
	,	weekOfMonth			=	case
								when day(getdate()) / 7.0 <= 1 then 2048	--	first
								when day(getdate()) / 7.0 <= 2 then 4096	--	second
								when day(getdate()) / 7.0 <= 3 then 8192	--	third
								when day(getdate()) / 7.0 <= 4 and
									--	is there less than a week left in the month?
									 day(tcu.fn_LastDayOfMonth(getdate())) - day(getdate()) > 6 then 16384
								else 32768 end	--	last
	,	monthType			=	case month(getdate()) % 2
								when 0 then 65536		--	even numbered month
								else 131072 end			--	odd numbered month
	,	isCompanyHoliday	=	case count(1) when 1 then sum(cast(IsCompany as tinyint)) else 0 end
	,	isFederalHoliday	=	case count(1) when 1 then sum(cast(IsFederal as tinyint)) else 0 end
	,	isLastDayOfMonth	=	case day(dateadd(day, 1, getdate())) when 1 then 1 else 0 end
	,	HolidayName			=	isnull(max(Holiday), 'not a holiday')
from	tcu.Calendar
where	HolidayOn			= cast(convert(char(10), getdate(), 121) as datetime);
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO