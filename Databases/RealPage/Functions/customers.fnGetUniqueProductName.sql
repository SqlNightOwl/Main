SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[fnGetUniqueProductName](@IPVC_PriceCapIDSeq bigint,@IPBI_RowNumber bigint)
returns varchar(255)
as
begin
	declare @LVVC_NewProductName as varchar(255) 
	declare @LVVC_OldProductName as varchar(255) 
	declare @LVVC_NewValue as varchar(255)

	select @LVVC_NewProductName = ProductName 
        from(
 	     select pro.DisplayName                             as ProductName,
                    row_number() over (order by pcprops.IDSeq ) as RowNumber 
             from Customers.dbo.PriceCapProducts              pcproducts with (nolock)
	     left outer join Customers.dbo.PriceCapProperties pcprops    with (nolock)
	     on   pcproducts.PriceCapIDSeq = pcprops.PriceCapIDSeq
             and  pcproducts.PriceCapIDSeq = @IPVC_PriceCapIDSeq
             left outer join products.dbo.product pro with (nolock)
             on pro.Code = pcproducts.productCode
	     where pcproducts.PriceCapIDSeq = @IPVC_PriceCapIDSeq
            )tbl
	where RowNumber = @IPBI_RowNumber


	select @LVVC_OldProductName = ProductName 
        from(select pro.DisplayName                      as ProductName,
             row_number() over (order by pcprops.IDSeq ) as RowNumber 
             from Customers.dbo.PriceCapProducts              pcproducts with (nolock)
	     left outer join Customers.dbo.PriceCapProperties pcprops    with (nolock)
	     on pcproducts.PriceCapIDSeq = pcprops.PriceCapIDSeq
             and pcproducts.PriceCapIDSeq = @IPVC_PriceCapIDSeq
             left outer join Products.dbo.product pro with (nolock)
             on pro.Code = pcproducts.productCode
	     where pcproducts.PriceCapIDSeq = @IPVC_PriceCapIDSeq
            )tbl
	where RowNumber = (@IPBI_RowNumber - 1)	


	if((rtrim(ltrim(@LVVC_NewProductName)) <> rtrim(ltrim(@LVVC_OldProductName))) or @IPBI_RowNumber = 1)
	begin
			set @LVVC_NewValue = @LVVC_NewProductName
	end
	else
	begin
			set @LVVC_NewValue = ''
	end
			return @LVVC_NewValue
end

-- select dbo.fnGetUniqueProductName(12,1)

GO
