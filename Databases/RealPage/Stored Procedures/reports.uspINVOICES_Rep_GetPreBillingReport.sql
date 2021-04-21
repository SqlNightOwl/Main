SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
select   convert(varchar(50),Invoicedate,101) as InvoiceDate,printflag,count(*) as Recordcount
from     Invoices.dbo.Invoice with (nolock)
group by convert(varchar(50),Invoicedate,101),printflag
order by InvoiceDate desc
---------------------------------------
---Example Calls
--Sample 1 : To compare Current Billing cycle to Previous Billing Cycle.
Exec Invoices.dbo.uspINVOICES_Rep_GetPreBillingReport  @IPDT_CurrentCycleStartDate = '04/16/2009',@IPDT_CurrentCycleEndDate= '04/16/2009',
                                                       @IPDT_PreviousCycleStartDate='03/15/2009',@IPDT_PreviousCycleEndDate='03/15/2009'

Exec Invoices.dbo.uspINVOICES_Rep_GetPreBillingReport  @IPDT_CurrentCycleStartDate = '06/03/2009',@IPDT_CurrentCycleEndDate='06/03/2009',
                                                       @IPDT_PreviousCycleStartDate='05/06/2009',@IPDT_PreviousCycleEndDate='05/06/2009'  


Exec Invoices.dbo.uspINVOICES_Rep_GetPreBillingReport  @IPDT_CurrentCycleStartDate = '11/04/2009',@IPDT_CurrentCycleEndDate='11/04/2009',
                                                       @IPDT_PreviousCycleStartDate='10/03/2009',@IPDT_PreviousCycleEndDate='10/03/2009'  

--Sample 2: To compare 1 month (2 Billing cycles)  with previous 1 month (2 billing cycles.
Exec Invoices.dbo.uspINVOICES_Rep_GetPreBillingReport  @IPDT_CurrentCycleStartDate = '10/17/2009',@IPDT_CurrentCycleEndDate= '11/04/2009',
                                                       @IPDT_PreviousCycleStartDate='09/17/2009',@IPDT_PreviousCycleEndDate= '10/03/2009' 

Exec Invoices.dbo.uspINVOICES_Rep_GetPreBillingReport  @IPDT_CurrentCycleStartDate = '01/12/2010',@IPDT_CurrentCycleEndDate= '01/19/2010',
                                                       @IPDT_PreviousCycleStartDate='12/10/2009',@IPDT_PreviousCycleEndDate= '12/17/2009'
*/

--------------------------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : uspINVOICES_Rep_GetPreBillingReport      
-- Description     : This procedure gets rolled up Billing data for Passed in InvoiceDate and Compares it with last 
--                   Invoice cycle
-- Input Parameters: @IPDT_CurrentCycleStartDate,@IPDT_CurrentCycleEndDate,@IPDT_PreviousCycleStartDate,@IPDT_PreviousCycleEndDate
--            
-- Code Example    : Exec [dbo].[uspINVOICES_Rep_GetPreBillingReport]  @IPDT_CurrentCycleStartDate = '04/16/2009',
--                                                                     @IPDT_CurrentCycleEndDate   = '04/16/2009',                                                       
--                                                                     @IPDT_PreviousCycleStartDate= '03/15/2009',
--                                                                     @IPDT_PreviousCycleEndDate  = '03/15/2009', 
--                                                                     @IPI_ReportByBillingCycleDate = 1
-- Revision History:      
-- Author          : SRS
-- 05/15/2009      : Stored Procedure Created.      
-------------------------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspINVOICES_Rep_GetPreBillingReport] (@IPDT_CurrentCycleStartDate     datetime,
                                                      @IPDT_CurrentCycleEndDate       datetime,
                                                      @IPDT_PreviousCycleStartDate    datetime,
                                                      @IPDT_PreviousCycleEndDate      datetime,
                                                      @IPI_ReportByBillingCycleDate   int     = 1
                                                     )
