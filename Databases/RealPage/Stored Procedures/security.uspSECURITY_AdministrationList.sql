SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : SECURITY
-- Procedure Name  : uspSECURITY_AdministrationList.sql
-- Description     : This procedure gets Administration List 

-- Input Parameters:
-- 
-- OUTPUT          : 

-- Code Example    : 

-- Revision History:

-- Author          : NAL, SRA Systems Limited.

-- 22/02/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspSECURITY_AdministrationList] (
                                                          @IPI_PageNumber     int,
                                                          @IPI_RowsPerPage    int, 
                                                          @IPVC_FirstName     varchar(200),
                                                          @IPVC_LastName      varchar(200),
                                                          @IPVC_Role          varchar(20),
                                                          @IPVC_OptionSelected int
)
AS
BEGIN

select * from 
(  
    SELECT top  (@IPI_RowsPerPage *  @IPI_PageNumber)
           u.IDSeq,
           u.FirstName,
           u.LastName,
           u.Title,
           u.LastLoginDate 
    FROM [Security]..[User] as u
    INNER JOIN [Security]..UserRoles  as r
    on r.UserIDSeq = u.IDSeq
    WHERE u.FirstName  like  '%'+@IPVC_FirstName+'%'
    AND   u.LastName   like  '%'+@IPVC_LastName+'%'
    AND     (
                 ((@IPVC_OptionSelected = '1' )      and      (u.LastLoginDate             BETWEEN   (DATEADD(week, -1, GETDATE()))  AND  GETDATE()))
                 or            
                 ((@IPVC_OptionSelected = '2' )      and      (u.LastLoginDate             BETWEEN   (DATEADD(m, -1, GETDATE()))     AND  GETDATE())) 
                 or            
                 ((@IPVC_OptionSelected = '0' )      and       convert(varchar(12),u.LastLoginDate,101) = convert(varchar(12),GETDATE(),101))                  
                 or
                 (@IPVC_OptionSelected = '' )  
            )  
)tbl
   
    
  
END

-- Exec [SECURITY].[dbo].[uspSECURITY_AdministrationList] 1,1,'stallin','','2',0


GO
