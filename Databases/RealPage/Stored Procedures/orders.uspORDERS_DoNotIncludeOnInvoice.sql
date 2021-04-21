SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_DoNotIncludeOnInvoice]
-- Description     : This procedure deletes the InvoiceItem when the 'Do Not Include On Invoice' check box is checked.
-- Input Parameters: @IPI_OrderItemIDSeq bigint,
--					 @IPVC_ChargeTypeCode varchar(3)
--                   
-- OUTPUT          : 
-- Code Example    : Exec [ORDERS].dbo.[uspORDERS_DoNotIncludeOnInvoice]   @IPI_OrderItemIDSeq  = 177,@IPVC_ChargeTypeCode='acs'
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 12/04/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_DoNotIncludeOnInvoice] 
(
@IPI_OrderItemIDSeq    bigint,
@IPVC_ChargeTypeCode   varchar(3),
@IPVC_OrderGroupIDSeq  bigint,
@IPB_IsCustomPackage   bit
)
AS
BEGIN	
	
if @IPB_IsCustomPackage = 0
  Begin
	   If exists(select 1 from orders.dbo.orderitem (nolock) 
				   where IDSeq=@IPI_OrderItemIDSeq and PrintedOnInvoiceFlag=0 and DoNotInvoiceFlag=1)
		Begin
			Delete from Invoices.dbo.Invoiceitem where OrderItemIDSeq=@IPI_OrderItemIDSeq
		End

	  If (@IPVC_ChargeTypeCode = 'ILF')
	   Begin
		  Update orders..orderitem   
			set LastBillingPeriodFromDate=null,
				LastBillingPeriodToDate=null 
			  --ILFStartDate=null,
			  --ILFEndDate=null
			where IDSeq=@IPI_OrderItemIDSeq
	   End

	  If (@IPVC_ChargeTypeCode = 'ACS')
	   Begin
		  Update orders..orderitem   
		  set LastBillingPeriodFromDate=null,
			  LastBillingPeriodToDate=null 
			--ActivationStartDate=null,
			--ActivationEndDate=null
		  where IDSeq=@IPI_OrderItemIDSeq
	   End
  End
-----------------------------------------------------
if @IPB_IsCustomPackage = 1
  begin
		 if exists(select 1 from orders.dbo.orderitem (nolock) 
			   where OrderGroupIDSeq=@IPVC_OrderGroupIDSeq and PrintedOnInvoiceFlag=0 and DoNotInvoiceFlag=1)
		Begin
			Delete from Invoices.dbo.Invoiceitem where OrderGroupIDSeq =@IPVC_OrderGroupIDSeq
		End

		 If (@IPVC_ChargeTypeCode = 'ILF')
		Begin
			Update orders..orderitem   
			set LastBillingPeriodFromDate=null,
			LastBillingPeriodToDate=null
			where OrderGroupIDSeq=@IPVC_OrderGroupIDSeq
		End

		 If (@IPVC_ChargeTypeCode = 'ACS')
		Begin
			Update orders..orderitem   
			set LastBillingPeriodFromDate=null,
			LastBillingPeriodToDate=null 
			where OrderGroupIDSeq=@IPVC_OrderGroupIDSeq
		End
  end

end


GO
