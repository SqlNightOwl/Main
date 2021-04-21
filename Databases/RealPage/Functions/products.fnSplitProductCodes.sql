SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [products].[fnSplitProductCodes] (@IPVC_ProductCodes varchar(max)  
                                            )  
returns @parsedList table (ProductCode  varchar(30),  
                           PriceVersion numeric(18,0)  
                          )  
as  
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
  IF LEN(@IPVC_ProductCodes) = 0 return
  WHILE @LI_Index <> 0
  BEGIN      
    -- Step 1: get the index of the first occurence of the fn_splitdelimitedstringintorows character
    select @LI_Index = CHARINDEX('|',@IPVC_ProductCodes)
    -- Step 2 : push everything to the left of it into the @LVC_Slice variable
    IF @LI_Index <> 0
    begin
      select @LVC_Slice = LEFT(@IPVC_ProductCodes,@LI_Index - 1)
    end
    ELSE
    begin
      select @LVC_Slice = @IPVC_ProductCodes
    end
    -- Step 3: Put the Sliced Item into result set 
    select @LVC_Slice = ltrim(rtrim(@LVC_Slice))
    if charindex(',',@LVC_Slice) > 0
    begin    
      insert into @parsedList(ProductCode,PriceVersion) 
      select substring(@LVC_Slice,
                       1,
                       charindex(',',@LVC_Slice)-1
                      ) as ProductCode,
             substring(@LVC_Slice,                     
                       charindex(',',@LVC_Slice)+1,
                       len(@LVC_Slice)-1
                      ) as Priceversion
    end
    -- Step 4: chop the item removed off the main string
    select @IPVC_ProductCodes = RIGHT(@IPVC_ProductCodes,LEN(@IPVC_ProductCodes) - @LI_Index)
    -- Step 5: Check Length of the remaining String.
    --         If Length<> 0 then go back to the loop.
    --         If Length=0 then Break
    IF LEN(@IPVC_ProductCodes) = 0 BREAK
  END
  delete from @parsedList where ProductCode is null
  --------------------------------------- 
  RETURN
  --------------------------------------- 
END
GO
