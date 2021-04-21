SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_OrderItemDoRollback]
-- Description     : This procedure does the actual Rollback of orderitem
--                   after call of Exec Orders.dbo.[uspORDERS_EligibilityCheckForOrderItemRollback] Parameters
--                   establishes eligibility for Rollback.
--@IPVC_RollbackReasonCode = Exec ORDERS.dbo.uspORDERS_GetReasonForCategory @IPVC_CategoryCode = 'RFUL', @IPI_ShowAllFlag = 0   
--@IPVC_RollbackReasonCode = Exec ORDERS.dbo.uspORDERS_GetReasonForCategory @IPVC_CategoryCode = 'RCAN', @IPI_ShowAllFlag = 0   
-- OUTPUT          : None
--
-- Code Example    : Exec Orders.dbo.[uspORDERS_OrderItemDoRollback] Parameters
-- Revision History:
-- Author          : SRS
-- 2010-10-21      : Stored Procedure Created.Defect 7745
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_OrderItemDoRollback] (@IPVC_Orderidseq                varchar(50),        ---> This is the Orderidseq of the Current Orderitem. UI knows this already                                                                         
                                                        @IPVC_OrderGroupIDSeq           varchar(50),        ---> This is the OrderGroupIDSeq of the Current Orderitem. UI knows this already
                                                        @IPVC_OrderItemIDSeq            varchar(50)=null,   ---> This is the OrderItemIDSeq of the Current Orderitem. UI knows this already
                                                                                                            ---     This will be NULL for CustomBundles ie PreconfiguredBundleFlag = 1
                                                        @IPVC_ChargeTypeCode            varchar(3),         ---> This is the ChargeTypeCode of the Current Orderitem. UI knows this already
                                                        @IPI_CustomBundleFlag           int,                ---> This is the custombundleFlag ie IsCustomPackage of the Current Orderitem. UI knows this already
                                                                                                            ---     0 means it is Alacarte and not part of Custom Bundle. 1 means it is part of Custom Bundle. This is PreconfiguredBundleFlag                                                                        
                                                        @IPI_RenewalCount               int= 0,             ---> This is renewal count number of the current Orderitem. UI knows this already. 
                                                        @IPVC_RollbackReasonCode        varchar(10),        ---> This is the code corresponding to Rollback Reasoncode code drop down user selection. Exec ORDERS.dbo.uspORDERS_GetReasonForCategory @IPVC_CategoryCode = 'RFUL', @IPI_ShowAllFlag = 0   
                                                        @IPBI_UserIDSeq                 bigint              ---> This is UserID of person logged on (Mandatory)                                        
                                                       )

