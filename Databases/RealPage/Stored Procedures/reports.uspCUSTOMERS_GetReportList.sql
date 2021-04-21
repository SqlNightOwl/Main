SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetReportList]
-- Description     : This procedure returns the Report List
-- 
-- OUTPUT          : RecordSet of fields describing the Report.
-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERS_GetReportList] 
-- 
-- Revision History:
-- Author          : Naval Kishore Singh
-- 07/02/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspCUSTOMERS_GetReportList](@IPI_PageNumber       as  int, 
					                                          @IPI_RowsPerPage      as  int, 
					                                          @IPI_IDSeq            as  int,
                                                    @IPI_UserIDSeq        as  bigint)  
AS
BEGIN

----------------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------------
  WITH tablefinal AS 
       ----------------------------------------------------------  
       (SELECT tableinner.*
        FROM
           ---------------------------------------------------------- 
          (select  row_number() over(order by SortSeq asc, ReportName asc)
                                         as RowNumber,
                   source.*
           from
             ----------------------------------------------------------  
          (SELECT DISTINCT
               r.IDSeq           as IDSeq,
               rc.[Name]          as ReportType,
               r.Description     as Description,
               r.[Name]           as ReportName,
               rc.SortSeq       


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
	                      
           ------------------------------------------------------------------
           )source
          --------------------------------------------------------------------
          )tableinner
         ----------------------------------------------------------------------
         WHERE tableinner.RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage
         AND   tableinner.RowNumber <= (@IPI_PageNumber) * @IPI_RowsPerPage 
        )
       SELECT  tablefinal.RowNumber,
               tablefinal.IDSeq               as IDSeq,
               tablefinal.ReportType          as ReportType,
	             tablefinal.Description         as Description,
               tablefinal.ReportName          as ReportName            
      from     tablefinal 
      Order by tablefinal.ReportType,tablefinal.ReportName

  -----------------------------------------------------------
END
GO
