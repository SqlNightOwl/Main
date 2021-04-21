SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- database  name       : INVOICES
-- procedure name       : [fn_GetMonthsForYrInvoiceProration]
-- description          : This procedures calculates and provides the number of months
--                      : in a date range for the purpose of invoice amount proration.  This number
--						: will be used as a divisor for the net amount multiplied * 12 = annual amt.
-- input parameters     : @StartDate datetime, @EndDate datetime
-- output               : smallint if successful
-- Creation Date        : 2008/05/21
-- Author               : MIS                     
-- code example         : select SiebelSourceDB.DBO.[fn_GetMonthsForYrInvoiceProration]('12/06/2009','12/01/2010')
---------------------------------------------------------------------------------------------
--Important Notes : This function is used for invoicing engine and data migration.
---------------------------------------------------------------------------------------------
-- modification history:
---------------------------------------------------------------------------------------------'
CREATE function [invoices].[fn_GetMonthsForYrInvoiceProration] (@StartDate datetime,@EndDate datetime)
returns SMALLINT
as
BEGIN --begin function

declare @MonthDuration smallint

SELECT @MonthDuration = CASE WHEN DAY(@StartDate) = DAY(@EndDate) THEN DATEDIFF(mm,@StartDate,@EndDate)
							 WHEN DAY(@StartDate) > 1 and DAY(@EndDate) > 1 THEN DATEDIFF(mm,@StartDate,@EndDate)
                       ELSE DATEDIFF(mm,@StartDate,@EndDate) + 1
                  END

return @MonthDuration

end --end function 


GO