AS
BEGIN --->Main Begin
  set nocount on;
  ----------------------------------------------------------------------------------
  ---Declare Local variables.
  Declare @LXML_OIRBEligibility           xml,
          @LI_EligibilityFlag             int,
          @LI_HigherRenewalExists         int

  declare @LVC_CodeSection                varchar(1000)

  Declare @LVC_AccountIDSeq               varchar(50),
          @LVC_CompanyIDSeq               varchar(50),
          @LVC_PropertyIDSeq              varchar(50),
          @LVC_ProductCode                varchar(50),
          @LVC_MeasureCode                varchar(20),
          @LVC_FrequencyCode              varchar(20),
          @LVC_ReportingTypeCode          varchar(20),          
          @LVC_StatusCode                 varchar(20),
          @LVC_RenewedFromOrderitemIDSeq  varchar(50),
          @LDT_StartDate                  datetime,
          @LDT_EndDate                    datetime,
          @LDT_CancelDate                 datetime,
          @LDT_LastBillFromDate           datetime,
          @LDT_LastBillToDate             datetime,
          @LDT_POILastBillFromDate        datetime,
          @LDT_POILastBillToDate          datetime  
  ----------------------------------------------------------------------------------
  declare @LDT_SystemDate        datetime;
  select  @LDT_SystemDate        = getdate()

  select @IPVC_OrderItemIDSeq = (case when @IPI_CustomBundleFlag=1 then NULL else nullif(@IPVC_OrderItemIDSeq,'') end),
         @LI_HigherRenewalExists = 0,@LI_EligibilityFlag=0
  ----------------------------------------------------------------------------------
  --Step 1 : Intial sanity check to see if the Orderitem is still eligible for rollback.  
  exec ORDERS.dbo.uspORDERS_EligibilityCheckForOrderItemRollback     @IPVC_Orderidseq       =@IPVC_Orderidseq,
                                                                     @IPVC_OrderGroupIDSeq  =@IPVC_OrderGroupIDSeq,
                                                                     @IPVC_OrderItemIDSeq   =@IPVC_OrderItemIDSeq,
                                                                     @IPVC_ChargeTypeCode   =@IPVC_ChargeTypeCode,
                                                                     @IPI_CustomBundleFlag  =@IPI_CustomBundleFlag, 
                                                                     @IPI_RenewalCount      =@IPI_RenewalCount,
                                                                     @IPBI_UserIDSeq        =@IPBI_UserIDSeq,
                                                                     @OPXML_OIRBEligibility =@LXML_OIRBEligibility OUTPUT;

  select @LI_EligibilityFlag = convert(varchar(10),EXD.NewDataSet.query('data(eligibilityflag)'))
  from   @LXML_OIRBEligibility.nodes('root') as EXD(NewDataSet)

  if (@LI_EligibilityFlag=0)
  begin
    ------------------------      
    select @LVC_CodeSection =  'Proc: uspORDERS_OrderItemDoRollback;This Orderitem has lost its eligibility for Rollback at the current moment --> OrderID: '+ @IPVC_Orderidseq
    ------------------------    
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  ----------------------------------------------------------------------------------
  select Top 1 @LVC_AccountIDSeq             = O.AccountIDSeq,
               @LVC_CompanyIDSeq             = O.CompanyIDSeq, 
               @LVC_PropertyIDSeq            = NullIf(O.PropertyIDSeq,''),
               @LVC_ProductCode              = (case when @IPI_CustomBundleFlag=1 then NULL else OI.ProductCode end),
               @LVC_MeasureCode              = OI.MeasureCode,
               @LVC_FrequencyCode            = OI.FrequencyCode,
               @LVC_ReportingTypeCode        = OI.ReportingTypeCode,
               @LVC_RenewedFromOrderitemIDSeq= OI.RenewedFromOrderitemIDSeq,               
               @LVC_StatusCode               = OI.StatusCode,
               @LDT_StartDate                = OI.StartDate,
               @LDT_EndDate                  = OI.EndDate,
               @LDT_CancelDate               = OI.CancelDate,
               @LDT_LastBillFromDate         = OI.LastBillingPeriodFromDate,
               @LDT_LastBillToDate           = OI.LastBillingPeriodToDate,
               @LDT_POILastBillFromDate      = OI.POILastBillingPeriodFromDate,
               @LDT_POILastBillToDate        = OI.POILastBillingPeriodToDate
  from   ORDERS.dbo.[Order] O with (nolock)
  inner join
         ORDERS.dbo.[Orderitem] OI with (nolock)
  on     O.Orderidseq       = OI.Orderidseq
  and    O.Orderidseq       = @IPVC_Orderidseq
  and    OI.Orderidseq      = @IPVC_Orderidseq
  and    OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
  and    ((@IPI_CustomBundleFlag = 1)
            OR
          (OI.IDSeq = @IPVC_OrderItemIDSeq and @IPI_CustomBundleFlag = 0)
         )   
  and    OI.ChargeTypeCode  = @IPVC_ChargeTypeCode
  and    OI.RenewalCount    = @IPI_RenewalCount
  ------------------------------------------------
  if exists (select top 1 1 
             from   ORDERS.dbo.[Orderitem] OI with (nolock)
             where  OI.Orderidseq       = @IPVC_Orderidseq
             and    OI.OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq
             and    OI.Productcode      = coalesce(@LVC_ProductCode,OI.Productcode)
             and    OI.ChargeTypeCode   = 'ACS'
             and    OI.ReportingTypeCode= 'ACSF'
             and    ((@IPI_CustomBundleFlag = 1)
                       OR
                     ((OI.RenewedFromOrderitemIDSeq = @IPVC_OrderItemIDSeq OR OI.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0)            
                    )   
             and    OI.ChargeTypeCode  = @IPVC_ChargeTypeCode
             and    OI.RenewalCount    > @IPI_RenewalCount
           )
  begin
    select @LI_HigherRenewalExists = 1
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 0 : Scenario 0 
  ---------->Rollback of fulfilled ACS Subscription back to pending
  ---------->Rollback of fulfilled Ancillary back to pending (including Tran Enabler Orderitem)
  ---------->Rollback of fulfilled ILF  back to pending
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'FULF' and isdate(@LDT_StartDate) = 1 and isdate(@LDT_POILastBillToDate) = 0)
  begin
    BEGIN TRY
      Exec INVOICES.dbo.uspINVOICES_RollBackInvoice @IPVC_Orderid          = @IPVC_Orderidseq,
                                                    @IPBI_OrderGroupID     = @IPVC_OrderGroupIDSeq,
                                                    @IPVC_OrderItemIDSeq   = @IPVC_OrderItemIDSeq,
                                                    @IPI_IsCustomBundle    = @IPI_CustomBundleFlag,                                                     
                                                    @IPVC_ProductCode      = @LVC_ProductCode,
                                                    @IPVC_ChargeTypeCode   = @IPVC_ChargeTypeCode,
                                                    @IPBI_UserIDSeq        = @IPBI_UserIDSeq;  


      Update OI
      set    OI.StatusCode           = 'PEND',
             OI.ActivationStartDate  = NULL,
             OI.ActivationEndDate    = NULL,
             OI.ILFStartDate         = NULL,
             OI.ILFEndDate           = NULL,
             OI.StartDate            = NULL,
             OI.EndDate              = NULL,
             OI.LastBillingPeriodFromDate = NULL,
             OI.LastBillingPeriodToDate   = NULL,
             ------------------------------------------
             OI.RenewalTypeCode      = (case when (OI.FrequencyCode = 'OT' or OI.FrequencyCode = 'SG' or @LI_HigherRenewalExists = 1) then 'DRNW' else 'ARNW' end),
             OI.RenewalReviewedFlag  = 0,
             OI.RenewalFlag          = 0,             
             OI.RenewalUserOverrideFlag=0,
             OI.RenewalAdjustedChargeAmount=NULL,
             OI.RenewalStartDate     = NULL,
             OI.RenewedByUserIDSeq   = NULL,
             OI.RenewalNotes         = NULL,
             OI.RenewalReviewedDate  = NULL,
             ------------------------------------------
             OI.CancelDate           = NULL,
             OI.CancelReasonCode     = NULL,
             OI.CancelNotes          = NULL,
             OI.CancelByIDSeq        = NULL,
             OI.CancelActivityDate   = NULL,
             ------------------------------------------
             OI.FulfilledByIDSeq     = NULL,
             OI.FulfilledDate        = NULL,
             ------------------------------------------
             OI.HistoryFlag          = 0, 
             OI.HistoryDate          = NULL,
             ------------------------------------------
             OI.RollbackReasonCode   = @IPVC_RollbackReasonCode,
             OI.RollbackByIDSeq      = @IPBI_UserIDSeq,
             OI.RollbackDate         = @LDT_SystemDate,
             ------------------------------------------
             OI.ModifiedByUserIDSeq  = @IPBI_UserIDSeq,
             OI.ModifiedDate         = @LDT_SystemDate,
             OI.SystemLogDate        = @LDT_SystemDate
             ------------------------------------------
      from   ORDERS.dbo.[Orderitem] OI with (nolock)
      where  OI.Orderidseq       = @IPVC_Orderidseq
      and    OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
      and   ((@IPI_CustomBundleFlag = 1)
                  OR
             ((OI.IDSeq = @IPVC_OrderItemIDSeq OR OI.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and OI.FrequencyCode <> 'OT')
                  OR
             ((OI.IDSeq = @IPVC_OrderItemIDSeq and OI.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and OI.FrequencyCode = 'OT')
            )   
      and    OI.ChargeTypeCode  = @IPVC_ChargeTypeCode
      and    OI.MeasureCode     = @LVC_MeasureCode
      and    OI.FrequencyCode   = @LVC_FrequencyCode
      and    OI.RenewalCount    = @IPI_RenewalCount
      and    OI.StatusCode      = @LVC_StatusCode
      and    isdate(OI.StartDate) = 1
      and    isdate(OI.POILastBillingPeriodToDate) = 0
    END TRY
    BEGIN CATCH
      ------------------------      
      select @LVC_CodeSection =  'Proc: uspORDERS_OrderItemDoRollback;Error Rolling back OrderItem from Fulfilled State back to Pending--> OrderID: '+ @IPVC_Orderidseq
      ------------------------    
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
      return;                  
    END CATCH;
    return
  end
  -------------------------------------
  ---- This will take care of SiteTransfer or Reprice Orders, where POILastBillingPeriodToDate is set at the time of fulfilment.
  if (@LVC_StatusCode = 'FULF' and isdate(@LDT_StartDate) = 1)
  begin
    if not exists (select top 1 1
                   From  Invoices.dbo.Invoice  I with (nolock)
                   inner join
                         Invoices.dbo.Invoiceitem II with (nolock)
                   on    I.InvoiceIDSeq = II.InvoiceIDSeq
                   and   II.Orderidseq      = @IPVC_Orderidseq
                   and   II.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
                   and    ((@IPI_CustomBundleFlag = 1)
                               OR
                           ((II.OrderItemIDSeq = @IPVC_OrderItemIDSeq OR II.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and II.FrequencyCode <> 'OT') 
                               OR
                           ((II.OrderItemIDSeq = @IPVC_OrderItemIDSeq AND II.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and II.FrequencyCode = 'OT')         
                          )   
                   and    II.ChargeTypeCode  = @IPVC_ChargeTypeCode
                   and    II.MeasureCode     = @LVC_MeasureCode
                   and    II.FrequencyCode   = @LVC_FrequencyCode
                   and    I.Printflag = 1
                  )
    begin
      BEGIN TRY
        Exec INVOICES.dbo.uspINVOICES_RollBackInvoice @IPVC_Orderid          = @IPVC_Orderidseq,
                                                      @IPBI_OrderGroupID     = @IPVC_OrderGroupIDSeq,
                                                      @IPVC_OrderItemIDSeq   = @IPVC_OrderItemIDSeq,
                                                      @IPI_IsCustomBundle    = @IPI_CustomBundleFlag,                                                       
                                                      @IPVC_ProductCode      = @LVC_ProductCode,
                                                      @IPVC_ChargeTypeCode   = @IPVC_ChargeTypeCode,
                                                      @IPBI_UserIDSeq        = @IPBI_UserIDSeq;  


        Update OI
        set    OI.StatusCode           = 'PEND',
               OI.ActivationStartDate  = NULL,
               OI.ActivationEndDate    = NULL,
               OI.ILFStartDate         = NULL,
               OI.ILFEndDate           = NULL,
               OI.StartDate            = NULL,
               OI.EndDate              = NULL,
               OI.LastBillingPeriodFromDate = NULL,
               OI.LastBillingPeriodToDate   = NULL,
               ------------------------------------------
               OI.RenewalTypeCode      = (case when (OI.FrequencyCode = 'OT' or OI.FrequencyCode = 'SG' or @LI_HigherRenewalExists = 1) then 'DRNW' else 'ARNW' end),
               OI.RenewalReviewedFlag  = 0,
               OI.RenewalFlag          = 0,
               OI.RenewalUserOverrideFlag=0,
               OI.RenewalAdjustedChargeAmount=NULL,
               OI.RenewalStartDate     = NULL,
               OI.RenewedByUserIDSeq   = NULL,
               OI.RenewalNotes         = NULL,
               OI.RenewalReviewedDate  = NULL,
               ------------------------------------------
               OI.CancelDate           = NULL,
               OI.CancelReasonCode     = NULL,
               OI.CancelNotes          = NULL,
               OI.CancelByIDSeq        = NULL,
               OI.CancelActivityDate   = NULL,
               ------------------------------------------
               OI.FulfilledByIDSeq     = NULL,
               OI.FulfilledDate        = NULL,
               ------------------------------------------
               OI.HistoryFlag          = 0, 
               OI.HistoryDate          = NULL,
               ------------------------------------------
               OI.RollbackReasonCode   = @IPVC_RollbackReasonCode,
               OI.RollbackByIDSeq      = @IPBI_UserIDSeq,
               OI.RollbackDate         = @LDT_SystemDate,
               ------------------------------------------
               OI.ModifiedByUserIDSeq  = @IPBI_UserIDSeq,
               OI.ModifiedDate         = @LDT_SystemDate,
               OI.SystemLogDate        = @LDT_SystemDate
               ------------------------------------------
        from   ORDERS.dbo.[Orderitem] OI with (nolock)
        where  OI.Orderidseq       = @IPVC_Orderidseq
        and    OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
        and   ((@IPI_CustomBundleFlag = 1)
                  OR
               ((OI.IDSeq = @IPVC_OrderItemIDSeq OR OI.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and OI.FrequencyCode <> 'OT')
                  OR
               ((OI.IDSeq = @IPVC_OrderItemIDSeq and OI.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and OI.FrequencyCode = 'OT')
              )    
        and    OI.ChargeTypeCode  = @IPVC_ChargeTypeCode
        and    OI.MeasureCode     = @LVC_MeasureCode
        and    OI.FrequencyCode   = @LVC_FrequencyCode
        and    OI.RenewalCount    = @IPI_RenewalCount
        and    OI.StatusCode      = @LVC_StatusCode
        and    isdate(OI.StartDate) = 1        
      END TRY
      BEGIN CATCH
        ------------------------      
        select @LVC_CodeSection =  'Proc: uspORDERS_OrderItemDoRollback;Error Rolling back OrderItem from Fulfilled State back to Pending--> OrderID: '+ @IPVC_Orderidseq
        ------------------------    
        Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
        return;                  
      END CATCH;
      return
    end
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 1 :  Scenario 1 
  ---------->Rollback of cancelled ACS Subscription back to pending, when cancelled before activation.
  ---------->Rollback of Cancelled Ancillary back to pending (including Tran Enabler Orderitem)
  ---------->Rollback of cancelled ILF back to pending, when cancelled before activation.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'CNCL' and isdate(@LDT_StartDate) = 0 and isdate(@LDT_POILastBillToDate) = 0)
  begin
    BEGIN TRY
      Exec INVOICES.dbo.uspINVOICES_RollBackInvoice @IPVC_Orderid          = @IPVC_Orderidseq,
                                                    @IPBI_OrderGroupID     = @IPVC_OrderGroupIDSeq,
                                                    @IPVC_OrderItemIDSeq   = @IPVC_OrderItemIDSeq,
                                                    @IPI_IsCustomBundle    = @IPI_CustomBundleFlag,                                                     
                                                    @IPVC_ProductCode      = @LVC_ProductCode,
                                                    @IPVC_ChargeTypeCode   = @IPVC_ChargeTypeCode,
                                                    @IPBI_UserIDSeq        = @IPBI_UserIDSeq;  


      Update OI
      set    OI.StatusCode           = 'PEND',
             OI.ActivationStartDate  = NULL,
             OI.ActivationEndDate    = NULL,
             OI.ILFStartDate         = NULL,
             OI.ILFEndDate           = NULL,
             OI.StartDate            = NULL,
             OI.EndDate              = NULL,
             OI.LastBillingPeriodFromDate = NULL,
             OI.LastBillingPeriodToDate   = NULL,
             ------------------------------------------
             OI.RenewalTypeCode      = (case when (OI.FrequencyCode = 'OT' or OI.FrequencyCode = 'SG' or @LI_HigherRenewalExists = 1) then 'DRNW' else 'ARNW' end),
             OI.RenewalReviewedFlag  = 0,
             OI.RenewalFlag          = 0,
             OI.RenewalUserOverrideFlag=0,
             OI.RenewalAdjustedChargeAmount=NULL,
             OI.RenewalStartDate     = NULL,
             OI.RenewedByUserIDSeq   = NULL,
             OI.RenewalNotes         = NULL,
             OI.RenewalReviewedDate  = NULL,
             ------------------------------------------
             OI.CancelDate           = NULL,
             OI.CancelReasonCode     = NULL,
             OI.CancelNotes          = NULL,
             OI.CancelByIDSeq        = NULL,
             OI.CancelActivityDate   = NULL,
             ------------------------------------------
             OI.FulfilledByIDSeq     = NULL,
             OI.FulfilledDate        = NULL,
             ------------------------------------------
             OI.HistoryFlag          = 0, 
             OI.HistoryDate          = NULL,
             ------------------------------------------
             OI.RollbackReasonCode   = @IPVC_RollbackReasonCode,
             OI.RollbackByIDSeq      = @IPBI_UserIDSeq,
             OI.RollbackDate         = @LDT_SystemDate,
             ------------------------------------------
             OI.ModifiedByUserIDSeq  = @IPBI_UserIDSeq,
             OI.ModifiedDate         = @LDT_SystemDate,
             OI.SystemLogDate        = @LDT_SystemDate
             ------------------------------------------
      from   ORDERS.dbo.[Orderitem] OI with (nolock)
      where  OI.Orderidseq       = @IPVC_Orderidseq
      and    OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
      and   ((@IPI_CustomBundleFlag = 1)
                  OR
             ((OI.IDSeq = @IPVC_OrderItemIDSeq OR OI.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and OI.FrequencyCode <> 'OT')
                  OR
             ((OI.IDSeq = @IPVC_OrderItemIDSeq and OI.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and OI.FrequencyCode = 'OT')
            )     
      and    OI.ChargeTypeCode  = @IPVC_ChargeTypeCode
      and    OI.MeasureCode     = @LVC_MeasureCode
      and    OI.FrequencyCode   = @LVC_FrequencyCode
      and    OI.RenewalCount    = @IPI_RenewalCount
      and    OI.StatusCode      = @LVC_StatusCode
      and    isdate(OI.StartDate) = 0
      and    isdate(OI.POILastBillingPeriodToDate) = 0
    END TRY
    BEGIN CATCH
      ------------------------      
      select @LVC_CodeSection =  'Proc: uspORDERS_OrderItemDoRollback;Error Rolling back OrderItem from Cancelled State back to Pending--> OrderID: '+ @IPVC_Orderidseq
      ------------------------    
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
      return;                  
    END CATCH;
    return
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 2 : 
  ---------->Rollback of cancelled ACS Subscription back to fulfilled, when cancelled after activation. --Back to DONOT RENEW state if renewal is present
  ---------->Rollback of cancelled ACS Subscription back to fulfilled, when cancelled after activation. --Back to AUTORENEW Mode if this is higher renewal
  ---------->Rollback of cancelled Ancillary back to fulfilled, when cancelled after activation.
  ---------->Rollback of cancelled ILF back to fulfilled, when cancelled after activation.  
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'CNCL' and isdate(@LDT_StartDate) = 1)
  begin
    BEGIN TRY
      Exec INVOICES.dbo.uspINVOICES_RollBackInvoice @IPVC_Orderid          = @IPVC_Orderidseq,
                                                    @IPBI_OrderGroupID     = @IPVC_OrderGroupIDSeq,
                                                    @IPVC_OrderItemIDSeq   = @IPVC_OrderItemIDSeq,
                                                    @IPI_IsCustomBundle    = @IPI_CustomBundleFlag,                                                     
                                                    @IPVC_ProductCode      = @LVC_ProductCode,
                                                    @IPVC_ChargeTypeCode   = @IPVC_ChargeTypeCode,
                                                    @IPBI_UserIDSeq        = @IPBI_UserIDSeq;  

  
      Update OI
      set    OI.StatusCode           = 'FULF',
             OI.ActivationStartDate  = OI.ActivationStartDate,
             OI.ActivationEndDate    = OI.ActivationEndDate,
             OI.ILFStartDate         = OI.ILFStartDate,
             OI.ILFEndDate           = OI.ILFEndDate,
             OI.StartDate            = OI.StartDate,
             OI.EndDate              = OI.EndDate,
             OI.LastBillingPeriodFromDate = OI.POILastBillingPeriodFromDate,
             OI.LastBillingPeriodToDate   = OI.POILastBillingPeriodToDate,
             ------------------------------------------
             OI.RenewalTypeCode      = (case when (OI.FrequencyCode = 'OT' or OI.FrequencyCode = 'SG' or @LI_HigherRenewalExists = 1) then 'DRNW' else 'ARNW' end),
             OI.CancelDate           = NULL,
             OI.CancelReasonCode     = NULL,
             OI.CancelNotes          = NULL,
             OI.CancelByIDSeq        = NULL,
             OI.CancelActivityDate   = NULL,
             ------------------------------------------
             OI.FulfilledByIDSeq     = OI.FulfilledByIDSeq,
             OI.FulfilledDate        = OI.FulfilledDate,
             ------------------------------------------
             OI.HistoryFlag          = (case when (OI.FrequencyCode = 'OT' or OI.FrequencyCode = 'SG' or @LI_HigherRenewalExists = 1) then 1 else 0 end),
             OI.HistoryDate          = (case when (OI.FrequencyCode = 'OT' or OI.FrequencyCode = 'SG' or @LI_HigherRenewalExists = 1) then @LDT_SystemDate else NULL end),
             ------------------------------------------
             OI.RollbackReasonCode   = @IPVC_RollbackReasonCode,
             OI.RollbackByIDSeq      = @IPBI_UserIDSeq,
             OI.RollbackDate         = @LDT_SystemDate,
             ------------------------------------------
             OI.ModifiedByUserIDSeq  = @IPBI_UserIDSeq,
             OI.ModifiedDate         = @LDT_SystemDate,
             OI.SystemLogDate        = @LDT_SystemDate
             ------------------------------------------
      from   ORDERS.dbo.[Orderitem] OI with (nolock)
      where  OI.Orderidseq       = @IPVC_Orderidseq
      and    OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
      and   ((@IPI_CustomBundleFlag = 1)
                  OR
             ((OI.IDSeq = @IPVC_OrderItemIDSeq OR OI.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and OI.FrequencyCode <> 'OT')
                  OR
             ((OI.IDSeq = @IPVC_OrderItemIDSeq and OI.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0 and OI.FrequencyCode = 'OT')
            )    
      and    OI.ChargeTypeCode  = @IPVC_ChargeTypeCode
      and    OI.MeasureCode     = @LVC_MeasureCode
      and    OI.FrequencyCode   = @LVC_FrequencyCode
      and    OI.RenewalCount    = @IPI_RenewalCount
      and    OI.StatusCode      = @LVC_StatusCode
      and    isdate(OI.StartDate) = 1
    END TRY
    BEGIN CATCH
      ------------------------      
      select @LVC_CodeSection =  'Proc: uspORDERS_OrderItemDoRollback;Error Rolling back OrderItem from Cancelled State back to Fulfilled--> OrderID: '+ @IPVC_Orderidseq
      ------------------------    
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
      return;                  
    END CATCH;
    return
  end
END
GO
