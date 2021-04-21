SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[fnProductName](@IPVC_ProductCode varchar(30))
returns varchar(255)
as
begin
        declare @LV_ProductName varchar(255);
        if exists(select top 1 1 from Products.dbo.Product with (nolock) where Code = @IPVC_ProductCode and  disabledflag = 0)
        begin
          select  @LV_ProductName = ltrim(rtrim(DisplayName)) 
          from   Products.dbo.Product with (nolock) where Code = @IPVC_ProductCode
          and    disabledflag = 0 
        end
        else 
        begin
          select top 1 @LV_ProductName = ltrim(rtrim(DisplayName)) 
          from Products.dbo.Product with (nolock) where Code = @IPVC_ProductCode          
        end

        return  @LV_ProductName
end

-- select dbo.fnProductName('PRM-LEG-LEG-LEG-LAAP')

GO
