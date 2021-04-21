SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : Administration
-- Procedure Name  : uspAdministration_AdministrationList.sql
-- Description     : This procedure gets Administration List 

-- Input Parameters:@IPI_PageNumber     int,
--                  @IPI_RowsPerPage    int, 
--                  @IPVC_FirstName     varchar(200),
--                  @IPVC_LastName      varchar(200),
--                  @IPVC_Role          int,
--                  @IPVC_OptionSelected varchar(2)
-- 
-- OUTPUT          : IDSeq,
--                   [Name],
--                   Title,
--                   LastLoginDate,
--                   RowNumber

-- Code Example    : 

-- Revision History:

-- Author          : NAL, SRA Systems Limited.

-- 22/02/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspADMINISTRATION_AdministrationList] (
                                                          @IPI_PageNumber     int,
                                                          @IPI_RowsPerPage    int, 
                                                          @IPVC_FirstName     varchar(200),
                                                          @IPVC_LastName      varchar(200),
                                                          @IPVC_Role          int,
                                                          @IPVC_OptionSelected varchar(2)
)
AS
BEGIN

------------------------------------------------------------------------------------------------------
----                                        Retrives Administration List
------------------------------------------------------------------------------------------------------

  SELECT TOP (@IPI_RowsPerPage)

              IDSeq,

              [Name],

              Title,

              LastLoginDate,
              
              Department,

           CASE WHEN (ActiveFlag = 'TRUE') THEN
						  'Active'
				  WHEN (ActiveFlag = 'FALSE') THEN
						  'InActive'
				  END as Status,

              RowNumber
 

  FROM       (SELECT DISTINCT   u.IDSeq,

                                u.FirstName + ' ' + u.LastName                             AS [Name],

                                u.Title,

                                u.LastLoginDate,

                                u.Department,
                               
                                u.ActiveFlag,

                                row_number() OVER(ORDER BY u.FirstName + ' ' + u.LastName)  AS RowNumber

              FROM              [Security]..[User] AS u

              LEFT OUTER JOIN   [Security]..[UserRoles] ur   on ur.UserIDSeq = u.IDSeq

              LEFT OUTER JOIN   [Security]..[Roles] r        on r.IDSeq = ur.RoleIDSeq

              WHERE             u.FirstName  like  '%'+@IPVC_FirstName+'%'

              AND               u.LastName   like  '%'+@IPVC_LastName+'%'

              AND (
                                ((@IPVC_OptionSelected = '1' ) 
                                  and (u.LastLoginDate        
                                  BETWEEN (DATEADD(week, -1, GETDATE()))  AND  GETDATE()))
    
                                 or      
            
                                ((@IPVC_OptionSelected = '2' )      
                                  and (u.LastLoginDate   
                                  BETWEEN   (DATEADD(m, -1, GETDATE()))    AND  GETDATE())) 

                                 or            
                    
                                ((@IPVC_OptionSelected = '0' )      
                                  and  convert(varchar(12),u.LastLoginDate,101) 
                                        = convert(varchar(12),GETDATE(),101))      
            
                                 or

                                (@IPVC_OptionSelected = '' ) 
                  )

              AND               ((@IPVC_Role = '') or EXISTS(
                                                select 1 
                                                from UserRoles 
                                                where RoleIDSeq = @IPVC_Role and UserIDSeq = u.IDSeq)
                                                )
              ) tbl
WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage
ORDER BY Name

------------------------------------------------------------------------------------------------------
--                                         Count of records 
------------------------------------------------------------------------------------------------------

  Select      count(*)

  FROM        [Security]..[User] as u

  WHERE       u.FirstName  like  '%'+@IPVC_FirstName+'%'

  AND         u.LastName   like  '%'+@IPVC_LastName+'%'

  AND (
              ((@IPVC_OptionSelected = '1' ) 
              AND (u.LastLoginDate 
              BETWEEN (DATEADD(week, -1, GETDATE()))  AND  GETDATE()))

              OR  
          
              ((@IPVC_OptionSelected = '2' )
              AND (u.LastLoginDate 
              BETWEEN   (DATEADD(m, -1, GETDATE()))     AND  GETDATE())) 

             OR
            
              ((@IPVC_OptionSelected = '0' ) 
              AND convert(varchar(12),u.LastLoginDate,101) = convert(varchar(12),GETDATE(),101)) 
                 
             OR

             (@IPVC_OptionSelected = '' ) 
        )
  AND (

            (@IPVC_Role = '') or EXISTS(
                                        SELECT 1 
                                        FROM UserRoles 
                                        WHERE RoleIDSeq = @IPVC_Role and UserIDSeq = u.IDSeq))
   
------------------------------------------------------------------------------------------------------
END

------------------------------------------------------------------------------------------------------

-- Exec [Administration].[dbo].[uspAdministration_AdministrationList] 1,3,'','',,

--Exec Security.dbo.uspAdministration_AdministrationList 1,10,'','','',''


------------------------------------------------------------------------------------------------------

GO
