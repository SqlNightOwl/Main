SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : fnGenericSplitString   
-- Description     : This procedure splits the given string for the character separator '|'.
-- Input Parameters: @IPVC_InputString varchar(8000)
--                     
-- Code Example    : SELECT SplitString FROM dbo.[fnGenericSplitString] ('|ONE|TWO|THREE||FOUR|FIVE||||')
--   
-- Revision History:  
-- Author          : STA  
-- 29/05/2007      : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------ 
CREATE FUNCTION [invoices].[fnGenericSplitString](@IPVC_InputString varchar(8000))
RETURNS @LT_StringList TABLE(SplitString varchar(1000))
AS
BEGIN
  ---------------------------------------
  --Declaring Local Variables
  Declare @LI_Index       int,
          @LVC_Delimiter  varchar(1)
  Declare @LVC_Slice      varchar(8000)
  ---------------------------------------
  -- Initialize Local Variable 
  SELECT @LI_Index = 1,@LVC_Delimiter='|'
  --------------------------------------- 
  --step 0 : If length of Input string is 0 
  --         then return without processing.
  --------------------------------------- 
  IF LEN(@IPVC_InputString) = 0 return
  WHILE @LI_Index <> 0
  BEGIN      
    -- Step 1: get the index of the first occurence of the fn_splitdelimitedstringintorows character
    select @LI_Index = CHARINDEX(@LVC_Delimiter,@IPVC_InputString)
    -- Step 2 : push everything to the left of it into the @LVC_Slice variable
    IF @LI_Index <> 0
    begin
      select @LVC_Slice = LEFT(@IPVC_InputString,@LI_Index - 1)
    end
    ELSE
    begin
      select @LVC_Slice = @IPVC_InputString
    end
    -- Step 3: Put the Sliced Item into result set     
    insert into @LT_StringList(SplitString) 
    select ltrim(rtrim(@LVC_Slice))
    where  ltrim(rtrim(@LVC_Slice)) <> ''
    -- Step 4: chop the item removed off the main string
    select @IPVC_InputString = RIGHT(@IPVC_InputString,LEN(@IPVC_InputString) - @LI_Index)
    -- Step 5: Check Length of the remaining String.
    --         If Length<> 0 then go back to the loop.
    --         If Length=0 then Break
    IF LEN(@IPVC_InputString) = 0 BREAK
  END
  --------------------------------------- 
  RETURN
  ---------------------------------------
END
GO
