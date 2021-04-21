SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- database  name       : Invoices
-- procedure name       : [fn_SetLastDayOfPreviousMonth]
-- description          : This procedures calculates last day of previous month of the date 
--                      : parameter passed to this function. 
-- input parameters     : @Date datetime.
-- output               : @Calculated_EndDate_day if successful
-- Creation Date        : 06-August-2007 
-- Author               : MIS                     
-- code examples        : select Invoices.DBO.fn_SetLastDayOfPreviousMonth('1/1/2009')
--                      : select Invoices.DBO.fn_SetLastDayOfPreviousMonth('12/1/2008')
---------------------------------------------------------------------------------------------
--Important Notes : This function is used for invoicing engine.
---------------------------------------------------------------------------------------------
-- modification history:
---------------------------------------------------------------------------------------------
CREATE function [invoices].[fn_SetLastDayOfPreviousMonth] (@Date datetime)
returns datetime
as
BEGIN --begin function
------------------------
--declare variables - 
------------------------
-- declare @Date datetime
-- set @Date = '1/01/07' 
declare @Calculated_LastDayOfPreviousMonth datetime

--         select @Date --2008-08-01 00:00:00.000
        select @Calculated_LastDayOfPreviousMonth =  
                                case datepart(dd,@Date) --first month, first day
						           when '01' 
					                   then dateadd(dd,-1,@Date) --then substract one day only
						           else dateadd(dd,-1,CAST(CAST(datepart(mm,@Date) as varchar(2)) + '/01/' + cast(DATEPART(yyyy,@Date) as varchar(4)) as datetime))
						        end
--  select @Calculated_LastDayOfPreviousMonth

    RETURN @Calculated_LastDayOfPreviousMonth  --returns a date 
END --end function 


GO
