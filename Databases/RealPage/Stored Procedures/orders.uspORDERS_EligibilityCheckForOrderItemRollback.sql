SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_EligibilityCheckForOrderItemRollback]
-- Description     : This procedure returns 1 or 0 for Eligibility.
--                    1 is eligible for Orderitem Rollback.
--                    0 is NOT ELIGIBLE for Orderitem Rollback.

--                   This proc should be called by UI when user initiates Rollback and that Status is not Pending, hold or Expired.
--                   If the resultset of Orders.dbo.uspORDERS_OrderPropertySelect that UI already calls to display has Status = Expired,Pending,Hold
--                    then UI can make the determination to not allow rollback.
--
-- OUTPUT          : RecordSet of eligibilityflag
--
-- Code Example    : Syntax for calling from UI or anywhere else.
/*
declare @LXML_OIRBEligibility XML
   exec [ORDERS].[dbo].[uspORDERS_EligibilityCheckForOrderItemRollback] 
                          @IPVC_Orderidseq='O0901114205',@IPI_CustomBundleFlag=0,@IPVC_OrderGroupIDSeq=115019,
                          @IPVC_ChargeTypeCode='ACS',@IPBI_UserIDSeq=76,@IPI_RenewalCount=1,@IPVC_OrderItemIDSeq=412201,
                          @OPXML_OIRBEligibility = @LXML_OIRBEligibility OUTPUT
   select @LXML_OIRBEligibility
*/
-- Revision History:
-- Author          : SRS
-- 2010-10-21      : Stored Procedure Created.Defect 7745
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_EligibilityCheckForOrderItemRollback] (@IPVC_Orderidseq                varchar(50),        ---> This is the Orderidseq of the Current Orderitem. UI knows this already                                                                         
                                                                         @IPVC_OrderGroupIDSeq           varchar(50),        ---> This is the OrderGroupIDSeq of the Current Orderitem. UI knows this already
                                                                         @IPVC_OrderItemIDSeq            varchar(50)=null,   ---> This is the OrderItemIDSeq of the Current Orderitem. UI knows this already
                                                                                                                             ---     This will be NULL for CustomBundles ie PreconfiguredBundleFlag = 1
                                                                         @IPVC_ChargeTypeCode            varchar(3),         ---> This is the ChargeTypeCode of the Current Orderitem. UI knows this already
                                                                         @IPI_CustomBundleFlag           int,                ---> This is the custombundleFlag ie IsCustomPackage of the Current Orderitem. UI knows this already
                                                                                                                             ---     0 means it is Alacarte and not part of Custom Bundle. 1 means it is part of Custom Bundle. This is PreconfiguredBundleFlag                                                                        
                                                                         @IPI_RenewalCount               int= 0,             ---> This is renewal count number of the current Orderitem. UI knows this already.    
                                                                         @IPBI_UserIDSeq                 bigint,             ---> This is UserID of person logged on (Mandatory)
                                                                         @OPXML_OIRBEligibility          xml     OUTPUT      ---> This is the @OPXML_OIRBEligibility OUTPUT PARAMETER
                                                                        )

