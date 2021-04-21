SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- database  name       : Invoices
-- procedure name       : [fn_SetLastDayOfMonth]
-- description          : This procedures calculates last day of date parameter that is  
--                      : passed to this function. 
-- input parameters     : @Date datetime.
-- output               : @Calculated_EndDate_day if successful
-- Creation Date        : 06-August-2007 
-- Author               : MIS                     
-- code examples        : select Invoices.DBO.fn_SetLastDayOfMonth('1/1/2009')
--                      : select Invoices.DBO.fn_SetLastDayOfMonth('12/1/2008')
---------------------------------------------------------------------------------------------
--Important Notes : This function is used for invoicing engine.
---------------------------------------------------------------------------------------------
-- modification history:
---------------------------------------------------------------------------------------------

CREATE function [invoices].[fn_SetLastDayOfMonth] (@Date datetime)
returns datetime
as
BEGIN --begin function
------------------------
--declare variables - 
------------------------
-- declare @Date datetime
-- set @Date = '1/1/07' 
declare @Calculated_StartDate varchar(10)
declare @Calculated_StartDate_Month varchar(2)
declare @Calculated_StartDate_day varchar(2)
declare @Calculated_StartDate_year varchar(4)

--set the end date 
declare @Calculated_EndDate varchar
declare @Calculated_EndDate_day datetime
declare @Calculated_EndDate_year datetime

	--select a month e.g. 5/20/2007, then set it to next month..i.e. 6th month.
 	select @Calculated_StartDate_Month = cast(datepart(mm,dateadd(mm,1,@Date)) as varchar(2))	
-- 	select @Calculated_StartDate_Month as '@Calculated_StartDate_Month' --set it to next month

-- 	--set the day variable on 01 so it is the first day.
        select @Calculated_StartDate_day = '01'
-- 	select @Calculated_StartDate_day as '@Calculated_StartDate_day'

	--select the year i.e 2007 but if it the 12th month, then set the year two years back. 
	select @Calculated_StartDate_year = cast(datepart(yyyy,@Date)as varchar(4))
-- 	select @Calculated_StartDate_year as '@Calculated_StartDate_year'

	--it will set the start date to first day of the next month - e.g. 6/01/2007
	select @Calculated_StartDate = @Calculated_StartDate_Month + '/' + @Calculated_StartDate_day + '/' +  @Calculated_StartDate_year
-- 	select @Calculated_StartDate as '@Calculated_StartDate'
 
	--final date value would be 2007-05-31 00:00:00.000, so date passed was 5/20/2007, this function will set it to 5/31/2007.
	select @Calculated_EndDate_day = case when datepart(mm, @Date)= '12'
					then dateadd(yyyy,1,dateadd(dd,-1,cast(@Calculated_StartDate as datetime)))
					else dateadd(dd,-1,cast(@Calculated_StartDate as datetime))
					end
-- 	select @Calculated_EndDate_day as '@Calculated_EndDate_day'
        return @Calculated_EndDate_day

END --end function 


GO
