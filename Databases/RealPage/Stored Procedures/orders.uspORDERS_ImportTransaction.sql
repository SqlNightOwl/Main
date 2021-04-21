SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_ImportTransaction]
-- Description     : Imports a single transaction into an order
-- Input Parameters: 
-- 
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : Davon Cannon 
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [orders].[uspORDERS_ImportTransaction] (
                                              @IPVC_AccountIDSeq    varchar(50), 
                                              @IPVC_ProductCode     varchar(50), 
                                              @IPN_Quantity         numeric(5,2), 
                                              @IPN_Amount           numeric(30,2),
                                              @IPD_BillDate         datetime, 
                                              @IPVC_Description     varchar(70),
                                              @IPB_InvoiceFlag      bit,
                                              @IPI_UserIDSeq        bigint = 0,
                                              @IPI_TransactionImportIDSeq bigint= NULL,
                                              @IPI_SourceTransactionID    varchar(50) = NULL,
                                              @IPB_OverridePriceFlag      bit = 0, -- If TRUE, use the amount passed in 
                                              @IPB_ForceImportFlag        bit = 0 -- If TRUE, Do not check for duplicate
					    )					
AS
BEGIN 
  set nocount on;
  ------------------------------------------------
  declare @LVC_OrderIDSeq      varchar(50)
  declare @LI_OrderItemIDSeq   bigint
  declare @LI_OrderGroupID     bigint
  declare @LI_OrderItemTransactionIDSeq bigint
  declare @LVC_UserName        varchar(70)
  declare @LC_StatusCode       varchar(4)
  set @LC_StatusCode = 'COMP'

  if isnull(@IPVC_AccountIDSeq, '') = ''
  begin
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'You must have an account ID' 
    return
  end

  select  top 1 @LVC_OrderIDSeq = o.OrderIDSeq,
          @LI_OrderItemIDSeq = oi.IDSeq, 
          @IPN_Amount = case when @IPB_OverridePriceFlag = 0 
                        then convert(numeric(30,2), (oi.NetChargeAmount * @IPN_Quantity))
                        else @IPN_Amount end,
         @IPB_InvoiceFlag = (case when oi.measurecode in ('UNIT','SITE') and oi.frequencycode <> 'OT'
                                      then 0
                                  else 1
                             end) 
  from Orders.dbo.[Order] o  with (nolock)
  inner join Orders.dbo.OrderItem oi  with (nolock)
  on    oi.OrderIDSeq = o.OrderIDSeq
  and   (oi.StatusCode = 'FULF' OR (oi.StatusCode = 'CNCL' AND CONVERT(INT, CONVERT(VARCHAR, ISNULL(CancelDate, GETDATE()), 112)) >= CONVERT(INT, CONVERT(VARCHAR, @IPD_BillDate, 112))))
--  and ((FrequencyCode = 'OT' and MeasureCode = 'ITEM') or (Measurecode = 'TRAN'))
--  and   oi.MeasureCode = 'TRAN'
  and   oi.ProductCode = @IPVC_ProductCode
  and o.AccountIDSeq = @IPVC_AccountIDSeq
  and ChargeTypeCode <> 'ILF'
  where o.AccountIDSeq = @IPVC_AccountIDSeq
  and ChargeTypeCode <> 'ILF'

  if isnull(@IPI_UserIDSeq, 0) = 0
  begin
    set @LVC_UserName = 'SADMIN'
  end
  else
  begin
    select top 1 @LVC_UserName = FirstName + ' ' + LastName
    from Security.dbo.[User]   with (nolock)
    where IDSeq = @IPI_UserIDSeq

    if @LVC_UserName is null
    begin
      declare @LVC_CodeSection varchar(100)

      set @LVC_CodeSection = 'Invalid user ID (' + convert(varchar(10), @IPI_UserIDSeq) + ')'
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    end
  end

  if @LVC_OrderIDSeq is null
  begin
    if exists (select 1
        from ORDERS.dbo.OrderItem   with (nolock)
        where StatusCode = 'EXPD'
        and ProductCode = @IPVC_ProductCode)
    begin
      set @LVC_CodeSection = 'Order expired (' + @IPVC_AccountIDSeq + ')'
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
      return
    end


    set @LVC_CodeSection = 'No order exists (' + @IPVC_AccountIDSeq + ')'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
