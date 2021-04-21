SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  uspCUSTOMERS_TransferSetCancel
-- Revision History:
-- Author          : DCannon
-- 6/14/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_TransferSetCancel] 
                  @IPC_FromCompanyIDSeq          Varchar(50),
                  @IPC_FromPropertyIDSeq         Varchar(50),
                  @IPC_ToCompanyIDSeq            Varchar(50)='',
                  @IPC_ToPropertyIDSeq           Varchar(50)='',
                  @IPVC_QuoteIDSeq               varchar(50)=''                  

AS
BEGIN
  set nocount on
  ---------------------------------------------------------------------------------------
  --Step 1: Update the Status from 'TRNSP' back to Active for @IPC_FromPropertyIDSeq
  --All null out TransferPMCIDSeq for @IPC_FromPropertyIDSeq
  Update CUSTOMERS.dbo.Property 
  set    TransferPMCIDSeq = NULL,
         StatusTypeCode   = 'ACTIV' 
  where  IDSeq = @IPC_FromPropertyIDSeq

  ----------------------------------------------------
  --Step 2: Update Statuses back to Original Orders and Orderitem 
  --        pertaining to @IPC_FromCompanyIDSeq and @IPC_FromPropertyIDSeq
  update D
  set    D.StatusCode = S.FromOrderStatusCode
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
  set    D.StatusCode = S.FromOrderItemStatusCode
  from   Orders.dbo.[OrderItem] D with (nolock)
  inner join
         ORDERS.dbo.SiteTransferOrderLog S with (nolock)
  on     D.OrderIDSeq        = S.FromOrderIDSeq
  and    D.IDSeq             = S.FromOrderItemIDSeq
  and    S.FromCompanyIDSeq  = @IPC_FromCompanyIDSeq
  and    S.FromPropertyIDSeq = @IPC_FromPropertyIDSeq
  and    S.ToQuoteIDSeq      = @IPVC_QuoteIDSeq  
  ---------------------------------------------------------------------------
  ---Step3 : Delete the newly reverse generated Quote for new property @IPC_ToPropertyIDSeq
  if (@IPVC_QuoteIDSeq is not null and @IPVC_QuoteIDSeq <> '')
  begin
    Exec Quotes.dbo.uspQUOTES_DeleteQuote @IPVC_CompanyID = @IPC_ToCompanyIDSeq,
                                          @IPVC_QuoteID   = @IPVC_QuoteIDSeq
  end
  ---------------------------------------------------------------------------
  --Step4: Delete all Customer Data related to newly generated @IPC_ToPropertyIDSeq
  Delete from CUSTOMERS.dbo.Address 
  where  CompanyIDSeq  = @IPC_ToCompanyIDSeq
  and    PropertyIDSeq = @IPC_ToPropertyIDSeq
  and    PropertyIDSeq is not null
  
  Delete from CUSTOMERS.dbo.Contact 
  where  CompanyIDSeq  = @IPC_ToCompanyIDSeq
  and    PropertyIDSeq = @IPC_ToPropertyIDSeq
  and    PropertyIDSeq is not null

  Delete from CUSTOMERS.dbo.Property
  where  IDSeq = @IPC_ToPropertyIDSeq
  and    IDSeq is not null
  ---------------------------------------------------------------------------
  --Step 5: Get rid of Orphan Records from SiteTransferLog for cancelled 
  --        Site transfer process for @IPC_ToCompanyIDSeq and @IPC_ToPropertyIDSeq
  --        and newly generated QuoteID @IPVC_QuoteIDSeq
  Delete from CUSTOMERS.dbo.SiteTransferLog 
  where  FromCompanyIDSeq  = @IPC_FromCompanyIDSeq
  and    FromPropertyIDSeq = @IPC_FromPropertyIDSeq
  and    ToCompanyIDSeq    = @IPC_ToCompanyIDSeq
  and    ToPropertyIDSeq   = @IPC_ToPropertyIDSeq
  and    QuoteIDSeq        = @IPVC_QuoteIDSeq  
  ---------------------------------------------------------------------------
  --Step 6: Get rid of Orphan Records from ORDERS.dbo.SiteTransferOrderLog for cancelled 
  --        Site transfer process for @IPC_ToCompanyIDSeq and @IPC_ToPropertyIDSeq
  --        and newly generated QuoteID @IPVC_QuoteIDSeq
  Delete from ORDERS.dbo.SiteTransferOrderLog
  where  FromCompanyIDSeq  = @IPC_FromCompanyIDSeq
  and    FromPropertyIDSeq = @IPC_FromPropertyIDSeq
  and    ToCompanyIDSeq    = @IPC_ToCompanyIDSeq
  and    ToPropertyIDSeq   = @IPC_ToPropertyIDSeq
  and    FromQuoteIDSeq    = @IPVC_QuoteIDSeq
  ---------------------------------------------------------------------------
END
GO
