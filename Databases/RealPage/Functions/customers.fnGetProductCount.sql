SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [customers].[fnGetProductCount](@IPBI_PriceCapIDSeq bigint) returns int
as
begin

      declare @IPI_ProductCount int
 
      select  @IPI_ProductCount = count(PriceCapIDSeq) from Customers.dbo.PriceCapProducts where PriceCapIDSeq = @IPBI_PriceCapIDSeq

      return  @IPI_ProductCount

end


GO
