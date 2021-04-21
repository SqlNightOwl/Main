SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : PRODUCTS      
-- Procedure Name  : [uspPRODUCTS_GetSelectedAssociatedProducts]      
-- Description     : This procedure gets Code,Name      
--                   from product table       
-- Input Parameters:       
-- OUTPUT          : RecordSet of Code,Name,PriceVersion      
-- Code Example    : exec [dbo].[uspPRODUCTS_GetSelectedAssociatedProducts] 'PRM-LEG-LEG-LEG-LAAP',101       
-- Author          : Anand Chakravarthy       
-- 15/07/2009      : Stored Procedure Created.      
      
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [products].[uspPRODUCTS_GetSelectedAssociatedProducts]       
     @IPVC_ProductCode VARCHAR(30),      
     @IPN_PriceVersion NUMERIC(18,0)         
AS      
BEGIN      
--------------------------------------------------------------------------------------------------      
--Product Details       
--------------------------------------------------------------------------------------------------      
  SELECT StockProductCode,       
   StockProductPriceVersion,       
   AssociatedProductCode,       
   AssociatedProductPriceVersion       
 FROM Products.dbo.StockProductLookUp      
 WHERE StockProductCode = @IPVC_ProductCode AND StockProductPriceVersion=@IPN_PriceVersion      
--------------------------------------------------------------------------------------------------      
SELECT P.DisplayName as SecondProductName,SP.AssociatedProductCode as SecondProductCode 
from Products.dbo.StockProductLookUp SP  
inner join   
Products.dbo.Product P   
on SP.AssociatedProductCode = P.Code  
AND SP.AssociatedProductPriceVersion = p.PriceVersion     
WHERE SP.StockProductPriceVersion = @IPN_PriceVersion   
      AND StockProductCode=  @IPVC_ProductCode  
  
END  
GO
