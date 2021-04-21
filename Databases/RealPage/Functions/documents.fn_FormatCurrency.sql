SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--select Quotes.DBO.fn_FormatCurrency(-11234.15430,1,2)
--select Quotes.DBO.fn_FormatCurrency(-1111234.15430,1,2)
CREATE Function [documents].[fn_FormatCurrency] (@IPD_Number decimal(30,10),@IPI_DisplayDecimals Int,@IPI_NumberofDecimalsToDisplay int)
Returns varchar(50)
as
BEGIN  
  DECLARE @LVC_NewNumber      varchar(100)
  DECLARE @LI_DecimalPos      int
  DECLARE @LVC_Decimals       varchar(50)
  DECLARE @LVC_HoldingCell    varchar(100)
  
  if @IPI_DisplayDecimals = 0
  begin
    SET @IPD_Number      =round(@IPD_Number,0)
  end
  else  
  begin
    SET @IPD_Number      =round(@IPD_Number,@IPI_NumberofDecimalsToDisplay)
  end

  SET @LVC_NewNumber   =convert(varchar(50),@IPD_Number)
  SET @LI_DecimalPos   =patindex('%.%',@LVC_NewNumber)
  SET @LVC_Decimals    =substring(@LVC_NewNumber,@LI_DecimalPos + 1,len(@LVC_NewNumber)) 
  select @LVC_Decimals =substring(@LVC_Decimals,1,@IPI_NumberofDecimalsToDisplay) 

  IF @LI_DecimalPos>0
  begin 
    SET @LVC_NewNumber= left(@LVC_NewNumber,@LI_DecimalPos-1) 
  end
  SET @LVC_HoldingCell=''
  IF Len(@LVC_NewNumber)>3
  begin
    WHILE len(@LVC_NewNumber)>3
    BEGIN
      SET @LVC_HoldingCell=',' + right(@LVC_NewNumber,3) + @LVC_HoldingCell
      SET @LVC_NewNumber=left(@LVC_NewNumber,len(@LVC_NewNumber)-3)
    END
    ---SET @LVC_HoldingCell=cast('$' + @LVC_NewNumber + @LVC_HoldingCell + '.' + @LVC_Decimals as varchar(50))
    --SET @LVC_HoldingCell=cast(@LVC_NewNumber + @LVC_HoldingCell + (case when @LVC_Decimals > 0 then '.' + @LVC_Decimals else '' end) as varchar(50))
    SET @LVC_HoldingCell=cast(@LVC_NewNumber + @LVC_HoldingCell + (case when @IPI_DisplayDecimals=0 then '' else  case when @IPI_NumberofDecimalsToDisplay > 0 then '.' + @LVC_Decimals else '' end end ) as varchar(50))
  End
  else
  begin
    ---SET @LVC_HoldingCell='$' + @LVC_NewNumber + '.' + @LVC_Decimals
    --SET @LVC_HoldingCell= @LVC_NewNumber + (case when @LVC_Decimals > 0 then '.' + @LVC_Decimals else '' end)
    SET @LVC_HoldingCell= cast(@LVC_NewNumber + (case when @IPI_DisplayDecimals=0 then '' else  case when @IPI_NumberofDecimalsToDisplay > 0 then '.' + @LVC_Decimals else '' end end ) as varchar(50))
  end
  --------------------------------------------------------------
  SELECT @LVC_HoldingCell = replace(@LVC_HoldingCell,'-,','-')
  --------------------------------------------------------------
  RETURN @LVC_HoldingCell
END




GO
