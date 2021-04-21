SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
select seq,Items from Orders.[dbo].[fn_SplitDelimitedStringIntoRows]
('Quantity is capped at 508 units.|Quantity is subject to a 30 minimum.|30 Units charged at $0.070667 per Units = $2.12.|'
,'|')
select seq,Items from Orders.[dbo].[fn_SplitDelimitedStringIntoRows]
(''
,'|')
*/
Create Function [orders].[fn_SplitDelimitedStringIntoRows](@IPVC_String varchar(8000),@IPVC_Delimiter varchar(1))
RETURNS @Results TABLE (seq int identity(1,1),Items varchar(8000))
AS
BEGIN
  ---------------------------------------
  --Declaring Local Variables
  DECLARE @LI_Index  int
  DECLARE @LVC_Slice varchar(8000)
  ---------------------------------------
  -- Initialize Local Variable 
  SELECT @LI_Index = 1
  --------------------------------------- 
  --step 0 : If length of Input string is 0 
  --         then return without processing.
  --------------------------------------- 
  IF LEN(@IPVC_String) = 0 return
  WHILE @LI_Index <> 0
  BEGIN      
    -- Step 1: get the index of the first occurence of the fn_splitdelimitedstringintorows character
    select @LI_Index = CHARINDEX(@IPVC_Delimiter,@IPVC_String)
    -- Step 2 : push everything to the left of it into the @LVC_Slice variable
    IF @LI_Index <> 0
    begin
      select @LVC_Slice = LEFT(@IPVC_String,@LI_Index - 1)
    end
    ELSE
    begin
      select @LVC_Slice = @IPVC_String
    end
    -- Step 3: Put the Sliced Item into result set     
    insert into @Results(Items) select ltrim(rtrim(@LVC_Slice))
    -- Step 4: chop the item removed off the main string
    select @IPVC_String = RIGHT(@IPVC_String,LEN(@IPVC_String) - @LI_Index)
    -- Step 5: Check Length of the remaining String.
    --         If Length<> 0 then go back to the loop.
    --         If Length=0 then Break
    IF LEN(@IPVC_String) = 0 BREAK
  END
  --------------------------------------- 
  RETURN
  --------------------------------------- 
END
GO
