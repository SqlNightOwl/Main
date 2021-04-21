SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [invoices].[fn_GetNumDaysInYear] (@IPDT_InputDate DATETIME)
RETURNS INT
AS
BEGIN
  DECLARE @LDT_DayNum INT
  SET @LDT_DayNum = (CASE WHEN (YEAR(@IPDT_InputDate) % 4 = 0 AND YEAR(@IPDT_InputDate) % 100 != 0) OR (YEAR(@IPDT_InputDate) % 400 = 0)
                           THEN 366
                          ELSE 365                               
                    END)
RETURN @LDT_DayNum
END


GO
