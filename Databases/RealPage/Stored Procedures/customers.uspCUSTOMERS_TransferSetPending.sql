SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  uspCUSTOMERS_TransferSetPending
-- Revision History:
-- Author          : DCannon
-- 6/14/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_TransferSetPending] 
                  (@IPC_FromCompanyIDSeq          varchar(50),
                  @IPC_FromPropertyIDSeq         varchar(50),
                  @IPC_ToCompanyIDSeq            varchar(50),
                  @IPC_ToPropertyIDSeq           varchar(50),
                  @IPVC_QuoteIDSeq               varchar(50),
                  @IPDT_OrderActivationStartDate  datetime, 
                  @IPN_CreatedByIDSeq            bigint)

AS
BEGIN
   if(@IPDT_OrderActivationStartDate is null or @IPDT_OrderActivationStartDate='')
    set @IPDT_OrderActivationStartDate = getdate()
  ----------------------------------------------------
  --Set Order status for @IPC_FromPropertyIDSeq
  update D
  set    D.StatusCode = 'TRNSP'
  from   Orders.dbo.[Order] D with (nolock)
  inner join
         ORDERS.dbo.SiteTransferOrderLog S with (nolock)
  on     D.OrderIDSeq        = S.FromOrderIDSeq 
  and    S.FromCompanyIDSeq  = @IPC_FromCompanyIDSeq
  and    S.FromPropertyIDSeq = @IPC_FromPropertyIDSeq
  and    S.ToQuoteIDSeq      = @IPVC_QuoteIDSeq
  ----------------------------------------------------
  --Set Orderitem status for @IPC_FromPropertyIDSeq
  update D
  set    D.StatusCode = 'TRNSP'
  from   Orders.dbo.[OrderItem] D with (nolock)
  inner join
         ORDERS.dbo.SiteTransferOrderLog S with (nolock)
  on     D.OrderIDSeq        = S.FromOrderIDSeq
  and    D.IDSeq             = S.FromOrderItemIDSeq
  and    S.FromCompanyIDSeq  = @IPC_FromCompanyIDSeq
  and    S.FromPropertyIDSeq = @IPC_FromPropertyIDSeq
  and    S.ToQuoteIDSeq      = @IPVC_QuoteIDSeq  
  ----------------------------------------------------
  --Update Quote for new @IPVC_QuoteIDSeq
  update Quotes.dbo.Quote
  set    OrderActivationStartDate = @IPDT_OrderActivationStartDate,
         CreatedByIDSeq           = @IPN_CreatedByIDSeq,
         ModifiedByIDSeq          = @IPN_CreatedByIDSeq,
         TransferredFlag          = 1
  where  QuoteIDSeq = @IPVC_QuoteIDSeq
  ----------------------------------------------------  
  --Insert into Site transfer Log
  insert into CUSTOMERS.dbo.SiteTransferLog 
         (Status, FromCompanyIDSeq, FromPropertyIDSeq, ToCompanyIDSeq, ToPropertyIDSeq,
          QuoteIDSeq, OrderActivationStartDate, CreatedByIDSeq)
  values ('PENDING', @IPC_FromCompanyIDSeq, @IPC_FromPropertyIDSeq, @IPC_ToCompanyIDSeq, @IPC_ToPropertyIDSeq,
          @IPVC_QuoteIDSeq, @IPDT_OrderActivationStartDate, @IPN_CreatedByIDSeq)
  ----------------------------------------------------
  --Update Status to TRNSP for @IPC_FromPropertyIDSeq
  update Customers.dbo.Property
  set TransferPMCIDSeq   = @IPC_ToCompanyIDSeq,
      StatusTypeCode     = 'TRNSP' 
  where IDSeq            = @IPC_FromPropertyIDSeq
  ----------------------------------------------------
  --Update Status to TRNSP for @IPC_ToPropertyIDSeq
  update Customers.dbo.Property
  set StatusTypeCode = 'TRNSP' 
  where IDSeq        = @IPC_ToPropertyIDSeq
  ----------------------------------------------------
END

GO
