SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  uspCUSTOMERS_DeletePriceCap
-- Description     :  This procedure deletes the list of Price Cap 
--                    for the specified Company ID.
--
-- Input Parameters: 	
-- 
-- OUTPUT          :  A record set of Code, Name, Description
--
-- Code Example    : Exec Products.DBO.[uspCUSTOMERS_DeletePriceCap]
-- 
-- Revision History:
-- Author          : STA, SRA Systems Limited
-- 02/15/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_DeletePriceCap] @IPBI_PriceCapIDSeq bigint
AS
BEGIN
  -------------------------------------------------------
  DELETE 
  FROM  
        Customers..PriceCap 
  
  WHERE 
        IDSeq = @IPBI_PriceCapIDSeq
  -------------------------------------------------------
END


--Exec [dbo].[uspCUSTOMERS_DeletePriceCap] 1

GO
