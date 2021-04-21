SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_ValidateCreditMemoInitiate
-- PreRequisites   : This will be the main Call Made by UI on click for Invoice-->Credit-->Full Credit
--                   This will be the main Call Made by UI on click for Invoice-->Credit-->Partial Credit
--                   This will be the main Call Made by UI on click for Invoice-->Credit-->Full Tax Credit

-- Description     : This will be the main Call Made by UI on click for Invoice-->Credit
--                   For Full credit Scenaro or Full Tax Credit Scenario or Partial Credit Scenario
-- Input Parameters: @IPVC_CreditType      as varchar(50),@IPVC_InvoiceIDSeq Varchar(50),@IPBI_UserIDSeq bigint
-- Syntax          : 
/*
EXEC INVOICES.dbo.uspINVOICES_ValidateCreditMemoInitiate  @IPVC_CreditType='FullCredit',@IPVC_InvoiceIDSeq = 'I1105025854',@IPVC_CreditMemoIDSeq='',@IPBI_UserIDSeq=123
EXEC INVOICES.dbo.uspINVOICES_ValidateCreditMemoInitiate  @IPVC_CreditType='PartialCredit',@IPVC_InvoiceIDSeq = 'I1105025854',@IPVC_CreditMemoIDSeq='',@IPBI_UserIDSeq=123
EXEC INVOICES.dbo.uspINVOICES_ValidateCreditMemoInitiate  @IPVC_CreditType='FullTax',@IPVC_InvoiceIDSeq = 'I1105025854',@IPVC_CreditMemoIDSeq='',@IPBI_UserIDSeq=123

*/
-- Revision History:
-- Author          : SRS : Task # 918: 
-- 09/28/2011      : 
-----------------------------------------------------------------------------------------------------------------------------
Create Procedure [invoices].[uspINVOICES_ValidateCreditMemoInitiate] (@IPVC_CreditType      varchar(50),     --> Mandatory : This is the Credit Type. 
                                                                                                          -- For this proc, only FullCredit or (TaxCredit or FullTax) or PartialCredit are acceptable values.
                                                                 @IPVC_InvoiceIDSeq    varchar(50),     --> Mandatory : This is the InvoiceIDSeq for which FullCredit or TaxCredit or PartialCredit are intiated by User.
                                                                 @IPVC_CreditMemoIDSeq varchar(50)= '', ---> Optional: If UI has this Credit Memo ID, then Pass that value when it goes for Revise.
                                                                                                          -- For Brand new CreditMemo Initiate to Create, UI will not have the value. Pass this as blank ''.
                                                                 @IPBI_UserIDSeq       bigint = -1      --> Mandatory : This is userID of the Person initiating this credit operation from UI.
                                                                                                        --   UI already knows this value to pass in.
                                                                )
