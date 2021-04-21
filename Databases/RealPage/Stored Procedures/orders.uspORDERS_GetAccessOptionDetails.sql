SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [orders].[uspORDERS_GetAccessOptionDetails] 
(@IPBI_OrderItemIDSeq bigint)
AS
	Declare @LV_ProductCode char(30)
	Select @LV_ProductCode=ProductCode from Orders.dbo.[OrderItem] (nolock) where IDSeq=@IPBI_OrderItemIDSeq
BEGIN
  select * 
  from products..charge 
  where productcode = @LV_ProductCode

  select Quantity,
		 NetChargeAmount as listPrice,
		 DiscountPercent as Discount,
		 NetChargeAmount as NetPrice 
  from Orders.dbo.[OrderItem] 
  where idseq=@IPBI_OrderItemIDSeq
END

GO
