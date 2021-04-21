SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspPRODUCTS_GetProductDetails]
-- Description     : This procedure returns the accounts based on the parameters
-- Input Parameters: 1. @IPVC_ProductCode char(30),
--                   2. @IPN_PriceVersion numeric(18, 0)
-- 
-- OUTPUT          : RecordSet of fields describing the Product.
-- Code Example    : Exec PRODUCTS.dbo.[uspPRODUCTS_GetProductDetails]  @IPVC_ProductCode = '',
--                                                                      @IPN_PriceVersion = 1
-- 
-- 
-- Revision History:
-- Author          : STA 
-- 07/02/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetProductDetails]    (
                                                            @IPVC_ProductCode char(30),
                                                            @IPN_PriceVersion numeric(18, 0)
                                                          )	
AS
BEGIN
  -----------------------------------------------------------
	SELECT  Code                    as ProductCode,
          DisplayName             as DisplayName,
          [Description]           as [Description],
          PlatformCode            as PlatformCode,
          FamilyCode              as FamilyCode,
          CategoryCode            as CategoryCode,
          OptionFlag              as OptionFlag,
          SOCFlag                 as SOCFlag,
          StartDate               as StartDate,
          EndDate                 as EndDate
  FROM    PRODUCTS.dbo.Product
  WHERE   Code                    = @IPVC_ProductCode
    AND   PriceVersion            = @IPN_PriceVersion
  -----------------------------------------------------------
END

GO
