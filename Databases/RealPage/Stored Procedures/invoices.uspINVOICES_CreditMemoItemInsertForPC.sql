SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_CreditMemoItemInsertForPC
-- PreRequisites   : Invoices.dbo.uspINVOICES_InvoiceItemSelect call would have returned rowset to UI modal.
/*
--PreRequisites Syntax Call to populate UI Modal
Exec Invoices.dbo.uspINVOICES_InvoiceItemSelect 'I0901011189','PartialCredit'
*/
-- Description     : This procedure gets Called  Upon Button Click "Send for Approval" for each selected (checked item) from credit Modal in UI.
--                   For Partial Credit  Scenario
-- Input Parameters: @IPVC_CreditType      as varchar(50),@IPVC_InvoiceIDSeq Varchar(50), other parameters from UI as below
-- Syntax          : 
/*
EXEC INVOICES.dbo.uspINVOICES_CreditMemoItemInsertForPC  @IPVC_CreditType='PartialCredit',@IPVC_InvoiceIDSeq = 'I0901011189',...
*/
-- Revision History:
-- Author          : Surya Kondapalli : Task # 918: Issue with the Credit Memo tab when full tax credit has been applied
-- 08/25/2011      : SRS (Defect 918) Code review and minor related enhancements
-----------------------------------------------------------------------------------------------------------------------------
Create Procedure [invoices].[uspINVOICES_CreditMemoItemInsertForPC] (@IPVC_CreditType                 varchar(50),  --> Mandatory : This is the Credit Type. 
                                                                                                               --> For this proc, only FullCredit or TaxCredit are acceptable values.
                                                                @IPVC_InvoiceIDSeq               varchar(50),  --> Mandatory : This is the InvoiceIDSeq for which Partial Credit are intiated by User.
                                                                @IPBI_InvoiceItemID              bigint = -999,--> This is Unique InvoiceItemIDSeq
                                                                                                               --  Mandatory when @IPI_CustomBundleNameEnabledFlag = 0
                                                                                                               --   Defaulted to -999 and ignored by proc when @IPI_CustomBundleNameEnabledFlag = 1
                                                                @IPVC_InvoiceGroupIDSeq          bigint,       --> Mandatory : This is InvoiceGroupIDSeq; UI knows this in the modal for each selected item.
                                                                @IPI_CustomBundleNameEnabledFlag int,          --> Mandatory : This is CustomBundleNameEnabledFlag;UI knows this in the modal for each selected item.
                                                                @IPVC_OrderIDSeq                 varchar(50),  --> Mandatory : This is OrderIDSeq;UI knows this in the modal for each selected item.
                                                                @IPBI_OrderGroupIDSeq            bigint,       --> Mandatory : This is OrderGroupIDSeq;UI knows this in the modal for each selected item.
                                                                @IPBI_RenewalCount               int,          --> Mandatory : This is renewalCount attribute associated with each row selected.;UI knows this in the modal for each selected item.
                                                                @IPVC_ChargeTypeCode             varchar(3),   --> Mandatory : This is ChargeTypeCode;UI knows this in the modal for each selected item.
                                                                @IPDT_BillingPeriodFromDate      datetime,     --> Mandatory : This is BillingPeriodFromDate;UI knows this in the modal for each selected item.
                                                                @IPDT_BillingPeriodToDate        datetime,     --> Mandatory : This is BillingPeriodToDate;UI knows this in the modal for each selected item.
                                                                -----------------------------------------------------
                                                                @IPM_CreditAmount                money,        --> Mandatory : This is the creditAmount that UI keys in the text box for each selected item in UI.
                                                                @IPM_ShippingAndHandlingAmount   money,        --> Mandatory : This is the ShippingAndHandlingAmount that UI keys in the text box for each selected item in UI.
                                                                                                               ---   For Majority of items this will be 0.00, except a few where the Invoiceitem (such as disc or book etc) is physically shipped
                                                                -----------------------------------------------------
                                                                @IPBI_UserIDSeq                  bigint = -1   --> Mandatory : This is userID of the Person initiating this credit operation from UI.
                                                                                                               --   UI already knows this value to pass in.
                                                               )
