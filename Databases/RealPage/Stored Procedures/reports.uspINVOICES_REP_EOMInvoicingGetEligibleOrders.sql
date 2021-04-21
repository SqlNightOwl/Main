SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : INVOICES
-- Procedure Name  : [uspINVOICES_REP_EOMInvoicingGetEligibleOrders]
-- Description     : This procedure accepts necessary parameters and returns resultset based on BillingCycleDate and EOMRunType
--                   Called by UI SRS REPORT
-- Input Parameters: @IPDT_BillingCycleDate
-- Code Example    : 
--  EXEC INVOICES.dbo.uspINVOICES_REP_EOMInvoicingGetEligibleOrders @IPDT_BillingCycleDate = '02/15/2010'
--  EXEC INVOICES.dbo.uspINVOICES_REP_EOMInvoicingGetEligibleOrders @IPDT_BillingCycleDate = '02/15/2010'
--  EXEC INVOICES.dbo.uspINVOICES_REP_EOMInvoicingGetEligibleOrders @IPDT_BillingCycleDate = '02/15/2010'
--Author           : SRS
--history          : Created 02/08/2010 Defect 7550

----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspINVOICES_REP_EOMInvoicingGetEligibleOrders]  (@IPDT_BillingCycleDate     datetime
                                                                  )
