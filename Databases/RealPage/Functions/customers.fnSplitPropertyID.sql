SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[fnSplitPropertyID](
                                      @IPVC_PropertyID varchar(max)
                                    )

returns @parsedList table
        (
            PropertyID varchar(30)
        )

as
begin
        DECLARE @PropertyIDSeq varchar(11), @Pos int

	      SET @Pos = CHARINDEX('|', @IPVC_PropertyID, 1)

	      IF REPLACE(@IPVC_PropertyID, '|', '') <> ''
	      BEGIN
		      WHILE @Pos > 0
		      BEGIN
			      SET @PropertyIDSeq = LTRIM(RTRIM(LEFT(@IPVC_PropertyID, @Pos - 1)))
			      IF @PropertyIDSeq <> ''
			      BEGIN
				      INSERT INTO @ParsedList (PropertyID) 
				      VALUES (CAST(@PropertyIDSeq AS varchar(30))) 
			      END
			      SET @IPVC_PropertyID = RIGHT(@IPVC_PropertyID, LEN(@IPVC_PropertyID) - @Pos)
			      SET @Pos = CHARINDEX('|', @IPVC_PropertyID, 1)

		      END
	      END	
	      RETURN

end
-- select * from dbo.fnSplitPropertyID ('|fhdkfh|fdjkshk|ldfjskl|fjldsj|fhkldsa|')

GO
