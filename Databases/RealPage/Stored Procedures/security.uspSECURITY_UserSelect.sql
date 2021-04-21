SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : SECURITY
-- Procedure Name  : uspSECURITY_UserSelect
-- Description     : This procedure selects the user for the specified ID.
-- Input Parameters: 	@IPN_UserIDSeq    bigint
-- 
-- OUTPUT          : RecordSet of the user and the user roles.
-- Code Example    : SECURITY.dbo.uspSECURITY_UserSelect 85
-- 
-- Revision History:
-- Author          : RealPage
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [security].[uspSECURITY_UserSelect]  (@IPN_UserIDSeq bigint)
AS
BEGIN
  ----------------------------------------------------------
  SELECT  FirstName, LastName, Title, Email, NTUser, Department
  FROM    [User] 
  WHERE   IDSeq = @IPN_UserIDSeq
  ----------------------------------------------------------

  ----------------------------------------------------------
  SELECT  RoleIDSeq 
  FROM    UserRoles
  WHERE   UserIDSeq = @IPN_UserIDSeq
  ----------------------------------------------------------
END




 
GO
