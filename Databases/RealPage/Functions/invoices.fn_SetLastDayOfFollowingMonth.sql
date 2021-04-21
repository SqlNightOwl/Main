SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- database  name       : Invoices
-- procedure name       : [fn_SetLastDayOfFollowingMonth]
-- description          : This procedures calculates and provides a last day of the  
--                      : following month of the date parameter that is passed to this 
--                      : function. 
-- input parameters     : @Date datetime.
-- output               : @Calculated_StartDate if successful
-- Creation Date        : 05-August-2007 
-- Author               : MIS                     
-- code example         : select Invoices.DBO.fn_SetLastDayOfFollowingMonth('12/01/2009')
---------------------------------------------------------------------------------------------
--Important Notes : This function is used for invoicing engine.
---------------------------------------------------------------------------------------------
-- modification history:
---------------------------------------------------------------------------------------------
CREATE function [invoices].[fn_SetLastDayOfFollowingMonth] (@Date datetime)
returns datetime
as
BEGIN --begin function
/*
------------------------
--declare variables - 
------------------------
-- declare @Date datetime
-- set @Date = '12/20/07' 
declare @Calculated_StartDate varchar(10)
declare @Calculated_StartDate_Month varchar(2)
declare @Calculated_StartDate_day varchar(2)
declare @Calculated_StartDate_year varchar(4)

--set the end date 
declare @Calculated_EndDate varchar
declare @Calculated_EndDate_day datetime
declare @Calculated_EndDate_year datetime

	--select a month e.g. 5/20/2007, then add 2 months
 	select @Calculated_StartDate_Month = cast(datepart(mm,dateadd(mm,2,@Date)) as varchar(2))
-- 	select @Calculated_StartDate_Month --set it to next month

-- 	--set the day variable on 01 so it is the first day.
        if datepart(dd, @Date) <> '01' 
        begin 
	select @Calculated_StartDate_day = '01'
        end 
        else 
	begin 
	select @Calculated_StartDate_day = datepart(dd, @Date)
	end 

	--select the year i.e 2007, if it is 12th month, then add a year 
	select @Calculated_StartDate_year = case when datepart(mm,@Date) = '12' 
                                                 then cast(datepart(yyyy,dateadd(yyyy,1,@Date))as varchar(4)) 
                                                 else  cast(datepart(yyyy,@Date)as varchar(4)) 
                                                 end
-- 	select @Calculated_StartDate_year
	
	--it will set the start date to first day of the calculated month - e.g. 2/01/2007
	select @Calculated_StartDate = @Calculated_StartDate_Month + '/' + @Calculated_StartDate_day + '/' +  @Calculated_StartDate_year
-- 	select @Calculated_StartDate 


	--final date value would be 2008-01-31 00:00:00.000, so date passed was 12/20/2007, this function will set it to 1/31/2008.
	select @Calculated_EndDate_day = dateadd(dd,-1,cast(@Calculated_StartDate as datetime))
-- 	select @Calculated_EndDate_day as '@Calculated_EndDate_day'

    return @Calculated_EndDate_day  --returns a dat
*/

declare @Calculated_EndDate_day datetime
select @Calculated_EndDate_day = dateadd(ms,-3,DATEADD(mm, DATEDIFF(m,0,@Date)+2, 0))
return convert(varchar(12),@Calculated_EndDate_day,101)

end --end function 


GO
