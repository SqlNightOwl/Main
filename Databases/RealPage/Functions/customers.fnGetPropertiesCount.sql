SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

create function [customers].[fnGetPropertiesCount](@IPBI_PriceCapIDSeq bigint) returns int
as
begin

      declare @IPI_PropertyCount int
	  declare @IPI_PMCPropertyCount int
		SET @IPI_PropertyCount=0
		SET @IPI_PMCPropertyCount=0
      select  @IPI_PropertyCount = count(PriceCapIDSeq) from Customers.dbo.PriceCapProperties where PriceCapIDSeq = @IPBI_PriceCapIDSeq
	IF(@IPI_PropertyCount=0)
	  select  @IPI_PMCPropertyCount = count(distinct PriceCapIDSeq) from Customers.dbo.PriceCapProducts where PriceCapIDSeq = @IPBI_PriceCapIDSeq
      return @IPI_PropertyCount + @IPI_PMCPropertyCount

end

-- select dbo.fnGetPropertiesCount('591')
--select * from Customers.dbo.PriceCapProducts where PriceCapIDSeq = '591'
--  select  count(PriceCapIDSeq) from Customers.dbo.PriceCapProperties where PriceCapIDSeq = 598 
GO
