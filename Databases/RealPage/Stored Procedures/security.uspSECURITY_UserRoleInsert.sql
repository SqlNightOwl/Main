SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [security].[uspSECURITY_UserRoleInsert]  (@IPN_UserIDSeq bigint, @IPN_RoleIDSeq bigint)
AS
BEGIN
  insert into UserRoles (UserIDSeq, RoleIDSeq)
  values (@IPN_UserIDSeq, @IPN_RoleIDSeq)
END




 
GO
