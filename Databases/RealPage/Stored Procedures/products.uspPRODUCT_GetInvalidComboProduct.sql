SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCT_GetInvalidComboProduct]
-- Description     : This procedure gets ProductName,SecondProductCode,IDSeq pertaining to passed 
--                   ProductCode and PriceVersion
-- Input Parameters: @IPC_ProductCode       as    char,
--                   @IPN_PriceVersion      as    numeric
-- OUTPUT          : Dataset of ProductName,SecondProductCode,IDSeq
-- Code Example    : exec PRODUCTS.[dbo].[uspPRODUCT_GetInvalidComboProduct] 'PRM-LEG-LEG-LEG-LAAP',101 
-- Author          : Naval Kishore Singh 
-- 09/07/2007     : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCT_GetInvalidComboProduct]
                                                   (
                                                    @IPC_ProductCode  varchar(30),
                                                    @IPN_PriceVersion numeric(18,0),
                                                    @IPI_PageNumber   int, 
                                                    @IPI_RowsPerPage  int
                                                    )					
AS
BEGIN
  ---------------------------------------------------------------------------------
      SELECT * FROM
      (
      SELECT Source.*,
             row_number() OVER(ORDER BY Source.DisplayName ) as RowNumber
      FROM 
          (SELECT DISTINCT
                  P.[Name]												 as ProductName,
                  P.DisplayName											 as DisplayName,
                  PIC.SecondProductCode									 as SecondProductCode,
                  (Select convert(VARCHAR(12),P1.StartDate,101)
                  From Products.dbo.Product P1 with (nolock)
                  Where P1.Code = @IPC_ProductCode
                  And   P1.PriceVersion = @IPN_PriceVersion)			 as StartDate,
                  convert(VARCHAR(12),P.EndDate,101)					 as EndDate           
           FROM Products.dbo.ProductInvalidCombo PIC with (nolock)
           INNER JOIN Products.dbo.Product P with (nolock)
           ON    P.Code = PIC.SecondProductCode  
           and   P.disabledflag = 0    
           WHERE PIC.FirstProductCode        = @IPC_ProductCode 
           AND   PIC.FirstProductPriceVersion= @IPN_PriceVersion
          ) source 
      ) tbl     
      where tbl.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
      AND   tbl.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage 
  -----------------------------------------------------------------------------------------
  SELECT  COUNT(DISTINCT P.Code) 
  FROM Products.dbo.ProductInvalidCombo PIC with (nolock)
  INNER JOIN Products.dbo.Product P with (nolock)
  ON    P.Code = PIC.SecondProductCode     
  and   P.disabledflag = 0     
  WHERE PIC.FirstProductCode        = @IPC_ProductCode 
  AND   PIC.FirstProductPriceVersion= @IPN_PriceVersion
       
  -----------------------------------------------------------------------------------------

END
GO
