SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_GetOrderItemNote
-- Description     : This procedure gets Applicable OrderItem Note
-- Syntax          : 
/*
EXEC ORDERS.dbo.uspORDERS_GetOrderItemNote  @IPVC_OrderIDSeq='O0902001183',@IPBI_OrderItemIDSeq=222376,@IPBI_OrderItemTransactionIDSeq = 21093
EXEC ORDERS.dbo.uspORDERS_GetOrderItemNote  @IPVC_OrderIDSeq='O0901010303',@IPBI_OrderItemIDSeq=35833

*/
-- Revision History:
-- Author          : SRS
-- 02/14/2010      : SRS (Defect 7915) Multiple Billing Address enhancement. SP Created.
-----------------------------------------------------------------------------------------------------------------------------
Create PROCEDURE [orders].[uspORDERS_GetOrderItemNote] (@IPVC_OrderIDSeq                 varchar(50),   --> This is the OrderIDSeq
                                                     @IPBI_OrderItemIDSeq             bigint,        --> This is OrderItemIDSeq
                                                     @IPBI_OrderItemTransactionIDSeq  bigint=0       --> This is OrderItemTransactionIDSeq
                                                    )
as
BEGIN
  set nocount on;
  ------------------------------------------
  if (@IPBI_OrderItemTransactionIDSeq=0 or @IPBI_OrderItemTransactionIDSeq is null)
  begin
    --Get all Orderitem Notes Pertaining to Main Orderitem
    select OIN.Description         as [description],
           OIN.mandatoryflag       as mandatoryflag,
           OIN.printoninvoiceflag  as printoninvoiceflag
    from   ORDERS.dbo.OrderitemNote OIN with (nolock)
    where  OIN.OrderIDSeq      = @IPVC_OrderIDSeq
    and    OIN.OrderItemIDSeq  = @IPBI_OrderItemIDSeq
    and    OIN.OrderItemTransactionIDSeq is null
    order by OIN.SortSeq asc,OIN.mandatoryflag asc,OIN.printoninvoiceflag asc
  end
  else
  begin
    ---Get  all Orderitem Notes Pertaining to  Orderitem Transaction
    select OIN.Description         as [description],
           OIN.mandatoryflag       as mandatoryflag,
           OIN.printoninvoiceflag  as printoninvoiceflag
    from   ORDERS.dbo.OrderitemNote OIN with (nolock)
    where  OIN.OrderIDSeq      = @IPVC_OrderIDSeq
    and    OIN.OrderItemIDSeq  = @IPBI_OrderItemIDSeq
    and    OIN.OrderItemTransactionIDSeq = @IPBI_OrderItemTransactionIDSeq
    order by OIN.SortSeq asc,OIN.mandatoryflag asc,OIN.printoninvoiceflag asc
 end
END
GO
