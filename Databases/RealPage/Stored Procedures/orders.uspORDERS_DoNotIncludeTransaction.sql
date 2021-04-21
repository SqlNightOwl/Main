SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_DoNotIncludeTransaction]
-- Description     : This procedure deletes the InvoiceItem when the 'Do Not Include On Invoice' check box is checked.
-- Input Parameters: @IPI_OrderItemIDSeq bigint,
--					 @IPVC_ChargeTypeCode varchar(3)
--                   
-- OUTPUT          : 
-- Code Example    : Exec [ORDERS].dbo.[uspORDERS_DoNotIncludeTransaction]   @IPI_OrderItemIDSeq  = 177,@IPVC_ChargeTypeCode='acs'
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 12/04/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_DoNotIncludeTransaction] 
(
@IPI_OrderItemIDSeq    bigint,
@IPVC_ChargeTypeCode   varchar(3),
@IPVC_OrderGroupIDSeq  bigint,
@IPB_IsCustomPackage   bit,
@IPI_TransactionIDSeq  bigint =NULL
)
AS
BEGIN	
	
if @IPB_IsCustomPackage = 0
  Begin
	   If exists(select 1 from orders.dbo.orderitem (nolock) 
				   where IDSeq=@IPI_OrderItemIDSeq and PrintedOnInvoiceFlag=0)
		Begin
			Delete from Invoices.dbo.Invoiceitem where OrderItemTransactionIDseq=@IPI_TransactionIDSeq
               
--            Update orders.dbo.[orderItemTransaction] 
--            set TransactionalFlag=0, InvoicedFlag=0
--            where IDSeq=@IPI_TransactionIDSeq
		End
  End
end


GO
