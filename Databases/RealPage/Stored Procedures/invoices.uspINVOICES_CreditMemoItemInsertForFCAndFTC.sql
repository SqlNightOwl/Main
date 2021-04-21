SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_CreditMemoItemInsertForFCAndFTC
-- PreRequisites   : Invoices.dbo.uspINVOICES_InvoiceItemSelect call would have returned rowset to UI modal.
/*
--PreRequisites Syntax Call to populate UI Modal
Exec Invoices.dbo.uspINVOICES_InvoiceItemSelect 'I0901011189','FullCredit'
Exec Invoices.dbo.uspINVOICES_InvoiceItemSelect 'I0901011189','TaxCredit'
*/

-- Description     : This procedure gets Called ONLY Once Upon Button Click "Send for Approval" from credit Modal in UI.
--                   For Full credit Scenaro or Full Tax Credit Scenario
-- Input Parameters: @IPVC_CreditType      as varchar(50),@IPVC_InvoiceIDSeq Varchar(50)
-- Syntax          : 
/*
EXEC INVOICES.dbo.uspINVOICES_CreditMemoItemInsertForFCAndFTC  @IPVC_CreditType='FullCredit',@IPVC_InvoiceIDSeq = 'I0901011189'
EXEC INVOICES.dbo.uspINVOICES_CreditMemoItemInsertForFCAndFTC  @IPVC_CreditType='TaxCredit',@IPVC_InvoiceIDSeq = 'I0901011189'
*/
-- Revision History:
-- Author          : Surya Kondapalli : Task # 918: Issue with the Credit Memo tab when full tax credit has been applied
-- 08/25/2011      : SRS (Defect 918) Code review and minor related enhancements
-----------------------------------------------------------------------------------------------------------------------------
Create Procedure [invoices].[uspINVOICES_CreditMemoItemInsertForFCAndFTC] (@IPVC_CreditType    varchar(50),  --> Mandatory : This is the Credit Type. 
                                                                                                        --> For this proc, only FullCredit or TaxCredit are acceptable values.
                                                                      @IPVC_InvoiceIDSeq  varchar(50),  --> Mandatory : This is the InvoiceIDSeq for which FullCredit or TaxCredit are intiated by User.
                                                                      @IPBI_UserIDSeq     bigint = -1   --> Mandatory : This is userID of the Person initiating this credit operation from UI.
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
  and    CM.CreditTypeCode = (Case when (@IPVC_CreditType = 'FullCredit') 
                                     then 'FULC'
                                   when (@IPVC_CreditType = 'TaxCredit' or @IPVC_CreditType = 'FullTax') 
                                     then 'TAXC'
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
    select @LVC_CodeSection = 'Proc:uspINVOICES_CreditMemoItemInsertForFCAndFTC-Invoice : ' + @IPVC_InvoiceIDSeq + ' CreditType ' + @IPVC_CreditType + 
                              ' System failed to identify Pending Approval CreditMemoIDSeq to complete CreditMemoItem Insert Operation.'
    EXEC CUSTOMERS.dbo.uspCUSTOMERS_RaiseError @IPVC_CodeSection = @LVC_CodeSection;
    Return;
  end;    
  -----------------------------------------------------------------------------------------------------------------
  --Step 3: Insert for CreditMemoItem for FullCredit Scenario.
  -- Business Logic : identify all corresponding InvoiceItems based on input parameters and just to 
  --     copy over other attributes along with Netchargeamount,SHAmount,TaxAmount,Distribution into creditmemoitem table, 
  --     since this is Full Credit operation.
  -- NO TAXWARE CALLS are MADE for FULL CREDIT OPERATION by UI, after this Insert operation.
  -----------------------------------------------------------------------------------------------------------------
  If (@IPVC_CreditType = 'FullCredit')
  begin   
    ---FullCredit
    declare @LI_PartialCreditIndicator  int;
    select  @LI_PartialCreditIndicator = 0;

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
    select @LI_PartialCreditIndicator = 1 
    where exists (select top 1 1
                  from   CTE_PreviousApprovedCMI CTE_PACMI
                  where  (CTE_PACMI.NetCreditAmount    > 0
                           OR
                          CTE_PACMI.NetCreditTaxAmount > 0
                         )
                  );
    ------------------------------------------------------------------------------------------------------------------------------------
    ---NOTE : A Full Credit will ONLY Continue to remain as Full Credit Type, 
    --          if and only when at the time of initiating this type of Full Credit, 
    --          The Entire and Exact Net($) and Tax($) of all the corresponding Invoiceitem(s) are available  either as first User event action 
    --          OR 
    --          in any Nth User event action when all prior Full Tax Credit or Partial Credits were reversed.
    ------------------------------------------------------------------------------------------------------------------------------------
    --->This below update is very important to keep this type of Credit Memo that is initiated by Full Credit Event by user 
    --  as a Partial Credit with all the remaining net($) and Tax($) credited back and open to the distinct possibility that 
    --  any of the prior approved creditmemos of this Invoice could be Reversed and that this pending Invoice will have to
    --  undergo Taxware call tax calculation again at approval or during revise operation to take into account any additional tax($) that may
    --  also need to be accurately credited back.

    --  OMS system Will not and should not second guess what the remaing Tax($) and Tax distribution based on should be credited back
    --  ANY internal MATH , but leave it to Taxware call return to determine that.
    -------------------------------------------------------------------
    if (@LI_PartialCreditIndicator > 0)
    begin      
      Update Invoices.dbo.CreditMemo 
      set    CreditTypeCode = 'PARC'
      where  CreditMemoIDSeq= @LVC_CreditMemoIDSeq;
    end;
    ------------------------------------------------------------------------------------------------------------------------------------
    ;With CTE_PreviousApprovedCMI (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                                   NetCreditAmount,NetCreditTaxAmount,ShippingAndHandlingCreditAmount
                                  )
        as (select CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag,
                   Sum(CMI.NetCreditAmount)                    as NetCreditAmount,
                   Sum(CMI.TaxAmount)                          as NetCreditTaxAmount,
                   sum(CMI.ShippingAndHandlingCreditAmount)    as ShippingAndHandlingCreditAmount
            from   INVOICES.dbo.CreditMemo     CM with (nolock)
            inner Join
                   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            on     CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq
            and    CM.InvoiceIDSeq    = CMI.InvoiceIDSeq
            and    CM.InvoiceIDSeq    = @IPVC_InvoiceIDSeq
            and    CM.CreditStatusCode= 'APPR'
            group by CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag
           ) 
    Insert into Invoices.dbo.CreditMemoItem
                (CreditMemoIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,CustomBundleNameEnabledFlag,InvoiceItemIdSeq,
                 UnitCreditAmount,EffectiveQuantity,ExtCreditAmount,DiscountCreditAmount,
                 NetCreditAmount,ShippingAndHandlingCreditAmount,
                 TaxPercent,TaxAmount,
                 RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,
                 RevenueRecognitionCode,TaxwareCode,DefaultTaxwareCode,
                 TaxwarePrimaryStateTaxPercent,TaxwarePrimaryStateTaxAmount,
                 TaxwareSecondaryStateTaxPercent,TaxwareSecondaryStateTaxAmount,TaxwarePrimaryCityTaxPercent,TaxwarePrimaryCityTaxAmount,
                 TaxwareSecondaryCityTaxPercent,TaxwareSecondaryCityTaxAmount,TaxwarePrimaryCountyTaxPercent,
                 TaxwarePrimaryCountyTaxAmount,TaxwareSecondaryCountyTaxPercent,TaxwareSecondaryCountyTaxAmount,
                 TaxwarePrimaryStateTaxBasisAmount,TaxwareSecondaryStateTaxBasisAmount,TaxwarePrimaryCityTaxBasisAmount,
                 TaxwareSecondaryCityTaxBasisAmount,TaxwarePrimaryCountyTaxBasisAmount,TaxwareSecondaryCountyTaxBasisAmount,
                 TaxwareGSTCountryTaxAmount,TaxwareGSTCountryTaxPercent,	
                 TaxwarePSTStateTaxAmount,TaxwarePSTStateTaxPercent, 
                 TaxwarePrimaryStateJurisdictionZipCode,TaxwareSecondaryStateJurisdictionZipCode,TaxwarePrimaryCityJurisdiction,
                 TaxwareSecondaryCityJurisdiction,TaxwarePrimaryCountyJurisdiction,TaxwareSecondaryCountyJurisdiction,
                 TaxwareCallOverrideFlag                 
                 ,CreatedByIDSeq,CreatedDate,SystemLogDate
                )
    select  @LVC_CreditMemoIDSeq as CreditMemoIDSeq,@IPVC_InvoiceIDSeq as InvoiceIDSeq,II.InvoiceGroupIDSeq,IG.CustomBundleNameEnabledFlag,II.IDSeq as InvoiceItemIdSeq,            
            (II.NetChargeAmount - coalesce(CTE_PACMI.NetCreditAmount,0))   as UnitCreditAmount,
            1                                                              as EffectiveQuantity,
            (II.NetChargeAmount - coalesce(CTE_PACMI.NetCreditAmount,0))   as ExtCreditAmount,
            0.00                                                           as DiscountCreditAmount,
            (II.NetChargeAmount - coalesce(CTE_PACMI.NetCreditAmount,0))   as NetCreditAmount,
            (II.ShippingAndHandlingAmount - coalesce(CTE_PACMI.ShippingAndHandlingCreditAmount,0)) 
                                                                           as ShippingAndHandlingCreditAmount,
            II.TaxPercent                                                  as TaxPercent,
            (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))      as TaxAmount,
            --------------------------            
            II.RevenueTierCode,II.RevenueAccountCode,II.DeferredRevenueAccountCode,
            II.RevenueRecognitionCode,II.TaxwareCode,II.DefaultTaxwareCode,
            --------------------------
            II.TaxwarePrimaryStateTaxPercent                               as TaxwarePrimaryStateTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryStateTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwarePrimaryStateTaxAmount,
            II.TaxwareSecondaryStateTaxPercent                            as TaxwareSecondaryStateTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryStateTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwareSecondaryStateTaxAmount,
            II.TaxwarePrimaryCityTaxPercent                               as TaxwarePrimaryCityTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryCityTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwarePrimaryCityTaxAmount,
            II.TaxwareSecondaryCityTaxPercent                             as TaxwareSecondaryCityTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryCityTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwareSecondaryCityTaxAmount,
            II.TaxwarePrimaryCountyTaxPercent                             as TaxwarePrimaryCountyTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryCountyTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwarePrimaryCountyTaxAmount,
            II.TaxwareSecondaryCountyTaxPercent                           as TaxwareSecondaryCountyTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryCountyTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwareSecondaryCountyTaxAmount,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryStateTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwarePrimaryStateTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryStateTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwareSecondaryStateTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryCityTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwarePrimaryCityTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryCityTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwareSecondaryCityTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryCountyTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwarePrimaryCountyTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryCountyTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwareSecondaryCountyTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwareGSTCountryTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwareGSTCountryTaxAmount,
            II.TaxwareGSTCountryTaxPercent                               as TaxwareGSTCountryTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwarePSTStateTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwarePSTStateTaxAmount,
            II.TaxwarePSTStateTaxPercent                                 as TaxwarePSTStateTaxPercent,
            ----------------------------------------
            II.TaxwarePrimaryStateJurisdictionZipCode,II.TaxwareSecondaryStateJurisdictionZipCode,
            II.TaxwarePrimaryCityJurisdiction,II.TaxwareSecondaryCityJurisdiction,II.TaxwarePrimaryCountyJurisdiction,
            II.TaxwareSecondaryCountyJurisdiction,II.TaxwareCallOverrideFlag
            --------------------------            
            ,@IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
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
    and    CTE_PACMI.InvoiceIDSeq = @IPVC_InvoiceIDSeq 
    where   II.InvoiceIDSeq       = @IPVC_InvoiceIDSeq
    and     IG.InvoiceIDSeq       = @IPVC_InvoiceIDSeq
    and     Not exists (select Top 1 1
                        from   Invoices.dbo.CreditMemoItem CMI with (nolock)
                        where  CMI.CreditMemoIDSeq    = @LVC_CreditMemoIDSeq
                        and    CMI.InvoiceIDSeq       = @IPVC_InvoiceIDSeq
                        and    CMI.InvoiceGroupIDSeq  = II.InvoiceGroupIDSeq                       
                        and    CMI.InvoiceItemIdSeq   = II.IDSeq
                        and    CMI.CustomBundleNameEnabledFlag = IG.CustomBundleNameEnabledFlag
                       )
    and     (
              
              (II.NetChargeAmount - coalesce(CTE_PACMI.NetCreditAmount,0)) > 0  ---> Criteria for Full Credit  
            )
    order by II.InvoiceGroupIDSeq ASC,II.IDSeq ASC;
    -----------------------------------------------------------------------
    Exec Invoices.dbo.[uspCredits_SyncCreditTaxAmount] @IPVC_CreditMemoIDSeq = @LVC_CreditMemoIDSeq;
    -----------------------------------------------------------------------
    return;
  end
  -----------------------------------------------------------------------------------------------------------------
  --Step 4: Insert for CreditMemoItem for Full Tax Credit Scenario.
  -- Business Logic : identify all corresponding InvoiceItems based on input parameters and just to 
  --     copy over  other attributes along with ONLY TaxAmount,Distribution into creditmemoitem table, 
  --     since this is Full Tax Credit operation. 
  --     ChargeAmount,ExtChargeAmount,DiscountAmount,NetChargeAmount will all come over as default 0.00
  --     since this is Full Tax Credit operation
  -- NO TAXWARE CALLS are MADE for FULL CREDIT OPERATION by UI, after this Insert operation.
  -----------------------------------------------------------------------------------------------------------------
  else if (@IPVC_CreditType='TaxCredit' or @IPVC_CreditType = 'FullTax')
  begin
    ---TaxCredit
    ;With CTE_PreviousApprovedCMI (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,CustomBundleNameEnabledFlag,
                                   NetCreditAmount,NetCreditTaxAmount,ShippingAndHandlingCreditAmount
                                  )
        as (select CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag,
                   Sum(CMI.NetCreditAmount)                    as NetCreditAmount,
                   Sum(CMI.TaxAmount)                          as NetCreditTaxAmount,
                   sum(CMI.ShippingAndHandlingCreditAmount)    as ShippingAndHandlingCreditAmount
            from   INVOICES.dbo.CreditMemo     CM with (nolock)
            inner Join
                   INVOICES.dbo.CreditMemoItem CMI with (nolock)
            on     CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq
            and    CM.InvoiceIDSeq    = CMI.InvoiceIDSeq
            and    CM.InvoiceIDSeq    = @IPVC_InvoiceIDSeq
            and    CM.CreditStatusCode= 'APPR'
            group by CMI.InvoiceIDSeq,CMI.InvoiceGroupIDSeq,CMI.InvoiceItemIDSeq,CMI.CustomBundleNameEnabledFlag
           ) 
    Insert into Invoices.dbo.CreditMemoItem
                (CreditMemoIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,CustomBundleNameEnabledFlag,InvoiceItemIdSeq,
                 UnitCreditAmount,EffectiveQuantity,ExtCreditAmount,DiscountCreditAmount,
                 NetCreditAmount,ShippingAndHandlingCreditAmount,
                 TaxPercent,TaxAmount,
                 RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,
                 RevenueRecognitionCode,TaxwareCode,DefaultTaxwareCode,
                 TaxwarePrimaryStateTaxPercent,TaxwarePrimaryStateTaxAmount,
                 TaxwareSecondaryStateTaxPercent,TaxwareSecondaryStateTaxAmount,TaxwarePrimaryCityTaxPercent,TaxwarePrimaryCityTaxAmount,
                 TaxwareSecondaryCityTaxPercent,TaxwareSecondaryCityTaxAmount,TaxwarePrimaryCountyTaxPercent,
                 TaxwarePrimaryCountyTaxAmount,TaxwareSecondaryCountyTaxPercent,TaxwareSecondaryCountyTaxAmount,
                 TaxwarePrimaryStateTaxBasisAmount,TaxwareSecondaryStateTaxBasisAmount,TaxwarePrimaryCityTaxBasisAmount,
                 TaxwareSecondaryCityTaxBasisAmount,TaxwarePrimaryCountyTaxBasisAmount,TaxwareSecondaryCountyTaxBasisAmount,
                 TaxwareGSTCountryTaxAmount,TaxwareGSTCountryTaxPercent,	
                 TaxwarePSTStateTaxAmount,TaxwarePSTStateTaxPercent, 
                 TaxwarePrimaryStateJurisdictionZipCode,TaxwareSecondaryStateJurisdictionZipCode,TaxwarePrimaryCityJurisdiction,
                 TaxwareSecondaryCityJurisdiction,TaxwarePrimaryCountyJurisdiction,TaxwareSecondaryCountyJurisdiction,
                 TaxwareCallOverrideFlag                 
                 ,CreatedByIDSeq,CreatedDate,SystemLogDate
                )
    select  @LVC_CreditMemoIDSeq as CreditMemoIDSeq,@IPVC_InvoiceIDSeq as InvoiceIDSeq,II.InvoiceGroupIDSeq,IG.CustomBundleNameEnabledFlag,II.IDSeq as InvoiceItemIdSeq,            
            0.00                                                         as UnitCreditAmount,
            1                                                            as EffectiveQuantity,
            0.00                                                         as ExtCreditAmount,
            0.00                                                         as DiscountCreditAmount,
            0.00                                                         as NetCreditAmount,
            0.00                                                         as ShippingAndHandlingCreditAmount,
            II.TaxPercent                                                as TaxPercent,
            (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))    as TaxAmount,
            --------------------------
            II.RevenueTierCode,II.RevenueAccountCode,II.DeferredRevenueAccountCode,
            II.RevenueRecognitionCode,II.TaxwareCode,II.DefaultTaxwareCode,
            --------------------------
            II.TaxwarePrimaryStateTaxPercent                              as TaxwarePrimaryStateTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryStateTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwarePrimaryStateTaxAmount,
            II.TaxwareSecondaryStateTaxPercent                            as TaxwareSecondaryStateTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryStateTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwareSecondaryStateTaxAmount,
            II.TaxwarePrimaryCityTaxPercent                               as TaxwarePrimaryCityTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryCityTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwarePrimaryCityTaxAmount,
            II.TaxwareSecondaryCityTaxPercent                             as TaxwareSecondaryCityTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryCityTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwareSecondaryCityTaxAmount,
            II.TaxwarePrimaryCountyTaxPercent                             as TaxwarePrimaryCountyTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryCountyTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwarePrimaryCountyTaxAmount,
            II.TaxwareSecondaryCountyTaxPercent                           as TaxwareSecondaryCountyTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryCountyTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwareSecondaryCountyTaxAmount,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryStateTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                     as TaxwarePrimaryStateTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryStateTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwareSecondaryStateTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryCityTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwarePrimaryCityTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryCityTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwareSecondaryCityTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwarePrimaryCountyTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwarePrimaryCountyTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwareSecondaryCountyTaxBasisAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwareSecondaryCountyTaxBasisAmount,
            Convert(money,
                         (convert(float,II.TaxwareGSTCountryTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwareGSTCountryTaxAmount,
            II.TaxwareGSTCountryTaxPercent                               as TaxwareGSTCountryTaxPercent,
            Convert(money,
                         (convert(float,II.TaxwarePSTStateTaxAmount)
                           /
                          convert(float,(case when II.TaxAmount = 0 then 1 else II.TaxAmount end))
                         ) * (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))
                    )                                                    as TaxwarePSTStateTaxAmount,
            II.TaxwarePSTStateTaxPercent                                 as TaxwarePSTStateTaxPercent,
            ----------------------------------------
            II.TaxwarePrimaryStateJurisdictionZipCode,II.TaxwareSecondaryStateJurisdictionZipCode,
            II.TaxwarePrimaryCityJurisdiction,II.TaxwareSecondaryCityJurisdiction,II.TaxwarePrimaryCountyJurisdiction,
            II.TaxwareSecondaryCountyJurisdiction,II.TaxwareCallOverrideFlag                      
            ,@IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate	
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
    and     Not exists (select Top 1 1
                        from   Invoices.dbo.CreditMemoItem CMI with (nolock)
                        where  CMI.CreditMemoIDSeq    = @LVC_CreditMemoIDSeq
                        and    CMI.InvoiceIDSeq       = @IPVC_InvoiceIDSeq
                        and    CMI.InvoiceGroupIDSeq  = II.InvoiceGroupIDSeq                       
                        and    CMI.InvoiceItemIdSeq   = II.IDSeq
                        and    CMI.CustomBundleNameEnabledFlag = IG.CustomBundleNameEnabledFlag
                       )
    and     (
              (II.TaxAmount - coalesce(CTE_PACMI.NetCreditTaxAmount,0))    > 0  ---> Criteria for Full Tax Credit                   
            )
    order by II.InvoiceGroupIDSeq ASC,II.IDSeq ASC;
    -----------------------------------------------------------------------
    Exec Invoices.dbo.[uspCredits_SyncCreditTaxAmount] @IPVC_CreditMemoIDSeq = @LVC_CreditMemoIDSeq;
    -----------------------------------------------------------------------
    return;
  end
  -----------------------------------------------------------------------------------------------------------------
END ----> Main END
GO