as
BEGIN ----> Main BEGIN
  set nocount on;
  -----------------------------------------------------------------------------------------------------------------
  --Local Variables declaration
  Declare   @LI_UIIntiateCreditFlag       int
           ,@LVC_UIStopAlertMessage       varchar(4000);

  Declare   @LVC_PendCreditMemoIDSeq      varchar(50),
            @LI_NetAmountBalanceIndicator int,
            @LI_TaxBalanceIndicator       int;
  -----------------------------------------------------------------------------------------------------------------
  --Local Variables Initialization
  select    @LI_UIIntiateCreditFlag    = 1
           ,@LVC_UIStopAlertMessage    = NULL
           ,@LI_NetAmountBalanceIndicator = 0
           ,@LI_TaxBalanceIndicator      = 0;

  select @IPVC_CreditMemoIDSeq = coalesce(nullif(ltrim(rtrim(@IPVC_CreditMemoIDSeq)),''),'ABCDEFHIJK');
  -----------------------------------------------------------------------------------------------------------------
  ----->Validation(s)
  -----------------------------------------------------------------------------------------------------------------
  --Step 1 : InvoiceID should be valid and exist in the system
  if not exists (select Top 1 1
                 from   Invoices.dbo.Invoice I with (nolock)
                 where  I.InvoiceIDSeq = @IPVC_InvoiceIDSeq
                )
  begin
    select  @LI_UIIntiateCreditFlag = 0
           ,@LVC_UIStopAlertMessage = 'Invoice : ' + @IPVC_InvoiceIDSeq + ' does not exists in the system. ' + 
                                      'Aborting new ' + @IPVC_CreditType + ' CreditMemo process now ...'

    select  @LI_UIIntiateCreditFlag    as UIIntiateCreditFlag
           ,@LVC_UIStopAlertMessage    as UIStopAlertMessage;
    return;
  end
  -----------------------------------------------------------------------------------------------------------------
  --Step 2 : InvoiceID should be already printed
  if not exists (select Top 1 1
                 from   Invoices.dbo.Invoice I with (nolock)
                 where  I.InvoiceIDSeq = @IPVC_InvoiceIDSeq
                 and    I.PrintFlag    = 1
                )
  begin
    select  @LI_UIIntiateCreditFlag = 0
           ,@LVC_UIStopAlertMessage = 'Invoice : ' + @IPVC_InvoiceIDSeq + ' is still pending and not printed. ' + 
                                      'Aborting new ' + @IPVC_CreditType + ' CreditMemo process now ...'

    select  @LI_UIIntiateCreditFlag    as UIIntiateCreditFlag
           ,@LVC_UIStopAlertMessage    as UIStopAlertMessage;
    return;
  end
  -----------------------------------------------------------------------------------------------------------------
  --Step 3: InvoiceID should not have a prior Pending Approval Credit Memo
  if exists (select Top 1 1
             from   Invoices.dbo.CreditMemo CM with (nolock)
             where  CM.InvoiceIDSeq     =  @IPVC_InvoiceIDSeq             
             and    CM.CreditStatusCode = 'PAPR'
             and    CM.CreditMemoIDSeq  <> @IPVC_CreditMemoIDSeq
            )
  begin
    select @LVC_PendCreditMemoIDSeq = CM.CreditMemoIDSeq
    from   Invoices.dbo.CreditMemo CM with (nolock)
    where  CM.InvoiceIDSeq     =  @IPVC_InvoiceIDSeq             
    and    CM.CreditStatusCode = 'PAPR'
    and    CM.CreditMemoIDSeq  <> @IPVC_CreditMemoIDSeq;

    select  @LI_UIIntiateCreditFlag = 0
           ,@LVC_UIStopAlertMessage = 'Invoice : ' + @IPVC_InvoiceIDSeq + ' already has a CreditMemo : ' + @LVC_PendCreditMemoIDSeq + ' that is Pending Approval ' +
                                      'which has to be adjudicated prior to this operation. ' + 
                                      'Aborting new ' + @IPVC_CreditType + ' CreditMemo process now ...'
    select  @LI_UIIntiateCreditFlag    as UIIntiateCreditFlag
           ,@LVC_UIStopAlertMessage    as UIStopAlertMessage;
    return;
  end 
  -----------------------------------------------------------------------------------------------------------------
  --Step 4: Full Tax Credit Scenario : InvoiceID should have atleast one invoice item with Non Zero TaxAmount balance.
  if (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
  begin
    select @LI_TaxBalanceIndicator = 0;
    -------------------------------------------
    ---Get TaxBalanceIndicator
    -------------------------------------------
    ;With CTE_PreviousApprovedCMI (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                                   NetCreditAmount,NetCreditTaxAmount,ShippingAndHandlingCreditAmount
                                  )
        as (select CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag,
                   Sum(CMI.NetCreditAmount)                 as NetCreditAmount,
                   Sum(CMI.TaxAmount)                       as NetCreditTaxAmount,
                   sum(CMI.ShippingAndHandlingCreditAmount) as ShippingAndHandlingCreditAmount
            from   INVOICES.dbo.CreditMemo     CM with (nolock)
            inner Join
                   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            on     CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq
            and    CM.InvoiceIDSeq    = CMI.InvoiceIDSeq
            and    CM.InvoiceIDSeq    = @IPVC_InvoiceIDSeq
            and    CM.CreditStatusCode= 'APPR'
            group by CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag
           ) 
    --------------
    select  @LI_TaxBalanceIndicator = count(1)
    from    Invoices.dbo.InvoiceItem  II WITH (NOLOCK)
    inner join 
            Invoices.dbo.InvoiceGroup IG WITH (NOLOCK)
    ON      IG.InvoiceIDSeq      = II.InvoiceIDSeq  
    and     IG.IDSeq             = II.InvoiceGroupIDSeq
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     IG.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     IG.orderidseq        = II.orderidseq  
    and     IG.ordergroupidseq   = II.ordergroupidseq
    left outer Join
           CTE_PreviousApprovedCMI  CTE_PACMI
    on     II.InvoiceIDSeq         = CTE_PACMI.InvoiceIDSeq
    and    IG.InvoiceIDSeq         = CTE_PACMI.InvoiceIDSeq
    and    IG.IDSeq                = CTE_PACMI.InvoiceGroupIDSeq
    and    II.InvoiceGroupIDSeq    = CTE_PACMI.InvoiceGroupIDSeq
    and    II.idseq                = CTE_PACMI.Invoiceitemidseq
    and    IG.CustomBundleNameEnabledFlag = CTE_PACMI.CustomBundleNameEnabledFlag
    and    CTE_PACMI.InvoiceIDSeq  = @IPVC_InvoiceIDSeq   
    where   II.InvoiceIDSeq        = @IPVC_InvoiceIDSeq
    and     IG.InvoiceIDSeq        = @IPVC_InvoiceIDSeq
    group by II.InvoiceIDSeq,II.InvoiceGroupIDSeq,
             (case when (convert(int,IG.CustomBundleNameEnabledFlag) = 1)
                    then -999
                  else II.IDSeq
              end)
             ,convert(int,IG.CustomBundleNameEnabledFlag)
             ,II.OrderIDSeq
             ,II.OrderGroupIDSeq
             ,II.OrderItemRenewalCount
             ,II.BillingPeriodFromDate
             ,II.BillingPeriodToDate
             ,II.ReportingTypeCode
             ,II.ChargeTypeCode
    having (Sum(II.TaxAmount) - Sum(coalesce(CTE_PACMI.NetCreditTaxAmount,0))) > 0;

    if (@LI_TaxBalanceIndicator=0)
    begin
      select  @LI_UIIntiateCreditFlag = 0
             ,@LVC_UIStopAlertMessage = 'Invoice : ' + @IPVC_InvoiceIDSeq + ' does not have atleast one item with NON ZERO Net Tax($) remaining balance left to be credited. ' + 
                                        'Aborting new ' + @IPVC_CreditType + ' CreditMemo process now ...'
      select  @LI_UIIntiateCreditFlag    as UIIntiateCreditFlag
             ,@LVC_UIStopAlertMessage    as UIStopAlertMessage;
      return;
    end
  end
  -----------------------------------------------------------------------------------------------------------------
  --Step 5: FullCredit PartialCredit Scenario : 
  --        InvoiceID should have atleast one invoice item with Non Zero TaxAmount balance.  OR
  --        InvoiceID should have atleast one invoice item with Non Zero NetChargeAmount balance.
  if (@IPVC_CreditType='FullCredit' or @IPVC_CreditType = 'PartialCredit')
  begin
    select  @LI_NetAmountBalanceIndicator = 0
           ,@LI_TaxBalanceIndicator       = 0;
    -------------------------------------------
    ---Get TaxBalanceIndicator
    -------------------------------------------
    ;With CTE_PreviousApprovedCMI (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                                   NetCreditAmount,NetCreditTaxAmount,ShippingAndHandlingCreditAmount
                                  )
        as (select CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag,
                   Sum(CMI.NetCreditAmount)                 as NetCreditAmount,
                   Sum(CMI.TaxAmount)                       as NetCreditTaxAmount,
                   sum(CMI.ShippingAndHandlingCreditAmount) as ShippingAndHandlingCreditAmount
            from   INVOICES.dbo.CreditMemo     CM with (nolock)
            inner Join
                   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            on     CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq
            and    CM.InvoiceIDSeq    = CMI.InvoiceIDSeq
            and    CM.InvoiceIDSeq    = @IPVC_InvoiceIDSeq
            and    CM.CreditStatusCode= 'APPR'
            group by CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag
           ) 
    --------------
    select  @LI_TaxBalanceIndicator = count(1)
    from    Invoices.dbo.InvoiceItem  II WITH (NOLOCK)
    inner join 
            Invoices.dbo.InvoiceGroup IG WITH (NOLOCK)
    ON      IG.InvoiceIDSeq      = II.InvoiceIDSeq  
    and     IG.IDSeq             = II.InvoiceGroupIDSeq
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     IG.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     IG.orderidseq        = II.orderidseq  
    and     IG.ordergroupidseq   = II.ordergroupidseq
    left outer Join
           CTE_PreviousApprovedCMI  CTE_PACMI
    on     II.InvoiceIDSeq         = CTE_PACMI.InvoiceIDSeq
    and    IG.InvoiceIDSeq         = CTE_PACMI.InvoiceIDSeq
    and    IG.IDSeq                = CTE_PACMI.InvoiceGroupIDSeq
    and    II.InvoiceGroupIDSeq    = CTE_PACMI.InvoiceGroupIDSeq
    and    II.idseq                = CTE_PACMI.Invoiceitemidseq
    and    IG.CustomBundleNameEnabledFlag = CTE_PACMI.CustomBundleNameEnabledFlag
    and    CTE_PACMI.InvoiceIDSeq  = @IPVC_InvoiceIDSeq   
    where   II.InvoiceIDSeq        = @IPVC_InvoiceIDSeq
    and     IG.InvoiceIDSeq        = @IPVC_InvoiceIDSeq
    group by II.InvoiceIDSeq,II.InvoiceGroupIDSeq,
             (case when (convert(int,IG.CustomBundleNameEnabledFlag) = 1)
                    then -999
                  else II.IDSeq
              end)
             ,convert(int,IG.CustomBundleNameEnabledFlag)
             ,II.OrderIDSeq
             ,II.OrderGroupIDSeq
             ,II.OrderItemRenewalCount
             ,II.BillingPeriodFromDate
             ,II.BillingPeriodToDate
             ,II.ReportingTypeCode
             ,II.ChargeTypeCode
    having (Sum(II.TaxAmount) - Sum(coalesce(CTE_PACMI.NetCreditTaxAmount,0))) > 0;
    -------------------------------------------
    ---Get NetAmountBalanceIndicator
    -------------------------------------------
    ;With CTE_PreviousApprovedCMI (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                                   NetCreditAmount,NetCreditTaxAmount,ShippingAndHandlingCreditAmount
                                  )
        as (select CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag,
                   Sum(CMI.NetCreditAmount)                 as NetCreditAmount,
                   Sum(CMI.TaxAmount)                       as NetCreditTaxAmount,
                   sum(CMI.ShippingAndHandlingCreditAmount) as ShippingAndHandlingCreditAmount
            from   INVOICES.dbo.CreditMemo     CM with (nolock)
            inner Join
                   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            on     CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq
            and    CM.InvoiceIDSeq    = CMI.InvoiceIDSeq
            and    CM.InvoiceIDSeq    = @IPVC_InvoiceIDSeq
            and    CM.CreditStatusCode= 'APPR'
            group by CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag
           ) 
    --------------
    select  Top 1 @LI_NetAmountBalanceIndicator = count(1)
    from    Invoices.dbo.InvoiceItem  II WITH (NOLOCK)
    inner join 
            Invoices.dbo.InvoiceGroup IG WITH (NOLOCK)
    ON      IG.InvoiceIDSeq      = II.InvoiceIDSeq  
    and     IG.IDSeq             = II.InvoiceGroupIDSeq
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     IG.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     IG.orderidseq        = II.orderidseq  
    and     IG.ordergroupidseq   = II.ordergroupidseq
    left outer Join
           CTE_PreviousApprovedCMI  CTE_PACMI
    on     II.InvoiceIDSeq         = CTE_PACMI.InvoiceIDSeq
    and    IG.InvoiceIDSeq         = CTE_PACMI.InvoiceIDSeq
    and    IG.IDSeq                = CTE_PACMI.InvoiceGroupIDSeq
    and    II.InvoiceGroupIDSeq    = CTE_PACMI.InvoiceGroupIDSeq
    and    II.idseq                = CTE_PACMI.Invoiceitemidseq
    and    IG.CustomBundleNameEnabledFlag = CTE_PACMI.CustomBundleNameEnabledFlag
    and    CTE_PACMI.InvoiceIDSeq  = @IPVC_InvoiceIDSeq   
    where   II.InvoiceIDSeq        = @IPVC_InvoiceIDSeq
    and     IG.InvoiceIDSeq        = @IPVC_InvoiceIDSeq
    group by II.InvoiceIDSeq,II.InvoiceGroupIDSeq,
             (case when (convert(int,IG.CustomBundleNameEnabledFlag) = 1)
                    then -999
                  else II.IDSeq
              end)
             ,convert(int,IG.CustomBundleNameEnabledFlag)
             ,II.OrderIDSeq
             ,II.OrderGroupIDSeq
             ,II.OrderItemRenewalCount
             ,II.BillingPeriodFromDate
             ,II.BillingPeriodToDate
             ,II.ReportingTypeCode
             ,II.ChargeTypeCode
    having (Sum(II.NetChargeAmount) - Sum(coalesce(CTE_PACMI.NetCreditAmount,0))) > 0;

    if (@LI_NetAmountBalanceIndicator=0 and @LI_TaxBalanceIndicator = 0)
    begin
      select  @LI_UIIntiateCreditFlag = 0
             ,@LVC_UIStopAlertMessage = 'Invoice : ' + @IPVC_InvoiceIDSeq + ' does not have atleast one item either with NON ZERO Net Charge($) or Net Tax($) remaining balance left to be credited. ' + 
                                        'Aborting new ' + @IPVC_CreditType + ' CreditMemo process now ...'
      select  @LI_UIIntiateCreditFlag    as UIIntiateCreditFlag
             ,@LVC_UIStopAlertMessage    as UIStopAlertMessage;
      return;
    end
    if (@LI_NetAmountBalanceIndicator=0 and @LI_TaxBalanceIndicator > 0)
    begin
      select  @LI_UIIntiateCreditFlag = 0
             ,@LVC_UIStopAlertMessage = 'Invoice : ' + @IPVC_InvoiceIDSeq + ' does not have atleast one item with NON ZERO Net Charge($) remaining balance left to be credited. ' +                                         
                                        'Aborting this new ' + @IPVC_CreditType + ' CreditMemo process now ... ' + 
                                        'However it does have atleast one item with NON ZERO Net Tax($) remaining balance left to be credited. ' +
                                        'Please initiate Full Tax Credit process. '
      select  @LI_UIIntiateCreditFlag    as UIIntiateCreditFlag
             ,@LVC_UIStopAlertMessage    as UIStopAlertMessage;
      return;
    end


  end

  -----------------------------------------------------------------------------------------------------------------
  --Final Select to UI to return default GO, when all above Validation steps pass.
  -----------------------------------------------------------------------------------------------------------------
  select  @LI_UIIntiateCreditFlag    as UIIntiateCreditFlag
         ,@LVC_UIStopAlertMessage    as UIStopAlertMessage;
END ----> Main END
GO
