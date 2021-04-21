SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERSREPORTS_GetReportCategory]
-- Description     : This procedure returns the Report List
-- 
-- OUTPUT          : RecordSet of fields describing the Report.
-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERSREPORTS_GetReportCategory] 
-- 
-- Revision History:
-- Author          : Naval Kishore Singh
-- 07/02/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspCUSTOMERSREPORTS_GetReportCategory] @IPI_UserIDSeq bigint  
AS
BEGIN

      SELECT DISTINCT
               IDSeq           as IDSeq,
               [Name]          as ReportName
      FROM     CUSTOMERS.dbo.ReportCategory rc with (nolock)
      INNER JOIN SECURITY.dbo.RoleRights rr with (nolock)
      ON    rc.RightIDSeq = rr.RightIDSeq
      INNER JOIN SECURITY.dbo.UserRoles ur with (nolock)
      ON    rr.RoleIDSeq = ur.RoleIDSeq
      WHERE   ur.UserIDSeq = @IPI_UserIDSeq            
      order by ReportName

  -----------------------------------------------------------
END
GO
