SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_UpdateProductDetails
-- Description     : This procedure gets Product Details pertaining to passed Product Code
-- Input Parameters: 1. @IPVC_OrderIDSeq        as varchar(10)
--                   2. @IPVC_OrderGroupIDSeq   as varchar(10)
--                   3. @IPVC_ProductCode       as varchar(30)
--                   4. @IPVC_ChargeTypeCode    as varchar(3)
--                   5. @IPVC_FrequencyCode     as varchar(6)
--                   6. @IPVC_MeasureCode       as varchar(6)
--                   7. @IPVC_StartDate         as varchar(11)
--                   8. @IPVC_EndDate           as varchar(11)
--                   9. @IPVC_Status            as varchar(15)
--                   
-- Revision History:
-- Author          : STA
-- 12/01/2006      : Stored Procedure Created.
-- 12/06/2006      : Transaction and Try Catch are implemented.
-- 11/9/2007       : To change the ILF status to Fulfilled when ACS status is changed to Fulfilled
-- 06/08/2010      : Shashi Bhushan - Defect #7754 -Modified to add parameters QuoteType and  LastBillingPeriodToDate values
-----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_UpdateProductDetails](
                                                        @IPVC_Orderidseq                varchar(50),
                                                        @IPVC_OrderItemIDSeq            bigint,
                                                        @IPVC_OrderGroupIDSeq           bigint,
                                                        @IPVC_ChargeTypeCode            varchar(3),
                                                        @IPVC_StartDate                 varchar(20),
                                                        @IPVC_EndDate                   varchar(20),
                                                        @IPVC_CancelDate                varchar(20),
                                                        @IPVC_Status                    varchar(15),
                                                        @IPB_IsCustomPackage            bit,
                                                        @IPVC_Renewal                   varchar(5) = '',
                                                        @IPVC_CancelReason              varchar(10),
                                                        @IPVC_SHCharge                  money,
                                                        @IPVC_CancelNotes               varchar(1000),
                                                        @IPBI_UserIDSeq                 bigint,              --> This is UserID of person logged on (Mandatory)  
                                                        @IPI_RenewalCount               int    = 0,
                                                        @IPVC_QuoteTypeCode             varchar(4) = 'NEWQ', --> This is QuoteTypeCode and NOT QuoteTypeName
                                                        @IPVC_LastBillingPeriodToDate   varchar(50)
                                                        )
