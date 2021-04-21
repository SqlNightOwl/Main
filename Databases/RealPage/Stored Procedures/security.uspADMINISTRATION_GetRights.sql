SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : Administration
-- Procedure Name  : uspAdministration_GetRoles.sql
-- Description     : This procedure gets Roles

-- Input Parameters:
-- 
-- OUTPUT          : 

-- Code Example    : 

-- Revision History:

-- Author          : NAL, SRA Systems Limited.

-- 22/02/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspADMINISTRATION_GetRights] 
AS
BEGIN

SELECT IDSeq,Code,[Name] FROM [SECURITY].[dbo].Rights order by [Name]

 
END

-- Exec Security.[dbo].[uspADMINISTRATION_GetRights] 

GO
