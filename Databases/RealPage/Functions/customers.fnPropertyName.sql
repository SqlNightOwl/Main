SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[fnPropertyName](
                                  @IPVC_PropertyIDSeq varchar(11)
                                )
returns varchar(255)
as
begin
        declare @LV_PropertyName varchar(255)

        select  @LV_PropertyName = ltrim(rtrim(Name)) from Customers.dbo.[Property] where IDSeq = @IPVC_PropertyIDSeq

        return  @LV_PropertyName
end

-- select dbo.fnPropertyName('P0000000009')
-- select * from Customers.dbo.[Property]

GO
