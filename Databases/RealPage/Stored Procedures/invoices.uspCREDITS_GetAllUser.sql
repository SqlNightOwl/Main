SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCREDITS_GetAllUser]
-- Description     : This procedure returns the User List based on Credit Administrator role.
-- Input Parameters: 	
-- 
-- OUTPUT          : RecordSet of USer ID,User Name
-- Code Example    : Exec INVOICES.[dbo].[uspCREDITS_GetAllUser] 
-- 
-- 
-- Revision History:
-- Author          : rri\dnethunuri
-- 12/13/2010      : Defect #8642 (ability to approve multiple credits at the same time).
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [invoices].[uspCREDITS_GetAllUser] 
AS
BEGIN

	SELECT DISTINCT 
		U.IDSeq, 
		U.FirstName + ' '+ U.LastName AS UserName
	FROM [Security].dbo.[Roles] R
	JOIN [Security].dbo.[UserRoles] UR on R.IDSeq = UR.RoleIDSeq
	JOIN [Security].dbo.[user] U on UR.UserIDSeq = U.IDSeq 
	WHERE R.Code ='UCre'
	ORDER BY U.FirstName + ' '+ U.LastName

END
GO
