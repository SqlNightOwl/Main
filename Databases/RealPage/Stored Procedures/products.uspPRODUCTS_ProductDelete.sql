SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ProductDelete]
			@IPVC_ProductCode	VARCHAR(50),
			@IPVC_PriceVersion	NUMERIC(18,0)
			
					 
AS
BEGIN--> Main Begin
DELETE FROM Products.dbo.ProductFootNote WHERE ProductCode=@IPVC_ProductCode and PriceVersion =@IPVC_PriceVersion
DELETE FROM Products.dbo.ChargeFootNote WHERE ProductCode=@IPVC_ProductCode and PriceVersion =@IPVC_PriceVersion
DELETE FROM Products.dbo.ProductInvalidCombo WHERE FirstProductCode=@IPVC_ProductCode and FirstProductPriceVersion =@IPVC_PriceVersion
DELETE FROM Products.dbo.StockProductLookUp WHERE StockProductCode=@IPVC_ProductCode and StockProductPriceVersion =@IPVC_PriceVersion
DELETE FROM Products.dbo.Charge WHERE ProductCode=@IPVC_ProductCode and PriceVersion =@IPVC_PriceVersion
DELETE FROM Products.dbo.Product WHERE Code=@IPVC_ProductCode and PriceVersion =@IPVC_PriceVersion
END-->Main End
GO
