SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_TransactionalList]
-- Description     : Lists all transactions
-- Syntax          : EXEC ORDERS.dbo.uspORDERS_TransactionalList @IPVC_OrderIDSeq = 'O0908001437',@IPI_PageNumber=1,@IPI_RowsPerPage=11
--                   EXEC ORDERS.dbo.uspORDERS_TransactionalList @IPVC_OrderIDSeq = 'O0901069605',@IPI_PageNumber=1,@IPI_RowsPerPage=11
------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_TransactionalList] (@IPVC_OrderIDSeq       varchar(50),
                                                      @IPI_PageNumber        bigint, --> page number. Starting with 1
                                                      @IPI_RowsPerPage       bigint  --> Records per page. Default 11						     
                                                     )  																
AS
BEGIN
  set nocount on;
  ----------------------------------------- 
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;  
  ----------------------------------------------------------------
  ;WITH tablefinal AS
         (select P.DisplayName                                            as [Name], 
                 OIT.TransactionItemName                                  as TransactionItemName, 
                 convert(NUMERIC(30,4),OIT.ExtChargeAmount)               as ExtChargeAmount,
                 convert(NUMERIC(30,4),OIT.Discountamount)                as Discount,
                 convert(NUMERIC(30,4),OIT.NetChargeAmount)               as NetChargeAmount,
                 convert(INT,OIT.Quantity)                                as Quantity,
                 (case when (OIT.InvoicedFlag = 1 and OIT.PrintedOnInvoiceFlag = 1)
                         then 'Yes;Printed'
                       when (OIT.InvoicedFlag = 1 and OIT.PrintedOnInvoiceFlag = 0)
                         then 'Yes;Pending Print'
                       when (OIT.InvoicedFlag = 0)
                         then 'No'
                  end)                                                    as Invoiced,
                 convert(varchar(50),OIT.ServiceDate,101)                 as ServiceDate,
                 OIT.ChargeTypeCode                                       as ChargeTypeCode,
                 OIT.OrderItemIDSeq                                       as OrderItemIDSeq,
                 OIT.OrderGroupIDSeq                                      as OrderGroupIDSeq,
                 OIT.IDSeq                                                as TransactionIDSeq,
                 OIT.ImportSource                                         as ImportSource,                 
                 (Case when (OIT.PrintedOnInvoiceFlag = 0) 
                          then 1 
                       else 0   
                 end)                                                     as EditableFlag,
                 row_number() OVER(ORDER BY OIT.PrintedOnInvoiceFlag asc,OIT.InvoicedFlag asc,P.Name asc,OIT.ServiceDate desc)   
                                                                          as [RowNumber],
                 Count(1) OVER()                                          as TotalCountForPaging
          from   Orders.dbo.OrderItemTransaction OIT with (nolock)          
          inner join Products.dbo.Product p with (nolock) 
          on     P.Code         = OIT.ProductCode 
          and    P.PriceVersion = OIT.PriceVersion
          and    OIT.OrderIDSeq = @IPVC_OrderIDSeq
          and    OIT.TransactionalFlag = 1
          where  OIT.OrderIDSeq = @IPVC_OrderIDSeq 
        )
   select tablefinal.[Name],
          tablefinal.TransactionItemName,
          tablefinal.ExtChargeAmount,
          tablefinal.Discount,
          tablefinal.NetChargeAmount,
          tablefinal.Quantity,
          tablefinal.Invoiced,
          tablefinal.ServiceDate,
          tablefinal.ChargeTypeCode,
          tablefinal.OrderItemIDSeq,
          tablefinal.OrderGroupIDSeq,
          tablefinal.TransactionIDSeq,
          tablefinal.ImportSource,
          tablefinal.EditableFlag,
          tablefinal.TotalCountForPaging     
from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
  -----------------------------------------------
END
GO
