SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [customers].[fnGetPriceCapName](
                                           @IPBI_PriceCapID bigint
                                      )
returns varchar(1000)
as
begin
declare @LVVC_ProductName varchar(1000)
declare @LVVC_TempProductName varchar(255)
declare @LVI_RowCount int
declare @LVI_Counter int

set @LVI_Counter = 1

set @LVVC_ProductName = ''

select @LVI_RowCount = count(*) from Customers.dbo.PriceCapProducts pcap where PriceCapIDSeq = @IPBI_PriceCapID

if @LVI_RowCount > 4 
   set @LVI_RowCount = 4

while(@LVI_Counter <= @LVI_RowCount)
begin

      select @LVVC_TempProductName = ProductName from
      (
            select ProductName,
                   row_number() over(order by IDSeq) as RowNumber  
            from   Customers.dbo.PriceCapProducts pcap where PriceCapIDSeq = @IPBI_PriceCapID
      ) tbl where RowNumber = @LVI_Counter
 
      if @LVI_Counter != 1
          set @LVVC_ProductName = @LVVC_ProductName + ',' +  @LVVC_TempProductName    
      else
          set @LVVC_ProductName = @LVVC_TempProductName    
      set @LVI_Counter = @LVI_Counter + 1
end

return @LVVC_ProductName

end





GO
