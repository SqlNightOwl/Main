SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [security].[uspSECURITY_RightsSelect]  (@IPVC_NTUser varchar(100), @IPVC_Rights varchar(8000)='')
AS
BEGIN
  set nocount on;
  select @IPVC_NTUser = lower(ltrim(rtrim(replace(@IPVC_NTUser,'\\','\'))));
  ------------------------------------------------------------------------
  --Check to see if OMS is in Lockdown mode in security.dbo.configoptions

  if exists (select top 1 1 from security.dbo.configoptions with (nolock)
             where ConfigOption = 'OMSLockDown' and ConfigValue = 1
            )
  begin
    --- OMS is in Lockdown mode. Return only limited Rights
    select DISTINCT Lower(r.Code) As Code
    from   Security.dbo.[User] u with (nolock)
    inner join
           Security.dbo.UserRoles ur with (nolock)
    on     u.IDSeq  = ur.UserIDSeq 
    and    lower(u.NTUser) = @IPVC_NTUser
    and    u.ActiveFlag = 1
    inner join
           Security.dbo.RoleRights rr with (nolock)
    on    ur.RoleIDSeq = rr.RoleIDSeq
    inner join
           Security.dbo.Rights r with (nolock)
    on     rr.RightIDSeq   = r.IDSeq
    and    r.LockableFlag  <> 1
    where  lower(u.NTUser) = @IPVC_NTUser
    and    r.LockableFlag  <> 1
    --and   charindex(',' + r.Code + ',', @IPVC_Rights) > 0
  end
  else
  begin
    --- OMS is NOT IN Lockdown mode. Return all Rights for this user
    select DISTINCT Lower(r.Code) As Code
    from   Security.dbo.[User] u with (nolock)
    inner join
           Security.dbo.UserRoles ur with (nolock)
    on     u.IDSeq  = ur.UserIDSeq 
    and    lower(u.NTUser) = @IPVC_NTUser
    and    u.ActiveFlag = 1
    inner join
           Security.dbo.RoleRights rr with (nolock)
    on    ur.RoleIDSeq = rr.RoleIDSeq
    inner join
           Security.dbo.Rights r with (nolock)
    on     rr.RightIDSeq   = r.IDSeq    
    where  lower(u.NTUser) = @IPVC_NTUser    
    --and   charindex(',' + r.Code + ',', @IPVC_Rights) > 0
  end
END

GO
