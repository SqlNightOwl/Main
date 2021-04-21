SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[fnGetFamilyCode](
                                  @IPVC_ProductCode varchar(30)
                                )
returns varchar(3)
as
begin
        declare @LV_FamilyCode varchar(3)

        select  @LV_FamilyCode = ltrim(rtrim(FamilyCode)) 
        from    Products.dbo.Product with (nolock)
        where   Code = @IPVC_ProductCode
        and     DisabledFlag = 0

        return  @LV_FamilyCode
end

-- select dbo.fnGetFamilyCode('PRM-LEG-LEG-LEG-LAAP')

GO
