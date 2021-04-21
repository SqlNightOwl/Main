SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_GetOrdersForProperty]
-- Description     : This procedure gets Order Details pertaining to passed 
--                        CustomerName,City,State,ZipCode,PropertyID and StatusType
-- Input Parameters:   @IPVC_PropertyID
-- OUTPUT          : RecordSet of OrderIDS
-- Code Example    : exec Customers.dbo.[uspCUSTOMERS_GetOrdersForProperty] 'P0901025992' 
-- Revision History:
-- Author          : Naval kishore
-- 03/25/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_GetOrdersForProperty] (@IPVC_PropertyID as varchar(20))


AS
BEGIN
  select O.OrderIDSeq   as OrderIDSeq
  from   Orders.dbo.[Order] O with (nolock)
  inner join
         Orders.dbo.[Orderitem] OI with (nolock)
  on     O.Orderidseq   = OI.Orderidseq
  and    O.propertyidseq= @IPVC_PropertyID
  and    OI.statuscode in ('FULF','PENR')
  group by O.OrderIDSeq
  Order by O.OrderIDSeq asc
END
GO
