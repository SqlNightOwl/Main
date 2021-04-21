SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Security
-- Procedure Name  : [uspSECURITY_CheckRole]
-- Description     : Checks the RoleName Exists or not
-- Input Parameters: 1. @IPVC_Role        as varchar(50)
--                   
-- OUTPUT          : RoleName
--
-- Code Example    : Exec Customers.DBO.[uspSECURITY_CheckRole] @IPVC_Role = 'Adminstrator'
-- 
-- 
-- Revision History:
-- Author          : Raghavender Reddy.
-- 23/04/2008      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspSECURITY_CheckRole]  (@IPN_IDSeq bigint, @IPVC_Role varchar(50))
AS
BEGIN
  SELECT [name] FROM Roles WHERE [name]=@IPVC_Role and IDSeq <> @IPN_IDSeq
END




  
GO
