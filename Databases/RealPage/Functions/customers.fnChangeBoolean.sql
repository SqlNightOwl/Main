SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[fnChangeBoolean](@IPB_BoolValue bit)
returns varchar(255)
as
begin
	declare @LVReturn varchar(3)
	if @IPB_BoolValue = 'true'
	begin
		set @LVReturn = 'Yes'	
	end
	else
	begin
		set @LVReturn = 'No'	
	end
	return @LVReturn
end

-- select dbo.[fnChangeBoolean](1)

GO
