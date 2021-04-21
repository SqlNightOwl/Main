SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_UpdateOrdersRenewal
-- Description     : Updates RenewalTypeCode in OrderItem table based on the parameters passed
-- Input Parameters: @orderItemIDSeq bigint,
--					 @RenewalTypeCode varchar(5)
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.dbo.[uspORDERS_UpdateOrdersRenewal]   @orderItemIDSeq = 177, @RenewalTypeCode='ARNW'
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 10/16/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_UpdateOrdersRenewal] 
(
@orderItemIDSeq bigint,
@RenewalTypeCode varchar(5)
)
AS
BEGIN
		Update Orders..OrderItem
		 Set RenewalTypeCode = @RenewalTypeCode
		Where IDSeq=@orderItemIDSeq
END

GO
