SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : PRODUCTS  
-- Procedure Name  : [uspPRODUCTS_GetAvailableStockProducts]  
-- Description     : This procedure gets Code,Name  
--                   from product table   
-- Input Parameters:   
-- OUTPUT          : RecordSet of Code,Name,PriceVersion  
-- Code Example    : exec [dbo].[uspPRODUCTS_GetAvailableStockProducts] 'PRM-LEG-LEG-LEG-LAAP',100   
-- Author          : Raghavender   
-- 12/06/2007      : Stored Procedure Created.  
  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [products].[uspPRODUCTS_GetAvailableStockProducts]   
     @IPVC_ProductCode VARCHAR(30),  
     @IPN_PriceVersion NUMERIC(18,0)     
AS  
BEGIN  
--------------------------------------------------------------------------------------------------  
--Product Details   
--------------------------------------------------------------------------------------------------  
   
  SELECT   
			P.Code							 as ProductCode,  
           --P.PriceVersion                  as PriceVersion,  
			P.[Name]                         as ProductName  
        
    FROM Products.dbo.Product P WITH (NOLOCK)  
    WHERE DisabledFlag=0 and PendingApprovalFlag=0   
    AND (P.Code not in (SELECT secondproductcode   
					    FROM Products.dbo.ProductInvalidCombo WITH (NOLOCK)  
                        WHERE FirstProductCode=@IPVC_ProductCode and FirstProductPriceVersion=@IPN_PriceVersion
                       )
        )  
 ORDER BY P.Name ASC  
  
--------------------------------------------------------------------------------------------------  
  
END  
GO