AS
BEGIN 
  set nocount on;
  set ansi_warnings off;
  ---------------------------------------------------
  declare @LVC_CompanyIDSeq              varchar(50),
          @LVC_ProductCode               varchar(30), 
          @LVC_ILFStartDate              varchar(20),
          @LVC_ILFEndDate                varchar(20),
          @LI_CancelCount                int,
          @LVC_MasterOrderItemIDSeq      varchar(50),
          @LBI_CB_MinOrderItemIDSeq      bigint,
          @LVC_CodeSection               varchar(1000),
          @LBI_ModifiedByUserIDSeq       bigint,
          @LDT_SystemDate                datetime;

  select @IPVC_CancelNotes = nullif(ltrim(rtrim(@IPVC_CancelNotes)),''),
         @IPVC_Renewal     = nullif(ltrim(rtrim(@IPVC_Renewal)),''),
         @LDT_SystemDate   = getdate();
  --------------------------------------------------
  ---Pre-Validation for Dates.
  --- If @IPVC_Status = 'FULF' then @IPVC_StartDate and @IPVC_EndDate are mandatory
  --   and @IPVC_EndDate should atleast be greater than or equal to @IPVC_StartDate as minimum requirement.
  if (@IPVC_Status = 'FULF')
  begin
    if (isdate(@IPVC_StartDate) = 0 Or @IPVC_StartDate = '01/01/1900')
    begin
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. StartDate is NULL or 01/01/1900 or Invalid for Order Fulfillment.Aborting Fulfillment...'
      return
    end
    if (isdate(@IPVC_EndDate) = 0 Or @IPVC_EndDate = '01/01/1900')
    begin
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. EndDate is NULL or 01/01/1900 or Invalid for Order Fulfillment.Aborting Fulfillment...'
      return
    end
    begin try
      if convert(datetime,@IPVC_EndDate) < convert(datetime,@IPVC_StartDate)
      begin
        Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. EndDate is less than StartDate for Order Fulfillment.Aborting Fulfillment...'
        return
      end
    end try
    begin catch
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. StartDate and Enddate are invalid for Order Fulfillment.Aborting Fulfillment...'
      return
    end catch
  end
  --------------------------------------------------
  ---If @IPVC_Status = 'CNCL' then CancelDate is mandatory
  if (@IPVC_Status = 'CNCL')
  begin
    if (isdate(@IPVC_CancelDate) = 0 Or @IPVC_CancelDate = '01/01/1900')
    begin
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. CancelDate is NULL or 01/01/1900 or Invalid for Order Cancellation..Aborting Cancellation...'
      return
    end    
  end
  --------------------------------------------------
  --If Not New Quote, and @IPVC_LastBillingPeriodToDate is not NULL or Blank and if it is not a valid date in date format, throw error.
  if (@IPVC_QuoteTypeCode <> 'NEWQ' and len(@IPVC_LastBillingPeriodToDate) > 0 and isdate(@IPVC_LastBillingPeriodToDate)=0)
  begin
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. LastBillingPeriodToDate is not in Valid Date Format.'
    return
  end
  --------------------------------------------------
  ---If @IPVC_LastBillingPeriodToDate is a valid date then it cannot be 01/01/1900 and  also it has to be between @IPVC_StartDate and @IPVC_EndDate
  if (@IPVC_QuoteTypeCode <> 'NEWQ' and isdate(@IPVC_LastBillingPeriodToDate)=1 and @IPVC_Status = 'FULF' )
  begin    
    if (@IPVC_LastBillingPeriodToDate = '01/01/1900')
    begin
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. LastBillingPeriodToDate is 01/01/1900 and is Invalid for Fulfillment.Aborting Fulfillment...'
      return
    end
    begin 
      if ((convert(datetime,@IPVC_LastBillingPeriodToDate) < convert(datetime,@IPVC_StartDate)) OR (convert(datetime,@IPVC_LastBillingPeriodToDate) > convert(datetime,@IPVC_EndDate)))
      begin        
        select  @LVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. ' +
                                   ' LastBillingPeriodToDate: ' + @IPVC_LastBillingPeriodToDate + ' is overriden by user ' +
                                   ' and does not fall within Startdate: '+ @IPVC_StartDate + '  and EndDate:' + @IPVC_EndDate
        Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
        return
      end
    end
  end
  -------------------------------------------------
  --Check if UserID is valid.
  if not exists (select top 1 1 from Security.dbo.[User] U with (nolock) where U.IDSeq = @IPBI_UserIDSeq)
  begin
    select  @LVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. ' +
                               ' UserID: ' + convert(varchar(50),@IPBI_UserIDSeq) + ' is not in the system.' +
                               ' Unauthorized use detected. Aborting Operation...' 
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  --------------------------------------------------
  select @LI_CancelCount = 0,@LBI_ModifiedByUserIDSeq=@IPBI_UserIDSeq;
  ---------------------------------------------------  

  ---------------------------------------------------
  IF  @IPB_IsCustomPackage = 1
  BEGIN--> Main Begin for @IPB_IsCustomPackage=1    
    -------------------------------------------------------------------------------------------------------
    ------------> Custom Bundle ILF Section
    -------------------------------------------------------------------------------------------------------
    --Case 1:
    IF (@IPVC_ChargeTypeCode = 'ILF' and @IPVC_Status = 'FULF')
    BEGIN
      ---Update for S&H Amount for Custom Bundle for ILF
      if @IPVC_SHCharge <> 0
      begin
        select @LBI_CB_MinOrderItemIDSeq = Min(IDSeq)
        from   Orders.dbo.Orderitem with (nolock)
        where  OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
        and    OrderIDSeq                = @IPVC_Orderidseq
        and    RenewalCount              = @IPI_RenewalCount 
        and    ChargeTypeCode            = 'ILF'
 
        Update ORDERS.dbo.Orderitem with (rowlock)
        set    ShippingAndHandlingAmount = @IPVC_SHCharge,
               ModifiedByUserIDSeq       = @LBI_ModifiedByUserIDSeq,
               ModifiedDate              = @LDT_SystemDate,
               SystemLogDate             = @LDT_SystemDate
        where  IDSeq                     = @LBI_CB_MinOrderItemIDSeq
        and    OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
        and    OrderIDSeq                = @IPVC_Orderidseq
        and    RenewalCount              = @IPI_RenewalCount 
        and    ChargeTypeCode            = 'ILF'
      end
      ---Step 1 : Update ILF Records for ILFStart,ILFEndDates for all products in the Group.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ILFStartDate = (Case isdate(@IPVC_StartDate) When 0 Then NULL else @IPVC_StartDate End),
             ILFEndDate   = (CASE isdate(@IPVC_EndDate)   when 1 then @IPVC_EndDate
                                  else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                           else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                        end)
                             END),
             StartDate    = (Case isdate(@IPVC_StartDate) When 0 Then NULL else @IPVC_StartDate End),
             EndDate      = (CASE isdate(@IPVC_EndDate) when 1
                                     then @IPVC_EndDate
                                  else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                           else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                        end)
                             END),
             CancelDate      = NULL,
             RenewalTypeCode = (case when (FrequencyCode = 'OT' or FrequencyCode = 'SG' or Productcode in ('DMD-PSR-ADM-ADM-AHDA','DMD-PSR-ADM-ADM-AHDF')) then 'DRNW' 
                                     else coalesce(@IPVC_Renewal,RenewalTypeCode) end),
             StatusCode      = @IPVC_Status,
             FulfilledByIDSeq          = @LBI_ModifiedByUserIDSeq,
             FulfilledDate             = @LDT_SystemDate,
             ModifiedByUserIDSeq       = @LBI_ModifiedByUserIDSeq,
             ModifiedDate              = @LDT_SystemDate,
             SystemLogDate             = @LDT_SystemDate                         
      where  OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq
      and    RenewalCount              = @IPI_RenewalCount 
      and    ChargeTypeCode            = 'ILF'
      and    StatusCode                = 'PEND' --> Only when Current Orderitem Status = Pending, do we allow to Fulfil.
      ---Step 2 : Carry Over this ILFStartDate and EndDate to ACS Records for all products in the Group irrespective of ACS items status.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ILFStartDate = (Case isdate(@IPVC_StartDate) When 0 Then NULL Else @IPVC_StartDate End),
             ILFEndDate   = (CASE isdate(@IPVC_EndDate) when 1
                                     then @IPVC_EndDate
                                  else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                           else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                        end)
                             END)
      where  OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq 
      and    RenewalCount              = @IPI_RenewalCount 
      and    ChargeTypeCode            = 'ACS'
    END
    --Case 2 : 
    else if (@IPVC_ChargeTypeCode = 'ILF' and @IPVC_Status in('HOLD','PEND'))
    BEGIN
      UPDATE ORDERS.dbo.Orderitem with (rowlock)
      set    StatusCode                = @IPVC_Status,
             ModifiedByUserIDSeq       = @LBI_ModifiedByUserIDSeq,
             ModifiedDate              = @LDT_SystemDate,
             SystemLogDate             = @LDT_SystemDate
      where  OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq
      and    RenewalCount              = @IPI_RenewalCount  
      and    ChargeTypeCode            = 'ILF'
      and    StatusCode                in ('PEND','HOLD') --> Only when Current Orderitem Status = Pending or HOLD, do we allow to continue to be in this status.
    END
    --Case 3 :
    else if (@IPVC_ChargeTypeCode = 'ILF' and @IPVC_Status = 'CNCL' and isdate(@IPVC_CancelDate)=1)
    BEGIN
      ---Step 1 : Cancellation of ILF will not trigger cancellation of ACS.
      UPDATE ORDERS.dbo.Orderitem with (rowlock)
      set    StatusCode       = @IPVC_Status,             
             CancelDate       = (Case when isdate(@IPVC_CancelDate)=0 Then NULL Else @IPVC_CancelDate End),             
             CancelReasonCode = nullif(@IPVC_CancelReason,''),
             CancelNotes      = @IPVC_CancelNotes,
             CancelByIDSeq    = @IPBI_UserIDSeq,
             CancelActivityDate=@LDT_SystemDate,
             ModifiedByUserIDSeq       = @LBI_ModifiedByUserIDSeq,
             ModifiedDate              = @LDT_SystemDate,
             -------------------------
             RenewalTypeCode  ='DRNW',
             HistoryFlag      = 1, 
             HistoryDate      = @LDT_SystemDate,
             SystemLogDate    = @LDT_SystemDate
             -------------------------
      where  OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq       = @IPVC_Orderidseq
      and    RenewalCount     = @IPI_RenewalCount  
      and    ChargeTypeCode   = 'ILF'
      and    StatusCode       not in ('EXPD','HOLD')
      and    (isdate(@IPVC_CancelDate)=1) -- Canceldate is mandatory
      ------------------------------------------------------------------
      Exec INVOICES.dbo.uspINVOICES_RollBackInvoice @IPVC_Orderid          = @IPVC_Orderidseq,
                                                    @IPBI_OrderGroupID     = @IPVC_OrderGroupIDSeq,
                                                    @IPVC_OrderItemIDSeq   = NULL,
                                                    @IPI_IsCustomBundle    = @IPB_IsCustomPackage, 
                                                    @IPVC_ProductCode      = NULL,
                                                    @IPVC_ChargeTypeCode   = 'ILF',
                                                    @IPBI_UserIDSeq        = @LBI_ModifiedByUserIDSeq  
      ------------------------------------------------------------------
    END
    -------------------------------------------------------------------------------------------------------
    ------------> Custom Bundle ACS Section
    -------------------------------------------------------------------------------------------------------
    --Case 1:
    ELSE if (@IPVC_ChargeTypeCode = 'ACS' and @IPVC_Status = 'FULF')
    BEGIN
      ---Update for S&H Amount for Custom Bundle for ACS
      if @IPVC_SHCharge <> 0
      begin
        select @LBI_CB_MinOrderItemIDSeq = Min(IDSeq)
        from   Orders.dbo.Orderitem with (nolock)
        where  OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
        and    OrderIDSeq                = @IPVC_Orderidseq
        and    RenewalCount              = @IPI_RenewalCount 
        and    ChargeTypeCode            = 'ACS'
 
        Update ORDERS.dbo.Orderitem  with (rowlock)
        set    ShippingAndHandlingAmount = @IPVC_SHCharge,
               ModifiedByUserIDSeq       = @LBI_ModifiedByUserIDSeq,
               ModifiedDate              = @LDT_SystemDate,
               SystemLogDate             = @LDT_SystemDate
        where  IDSeq                     = @LBI_CB_MinOrderItemIDSeq
        and    OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
        and    OrderIDSeq                = @IPVC_Orderidseq
        and    RenewalCount              = @IPI_RenewalCount 
        and    ChargeTypeCode            = 'ACS'
      end
      ---Step 1 : Update ACS Records for ActivationStart,ActivationEndDates for all products in the Group.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ActivationStartDate = (Case isdate(@IPVC_StartDate) When 0 Then NULL else @IPVC_StartDate End),
             ActivationEndDate   = (Case @IPVC_EndDate When '' Then NULL else @IPVC_EndDate End), 
             StartDate           = (Case isdate(@IPVC_StartDate) When 0 Then NULL else @IPVC_StartDate End),
             EndDate             = (Case @IPVC_EndDate When '' Then NULL else @IPVC_EndDate End), 
             CancelDate          = NULL,
             RenewalTypeCode     = (case when (FrequencyCode = 'OT' or FrequencyCode = 'SG' or Productcode in ('DMD-PSR-ADM-ADM-AHDA','DMD-PSR-ADM-ADM-AHDF')) then 'DRNW' 
                                         else coalesce(@IPVC_Renewal,RenewalTypeCode) end), 
             StatusCode          = @IPVC_Status,
             FulfilledByIDSeq    = @LBI_ModifiedByUserIDSeq,
             FulfilledDate       = @LDT_SystemDate,
             ModifiedByUserIDSeq = @LBI_ModifiedByUserIDSeq,
             ModifiedDate        = @LDT_SystemDate,
             LastBillingPeriodFromDate = (Case when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodFromDate)=1) then LastBillingPeriodFromDate -->For NewQuote Order if LastBillingPeriodFromDate is already filled, Don't change.
                                               when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodFromDate)=0) then NULL                      -->For NewQuote Order if LastBillingPeriodFromDate is not filled, Don't change. 
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=1)     then LastBillingPeriodFromDate -->For 'STFQ','RPRQ' and LastBillingPeriodFromDate is already fileld,Don't change.
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=1) then @IPVC_StartDate           -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is valid then @IPVC_StartDate
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=0) then NULL                      -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is null then NULL
                                               Else NULL
                                          End),
             LastBillingPeriodToDate   = (Case when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodToDate)=1) then LastBillingPeriodToDate -->For NewQuote Order if LastBillingPeriodToDate is already filled, Don't change.
                                               when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodToDate)=0) then NULL                      -->For NewQuote Order if LastBillingPeriodToDate is not filled, Don't change. 
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=1)     then LastBillingPeriodToDate -->For 'STFQ','RPRQ' and LastBillingPeriodToDate is already filled,Don't change.
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=1) then @IPVC_LastBillingPeriodToDate  -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is valid then @IPVC_LastBillingPeriodToDate
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=0) then NULL                           -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is null then NULL
                                               Else NULL
                                          End),
             POILastBillingPeriodFromDate = (Case when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodFromDate)=1) then LastBillingPeriodFromDate -->For NewQuote Order if LastBillingPeriodFromDate is already filled, Don't change.
                                               when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodFromDate)=0) then NULL                      -->For NewQuote Order if LastBillingPeriodFromDate is not filled, Don't change. 
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=1)     then LastBillingPeriodFromDate -->For 'STFQ','RPRQ' and LastBillingPeriodFromDate is already fileld,Don't change.
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=1) then @IPVC_StartDate           -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is valid then @IPVC_StartDate
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=0) then NULL                      -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is null then NULL
                                               Else NULL
                                          End),
             POILastBillingPeriodToDate   = (Case when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodToDate)=1) then LastBillingPeriodToDate -->For NewQuote Order if LastBillingPeriodToDate is already filled, Don't change.
                                               when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodToDate)=0) then NULL                      -->For NewQuote Order if LastBillingPeriodToDate is not filled, Don't change. 
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=1)     then LastBillingPeriodToDate -->For 'STFQ','RPRQ' and LastBillingPeriodToDate is already filled,Don't change.
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=1) then @IPVC_LastBillingPeriodToDate  -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is valid then @IPVC_LastBillingPeriodToDate
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=0) then NULL                           -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is null then NULL
                                               Else NULL
                                          End),
             SystemLogDate             = @LDT_SystemDate
      where  OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq 
      and    RenewalCount              = @IPI_RenewalCount 
      and    ChargeTypeCode            = 'ACS'
      and    StatusCode                = 'PEND' --> Only when Current Orderitem Status = Pending, do we allow to Fulfil.
      ---Step 2 : Carry Over this ActivationStartDate and ActivationEndDate to ILF Records for all products in the Group, irrespective of corresponding ILF statuses.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ActivationStartDate = (Case isdate(@IPVC_StartDate) When 0 Then NULL Else @IPVC_StartDate End),
             ActivationEndDate   = (Case @IPVC_EndDate When '' Then NULL else @IPVC_EndDate End)              
      where  OrderGroupIDSeq     = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq          = @IPVC_Orderidseq
      and    RenewalCount        = @IPI_RenewalCount  
      and    ChargeTypeCode      = 'ILF'
      ---Step 3 : If ACS is the first Item to get fullfilled then corresponding ILF item should also get fullfilled.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ILFStartDate     = (Case isdate(@IPVC_StartDate) When 0 Then NULL Else @IPVC_StartDate End),
             ILFEndDate       = (CASE isdate(@IPVC_EndDate) when 1
                                          then @IPVC_EndDate
                                      else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                               else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                            end)
                                 END),
             StartDate        = (Case isdate(@IPVC_StartDate) When 0 Then NULL Else @IPVC_StartDate End),
             EndDate          = (CASE isdate(@IPVC_EndDate) when 1
                                          then @IPVC_EndDate
                                      else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                               else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                            end)
                                 END),
             CancelDate       = NULL,
             RenewalTypeCode  = (case when (FrequencyCode = 'OT' or FrequencyCode = 'SG' or Productcode in ('DMD-PSR-ADM-ADM-AHDA','DMD-PSR-ADM-ADM-AHDF')) then 'DRNW' 
                                      else coalesce(@IPVC_Renewal,RenewalTypeCode) end),
             StatusCode       = 'FULF',
             FulfilledByIDSeq     = @LBI_ModifiedByUserIDSeq,
             FulfilledDate        = @LDT_SystemDate,
             ModifiedByUserIDSeq  = @LBI_ModifiedByUserIDSeq,
             ModifiedDate         = @LDT_SystemDate,
             SystemLogDate        = @LDT_SystemDate
      where  OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq       = @IPVC_Orderidseq 
      and    RenewalCount     = @IPI_RenewalCount 
      and    ChargeTypeCode   = 'ILF'
      and    StatusCode       in ('PEND','HOLD')
      ---Step 3 : If ILF item is already fullfilled then if ACS item is fullfilled, then updating ILFStartDate and ILFEndDate in ACS row
      select TOP 1 @LVC_ILFStartDate = ILFStartDate,
                   @LVC_ILFEndDate   = ILFEndDate
      from   ORDERS.dbo.Orderitem with (nolock)
      where  OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq      = @IPVC_Orderidseq
      and    RenewalCount    = @IPI_RenewalCount  
      and    ChargeTypeCode  = 'ILF'

      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ILFStartDate        = @LVC_ILFStartDate,
             ILFEndDate          = @LVC_ILFEndDate,
             RenewalTypeCode     = (case when (FrequencyCode = 'OT' or FrequencyCode = 'SG' or Productcode in ('DMD-PSR-ADM-ADM-AHDA','DMD-PSR-ADM-ADM-AHDF')) then 'DRNW' 
                                          else coalesce(@IPVC_Renewal,RenewalTypeCode) end)
      where  OrderGroupIDSeq     = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq          = @IPVC_Orderidseq
      and    RenewalCount        = @IPI_RenewalCount  
      and    ChargeTypeCode      = 'ACS'      
    END
    --Case 2 : 
    else if (@IPVC_ChargeTypeCode = 'ACS' and @IPVC_Status in('PEND','HOLD'))
    BEGIN
      UPDATE ORDERS.dbo.Orderitem with (rowlock)
      set    StatusCode            = @IPVC_Status,
             ModifiedByUserIDSeq   = @LBI_ModifiedByUserIDSeq,
             ModifiedDate          = @LDT_SystemDate,
             SystemLogDate         = @LDT_SystemDate
      where  OrderGroupIDSeq       = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq            = @IPVC_Orderidseq 
      and    RenewalCount          = @IPI_RenewalCount 
      and    ChargeTypeCode        = 'ACS'
      and    StatusCode           in ('PEND','HOLD') --> Only when Current Orderitem Status = Pending or HOLD, do we allow to continue to be in this status.
    END
    --Case 3 :
    else if (@IPVC_ChargeTypeCode = 'ACS' and @IPVC_Status = 'CNCL' and isdate(@IPVC_CancelDate)=1)
    BEGIN
      ---Step 1 : Cancellation of ACS will not trigger cancellation of ILF.
      UPDATE ORDERS.dbo.Orderitem with (rowlock)
      set    StatusCode            = @IPVC_Status,                          
             CancelDate            = (Case when isdate(@IPVC_CancelDate)=0 Then NULL Else @IPVC_CancelDate End),             
             CancelReasonCode      = nullif(@IPVC_CancelReason,''),
             CancelNotes           = @IPVC_CancelNotes,
             CancelByIDSeq         = @IPBI_UserIDSeq,
             CancelActivityDate    = @LDT_SystemDate,
             ModifiedByUserIDSeq   = @LBI_ModifiedByUserIDSeq,
             ModifiedDate          = @LDT_SystemDate,
             -------------------------
             RenewalTypeCode       ='DRNW',
             HistoryFlag           = 1, 
             HistoryDate           = @LDT_SystemDate,
             SystemLogDate         = @LDT_SystemDate
             -------------------------
      where  OrderGroupIDSeq       =  @IPVC_OrderGroupIDSeq
      and    OrderIDSeq            =  @IPVC_Orderidseq
      and    RenewalCount         >=  @IPI_RenewalCount  
      and    ChargeTypeCode        = 'ACS'
      and    StatusCode           not in ('EXPD','HOLD')
      and    (isdate(@IPVC_CancelDate)=1);---Canceldate is mandatory
      ------------------------------------------------------------------
      Exec INVOICES.dbo.uspINVOICES_RollBackInvoice @IPVC_Orderid          = @IPVC_Orderidseq,
                                                    @IPBI_OrderGroupID     = @IPVC_OrderGroupIDSeq,
                                                    @IPVC_OrderItemIDSeq   = NULL,
                                                    @IPI_IsCustomBundle    = @IPB_IsCustomPackage, 
                                                    @IPVC_ProductCode      = NULL,
                                                    @IPVC_ChargeTypeCode   = 'ACS',
                                                    @IPBI_UserIDSeq        = @LBI_ModifiedByUserIDSeq; 
      ------------------------------------------------------------------
    END
    ---------------------------------------------------------------------------    
  END--> Main End for @IPB_IsCustomPackage=1
  ---*********************************************************************************----
  ELSE 
  BEGIN --> Main Begin for Alarcarte products (ie @IPB_IsCustomPackage=0)
    --------------------------------------------------
    -- Updating Billing Address Code
    --------------------------------------------------
    SELECT top 1
               @LVC_ProductCode = ProductCode,
               @LVC_MasterOrderItemIDSeq = MasterOrderItemIDSeq
    FROM   Orders.dbo.OrderItem with (nolock)
    WHERE  IDSeq            = @IPVC_OrderItemIDSeq 
    AND    OrderGroupIDSeq  = @IPVC_OrderGroupIDSeq
    and    OrderIDSeq       = @IPVC_Orderidseq
    and    RenewalCount     = @IPI_RenewalCount    
    -------------------------------------------------------------------------------------------------------
    ------------> Alacarte Product ILF Section
    -------------------------------------------------------------------------------------------------------
    --Case 1:
    IF (@IPVC_ChargeTypeCode = 'ILF' and @IPVC_Status = 'FULF')
    BEGIN
      ---Step 1 : Update ILF Records for ILFStart,ILFEndDates
      ---         for @IPVC_OrderItemIDSeq and @LVC_ProductCode product in the Group.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ILFStartDate = (Case isdate(@IPVC_StartDate) When 0 Then NULL else @IPVC_StartDate End),
             ILFEndDate   = (CASE isdate(@IPVC_EndDate) when 1
                                          then @IPVC_EndDate
                                      else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                               else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                            end)
                             END),
             StartDate    = (Case isdate(@IPVC_StartDate) When 0 Then NULL else @IPVC_StartDate End),
             EndDate      = (CASE isdate(@IPVC_EndDate) when 1
                                          then @IPVC_EndDate
                                      else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                               else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                            end)
                             END),
             CancelDate      = NULL,
             RenewalTypeCode = (case when (FrequencyCode = 'OT' or FrequencyCode = 'SG' or Productcode in ('DMD-PSR-ADM-ADM-AHDA','DMD-PSR-ADM-ADM-AHDF')) then 'DRNW' 
                                      else coalesce(@IPVC_Renewal,RenewalTypeCode) end),
             StatusCode      = @IPVC_Status,
             FulfilledByIDSeq          = @LBI_ModifiedByUserIDSeq,
             FulfilledDate             = @LDT_SystemDate,
             ShippingAndHandlingAmount = @IPVC_SHCharge,
             ModifiedByUserIDSeq       = @LBI_ModifiedByUserIDSeq,
             ModifiedDate              = @LDT_SystemDate,
             SystemLogDate             = @LDT_SystemDate
      where  IDSeq                     = @IPVC_OrderItemIDSeq
      and    OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq 
      and    RenewalCount              = @IPI_RenewalCount
      and    ProductCode               = @LVC_ProductCode
      and    ChargeTypeCode            = 'ILF'
      and    StatusCode                = 'PEND' --> Only when Current Orderitem Status = Pending, do we allow to Fulfil.
      ---Step 2 : Carry Over this ILFStartDate and EndDate to ACS Record for @LVC_ProductCode product in the Group, irrespective of status.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ILFStartDate = (Case isdate(@IPVC_StartDate) When 0 Then NULL Else @IPVC_StartDate End),
             ILFEndDate   = (CASE isdate(@IPVC_EndDate) when 1
                                          then @IPVC_EndDate
                                      else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                               else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                            end)
                             END)
      where  OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq       
      and    OrderIDSeq                = @IPVC_Orderidseq 
      and    RenewalCount              = @IPI_RenewalCount
      and    ProductCode               = @LVC_ProductCode
      and    ChargeTypeCode            = 'ACS'
    END
    --Case 2 : 
    else if (@IPVC_ChargeTypeCode = 'ILF' and @IPVC_Status in('PEND','HOLD'))
    BEGIN
      UPDATE ORDERS.dbo.Orderitem with (rowlock)
      set    StatusCode    = @IPVC_Status,
             ModifiedByUserIDSeq       = @LBI_ModifiedByUserIDSeq,
             ModifiedDate              = @LDT_SystemDate,
             SystemLogDate             = @LDT_SystemDate
      where  IDSeq                     = @IPVC_OrderItemIDSeq
      and    OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq 
      and    RenewalCount              = @IPI_RenewalCount
      and    ProductCode               = @LVC_ProductCode
      and    ChargeTypeCode            = 'ILF'
      and    StatusCode                in ('PEND','HOLD') --> Only when Current Orderitem Status = Pending or HOLD, do we allow to continue to be in this status.
    END
    --Case 3 :
    else if (@IPVC_ChargeTypeCode = 'ILF' and @IPVC_Status = 'CNCL' and isdate(@IPVC_CancelDate)=1)
    BEGIN
      ---Step 1 : Cancellation of ILF will not trigger cancellation of ACS.
      UPDATE ORDERS.dbo.Orderitem with (rowlock)
      set    StatusCode        = @IPVC_Status,                      
             CancelDate        = (Case when isdate(@IPVC_CancelDate)=0 Then NULL Else @IPVC_CancelDate End),             
             CancelReasonCode  = nullif(@IPVC_CancelReason,''),
             CancelNotes       = @IPVC_CancelNotes,
             CancelByIDSeq     = @IPBI_UserIDSeq,
             CancelActivityDate= @LDT_SystemDate,
             ModifiedByUserIDSeq  = @LBI_ModifiedByUserIDSeq,
             ModifiedDate         = @LDT_SystemDate,
             -------------------------
             RenewalTypeCode  ='DRNW',
             HistoryFlag      = 1, 
             HistoryDate      = @LDT_SystemDate,
             SystemLogDate    = @LDT_SystemDate
             -------------------------
      where  IDSeq                     = @IPVC_OrderItemIDSeq
      and    OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq
      and    RenewalCount              = @IPI_RenewalCount  
      and    ProductCode               = @LVC_ProductCode
      and    ChargeTypeCode            = 'ILF' 
      and    StatusCode                not in ('EXPD','HOLD')
      and    (isdate(@IPVC_CancelDate)=1) -- Canceldate is mandatory    

      -----------------------------------------------------------------
      Exec INVOICES.dbo.uspINVOICES_RollBackInvoice @IPVC_Orderid          = @IPVC_Orderidseq,
                                                    @IPBI_OrderGroupID     = @IPVC_OrderGroupIDSeq,
                                                    @IPVC_OrderItemIDSeq   = @IPVC_OrderItemIDSeq,
                                                    @IPI_IsCustomBundle    = @IPB_IsCustomPackage, 
                                                    @IPVC_ProductCode      = @LVC_ProductCode,
                                                    @IPVC_ChargeTypeCode   = 'ILF',
                                                    @IPBI_UserIDSeq        = @LBI_ModifiedByUserIDSeq 
      ------------------------------------------------------------------
    END
    -------------------------------------------------------------------------------------------------------
    ------------> Alacarte Product ACS Section
    -------------------------------------------------------------------------------------------------------
    --Case 1:
    ELSE if (@IPVC_ChargeTypeCode = 'ACS' and @IPVC_Status = 'FULF')
    BEGIN
      ---Step 1 : Update ACS Records for ActivationStart,ActivationEndDates 
      ----        for @IPVC_OrderItemIDSeq and @LVC_ProductCode product in the Group.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ActivationStartDate = (Case isdate(@IPVC_StartDate) When 0 Then NULL else @IPVC_StartDate End),
             ActivationEndDate   = (Case @IPVC_EndDate When '' Then NULL else @IPVC_EndDate End),  
             StartDate           = (Case isdate(@IPVC_StartDate) When 0 Then NULL else @IPVC_StartDate End),
             EndDate             = (Case @IPVC_EndDate When '' Then NULL else @IPVC_EndDate End),
             CancelDate          = NULL,  
             RenewalTypeCode     = (case when (FrequencyCode = 'OT' or FrequencyCode = 'SG' or Productcode in ('DMD-PSR-ADM-ADM-AHDA','DMD-PSR-ADM-ADM-AHDF')) then 'DRNW' 
                                         else coalesce(@IPVC_Renewal,RenewalTypeCode) end), 
             StatusCode          = @IPVC_Status,
             FulfilledByIDSeq          = @LBI_ModifiedByUserIDSeq,
             FulfilledDate             = @LDT_SystemDate,
             ShippingAndHandlingAmount = @IPVC_SHCharge,
             ModifiedByUserIDSeq       = @LBI_ModifiedByUserIDSeq,
             ModifiedDate              = @LDT_SystemDate,
             LastBillingPeriodFromDate = (Case when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodFromDate)=1) then LastBillingPeriodFromDate -->For NewQuote Order if LastBillingPeriodFromDate is already filled, Don't change.
                                               when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodFromDate)=0) then NULL                      -->For NewQuote Order if LastBillingPeriodFromDate is not filled, Don't change. 
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=1)     then LastBillingPeriodFromDate -->For 'STFQ','RPRQ' and LastBillingPeriodFromDate is already fileld,Don't change.
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=1) then @IPVC_StartDate           -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is valid then @IPVC_StartDate
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=0) then NULL                      -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is null then NULL
                                               Else NULL
                                          End),
             LastBillingPeriodToDate   = (Case when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodToDate)=1) then LastBillingPeriodToDate -->For NewQuote Order if LastBillingPeriodToDate is already filled, Don't change.
                                               when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodToDate)=0) then NULL                      -->For NewQuote Order if LastBillingPeriodToDate is not filled, Don't change. 
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=1)     then LastBillingPeriodToDate -->For 'STFQ','RPRQ' and LastBillingPeriodToDate is already filled,Don't change.
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=1) then @IPVC_LastBillingPeriodToDate  -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is valid then @IPVC_LastBillingPeriodToDate
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=0) then NULL                           -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is null then NULL
                                               Else NULL
                                          End),
             POILastBillingPeriodFromDate = (Case when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodFromDate)=1) then LastBillingPeriodFromDate -->For NewQuote Order if LastBillingPeriodFromDate is already filled, Don't change.
                                               when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodFromDate)=0) then NULL                      -->For NewQuote Order if LastBillingPeriodFromDate is not filled, Don't change. 
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=1)     then LastBillingPeriodFromDate -->For 'STFQ','RPRQ' and LastBillingPeriodFromDate is already fileld,Don't change.
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=1) then @IPVC_StartDate           -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is valid then @IPVC_StartDate
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodFromDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=0) then NULL                      -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is null then NULL
                                               Else NULL
                                          End),
             POILastBillingPeriodToDate   = (Case when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodToDate)=1) then LastBillingPeriodToDate -->For NewQuote Order if LastBillingPeriodToDate is already filled, Don't change.
                                               when (@IPVC_QuoteTypeCode = 'NEWQ' and isdate(LastBillingPeriodToDate)=0) then NULL                      -->For NewQuote Order if LastBillingPeriodToDate is not filled, Don't change. 
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=1)     then LastBillingPeriodToDate -->For 'STFQ','RPRQ' and LastBillingPeriodToDate is already filled,Don't change.
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=1) then @IPVC_LastBillingPeriodToDate  -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is valid then @IPVC_LastBillingPeriodToDate
                                               When (@IPVC_QuoteTypeCode in ('STFQ','RPRQ') and isdate(LastBillingPeriodToDate)=0  and isdate(@IPVC_LastBillingPeriodToDate)=0) then NULL                           -->For 'STFQ','RPRQ' and if brand new and if @IPVC_LastBillingPeriodToDate is null then NULL
                                               Else NULL
                                          End),
             SystemLogDate             = @LDT_SystemDate
      where  IDSeq                     = @IPVC_OrderItemIDSeq
      and    OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq 
      and    RenewalCount              = @IPI_RenewalCount
      and    ProductCode               = @LVC_ProductCode
      and    ChargeTypeCode            = 'ACS'
      and    StatusCode                = 'PEND' --> Only when Current Orderitem Status = Pending, do we allow to Fulfil.
      ---Step 2 : Carry Over this ActivationStartDate and ActivationEndDate to ILF Record for @LVC_ProductCode product in the Group, irrespective of status.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ActivationStartDate = (Case isdate(@IPVC_StartDate) When 0 Then NULL Else @IPVC_StartDate End),
             ActivationEndDate   = (Case isdate(@IPVC_EndDate)   When 0 Then NULL else @IPVC_EndDate End)             
      where  OrderGroupIDSeq     = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq          = @IPVC_Orderidseq 
      and    RenewalCount        = @IPI_RenewalCount
      and    ProductCode         = @LVC_ProductCode
      and    ChargeTypeCode      = 'ILF'
      ---Step 3 : If ACS is the first Item to get fullfilled then corresponding ILF item should also get fullfilled.
      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ILFStartDate        = (Case isdate(@IPVC_StartDate) When 0 Then NULL Else @IPVC_StartDate End),
             ILFEndDate          = (CASE isdate(@IPVC_EndDate) when 1
                                          then @IPVC_EndDate
                                         else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                               else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                            end)
                                    END),
             StartDate           = (Case isdate(@IPVC_StartDate) When 0 Then NULL Else @IPVC_StartDate End),
             EndDate             = (CASE isdate(@IPVC_EndDate)   when 1 then @IPVC_EndDate
                                         else (Case isdate(@IPVC_StartDate) When 0 Then NULL 
                                               else convert(varchar(20),dateadd(yy,1,convert(datetime,@IPVC_StartDate)),101) 
                                            end)
                                    END),
             CancelDate          = NULL, 
             RenewalTypeCode     = (case when (FrequencyCode = 'OT' or FrequencyCode = 'SG' or Productcode in ('DMD-PSR-ADM-ADM-AHDA','DMD-PSR-ADM-ADM-AHDF')) then 'DRNW'
                                         else coalesce(@IPVC_Renewal,RenewalTypeCode) end),
             StatusCode          = 'FULF',
             FulfilledByIDSeq          = @LBI_ModifiedByUserIDSeq,
             FulfilledDate             = @LDT_SystemDate,
             ModifiedByUserIDSeq       = @LBI_ModifiedByUserIDSeq,
             ModifiedDate              = @LDT_SystemDate,
             SystemLogDate             = @LDT_SystemDate
      where  OrderGroupIDSeq     = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq          = @IPVC_Orderidseq 
      and    RenewalCount        = @IPI_RenewalCount
      and    ProductCode         = @LVC_ProductCode
      and    ChargeTypeCode      = 'ILF'
      and    StatusCode         in ('PEND','HOLD')
      ---Step 3 : If ILF item is already fullfilled then if ACS item is fullfilled, then updating ILFStartDate and ILFEndDate in ACS row
      select TOP 1 @LVC_ILFStartDate = ILFStartDate,
                   @LVC_ILFEndDate   = ILFEndDate
      from   ORDERS.dbo.Orderitem with (nolock)
      where  OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq      = @IPVC_Orderidseq 
      and    RenewalCount    = @IPI_RenewalCount
      and    ProductCode     = @LVC_ProductCode
      and    ChargeTypeCode  = 'ILF'

      Update ORDERS.dbo.Orderitem with (rowlock)
      set    ILFStartDate        = @LVC_ILFStartDate,
             ILFEndDate          = @LVC_ILFEndDate,
             RenewalTypeCode     = (case when (FrequencyCode = 'OT' or FrequencyCode = 'SG' or Productcode in ('DMD-PSR-ADM-ADM-AHDA','DMD-PSR-ADM-ADM-AHDF')) then 'DRNW' 
                                          else coalesce(@IPVC_Renewal,RenewalTypeCode) end)
      where  IDSeq                     = @IPVC_OrderItemIDSeq
      and    OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq
      and    RenewalCount              = @IPI_RenewalCount 
      and    ProductCode               = @LVC_ProductCode
      and    ChargeTypeCode            = 'ACS'     
    END
    --Case 2 : 
    else if (@IPVC_ChargeTypeCode = 'ACS' and @IPVC_Status in('PEND','HOLD'))
    BEGIN
      UPDATE ORDERS.dbo.Orderitem with (rowlock)
      set    StatusCode           = @IPVC_Status,
             ModifiedByUserIDSeq  = @LBI_ModifiedByUserIDSeq,
             ModifiedDate         = @LDT_SystemDate,
             SystemLogDate             = @LDT_SystemDate
      where  IDSeq                     = @IPVC_OrderItemIDSeq
      and    OrderGroupIDSeq           = @IPVC_OrderGroupIDSeq
      and    OrderIDSeq                = @IPVC_Orderidseq 
      and    RenewalCount              = @IPI_RenewalCount
      and    ProductCode               = @LVC_ProductCode
      and    ChargeTypeCode            = 'ACS'
      and    StatusCode                in ('HOLD','PEND') --> Only when Current Orderitem Status = Pending or HOLD, do we allow to continue to be in this status.
    END
    --Case 3 :
    else if (@IPVC_ChargeTypeCode = 'ACS' and @IPVC_Status = 'CNCL' and isdate(@IPVC_CancelDate)=1) 
    BEGIN
      ---Step 1 : Cancellation of ACS will not trigger cancellation of ILF.
      UPDATE ORDERS.dbo.Orderitem with (rowlock)
      set    StatusCode           = @IPVC_Status,                          
             CancelDate           = (Case When isdate(@IPVC_CancelDate)=0 Then NULL Else @IPVC_CancelDate End),             
             CancelReasonCode     = nullif(@IPVC_CancelReason,''),
             CancelNotes          = @IPVC_CancelNotes,
             CancelByIDSeq        = @IPBI_UserIDSeq,
             CancelActivityDate   = @LDT_SystemDate, 
             ModifiedByUserIDSeq  = @LBI_ModifiedByUserIDSeq,
             ModifiedDate         = @LDT_SystemDate,
             -------------------------
             RenewalTypeCode      = 'DRNW',
             HistoryFlag          = 1, 
             HistoryDate          = @LDT_SystemDate,
             SystemLogDate        = @LDT_SystemDate
             -------------------------
      where  OrderIDSeq           = @IPVC_Orderidseq 
      and    OrderGroupIDSeq      = @IPVC_OrderGroupIDSeq
      and    RenewalCount         >= @IPI_RenewalCount
      and    ProductCode          = @LVC_ProductCode
      and    (IDSeq               = @IPVC_OrderItemIDSeq
                 OR
              MasterOrderItemIDSeq = @LVC_MasterOrderItemIDSeq
             )
      and    ChargeTypeCode       = 'ACS'
      and    StatusCode          not in ('EXPD','HOLD')
      and    (isdate(@IPVC_CancelDate)=1);----Canceldate is mandatory

      ------------------------------------------------------------------
      Exec INVOICES.dbo.uspINVOICES_RollBackInvoice @IPVC_Orderid          = @IPVC_Orderidseq,
                                                    @IPBI_OrderGroupID     = @IPVC_OrderGroupIDSeq,
                                                    @IPVC_OrderItemIDSeq   = @IPVC_OrderItemIDSeq,
                                                    @IPI_IsCustomBundle    = @IPB_IsCustomPackage, 
                                                    @IPVC_ProductCode      = @LVC_ProductCode,
                                                    @IPVC_ChargeTypeCode   = 'ACS',
                                                    @IPBI_UserIDSeq        = @LBI_ModifiedByUserIDSeq; 
      ------------------------------------------------------------------
    END
    ---------------------------------------------------------------------------    
  END--> Main End for Alarcarte products (ie @IPB_IsCustomPackage=0)
  ---*********************************************************************************----
  ----------------------------------------------------------------------------
  ---Refresh INVOICES.dbo.BillingTargetDateMapping as it is critical for Invoicing.
  begin try
    EXEC INVOICES.dbo.uspINVOICES_BillingTargetDateMappingRefresh;
  end try
  Begin Catch
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = 'Proc:uspORDERS_UpdateProductDetails. Proc call uspINVOICES_BillingTargetDateMappingRefresh Failed.'
    return
  end   Catch 
  ----------------------------------------------------------------------------  
END
GO
