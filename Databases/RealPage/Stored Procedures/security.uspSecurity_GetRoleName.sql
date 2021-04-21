SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Security
-- Procedure Name  : [uspSecurity_GetRoleName].sql
-- Description     : This procedure gets Users Roles List 

-- Code Example    : Exec Security.dbo.[uspSecurity_GetRoleName] 
-- Revision History:
-- Author          : Anand Chakravarthy
-- 19/05/2009      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------

CREATE procedure [security].[uspSecurity_GetRoleName] 
AS
BEGIN
select Code,[Name] from Security.dbo.Roles
order by [Name] asc
END
GO
