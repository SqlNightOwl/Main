SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_TransactionalProductUpdate]
-- Description     : This procedure updates the transaction Information.
-- Input Parameters:  @IPBI_OrderItemID      bigint,
--					  @IPD_Date              datetime, 
--					  @IPM_Cost              money, 
--					  @IPVC_TransactionItemName varchar(70), 
--					  @IPB_TransactionalFlag bit,
--					  @IPI_TransactionIDSeq  bigint
--                   
-- OUTPUT          : 
-- Code Example    : Exec [ORDERS].dbo.[uspORDERS_TransactionalProductUpdate]   @IPI_OrderItemIDSeq  = 177,@IPVC_ChargeTypeCode='acs'
--                                                             
-- Revision History:
-- Author          : Anand Chakravarthy
-- 01/02/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_TransactionalProductUpdate](
                                                              @IPBI_OrderItemID      bigint,
                                                              @IPD_Date              datetime, 
                                                              @IPM_Cost              money, 
                                                              @IPVC_TransactionItemName varchar(500), 
                                                              @IPI_TransactionIDSeq  bigint,
                                                              @IPBI_Quantity         int = 1,
                                                              @IPI_UserIDSeq         bigint  -->User ID of User Manually updating the transaction.UI knows this.
                                                             )  																
AS
BEGIN
  SET NOCOUNT ON;
  ----------------------------------------
  declare @LDT_SystemDate     datetime;

  select @LDT_SystemDate = getdate();
  
  Update ORDERS.dbo.OrderItemTransaction  WITH (ROWLOCK)
  Set    OrderItemIDSeq      = @IPBI_OrderItemID,
         ServiceDate         = @IPD_Date,
         TransactionalFlag   = 1,
         TransactionItemName = SUBSTRING(@IPVC_TransactionItemName,1,300),
         ExtChargeAmount     = convert(numeric(30,4),(@IPM_Cost)/(case when @IPBI_Quantity = 0 then 1 else @IPBI_Quantity end)),
         NetChargeAmount     = @IPM_Cost,
         Quantity            = @IPBI_Quantity,
         ModifiedByIDSeq     = @IPI_UserIDSeq,
         ModifiedDate        = @LDT_SystemDate,
         SystemLogDate       = @LDT_SystemDate 
   Where IDSeq=@IPI_TransactionIDSeq
END  
GO
