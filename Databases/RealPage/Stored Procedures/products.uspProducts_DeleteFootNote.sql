SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspProducts_DeleteFootNote]
@IPI_IDSeq BIGINT

AS
BEGIN
	 DELETE FROM Products.dbo.ProductFootNote WHERE IDSeq=@IPI_IDSeq
END
GO
