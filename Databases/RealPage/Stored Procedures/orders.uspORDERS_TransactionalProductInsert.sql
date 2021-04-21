SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_TransactionalProductInsert]
-- Description     : Insert a transaction for the specified order.
------------------------------------------------------------------------------------------------------
CREATE procedure [orders].[uspORDERS_TransactionalProductInsert] (@IPBI_OrderItemID bigint,
                                                               @IPD_Date         datetime,
                                                               @IPM_Cost         money,
                                                               @IPVC_TransactionItemName varchar(500),
                                                               @IPBI_Quantity    int = 1,
                                                               @IPI_UserIDSeq    bigint  -->User ID of User Manually Adding the transaction.UI knows this.
                                                              )  																
AS
BEGIN
  SET NOCOUNT ON;
  ----------------------------------------
  declare @LI_OrderItemTransactionIDSeq bigint;
  declare @LDT_SystemDate               datetime;

  select @LDT_SystemDate = getdate();
  ----------------------------------------
  --Validation for Revenue related code and Taxwarecod
  if exists (select top 1 1
             from    Orders.dbo.OrderItem OI   with (nolock)
             inner join
                     Products.dbo.Charge C     with (nolock)
             on      OI.IDSeq         = @IPBI_OrderItemID
             and     OI.ProductCode  = C.ProductCode
             and     OI.PriceVersion = C.PriceVersion
             and     OI.Measurecode  = C.measurecode
             and     OI.Frequencycode= C.Frequencycode 
             and     OI.Chargetypecode=C.Chargetypecode   
             and     OI.IDSeq         = @IPBI_OrderItemID
             and    (
                      (ltrim(rtrim(C.RevenueAccountCode)) is NULL or ltrim(rtrim(C.RevenueAccountCode)) = '') --> Mandatory   
                        OR
                      (ltrim(rtrim(C.RevenueTierCode)) is NULL or ltrim(rtrim(C.RevenueTierCode)) = '') --> Mandatory          
                        OR
                      (ltrim(rtrim(C.TaxwareCode)) is NULL or ltrim(rtrim(C.TaxwareCode)) = '') --> Mandatory                                    
                        OR  
                      (C.RevenueRecognitionCode in ('SRR','MRR') and (ltrim(rtrim(C.DeferredRevenueAccountCode)) is null or ltrim(rtrim(C.DeferredRevenueAccountCode)) = '')
                      ) --> DeferredRevenueAccountCode is Mandatory for RevenueRecognitionCode SRR,MRR
                    )
             where OI.IDSeq         = @IPBI_OrderItemID
             )
  begin
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspORDERS_TransactionalProductInsert. This Transactional product requires Revenue and/or Taxware code to be configured.'
    return
  end
  ----------------------------------------
  begin TRY
    BEGIN TRANSACTION OIT; 
      insert into OrderItemTransaction (OrderItemIDSeq, OrderIDSeq, OrderGroupIDSeq, ProductCode,PriceVersion,
                                        ChargeTypeCode, FrequencyCode, MeasureCode, ServiceCode, TransactionItemName,
                                        ExtChargeAmount, DiscountAmount, NetChargeAmount,Quantity,TransactionalFlag,
                                        InvoicedFlag, ServiceDate,
                                         CreatedByIDSeq,CreatedDate,ImportSource,ImportDate,SystemLogDate)
      select TOP 1 oi.IDSeq, oi.OrderIDSeq, oi.OrderGroupIDSeq, oi.ProductCode,oi.PriceVersion, oi.ChargeTypeCode,
                 oi.FrequencyCode, oi.MeasureCode, '', SUBSTRING(@IPVC_TransactionItemName,1,300),
                 convert(numeric(30,4),(@IPM_Cost)/(case when @IPBI_Quantity = 0 then 1 else @IPBI_Quantity end)) as ChargeAmount,
                 0, @IPM_Cost,@IPBI_Quantity as Quantity, 1 as TransactionalFlag,
                 0 as InvoicedFlag, @IPD_Date as ServiceDate,
                 @IPI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,'ManualAddition' as ImportSource,@LDT_SystemDate as ImportDate,
                 @LDT_SystemDate  as SystemLogDate
     from Orders.dbo.OrderItem oi with (nolock) 
     where oi.IDSeq = @IPBI_OrderItemID

     select @LI_OrderItemTransactionIDSeq = scope_identity();

     select @LI_OrderItemTransactionIDSeq as OrderItemTransactionIDSeq
    COMMIT TRANSACTION OIT;
  end TRY
  begin CATCH
        -- XACT_STATE:
           -- If 1, the transaction is committable.
           -- If -1, the transaction is uncommittable and should be rolled back.
           -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OIT;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION OIT;
    end
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OIT;
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'ManualAddition of this transaction encountered critical error. Please try again later.'
    return;
  end CATCH;
END  
GO
