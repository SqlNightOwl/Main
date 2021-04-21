SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_InvoiceOrderCount]
-- Description     : Returns the number of orders ready to be invoiced
-- INPUT           : @LDT_BillingPeriod datetime
--                   
-- OUTPUT          : The order count, target date, and number of unprinted invoices
--                   
-- Code Example    : exec QUOTES.dbo.[uspINVOICES_InvoiceOrderCount]
----------------------------------------------------------------------------------------------------
-- exec [uspINVOICES_InvoiceOrderCount] '12/1/2007'
CREATE PROCEDURE [invoices].[uspINVOICES_InvoiceOrderCount] @LDT_BillingPeriod datetime
AS
BEGIN
  set nocount on 
  declare @LDT_TargetDate datetime
  set @LDT_TargetDate = dateadd(day, 45, @LDT_BillingPeriod)
  declare @LN_OrderCount int, @LN_UnprintedInvoices int

  -- Get all the active products ready for billing
  select @LN_OrderCount = count(distinct o.OrderIDSeq)
  from Orders.dbo.[Order] o with (nolock)
  inner join Orders.dbo.OrderItem oi with (nolock)
  on    o.OrderIDSeq = oi.OrderIDSeq
  where oi.LastBillingPeriodToDate < @LDT_TargetDate
  and   oi.StatusCode = 'FULF'
  and   oi.ActivationEndDate  > @LDT_TargetDate

  -- Get all the invoices that have not been printed
  select @LN_UnprintedInvoices = count(*)
  from Invoices.dbo.Invoice with (nolock)
  where PrintFlag = 0

  select @LN_OrderCount as OrderCount, @LN_UnprintedInvoices as UnprintedInvoices,
    convert(varchar(10), @LDT_TargetDate, 101) as TargetDate
  
end
GO
