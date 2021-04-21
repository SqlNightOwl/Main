SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function oms.fn_FormatCurrency
(	@IPD_Number						decimal(30,10)
,	@IPI_DisplayDecimals			int
,	@IPI_NumberofDecimalsToDisplay	int	)
returns varchar(50)
as
begin  
	declare
		@LVC_NewNumber		varchar(100)
	,	@LI_DecimalPos		int
	,	@LVC_Decimals		varchar(50)
	,	@LVC_HoldingCell	varchar(100)
  
	if @IPI_DisplayDecimals = 0
	begin
		set @IPD_Number = round(@IPD_Number, 0);
	end;
	else
	begin
		set @IPD_Number = round(@IPD_Number, @IPI_NumberofDecimalsToDisplay);
	end;

	set @LVC_NewNumber	= convert(varchar(50), @IPD_Number);
	set @LI_DecimalPos	= patindex('%.%', @LVC_NewNumber);
	set @LVC_Decimals	= substring(@LVC_NewNumber,@LI_DecimalPos + 1, len(@LVC_NewNumber));
	set @LVC_Decimals	= substring(@LVC_Decimals, 1, @IPI_NumberofDecimalsToDisplay);

	if @LI_DecimalPos > 0
	begin 
		set @LVC_NewNumber= left(@LVC_NewNumber,@LI_DecimalPos - 1);
	end;

	set @LVC_HoldingCell = ''
	if len(@LVC_NewNumber) > 3
	begin
		while len(@LVC_NewNumber)>3
		begin
			set @LVC_HoldingCell = ',' + right(@LVC_NewNumber,3) + @LVC_HoldingCell;
			set @LVC_NewNumber	 = left(@LVC_NewNumber, len(@LVC_NewNumber) - 3);
		end;
		set @LVC_HoldingCell	 = cast(@LVC_NewNumber + @LVC_HoldingCell
								 + (case @IPI_DisplayDecimals
									when 0 then ''
									else case
										 when @IPI_NumberofDecimalsToDisplay > 0 then '.' + @LVC_Decimals
										 else ''
										 end
									end ) as varchar(50));
	end;
	else
	begin
		set @LVC_HoldingCell	 = cast(@LVC_NewNumber
								 + (case @IPI_DisplayDecimals
									when 0 then ''
									else case
										 when @IPI_NumberofDecimalsToDisplay > 0 then '.' + @LVC_Decimals
										 else ''
										 end
									end ) as varchar(50));
	end;
	--------------------------------------------------------------
	return replace(@LVC_HoldingCell, '-,', '-');
end;
GO
