SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : [uspInvoices_Rep_CustomBundleInvoiceDetail]  
-- Description     : This procedure gets Custom Bundle Invoice Details   
-- Input Parameters: @IPVC_CustomerID				varchar(22),
--                   @IPVC_CustomerName	   		    varchar(100),
--                   @IPVC_AccountID			    varchar(22),
--					 @IPVC_AccountName		    	varchar(100),
--					 @IPVC_InvoiceID			    varchar(22),
--                   @IPVC_OrderID			    	varchar(22),
--					 @IPDT_BillingFrom		    	varchar(22),
--					 @IPDT_BillingTo		        varchar(22),
--					 @IPDT_InvoiceDateFrom        	varchar(22),
--					 @IPDT_InvoiceDateTo	        varchar(22),
--					 @IPVC_Product                  varchar(100)
--                     
-- OUTPUT          :   
-- Code Example    : Exec INVOICES.DBO.[uspInvoices_Rep_CustomBundleInvoiceDetail] '','sares','','','','','','','','',''  
-- 
-- Revision History:  
-- Author          : Anand Chakravarthy  
-- 03/18/2009      : Stored Procedure Created.  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [reports].[uspInvoices_Rep_CustomBundleInvoiceDetail] (  
                                                        @IPVC_CustomerID				varchar(22) ,
                                                        @IPVC_CustomerName	   		    varchar(100),
                                                        @IPVC_AccountID			    	varchar(22) ,
														@IPVC_AccountName		    	varchar(100),
														@IPVC_InvoiceID			    	varchar(22) ,
                                                        @IPVC_OrderID			    	varchar(22) ,
														@IPDT_BillingFrom		    	varchar(22) ,
														@IPDT_BillingTo		        	varchar(22)	,
														@IPDT_InvoiceDateFrom        	varchar(22) ,
														@IPDT_InvoiceDateTo	        	varchar(22) ,
														@IPVC_Product                   varchar(100)
													    )  
AS  
BEGIN   
  set nocount on ; 
   --------------------------------------------------------------------------  
  set @IPVC_CustomerID		  = nullif(@IPVC_CustomerID,'')  
  set @IPVC_CustomerName	  = nullif(@IPVC_CustomerName,'')  
  set @IPVC_AccountID		  = nullif(@IPVC_AccountID,'')  
  set @IPVC_AccountName		  = nullif(@IPVC_AccountName,'')  
  set @IPVC_InvoiceID         = nullif(@IPVC_InvoiceID , '')  
  set @IPVC_OrderID           = nullif(@IPVC_OrderID,'')  
  set @IPDT_BillingFrom       = nullif(@IPDT_BillingFrom,'')  
  set @IPDT_BillingTo         = nullif(@IPDT_BillingTo,'')  
  set @IPDT_InvoiceDateFrom   = nullif(@IPDT_InvoiceDateFrom , '')  
  set @IPDT_InvoiceDateTo     = nullif(@IPDT_InvoiceDateTo,'')  
  set @IPVC_Product           = nullif(@IPVC_Product,'')  