as
BEGIN ----> Main BEGIN
  set nocount on;
  -----------------------------------------------------------------------------------------------------------------
  Declare @LVC_CreditMemoIDSeq   varchar(50),
          @LDT_SystemDate        datetime,
          @LVC_CodeSection       varchar(500);

  select @LDT_SystemDate = Getdate()
  -----------------------------------------------------------------------------------------------------------------
  --Step 1: Get the latest CreditMemoIDSeq for CreditType that is in Pending approval status pertaining to the @IPVC_InvoiceIDSeq
  Select @LVC_CreditMemoIDSeq = MAX(CM.CreditMemoIDSeq)
  from   Invoices.dbo.CreditMemo CM WITH (NOLOCK)
  where  CM.InvoiceIDSeq = @IPVC_InvoiceIDSeq
  and    CM.CreditTypeCode = (Case when @IPVC_CreditType = 'PartialCredit' then 'PARC'                                   
                                   else 'ABCD'
                              end)
  and    CM.CreditStatusCode = 'PAPR'
  -----------------------------------------------------------------------------------------------------------------
  --Step 2 : Check if  @LVC_CreditMemoIDSeq is not nul and valid. 
  -- If Main call for uspINVOICES_CreditMemoInsert had succeeded a header CreditMemo Record should existing in the system
  --  in Pending approval status pertaining to the @IPVC_InvoiceIDSeq.
  -- If Not, then throw an Error Back to UI
  -----------------------------------------------------------------------------------------------------------------
  If (@LVC_CreditMemoIDSeq is null)
  begin
    select @LVC_CodeSection = 'Proc:uspINVOICES_CreditMemoItemInsertForPC-Invoice : ' + @IPVC_InvoiceIDSeq + ' CreditType ' + @IPVC_CreditType + 
                              ' System failed to identify Pending Approval CreditMemoIDSeq to complete CreditMemoItem Insert Operation.'
    EXEC CUSTOMERS.dbo.uspCUSTOMERS_RaiseError @IPVC_CodeSection = @LVC_CodeSection;
    Return;
  end
  -----------------------------------------------------------------------------------------------------------------
  --Step 3: Insert for CreditMemoItem for PartialCredit Scenario and when @IPI_CustomBundleNameEnabledFlag = 0
  -- Business Logic : identify all corresponding InvoiceItems based on input parameters to copy over
  --                  other attributes along with input @IPM_CreditAmount,@IPM_ShippingAndHandlingAmount,
  --                  Since this is  Partial Credit Scenario for CustomBundleNameEnabledFlag = 0
  -- Only TaxwareCode and DefaultTaxwareCode will also come along.
  -- NO TAX Related TaxAmount,TaxPercent,TawarePrimary and secondary distribution will flow through from Invoiceitem

  -- TAXWARE CALLS WILL be FINALLY MADE by UI for PARTIAL CREDIT OPERATION by UI Upon Button Click "Send for Approval", 
  ---  after the Insert operation Call of this proc by UI
  --   is fully complete for each of the selected (checked item) in UI. 
  --  The Get proc will be [INVOICES].dbo.uspINVOICES_GetTaxableCreditMemoItemsForPartialCredit.SQL
  --  The set proc to records the taxware results will be [INVOICES].dbo.uspINVOICES_CreditMemoItemTaxWareUpdate 

  -- UI WILL ALSO Make a followup TAXWARE CALLS only for partial Credit at the time of APPROVE CREDIT.
  -----------------------------------------------------------------------------------------------------------------
  If (@IPVC_CreditType = 'PartialCredit' and @IPI_CustomBundleNameEnabledFlag = 0)
  begin
    ---PartialCredit and CustomBundleNameEnabledFlag = 0
    Insert into Invoices.dbo.CreditMemoItem
                (CreditMemoIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,
                 CustomBundleNameEnabledFlag,InvoiceItemIdSeq,
                 UnitCreditAmount,EffectiveQuantity,ExtCreditAmount,DiscountCreditAmount,
                 NetCreditAmount,ShippingAndHandlingCreditAmount,
                 TaxPercent,TaxAmount,
                 RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,RevenueRecognitionCode,
                 TaxwareCode,DefaultTaxwareCode                
                 ,CreatedByIDSeq,CreatedDate,SystemLogDate
                )
    select @LVC_CreditMemoIDSeq    as CreditMemoIDSeq,@IPVC_InvoiceIDSeq as InvoiceIDSeq,
           @IPVC_InvoiceGroupIDSeq as InvoiceGroupIDSeq,@IPI_CustomBundleNameEnabledFlag as CustomBundleNameEnabledFlag,
           @IPBI_InvoiceItemID     as InvoiceItemIdSeq,
           -------------------------------
           @IPM_CreditAmount       as UnitCreditAmount,
           1                       as EffectiveQuantity,
           @IPM_CreditAmount       as ExtCreditAmount,
           0.00                    as DiscountCreditAmount,
           @IPM_CreditAmount       as NetCreditAmount, 
           (case when II.ShippingAndHandlingAmount > 0 
                   then @IPM_ShippingAndHandlingAmount 
                  else 0.00 
            end)                   as ShippingAndHandlingCreditAmount,
           0.00                    as TaxPercent,-----> These will be defaulted to 0.00 for initial insert, which will be updated by taxware call.
           0.00                    as TaxAmount, -----> These will be defaulted to 0.00 for initial insert, which will be updated by taxware call. 
           -------------------------------
           II.RevenueTierCode,II.RevenueAccountCode,II.DeferredRevenueAccountCode,II.RevenueRecognitionCode,
           II.TaxwareCode,II.DefaultTaxwareCode           
           ,@IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
    from    Invoices.dbo.InvoiceItem  II WITH (NOLOCK)
    where   II.InvoiceIDSeq          = @IPVC_InvoiceIDSeq
    and     II.IDSeq                 = @IPBI_InvoiceItemID
    and     II.InvoiceGroupIDSeq     = @IPVC_InvoiceGroupIDSeq
    and     II.orderidseq            = @IPVC_OrderIDSeq
    and     II.OrderGroupIDSeq       = @IPBI_OrderGroupIDSeq
    and     II.ChargeTypeCode        = @IPVC_ChargeTypeCode
    and     II.OrderItemRenewalCount = @IPBI_RenewalCount
    and     II.BillingPeriodFromDate = @IPDT_BillingPeriodFromDate
    and     II.BillingPeriodToDate   = @IPDT_BillingPeriodToDate
    and     (@IPI_CustomBundleNameEnabledFlag = 0)
    and     Not exists (select Top 1 1
                        from   Invoices.dbo.CreditMemoItem CMI with (nolock)
                        where  CMI.CreditMemoIDSeq             = @LVC_CreditMemoIDSeq
                        and    CMI.InvoiceIDSeq                = @IPVC_InvoiceIDSeq
                        and    CMI.InvoiceGroupIDSeq           = @IPVC_InvoiceGroupIDSeq                   
                        and    CMI.InvoiceItemIdSeq            = @IPBI_InvoiceItemID
                        and    CMI.CustomBundleNameEnabledFlag = @IPI_CustomBundleNameEnabledFlag
                       );

   -----------------------------------------------------------------------
   Exec Invoices.dbo.[uspCredits_SyncCreditTaxAmount] @IPVC_CreditMemoIDSeq = @LVC_CreditMemoIDSeq;
   -----------------------------------------------------------------------
   return;
  end 
  -----------------------------------------------------------------------------------------------------------------
  --Step 4: Insert for CreditMemoItem for PartialCredit Scenario and when @IPI_CustomBundleNameEnabledFlag = 1
  -- Business Logic : identify all corresponding InvoiceItems based on input parameters to copy over
  --                  other attributes along with input @IPM_CreditAmount,@IPM_ShippingAndHandlingAmount,
  --                  Since this is  Partial Credit Scenario for CustomBundleNameEnabledFlag = 1
  -- Only TaxwareCode and DefaultTaxwareCode will also come along.
  -- NO TAX Related TaxAmount,TaxPercent,TawarePrimary and secondary distribution will flow through from Invoiceitem

  -- TAXWARE CALLS WILL be FINALLY MADE by UI for PARTIAL CREDIT OPERATION by UI Upon Button Click "Send for Approval", 
  ---  after the Insert operation Call of this proc by UI
  --   is fully complete for each of the selected (checked item) in UI. 
  --  The Get proc will be [INVOICES].dbo.uspINVOICES_GetTaxableCreditMemoItemsForPartialCredit.SQL
  --  The set proc to records the taxware results will be [INVOICES].dbo.uspINVOICES_CreditMemoItemTaxWareUpdate 

  -- UI WILL ALSO Make a followup TAXWARE CALLS only for partial Credit at the time of APPROVE CREDIT.
  -----------------------------------------------------------------------------------------------------------------
  If (@IPVC_CreditType = 'PartialCredit' and @IPI_CustomBundleNameEnabledFlag = 1)
  begin
    ---PartialCredit and CustomBundleNameEnabledFlag = 1
    ;With CTE_InvoiceGroup (InvoiceIDSeq,InvoiceGroupIDSeq,
                            OrderIDSeq,OrderGroupIDSeq,ChargeTypeCode,RenewalCount,
                            BillingPeriodFromDate,BillingPeriodToDate,GroupNetChargeAmount
                           )
     as (select II.InvoiceIDSeq,II.InvoiceGroupIDSeq,
                II.OrderIDSeq,II.OrderGroupIDSeq,II.ChargeTypeCode,II.OrderItemRenewalCount as RenewalCount,
                II.BillingPeriodFromDate,II.BillingPeriodToDate,
                Convert(float,
                             (case when Sum(II.NetChargeAmount) > 0 
                                     then Sum(II.NetChargeAmount)
                                   else 1.00
                              end)
                        )                   as GroupNetChargeAmount
         from  Invoices.dbo.InvoiceItem  II WITH (NOLOCK)
         where   II.InvoiceIDSeq          = @IPVC_InvoiceIDSeq
         and     II.InvoiceGroupIDSeq     = @IPVC_InvoiceGroupIDSeq
         and     II.orderidseq            = @IPVC_OrderIDSeq
         and     II.OrderGroupIDSeq       = @IPBI_OrderGroupIDSeq
         and     II.ChargeTypeCode        = @IPVC_ChargeTypeCode
         and     II.OrderItemRenewalCount = @IPBI_RenewalCount
         and     II.BillingPeriodFromDate = @IPDT_BillingPeriodFromDate
         and     II.BillingPeriodToDate   = @IPDT_BillingPeriodToDate
         and     (@IPI_CustomBundleNameEnabledFlag = 1)
         group by II.InvoiceIDSeq,II.InvoiceGroupIDSeq,
                  II.OrderIDSeq,II.OrderGroupIDSeq,II.ChargeTypeCode,II.OrderItemRenewalCount,
                  II.BillingPeriodFromDate,II.BillingPeriodToDate
       )
    Insert into Invoices.dbo.CreditMemoItem
                (CreditMemoIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,
                 CustomBundleNameEnabledFlag,InvoiceItemIdSeq,
                 UnitCreditAmount,EffectiveQuantity,ExtCreditAmount,DiscountCreditAmount,
                 NetCreditAmount,ShippingAndHandlingCreditAmount,
                 TaxPercent,TaxAmount,
                 RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,RevenueRecognitionCode,
                 TaxwareCode,DefaultTaxwareCode                 
                 ,CreatedByIDSeq,CreatedDate,SystemLogDate
                )
    select @LVC_CreditMemoIDSeq    as CreditMemoIDSeq,@IPVC_InvoiceIDSeq as InvoiceIDSeq,
           @IPVC_InvoiceGroupIDSeq as InvoiceGroupIDSeq,@IPI_CustomBundleNameEnabledFlag as CustomBundleNameEnabledFlag,
           II.IDSeq                as InvoiceItemIdSeq,
           ---------------------------------------
           convert(numeric(18,2),
                                ((convert(float,II.NetChargeAmount) * @IPM_CreditAmount)
                                         /
                                 (CTEIG.GroupNetChargeAmount)
                                )
                   )               as UnitCreditAmount,
           ---------------------------------------
           1                       as EffectiveQuantity,
           ---------------------------------------
           convert(numeric(18,2),
                                ((convert(float,II.NetChargeAmount) * @IPM_CreditAmount)
                                         /
                                 (CTEIG.GroupNetChargeAmount)
                                )
                   )               as ExtCreditAmount,
           ---------------------------------------
           0.00                    as DiscountCreditAmount,
           ---------------------------------------
           convert(numeric(18,2),
                                ((convert(float,II.NetChargeAmount) * @IPM_CreditAmount)
                                         /
                                 (CTEIG.GroupNetChargeAmount)
                                )
                   )               as NetCreditAmount,
           ---------------------------------------
           (case when II.ShippingAndHandlingAmount > 0 
                   then @IPM_ShippingAndHandlingAmount 
                  else 0.00 
            end)                   as ShippingAndHandlingCreditAmount,
           ---------------------------------------
           0.00                    as TaxPercent,-----> These will be defaulted to 0.00 for initial insert, which will be updated by taxware call.
           0.00                    as TaxAmount, -----> These will be defaulted to 0.00 for initial insert, which will be updated by taxware call. 
           ---------------------------------------           
           II.RevenueTierCode,II.RevenueAccountCode,II.DeferredRevenueAccountCode,II.RevenueRecognitionCode,
           II.TaxwareCode,II.DefaultTaxwareCode          
           ,@IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
    from    Invoices.dbo.InvoiceItem  II WITH (NOLOCK)
    inner join
            CTE_InvoiceGroup  CTEIG 
    on      II.InvoiceIDSeq          = CTEIG.InvoiceIDSeq
    and     II.InvoiceGroupIDSeq     = CTEIG.InvoiceGroupIDSeq
    and     II.orderidseq            = CTEIG.OrderIDSeq
    and     II.OrderGroupIDSeq       = CTEIG.OrderGroupIDSeq
    and     II.ChargeTypeCode        = CTEIG.ChargeTypeCode
    and     II.OrderItemRenewalCount = CTEIG.RenewalCount
    and     II.BillingPeriodFromDate = CTEIG.BillingPeriodFromDate
    and     II.BillingPeriodToDate   = CTEIG.BillingPeriodToDate 
    ------------------------------------
    and     II.InvoiceIDSeq          = @IPVC_InvoiceIDSeq
    and     II.InvoiceGroupIDSeq     = @IPVC_InvoiceGroupIDSeq
    and     II.orderidseq            = @IPVC_OrderIDSeq
    and     II.OrderGroupIDSeq       = @IPBI_OrderGroupIDSeq
    and     II.ChargeTypeCode        = @IPVC_ChargeTypeCode
    and     II.OrderItemRenewalCount = @IPBI_RenewalCount
    and     II.BillingPeriodFromDate = @IPDT_BillingPeriodFromDate
    and     II.BillingPeriodToDate   = @IPDT_BillingPeriodToDate 
    ------------------------------------
    where   II.InvoiceIDSeq          = @IPVC_InvoiceIDSeq
    and     II.InvoiceGroupIDSeq     = @IPVC_InvoiceGroupIDSeq
    and     II.orderidseq            = @IPVC_OrderIDSeq
    and     II.OrderGroupIDSeq       = @IPBI_OrderGroupIDSeq
    and     II.ChargeTypeCode        = @IPVC_ChargeTypeCode
    and     II.OrderItemRenewalCount = @IPBI_RenewalCount
    and     II.BillingPeriodFromDate = @IPDT_BillingPeriodFromDate
    and     II.BillingPeriodToDate   = @IPDT_BillingPeriodToDate
    and     (@IPI_CustomBundleNameEnabledFlag = 1)
    and     Not exists (select Top 1 1
                        from   Invoices.dbo.CreditMemoItem CMI with (nolock)
                        where  CMI.CreditMemoIDSeq             = @LVC_CreditMemoIDSeq
                        and    CMI.InvoiceIDSeq                = @IPVC_InvoiceIDSeq
                        and    CMI.InvoiceGroupIDSeq           = @IPVC_InvoiceGroupIDSeq                   
                        and    CMI.InvoiceItemIdSeq            = II.IDSeq
                        and    CMI.CustomBundleNameEnabledFlag = @IPI_CustomBundleNameEnabledFlag
                       );
   -----------------------------------------------------------------------
   ---Adjustment for the last penny if difference between sum(NetCreditAmount) and @IPM_CreditAmount yields a non zero penny or two
   --- BL : Calculate the difference between sum(NetCreditAmount) and @IPM_CreditAmount
   ---      Add/Subtract to the very last Invoiceitem of the Group
   ---      Applicable only to PartialCredit and CustomBundleNameEnabledFlag = 1 and distribution of @IPM_CreditAmount yields a recurring decimals.
   -----------------------------------------------------------------------
   ;With CTE_CMIIG (CreditMemoIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,GroupNetCreditAmount,InvoiceItemIDSeq)
     as (select CMI.CreditMemoIDSeq                 as CreditMemoIDSeq,
                CMI.InvoiceIDSeq                    as InvoiceIDSeq,
                CMI.InvoiceGroupIDSeq               as InvoiceGroupIDSeq,
                Sum(CMI.NetCreditAmount)            as GroupNetCreditAmount,
                Max(CMI.InvoiceItemIDSeq)           as InvoiceItemIDSeq
         from  Invoices.dbo.CreditMemoItem  CMI WITH (NOLOCK)
         where   CMI.CreditMemoIDSeq       = @LVC_CreditMemoIDSeq
         and     CMI.InvoiceIDSeq          = @IPVC_InvoiceIDSeq
         and     CMI.InvoiceGroupIDSeq     = @IPVC_InvoiceGroupIDSeq
         and     CMI.CustomBundleNameEnabledFlag = 1
         and     (@IPI_CustomBundleNameEnabledFlag = 1)
         group by CMI.CreditMemoIDSeq ,CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq
        )
     Update CMI
     set    CMI.UnitCreditAmount = CMI.UnitCreditAmount + (@IPM_CreditAmount-CTE_CMIIG.GroupNetCreditAmount)
           ,CMI.ExtCreditAmount  = CMI.ExtCreditAmount  + (@IPM_CreditAmount-CTE_CMIIG.GroupNetCreditAmount) 
           ,CMI.NetCreditAmount  = CMI.NetCreditAmount  + (@IPM_CreditAmount-CTE_CMIIG.GroupNetCreditAmount)            
     from   Invoices.dbo.CreditMemoItem  CMI WITH (NOLOCK)
     inner join
            CTE_CMIIG CTE_CMIIG
     on     CMI.CreditMemoIDSeq       = CTE_CMIIG.CreditMemoIDSeq
     and    CMI.InvoiceIDSeq          = CTE_CMIIG.InvoiceIDSeq
     and    CMI.InvoiceGroupIDSeq     = CTE_CMIIG.InvoiceGroupIDSeq 
     and    CMI.InvoiceItemIDSeq      = CTE_CMIIG.InvoiceItemIDSeq
     and    CMI.CreditMemoIDSeq       = @LVC_CreditMemoIDSeq
     and    CMI.InvoiceIDSeq          = @IPVC_InvoiceIDSeq
     and    CMI.InvoiceGroupIDSeq     = @IPVC_InvoiceGroupIDSeq
     and    CMI.CustomBundleNameEnabledFlag = 1
     where  CMI.CreditMemoIDSeq       = CTE_CMIIG.CreditMemoIDSeq
     and    CMI.InvoiceIDSeq          = CTE_CMIIG.InvoiceIDSeq
     and    CMI.InvoiceGroupIDSeq     = CTE_CMIIG.InvoiceGroupIDSeq 
     and    CMI.InvoiceItemIDSeq      = CTE_CMIIG.InvoiceItemIDSeq
     and    CMI.CreditMemoIDSeq       = @LVC_CreditMemoIDSeq
     and    CMI.InvoiceIDSeq          = @IPVC_InvoiceIDSeq
     and    CMI.InvoiceGroupIDSeq     = @IPVC_InvoiceGroupIDSeq
     and    CMI.CustomBundleNameEnabledFlag = 1
   -----------------------------------------------------------------------
   Exec Invoices.dbo.[uspCredits_SyncCreditTaxAmount] @IPVC_CreditMemoIDSeq = @LVC_CreditMemoIDSeq;
   -----------------------------------------------------------------------
   return;
  end 
-----------------------------------------------------------------------------------------------------------------
END ----> Main END
GO
