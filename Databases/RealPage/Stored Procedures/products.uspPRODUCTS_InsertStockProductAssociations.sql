SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_InsertStockProductAssociations]
-- Description     : This INSERT OPERATIONS
   
 
-- Code Example    : exec [dbo].[uspPRODUCTS_InsertStockProductAssociations]  
-- Author          : Raghavender Reddy.T
-- 15/06/2009	   : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_InsertStockProductAssociations](
                                                          @IPC_ProductCode		CHAR(30),
                                                          @IPN_PriceVersion		NUMERIC(18,0),
                                                          @IPC_SecondProduct	VARCHAR(4000)
                                                     ) 		
AS
BEGIN
DECLARE @loopid INT;
DECLARE @PriceVersion NUMERIC(18,0)
--------------------------------------------------------------------------------------------------
--Delete from ProductInvalidCombo for existing Combination
--------------------------------------------------------------------------------------------------
DELETE FROM dbo.StockProductLookUp WHERE StockProductCode=@IPC_ProductCode  
                                      AND StockProductPriceVersion=@IPN_PriceVersion      
   
   
CREATE TABLE #Tbl1 (rowid int identity(1,1),
					ProductCode varchar(4000))

INSERT INTO #Tbl1(ProductCode)  
SELECT ProductCode  FROM   Customers.dbo.fnSplitProductCodes ('|'+@IPC_SecondProduct)

SELECT @loopid = 1

WHILE @loopid <= (SELECT Count(rowid) FROM #Tbl1)
BEGIN

SET @PriceVersion = (select P.Priceversion from Products.dbo.Product P inner join #Tbl1 T1 on p.code = T1.Productcode where T1.ProductCode = P.Code and P.DisabledFlag = 0 and P.PendingApprovalFlag=0 and  T1.rowid = @loopid)
INSERT INTO dbo.StockProductLookUp
              (
				StockProductCode,  
				StockProductPriceVersion,  
                AssociatedProductCode,  
                AssociatedProductPriceVersion  
              ) 
           SELECT 
                  @IPC_ProductCode,
                  @IPN_PriceVersion, 
                  T1.ProductCode,
                  @PriceVersion  
           From  #Tbl1 T1
           where T1.rowid = @loopid  
          
SET @loopid = @loopid + 1
END
drop table #Tbl1
END
GO
