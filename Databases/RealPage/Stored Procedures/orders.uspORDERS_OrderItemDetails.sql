SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_OrderItemDetails
-- Description     : This procedure gets Order Item Details pertaining to passed Order Id,
--                                  Charge Type   
-- Input Parameters: @IPBI_ORDERID bigint,
--                   @IPC_CHARGETYPE char(3)

-- OUTPUT          : RecordSet of ProductName,PricedBy,Quantity,ListPrice,Discount,
--                                NetPrice,TaxAmount,GrossAmount,StatusCode,ILFStartDate,
--                                ILFEndDate
-- Code Example    : Exec ORDERS.DBO.uspORDERS_OrderItemDetails   @IPBI_ORDERID = 2,
--                                                                @IPC_CHARGETYPE 'ILF'   
-- 
-- 
-- Revision History:
-- Author          : KISHORE KUMAR A S 
-- 11/25/2006      : Stored Procedure Created.
-- 11/28/2006      : Changed by KISHORE KUMAR A S. Changed Variable Names.
-- 11/26/2006      : Changed by XYZZYX. Tuned for Performance.
-- 
------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_OrderItemDetails] (@IPBI_ORDERID   varchar(50),
                                                     @IPC_CHARGETYPE char(3)
                                                    )  																
AS
BEGIN-- Main BEGIN starts at Col 01
  --Rest of the code starts at Col 03
  
  ----------------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------------
  select 
          pro.DisplayName                                                                      as ProductName, 
          oItem.MeasureCode                                                                    as PricedBy, 
          oItem.Quantity                                                                       as Quantity, 
          oItem.NetChargeAmount                                                                as ListPrice,
          ((oItem.DiscountPercent * oItem.NetChargeAmount)/100)                                as Discount,
          (oItem.NetChargeAmount - ((oItem.DiscountPercent * oItem.NetChargeAmount)/100))      as NetPrice,
          '0'                                                                                  as TaxAmount, 
          (oItem.NetChargeAmount - ((oItem.DiscountPercent * oItem.NetChargeAmount)/100))      as GrossAmount,
          osType.Name                                                                          as StatusCode,
          isnull(convert(varchar(12),convert(varchar(12),oItem.ILFStartDate,101)),'N/A')       as ILFStartDate,
          isnull(convert(varchar(12),convert(varchar(12),oItem.ILFEndDate,101)),'N/A')         as ILFEndDate
  from Orders.dbo.OrderItem oItem with (nolock)
  left outer join 
             Products.dbo.Product          pro with (nolock)
  ON         oItem.ProductCode             =    pro.Code
  and        oItem.PriceVersion            =    pro.PriceVersion
  and        oItem.ChargeTypeCode          =    @IPC_CHARGETYPE
  and        oItem.OrderIDSeq              =    @IPBI_ORDERID
  inner join 
             Orders.dbo.OrderStatusType    osType with (nolock) 
  ON         oItem.StatusCode              =    osType.Code  
  where      oItem.ChargeTypeCode          =    @IPC_CHARGETYPE
  and        oItem.OrderIDSeq              =    @IPBI_ORDERID

END  -- Main END starts at Col 01


GO
