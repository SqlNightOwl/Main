SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [security].[uspSECURITY_UserSelectID]  (@UserName varchar(1000))
AS
BEGIN
  select IDSeq from [Security]..[User] where NTUser = @UserName
END




GO
