SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- database  name       : Invoices
-- procedure name       : [fn_SetFirstDayOfMonth]
-- description          : This procedures calculates first day of date parameter that is  
--                      : passed to this function. 
-- input parameters     : @Date datetime.
-- output               : @Calculated_StartDate if successful
-- Creation Date        : 05-August-2007 
-- Author               : MIS                     
-- code example         : select Invoices.DBO.fn_SetFirstDayOfMonth('12/05/2009')
---------------------------------------------------------------------------------------------
--Important Notes : This function is used for invoicing engine.
---------------------------------------------------------------------------------------------
-- modification history:
---------------------------------------------------------------------------------------------
CREATE function [invoices].[fn_SetFirstDayOfMonth] (@Date datetime)
returns datetime
as
BEGIN --begin function
------------------------
--declare variables - 
------------------------
-- declare @Date datetime
-- set @Date = '12/1/07' 
declare @Calculated_StartDate varchar(10)
declare @Calculated_StartDate_Month varchar(2)
declare @Calculated_StartDate_day varchar(2)
declare @Calculated_StartDate_year varchar(4)

--set the end date 
declare @Calculated_EndDate varchar
declare @Calculated_EndDate_day datetime
declare @Calculated_EndDate_year datetime

	--select a month e.g. 5/20/2007, then set it to next month..i.e. 6th month.
 	select @Calculated_StartDate_Month = cast(datepart(mm,@Date) as varchar(2))
-- 	select @Calculated_StartDate_Month --set it to next month

-- 	--set the day variable on 01 so it is the first day.
        select @Calculated_StartDate_day = '01'
-- 	select @Calculated_StartDate_day

	--select the year i.e 2007 
	select @Calculated_StartDate_year = cast(datepart(yyyy,@Date)as varchar(4))
-- 	select @Calculated_StartDate_year
	
	--it will set the start date to first day of the next month - e.g. 6/01/2007
	select @Calculated_StartDate = @Calculated_StartDate_Month + '/' + @Calculated_StartDate_day + '/' +  @Calculated_StartDate_year
-- 	select @Calculated_StartDate 
    return @Calculated_StartDate  --returns a date 
end --end function 


GO
