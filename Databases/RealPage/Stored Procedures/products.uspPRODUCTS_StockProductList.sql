SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_PlatformList
-- Description     : This procedure gets the list of  dbo.StockProductLookUp 
--
-- OUTPUT          : RecordSet of Code, Name from PRODUCTS..[StockProductLookUp]
--
-- Code Example    : Exec [uspPRODUCTS_StockProductList] 1,10,'DMD-OSD-CNV-CNV-CTRV','700'
--
-- Revision History:
-- Author          : Raghavender Talusani.
-- 04/23/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_StockProductList] 
@IPI_PageNumber     int,         
@IPI_RowsPerPage    int,    
@IPC_ProductCode char(30),    
@IPN_PriceVersion   NUMERIC(18,0)       
as    
begin     
 SELECT * FROM (            
    ---------------------------------------------------------------------------------            
    SELECT        
 SP.StockProductCode,     
 SP.StockProductPriceVersion,     
 SP.AssociatedProductCode,     
 SP.AssociatedProductPriceVersion,    
 P.[Name] as ProductName,    
 P.DisplayName as DisplayName,    
  row_number() over(order by idseq)   as RowNumber     
 from   Products.dbo.StockProductLookUp SP LEFT JOIN  Products.dbo.Product P on SP.AssociatedProductCode=P.Code    
 AND SP.AssociatedProductPriceVersion = p.PriceVersion     
 --AND SP.AssociatedProductCode = P.Code    
    WHERE SP.StockProductPriceVersion = @IPN_PriceVersion   
          AND StockProductCode=  @IPC_ProductCode )tbl    
     
 WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage  and   StockProductCode=  @IPC_ProductCode and StockProductPriceVersion = @IPN_PriceVersion       
                   
     
   SELECT COUNT(*) From Products.dbo.StockProductLookUp where  StockProductCode=  @IPC_ProductCode and StockProductPriceVersion = @IPN_PriceVersion      
    
END      
GO
