SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [invoices].[fn_GetNumDaysInMonth] (@IPDT_InputDate DATETIME)
RETURNS INT
AS
BEGIN
  DECLARE @LDT_DayNum INT
  SET @LDT_DayNum = (CASE WHEN MONTH(@IPDT_InputDate) IN (1, 3, 5, 7, 8, 10, 12) THEN 31
                          WHEN MONTH(@IPDT_InputDate) IN (4, 6, 9, 11) THEN 30
                          ELSE (CASE WHEN (YEAR(@IPDT_InputDate) % 4 = 0 AND YEAR(@IPDT_InputDate) % 100 != 0) OR (YEAR(@IPDT_InputDate) % 400 = 0)
                                      THEN 29
                                     ELSE 28 
                                END)
                    END)
RETURN @LDT_DayNum
END


GO
