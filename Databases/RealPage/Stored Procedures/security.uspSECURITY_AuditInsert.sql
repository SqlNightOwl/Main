SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [security].[uspSECURITY_AuditInsert]  (@IPVC_NTUser varchar(50), @IPVC_AuditCode varchar(5))
AS
BEGIN
  declare @UserIDSeq bigint

  select @UserIDSeq = IDSeq
  from [User]
  where NTUser = @IPVC_NTUser

  insert into [UserAudit] (AuditCode, NTUser, UserIDSeq, CreatedDate)
  values (@IPVC_AuditCode, @IPVC_NTUser, @UserIDSeq, getdate())
END




 
GO
