SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [security].[uspSECURITY_GetLockDownStatus] 
AS
BEGIN
  set nocount on;
  declare @LVC_ConfigValue   varchar(50);
  declare @LVC_UNIQUEID      varchar(200);
  select  @LVC_UNIQUEID = convert(varchar(200),REPLACE(NEWID(),'-','')),@LVC_ConfigValue = CFG.ConfigValue
  from    security.dbo.configoptions CFG with (nolock)
  where   CFG.ConfigOption = 'OMSLockDown' 
 
  if @LVC_ConfigValue=1
  begin
    select @LVC_UNIQUEID as LockDownStatus
  end
  else
  begin
    select '' as LockDownStatus
  end
END

GO