AS      
BEGIN         
  SET NOCOUNT ON;   
  set ANSI_WARNINGS off;
  -------------------------------------------------------
  select @IPDT_CurrentCycleStartDate = convert(datetime,convert(varchar(50),@IPDT_CurrentCycleStartDate,101)),
         @IPDT_CurrentCycleEndDate   = convert(datetime,convert(varchar(50),@IPDT_CurrentCycleEndDate,101)), 
         @IPDT_PreviousCycleStartDate= convert(datetime,convert(varchar(50),@IPDT_PreviousCycleStartDate,101)),
         @IPDT_PreviousCycleEndDate  = convert(datetime,convert(varchar(50),@IPDT_PreviousCycleEndDate,101))
  -------------------------------------------------------
  Create table #LT_PreBillingReport(SortSeq                    int not null identity(1,1),
                                    CompanyID                  varchar(50),
                                    CompanyName                varchar(500),
                                    PropertyID                 varchar(50),
                                    PropertyName               varchar(500),
                                    AccountID                  varchar(50),                                    
                                    OrderID                    varchar(50),
                                    OrderGroupID               bigint,
                                    OrderItemID                bigint,
                                    RenewalCount               int,                                    
                                    ProductCode                varchar(50),
                                    ProductName                varchar(500),
                                    BundleName                 varchar(500),
                                    CustomBundleFlag           int,
                                    Family                     varchar(255),
                                    ReportingTypeCode          varchar(50),
                                    ReportingTypeName          varchar(255),
                                    ChargetypeCode             varchar(50),
                                    MeasureCode                varchar(50),
                                    FrequencyCode              varchar(50),                                    
                                    CurrentInvoiceID           varchar(50),
                                    CurrentInvoiceDate         varchar(50),
                                    CurrentUnits               int,
                                    CurrentBeds                int,
                                    CurrentPPU                 int,
                                    CurrentExtChargeAmount     numeric(30,2),
                                    CurrentEffectiveQuantity   float,
                                    CurrentDiscountAmount      numeric(30,2),
                                    CurrentChargeamount        numeric(30,3),
                                    CurrentNetChargeAmount     numeric(30,2),
                                    CurrentShippingAndHandlingAmount numeric(30,2),
                                    CurrentNetTaxAmount        numeric(30,2),
                                    CurrentMinBillingPeriod    datetime,
                                    CurrentMaxBillingPeriod    datetime,
                                    CurrentCountofRecords      int,
                                    Currentdate_applied        datetime,
                                    RenewalActivityMonth       varchar(50),                                    
                                    PreviousInvoiceID          varchar(50),
                                    PreviousInvoiceDate        varchar(50),
                                    PreviousUnits              int,
                                    PreviousBeds               int,
                                    PreviousPPU                int,
                                    PreviousExtChargeAmount    numeric(30,2),
                                    PreviousEffectiveQuantity  float,
                                    PreviousDiscountAmount     numeric(30,2),
                                    PreviousChargeamount       numeric(30,3),
                                    PreviousNetChargeAmount    numeric(30,2),                                   
                                    PreviousShippingAndHandlingAmount numeric(30,2),
                                    PreviousNetTaxAmount       numeric(30,2),
                                    PreviousCountofRecords     int,
                                    PreviousMinBillingPeriod   datetime,
                                    PreviousMaxBillingPeriod   datetime,
                                    Previousdate_applied       datetime
                                   );
  Create table #LT_CurrentPreBillingReport(SortSeq                    int not null identity(1,1),
                                    CompanyID                  varchar(50),
                                    CompanyName                varchar(500),
                                    PropertyID                 varchar(50),
                                    PropertyName               varchar(500),
                                    AccountID                  varchar(50),                                    
                                    OrderID                    varchar(50),
                                    OrderGroupID               bigint,
                                    OrderItemID                bigint,
                                    RenewalCount               int,                                    
                                    ProductCode                varchar(50),
                                    ProductName                varchar(500),
                                    BundleName                 varchar(500),
                                    CustomBundleFlag           int,
                                    Family                     varchar(255),
                                    ReportingTypeCode          varchar(50),
                                    ReportingTypeName          varchar(255),
                                    ChargetypeCode             varchar(50),
                                    MeasureCode                varchar(50),
                                    FrequencyCode              varchar(50),                                    
                                    CurrentInvoiceID           varchar(50),
                                    CurrentInvoiceDate         varchar(50),
                                    CurrentUnits               int,
                                    CurrentBeds                int,
                                    CurrentPPU                 int,
                                    CurrentExtChargeAmount     numeric(30,2),
                                    CurrentEffectiveQuantity   float,
                                    CurrentDiscountAmount      numeric(30,2),
                                    CurrentChargeamount        numeric(30,3),
                                    CurrentNetChargeAmount     numeric(30,2),                                   
                                    CurrentShippingAndHandlingAmount numeric(30,2),
                                    CurrentNetTaxAmount        numeric(30,2),
                                    CurrentMinBillingPeriod    datetime,
                                    CurrentMaxBillingPeriod    datetime,
                                    CurrentCountofRecords      int,
                                    RenewalActivityMonth       varchar(50),
                                    Currentdate_applied        datetime                                    
                                   );
  Create table #LT_PreviousPreBillingReport(SortSeq                    int not null identity(1,1),
                                    CompanyID                  varchar(50),
                                    CompanyName                varchar(500),
                                    PropertyID                 varchar(50),
                                    PropertyName               varchar(500),
                                    AccountID                  varchar(50),                                    
                                    OrderID                    varchar(50),
                                    OrderGroupID               bigint,
                                    OrderItemID                bigint,
                                    RenewalCount               int,                                    
                                    ProductCode                varchar(50),
                                    ProductName                varchar(500),
                                    BundleName                 varchar(500),
                                    CustomBundleFlag           int,
                                    Family                     varchar(255),
                                    ReportingTypeCode          varchar(50),
                                    ReportingTypeName          varchar(255),
                                    ChargetypeCode             varchar(50),
                                    MeasureCode                varchar(50),
                                    FrequencyCode              varchar(50),
                                    PreviousInvoiceID          varchar(50),
                                    PreviousInvoiceDate        varchar(50),
                                    PreviousUnits              int,
                                    PreviousBeds               int,
                                    PreviousPPU                int,
                                    PreviousExtChargeAmount    numeric(30,2),
                                    PreviousEffectiveQuantity  float,
                                    PreviousDiscountAmount     numeric(30,2),
                                    PreviousChargeamount       numeric(30,3),
                                    PreviousNetChargeAmount    numeric(30,2),                                    
                                    PreviousShippingAndHandlingAmount numeric(30,2), 
                                    PreviousNetTaxAmount              numeric(30,2),
                                    PreviousCountofRecords     int,
                                    PreviousMinBillingPeriod   datetime,
                                    PreviousMaxBillingPeriod   datetime,
                                    RenewalActivityMonth       varchar(50),
                                    Previousdate_applied       datetime 
                                   );
  --------------------------------------------------------------------------------
  ---Step 1 : Get Current Month : 
  Insert into #LT_CurrentPreBillingReport(CompanyID,CompanyName,PropertyID,PropertyName,AccountID,
                                   OrderID,OrderGroupID,OrderItemID,RenewalCount,ProductCode,ProductName,BundleName,CustomBundleFlag,
                                   Family,ReportingTypeCode,ChargetypeCode,MeasureCode,FrequencyCode,
                                   CurrentInvoiceID,CurrentInvoiceDate,CurrentUnits,CurrentBeds,CurrentPPU,
                                   CurrentExtChargeAmount,CurrentEffectiveQuantity,
                                   CurrentDiscountAmount,CurrentChargeamount,CurrentNetChargeAmount,
                                   CurrentShippingAndHandlingAmount,CurrentNetTaxAmount,
                                   CurrentMinBillingPeriod,CurrentMaxBillingPeriod,CurrentCountofRecords,RenewalActivityMonth,Currentdate_applied
                                   )
  select I.CompanyIDSeq,Max(I.CompanyName) as CompanyName,I.PropertyIDSeq as PropertyID,Max(I.PropertyName),I.AccountIDSeq as AccountID,
         II.OrderIDSeq,II.OrdergroupIDSeq,II.OrderItemIDSeq,II.OrderItemRenewalCount,II.ProductCode,Max(PRD.Displayname) as ProductName,
         (case when convert(int,IG.CustomBundleNameEnabledFlag) = 1 then Max(IG.Name) else NULL end) as BundleName,         
         convert(int,IG.CustomBundleNameEnabledFlag) as CustomBundleFlag,Max(F.Name) as FamilyName,II.ReportingTypeCode,II.ChargetypeCode,II.MeasureCode,II.FrequencyCode,
         Max(II.InvoiceIDSeq) as CurrentInvoiceID,Max(convert(varchar(50),I.InvoiceDate,101)) as CurrentInvoiceDate,Max(II.Units) as CurrentUnits,Max(II.Beds) as CurrentBeds,Max(II.PPUPercentage) as CurrentPPU,
         Sum(II.ExtChargeAmount) as CurrentExtChargeAmount,Sum(distinct II.EffectiveQuantity) as CurrentEffectiveQuantity,
         Sum(II.DiscountAmount) as CurrentDiscountAmount,
         Sum(II.ExtChargeAmount)/(Case when Sum(distinct II.EffectiveQuantity)=0 then 1 else Sum(distinct II.EffectiveQuantity) end) as CurrentChargeamount,
         Sum(II.NetChargeAmount) as CurrentNetChargeAmount,
         Sum(II.ShippingAndHandlingAmount) as CurrentShippingAndHandlingAmount,
         Sum(II.TaxAmount)       as CurrentNetTaxAmount,   
         Min(convert(varchar(50),II.BillingPeriodFromDate,101)) as CurrentMinBillingPeriod,Max(convert(varchar(50),II.BillingPeriodToDate,101)) as CurrentMaxBillingPeriod,
         Count(*)  as CurrentCountofRecords,
         (Case when isnumeric(Max(OI.RenewedFromOrderItemIDSeq))=1 then DATENAME(month,Max(OI.CreatedDate)) end) as RenewalActivityMonth,
         MAX(dateadd(dd,x.date_applied - 639906, '1/1/1753'))
  From   Invoices.dbo.Invoice I with (nolock)
  inner Join
         Invoices.dbo.InvoiceItem II with (nolock)
  on     I.InvoiceIDSeq = II.InvoiceIDSeq
  and  ( 
         (convert(datetime,convert(varchar(50),I.InvoiceDate,101)) >= @IPDT_CurrentCycleStartDate
                AND
          convert(datetime,convert(varchar(50),I.InvoiceDate,101)) <= @IPDT_CurrentCycleEndDate
                AND
          @IPI_ReportByBillingCycleDate = 0
         )
            OR
         (convert(datetime,convert(varchar(50),I.BillingCycleDate,101)) >= @IPDT_CurrentCycleStartDate
                AND
          convert(datetime,convert(varchar(50),I.BillingCycleDate,101)) <= @IPDT_CurrentCycleEndDate
                AND
          @IPI_ReportByBillingCycleDate = 1
         )
       )  
  inner Join
         Orders.dbo.Orderitem OI with (nolock)
  on     II.Orderidseq = OI.Orderidseq
  and    II.Ordergroupidseq = OI.OrderGroupidseq
  and    II.OrderitemIDSeq  = OI.IDSeq
  inner Join
         Invoices.dbo.InvoiceGroup IG With (nolock)
  on     IG.Invoiceidseq = II.Invoiceidseq
  and    IG.IDSeq        = II.InvoiceGroupidseq  
  inner Join
         Products.dbo.Product PRD with (nolock)
  on     II.ProductCode = PRD.Code
  and    II.Priceversion= PRD.Priceversion
  inner join
         Products.dbo.Family F with (nolock)
  on     PRD.FamilyCode = F.Code
  LEFT OUTER JOIN OMSREPORTS.dbo.artrx x with (nolock) on i.invoiceidseq=x.doc_ctrl_num and x.trx_type=2031
  group by
         I.CompanyIDSeq,I.PropertyIDSeq,I.AccountIDSeq,II.OrderIDSeq,II.OrdergroupIDSeq,II.OrderItemIDSeq,convert(int,IG.CustomBundleNameEnabledFlag),II.OrderItemRenewalCount,II.ProductCode,
         II.ReportingTypeCode,II.ChargetypeCode,II.MeasureCode,II.FrequencyCode   
  --------------------------------------------------------------------------------
  ---Step 1.1 : Get Previous Billing : 
  Insert into #LT_PreviousPreBillingReport(CompanyID,CompanyName,PropertyID,PropertyName,AccountID,
                                   OrderID,OrderGroupID,OrderItemID,RenewalCount,ProductCode,ProductName,BundleName,CustomBundleFlag,
                                   Family,ReportingTypeCode,ChargetypeCode,MeasureCode,FrequencyCode,
                                   PreviousInvoiceID,PreviousInvoiceDate,PreviousUnits,PreviousBeds,PreviousPPU,
                                   PreviousExtChargeAmount,PreviousEffectiveQuantity,
                                   PreviousDiscountAmount,PreviousChargeamount,PreviousNetChargeAmount,
                                   PreviousShippingAndHandlingAmount,PreviousNetTaxAmount,
                                   PreviousMinBillingPeriod,PreviousMaxBillingPeriod,PreviousCountofRecords,RenewalActivityMonth,Previousdate_applied
                                   )
  select I.CompanyIDSeq,Max(I.CompanyName) as CompanyName,I.PropertyIDSeq as PropertyID,Max(I.PropertyName),I.AccountIDSeq as AccountID,
         II.OrderIDSeq,II.OrdergroupIDSeq,II.OrderItemIDSeq,II.OrderItemRenewalCount,II.ProductCode,Max(PRD.Displayname) as ProductName,
         (case when convert(int,IG.CustomBundleNameEnabledFlag) = 1 then Max(IG.Name) else NULL end) as BundleName,
         convert(int,IG.CustomBundleNameEnabledFlag) as CustomBundleFlag,Max(F.Name) as FamilyName,II.ReportingTypeCode,II.ChargetypeCode,II.MeasureCode,II.FrequencyCode,
         Max(II.InvoiceIDSeq) as PreviousInvoiceID,Max(convert(varchar(50),I.InvoiceDate,101))  as PreviousInvoiceDate,Max(II.Units) as PreviousUnits,Max(II.Beds) as PreviousBeds,Max(II.PPUPercentage) as PreviousPPU,
         Sum(II.ExtChargeAmount) as PreviousExtChargeAmount,Sum(distinct II.EffectiveQuantity) as PreviousEffectiveQuantity,
         Sum(II.DiscountAmount) as PreviousDiscountAmount,
         Sum(II.ExtChargeAmount)/(Case when Sum(distinct II.EffectiveQuantity)=0 then 1 else Sum(distinct II.EffectiveQuantity) end) as PreviousChargeamount,
         Sum(II.NetChargeAmount) as PreviousNetChargeAmount,
         Sum(II.ShippingAndHandlingAmount) as PreviousShippingAndHandlingAmount,
         Sum(II.TaxAmount)        as PreviousNetTaxAmount,    
         Min(convert(varchar(50),II.BillingPeriodFromDate,101)) as PreviousMinBillingPeriod,Max(convert(varchar(50),II.BillingPeriodToDate,101)) as PreviousMaxBillingPeriod,
         Count(*)  as PreviousCountofRecords,
         (Case when isnumeric(Max(OI.RenewedFromOrderItemIDSeq))=1 then DATENAME(month,Max(OI.CreatedDate)) end) as RenewalActivityMonth,
         MAX(dateadd(dd,x.date_applied - 639906, '1/1/1753')) as Previous_applied
  From   Invoices.dbo.Invoice I with (nolock)
  inner Join
         Invoices.dbo.InvoiceItem II with (nolock)
  on     I.InvoiceIDSeq = II.InvoiceIDSeq  
  and  ( 
         (convert(datetime,convert(varchar(50),I.InvoiceDate,101)) >= @IPDT_PreviousCycleStartDate
            AND
          convert(datetime,convert(varchar(50),I.InvoiceDate,101)) <= @IPDT_PreviousCycleEndDate
            AND
          @IPI_ReportByBillingCycleDate = 0
          )
            OR
         (convert(datetime,convert(varchar(50),I.BillingCycleDate,101)) >= @IPDT_PreviousCycleStartDate
            AND
          convert(datetime,convert(varchar(50),I.BillingCycleDate,101)) <= @IPDT_PreviousCycleEndDate
            AND
          @IPI_ReportByBillingCycleDate = 1
         )
       ) 
  inner Join
         Orders.dbo.Orderitem OI with (nolock)
  on     II.Orderidseq = OI.Orderidseq
  and    II.Ordergroupidseq = OI.OrderGroupidseq
  and    II.OrderitemIDSeq  = OI.IDSeq
  inner Join
         Invoices.dbo.InvoiceGroup IG With (nolock)
  on     IG.Invoiceidseq = II.Invoiceidseq
  and    IG.IDSeq        = II.InvoiceGroupidseq  
  inner Join
         Products.dbo.Product PRD with (nolock)
  on     II.ProductCode = PRD.Code
  and    II.Priceversion= PRD.Priceversion
  inner join
         Products.dbo.Family F with (nolock)
  on     PRD.FamilyCode = F.Code
  LEFT OUTER JOIN OMSREPORTS.dbo.artrx x with (nolock) on i.invoiceidseq=x.doc_ctrl_num and x.trx_type=2031
  group by
         I.CompanyIDSeq,I.PropertyIDSeq,I.AccountIDSeq,II.OrderIDSeq,II.OrdergroupIDSeq,II.OrderItemIDSeq,convert(int,IG.CustomBundleNameEnabledFlag),II.OrderItemRenewalCount,II.ProductCode,
         II.ReportingTypeCode,II.ChargetypeCode,II.MeasureCode,II.FrequencyCode
  --------------------------------------------------------------------------------
  --Step 3 : Insert Final PreBillingReport
  Insert into #LT_PreBillingReport
              (CompanyID,CompanyName,PropertyID,PropertyName,AccountID,OrderID,OrderGroupID,OrderItemID,RenewalCount,ProductCode,ProductName,
               BundleName,CustomBundleFlag,Family,ReportingTypeCode,ChargetypeCode,MeasureCode,FrequencyCode,
               CurrentInvoiceID,CurrentInvoiceDate,CurrentUnits,CurrentBeds,CurrentPPU,CurrentExtChargeAmount,
               CurrentEffectiveQuantity,CurrentDiscountAmount,CurrentChargeamount,CurrentNetChargeAmount,
               CurrentShippingAndHandlingAmount,CurrentNetTaxAmount,
               CurrentMinBillingPeriod,CurrentMaxBillingPeriod,CurrentCountofRecords,RenewalActivityMonth,
               Currentdate_applied,
               PreviousInvoiceID,PreviousInvoiceDate,PreviousUnits,PreviousBeds,PreviousPPU,
               PreviousExtChargeAmount,PreviousEffectiveQuantity,
               PreviousDiscountAmount,PreviousChargeamount,PreviousNetChargeAmount,
               PreviousShippingAndHandlingAmount,PreviousNetTaxAmount,
               PreviousCountofRecords,PreviousMinBillingPeriod,PreviousMaxBillingPeriod,Previousdate_applied)
  select distinct
         coalesce(C.CompanyID,P.CompanyID),coalesce(C.CompanyName,P.CompanyName),
         coalesce(C.PropertyID,P.PropertyID),coalesce(C.PropertyName,P.PropertyName),
         coalesce(C.AccountID,P.AccountID),Max(coalesce(C.OrderID,P.OrderID)),Max(coalesce(C.OrderGroupID,P.OrderGroupID)),Max(coalesce(C.OrderItemID,P.OrderItemID)),
         Max(coalesce(C.RenewalCount,P.RenewalCount)),
         coalesce(C.ProductCode,P.Productcode),Max(coalesce(C.ProductName,P.ProductName)),
         Max(coalesce(C.BundleName,P.BundleName)) as BundleName,
         coalesce(C.CustomBundleFlag,P.CustomBundleFlag),Max(Coalesce(C.Family,P.Family)),
         coalesce(C.ReportingTypeCode,P.ReportingTypeCode),
         coalesce(C.ChargetypeCode,P.chargetypecode),coalesce(C.MeasureCode,P.Measurecode),coalesce(C.FrequencyCode,P.FrequencyCode),
         Max(C.CurrentInvoiceID),Max(C.CurrentInvoiceDate),Max(C.CurrentUnits),Max(C.CurrentBeds),Max(C.CurrentPPU),
         sum(C.CurrentExtChargeAmount),sum(C.CurrentEffectiveQuantity),
         sum(C.CurrentDiscountAmount),sum(C.CurrentChargeamount),sum(C.CurrentNetChargeAmount),
         sum(C.CurrentShippingAndHandlingAmount),sum(C.CurrentNetTaxAmount),
         Max(C.CurrentMinBillingPeriod),Max(C.CurrentMaxBillingPeriod),Max(C.CurrentCountofRecords),Max(C.RenewalActivityMonth),
         Max(C.Currentdate_applied),
         Max(P.PreviousInvoiceID),Max(P.PreviousInvoiceDate),Max(P.PreviousUnits),Max(P.PreviousBeds),Max(P.PreviousPPU),
         sum(P.PreviousExtChargeAmount),sum(P.PreviousEffectiveQuantity),
         sum(P.PreviousDiscountAmount),sum(P.PreviousChargeamount),sum(P.PreviousNetChargeAmount),
         sum(P.PreviousShippingAndHandlingAmount),sum(P.PreviousNetTaxAmount),
         Max(P.PreviousCountofRecords),Max(P.PreviousMinBillingPeriod),Max(P.PreviousMaxBillingPeriod),Max(P.Previousdate_applied)
  from   #LT_CurrentPreBillingReport  C with (nolock)
  FULL OUTER JOIN
         #LT_PreviousPreBillingReport P with (nolock)
  on    C.CompanyID = P.CompanyID
  and   coalesce(C.PropertyID,'')= coalesce(P.PropertyID,'')
  and   coalesce(C.AccountID,'') = coalesce(P.AccountID,'')
  and   C.OrderID   = P.OrderID
  and   C.OrderGroupID = P.OrderGroupID  
  and   coalesce(C.OrderItemID,-1)  = coalesce(P.OrderItemID,-1)
  and   C.CustomBundleFlag = P.CustomBundleFlag
  and   C.RenewalCount = P.RenewalCount
  and   coalesce(C.ProductCode,'')  = coalesce(P.ProductCode,'')
  and   C.Chargetypecode = P.Chargetypecode
  and   C.Measurecode    = P.Measurecode
  and   C.FrequencyCode  = P.Frequencycode
  group by coalesce(C.CompanyID,P.CompanyID),coalesce(C.CompanyName,P.CompanyName),
           coalesce(C.PropertyID,P.PropertyID),coalesce(C.PropertyName,P.PropertyName),
           coalesce(C.AccountID,P.AccountID),
           coalesce(C.ProductCode,P.Productcode),         
           coalesce(C.CustomBundleFlag,P.CustomBundleFlag),
           coalesce(C.ReportingTypeCode,P.ReportingTypeCode),
           coalesce(C.ChargetypeCode,P.chargetypecode),coalesce(C.MeasureCode,P.Measurecode),coalesce(C.FrequencyCode,P.FrequencyCode)
          ,coalesce(C.OrderID,P.OrderID),coalesce(C.OrderGroupID,P.OrderGroupID)
          ,coalesce(C.OrderItemID,P.OrderItemID),P.OrderItemID,P.CustomBundleFlag
  --------------------------------------------------------------------------------
  -- Final Select
  Select CompanyID,CompanyName,PropertyID,PropertyName,AccountID,OrderID,OrderGroupID,OrderItemID,RenewalCount,ProductCode,ProductName,
               BundleName as CustomBundleName,CustomBundleFlag,Family,ReportingTypeCode,ChargetypeCode,MeasureCode,FrequencyCode,
               CurrentInvoiceID,CurrentInvoiceDate,CurrentUnits,CurrentBeds,CurrentPPU,CurrentExtChargeAmount,
               CurrentEffectiveQuantity,CurrentDiscountAmount,CurrentChargeamount,CurrentNetChargeAmount,
               CurrentShippingAndHandlingAmount,CurrentNetTaxAmount,
               CurrentMinBillingPeriod,CurrentMaxBillingPeriod,CurrentCountofRecords,RenewalActivityMonth,Currentdate_applied,
               PreviousInvoiceID,PreviousInvoiceDate,PreviousUnits,PreviousBeds,PreviousPPU,
               PreviousExtChargeAmount,PreviousEffectiveQuantity,PreviousDiscountAmount,PreviousChargeamount,PreviousNetChargeAmount,
               PreviousShippingAndHandlingAmount,PreviousNetTaxAmount,
               PreviousCountofRecords,PreviousMinBillingPeriod,PreviousMaxBillingPeriod,Previousdate_applied
  from #LT_PreBillingReport with (nolock) --where CustomBundleFlag = 1
  order by CompanyName ASC,PropertyName ASC,CompanyID ASC,PropertyID ASC,CustomBundleFlag DESC,ProductName ASC,
           ChargetypeCode ASC,MeasureCode ASC,FrequencyCode ASC 
  --------------------------------------------------------------------------------
  --Final Cleanup
  if (object_id('tempdb.dbo.#LT_PreBillingReport') is not null) 
  begin
    drop table #LT_PreBillingReport
  end
  if (object_id('tempdb.dbo.#LT_CurrentPreBillingReport') is not null) 
  begin
    drop table #LT_CurrentPreBillingReport
  end 
  if (object_id('tempdb.dbo.#LT_PreviousPreBillingReport') is not null) 
  begin
    drop table #LT_PreviousPreBillingReport
  end  
  ---------------------------------------------------------
END
GO