--------------------------------------------------------------------------     
  --------------------------------------------------------------------  
  Declare @LBI_TotalRecords bigint   
  --Declare Local variable and Temp Tables.   
  create Table #Temp_InvoiceItems   
                                 (  
                                  sortseq                     bigint not null identity(1,1),  
                                  CompanyIdSeq                varchar(22),  
                                  CompanyName				  varchar(100),  
                                  AccountIDSeq                varchar(22),  
                                  AccountName                 varchar(100),  
                                  InvoiceIDSeq                varchar(22),  
                                  OrderIDSeq                  varchar(22),    
                                  productcode                 varchar(50),  
                                  productdisplayname          varchar(255),  
                                  custombundlenameenabledflag int    not null default (0),  
                                  Invoicegroupname            varchar(255),
                                  InvoiceDescription          varchar(255),  
                                  BillingPeriodFromDate       datetime,  
                                  BillingPeriodToDate         datetime,  
                                  chargetypecode              varchar(3),  
                                  frequencyname               varchar(50),  
                                  measurename                 varchar(50),                                   
                                  netchargeamount             numeric(30,6),  
                                  Total                       numeric(30,6),   
                                  accessexists                int    not null default (0)                                 
                                 )ON [PRIMARY]      
  
  create Table #Temp_FinalInvoiceItems
								 ( 
                                  sortseq                     bigint not null identity(1,1),
                                  CBSortSeq                   int default 0,    
                                  CompanyIdSeq                varchar(22),  
                                  CompanyName				  varchar(100),  
                                  AccountIDSeq                varchar(22),  
                                  AccountName                 varchar(100),  
                                  InvoiceIDSeq                varchar(22),  
                                  OrderIDSeq                  varchar(22),    
                                  productcode                 varchar(50),  
                                  productdisplayname          varchar(255),  
                                  custombundlenameenabledflag int    not null default (0),  
                                  Invoicegroupname            varchar(255),
								  InvoiceDescription          varchar(255), 	  
                                  BillingPeriodFromDate       datetime,  
                                  BillingPeriodToDate         datetime,  
                                  chargetypecode              varchar(3),  
                                  frequencyname               varchar(50),  
                                  measurename                 varchar(50),                                   
                                  netchargeamount             numeric(30,6),  
                                  Total                       numeric(30,6),   
                                  accessexists                int    not null default (0),
                                  internalrecordtype          varchar(5)                                 
                                 )ON [PRIMARY]      
  --------------------------------------------------------------------    
  --Step1 : Get Order Items for the specified Order ID, @IPVC_OrderID.  
  --------------------------------------------------------------------  
  Insert into #Temp_InvoiceItems  
                                (  
                                 CompanyIDSeq,CompanyName,  
                                 AccountIDSeq,AccountName,InvoiceIDSeq,OrderIDSeq,productcode,  
                                 productdisplayname,custombundlenameenabledflag,Invoicegroupname,InvoiceDescription,BillingPeriodFromDate,  
                                 BillingPeriodToDate,chargetypecode,frequencyname,measurename,  
                                 netchargeamount,Total,accessexists  
                                )  
  select   
         I.CompanyIDSeq                 as CompanyIDSeq,  
         I.CompanyName					as CompanyName,  
         I.AccountIDSeq					as AccountID,  
         I.PropertyName                 as AccountName,  
         I.InvoiceIDSeq					as InvoiceIDSeq,
         II.OrderIDSeq					as OrderIDSeq,
         II.ProductCode                 as ProductCode,  
         PRD.displayname                as productdisplayname,  
         IG.custombundlenameenabledflag as custombundlenameenabledflag,  
         IG.Name                        as Invoicegroupname,
         QG.Description                 as InvoiceDescription,  
         II.BillingPeriodFromDate       as BillingPeriodFromDate,  
         II.BillingPeriodToDate         as BillingPeriodToDate,  
         II.chargetypecode              as chargetypecode,  
         FR.Name                        as FrequencyName,  
         M.Name                         as MeasureName,  
         II.netchargeamount             as netchargeamount,  
         ((convert(numeric(30,6),isnull(II.NetChargeAmount,0))) +  
        (convert(numeric(30,6),isnull(II.ShippingAndHandlingAmount,0))) +   
                 (isnull(II.TaxAmount,0))    
                      ) as Total,  
         0                                       as accessexists  
  from  
  Invoices.dbo.Invoice I with (nolock)  
  inner Join 
  Invoices.dbo.InvoiceItem II with (nolock)
  on      II.InvoiceIDSeq      = I.InvoiceIDSeq 
  inner Join  
        Invoices.dbo.[InvoiceGroup] IG  with (nolock)   
  on      II.InvoiceIDSeq      = IG.InvoiceIDSeq  
  and     II.InvoiceGroupIDSeq = IG.IDSeq   
  and     II.OrderIDSeq        = IG.OrderIDSeq  
  and     II.OrderGroupIDSeq   = IG.OrderGroupIDSeq
  and     IG.custombundlenameenabledflag = 1   
  and     II.MeasureCode <> 'TRAN'
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
  inner join
         Orders.dbo.[Order] O with (nolock)
  on     O.OrderIDSeq  = II.OrderIDSeq
  inner join 
          Quotes.dbo.[Group] QG with (nolock)
  on      O.QuoteIDSeq    = QG.QuoteIDSeq
  and     O.CompanyIDSeq  = QG.CustomerIDSeq
  and     QG.CustomBundleNameEnabledFlag= 1
  WHERE I.CompanyIDSeq  = coalesce(@IPVC_CustomerID,I.CompanyIDSeq)  
  and     QG.CustomBundleNameEnabledFlag= 1
  AND   I.AccountIDSeq  = coalesce(@IPVC_AccountID,I.AccountIDSeq)  
  AND ((I.CompanyName  LIKE '%' + coalesce(@IPVC_CustomerName,I.CompanyName) + '%'))
  AND ((I.PropertyName  LIKE '%' + coalesce(@IPVC_AccountName,I.PropertyName) + '%'))  
  AND    I.InvoiceIDSeq  = coalesce(@IPVC_InvoiceID,I.InvoiceIDSeq)  
  AND   II.OrderIDSeq  = coalesce(@IPVC_OrderID,II.OrderIDSeq)  
  AND   II.BillingPeriodFromDate   = coalesce(@IPDT_BillingFrom,II.BillingPeriodFromDate)  
  AND   II.BillingPeriodToDate    =  coalesce(@IPDT_BillingTo,II.BillingPeriodToDate)  
  AND  convert(varchar(12),I.InvoiceDate,101) >= coalesce(@IPDT_InvoiceDateFrom,I.InvoiceDate)  
  AND  convert(varchar(12),I.InvoiceDate,101) <= coalesce(@IPDT_InvoiceDateTo,I.InvoiceDate) 
  AND ((PRD.DisplayName  LIKE '%' + coalesce(@IPVC_Product,PRD.DisplayName) + '%'))
  --------------------------------------------------------------------    
  --Step2 : Insert Into #Temp_FinalInvoiceItems   
  --       -- Alacarte Products and Rolledup for Custom Bundles.  
  --------------------------------------------------------------------         
  Insert into #Temp_FinalInvoiceItems  
                                     (  
                                 CompanyIDSeq,CompanyName,  
                                 AccountIDSeq,AccountName,InvoiceIDSeq,OrderIDSeq,productcode,  
                                 productdisplayname,custombundlenameenabledflag,Invoicegroupname,InvoiceDescription,BillingPeriodFromDate,  
                                 BillingPeriodToDate,chargetypecode,frequencyname,measurename,  
                                 netchargeamount,Total,accessexists,internalrecordtype  
                                     )  
  select Source.CompanyIDSeq,Source.CompanyName,Source.AccountIDSeq,  
         Source.AccountName,Source.InvoiceIDSeq,Source.OrderIDSeq,Source.productcode,Source.productdisplayname,  
         Source.custombundlenameenabledflag,Source.Invoicegroupname,Source.InvoiceDescription,Source.BillingPeriodFromDate,Source.BillingPeriodToDate,Source.chargetypecode,  
         Source.frequencyname,Source.measurename,  
         Source.netchargeamount,Source.Total,  
         Source.accessexists,Source.internalrecordtype  
  from   
  (select CB.CompanyIDSeq,CB.CompanyName,CB.AccountIDSeq,CB.AccountName, 
          MAX(CB.InvoiceIDSeq) as InvoiceIDSeq,MAX(CB.OrderIDSeq) as OrderIDSeq,  
          NULL as productcode,Max(CB.Invoicegroupname) as productdisplayname,  
          MAX(CB.custombundlenameenabledflag) as custombundlenameenabledflag,max(CB.Invoicegroupname) as Invoicegroupname,max(CB.InvoiceDescription) as InvoiceDescription,  
          CB.BillingPeriodFromDate as BillingPeriodFromDate,CB.BillingPeriodToDate as BillingPeriodToDate,  
          Max(CB.chargetypecode) as chargetypecode,  
          MAX(CB.frequencyname) as frequencyname,  
          MAX(CB.measurename) as measurename,  
          NULL as netchargeamount,  
          sum(CB.Total) as Total,  
          Max(accessexists) as accessexists,  
         'CB' as internalrecordtype  
   from  #Temp_InvoiceItems CB With (nolock)  
   where CB.custombundlenameenabledflag = 1
   AND   CB.ChargeTypeCode = 'ACS'  
   group by CB.Invoiceidseq,CB.BillingPeriodFromDate,CB.BillingPeriodToDate,CB.CompanyName,CB.CompanyIDSeq,CB.AccountIDSeq,CB.AccountName 
--   -----------------------------------------  
--   UNION  
--   -----------------------------------------  
--   select A.CompanyIDSeq,A.CompanyName,A.AccountIDSeq,  
--          A.AccountName,A.InvoiceIDSeq,A.OrderIDSeq,A.productcode,A.productdisplayname,  
--          A.custombundlenameenabledflag,A.Invoicegroupname,A.InvoiceDescription,A.BillingPeriodFromDate,A.BillingPeriodToDate,A.chargetypecode,  
--          A.frequencyname,A.measurename,  
--          A.netchargeamount,A.Total,  
--          A.accessexists,  
--          'PR' as internalrecordtype  
--   from  #Temp_InvoiceItems A With (nolock)  
--   where A.custombundlenameenabledflag = 0
--   AND A.chargetypecode = 'ACS' 
  ) Source  
  order by (RANK() OVER (ORDER BY custombundlenameenabledflag DESC,productdisplayname ASC))  
  -------------------------------------------------------------------------------------- 
   --------------------------------------------------------------------    
  --Step3 : Insert Into #Temp_FinalInvoiceItems For ILF Products  
  --------------------------------------------------------------------         
  Insert into #Temp_FinalInvoiceItems  
                                     (  
                                 CompanyIDSeq,CompanyName,  
                                 AccountIDSeq,AccountName,InvoiceIDSeq,OrderIDSeq,productcode,  
                                 productdisplayname,custombundlenameenabledflag,Invoicegroupname,InvoiceDescription,BillingPeriodFromDate,  
                                 BillingPeriodToDate,chargetypecode,frequencyname,measurename,  
                                 netchargeamount,Total,accessexists,internalrecordtype  
                                     )  
  select Source.CompanyIDSeq,Source.CompanyName,Source.AccountIDSeq,  
         Source.AccountName,Source.InvoiceIDSeq,Source.OrderIDSeq,Source.productcode,Source.productdisplayname,  
         Source.custombundlenameenabledflag,Source.Invoicegroupname,Source.InvoiceDescription,Source.BillingPeriodFromDate,Source.BillingPeriodToDate,Source.chargetypecode,  
         Source.frequencyname,Source.measurename,  
         Source.netchargeamount,Source.Total,  
         Source.accessexists,Source.internalrecordtype  
  from   
  (select CB.CompanyIDSeq,CB.CompanyName,CB.AccountIDSeq,CB.AccountName, 
          MAX(CB.InvoiceIDSeq) as InvoiceIDSeq,MAX(CB.OrderIDSeq) as OrderIDSeq,  
          NULL as productcode,Max(CB.Invoicegroupname) as productdisplayname,  
          MAX(CB.custombundlenameenabledflag) as custombundlenameenabledflag,max(CB.Invoicegroupname) as Invoicegroupname,max(CB.InvoiceDescription) as InvoiceDescription,  
          CB.BillingPeriodFromDate as BillingPeriodFromDate,CB.BillingPeriodToDate as BillingPeriodToDate,  
          Max(CB.chargetypecode) as chargetypecode,  
          MAX(CB.frequencyname) as frequencyname,  
          MAX(CB.measurename) as measurename,  
          NULL as netchargeamount,  
          sum(CB.Total) as Total,  
          Max(accessexists) as accessexists,  
         'CB' as internalrecordtype  
   from  #Temp_InvoiceItems CB With (nolock)  
   where CB.custombundlenameenabledflag = 1
   AND   CB.ChargeTypeCode = 'ILF'  
   group by CB.Invoiceidseq,CB.BillingPeriodFromDate,CB.BillingPeriodToDate,CB.CompanyName,CB.CompanyIDSeq,CB.AccountIDSeq,CB.AccountName 
--   -----------------------------------------  
--   UNION  
--   -----------------------------------------  
--   select A.CompanyIDSeq,A.CompanyName,A.AccountIDSeq,  
--          A.AccountName,A.InvoiceIDSeq,A.OrderIDSeq,A.productcode,A.productdisplayname,  
--          A.custombundlenameenabledflag,A.Invoicegroupname,A.InvoiceDescription,A.BillingPeriodFromDate,A.BillingPeriodToDate,A.chargetypecode,  
--          A.frequencyname,A.measurename,  
--          A.netchargeamount,A.Total,  
--          A.accessexists,  
--          'PR' as internalrecordtype  
--   from  #Temp_InvoiceItems A With (nolock)  
--   where A.custombundlenameenabledflag = 0
--   AND A.chargetypecode = 'ILF' 
  ) Source  
  order by (RANK() OVER (ORDER BY custombundlenameenabledflag DESC,productdisplayname ASC))  
  --------------------------------------------------------------------------------------  
 
  --Step 4 : Insert Only product Records with No pricing for Products for CustomBundles  
  --------------------------------------------------------------------------------------  
  set identity_insert #Temp_FinalInvoiceItems on;  
  
  Insert into #Temp_FinalInvoiceItems  
                                     (  
                                      sortseq,CBSortSeq,CompanyIDSeq,CompanyName,AccountIDSeq,  
                                      AccountName,InvoiceIDSeq,OrderIDSeq,productcode,productdisplayname,  
                                      custombundlenameenabledflag,Invoicegroupname,InvoiceDescription,BillingPeriodFromDate,BillingPeriodToDate,chargetypecode,  
                                      frequencyname,measurename,  
                                      netchargeamount,Total,  
                                      accessexists,internalrecordtype  
                                     )  
  select Source.sortseq,1,NULL as CompanyIDSeq,NULL as CompanyName,NULL as AccountIDSeq,  
         NULL as AccountName, NULL as InvoiceIDSeq,NULL as OrderIDSeq,Source.productcode,'           '+T.productdisplayname,  
         T.custombundlenameenabledflag as custombundlenameenabledflag,NULL as Invoicegroupname, NULL as InvoiceDescription,NULL as BillingPeriodFromDate,NULL as BillingPeriodToDate,NULL as chargetypecode,  
         NULL as frequencyname,NULL as measurename,  
         T.netchargeamount as netchargeamount,NULL as Total,  
         T.accessexists as accessexists,'PC' as internalrecordtype  
  from #Temp_FinalInvoiceItems Source with (nolock)  
  inner join  
       #Temp_InvoiceItems      T with (nolock)  
  on   Source.CompanyIDSeq                = T.CompanyIDSeq  
  and  Source.CompanyName                 = T.CompanyName  
  and  Source.AccountIDSeq                = T.AccountIDSeq  
  and  Source.AccountName                 = T.AccountName  
  and  Source.BillingPeriodFromDate       = T.BillingPeriodFromDate  
  and  Source.BillingPeriodToDate         = T.BillingPeriodToDate  
  and  Source.custombundlenameenabledflag = T.custombundlenameenabledflag 
  and  Source.chargetypecode              = T.chargetypecode   
  and  Source.custombundlenameenabledflag = 1  
  and  T.custombundlenameenabledflag      = 1  
  and  Source.internalrecordtype          = 'CB'
  order by Source.sortseq asc  
  set identity_insert #Temp_FinalInvoiceItems off  
  --------------------------------------------------------------------------------------       
  --Step 5 : Get Total records in a variable for final select  
  --------------------------------------------------------------------------------------  
  select @LBI_TotalRecords = Count(sortseq) from #Temp_FinalInvoiceItems with (nolock)  
  --------------------------------------------------------------------------------------       
  --Step 6 : Final Select to UI based on Range passed.  
  --------------------------------------------------------------------------------------  
  select   CompanyIDSeq                                as CompanyIDSeq,  
    CompanyName										   as CompanyName,  
    AccountIDSeq                                       as AccountIDSeq,  
    orderidseq                                         as OrderIDSeq,  
    AccountName                                        as AccountName,  
    InvoiceIDSeq                                       as InvoiceIDSeq,
    productcode                                        as ProductCode,  
    productdisplayname                                 as ProductName,  
    Invoicegroupname                                   as Invoicegroupname,
    InvoiceDescription                                 as InvoiceDescription,  
    BillingPeriodFromDate							   as BillingPeriodFromDate,  
    BillingPeriodToDate								   as BillingPeriodToDate,  
    chargetypecode									   as Charge,  
    frequencyname									   as Frequency,  
    measurename									       as Measure,  
    Quotes.DBO.fn_FormatCurrency (netchargeamount,2,2) as NetChargeAmount,  
    Quotes.DBO.fn_FormatCurrency (Total,2,2)           as Total,            
    accessexists									   as ACSExists,  
    internalrecordtype								   as BundleProductFlag,  
    custombundlenameenabledflag                        as PreconfiguredBundleFlag  
   from      #Temp_FinalInvoiceItems S WITH (NOLOCK)
   WHERE   custombundlenameenabledflag = 1
   order by  SortSeq,CBSortSeq,productdisplayname  
  --------------------------------------------------------------------------------------       
  --Step 5 : Final Select for Total Record count  
  select @LBI_TotalRecords --as RecordCount  
  --------------------------------------------------------------------------------------  
  ---Final Cleanup  
  drop table #Temp_FinalInvoiceItems  
  drop table #Temp_InvoiceItems  
  --------------------------------------------------------------------------------------  
END  
GO
