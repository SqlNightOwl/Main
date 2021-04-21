SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[fnGetProductName](@IPBI_PriceCapIDSeq bigint) returns varchar(255)
as
begin

declare @LVVC_ProductName as varchar(255)

select @LVVC_ProductName =  pro.DisplayName from Customers.dbo.PriceCapProducts pcprod left outer join Products.dbo.product pro
on pro.Code = pcprod.ProductCode where pcprod.PriceCapIDSeq = @IPBI_PriceCapIDSeq

return @LVVC_ProductName

end



GO