/*
    begin TRY;
      BEGIN TRANSACTION;
        update ORDERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
        set    IDSeq = IDSeq+1,
               GeneratedDate =CURRENT_TIMESTAMP
      
        select @LVC_OrderIDSeq = OrderIDSeq
        from   ORDERS.DBO.IDGenerator with (NOLOCK)  
      
        Insert into Orders.dbo.[Order](OrderIDSeq,AccountIDSeq,CompanyIDSeq,PropertyIDSeq,
                                       QuoteIDSeq,StatusCode,TransferredFlag,
                                       CreatedBy,ModifiedBy,ApprovedBy,CreatedDate,ModifiedDate,ApprovedDate,
                                       DelayILFBillingFlag)
        select Top 1 @LVC_OrderIDSeq as OrderIDSeq,
                     @IPVC_AccountIDSeq as AccountIDSeq, CompanyIDSeq, PropertyIDSeq,
                     NULL,'APPR' as StatusCode, 0 as TransferredFlag,
                     @LVC_UserName, @LVC_UserName, NULL,
                     Getdate() as CreatedDate,Getdate() as ModifiedDate,
                     NULL,0
        from   Customers.dbo.Account
        where  IDSeq = @IPVC_AccountIDSeq
        and ActiveFlag = 1
      COMMIT TRANSACTION;       

      BEGIN TRANSACTION;
      Insert into Orders.dbo.[OrderGroup](OrderIDSeq,DiscAllocationCode,
                                          Name,Description,TransferredFlag,                                          
                                          AllowProductCancelFlag,OrderGroupType,CustomBundleNameEnabledFlag,
                                          excludeforbookingsflag)
      select Top 1 @LVC_OrderIDSeq,'IND','Custom','Custom',0,                   
                   1, case when PropertyIDSeq is null then 'SITE' else 'PMC' end,
                   0, 0
       from   Customers.dbo.Account
       where  IDSeq = @IPVC_AccountIDSeq

      select @LI_OrderGroupID =  SCOPE_IDENTITY() 
      COMMIT TRANSACTION; 

      Insert into Orders.dbo.OrderItem(OrderIDSeq,OrderGroupIDSeq,
                                     ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,
                                     PriceVersion,minunits,maxunits,
                                     dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                     Quantity,
                                     AllowProductCancelFlag,
                                     ChargeAmount,ExtChargeAmount,
                                     DiscountPercent,DiscountAmount,totaldiscountpercent,totaldiscountamount,
                                     NetChargeAmount,
                                     StatusCode,
                                     StartDate,EndDate,
                                     ILFStartDate, ILFEndDate)
      select top 1 @LVC_OrderIDSeq, @LI_OrderGroupID, p.Code, c.ChargeTypeCode, c.FrequencyCode, c.MeasureCode, p.FamilyCode,
        p.PriceVersion, c.minunits, c.maxunits, c.dollarminimum, c.dollarmaximum, c.credtcardpricingpercentage,
        1, 1, c.ChargeAmount, c.ChargeAmount, 0, 0, 0, 0, c.ChargeAmount, 'FULF', case when c.ChargeTypeCode = 'ACS' then getdate() else null end,
        case when c.ChargeTypeCode = 'ACS' then '1/1/2099' else null end, 
        case when c.ChargeTypeCode = 'ILF' then getdate() else null end, case when c.ChargeTypeCode = 'ILF' then '1/1/2099'else null end
      from  Products.dbo.Product p 
      inner join Products.dbo.Charge c
      on    c.ProductCode = p.Code
      and   c.DisabledFlag = 0
      and   Measurecode = 'TRAN'
--      and ((FrequencyCode = 'OT' and MeasureCode = 'ITEM') or (Measurecode = 'TRAN'))
--      and   c.ChargeTypeCode = 'ACS'
      --and   c.FrequencyCode = 'SG'
--      and   c.MeasureCode = 'TRAN'
      where p.Code = @IPVC_ProductCode
      and   p.DisabledFlag = 0

      set @LI_OrderItemIDSeq = SCOPE_IDENTITY()

      if @@rowcount = 0
      begin
        set @LVC_CodeSection = 'No valid charge is available for the new order. (' + @IPVC_ProductCode + ')'
        Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
        return
      end 

      set @LC_StatusCode = 'NEWO'
    end TRY
    begin CATCH;
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'New OrderID Generation failed' 
      if (XACT_STATE()) = -1
      begin
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      end
      else if (XACT_STATE()) = 1
      begin
        IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
      end                 
    end CATCH; 
*/
  end
  else if @IPB_ForceImportFlag = 0
  begin 
    select top 1 @LI_OrderItemTransactionIDSeq = IDSeq, @LI_OrderItemIDSeq = OrderItemIDSeq
    from Orders.dbo.OrderItemTransaction   with (nolock)
    where OrderItemIDSeq = @LI_OrderItemIDSeq
    and   SourceTransactionID = @IPI_SourceTransactionID

    if @LI_OrderItemTransactionIDSeq is not null
    begin
      select @LI_OrderItemTransactionIDSeq as OrderItemTransactionIDSeq, 'DUPE' as StatusCode, @LI_OrderItemIDSeq as OrderItemIDSeq
      return
    end
  end


  insert into OrderItemTransaction (OrderItemIDSeq, OrderIDSeq, OrderGroupIDSeq, ProductCode,
    PriceVersion, ChargeTypeCode, FrequencyCode, MeasureCode, ServiceCode, TransactionItemName,
    ExtChargeAmount, DiscountAmount, NetChargeAmount, TransactionalFlag, InvoicedFlag, Quantity, ServiceDate,
    SourceTransactionID, TransactionImportIDSeq)
  select top 1 IDSeq, OrderIDSeq, OrderGroupIDSeq, ProductCode, 
    PriceVersion, ChargeTypeCode, FrequencyCode, MeasureCode, ProductCode, @IPVC_Description,
    case when @IPN_Quantity = 0.0 then @IPN_Amount else  convert(numeric(30,2),(convert(numeric(30,5),@IPN_Amount)/@IPN_Quantity)) end, 
    0, @IPN_Amount, @IPB_InvoiceFlag as TransactionalFlag, 0, @IPN_Quantity, @IPD_BillDate,
    @IPI_SourceTransactionID, @IPI_TransactionImportIDSeq
  from Orders.dbo.OrderItem   with (nolock)
  where IDSeq = @LI_OrderItemIDSeq
  
  select SCOPE_IDENTITY() as OrderItemTransactionIDSeq, @LC_StatusCode as StatusCode, @LI_OrderItemIDSeq as OrderItemIDSeq
END
GO
