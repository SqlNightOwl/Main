SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [invoices].[uspINVOICES_GetFamilyFootNoteList]  (
                                                              @IPI_PageNumber    int,
                                                              @IPI_RowsPerPage   int
                                                            )	
AS
BEGIN
  ----------------------------------------------------------------------------
  ----------------------------------------------------------------------------
	SELECT  *
  FROM    (
	          SELECT  TOP   (@IPI_RowsPerPage * @IPI_PageNumber)
                            FFN.IDSeq                   AS IDSeq,
                            FFN.FamilyCode              AS FamilyCode,
                            F.Name                      AS FamilyName,
                            FFN.Description             AS [Description],
              row_number()  OVER(ORDER BY [Name])       AS RowNumber
              FROM        INVOICES.dbo.FamilyFootNote FFN with (nolock)
              INNER JOIN  PRODUCTS.dbo.Family F with (nolock)
                ON        F.Code = FFN.FamilyCode
          ) LVT_FootNoteListList
  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage
  ----------------------------------------------------------------------------

  ----------------------------------------------------------------------------
  SELECT COUNT(*) FROM INVOICES.dbo.FamilyFootNote with (nolock)
  ----------------------------------------------------------------------------

END

GO
