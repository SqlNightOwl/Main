create function tcu.fn_DateDetails
(	@dateTime datetime = null	)
returns @results table
(	effectiveDate		datetime	not null	primary key
,	effectiveTime		datetime	not null
,	dayName				varchar(60)	not null
,	dayOfMonth			smallint	not null
,	dayOfWeek			smallint	not null
,	theDay				smallint	not null
,	bitwise				smallint	not null
,	bitwiseDay			int			not null
,	lastDayOfMonth		datetime	not null
,	lastDay				smallint	not null
,	businessDayFirst	smallint	not null
,	businessDayLast		smallint	not null
,	isBusinessDayFirst	smallint	not null
,	isBusinessDayLast	smallint	not null
,	weekOfMonth			int			not null
,	monthType			int			not null
,	isCompanyHoliday	smallint	not null
,	isFederalHoliday	smallint	not null
,	isLastDayOfMonth	smallint	not null	
)
as
/*
????????????????????????????????????????????????????????????????????????????????
			c 2000-10 ? Texans Credit Union ? All rights reserved.
????????????????????????????????????????????????????????????????????????????????
Developer:	Paul Hunter
Created  :	06/22/2008
Purpose  :	Statistics about effective date and time .
History  :
  Date		Developer		Description
??????????	??????????????	????????????????????????????????????????????????????
01/07/2009	Paul Hunter		Changed to use the tcu.Calendar table
????????????????????????????????????????????????????????????????????????????????
*/
begin
	set	@dateTime = isnull(@dateTime, getdate());

	insert	@results
	select	effectiveDate		=	cast(convert(char(10), @dateTime, 101) as datetime)
		,	effectiveTime		=	cast(convert(char(8), @dateTime, 14) as datetime)
		,	dayName				=	datename(weekday, @dateTime)
		,	dayOfMonth			=	day(@dateTime)
		,	dayOfWeek			=	datepart(weekday, @dateTime)
		,	theDay				=	day(@dateTime)
		,	bitwise				=	power(2, datepart(weekday, @dateTime))
		,	bitwiseDay			=	power(2, datepart(weekday, @dateTime))
		,	lastDayOfMonth		=	tcu.fn_LastDayOfMonth(@dateTime)
		,	lastDay				=	day(tcu.fn_LastDayOfMonth(@dateTime))
		,	businessDayFirst	=	day(tcu.fn_FirstBusinessDay(@dateTime))
		,	businessDayLast		=	day(tcu.fn_LastBusinessDay(@dateTime))
		,	isBusinessDayFirst	=	case day(tcu.fn_FirstBusinessDay(@dateTime))
									when day(@dateTime) then 1 else 0 end
		,	isBusinessDayLast	=	case day(day(tcu.fn_LastBusinessDay(@dateTime)))
									when day(@dateTime) then 1 else 0 end
		,	weekOfMonth			=	case
									when day(@dateTime) / 7.0 <= 1 then 2048	--	first
									when day(@dateTime) / 7.0 <= 2 then 4096	--	second
									when day(@dateTime) / 7.0 <= 3 then 8192	--	third
									when day(@dateTime) / 7.0 <= 4 and
										--	is there less than a week left in the month?
										 day(tcu.fn_LastDayOfMonth(@dateTime)) - day(@dateTime) > 6 then 16384
									else 32768 end	--	last week of the month
		,	monthType			=	case month(@dateTime) % 2
									when 0 then 65536		--	even numbered month
									else 131072 end			--	odd numbered month
		,	isCompanyHoliday	=	case count(1) when 1 then sum(cast(IsCompany as tinyint)) else 0 end
		,	isFederalHoliday	=	case count(1) when 1 then sum(cast(IsFederal as tinyint)) else 0 end
		,	isLastDayOfMonth	=	case day(dateadd(day, 1, @dateTime)) when 1 then 1 else 0 end
	from	tcu.Calendar
	where	HolidayOn			=	cast(convert(char(10), @dateTime, 121) as datetime);
	return;
end;
GO
