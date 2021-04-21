SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_OrderGroupItemSelect
-- Description     : This procedure gets Order Item Details for the specifed Order Group ID Sequence
-- Input Parameters: 1. @IPVC_OrderID   as varchar(10)
--                   2. @IPI_PageNumber as integer 
--                   3. @IPI_RowsPerPage      int 
--                   
-- OUTPUT          : RecordSet of OrderIDSeq, MeasureCode, PricedBy, Quantity, ChargeAmount,
--                   DiscountAmount, NetChargeAmount, StatusCode, StartDate, EndDate,
--                   from Orders.dbo.[OrderItem]
--                   RecordSet of Name from Products.dbo.[Product]  
--
-- Code Example    : Exec ORDERS.DBO.uspORDERS_OrderGroupItemSelect @IPVC_OrderGroupIDSeq =3,
--                                                                  @IPI_PageNumber = 1,
--                                                                  @IPI_RowsPerPage = 10
-- 
-- 
-- Revision History:
-- Author          : STA
-- 10/04/2006      : Stored Procedure Created.
--
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_OrderGroupItemSelect] (@IPVC_OrderGroupIDSeq varchar(50),
                                                         @IPI_PageNumber       int, 
                                                         @IPI_RowsPerPage      int 
                                                         )
AS
BEGIN
  -----------------------------------------------------------------------
  SELECT * FROM (
    select top (@IPI_PageNumber * @IPI_RowsPerPage)
           o.OrderIDSeq                              as OrderIDSeq,
           o.OrderGroupIDSeq                         as OrderGroupIDSeq,
           p.Code                                    as ProductCode,
           o.ChargeTypeCode                          as ChargeTypeCode,
           o.FrequencyCode                           as FrequencyCode,
           o.MeasureCode                             as MeasureCode,
 
           p.Name                                    as [Name],
           o.MeasureCode                             as PricedBy,
           o.Quantity                                as Quantity,
           o.ChargeAmount                            as ListPrice,
           o.DiscountAmount                          as Discount,
           o.NetChargeAmount                         as NetPrice,
           ost.Name                                  as Status,
           convert(varchar(11),o.ILFStartDate,101)   as StartDate,
           convert(varchar(11),o.ILFEndDate,101)     as EndDate,
           pt.Name                                   as ProductType,           
           row_number() over(order by o.OrderIDSeq)  as RowNumber,
           (case when  o.FamilyCode = 'SBL' then 1
                  else 0 
            end)                                     as PreConfiguredBundleFlag
    from   Orders.dbo.[OrderItem] o (nolock)

    inner join 
         Products.dbo.[Product] p (nolock)
    on     
         p.Code=o.ProductCode 
    and  p.priceversion = o.priceversion    
    and  o.FamilyCode = 'SBL'
    and  o.OrderGroupIDSeq              = @IPVC_OrderGroupIDSeq
    inner join
         Orders.dbo.OrderStatusType ost (nolock)
    on
         ost.Code = o.StatusCode

    inner join
       Products.dbo.ProductType pt (nolock)
    on
       pt.Code = p.ProductTypeCode

    where  
       o.OrderGroupIDSeq              = @IPVC_OrderGroupIDSeq
     ) LT_Table  
  WHERE 
       RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage 
  -----------------------------------------------------------------------
  SELECT COUNT(*) FROM Orders.dbo.[OrderItem] o (nolock)

  INNER JOIN Products.dbo.[Product]        p (nolock)
  ON         p.Code                      = o.ProductCode 
  and        p.priceversion              = o.priceversion  
  and        o.FamilyCode = 'SBL'
  and        o.OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
  INNER JOIN Orders.dbo.OrderStatusType    ost (nolock)
  ON         ost.Code                    = o.StatusCode

  INNER JOIN Products.dbo.ProductType      pt (nolock)
  ON         pt.Code                     = p.ProductTypeCode
  WHERE      o.OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
  -----------------------------------------------------------------------
END

GO