AS
BEGIN --->Main Begin
  set nocount on;
  ----------------------------------------------------------------------------------
  ---Declare Local variables.
  Declare @LI_eligibilityflag        int,
          @LVC_message               varchar(2000),
          @LI_HigherRenewalExists    int

  Declare @LVC_AccountIDSeq               varchar(50),
          @LVC_CompanyIDSeq               varchar(50),
          @LVC_PropertyIDSeq              varchar(50),
          @LVC_ProductCode                varchar(50),
          @LVC_MeasureCode                varchar(20),
          @LVC_FrequencyCode              varchar(20),
          @LVC_ReportingTypeCode          varchar(20),
          @LVC_BillToAddressTypeCode      varchar(20),
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
  --Initialize local Variables.
  select @IPVC_OrderItemIDSeq = (case when @IPI_CustomBundleFlag=1 then NULL else nullif(@IPVC_OrderItemIDSeq,'') end), 
         @LI_HigherRenewalExists = 0

  select  @LI_eligibilityflag = 0,
          @LVC_message        = 'This Orderitem is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+
                                'Reason: Failed to meet minimum requirements under general criteria for Rollback.' + char(13)

  
  select Top 1 @LVC_AccountIDSeq             = O.AccountIDSeq,
               @LVC_CompanyIDSeq             = O.CompanyIDSeq, 
               @LVC_PropertyIDSeq            = NullIf(O.PropertyIDSeq,''),
               @LVC_ProductCode              = (case when @IPI_CustomBundleFlag=1 then NULL else OI.ProductCode end),
               @LVC_MeasureCode              = OI.MeasureCode,
               @LVC_FrequencyCode            = OI.FrequencyCode,
               @LVC_ReportingTypeCode        = OI.ReportingTypeCode,
               @LVC_RenewedFromOrderitemIDSeq= OI.RenewedFromOrderitemIDSeq,
               @LVC_BillToAddressTypeCode    = OI.BillToAddressTypeCode,
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
  -----------------------------------------------------------------------------------
  ---Check for all Ineligible conditions first               
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 0 : If Status is PEND or HOLD or EXPD, Rollback is NOT possible.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode in ('PEND','HOLD','EXPD'))
  begin 
    select @LI_eligibilityflag = 0,
           @LVC_message        = 'This Orderitem is NOT ELIGIBLE for Rollback.' + char(13) + char(13)+
                                 'Reason: ' + (case when @LVC_StatusCode = 'PEND' then 'This Order item is already in a base Pending State.'
                                                    when @LVC_StatusCode = 'HOLD' then 'This Order item is already in a base Holding/Pending State.'
                                                    when @LVC_StatusCode = 'EXPD' then 'This Order item is already Invoiced upto to full contract term and has Expired.'
                                               end) + char(13)
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 1 : Fulfilled TRAN enabler Order that has atleast one transaction invoiced to Client is NOT ELIGIBLE for Rollback to Pending state
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'FULF' and @LVC_MeasureCode = 'TRAN' and isdate(@LDT_POILastBillToDate) = 1)
  begin
    select @LI_eligibilityflag = 0,
           @LVC_message        = 'This Orderitem is NOT ELIGIBLE for Rollback from Fulfilled State back to Pending State.' + char(13) + char(13)+
                                 'Reason: ' + 'This Tran Enabler Order item has associated transaction(s) which are already invoiced to customer.' + char(13)
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 2 :  Fulfilled TRAN enabler Order that has no transaction Invoiced to Client, but waiting to be invoiced is NOT ELIGIBLE to Rollback to Pending state 
  --          until Rollback of Transaction Import Batch is Initiated.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'FULF' and @LVC_MeasureCode = 'TRAN' and isdate(@LDT_POILastBillToDate) = 0)
  and exists (select top 1 1 
              from   Orders.dbo.OrderitemTransaction OIT with (nolock)
              where  OIT.Orderidseq       = @IPVC_Orderidseq
              and    OIT.OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq
              and    ((@IPI_CustomBundleFlag = 1)
                        OR
                      (OIT.OrderitemIDSeq = @IPVC_OrderItemIDSeq and @IPI_CustomBundleFlag = 0)
                     )              
              and    OIT.TransactionalFlag= 1
             )
  begin
    select @LI_eligibilityflag = 0,
           @LVC_message        = 'This Orderitem is NOT ELIGIBLE for Rollback from Fulfilled State back to Pending State.' + char(13) + char(13)+
                                 'Reason    : ' + 'This Tran Enabler Order item has associated transaction(s) queued for Invoicing.' + char(13)+
                                 'Suggestion: Rollback Import Batch or Delete manually added transaction(s) to make this orderitem eligible for rollback.' + char(13)
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 3 : Fulfilled Non Tran Order that is already Invoiced to Client is NOT ELIGIBLE for Rollback to Pending state
  --         This scenario also takes care of Migrated orders which were Invoiced in external system.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'FULF' and isdate(@LDT_POILastBillToDate) = 1)
  begin
    select @LI_eligibilityflag = 0,
           @LVC_message        = 'This Orderitem is NOT ELIGIBLE for Rollback from Fulfilled State back to Pending State.' + char(13) + char(13)+
                                 'Reason: ' + 'This Order item is Fulfilled and either all or part of contract term is already invoiced to customer.' + char(13) 
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 4 : Fulfilled Non Tran Order that have higher renewals is NOT ELIGIBLE for Rollback to Pending state
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'FULF' and @LI_HigherRenewalExists = 1) 
  begin
    select @LI_eligibilityflag = 0,
           @LVC_message        = 'This Orderitem is NOT ELIGIBLE for Rollback from Fulfilled State back to Pending State.' + char(13) + char(13)+
                                 'Reason: ' + 'This Order item is Fulfilled and has one or more derived Renewal(s).' + char(13) 
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 6 : Fulfilled Non Tran Order that is a renewal is NOT ELIGIBLE for Rollback to Pending state
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode in('FULF','PENR') and isnumeric(@LVC_RenewedFromOrderitemIDSeq) = 1 and @IPI_RenewalCount > 0 )
  begin
    select @LI_eligibilityflag = 0,
           @LVC_message        = 'This Renewed Orderitem is NOT ELIGIBLE for Rollback from Fulfilled State back to Pending State.' + char(13) + char(13)+
                                 'Reason    : ' + 'This is a Renewal Order item derived from Master Order and Fulfilled by Renewal Process.' + char(13) +
                                 'Suggestion: ' + 'Cancel this Renewal Order if it is renewed in error and follow Re-price Quote approval process.' + char(13) 
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 7 : Fulfilled ILF that is not Invoiced to Client is NOT ELIGIBLE to rollback to Pending State, until corresponding Access(if any) is Rolled back to Pending State.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'FULF' and @IPVC_ChargeTypeCode = 'ILF' and isdate(@LDT_POILastBillToDate) = 0)
  and exists (select top 1 1 
              from   ORDERS.dbo.[Order] O with (nolock)
              inner join
                     ORDERS.dbo.[Orderitem] OI with (nolock)
              on     O.AccountIDSeq      = @LVC_AccountIDSeq
              and    O.Orderidseq        = OI.Orderidseq
              and    O.Orderidseq        = @IPVC_Orderidseq
              and    OI.OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq
              and    OI.Productcode      = coalesce(@LVC_ProductCode,OI.Productcode)
              and    OI.ChargeTypeCode   = 'ACS'
              and    OI.ReportingTypeCode= 'ACSF'
              and    OI.StatusCode       <>'PEND'
              and    isdate(OI.POILastBillingPeriodToDate) = 0
             )
  begin
    select @LI_eligibilityflag = 0,
           @LVC_message        = 'This ILF Orderitem is NOT ELIGIBLE for Rollback from Fulfilled State back to Pending State.' + char(13) + char(13)+
                                 'Reason    : ' + 'This Order item has associated Access Order item that is not in Pending State.' + char(13)+
                                 'Suggestion: ' + 'Rollback associated Access Order item to Pending State first in order to make this ILF orderitem eligible for rollback.' + char(13)
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  ---Step 8 : Cancelled ILF (before Activation) is NOT ELIGIBLE to rollback to Pending State, until corresponding Access(if any) is Rolled Back to Pending State.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'CNCL' and @IPVC_ChargeTypeCode = 'ILF' and isdate(@LDT_StartDate) = 0)
  and exists (select top 1 1 
              from   ORDERS.dbo.[Order] O with (nolock)
              inner join
                     ORDERS.dbo.[Orderitem] OI with (nolock)
              on     O.AccountIDSeq      = @LVC_AccountIDSeq
              and    O.Orderidseq        = OI.Orderidseq
              and    O.Orderidseq        = @IPVC_Orderidseq
              and    OI.OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq
              and    OI.Productcode      = coalesce(@LVC_ProductCode,OI.Productcode)
              and    OI.ChargeTypeCode   = 'ACS'
              and    OI.ReportingTypeCode= 'ACSF'
              and    OI.StatusCode       <>'PEND'
              and    isdate(OI.StartDate) = 0
             )
  begin
    select @LI_eligibilityflag = 0,
           @LVC_message        = 'This ILF Orderitem is NOT ELIGIBLE for Rollback from Cancelled State back to Pending State.' + char(13) + char(13)+
                                 'Reason    : ' + 'This Order item has associated Access Order item that is not in Pending State.' + char(13)+
                                 'Suggestion: ' + 'Rollback associated Access Order item to Pending State first in order to make this ILF orderitem eligible for rollback.' + char(13)
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  ---Step 9 : Cancelled ACS (After Activation) is NOT ELIGIBLE to rollback to Fulfilled State, unless it passes Fulfilment validations
  --          
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'CNCL' and isdate(@LDT_StartDate) = 1 )
  begin
    create table #LTBL_OrderFulFillmentErrors  (Seq              int identity(1,1)  not null primary key,
                                                ErrorMsg         varchar(2000)      null, 
                                                Name             varchar(2000)      null,
                                                CanOverrideFlag  Bit                not null default(0)
                                               );
    Insert into #LTBL_OrderFulFillmentErrors(ErrorMsg,Name,CanOverrideFlag)
    EXEC ORDERS.dbo.uspORDERS_ValidateOrderItemFulfillment @IPVC_OrderIDSeq       = @IPVC_OrderIDSeq,
                                                           @IPVC_OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq,
                                                           @IPVC_OrderItemIDSeq   = @IPVC_OrderItemIDSeq,
                                                           @IPVC_FulFillStartDate = @LDT_StartDate,
                                                           @IPVC_FulFillEndDate   = @LDT_EndDate,
                                                           @IPVC_ValidationType   = 'FulFillOrder';

    if exists(select top 1 1 from #LTBL_OrderFulFillmentErrors with (nolock))
    begin
      select Top 1
             @LI_eligibilityflag = 0,
             @LVC_message        = 'This Orderitem is NOT ELIGIBLE for Rollback from Cancelled State back to Fulfilled State.' + char(13) + char(13)+
                                   'Reason          : ' + 'This Order item failed one or more critical fulfilment validations.' + char(13)+
                                   'Validation Error: ' + ErrorMsg + char(13)+
                                   'Suggestion      : ' + 'Abort Rollback or follow other fulfilment validation suggestion(s) below : ' + [Name] + char(13)
      from  #LTBL_OrderFulFillmentErrors with (nolock)
      ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))

      if (object_id('tempdb.dbo.#LTBL_OrderFulFillmentErrors') is not null) 
      begin
        drop table #LTBL_OrderFulFillmentErrors
      end
      return
    end
  end
  -----------------------------------------------------------------------------------
  ---Now Check for all ELIGIBLE conditions in sequential Order               
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 0 : 
  ---------->Rollback of fulfilled ACS Subscription back to pending
  ---------->Rollback of fulfilled Ancillary back to pending (including Tran Enabler Orderitem)
  ---------->Rollback of fulfilled ILF  back to pending
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'FULF' and isdate(@LDT_StartDate) = 1 and isdate(@LDT_POILastBillToDate) = 0)
  begin
    select @LI_eligibilityflag = 1,
           @LVC_message        = 'This Orderitem(s) is ELIGIBLE for Rollback from Fulfilled State back to Pending State.' + char(13) + char(13)+
                                 '(a) Will consider Fulfillment event as erroneous and Reset Fulfillment Status and attributes if any.' + char(13)+ 
                                 '(b) Rollback all corresponding Invoiceitem(s) from open unprinted Invoice(s) if any.' + char(13)+
                                 '(c) Will mark ' + (case when @IPVC_ChargeTypeCode='ILF' 
                                                            then 'ILF Orderitem(if Ala-Carte)/Orderitem(s)(if Custom bundle)'
                                                          when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode = 'TRAN')
                                                            then 'TRAN Enabler Orderitem'
                                                          when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode <> 'TRAN' and @LVC_ReportingTypeCode='ACSF')
                                                            then 'Access Orderitem(if Ala-Carte)/Orderitem(s)(if Custom bundle)'
                                                          when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode <> 'TRAN' and @LVC_ReportingTypeCode='ANCF')
                                                            then 'Ancillary Enabler Orderitem'
                                                     end)+ ' as Pending.' + char(13)+
                                 '(d) Will require and record valid Rollback Reason and user who initiates rollback for audit reporting.' + char(13)
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end  
  -----------------------------------------------------------
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
                           ((II.OrderItemIDSeq = @IPVC_OrderItemIDSeq OR II.Productcode= @LVC_ProductCode) and @IPI_CustomBundleFlag = 0)            
                          )   
                   and    II.ChargeTypeCode  = @IPVC_ChargeTypeCode
                   and    II.MeasureCode     = @LVC_MeasureCode
                   and    II.FrequencyCode   = @LVC_FrequencyCode
                   and    I.Printflag = 1
                  )
    begin
      select @LI_eligibilityflag = 1,
             @LVC_message        = 'This Orderitem(s) is ELIGIBLE for Rollback from Fulfilled State back to Pending State.' + char(13) + char(13)+
                                   '(a) Will consider Fulfillment event as erroneous and Reset Fulfillment Status and attributes if any.' + char(13)+ 
                                   '(b) Rollback all corresponding Invoiceitem(s) from open unprinted Invoice(s) if any.' + char(13)+
                                   '(c) Will mark ' + (case when @IPVC_ChargeTypeCode='ILF' 
                                                            then 'ILF Orderitem(if Ala-Carte)/Orderitem(s)(if Custom bundle)'
                                                          when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode = 'TRAN')
                                                            then 'TRAN Enabler Orderitem'
                                                          when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode <> 'TRAN' and @LVC_ReportingTypeCode='ACSF')
                                                            then 'Access Orderitem(if Ala-Carte)/Orderitem(s)(if Custom bundle)'
                                                          when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode <> 'TRAN' and @LVC_ReportingTypeCode='ANCF')
                                                            then 'Ancillary Enabler Orderitem'
                                                      end)+ ' as Pending.' + char(13)+
                                  '(d) Will require and record valid Rollback Reason and user who initiates rollback for audit reporting.' + char(13)
             ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
      return
    end
  end
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 1 : 
  ---------->Rollback of cancelled ACS Subscription back to pending, when cancelled before activation.
  ---------->Rollback of Cancelled Ancillary back to pending (including Tran Enabler Orderitem)
  ---------->Rollback of cancelled ILF back to pending, when cancelled before activation.
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'CNCL' and isdate(@LDT_StartDate) = 0 and isdate(@LDT_POILastBillToDate) = 0)
  begin
    select @LI_eligibilityflag = 1,
           @LVC_message        = 'This Orderitem(s) is ELIGIBLE for Rollback from Cancelled State back to Pending State.' + char(13) + char(13)+ 
                                 '(a) Will consider Cancellation event as erroneous and Reset Cancellation Status and attributes if any.' + char(13)+                                
                                 '(b) Rollback all corresponding Invoiceitem(s) from open unprinted Invoice(s) if any.' + char(13)+
                                 '(c) Will mark ' + (case when @IPVC_ChargeTypeCode='ILF' 
                                                            then 'ILF Orderitem(if Ala-Carte)/Orderitem(s)(if Custom bundle)'
                                                          when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode = 'TRAN')
                                                            then 'TRAN Enabler Orderitem'
                                                          when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode <> 'TRAN' and @LVC_ReportingTypeCode='ACSF')
                                                            then 'Access Orderitem(if Ala-Carte)/Orderitem(s)(if Custom bundle)'
                                                          when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode <> 'TRAN' and @LVC_ReportingTypeCode='ANCF')
                                                            then 'Ancillary Enabler Orderitem'
                                                     end) + ' as Pending.' + char(13)+
                                 '(d) Will require and record valid Rollback Reason and user who initiates rollback for audit reporting.' + char(13)
    ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
    return
  end 
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Step 2 : This can be done only after it passes validations.

  ---------->Rollback of cancelled ACS Subscription back to fulfilled, when cancelled after activation. --Back to DONOT RENEW state if renewal is present
  ---------->Rollback of cancelled ACS Subscription back to fulfilled, when cancelled after activation. --Back to AUTORENEW Mode if this is higher renewal
  ---------->Rollback of cancelled Ancillary back to fulfilled, when cancelled after activation.
  ---------->Rollback of cancelled ILF back to fulfilled, when cancelled after activation.  
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  if (@LVC_StatusCode = 'CNCL' and isdate(@LDT_StartDate) = 1)
  begin
    create table #LTBL_OrderFulFillmentErrors_1  (Seq              int identity(1,1)  not null primary key,
                                                  ErrorMsg         varchar(2000)      null, 
                                                  Name             varchar(2000)      null,
                                                  CanOverrideFlag  Bit                not null default(0)
                                                 );
    Insert into #LTBL_OrderFulFillmentErrors_1(ErrorMsg,Name,CanOverrideFlag)
    EXEC ORDERS.dbo.uspORDERS_ValidateOrderItemFulfillment @IPVC_OrderIDSeq       = @IPVC_OrderIDSeq,
                                                           @IPVC_OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq,
                                                           @IPVC_OrderItemIDSeq   = @IPVC_OrderItemIDSeq,
                                                           @IPVC_FulFillStartDate = @LDT_StartDate,
                                                           @IPVC_FulFillEndDate   = @LDT_EndDate,
                                                           @IPVC_ValidationType   = 'FulFillOrder';

    if exists(select top 1 1 from #LTBL_OrderFulFillmentErrors_1 with (nolock))
    begin
      select Top 1
             @LI_eligibilityflag = 0,
             @LVC_message        = 'This Orderitem is NOT ELIGIBLE for Rollback from Cancelled State back to Fulfilled State.' + char(13) + char(13)+
                                   'Reason          : ' + 'This Order item failed one or more critical fulfilment validations.' + char(13)+
                                   'Validation Error: ' + ErrorMsg + char(13)+
                                   'Suggestion      : ' + 'Abort Rollback or follow other fulfilment validation suggestion(s) below : ' + [Name] + char(13)
      from  #LTBL_OrderFulFillmentErrors_1 with (nolock)
      ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))

      if (object_id('tempdb.dbo.#LTBL_OrderFulFillmentErrors_1') is not null) 
      begin
        drop table #LTBL_OrderFulFillmentErrors_1
      end
      return
    end
    else
    begin
      select @LI_eligibilityflag = 1,
             @LVC_message        = 'This Orderitem(s) is ELIGIBLE for Rollback from Cancelled State back to Fulfilled State.' + char(13) + char(13)+                                 
                                   '(a) Will consider Cancellation event as erroneous and Reset Cancellation Status and attributes if any.' + char(13)+
                                   '(b) Will mark ' + (case when @IPVC_ChargeTypeCode='ILF' 
                                                              then 'ILF Orderitem(if Ala-Carte)/Orderitem(s)(if Custom bundle)'
                                                            when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode = 'TRAN')
                                                              then 'TRAN Enabler Orderitem'
                                                            when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode <> 'TRAN' and @LVC_ReportingTypeCode='ACSF')
                                                              then 'Access Orderitem(if Ala-Carte)/Orderitem(s)(if Custom bundle)'
                                                            when (@IPVC_ChargeTypeCode='ACS' and @LVC_MeasureCode <> 'TRAN' and @LVC_ReportingTypeCode='ANCF')
                                                              then 'Ancillary Enabler Orderitem'
                                                       end) + ' as Fulfilled.' + char(13)+
                                   '(c) Will mark for Auto renewal (if Access subscription) to enable this item to come up for renewal at the end of contract term.' + char(13)+
                                   '(d) Will instruct OMS to resume Invoicing this item for any remaining term from Last Billing Period (if applicable) which was stopped by previous cancellation event.' + char(13)+
                                   '(e) Will require and record valid Rollback Reason and user who initiates rollback for audit reporting.' + char(13)
                                  
      ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,1 as callonlineinvoiceflag For XML Path('root'))
    return
    end
  end 
  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
  --Final Select (This will get executed if none of the above conditions get satisfied.
  -----------------------------------------------------------------------------------
  ;Select @OPXML_OIRBEligibility =(select @LI_eligibilityflag as eligibilityflag,@LVC_message as message,0 as callonlineinvoiceflag For XML Path('root'))
  -----------------------------------------------------------------------------------
END
GO
