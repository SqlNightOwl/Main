SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [customers].[fnGetPropertiesCountForExpiredPriceCap](@IPBI_PriceCapIDSeq bigint) returns int
as
begin

      declare @IPI_PropertyCount int
 
      select  @IPI_PropertyCount = count(PriceCapIDSeq) from Customers.dbo.PriceCapPropertiesHistory with (nolock) where PriceCapIDSeq = @IPBI_PriceCapIDSeq

      return @IPI_PropertyCount

end




GO
