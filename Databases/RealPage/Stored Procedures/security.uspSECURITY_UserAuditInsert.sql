SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [security].[uspSECURITY_UserAuditInsert]  (@IPVC_NTUser varchar(50), @IPVC_AuditCode varchar(5))
AS
BEGIN
  declare @UserIDSeq bigint

  select @UserIDSeq = IDSeq
  from [User]
  where NTUser = @IPVC_NTUser

  if @UserIDSeq is not null
  update [User]
  set LastLoginDate = getdate()
  where IDSeq = @UserIDSeq

  insert into [UserAudit] (AuditCode, NTUser, UserIDSeq, CreatedDate)
  values (@IPVC_AuditCode, @IPVC_NTUser, @UserIDSeq, getdate())
END




 
GO
