SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [customers].[fnSplitProductCodes](
                                      @IPVC_ProductCodes varchar(max)
                                    )

returns @parsedList table
        (
            ProductCode varchar(30)
        )

as
begin
        DECLARE @ProductCode varchar(30), @Pos int

	      SET @Pos = CHARINDEX('|', @IPVC_ProductCodes, 1)

	      IF REPLACE(@IPVC_ProductCodes, '|', '') <> ''
	      BEGIN
		      WHILE @Pos > 0
		      BEGIN
			      SET @ProductCode = LTRIM(RTRIM(LEFT(@IPVC_ProductCodes, @Pos - 1)))
			      IF @ProductCode <> ''
			      BEGIN
				      INSERT INTO @ParsedList (ProductCode) 
				      VALUES (CAST(@ProductCode AS varchar(30))) 
			      END
			      SET @IPVC_ProductCodes = RIGHT(@IPVC_ProductCodes, LEN(@IPVC_ProductCodes) - @Pos)
			      SET @Pos = CHARINDEX('|', @IPVC_ProductCodes, 1)

		      END
	      END	
	      RETURN

end
-- select * from dbo.[fnSplitProductCodes] ('|fhdkfh|fdjkshk|ldfjskl|fjldsj|fhkldsa|')

GO
