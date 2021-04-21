SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_InvoiceAllOrders
-- Description     : Invoices are the orders within the billing target date
--                   
-- Code Example    : exec INVOICES.dbo.[uspINVOICES_GetOrdersForTransactionsEOMInvoices] @IPDT_TargetDate = '6/21/2008'
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetOrdersForTransactionsEOMInvoices]  (@IPDT_TargetDate datetime = NULL,
                                                                           @IPI_TargetDays  Int = 45
                                                                          )
AS
BEGIN
  set nocount on; 
  set @IPDT_TargetDate = isnull(@IPDT_TargetDate,dateadd(day, @IPI_TargetDays, getdate()))
  -- IF YOU CHANGE THIS VALUE, ALSO CHANGE uspINVOICES_CreateTransactionInvoice

  -- Get all the active orders ready for billing transactions
  select distinct o.OrderIDSeq, o.AccountIDSeq, o.CompanyIDSeq, o.PropertyIDSeq,                  
                  @IPDT_TargetDate as TargetDate
  from   Orders.dbo.[Order] o with (nolock)
  inner join 
        Orders.dbo.OrderItemTransaction oit WITH (NOLOCK) 
  on    o.OrderIDSeq = oit.OrderIDSeq
  and   oit.TransactionalFlag = 1
  and   oit.InvoicedFlag      = 0 
  and   oit.ServiceDate       <= @IPDT_TargetDate
  where o.OrderIDSeq = oit.OrderIDSeq
  and   oit.TransactionalFlag = 1
  and   oit.InvoicedFlag      = 0 
  and   oit.ServiceDate       <= @IPDT_TargetDate
end

GO
