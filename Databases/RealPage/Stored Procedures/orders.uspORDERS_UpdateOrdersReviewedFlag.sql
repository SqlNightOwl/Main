SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_UpdateOrdersReviewedFlag]
-- Description     : Updates RenewalReviewedFlag in OrderItem table based on the parameters passed
-- Input Parameters: @orderItemIDSeq bigint,
--					
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.dbo.[uspORDERS_UpdateOrdersRenewal]   @orderItemIDSeq = 177, @RenewalTypeCode='ARNW'
--                                                             
-- Revision History:
-- Author          : Naval Kishore Singh
-- 12/14/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_UpdateOrdersReviewedFlag] 

@IPVC_orderItemIDSeq bigint

AS
BEGIN
		Update Orders..OrderItem
		 Set RenewalReviewedFlag = 1
		Where IDSeq=@IPVC_orderItemIDSeq
END

--Exec ORDERS.dbo.[uspORDERS_UpdateOrdersReviewedFlag] 177

GO
