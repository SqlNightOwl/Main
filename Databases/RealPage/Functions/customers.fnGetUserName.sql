SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create function [customers].[fnGetUserName]( @IPVC_NTUser varchar(40))
returns varchar(255)
as
begin
	declare @LVReturn varchar(255)
	select @LVReturn = FirstName + ' ' + LastName
  from Security.dbo.[User]
  where lower(NTUser) = lower(@IPVC_NTUser)
	return @LVReturn
end

-- select dbo.fnGetUserName('rri\gguidroz')

GO
