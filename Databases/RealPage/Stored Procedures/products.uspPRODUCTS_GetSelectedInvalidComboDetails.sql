SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_GetSelectedInvalidComboDetails
-- Description     : This procedure gets Code,Name
--                   StartDate,EndDate from product table and Secondproductcode from ProductInvalidCombo
--                   pertaining to passed  ProductCode and PriceVersion.
-- Input Parameters: @IPC_ProductCode       as    char,
--                   @IPN_PriceVersion      as    numeric
-- OUTPUT          : RecordSet of Code,Name,ItemCode,Displayname,Description,OptionFlag,SOCFlag,
--                   DisabledFlag,StartDate,EndDate,CreatedBy,ModifiedBy,CreatedDate,ModifyDate,PriceCapEnabledFlag,
--                   PendingApprovalFlag,Category,Family,[Platform],ProductType,RowNumber
-- Code Example    : exec [dbo].[uspPRODUCTS_GetSelectedInvalidComboDetails] 'PRM-LEG-LEG-LEG-LAAP',101 
-- Author          : Naval Kishore Singh 
-- 12/06/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetSelectedInvalidComboDetails]
                                                   (
                                                    @IPC_ProductCode char(30),
                                                    @IPN_PriceVersion numeric(18,0)
                                                    )					
AS
BEGIN
--------------------------------------------------------------------------------------------------
--Product Details 
--------------------------------------------------------------------------------------------------
  SELECT 
      P.Code                                 as ProductCode,
      P.PriceVersion                         as PriceVersion,
      P.[Name]                               as ProductName,
      convert(varchar (15),P.StartDate,101)  as StartDate,
      convert(varchar (15),P.EndDate,101)    as EndDate
     
    FROM Products.dbo.Product P with (nolock)
    
    WHERE P.Code = @IPC_ProductCode AND P.PriceVersion=@IPN_PriceVersion

--------------------------------------------------------------------------------------------------
--ProductInvalidCombo
--------------------------------------------------------------------------------------------------
  
SELECT  P.[Name]                               as SecondProductName,
        PIC.SecondProductCode                  as SecondProductCode
                  
    FROM Products.dbo.ProductInvalidCombo PIC with (nolock)

    INNER JOIN Products.dbo.Product P with (nolock)
      ON  P.Code = PIC.SecondProductCode
      
    WHERE PIC.FirstProductCode = @IPC_ProductCode 
    AND PIC.FirstProductPriceVersion=@IPN_PriceVersion

--------------------------------------------------------------------------------------------------

END
GO
