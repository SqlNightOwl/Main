SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERSREPORTS_GetReportListCount]
-- Description     : This procedure returns the Report List
-- 
-- OUTPUT          : RecordSet of fields describing the Report.
-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERSREPORTS_GetReportListCount] 
-- 
-- Revision History:
-- Author          : Naval Kishore Singh
-- 07/02/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspCUSTOMERSREPORTS_GetReportListCount] 
                                              (@IPI_IDSeq            as  int, @IPI_UserIDSeq bigint) 


AS
BEGIN-->Main Begin
  ----------------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------------
  WITH tablefinal AS 
       ----------------------------------------------------------
       (SELECT count(tableinner.IDSeq)   as [Count]
           FROM
           ----------------------------------------------------------   
           (select  *
            from
             ----------------------------------------------------------
             (SELECT DISTINCT
               rc.IDSeq           as IDSeq,
               rc.[Name]          as ReportType,
               rc.Description     as Description,
               r.[Name]           as ReportName


              FROM CUSTOMERS.dbo.ReportCategory rc with (nolock)

              INNER JOIN CUSTOMERS.dbo.Report r with (nolock)
                ON  r.CategoryIDSEQ = rc.IDSEQ
              INNER JOIN SECURITY.dbo.RoleRights rr with (nolock)
              ON    r.RightIDSeq = rr.RightIDSeq
              INNER JOIN SECURITY.dbo.UserRoles ur with (nolock)
              ON    rr.RoleIDSeq = ur.RoleIDSeq
	          WHERE   ur.UserIDSeq = @IPI_UserIDSeq            
            AND
		          ((@IPI_IDSeq is not null and 
                     rc.IDSeq = + @IPI_IDSeq ) 
                or @IPI_IDSeq     = '')
	                      )source
        ------------------------------------------------------------------------
        ) tableinner
      -----------------------------------------------------------------------------
      )
      SELECT  tablefinal.[Count]    
      from     tablefinal 
  -------------------------------------------------------------------------------

 -----------------------------------------------------------
END
GO
