SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : SECURITY
-- Procedure Name  : uspSECURITY_RightsList
-- Description     : Get Rights details
-- Input Parameters: 
-- Code Example    : EXEC [SECURITY].dbo.[uspSECURITY_RightsList]  1, 20

-- Revision History:
-- Author          : dnethunuri
-- 11/22/2010      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [security].[uspSECURITY_RightsList] (
                                                          @IPI_PageNumber     int,
                                                          @IPI_RowsPerPage    int,
														  @IPVC_Right		  varchar(50),
                                                          @IPVC_RightCode     varchar(20)
                                                         
                                                         
)
AS
BEGIN

------------------------------------------------------------------------------------------------------
----                                        Retrives Rights List
------------------------------------------------------------------------------------------------------

 SELECT  DISTINCT
	COUNT (*) OVER() as TotalRows,
	row_number() OVER(ORDER BY [Name],IDSeq) AS RowNumber, 
	IDSeq,
	Code, 
	[Name]
	INTO #tblRights
	FROM [Security].dbo.[Rights] 

  SELECT * FROM #tblRights
	WHERE
		(((@IPVC_Right <> '') and ([Name] like '%' + @IPVC_Right + '%')) OR (@IPVC_Right =  ''))
	AND (((@IPVC_RightCode <> '') and (Code like '%' + @IPVC_RightCode + '%')) OR (@IPVC_RightCode =  ''))
	AND RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
       AND   RowNumber <= (@IPI_PageNumber)  * @IPI_RowsPerPage

DROP TABLE #tblRights
  
------------------------------------------------------------------------------------------------------
END
GO
