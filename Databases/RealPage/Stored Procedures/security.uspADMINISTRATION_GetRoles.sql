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

-- June 26, 2010   : Naval Kishore Modified for defect # 7748

------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspADMINISTRATION_GetRoles] 
AS
BEGIN
 
   SELECT IDSeq,Code,[Name] 
   FROM   [SECURITY].[dbo].Roles with (nolock) 
   where  ActiveFlag = 1
   order by [Name]

END
GO
