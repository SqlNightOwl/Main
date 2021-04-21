SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetSiteOrderDetails]
-- Description     : This procedure gets Order Details pertaining to passed AccountID
-- Input Parameters: 1. @IPI_AccountID   as varchar(20)
--                   2. @IPI_PageNumber  as integer
--                   3. @IPI_RowsPerPage as integer
-- 
-- OUTPUT          : RecordSet of OrderID,Status,CustomerID,CustomerName,AccountID,
--                                AccountName,OrderDate,OrderPeriod,LastInvoice,RowNumber
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetOrderDetails @IPI_AccountID  =1,
--                                                                   @IPI_PageNumber =3,
--                                                                   @IPI_RowsPerPage=20    
-- 
-- 
-- Revision History: Eric Font: @IPI_AccountID parameter must be a VARCHAR instead of an INT
-- Author          : SRA Systems 
-- 11/22/2006      : Stored Procedure Created.
-- 11/28/2006      : Changed by RealPage. Changed as per RPI standards.
-- 11/28/2006      : Changed by STA. The Account ID and the Account Name fields are removed
--                   as they need not be displayed in the account details sub tab page.
-- 12/07/2006      : Changed by STA. To implement the paging functionality of the top 20 records.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetSiteOrderDetails] (
                                                       @IPI_PageNumber    int, 
                                                       @IPI_RowsPerPage   int,
                                                       @IPI_AccountID     varchar(22) 
                                                      )
AS
BEGIN 
SELECT TOP (@IPI_RowsPerPage) * FROM
  (
  SELECT TOP (@IPI_PageNumber * @IPI_RowsPerPage) * from
    (
    SELECT  *, row_number() over(order by OrderDate desc) as RowNumber from
      (
                      select 

                    prod.DisplayName as ProductName,
                    ostype.Name as Status,
                    convert(numeric(10,2),invo.ILFChargeAmount) as ILF,
                    convert(numeric(10,2),invo.AccessChargeAmount) as Access,  
                    convert(varchar(10),ord.CreatedDate,101) as OrderDate,
                    (select convert(varchar(50),min(ILFStartDate),101)
                                      + ' ' + '-' + ' ' +
                                      convert(varchar(50),max(ILFEndDate),101)  
                                      from Orders..OrderItem  where  OrderIDseq = ord.OrderIDSeq)    as OrderPeriod
                   
              from Orders.dbo.[orderitem] oitem with (nolock)

              inner join Orders.dbo.[order] ord with (nolock)

              on oitem.OrderIDSeq = ord.OrderIDSeq

              left outer join Invoices.dbo.Invoice invo with (nolock)

              on ord.AccountIDSeq = invo.AccountIDSeq

              and ord.CompanyIDSeq = invo.CompanyIDSeq

              and ord.PropertyIDSeq = invo.PropertyIDSeq

              inner join Orders.dbo.OrderStatusType ostype with (nolock)

              on ostype.Code = ord.StatusCode

              left outer join Products.dbo.Product prod with (nolock)

              on prod.Code = oitem.ProductCode
              and prod.PriceVersion = oitem.PriceVersion

              where invo.PropertyIDSeq is not null

              and ord.AccountIDSeq = @IPI_AccountID

      ) LT_OrderList

    ) LT_ListOfOrders
    
  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage 

    and RowNumber <= (@IPI_PageNumber) * @IPI_RowsPerPage
  )

AS RecordTable
  ----------------------------------------------------------------------------

              select 

                    count(*)
                   
              from Orders.dbo.[orderitem] oitem with (nolock)

              inner join Orders.dbo.[order] ord with (nolock)

              on oitem.OrderIDSeq = ord.OrderIDSeq

              left outer join Invoices.dbo.Invoice invo with (nolock)

              on ord.AccountIDSeq = invo.AccountIDSeq

              and ord.CompanyIDSeq = invo.CompanyIDSeq

              and ord.PropertyIDSeq = invo.PropertyIDSeq

              inner join Orders.dbo.OrderStatusType ostype with (nolock)

              on ostype.Code = ord.StatusCode

              left outer join Products.dbo.Product prod with (nolock)

              on prod.Code = oitem.ProductCode
              and prod.PriceVersion = oitem.PriceVersion

              where invo.PropertyIDSeq is not null

              and ord.AccountIDSeq = @IPI_AccountID

END

GO
