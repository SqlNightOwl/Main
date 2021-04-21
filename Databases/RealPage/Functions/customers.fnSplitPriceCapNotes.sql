SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[fnSplitPriceCapNotes](
                                      @IPVC_PriceCapNotes varchar(max)
                                    )

returns @parsedList table
        (
            PriceCapNotes varchar(max)
        )

as
begin
        DECLARE @PriceCapNotes varchar(max), @Pos int

	      SET @Pos = CHARINDEX('|', @IPVC_PriceCapNotes, 1)

	      IF REPLACE(@IPVC_PriceCapNotes, '|', '') <> ''
	      BEGIN
		      WHILE @Pos > 0
		      BEGIN
			      SET @PriceCapNotes = LTRIM(RTRIM(LEFT(@IPVC_PriceCapNotes, @Pos - 1)))
			      IF @PriceCapNotes <> ''
			      BEGIN
				      INSERT INTO @ParsedList (PriceCapNotes) 
				      VALUES (CAST(@PriceCapNotes AS varchar(max))) 
			      END
			      SET @IPVC_PriceCapNotes = RIGHT(@IPVC_PriceCapNotes, LEN(@IPVC_PriceCapNotes) - @Pos)
			      SET @Pos = CHARINDEX('|', @IPVC_PriceCapNotes, 1)

		      END
	      END	
	      RETURN

end
-- select * from dbo.fnSplitPropertyID ('|fhdkfh|fdjkshk|ldfjskl|fjldsj|fhkldsa|')
GO
