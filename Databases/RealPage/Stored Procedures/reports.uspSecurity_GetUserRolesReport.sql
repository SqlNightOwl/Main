SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Security
-- Procedure Name  : [uspSecurity_GetUserRolesReport].sql
-- Description     : This procedure gets Users Roles List 

-- Input Parameters:@IPVC_FirstName     varchar(200),
--					  @IPVC_LastName      varchar(200),
--					  @IPVC_Department    varchar(200),
--					  @IPVC_Title		  varchar(200),
--					  @IPVC_StatusOption varchar(2)
-- 
-- OUTPUT          : IDSeq,
--                   [Name],
--                   Title,
--                   LastLoginDate,
--                   RowNumber

-- Code Example    : Exec Security.dbo.[uspSecurity_GetUserRolesReport] 'naval','','','',''
-- Revision History:
-- Author          : Naval Kishore Singh
-- 19/03/2009      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [reports].[uspSecurity_GetUserRolesReport] (
                                                          @IPVC_FirstName     varchar(200),
                                                          @IPVC_LastName      varchar(200),
                                                          @IPVC_Department    varchar(200),
														  @IPVC_Title		  varchar(200),
                                                          @IPVC_Status		  varchar(10)
)
AS
BEGIN

------------------------------------------------------------------------------------------------------
----                                        Retrives User Roles
------------------------------------------------------------------------------------------------------

SELECT 
		u.IDSeq						AS IDSeq,
		(CASE WHEN (u.ActiveFlag = 'TRUE') THEN 'Active'  
			 WHEN (u.ActiveFlag = 'FALSE') THEN 'InActive' 
			 ELSE 'NULL' 
		END)						 AS [Status],  
		(u.FirstName+' '+u.LastName) AS [name],
		R.name						 AS RoleName,
		(CASE WHEN ur.useridseq is null THEN 0 ELSE 1 
		END)						 AS [right]
FROM Security.dbo.[User] u
	cross join Security.dbo.Roles R
	left join Security.dbo.UserRoles uR
ON ur.roleidseq = R.IDseq
	and ur.useridseq = u.idseq
WHERE u.FirstName  LIKE  '%'+@IPVC_FirstName+'%'
AND   u.LastName   LIKE  '%'+@IPVC_LastName+'%'
AND   (
		((@IPVC_Title = '') and (u.Title is null or u.Title      LIKE  '%'+@IPVC_Title+'%')) 
    or     u.Title      LIKE  '%'+@IPVC_Title+'%')
AND   isnull(u.Department,'') = isnull(nullif(@IPVC_Department,''), isnull(u.department,''))
AND   ((@IPVC_Status='') or  ( ISNULL(u.ActiveFlag,0) = isnull(nullif(@IPVC_Status,''),ISNULL(u.ActiveFlag,0)))) 
ORDER BY u.IDSeq, R.Name 

------------------------------------------------------------------------------------------------------
END

------------------------------------------------------------------------------------------------------

--Exec Security.dbo.[uspSecurity_GetUserRolesReport] '','','','financ','' 
------------------------------------------------------------------------------------------------------


GO
