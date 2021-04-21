SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [security].[uspSECURITY_UserByRightSelect]  (@IPVC_RightCode varchar(20))
AS
BEGIN
  select IDSeq, FirstName + ' ' + LastName as DisplayName
  from [Security]..[User] u
  where exists (select 1 from Security..UserRoles ur with (nolock), 
  Security..RoleRights rr with (nolock), Security..Rights r with (nolock)
  where r.Code = @IPVC_RightCode
  and rr.RightIDSeq = r.IDSeq
  and ur.UserIDSeq = u.IDSeq
  and ur.RoleIDSeq = rr.RoleIDSeq)
  and u.ActiveFlag = 1
  order by DisplayName
END




 
GO
