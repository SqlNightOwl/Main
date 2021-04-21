SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  uspPRODUCTS_GetPriceCapBasis
-- Description     :  This procedure gets the list of Price Cap 
--                    for the specified Company ID.
--
-- Input Parameters: 	
-- 
-- OUTPUT          :  A record set of Code, Name, Description
--
-- Code Example    : Exec Products.DBO.uspPRODUCTS_GetPriceCapBasis
-- 
-- Revision History:
-- Author          : STA, SRA Systems Limited
-- 02/15/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetPriceCapBasis] 
AS
BEGIN
  --------------------------------------------------
  SELECT DISTINCT 
                  Code,
                  [Name] 
  FROM
                  PRODUCTS.dbo.PriceCapBasis (nolock)
END


GO
