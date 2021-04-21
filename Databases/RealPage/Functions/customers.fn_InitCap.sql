SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE function [customers].[fn_InitCap] (@String varchar(8000))
returns varchar(8000)
as
BEGIN --begin function PROCEDURE
    DECLARE @StringCount int
    SET @string = lower(@string)
    SET @string = stuff(@string,1,1,left(upper(@string),1)) --Capitalize the first letter 
    SET @StringCount = 0
    WHILE @StringCount < len(@string)


        BEGIN --begin WHILE
         IF substring(@string,charindex(space(1),@string,@StringCount),1) = space(1)


             BEGIN --begin IF	
            SET @string = stuff(@string,charindex(space(1),@string,@StringCount)+1,1,substring(upper(@string),charindex(' ',@string,@StringCount)+1,1)) 
         END --end IF
        SET @StringCount = @StringCount + 1
    END --end WHILE
    RETURN @string --return the formatted string
END --end function 


GO
