SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Security
-- Procedure Name  : [uspSecurity_GetUserRolesReportRights].sql
-- Description     : This procedure gets Users Roles List 

-- Code Example    : Exec Security.dbo.[uspSecurity_GetUserRolesReportRights] 
-- Revision History:
-- Author          : Anand Chakravarthy
-- 19/05/2009      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [reports].[uspSecurity_GetUserRolesReportRights]  
(  
                                               @IPVC_RoleName   varchar(8000)  
)  
AS  

DECLARE @LT_RoleName TABLE (RoleName CHAR(100))
DECLARE @LVC_Delimiter       char(1)
DECLARE @SQLErrorCode        int    
DECLARE @SQLRowCount         int
SET @LVC_Delimiter = ','   
BEGIN  


IF (@IPVC_RoleName IS NULL OR LTRIM(RTRIM(@IPVC_RoleName)) = '') SET @IPVC_RoleName = ''  
IF LEN(@IPVC_RoleName) > 0 AND CHARINDEX(@IPVC_RoleName,'',1) > 0 SET @IPVC_RoleName = '' -- If all is one selection, set to all  
IF @IPVC_RoleName <> '' -- parameters were passed  
BEGIN  
 --Parse the string to get all the parameters passed  
 INSERT INTO @LT_RoleName ([RoleName])  
 SELECT [Items] as [RoleName] from OMSREPORTS.dbo.fnSplitDelimitedString(@IPVC_RoleName,@LVC_Delimiter) 
-- select rolename from  @LT_RoleName
 SELECT @SQLErrorCode = @@ERROR, @SQLRowCount = @@ROWCOUNT  
 IF @SQLErrorCode <> 0  
 begin  
  PRINT 'A SQL Error occurred, ' + CAST(@SQLErrorCode AS VARCHAR(10)) + ', attempting to get '  
   + 'the Category Code parameters passed.'  
  RETURN -1  
 end  
 IF @SQLRowCount = (SELECT COUNT(1) FROM Security.dbo.Roles (NOLOCK)) SET @IPVC_RoleName= ''  
END  

  
------------------------------------------------------------------------------------------------------  
----                                        Retrives User Roles Rights  
------------------------------------------------------------------------------------------------------  

SELECT   
       R.Name      AS RightName,  
       RO.Name                   AS RoleName,  
(CASE WHEN rr.roleidseq is null THEN 0 ELSE 1     
  END)                           AS [RoleRight]    
FROM Roles Ro 
INNER JOIN @LT_RoleName LR 
ON Ro.Name   =  LR.RoleName collate SQL_Latin1_General_CP1_CI_AS  
CROSS JOIN Rights R  
LEFT JOIN  RoleRights RR  
ON RR.rightidseq = R.idseq  
AND  RR.roleidseq = RO.idseq
ORDER BY R.Name
     
------------------------------------------------------------------------------------------------------  
END  
GO
