SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_InvoiceAllOrders
-- Description     : Invoices are the orders within the billing target date
--                   
-- OUTPUT          : None
--                   
-- Code Example    : exec QUOTES.dbo.uspINVOICES_InvoiceAllOrders
----------------------------------------------------------------------------------------------------
-- exec uspINVOICES_InvoiceAllOrders
CREATE PROCEDURE [invoices].[uspINVOICES_InvoiceAllOrders]  
AS
BEGIN
  set nocount on 

  declare @LDT_TargetDate datetime
  set @LDT_TargetDate = dateadd(day, 45, getdate())

  create table #TEMPInvoiceOrders (
    IDSeq bigint identity(1,1),
    OrderIDSeq varchar(22),
    AccountIDSeq varchar(20),
    CompanyIDSeq varchar(20),
    PropertyIDSeq varchar(20))

  -- Get all the active orders ready for billing
  insert into #TEMPInvoiceOrders (OrderIDSeq, AccountIDSeq, CompanyIDSeq, PropertyIDSeq)
  select distinct o.OrderIDSeq, o.AccountIDSeq, o.CompanyIDSeq, o.PropertyIDSeq
  from Orders.dbo.[Order] o with (nolock)
  inner join Orders.dbo.OrderItem oi with (nolock)
  on    o.OrderIDSeq = oi.OrderIDSeq
  where oi.LastBillingPeriodToDate < @LDT_TargetDate
  and oi.StatusCode = 'FULF'
  and oi.ActivationEndDate  > @LDT_TargetDate

  declare @MIN bigint, @MAX bigint
  declare @LVC_OrderIDSeq varchar(22), @LVC_AccountIDSeq varchar(20), @LVC_CompanyIDSeq varchar(20),
    @LVC_PropertyIDSeq varchar(20)

  select @MIN = 1, @MAX = count(*) from #TEMPInvoiceOrders

  while @MIN <= @MAX
  begin
    begin try
      select  @LVC_OrderIDSeq = OrderIDSeq, 
              @LVC_AccountIDSeq = AccountIDSeq, 
              @LVC_CompanyIDSeq = CompanyIDSeq, 
              @LVC_PropertyIDSeq = PropertyIDSeq
      from #TEMPInvoiceOrders with (nolock)
      where IDSeq = @MIN

      exec INVOICES.[dbo].[uspINVOICES_CreateRecurringInvoice] 
                  @IPVC_AccountID = @LVC_AccountIDSeq,
                  @IPVC_CompanyID = @LVC_CompanyIDSeq,
                  @IPVC_PropertyID = @LVC_PropertyIDSeq,
                  @LDT_TargetDate = @LDT_TargetDate,     
                  @LVC_Event = 'CreateRecurringInvoice', 
	                @IPVC_OrderID = @LVC_OrderIDSeq 
    end TRY
    begin CATCH
      print 'FAILED: Account: ' + @LVC_AccountIDSeq + ' @LVC_CompanyIDSeq:' + @LVC_CompanyIDSeq + 
        ' @LVC_PropertyIDSeq:' + @LVC_PropertyIDSeq + 
        ' @LDT_TargetDate:' + convert(varchar(10), @LDT_TargetDate, 101) + 
        ' @LVC_OrderIDSeq:' + @LVC_OrderIDSeq
    end CATCH

    set @MIN = @MIN + 1
  end

  --select * from #TEMPInvoiceOrders
  drop table #TEMPInvoiceOrders
end
GO