As
Begin
  set nocount on;
  ------------------------------------------------------------
  Create Table #LT_REP_TempOrdersTobeInvoiced
                                      (IDSeq                           bigint NOT NULL identity(1,1) primary key,
                                       CompanyName                     varchar(255)           NULL,
                                       PropertyName                    varchar(255)           NULL,
                                       AccountIDSeq                    varchar(22)            NOT NULL,
                                       CompanyIDSeq                    varchar(22)            NULL,
                                       PropertyIDSeq                   varchar(22)            NULL,  
                                       OrderIDSeq                      varchar(22)            NOT NULL,
                                       OrderItemIDSeq                  bigint                 NULL,
                                       ProductName                     varchar(255)           NULL,
                                       ReportingType                   varchar(100)           NULL,
                                       BillingClassification           varchar(200)           NULL,
                                       BeforeEOMBillingPeriodFromDate  datetime               NULL,
                                       BeforeEOMBillingPeriodToDate    datetime               NULL,
                                       ItemCount                       bigint                 NOT NULL Default(0)
                                      )
  ------------------------------------------------------------
  Insert into #LT_REP_TempOrdersTobeInvoiced(AccountIDSeq,CompanyIDSeq,PropertyIDSeq,OrderIDSeq,OrderItemIDSeq,
                                         BeforeEOMBillingPeriodFromDate,BeforeEOMBillingPeriodToDate,
                                         BillingClassification,ProductName,ReportingType,ItemCount
                                        )
  select  O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq, OI.IDSeq as OrderItemIDSeq,
          Max(OI.LastBillingPeriodFromDate) as BeforeEOMBillingPeriodFromDate,
          Max(OI.LastBillingPeriodToDate)   as BeforeEOMBillingPeriodToDate,
          'NewContractsBilling'        as BillingClassification,
          Max(P.DisplayName)           as ProductName,
          Max(RT.Name)                 as ReportingTypeName,
          Count(*)                     as ItemCount
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
  Inner Join
          Products.dbo.Product P With (nolock)
  on      OI.Productcode = P.code
  and     OI.priceversion= P.priceversion
  Inner Join
          Products.dbo.ReportingType RT with (nolock)
  on      OI.ReportingTypeCode = RT.Code
  Group by O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq, OI.IDSeq,OI.Productcode,OI.ReportingTypeCode  
  order by ProductName ASC,O.AccountIDSeq ASC,OI.OrderIDSeq ASC,OI.IDSeq ASC
  ---------------------------------------------------------------------------------------------------------------
  Insert into #LT_REP_TempOrdersTobeInvoiced(AccountIDSeq,CompanyIDSeq,PropertyIDSeq,OrderIDSeq,OrderItemIDSeq,
                                        BeforeEOMBillingPeriodFromDate,BeforeEOMBillingPeriodToDate,
                                        BillingClassification,ProductName,ReportingType,ItemCount
                                       ) 
  select O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq, OI.IDSeq as OrderItemIDSeq,
         Max(OI.LastBillingPeriodFromDate) as BeforeEOMBillingPeriodFromDate,
         Max(OI.LastBillingPeriodToDate)   as BeforeEOMBillingPeriodToDate,
         'RecurringMonthlyBilling'    as BillingClassification,
         Max(P.DisplayName)                as ProductName,
         Max(RT.Name)                      as ReportingTypeName,
         Count(*)                     as ItemCount
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
         )   
  ----------------
  Inner Join
          Products.dbo.Product P With (nolock)
  on      OI.Productcode = P.code
  and     OI.priceversion= P.priceversion
  Inner Join
          Products.dbo.ReportingType RT with (nolock)
  on      OI.ReportingTypeCode = RT.Code
  Group by O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq, OI.IDSeq,OI.Productcode,OI.ReportingTypeCode  
  order by ProductName ASC,O.AccountIDSeq ASC,OI.OrderIDSeq ASC,OI.IDSeq ASC
  ---------------------------------------------------------------------------------------------------------------  
  Insert into #LT_REP_TempOrdersTobeInvoiced(AccountIDSeq,CompanyIDSeq,PropertyIDSeq,OrderIDSeq,OrderItemIDSeq,
                                      BeforeEOMBillingPeriodFromDate,BeforeEOMBillingPeriodToDate,
                                      BillingClassification,ProductName,ReportingType,ItemCount
                                     )
  select O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq,OI.IDSEQ as OrderItemIDSeq,
         NULL   as BeforeEOMBillingPeriodFromDate,
         NULL   as BeforeEOMBillingPeriodToDate,
         'TransactionsBilling' as BillingClassification,
         Max(P.DisplayName)    as ProductName,
         Max(RT.Name)          as ReportingTypeName,
         Count(*)              as ItemCount
  from    ORDERS.dbo.[Order]     O  with (nolock)
  inner join 
          Orders.dbo.[Orderitem] OI with (nolock)
  on      OI.Orderidseq    = O.Orderidseq
  and     OI.StatusCode   <> 'EXPD'
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
          Products.dbo.Product P With (nolock)
  on      OI.Productcode = P.code
  and     OI.priceversion= P.priceversion
  Inner Join
          Products.dbo.ReportingType RT with (nolock)
  on      OI.ReportingTypeCode = RT.Code
  Inner Join
          Orders.dbo.[OrderItemTransaction] OIT with (nolock)
  on      OIT.OrderIDSeq = OI.OrderIDSeq
  and     OIT.OrderIDSeq = O.OrderIDSeq
  and     OI.IDseq       = OIT.OrderItemIDSeq
  and     OIT.TransactionalFlag = 1
  and     OIT.InvoicedFlag      = 0 
  and     OIT.ServiceDate       <= BTM.TargetDate
  Group by O.AccountIDSeq,O.CompanyIDSeq,O.PropertyIDSeq,OI.OrderIDSeq, OI.IDSeq,OI.Productcode,OI.ReportingTypeCode  
  order by ProductName ASC,O.AccountIDSeq ASC,OI.OrderIDSeq ASC,OI.IDSeq ASC   
  ------------------------------------------------------------
  Update D
  set    D.CompanyName = S.Name 
  from   #LT_REP_TempOrdersTobeInvoiced D with (nolock)
  inner Join
         Customers.dbo.Company S with (nolock)
  on     D.CompanyIDSeq = S.IDSeq
  
  Update D
  set    D.PropertyName = S.Name 
  from   #LT_REP_TempOrdersTobeInvoiced D with (nolock)
  inner Join
         Customers.dbo.Property S with (nolock)
  on     D.PropertyIDSeq = S.IDSeq
  ------------------------------------------------------------
  --Final select to EOM Program
  select CompanyName,PropertyName,AccountIDSeq,CompanyIDSeq,PropertyIDSeq,OrderIDSeq,OrderItemIDSeq,
         BeforeEOMBillingPeriodFromDate,BeforeEOMBillingPeriodToDate,
         BillingClassification,ProductName,ReportingType,ItemCount
  from   #LT_REP_TempOrdersTobeInvoiced with (nolock)
  order by IDSeq ASC,CompanyName ASC,PropertyName ASC
  ------------------------------------------------------------
  if (object_id('tempdb.dbo.#LT_REP_TempOrdersTobeInvoiced') is not null) 
  begin
    drop table #LT_REP_TempOrdersTobeInvoiced
  end 
End
GO
