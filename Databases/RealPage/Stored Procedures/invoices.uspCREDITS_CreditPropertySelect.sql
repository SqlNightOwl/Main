SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure invoices.uspCREDITS_CreditPropertySelect
	@IPVC_CreditMemoID		varchar(22)
,	@IPVC_ReportingTypecode	varchar(4)
as
/*
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspCREDITS_CreditPropertySelect]
-- Description     : This procedure gets Credit Details pertaining to passed CreditMemoID
-- Input Parameters: @IPVC_OrderID           varchar(50)
--                   @IPVC_ReportingTypecode varchar(4)
--                   
-- OUTPUT          : 
-- Code Example    : Exec invoices.[uspCREDITS_CreditPropertySelect] 'R0808000126','ACSF' 
-- 
-- Revision History:
-- Author          : SRS
-- 04/24/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
*/
begin 
  set nocount on ;  
  declare @LVC_CreditType   varchar(6)
  declare @LVC_InvoiceIDSeq varchar(22)

  select @LVC_CreditType = CreditTypeCode, 
        @LVC_InvoiceIDSeq = InvoiceIDSeq 
  from invoices.CreditMemo with (nolock)
  where CreditMemoIDSeq = @IPVC_CreditMemoID

  if exists (select CreditMemoIDSeq 
             from invoices.CreditMemo 
             where CreditStatusCode = 'APPR' 
             and CreditTypeCode in ('TAXC','PARC') 
             and InvoiceIDSeq = @LVC_InvoiceIDSeq)
  begin
        set @LVC_CreditType = 'PARC'
  end
  --------------------------------------------------------------------
  declare @LBI_TotalRecords bigint 
  --Declare Local variable and Temp Tables. 
  create table #Temp_CreditItems 
                                 (
                                  SortSeq                     bigint not null identity(1,1),
                                  CreditMemoIDSeq             varchar(50),
                                  CreditMemoItemIDSeq         bigint,
                                  InvoiceIDSeq                varchar(50),
                                  InvoiceGroupIDSeq           bigint,
                                  InvoiceItemIDSeq            bigint,                                    
                                  ProductCode                 varchar(50),
                                  productdisplayname          varchar(255),
                                  CustomBundleNameEnabledFlag int    not null default (0),
                                  Invoicegroupname            varchar(255),
                                  BillingPeriodFromDate       datetime,
                                  BillingPeriodToDate         datetime,
                                  ChargeTypeCode              varchar(3),
                                  FrequencyCode               varchar(6),
                                  frequencyname               varchar(50),
                                  MeasureCode                 varchar(6),
                                  measurename                 varchar(50),                                 
                                  Quantity                    numeric(30,6),
                                  ExtChargeAmount             numeric(30,6),
                                  DiscountAmount              numeric(30,6),
                                  NetChargeAmount             numeric(30,6), 
                                  CreditAmount                numeric(30,6), 
                                  TaxAmount                   numeric(30,6), 
                                  ShippingAndHandlingAmount   numeric(30,6),
                                  TotalCreditAmount           numeric(30,6), 
                                  remainingamount             numeric(30,6), 
                                  accessexists                int    not null default (0)                               
                                 )on [primary]    

  create table #Temp_FinalCreditItems
                                      (
                                       SortSeq                     bigint not null identity(1,1),
                                       CBSortSeq                   int default 0,
                                       CreditMemoIDSeq             varchar(50),
                                       CreditMemoItemIDSeq         bigint,
                                       InvoiceIDSeq                varchar(50),
                                       InvoiceGroupIDSeq           bigint,
                                       InvoiceItemIDSeq            bigint,
                                       ProductCode                 varchar(50),
                                       productdisplayname          varchar(255),
                                       CustomBundleNameEnabledFlag int    null,
                                       Invoicegroupname            varchar(255),
                                       BillingPeriodFromDate       datetime,
                                       BillingPeriodToDate         datetime,
                                       ChargeTypeCode              varchar(3),
                                       FrequencyCode               varchar(6),
                                       frequencyname               varchar(50),
                                       MeasureCode                 varchar(6),
                                       measurename                 varchar(50),                                 
                                       Quantity                    numeric(30,6),
                                       ExtChargeAmount             numeric(30,6),
                                       DiscountAmount              numeric(30,6),
                                       NetChargeAmount             numeric(30,6), 
                                       CreditAmount                numeric(30,6), 
                                       TaxAmount                   numeric(30,6), 
                                       ShippingAndHandlingAmount   numeric(30,6),
                                       TotalCreditAmount           numeric(30,6), 
                                       remainingamount             numeric(30,6), 
                                       accessexists                int,
                                       internalrecordtype          varchar(5)
                                      ) on [primary]            
  --------------------------------------------------------------------  
  --Step1 : Get Order Items for the specified Order ID, @IPVC_OrderID.
  --------------------------------------------------------------------
  insert into #Temp_CreditItems
                                (
                                 CreditMemoIDSeq,CreditMemoItemIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,
                                 ProductCode,productdisplayname,CustomBundleNameEnabledFlag,Invoicegroupname,
                                 BillingPeriodFromDate,BillingPeriodToDate,ChargeTypeCode,FrequencyCode,frequencyname,MeasureCode,measurename,
                                 Quantity,ExtChargeAmount,DiscountAmount,NetChargeAmount,CreditAmount,TaxAmount,
                                 ShippingAndHandlingAmount,TotalCreditAmount,remainingamount,accessexists
                                )
  select 
         CMI.CreditMemoidseq            as CreditMemoIDSeq,
         CMI.IDSeq                      as CreditMemoItemIDSeq,
         CMI.InvoiceIDSeq               as InvoiceIDSeq,
         CMI.Invoicegroupidseq          as InvoiceGroupIDSeq,
         CMI.InvoiceItemIDSeq           as InvoiceItemIDSeq,
         II.ProductCode                 as ProductCode,
         PRD.displayname                as productdisplayname,
         CMI.custombundlenameenabledflag as CustomBundleNameEnabledFlag,
         IG.Name                        as Invoicegroupname,
         II.BillingPeriodFromDate       as BillingPeriodFromDate,
         II.BillingPeriodToDate         as BillingPeriodToDate,
         II.chargetypecode              as ChargeTypeCode,
         II.frequencycode               as FrequencyCode,
         FR.Name                        as FrequencyName,
         II.Measurecode                 as MeasureCode,
         M.Name                         as MeasureName,
         II.Quantity                    as Quantity,      
         II.extchargeamount             as ExtChargeAmount,
         II.discountamount              as DiscountAmount,
         II.netchargeamount             as NetChargeAmount,
         (CMI.extcreditamount
        - CMI.DiscountCreditAmount)     as CreditAmount,
         CMI.taxamount                  as TaxAmount,
         CMI.ShippingAndHandlingCreditAmount   as ShippingAndHandlingAmount,
        (CMI.extcreditamount
       + CMI.taxamount
       - CMI.DiscountCreditAmount
       + CMI.ShippingAndHandlingCreditAmount)  as TotalCreditAmount,
       case when (@LVC_CreditType = 'FULC')
        then
			(II.netchargeamount
		   + II.taxamount
           + II.ShippingAndHandlingAmount
		   - CMI.netcreditamount             
		   - CMI.taxamount
           - CMI.ShippingAndHandlingCreditAmount)                 
       else
           (II.netchargeamount
		   + II.taxamount
           + II.ShippingAndHandlingAmount
		   - CMI.netcreditamount
           - CMI.ShippingAndHandlingCreditAmount)      
       end                              as remainingamount,
          0                             as accessexists
  from  invoices.CreditMemoItem CMI with (nolock)
  inner join
        invoices.InvoiceItem II with (nolock)
  on      CMI.InvoiceIDSeq      = II.InvoiceIDSeq
  and     CMI.InvoiceGroupIDSeq = II.InvoiceGroupIDSeq
  and     CMI.InvoiceItemIDSeq  = II.IDSeq
  and     II.MeasureCode <> 'TRAN'
  inner join
        invoices.[InvoiceGroup] IG  with (nolock) 
  on      II.InvoiceIDSeq      = IG.InvoiceIDSeq
  and     II.InvoiceGroupIDSeq = IG.IDSeq 
  and     II.OrderIDSeq        = IG.OrderIDSeq
  and     II.OrderGroupIDSeq   = IG.OrderGroupIDSeq
  and     CMI.InvoiceIDSeq     = IG.InvoiceIDSeq
  and     CMI.CreditMemoIDSeq  = @IPVC_CreditMemoID 
  and     II.Reportingtypecode = @IPVC_ReportingTypecode 
  inner join
          products.Product PRD with (nolock)
  on      II.productcode       = PRD.code
  and     II.priceversion      = PRD.Priceversion         
  inner join 
          products.Measure M  with (nolock)
  on      II.MeasureCode       = M.Code           
  inner join 
          products.Frequency FR with (nolock)
  on      II.FrequencyCode     = FR.Code  
  where   CMI.CreditMemoIDSeq  = @IPVC_CreditMemoID 
  and     II.Reportingtypecode = @IPVC_ReportingTypecode 
  Order by PRD.displayname
  -------------------------------------------------------------------- 
  --Step 2.1 : Update to find if ACCESS record exists for an ILF Item
  --           only if @IPVC_ReportingTypecode = 'ILFF'
  if @IPVC_ReportingTypecode = 'ILFF'
  begin
    update D set accessexists  = 1
    from   #Temp_CreditItems D with (nolock)    
    where  D.CreditMemoIDSeq      = @IPVC_CreditMemoID      
    and    exists (select top 1 1 
                   from   invoices.InvoiceItem S with (nolock)
                   join   invoices.CreditMemoItem CMI with (nolock)
                   on     S.InvoiceIDSeq      = CMI.InvoiceIDSeq
                   and    S.IDSeq             = CMI.InvoiceItemIDSeq
                   where  CMI.CreditMemoIDSeq = @IPVC_CreditMemoID
                   and    S.Chargetypecode    = 'ACS'
                   and    S.InvoiceIDSeq      = D.InvoiceIDSeq
                   and    S.Invoicegroupidseq = D.Invoicegroupidseq
                   and    S.Productcode       = D.productcode
                  )
  end
  --------------------------------------------------------------------  
  --Step2 : Insert Into #Temp_FinalCreditItems 
  --       -- Alacarte Products and Rolledup for Custom Bundles.
  --------------------------------------------------------------------          
  insert into #Temp_FinalCreditItems
                                     (
                                      CreditMemoIDSeq,CreditMemoItemIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,
                                      ProductCode,productdisplayname,CustomBundleNameEnabledFlag,Invoicegroupname,BillingPeriodFromDate,BillingPeriodToDate,
                                      ChargeTypeCode,FrequencyCode,frequencyname,MeasureCode,measurename,
                                      Quantity,ExtChargeAmount,DiscountAmount,NetChargeAmount,CreditAmount,TaxAmount,
                                      ShippingAndHandlingAmount,TotalCreditAmount,remainingamount,
                                      accessexists,internalrecordtype
                                     )
  select src.CreditMemoidseq,src.CreditMemoItemidseq,src.Invoiceidseq,src.Invoicegroupidseq,src.Invoiceitemidseq,
         src.productcode,src.productdisplayname,
         src.custombundlenameenabledflag,src.Invoicegroupname,src.BillingPeriodFromDate,src.BillingPeriodToDate,src.chargetypecode,
         src.frequencycode,src.frequencyname,src.measurecode,src.measurename,
         src.quantity,src.extchargeamount,src.discountamount,src.netchargeamount,src.creditamount,src.taxamount,
         src.shippingandhandlingamount,src.TotalCreditAmount,src.remainingamount,
         src.accessexists,src.internalrecordtype
  from 
  (select CB.CreditMemoidseq,null CreditMemoItemIDSeq,CB.Invoiceidseq,CB.Invoicegroupidseq,null InvoiceItemIDSeq,
          null as ProductCode,max(CB.Invoicegroupname) as productdisplayname,
          max(CB.custombundlenameenabledflag) as CustomBundleNameEnabledFlag,max(CB.Invoicegroupname) as Invoicegroupname,
          CB.BillingPeriodFromDate as BillingPeriodFromDate,CB.BillingPeriodToDate as BillingPeriodToDate,
          max(CB.chargetypecode) as ChargeTypeCode,
          max(CB.frequencycode) as FrequencyCode,max(CB.frequencyname) as frequencyname,
          max(CB.measurecode) as MeasureCode,max(CB.measurename) as measurename,
          1 as  Quantity,sum(CB.extchargeamount) as ExtChargeAmount,sum(CB.discountamount) as DiscountAmount,
          sum(CB.netchargeamount) as NetChargeAmount,sum(CB.creditamount) as CreditAmount,sum(CB.taxamount) as TaxAmount,
          sum(CB.shippingandhandlingamount) as ShippingAndHandlingAmount,sum(CB.TotalCreditAmount) as TotalCreditAmount,
          sum(CB.remainingamount) as remainingamount,max(accessexists) as accessexists,
         'CB' as internalrecordtype
   from  #Temp_CreditItems CB with (nolock)
   where CB.custombundlenameenabledflag = 1
   group by CB.CreditMemoidseq,CB.Invoiceidseq,CB.Invoicegroupidseq,CB.BillingPeriodFromDate,CB.BillingPeriodToDate
   -----------------------------------------
   union
   -----------------------------------------
   select A.CreditMemoidseq,A.CreditMemoItemidseq,A.Invoiceidseq,A.Invoicegroupidseq,A.Invoiceitemidseq,
          A.productcode,A.productdisplayname,
          A.custombundlenameenabledflag,A.Invoicegroupname,A.BillingPeriodFromDate,A.BillingPeriodToDate,A.chargetypecode,
          A.frequencycode,A.frequencyname,A.measurecode,A.measurename,
          A.quantity,A.extchargeamount,A.discountamount,A.netchargeamount,A.creditamount,A.taxamount,
          A.shippingandhandlingamount,A.TotalCreditAmount,A.remainingamount,
          A.accessexists,
          'PR' as internalrecordtype
   from  #Temp_CreditItems A with (nolock)
   where A.custombundlenameenabledflag = 0
  ) src
  Order by (rank() over (Order by CustomBundleNameEnabledFlag desc,productdisplayname asc))
  --------------------------------------------------------------------------------------
  --Step 3 : Insert Only product Records with No pricing for Products for CustomBundles
  --------------------------------------------------------------------------------------
  set identity_insert #Temp_FinalCreditItems on;

  insert into #Temp_FinalCreditItems
                                     (
                                      SortSeq,CBSortSeq,CreditMemoIDSeq,CreditMemoItemIDSeq,InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceItemIDSeq,
                                      ProductCode,productdisplayname,CustomBundleNameEnabledFlag,Invoicegroupname,BillingPeriodFromDate,BillingPeriodToDate,
                                      ChargeTypeCode,FrequencyCode,frequencyname,MeasureCode,measurename,
                                      Quantity,ExtChargeAmount,DiscountAmount,NetChargeAmount,CreditAmount,TaxAmount,
                                      ShippingAndHandlingAmount,TotalCreditAmount,remainingamount,
                                      accessexists,internalrecordtype
                                     )
  select src.sortseq,1,src.CreditMemoidseq,src.CreditMemoItemidseq,src.Invoiceidseq,src.Invoicegroupidseq,src.Invoiceitemidseq,
         src.productcode,T.productdisplayname,
         null as CustomBundleNameEnabledFlag,null as Invoicegroupname,T.BillingPeriodFromDate,T.BillingPeriodToDate,null as ChargeTypeCode,
         null as FrequencyCode,null as frequencyname,null as MeasureCode,null as measurename,
         null as Quantity,null as ExtChargeAmount,null as DiscountAmount,null as NetChargeAmount,null as CreditAmount,null as TaxAmount,
         null as ShippingAndHandlingAmount,null as TotalCreditAmount,null as remainingamount,
         null as accessexists,'PC' internalrecordtype
  from #Temp_FinalCreditItems src with (nolock)
  inner join
       #Temp_CreditItems      T with (nolock)
  on   src.CreditMemoidseq             = T.CreditMemoidseq
  and  src.Invoiceidseq                = T.Invoiceidseq
  and  src.InvoiceGroupIDSeq           = T.InvoiceGroupIDSeq
  and  src.BillingPeriodFromDate       = T.BillingPeriodFromDate
  and  src.BillingPeriodToDate         = T.BillingPeriodToDate
  and  src.custombundlenameenabledflag = T.custombundlenameenabledflag
  and  src.custombundlenameenabledflag = 1
  and  T.custombundlenameenabledflag      = 1
  and  src.internalrecordtype          = 'CB'
  Order by src.sortseq asc
  set identity_insert #Temp_FinalCreditItems off
  --------------------------------------------------------------------------------------     
  --Step 5 : Final Select to UI based on Range passed.
  --------------------------------------------------------------------------------------
   select --row_number() OVER (ORDER BY SortSeq) as seq ,
         CreditMemoIDSeq                                              as CreditMemoIDSeq,
         CreditMemoItemIDSeq                                          as CreditMemoItemIDSeq,
         InvoiceIDSeq                                                 as InvoiceIDSeq,
         InvoiceGroupIDSeq                                            as GroupIDSeq,
         InvoiceItemIDSeq                                             as InvoiceItemIDSeq,
         ProductCode                                                  as ProductCode,
         productdisplayname                                           as ProductName,
         Invoicegroupname                                             as Invoicegroupname,
         convert(varchar(12),BillingPeriodFromDate,101)               as BillingPeriodFromDate,
         convert(varchar(12),BillingPeriodToDate,101)                 as BillingPeriodToDate,
         ChargeTypeCode                                               as ChargeTypeCode,
         frequencyname                                                as FrequencyCode,
         frequencyname                                                as Frequency,
         MeasureCode                                                  as MeasureCode,
         upper(MeasureCode)                                           as PricedBy,
         Quantity                                                     as Quantity,
         oms.fn_FormatCurrency (ExtChargeAmount,2,2)           as ListPrice,
         oms.fn_FormatCurrency (DiscountAmount,2,2)            as Discount,
         oms.fn_FormatCurrency (NetChargeAmount,2,2)           as NetPrice,
         oms.fn_FormatCurrency (CreditAmount,2,2)              as CreditAmount,
         oms.fn_FormatCurrency (TaxAmount,2,2)                 as TaxAmount,
         oms.fn_FormatCurrency (ShippingAndHandlingAmount,2,2) as ShippingCharge,
         oms.fn_FormatCurrency (TotalCreditAmount,2,2)         as TotalCreditAmount,
         oms.fn_FormatCurrency (remainingamount,2,2)           as RemainingAmount,
         accessexists                                                 as ACSExists,
         internalrecordtype                                           as BundleName,
         CustomBundleNameEnabledFlag                                  as PreConfiguredBundleFlag 
   from  #Temp_FinalCreditItems S with (nolock)
   Order by  SortSeq,CBSortSeq,productdisplayname
  --------------------------------------------------------------------------------------     
  -- Query for calculating the total amount of the Credit Memo Items
  --------------------------------------------------------------------------------------
  select  sum(convert(numeric(30,2),CIS.Quantity))                                 as NetQuantity,
          isnull('$'+ oms.fn_FormatCurrency(sum(CIS.extchargeamount),2,2),'0')    as NetListPrice,
          isnull('$'+ oms.fn_FormatCurrency(sum(CIS.discountamount),2,2),'0')     as NetDiscount,
          isnull('$'+ oms.fn_FormatCurrency(sum(CIS.netchargeamount),2,2),'0')     as NetNetPrice,  
          isnull('$'+ oms.fn_FormatCurrency(sum(CIS.CreditAmount),2,2),'0') as NetCreditAmount,
          isnull('$'+ oms.fn_FormatCurrency(sum(CIS.TaxAmount),2,2),'0')    as NetTaxAmount,
		  isnull('$'+ oms.fn_FormatCurrency(convert(varchar(20),convert(numeric(30,2),
          sum(CIS.shippingandhandlingamount) + sum(CIS.CreditAmount) + (sum(CIS.TaxAmount)))),2,2),'0')                 as NetTotalCreditAmount,
		  isnull('$'+	oms.fn_FormatCurrency(convert(varchar(20),convert(numeric(30,2),sum(CIS.RemainingAmount))),2,2),'0')    as NetRemainingAmount,
          isnull('$' + oms.fn_FormatCurrency(convert(varchar(20),convert(numeric(30,2),sum(CIS.shippingandhandlingamount))),2,2),'0')        as TotalShipping  
  from  #Temp_FinalCreditItems CIS with (nolock)
  where internalrecordtype != 'PC'
  --------------------------------------------------------------------------------------
  ---Final Cleanup
  drop table #Temp_FinalCreditItems
  drop table #Temp_CreditItems
  --------------------------------------------------------------------------------------
end
GO
