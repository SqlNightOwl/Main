SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Security
-- Procedure Name  : [uspSECURITY_GetUserName]
-- Description     : Gets the NT User's name
-- Input Parameters: 1. @IPVC_NTUser        as varchar(40)
--                   
-- OUTPUT          : the NT User's name
--
-- Code Example    : Exec Customers.DBO.[uspSECURITY_GetUserName] @IPVC_NTUser = 'rri\dcannon'
-- 
-- 
-- Revision History:
-- Author          : DCANNOn
-- 4/02/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [security].[uspSECURITY_GetUserName](
                                                    @IPVC_NTUser varchar(40)
                                                    )

AS
BEGIN
  select top 1 FirstName + ' ' + LastName
  from Security.dbo.[User]
  where lower(NTUser) = lower(@IPVC_NTUser)
END

GO
