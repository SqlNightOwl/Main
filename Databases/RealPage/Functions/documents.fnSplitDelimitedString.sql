SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Syntaxt for calling: 

declare @LVC_DelimitedString varchar(8000)
declare @LVC_Delimiter char(1)
select @LVC_DelimitedString = 'Q0000005367,Q0000005398,Q0000005399,Q0000005400'
select @LVC_Delimiter = ','
select Items from fnSplitDelimitedString(@LVC_DelimitedString,@LVC_Delimiter)
*/
CREATE FUNCTION [documents].[fnSplitDelimitedString](@IPVC_DelimitedString varchar(8000),@IPVC_Delimiter varchar(1))
RETURNS @LT_Results TABLE (Items varchar(8000))
AS
BEGIN
  DECLARE @LI_Index  int
  DECLARE @LVC_Slice varchar(8000)
  --Initialize the variable
  SELECT @LI_Index = 1
  -----------------------------------------------------------------
  WHILE @LI_Index !=0
  begin      
    -- get the index of the first occurence of the split character
    SELECT @LI_Index = CHARINDEX(@IPVC_Delimiter,@IPVC_DelimitedString)
    -- push everything to the left of it into the slice variable
    ----------------------------------------
    IF @LI_Index !=0
    begin
       SELECT @LVC_Slice = LEFT(@IPVC_DelimitedString,@LI_Index-1)
    end
    else
    begin
       SELECT @LVC_Slice = @IPVC_DelimitedString
    end 
    ----------------------------------------
    -- Insert item into the results set
    INSERT INTO @LT_Results(Items) VALUES(@LVC_Slice)
    -- chop the item removed off the main string
    SELECT @IPVC_DelimitedString = RIGHT(@IPVC_DelimitedString,LEN(@IPVC_DelimitedString)-@LI_Index)
    -- break the loop when done
    IF LEN(@IPVC_DelimitedString) = 0 BREAK    
  end
  -----------------------------------------------------------------
  RETURN
END


GO
