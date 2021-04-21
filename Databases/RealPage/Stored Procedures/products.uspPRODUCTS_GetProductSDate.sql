SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_GetProductSDate]
								@IPVC_ProductCode VARCHAR(50),
								@IPN_PriceVersion NUMERIC(18,0)
								 

AS
BEGIN
SELECT      Convert(VARCHAR(12), StartDate,101) AS StartDate 
FROM	Products.dbo.Product with(nolock)
WHERE	Code=@IPVC_ProductCode
AND     PriceVersion = @IPN_PriceVersion
										 
END
GO
