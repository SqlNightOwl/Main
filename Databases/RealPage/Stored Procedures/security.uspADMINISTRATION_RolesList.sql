SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : SECURITY
-- Procedure Name  : uspSECURITY_OrderList
-- Description     : This procedure gets the IDSEq Code and Name from the Roles table
--
-- Input Parameters: @IPI_PageNumber      as    integer 
--                   @IPI_RowsPerPage     as    integer 
-- 
-- OUTPUT          : RecordSet of IDSeq, Code and name
-- Code Example    : Exec [SECURITY].DBO.[uspADMINISTRATION_RolesList]  @IPI_PageNumber  =   2,
--					                                                            @IPI_RowsPerPage =   20, 
--                                                        
-- Revision History:
-- Author          : STA
-- 04/09/2006      : Stored Procedure Created.
-- June 26, 2010   : Naval Kishore Modified for defect # 7748
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [security].[uspADMINISTRATION_RolesList]  (
                                                         @IPI_PageNumber    int,
                                                         @IPI_RowsPerPage   int
                                                      )
AS
BEGIN
  /***************************************************************************/
  SELECT * 
  FROM
        (
	        SELECT  TOP (@IPI_RowsPerPage * @IPI_PageNumber)          
                      IDSeq                                   AS IDSeq,
                      Code                                    AS Code,
                      [Name]                                  AS [Name],
					  (Case when ActiveFlag = 1
							then 'Active'
							Else 'Inactive'
							END)  AS [Status],
                      row_number() OVER(ORDER BY [Name])      AS RowNumber 
          FROM        [SECURITY].[dbo].Roles with (nolock)                  
        ) LVT_RolesList

  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage

  /***************************************************************************/  
  SELECT COUNT(*) FROM [SECURITY].[dbo].Roles 
  /***************************************************************************/
END
GO
