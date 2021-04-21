SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspProducts_GetFootNote]

		@IPVC_ProductCode VARCHAR(20),
		@IPN_PriceVersion NUMERIC(18,0)
AS
BEGIN

SELECT
       PF.IDSeq,
       PF.ProductCode,
       PF.PriceVersion,
       PF.DisabledFlag,
       PF.FootNote,
       P.Name 
FROM		Products.dbo.ProductFootNote PF with(nolock) 
inner join  Products.dbo.Product P with(nolock)
		 ON PF.ProductCode=P.Code 
AND			PF.PriceVersion = P.PriceVersion
AND			PF.PriceVersion = @IPN_PriceVersion
WHERE ProductCode=@IPVC_ProductCode
AND   P.PriceVersion = @IPN_PriceVersion
END
GO
