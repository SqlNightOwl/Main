SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_GetProductHistory]
-- Description     : This procedure gets ChargeID,MeasureCode,Frequency,RevRecognition,DefRevAcctCode,
--                   TaxwareCode,MinUnits,MaxUnits,StartDate,EndDate,RowNumber pertaining to passed 
--                   ProductCode,priceversion,chargetypecode
-- Input Parameters: @IPC_ProductCode       as    char
--                   @IPN_PriceVersion      as    numeric
--                   @IPC_ChargeTypeCode    as    char
-- OUTPUT          : ChargeID,MeasureCode,Frequency,RevRecognition,DefRevAcctCode,
--                   TaxwareCode,MinUnits,MaxUnits,StartDate,EndDate,RowNumber
-- Code Example    : exec [dbo].[uspPRODUCTS_GetProductHistory] 'DMD-SBL-CNV-CNV-CSCV',100,'',1,20 
-- Author          : Naval Kishore Singh 
-- 06/07/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetProductHistory]
                                                    @IPC_ProductCode	CHAR(30),
                                                    @IPI_PageNumber		INT, 
                                                    @IPI_RowsPerPage	INT
                                                    					
AS
BEGIN
-----------------------------------------------------------------------------------------
  SELECT * FROM (
    ---------------------------------------------------------------------------------
    SELECT TOP  (@IPI_RowsPerPage * @IPI_PageNumber)   
  
      P.Code                                 as ProductCode,  
      P.PriceVersion                         as PriceVersion, 
      P.ModifiedBy							 as Modifiedby, 
      --convert(varchar(12),P.createdate,101)   as StartDate,  
      convert(VARCHAR(12),P.modifydate,101)     as Modifydate,    
      row_number() OVER(ORDER BY P.[Name])   as RowNumber  
  
       
    FROM Products.dbo.Product P with (nolock)  
  
--    INNER JOIN Products.dbo.Family F with (nolock)  
--      ON  P.FamilyCode = F.Code  
--      and P.DisabledFlag = 0  
--    INNER JOIN Products.dbo.ProductType PT with (nolock)  
--      ON P.ProductTypeCode = PT.Code  
--  
--    INNER JOIN Products.dbo.Category C with (nolock)  
--      ON P.CategoryCode = C.Code  
--  
--    INNER JOIN Products.dbo.[Platform] PF with (nolock)  
--      ON P.PlatformCode = PF.Code  
  
     WHERE P.Code = @IPC_ProductCode  ORDER BY P.PriceVersion DESC ) tbl
 ---------------------------------------------------------------------------------

  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage

  -----------------------------------------------------------------------------------------

  -----------------------------------------------------------------------------------------
  SELECT      COUNT(*) 
  FROM Products.dbo.Product P with (nolock)

    INNER JOIN Products.dbo.Family F with (nolock)
      ON  P.FamilyCode = F.Code
      and P.DisabledFlag = 0
    INNER JOIN Products.dbo.ProductType PT with (nolock)
      ON P.ProductTypeCode = PT.Code

    INNER JOIN Products.dbo.Category C with (nolock)
      ON P.CategoryCode = C.Code

    INNER JOIN Products.dbo.[Platform] PF with (nolock)
      ON P.PlatformCode = PF.Code

	    WHERE P.Code = @IPC_ProductCode
  -----------------------------------------------------------------------------------------

END
GO
