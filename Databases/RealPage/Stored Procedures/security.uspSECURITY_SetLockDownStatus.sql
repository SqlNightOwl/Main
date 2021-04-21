SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [security].[uspSECURITY_SetLockDownStatus] (@IPI_ConfigValue int = 0)
AS
BEGIN
  set nocount on;
  Update security.dbo.configoptions
  set    ConfigValue = @IPI_ConfigValue  
  where  ConfigOption = 'OMSLockDown' 
END

GO
