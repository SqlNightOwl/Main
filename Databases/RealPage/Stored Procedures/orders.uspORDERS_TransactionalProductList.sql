SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_TransactionalProductList
-- Description     : This procedure Lists all transactional products
-- Input Parameters: @IPBI_ORDERID varchar(20)
-- OUTPUT          :       
--                   
-- Code Example    : Exec ORDERS.DBO.uspORDERS_TransactionalProductList 'O0901081669' 
-- 
-- Revision History:
-- Author          : ShashiBhushan
-- 10/19/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_TransactionalProductList] (@IPBI_ORDERID varchar(20))  																
AS
BEGIN
  set nocount on
  Declare @IPVC_QuoteApprovalDate   datetime
  select @IPVC_QuoteApprovalDate = coalesce(Q.ApprovalDate,O.approveddate)
  from   orders.dbo.[order] O with (nolock) 
  left outer join
         Quotes.dbo.Quote Q with (nolock)
  on     O.Quoteidseq = Q.Quoteidseq
  and    O.orderidseq = @IPBI_ORDERID
  where  O.orderidseq = @IPBI_ORDERID

  select  oi.IDSeq,p.DisplayName,
          convert(varchar(11),@IPVC_QuoteApprovalDate,101) as  QuoteApprovedDate  
  from    Orders.dbo.OrderItem oi (nolock) 
  inner join Products.dbo.Product p (nolock) on p.Code = oi.ProductCode and p.PriceVersion = oi.PriceVersion
  AND   OI.OrderIDSeq = @IPBI_ORDERID and OI.ChargeTypeCode='ACS' and OI.MeasureCode='TRAN' and OI.StatusCode<>'CNCL'
  where OI.OrderIDSeq = @IPBI_ORDERID and OI.ChargeTypeCode='ACS' and OI.MeasureCode='TRAN' and OI.StatusCode<>'CNCL'
	
END
GO
