SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspProducts_GetRevenueRecognitionList]
			  
AS
BEGIN
	 SELECT CODE,[NAME] FROM Products.dbo.RevenueRecognition  with(nolock)
END
GO
