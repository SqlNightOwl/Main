use DataSoup
go
SET QUOTED_IDENTIFIER ON 
GO
SET ANSI_NULLS ON 
GO
if exists (select * from dbo.sysobjects where id = object_id(N'[wh].[dim_Date_process]') and OBJECTPROPERTY(id, N'IsProcedure') = 1)
drop procedure [wh].[dim_Date_process]
GO
setuser N'wh'
GO
CREATE procedure wh.dim_Date_process
as
/*
————————————————————————————————————————————————————————————————————————————————
			© 2000-10 - Texans Credit Union - All Rights Reserved.
————————————————————————————————————————————————————————————————————————————————
Developer:	Paul Huner
Created  :	04/03/2009
Purpose  :	Builds the date dimension for the current month.  This is intended
			to run shortly after midnight on the first day of the month.
History  :
   Date     Developer       Description
——————————  ——————————————  ————————————————————————————————————————————————————
————————————————————————————————————————————————————————————————————————————————
*/

set nocount on;

declare
	@dateValue		datetime
,	@dateId			int
,	@dayNumber		tinyint
,	@dayOfYear		smallint
,	@EOM			datetime
,	@MONTH_NAME		varchar(9)
,	@MONTH_NUMBER	tinyint
,	@QUARTER_NAME	char(7)
,	@QUARTER_NUMBER	tinyint
,	@YEAR_NUMBER	smallint

--	initialize the date variables...
select	@dateValue	= tcu.fn_FirstDayOfMonth(null)
	,	@dateId		= cast(@dateValue as int);

--	add only if the months hasn't already been loaded...
if not exists (	select DateId from wh.dim_Date where DateId = @dateId )
begin
	--	initialize the date variables and some constants....
	select	@dayNumber		= day(@dateValue)
		,	@dayOfYear		= datepart(dayofyear, @dateValue)
			--	these are unchanging constants for the balance of adding the dates...
		,	@EOM			= dateadd(month, 1, @dateValue)
		,	@MONTH_NAME		= datename(month, @dateValue)
		,	@MONTH_NUMBER	= month(@dateValue)
		,	@QUARTER_NAME	= cast(year(@dateValue) as char(5)) + 'Q' + cast(@QUARTER_NUMBER as char(1))
		,	@QUARTER_NUMBER	= datepart(quarter, @dateValue)
		,	@YEAR_NUMBER	= year(@dateValue)

	while @dateValue < @EOM
	begin
		--	add the date to the dimension...
		insert	wh.dim_Date
		select	@dateId
			,	@dateValue
			,	@MONTH_NUMBER
			,	@dayNumber
			,	datepart(weekday, @dateValue)			as DayOfWeek
			,	@dayOfYear
			,	@YEAR_NUMBER
			,	@QUARTER_NUMBER
			,	datepart(week, @dateValue)				as WeekOfYear
			,	isnull(sum(cast(IsFederal as int)), 0)
			,	isnull(sum(cast(IsCompany as int)), 0)
			,	left(datename(weekday, @dateValue), 3)	as DayOfWeekNameShort
			,	'Week'
			+	case when datepart(weekday, @dateValue) in (1,7)
				then 'end'
				else 'day'
				end									as WeekPart
			,	@QUARTER_NAME
			,	left(@MONTH_NAME, 3)	+
				right('  ' + cast(@dayNumber as varchar(2)), 3) + ', ' +
				cast(@YEAR_NUMBER as varchar(4))	as DateNameShort
			,	@MONTH_NAME +
				right('  ' + cast(@dayNumber as varchar(2)), 3) + ', ' +
				cast(@YEAR_NUMBER as varchar(4))	as DateNameLong
			,	DayOfWeekName		= datename(weekday, @dateValue)
			,	@MONTH_NAME
			,	isnull(max(Holiday), 'not a holiday')
		from	tcu.Calendar
		where	HolidayOn = @dateValue;

		--	increment the tracking variables...
		select	@dateValue	= dateadd(day, 1, @dateValue)
			,	@dayNumber	= @dayNumber + 1
			,	@dayOfYear	= @dayOfYear + 1;
	end;
end;

return @@error;
GO
setuser
GO
SET QUOTED_IDENTIFIER OFF 
GO
SET ANSI_NULLS ON 
GO