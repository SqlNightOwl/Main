SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_InvoicePropertySelect]
-- Description     : This procedure gets Invoice Details pertaining to passed InvoiceID
-- Input Parameters: @IPVC_OrderID           varchar(50)
--                   @IPVC_ReportingTypecode varchar(4)
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.DBO.[uspINVOICES_InvoicePropertySelect] 'I0808009645','ANCF'
-- 
-- Revision History:
-- Author          : SRS
-- 04/24/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_InvoicePropertySelect] (
                                                             @IPVC_InvoiceID         VARCHAR(22),
                                                             @IPVC_ReportingTypecode VARCHAR(4)
                                                           )
AS
BEGIN 
  set nocount on ;  
  --------------------------------------------------------------------
  Declare @LBI_TotalRecords bigint 
  --Declare Local variable and Temp Tables. 
  create Table #Temp_InvoiceItems 
                                 (
                                  sortseq                     bigint not null identity(1,1),
                                  Invoiceidseq                varchar(50),
                                  Invoicegroupidseq           bigint,
                                  Invoiceitemidseq            bigint,
                                  orderidseq                  varchar(50),
                                  ordergroupidseq             bigint,
                                  orderitemidseq              bigint,  
                                  productcode                 varchar(50),
                                  productdisplayname          varchar(255),
                                  custombundlenameenabledflag int    not null default (0),
                                  Invoicegroupname            varchar(255),
                                  BillingPeriodFromDate       datetime,
                                  BillingPeriodToDate         datetime,
                                  chargetypecode              varchar(3),
                                  frequencycode               varchar(6),
                                  frequencyname               varchar(50),
                                  measurecode                 varchar(6),
                                  measurename                 varchar(50),                                 
                                  quantity                    numeric(30,2),
                                  extchargeamount             numeric(30,6),
                                  discountamount              numeric(30,6),
                                  netchargeamount             numeric(30,6),
                                  TaxAmount                   numeric(30,6),
                                  CreditAmount                numeric(30,6),
                                  Total                       numeric(30,6), 
                                  shippingandhandlingamount   numeric(30,6),
                                  accessexists                int    not null default (0)                               
                                 )ON [PRIMARY]    

  create Table #Temp_FinalInvoiceItems
                                      (
                                       SortSeq                     bigint not null identity(1,1),
                                       CBSortSeq                   int default 0,
                                       Invoiceidseq                varchar(50),
                                       Invoicegroupidseq           bigint,
                                       Invoiceitemidseq            bigint,
                                       orderidseq                  varchar(50),
                                       ordergroupidseq             bigint,
                                       orderitemidseq              bigint,  
                                       productcode                 varchar(50),
                                       productdisplayname          varchar(255),
                                       custombundlenameenabledflag int    null,
                                       Invoicegroupname            varchar(255),
                                       BillingPeriodFromDate       datetime,
                                       BillingPeriodToDate         datetime,
                                       chargetypecode              varchar(3),
                                       frequencycode               varchar(6),
                                       frequencyname               varchar(50),
                                       measurecode                 varchar(6),
                                       measurename                 varchar(50),                                 
                                       quantity                    numeric(30,2),
                                       extchargeamount             numeric(30,6),
                                       discountamount              numeric(30,6),
                                       netchargeamount             numeric(30,6),
                                       TaxAmount                   numeric(30,6),
                                       CreditAmount                numeric(30,6),
                                       Total                       numeric(30,6),  
                                       shippingandhandlingamount   numeric(30,6),
                                       accessexists                int,
                                       internalrecordtype          varchar(5)
                                      ) ON [PRIMARY]            
  --------------------------------------------------------------------  
  --Step1 : Get Order Items for the specified Order ID, @IPVC_OrderID.
  --------------------------------------------------------------------
  Insert into #Temp_InvoiceItems
                                (
                                 Invoiceidseq,Invoicegroupidseq,Invoiceitemidseq,
                                 orderidseq,ordergroupidseq,orderitemidseq,productcode,productdisplayname,
                                 custombundlenameenabledflag,Invoicegroupname,BillingPeriodFromDate,BillingPeriodToDate,
                                 chargetypecode,frequencycode,frequencyname,measurecode,measurename,
                                 quantity,extchargeamount,discountamount,netchargeamount,TaxAmount,CreditAmount,Total,
                                 shippingandhandlingamount,accessexists
                                )
  select 
         II.InvoiceIDSeq                as InvoiceIDSeq,
         II.Invoicegroupidseq           as Invoicegroupidseq,
         II.IDSeq                       as InvoiceItemIDSeq,
         II.OrderIDSeq                  as OrderIDSeq,
         II.OrderGroupIDSeq             as OrderGroupIDSeq,
         II.OrderItemIDSeq              as OrderItemIDSeq,
         II.ProductCode                 as ProductCode,
         PRD.displayname                as productdisplayname,
         IG.custombundlenameenabledflag as custombundlenameenabledflag,
         IG.Name                        as Invoicegroupname,
         II.BillingPeriodFromDate       as BillingPeriodFromDate,
         II.BillingPeriodToDate         as BillingPeriodToDate,
         II.chargetypecode              as chargetypecode,
         II.frequencycode               as frequencycode,
         FR.Name                        as FrequencyName,
         II.Measurecode                 as Measurecode,
         M.Name                         as MeasureName,
         II.Quantity                    as quantity,      
         II.extchargeamount             as extchargeamount,
         II.discountamount              as discountamount,
         II.netchargeamount             as netchargeamount,
         II.TaxAmount                   as TaxAmount,
         isnull(Credits.Amount,0)       as CreditAmount,
          ((convert(numeric(30,6),isnull(II.NetChargeAmount,0))) +
		      (convert(numeric(30,6),isnull(II.ShippingAndHandlingAmount,0))) + 
                 (isnull(II.TaxAmount,0)) - 
                      (isnull(Credits.Amount,0))) as Total,
         II.ShippingAndHandlingAmount             as shippingandhandlingamount,        
          0                                       as accessexists
  from  Invoices.dbo.InvoiceItem II with (nolock)
  inner Join
        Invoices.dbo.[InvoiceGroup] IG  with (nolock) 
  on      II.InvoiceIDSeq      = IG.InvoiceIDSeq
  and     II.InvoiceGroupIDSeq = IG.IDSeq 
  and     II.OrderIDSeq        = IG.OrderIDSeq
  and     II.OrderGroupIDSeq   = IG.OrderGroupIDSeq  
  and     II.InvoiceIDSeq      = @IPVC_InvoiceID 
  and     II.Reportingtypecode = @IPVC_ReportingTypecode   
  and     II.MeasureCode <> 'TRAN'          
  and     IG.InvoiceIDSeq      = @IPVC_InvoiceID    
  inner join
          Products.dbo.Product PRD with (nolock)
  on      II.productcode       = PRD.code
  and     II.priceversion      = PRD.Priceversion         
  inner join 
          Products.dbo.Measure M  with (nolock)
  on      II.MeasureCode       = M.Code           
  inner join 
          Products.dbo.Frequency FR with (nolock)
  on      II.FrequencyCode     = FR.Code 
  left outer join 
          (select isnull((sum(convert(numeric(30,6),cmi.ExtCreditAmount))+
                  sum(convert(numeric(30,6),cmi.TaxAmount))+ sum(convert(numeric(30,6),cmi.ShippingAndHandlingCreditAmount))
                  -sum(convert(numeric(30,6),cmi.discountcreditamount))),0)  AS Amount,                                        
                  InvoiceItemIDSeq
           from   CreditMemoItem cmi with (nolock), CreditMemo cm with (nolock)
           where  cm.InvoiceIDSeq     = @IPVC_InvoiceID
              and cmi.CreditMemoIDSeq = cm.CreditMemoIDSeq 
              and CreditStatusCode    = 'APPR'
		   Group by InvoiceItemIDSeq
           ) AS Credits
  on            Credits.InvoiceItemIDSeq = II.IDSeq 
  where   II.InvoiceIDSeq      = @IPVC_InvoiceID 
  and     II.Reportingtypecode = @IPVC_ReportingTypecode
  and     II.MeasureCode <> 'TRAN'   
  and     IG.InvoiceIDSeq      = @IPVC_InvoiceID
  order by PRD.displayname   
  -------------------------------------------------------------------- 
  --Step 2.1 : Update to find if ACCESS record exists for an ILF Item
  --           only if @IPVC_ReportingTypecode = 'ILFF'
  -------------------------------------------------------------------- 
  if @IPVC_ReportingTypecode = 'ILFF'
  begin
    Update D set accessexists  = 1
    from   #Temp_InvoiceItems D with (nolock)    
    where  D.InvoiceIDSeq      = @IPVC_InvoiceID      
    and    exists (select top 1 1 
                   from   Invoices.dbo.InvoiceItem S with (nolock)
                   where  S.InvoiceIDSeq      = @IPVC_InvoiceID
                   and    S.Chargetypecode    = 'ACS'
                   and    S.InvoiceIDSeq      = D.InvoiceIDSeq
                   and    S.Invoicegroupidseq = D.Invoicegroupidseq
                   and    S.OrderIDSeq        = D.OrderIDSeq
                   and    S.Ordergroupidseq   = D.Ordergroupidseq
                   and    S.Productcode       = D.productcode
                  )
  end
  --------------------------------------------------------------------  
  --Step2 : Insert Into #Temp_FinalInvoiceItems 
  --       -- Alacarte Products and Rolledup for Custom Bundles.
  --------------------------------------------------------------------       
  Insert into #Temp_FinalInvoiceItems
                                     (
                                      Invoiceidseq,Invoicegroupidseq,Invoiceitemidseq,
                                      orderidseq,ordergroupidseq,orderitemidseq,productcode,productdisplayname,
                                      custombundlenameenabledflag,Invoicegroupname,BillingPeriodFromDate,BillingPeriodToDate,chargetypecode,
                                      frequencycode,frequencyname,measurecode,measurename,
                                      quantity,extchargeamount,discountamount,netchargeamount,TaxAmount,CreditAmount,Total,
                                      shippingandhandlingamount,
                                      accessexists,internalrecordtype
                                     )
  select Source.Invoiceidseq,Source.Invoicegroupidseq,Source.Invoiceitemidseq,
         Source.orderidseq,Source.ordergroupidseq,Source.orderitemidseq,Source.productcode,Source.productdisplayname,
         Source.custombundlenameenabledflag,Source.Invoicegroupname,Source.BillingPeriodFromDate,Source.BillingPeriodToDate,Source.chargetypecode,
         Source.frequencycode,Source.frequencyname,Source.measurecode,Source.measurename,
         Source.quantity,Source.extchargeamount,Source.discountamount,Source.netchargeamount,Source.TaxAmount,Source.CreditAmount,Source.Total,
         Source.shippingandhandlingamount,
         Source.accessexists,Source.internalrecordtype
  from 
  (select CB.Invoiceidseq,CB.Invoicegroupidseq,NULL Invoiceitemidseq,
          MAX(CB.orderidseq) as orderidseq,MAX(CB.ordergroupidseq) as ordergroupidseq,
          NULL orderitemidseq,NULL as productcode,Max(CB.Invoicegroupname) as productdisplayname,
          MAX(CB.custombundlenameenabledflag) as custombundlenameenabledflag,max(CB.Invoicegroupname) as Invoicegroupname,
          CB.BillingPeriodFromDate as BillingPeriodFromDate,CB.BillingPeriodToDate as BillingPeriodToDate,
          Max(CB.chargetypecode) as chargetypecode,
          Max(CB.frequencycode) as frequencycode,MAX(CB.frequencyname) as frequencyname,
          MAX(CB.measurecode) as measurecode,MAX(CB.measurename) as measurename,
          NULL as  quantity,sum(CB.extchargeamount) as extchargeamount,sum(CB.discountamount) as discountamount,
          sum(CB.netchargeamount) as netchargeamount,
          sum(CB.TaxAmount) as TaxAmount,sum(CB.CreditAmount) as CreditAmount,sum(CB.Total) as Total,
          sum(CB.shippingandhandlingamount) as shippingandhandlingamount,
          Max(accessexists) as accessexists,
         'CB' as internalrecordtype
   from  #Temp_InvoiceItems CB With (nolock)
   where CB.custombundlenameenabledflag = 1
   group by CB.Invoiceidseq,CB.Invoicegroupidseq,CB.BillingPeriodFromDate,CB.BillingPeriodToDate
   -----------------------------------------
   UNION
   -----------------------------------------
   select A.Invoiceidseq,A.Invoicegroupidseq,A.Invoiceitemidseq,
          A.orderidseq,A.ordergroupidseq,A.orderitemidseq,A.productcode,A.productdisplayname,
          A.custombundlenameenabledflag,A.Invoicegroupname,A.BillingPeriodFromDate,A.BillingPeriodToDate,A.chargetypecode,
          A.frequencycode,A.frequencyname,A.measurecode,A.measurename,
          A.quantity,A.extchargeamount,A.discountamount,A.netchargeamount,A.TaxAmount,A.CreditAmount,A.Total,
          A.shippingandhandlingamount,
          A.accessexists,
          'PR' as internalrecordtype
   from  #Temp_InvoiceItems A With (nolock)
   where A.custombundlenameenabledflag = 0
  ) Source
  order by (RANK() OVER (ORDER BY custombundlenameenabledflag DESC,productdisplayname ASC))
  --------------------------------------------------------------------------------------
  --Step 3 : Insert Only product Records with No pricing for Products for CustomBundles
  --------------------------------------------------------------------------------------
  set identity_insert #Temp_FinalInvoiceItems on;

  Insert into #Temp_FinalInvoiceItems
                                     (
                                      sortseq,CBSortSeq,Invoiceidseq,Invoicegroupidseq,Invoiceitemidseq,
                                      orderidseq,ordergroupidseq,orderitemidseq,productcode,productdisplayname,
                                      custombundlenameenabledflag,Invoicegroupname,BillingPeriodFromDate,BillingPeriodToDate,chargetypecode,
                                      frequencycode,frequencyname,measurecode,measurename,
                                      quantity,extchargeamount,discountamount,netchargeamount,TaxAmount,CreditAmount,Total,
                                      shippingandhandlingamount,
                                      accessexists,internalrecordtype
                                     )
  select Source.sortseq,1,Source.Invoiceidseq,Source.Invoicegroupidseq,Source.Invoiceitemidseq,
         Source.orderidseq,Source.ordergroupidseq,T.orderitemidseq,Source.productcode,T.productdisplayname,
         NULL as custombundlenameenabledflag,NULL as Invoicegroupname,T.BillingPeriodFromDate,T.BillingPeriodToDate,NULL as chargetypecode,
         NULL as frequencycode,NULL as frequencyname,NULL as measurecode,NULL as measurename,
         NULL as quantity,NULL as extchargeamount,NULL as discountamount,NULL as netchargeamount,NULL as TaxAmount,NULL as CreditAmount,NULL as Total,
         NULL as shippingandhandlingamount,
         NULL as accessexists,'PC' internalrecordtype
  from #Temp_FinalInvoiceItems Source with (nolock)
  inner join
       #Temp_InvoiceItems      T with (nolock)
  on   Source.Invoiceidseq                = T.Invoiceidseq
  and  Source.InvoiceGroupIDSeq           = T.InvoiceGroupIDSeq
  and  Source.Orderidseq                  = T.Orderidseq
  and  Source.OrderGroupIDSeq             = T.OrderGroupIDSeq
  and  Source.BillingPeriodFromDate       = T.BillingPeriodFromDate
  and  Source.BillingPeriodToDate         = T.BillingPeriodToDate
  and  Source.custombundlenameenabledflag = T.custombundlenameenabledflag
  and  Source.custombundlenameenabledflag = 1
  and  T.custombundlenameenabledflag      = 1
  and  Source.internalrecordtype          = 'CB'
  order by Source.sortseq asc
  set identity_insert #Temp_FinalInvoiceItems off
  --------------------------------------------------------------------------------------     
  --Step 4 : Get Total records in a variable for final select
  --------------------------------------------------------------------------------------
  select @LBI_TotalRecords = Count(sortseq) from #Temp_FinalInvoiceItems with (nolock)
  --------------------------------------------------------------------------------------     
  --Step 5 : Final Select to UI based on Range passed.
  --------------------------------------------------------------------------------------
  select 	 Invoiceidseq                       									as Invoiceidseq,
			 Invoicegroupidseq                  									as Invoicegroupidseq,
			 Invoiceitemidseq                   									as Invoiceitemidseq,
			 orderidseq                         									as OrderIDSeq,
			 ordergroupidseq                    									as OrderGroupIDSeq,
			 orderitemidseq                     									as ItemIDSeq,
			 productcode                        									as ProductCode,
			 productdisplayname                 									as ProductName,
			 Invoicegroupname														as Invoicegroupname,
			 Convert(varchar(12),BillingPeriodFromDate,101)							as StartDate,
			 Convert(varchar(12),BillingPeriodToDate,101)							as EndDate,
			 chargetypecode															as ChargeTypeCode,
			 frequencycode															as FrequencyCode,
			 frequencyname															as Frequency,
			 measurename															as MeasureCode,
			 measurename															as PricedBy,
			 quantity																as Quantity,
			 Quotes.DBO.fn_FormatCurrency (extchargeamount,2,2)                     as ListPrice,
			 Quotes.DBO.fn_FormatCurrency (discountamount,2,2)                      as Discount,
			 Quotes.DBO.fn_FormatCurrency (netchargeamount,2,2)                     as NetPrice,
             Quotes.DBO.fn_FormatCurrency (TaxAmount,2,2)                           as TaxAmount,
             Quotes.DBO.fn_FormatCurrency (CreditAmount,2,2)                        as CreditAmount,
             Quotes.DBO.fn_FormatCurrency (Total,2,2)                               as Total,          
			 Quotes.DBO.fn_FormatCurrency (shippingandhandlingamount,2,2)           as ShippingCharge,
			 accessexists															as ACSExists,
			 internalrecordtype														as BundleProductFlag,
			 custombundlenameenabledflag											as PreconfiguredBundleFlag
   from      #Temp_FinalInvoiceItems S WITH (NOLOCK)
   order by  SortSeq,CBSortSeq,productdisplayname
  --------------------------------------------------------------------------------------     
  -- Query for calculating the total amount of the Credit Memo Items
  --------------------------------------------------------------------------------------
   select isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(TaxAmount),2,2),'0')     as NetTaxAmount,
          isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(CreditAmount),2,2),'0')  as NetCreditAmount,
          isnull('$'+ Quotes.DBO.fn_FormatCurrency(sum(Total),2,2),'0')         as NetTotal
   from   #Temp_FinalInvoiceItems with (nolock) 
   where  internalrecordtype <> 'PC'
  --------------------------------------------------------------------------------------     
  --Step 6 : Final Select for Total Record count
  select @LBI_TotalRecords --as RecordCount
  --------------------------------------------------------------------------------------
  ---Final Cleanup
  drop table #Temp_FinalInvoiceItems
  drop table #Temp_InvoiceItems
  --------------------------------------------------------------------------------------
END

GO
