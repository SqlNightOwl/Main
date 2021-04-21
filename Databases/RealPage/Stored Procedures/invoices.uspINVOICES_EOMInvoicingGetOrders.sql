SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [invoices].[uspINVOICES_EOMInvoicingGetOrders]  (@IPDT_BillingCycleDate     datetime,
                                                       @IPI_EOMRunBatchNumber     int,
                                                       @IPVC_EOMRunType           varchar(200)='NewContractsBilling',
                                                       @IPBI_UserIDSeq            bigint = NULL                                                                
                                                      )
As
Begin
  set nocount on;

  Delete from INVOICES.dbo.InvoiceEOMRunLog where EOMRunStatus = 2 and EOMRunBatchNumber <> @IPI_EOMRunBatchNumber

  ------------------------------------------------------------
  Create Table #TempOrdersTobeInvoiced(SortSeq                         bigint not null identity(1,1) primary Key,
                                       AccountIDSeq                    varchar(22)  NOT NULL,
                                       CompanyIDSeq                    varchar(22)  NULL,
                                       PropertyIDSeq                   varchar(22)  NULL,  
                                       OrderIDSeq                      varchar(22)  NOT NULL,
                                       OrderItemIDSeq                  bigint       NULL,
                                       BeforeEOMBillingPeriodFromDate  datetime     NULL,
                                       BeforeEOMBillingPeriodToDate    datetime     NULL            
                                      )
  ------------------------------------------------------------
  If @IPVC_EOMRunType = 'NewContractsBilling'
  begin
    Insert into #TempOrdersTobeInvoiced(AccountIDSeq,CompanyIDSeq,PropertyIDSeq,OrderIDSeq,OrderItemIDSeq,
                                        BeforeEOMBillingPeriodFromDate,BeforeEOMBillingPeriodToDate
                                       )
    select  O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq, OI.IDSeq as OrderItemIDSeq,
            MAX(OI.LastBillingPeriodFromDate) as BeforeEOMBillingPeriodFromDate,
            MAX(OI.LastBillingPeriodToDate)   as BeforeEOMBillingPeriodToDate
    from    ORDERS.dbo.[Order]     O  with (nolock)
    inner join 
            Orders.dbo.[Orderitem] OI with (nolock)
    on      OI.Orderidseq    = O.Orderidseq
    and     OI.StatusCode    <> 'EXPD'
    and     OI.MeasureCode   <> 'TRAN'
    and     OI.DoNotInvoiceFlag    = 0
    ----------------
    inner Join
            Products.dbo.Charge C with (nolock)
    on      OI.ProductCode       = C.ProductCode
    and     OI.PriceVersion      = C.PriceVersion
    and     OI.ChargeTypeCode    = C.ChargeTypeCode
    and     OI.MeasureCode       = C.MeasureCode
    and     OI.FrequencyCode     = C.FrequencyCode
    Inner Join
            INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
    on      C.LeadDays           = BTM.LeadDays
    and     BTM.BillingCycleDate = @IPDT_BillingCycleDate
    ----------------
    and  (
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NULL
           )             
         )   
    ---------------- 
    /*
     ---->OLD Orginal Code
     and    (
             (OI.ChargeTypeCode = 'ILF' and (OI.ILFStartDate <> Coalesce(OI.canceldate,'')) and OI.ILFEndDate is NOT NULL ---->and OI.ILFStartDate <= @LDT_TargetDate Defect#5467
              and (coalesce(OI.Canceldate,OI.ILFStartDate) >= OI.ILFStartDate) and  OI.LastBillingPeriodToDate is NULL)
                     OR
             (OI.ChargeTypeCode = 'ACS' and OI.Frequencycode = 'OT'  and (OI.ActivationStartDate <> Coalesce(OI.canceldate,'')) and OI.ActivationEndDate is NOT NULL 
              and (coalesce(OI.Canceldate,OI.ActivationStartDate) >= OI.ActivationStartDate) and OI.LastBillingPeriodToDate is NULL)
                     OR
             (OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  <> 'OT' and (OI.ActivationStartDate <> Coalesce(OI.canceldate,'')) and OI.ActivationEndDate is NOT NULL and OI.ActivationStartDate <= @IPDT_EOMTargetDate 
              and (coalesce(OI.Canceldate,OI.ActivationStartDate) >= OI.ActivationStartDate) and  OI.LastBillingPeriodToDate is NULL)
           )
    */
    group by O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq, OI.IDSeq
    order by O.AccountIDSeq ASC,OI.OrderIDSeq ASC,OI.IDSeq ASC
  end
  else If @IPVC_EOMRunType = 'RecurringMonthlyBilling'
  begin
    Insert into #TempOrdersTobeInvoiced(AccountIDSeq,CompanyIDSeq,PropertyIDSeq,OrderIDSeq,OrderItemIDSeq,
                                        BeforeEOMBillingPeriodFromDate,BeforeEOMBillingPeriodToDate
                                       )
    select  O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq, OI.IDSeq as OrderItemIDSeq,
            MAX(OI.LastBillingPeriodFromDate) as BeforeEOMBillingPeriodFromDate,
            MAX(OI.LastBillingPeriodToDate)   as BeforeEOMBillingPeriodToDate
    from    ORDERS.dbo.[Order]     O  with (nolock)
    inner join 
            Orders.dbo.[Orderitem] OI with (nolock)
    on      OI.Orderidseq    = O.Orderidseq
    and     OI.StatusCode    <> 'EXPD'
    and     OI.MeasureCode   <> 'TRAN'
    and     OI.DoNotInvoiceFlag    = 0
    ------------
    inner Join
            Products.dbo.Charge C with (nolock)
    on      OI.ProductCode       = C.ProductCode
    and     OI.PriceVersion      = C.PriceVersion
    and     OI.ChargeTypeCode    = C.ChargeTypeCode
    and     OI.MeasureCode       = C.MeasureCode
    and     OI.FrequencyCode     = C.FrequencyCode
    Inner Join
            INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
    on      C.LeadDays           = BTM.LeadDays
    and     BTM.BillingCycleDate = @IPDT_BillingCycleDate
    ----------------
    and  (
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NOT NULL
             and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.EndDate)
             and  OI.LastBillingPeriodToDate < BTM.TargetDate
             and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  <> 'OT'
            )   

            OR

           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NULL
           )          

         )   
    ----------------
    /*
     ---->OLD Orginal Code
    AND  (      
           (OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  = 'MN' and (OI.ActivationStartDate <> Coalesce(OI.canceldate,'')) 
            and  OI.ActivationEndDate is NOT NULL and OI.ActivationStartDate <= @IPDT_EOMTargetDate 
            and (coalesce(OI.Canceldate,OI.ActivationStartDate) >= OI.ActivationStartDate)
            and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.ActivationEndDate)
            and  OI.LastBillingPeriodToDate < @IPDT_EOMTargetDate)
         )
    */
    group by O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq, OI.IDSeq
    order by O.AccountIDSeq ASC,OI.OrderIDSeq ASC
  end
  else If @IPVC_EOMRunType = 'TransactionsBilling'
  begin
    Insert into #TempOrdersTobeInvoiced(AccountIDSeq,CompanyIDSeq,PropertyIDSeq,OrderIDSeq,OrderItemIDSeq,
                                        BeforeEOMBillingPeriodFromDate,BeforeEOMBillingPeriodToDate
                                       )
    select  O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq,Min(OI.IDseq) as OrderItemIDSeq,
            NULL   as BeforeEOMBillingPeriodFromDate,
            NULL   as BeforeEOMBillingPeriodToDate
    from    ORDERS.dbo.[Order]     O  with (nolock)
    inner join 
            Orders.dbo.[Orderitem] OI with (nolock)
    on      OI.Orderidseq    = O.Orderidseq    
    and     OI.MeasureCode   = 'TRAN'
    and     OI.DoNotInvoiceFlag    = 0
    ------------
    inner Join
            Products.dbo.Charge C with (nolock)
    on      OI.ProductCode       = C.ProductCode
    and     OI.PriceVersion      = C.PriceVersion
    and     OI.ChargeTypeCode    = C.ChargeTypeCode
    and     OI.MeasureCode       = C.MeasureCode
    and     OI.FrequencyCode     = C.FrequencyCode
    Inner Join
            INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
    on      C.LeadDays           = BTM.LeadDays
    and     BTM.BillingCycleDate = @IPDT_BillingCycleDate
    ----------------
    Inner Join
          Orders.dbo.[OrderItemTransaction] OIT with (nolock)
    on      OIT.OrderIDSeq = OI.OrderIDSeq
    and     OIT.OrderIDSeq = O.OrderIDSeq
    and     OI.IDseq       = OIT.OrderItemIDSeq
    and     OIT.TransactionalFlag = 1
    and     OIT.InvoicedFlag      = 0 
    and     OIT.ServiceDate       <= BTM.TargetDate
    group by O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq
    order by O.AccountIDSeq ASC,OI.OrderIDSeq ASC                    
  end 
  ------------------------------------------------------------
  ---Insert into InvoiceEOMRunLog
  Insert into INVOICES.dbo.InvoiceEOMRunLog(AccountIDSeq,CompanyIDSeq,PropertyIDSeq,OrderIDSeq,OrderItemIDSeq,
                                            BeforeEOMBillingPeriodFromDate,BeforeEOMBillingPeriodToDate,
                                            BillingCycleDate,EOMRunType,EOMRunBatchNumber,EOMRunStatus,
                                            CreatedByIDSeq,CreatedDate
                                           )
  select AccountIDSeq,CompanyIDSeq,PropertyIDSeq,OrderIDSeq,OrderItemIDSeq,
         BeforeEOMBillingPeriodFromDate,BeforeEOMBillingPeriodToDate,
         @IPDT_BillingCycleDate as EOMTargetDate,
         @IPVC_EOMRunType       as EOMRunType,
         @IPI_EOMRunBatchNumber as EOMRunBatchNumber,0 as EOMRunStatus,
         @IPBI_UserIDSeq as CreatedByIDSeq,Getdate() as CreatedDate
  from   #TempOrdersTobeInvoiced with (nolock)
  order by SortSeq ASC;
  ------------------------------------------------------------
  --Final select to EOM Program
  select distinct [AccountIDSeq],[CompanyIDSeq],[PropertyIDSeq],[OrderIDSeq],[OrderItemIDSeq]
  from   #TempOrdersTobeInvoiced with (nolock)
  order by [AccountIDSeq] asc, [OrderIDSeq] asc, [OrderItemIDSeq] asc
  ------------------------------------------------------------
  --Final CleanUp
  if (object_id('tempdb.dbo.#TempOrdersTobeInvoiced') is not null) 
  begin
    drop table #TempOrdersTobeInvoiced
  end
  -----------------------------------------------------------
End
GO
