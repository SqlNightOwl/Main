SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_GetRenewalDetails]
-- Description     : Retrieves order Renewal Details.
-- Input Parameters: @OrderItemIDSeq bigint
--                   
-- OUTPUT          : 
-- Code Example    : Exec [ORDERS].dbo.[uspORDERS_GetRenewalDetails]   @OrderItemIDSeq  = 177
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 11/13/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetRenewalDetails] @OrderItemIDSeq bigint
AS
BEGIN
    Select OI.ProductCode as ProductCode,PRD.DisplayName as ProductName,OI.RenewalTypeCode as RenewalType,OI.NetChargeAmount as ChargeAmount
	From Orders..OrderItem OI (nolock)
		Join Products.dbo.Product PRD (nolock) On OI.ProductCode=PRD.Code and OI.PriceVersion=PRD.PriceVersion
	where OI.IDSeq=@OrderItemIDSeq
END


GO
