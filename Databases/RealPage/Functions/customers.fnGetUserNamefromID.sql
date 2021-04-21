SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE function [customers].[fnGetUserNamefromID]( @IPI_UserID BIGINT)
returns varchar(255)
as
begin  
  declare @LVReturn varchar(255)
  select @LVReturn = FirstName + ' ' + LastName
  from  Security.dbo.[User] with (nolock)
  where IDSeq = @IPI_UserID

  return @LVReturn 
end

-- select dbo.fnGetUserNamefromID(15)

GO
