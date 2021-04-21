SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : SECURITY
-- Procedure Name  : uspSECURITY_GetUser.sql
-- Description     : This procedure gets user

-- Input Parameters:
-- 
-- OUTPUT          : 

-- Code Example    : 

-- Revision History:

-- Author          : NAL, SRA Systems Limited.

-- 22/02/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspSECURITY_GetUser] 
AS
BEGIN

SELECT IDSeq,FirstName,LastName,NTUser FROM [SECURITY].[dbo].[User]

 
END

-- Exec [SECURITY].[dbo].[uspSECURITY_GetRoles] 


GO
