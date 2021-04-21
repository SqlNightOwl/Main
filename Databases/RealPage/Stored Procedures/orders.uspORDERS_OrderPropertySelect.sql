SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : [uspORDERS_OrderPropertySelect]
-- Description     : This procedure gets Order Details pertaining to passed OrderID
-- Input Parameters: @IPVC_OrderID           varchar(50)
--                   @IPVC_ReportingTypecode varchar(4)
--                   
-- OUTPUT          : 
-- Code Example    : Exec ORDERS.DBO.uspORDERS_OrderPropertySelect 'O0804071616','ILFF',1,21
-- 
-- Revision History:
-- Author          : SRS
-- 04/24/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_OrderPropertySelect] (
                                                         @IPVC_OrderID           varchar(50),
                                                         @IPVC_ReportingTypecode varchar(4),
                                                         @IPI_PageNumber         int, 
                                                         @IPI_RowsPerPage        int
                                                       )
AS
BEGIN 
  set nocount on ;    
  --------------------------------------------------------------------  
  Declare @LBI_TotalRecords int   
  --Declare Local variable and Temp Tables.  
  create Table #Temp_OrderItems (  
                                 sortseq                     bigint not null identity(1,1),  
                                 orderidseq                  varchar(50),  
                                 ordergroupidseq             bigint,  
                                 orderitemidseq              bigint,
                                 ordergrouptype              varchar(50),    
                                 productcode                 varchar(50),  
                                 productdisplayname          varchar(255),  
                                 custombundlenameenabledflag int    not null default (0),  
                                 ordergroupname              varchar(255),  
                                 renewalcount                bigint not null default (0),  
                                 ----------------------------------------  
                                 status                      varchar(50),  
                                 chargetypecode              varchar(3),  
                                 frequencycode               varchar(6),  
                                 frequencyname               varchar(50),  
                                 measurecode                 varchar(6),  
                                 measurename                 varchar(50),                                   
                                 quantity                    numeric(30,2),  
                                 extchargeamount             numeric(30,2),  
                                 discountamount              numeric(30,2),  
                                 netchargeamount             numeric(30,2),   
                                 shippingandhandlingamount   numeric(30,2),  
                                 startdate                   datetime,  
                                 enddate                     datetime,
                                 canceldate                  datetime,  
                                 accessexists                int    not null default (0),  
                                 generateaccess              int,
                                 priceversion                numeric(18,2),
                                 migratedflag                bit                               
                                )ON [PRIMARY]      
  
  create Table #Temp_FinalOrderItems  
                                (  
                                 SortSeq                     bigint not null identity(1,1),  
                                 orderidseq                  varchar(50),  
                                 ordergroupidseq             bigint,  
                                 orderitemidseq              bigint,    
                                 productcode                 varchar(50),  
                                 productdisplayname          varchar(255),  
                                 custombundlenameenabledflag int    null,  
                                 ordergroupname              varchar(255),  
                                 renewalcount                bigint not null default (0),  
                                 ----------------------------------------  
                                 status                      varchar(50),  
                                 chargetypecode              varchar(3),  
                                 frequencycode               varchar(6),  
                                 frequencyname               varchar(50),  
                                 measurecode                 varchar(6),  
                                 measurename                 varchar(50),                                   
                                 quantity                    numeric(30,2),  
                                 extchargeamount             numeric(30,2),  
                                 discountamount              numeric(30,2),  
                                 netchargeamount             numeric(30,2),   
                                 shippingandhandlingamount   numeric(30,2),  
                                 startdate                   datetime,  
                                 enddate                     datetime,
                                 canceldate                  datetime,  
                                 accessexists                int,  
                                 generateaccess              int,  
                                 ----------------------------------------   
                                 internalrecordtype          varchar(5)  
                                ) ON [PRIMARY]              
  --------------------------------------------------------------------    
  --Step1 : Get Order Items for the specified Order ID, @IPVC_OrderID.  
  --------------------------------------------------------------------  
  Insert into #Temp_OrderItems(  
                               orderidseq,ordergroupidseq,orderitemidseq,ordergrouptype,productcode,productdisplayname,  
                               custombundlenameenabledflag,ordergroupname,renewalcount,status,  
                               chargetypecode,frequencycode,frequencyname,measurecode,measurename,  
                               quantity,extchargeamount,discountamount,netchargeamount,shippingandhandlingamount,  
                               startdate,enddate,canceldate,accessexists,generateaccess,priceversion,migratedflag 
                              )  
  select OI.OrderIDSeq                  as OrderIDSeq,  
         OI.OrderGroupIDSeq             as OrderGroupIDSeq,  
         OI.IDSeq                       as OrderItemIDSeq,
         OG.ordergrouptype              as ordergrouptype,
         OI.ProductCode                 as ProductCode,  
         PRD.displayname                as productdisplayname,  
         OG.custombundlenameenabledflag as custombundlenameenabledflag,  
         OG.Name                        as ordergroupname,  
         OI.renewalCount                as renewalcount,  
         OST.Name                       as status,  
         OI.chargetypecode              as chargetypecode,  
         OI.frequencycode               as frequencycode,  
         FR.Name                        as FrequencyName,  
         OI.Measurecode                 as Measurecode,  
         M.Name                         as MeasureName,  
         OI.Quantity                    as quantity,        
         OI.extchargeamount             as extchargeamount,  
         OI.discountamount              as discountamount,  
         OI.netchargeamount             as netchargeamount,  
         OI.ShippingAndHandlingAmount   as shippingandhandlingamount,  
         (Case when OI.Chargetypecode = 'ILF' then convert(varchar(50),coalesce(OI.ILFStartDate,OI.Startdate,OI.ActivationStartDate),101)  
               else convert(varchar(50),coalesce(OI.ActivationStartDate,OI.Startdate),101)  
          end)                          as Startdate,  
         (Case when OI.Chargetypecode = 'ILF' then convert(varchar(50),coalesce(OI.ILFEndDate,OI.Enddate,OI.ActivationEndDate),101)  
               else convert(varchar(50),coalesce(OI.ActivationEndDate,OI.Enddate),101)  
          end)                          as Enddate,  
          convert(varchar(50),OI.canceldate,101) as canceldate, 
          0                             as accessexists,
          0                             as generateaccess,
         OI.priceversion                as priceversion,
         OI.MigratedFlag                as MigratedFlag    
  from  ORDERS.dbo.OrderItem OI with (nolock)  
  inner Join  
        ORDERS.dbo.[OrderGroup] OG  with (nolock)   
  on      OI.OrderIDSeq        = OG.OrderIDSeq  
  and     OI.OrderGroupIDSeq   = OG.IDSeq    
  and     OI.OrderIDSeq        = @IPVC_OrderID   
  and     OI.Reportingtypecode = @IPVC_ReportingTypecode     
  and     OG.OrderIDSeq        = @IPVC_OrderID    
  inner join  
          ORDERS.dbo.OrderStatustype OST with (nolock)  
  on      OI.Statuscode      = OST.Code  
  inner join  
          Products.dbo.Product PRD with (nolock)  
  on      OI.productcode = PRD.code  
  and     OI.priceversion= PRD.Priceversion     
  inner join   
          PRODUCTS.dbo.Measure M  with (nolock)  
  on      OI.MeasureCode   = M.Code
  --     and     OI.MeasureCode  <> 'TRAN'             
  inner join   
          PRODUCTS.dbo.Frequency FR with (nolock)  
  on      OI.FrequencyCode     = FR.Code    
  where   OI.OrderIDSeq        = @IPVC_OrderID   
  and     OI.Reportingtypecode = @IPVC_ReportingTypecode     
  and     OG.OrderIDSeq        = @IPVC_OrderID    
  --------------------------------------------------------------------   
  --Step 2.1 : Update to find if ACCESS record exists for an ILF Item  
  --           only if @IPVC_ReportingTypecode = 'ILFF'  
  if @IPVC_ReportingTypecode = 'ILFF'  
  begin
    Update D set D.accessexists = 1  
    from   #Temp_OrderItems D with (nolock)      
    where  D.accessexists      = 0
    and    D.OrderIDSeq        = @IPVC_OrderID       
    and    exists (select top 1 1   
                   from   ORDERS.dbo.OrderItem S with (nolock)  
                   where  S.OrderIDSeq        = @IPVC_OrderID  
                   and    S.Chargetypecode    = 'ACS'  
                   and    S.OrderIDSeq        = D.OrderIDSeq  
                   and    S.Ordergroupidseq   = D.Ordergroupidseq  
                   and    S.Productcode       = D.productcode  
                  )  


    Update D set D.generateaccess = 1
    from   #Temp_OrderItems D with (nolock) 
    where  D.accessexists      = 0
    and    D.MigratedFlag      = 1
    and    D.OrderIDSeq        = @IPVC_OrderID 
    and    exists (select top 1 1
                   from   Products.dbo.Charge Ch with (nolock)  
                   where  Ch.Chargetypecode    = 'ACS'  
		   and    Ch.Productcode       = D.productcode
		   and    Ch.DisplayType <> 'OTHER'
                   and   (Ch.DisplayType = D.ordergrouptype
                              OR
                          Ch.DisplayType = 'BOTH'
                          )
                  ) 
  end  
  --------------------------------------------------------------------    
  --Step2 : Insert Into #Temp_FinalOrderItems   
  --       -- Alacarte Products and Rolledup for Custom Bundles.  
  --------------------------------------------------------------------            
  Insert into #Temp_FinalOrderItems(  
                                    orderidseq,ordergroupidseq,orderitemidseq,productcode,productdisplayname,  
                                    custombundlenameenabledflag,ordergroupname,renewalcount,chargetypecode,status,  
                                    frequencycode,frequencyname,measurecode,measurename,  
                                    quantity,extchargeamount,discountamount,netchargeamount,shippingandhandlingamount,  
                                    startdate,enddate,canceldate,accessexists,generateaccess,internalrecordtype  
                                   )  
  select Source.orderidseq,Source.ordergroupidseq,Source.orderitemidseq,Source.productcode,Source.productdisplayname,  
         Source.custombundlenameenabledflag,ordergroupname,renewalcount,chargetypecode,status,  
         Source.frequencycode,Source.frequencyname,Source.measurecode,Source.measurename,  
         Source.quantity,Source.extchargeamount,Source.discountamount,Source.netchargeamount,Source.shippingandhandlingamount,  
         Source.startdate,Source.enddate,Source.canceldate,Source.accessexists,Source.generateaccess,Source.internalrecordtype  
  from   
  (select CB.orderidseq as orderidseq,CB.ordergroupidseq as ordergroupidseq,  
          NULL orderitemidseq,NULL as productcode,Max(CB.ordergroupname) as productdisplayname,  
          MAX(CB.custombundlenameenabledflag) as custombundlenameenabledflag,max(CB.ordergroupname) as ordergroupname,  
          CB.renewalcount as renewalcount,Max(CB.chargetypecode) as chargetypecode,Max(CB.status) as status,  
          Max(CB.frequencycode) as frequencycode,MAX(CB.frequencyname) as frequencyname,  
          MAX(CB.measurecode) as measurecode,MAX(CB.measurename) as measurename,  
          1 as  quantity,sum(CB.extchargeamount) as extchargeamount,sum(CB.discountamount) as discountamount,  
          sum(CB.netchargeamount) as netchargeamount,sum(CB.shippingandhandlingamount) as shippingandhandlingamount,  
          Max(CB.startdate) as startdate,Max(CB.enddate) as enddate,Max(CB.canceldate) as canceldate,
          Max(accessexists) as accessexists,Max(generateaccess) as generateaccess,  
         'CB' as internalrecordtype  
   from  #Temp_OrderItems CB With (nolock)  
   where CB.custombundlenameenabledflag = 1  
   group by CB.orderidseq,CB.ordergroupidseq,CB.renewalCount  
   -----------------------------------------  
   UNION  
   -----------------------------------------  
   select A.orderidseq,A.ordergroupidseq,A.orderitemidseq,A.productcode,A.productdisplayname,  
          A.custombundlenameenabledflag,A.ordergroupname,A.renewalcount,A.chargetypecode,A.status,  
          A.frequencycode,A.frequencyname,A.measurecode,A.measurename,  
          A.quantity,A.extchargeamount,A.discountamount,A.netchargeamount,A.shippingandhandlingamount,  
          A.startdate,A.enddate,A.canceldate,A.accessexists,A.generateaccess,  
          'PR' as internalrecordtype  
   from  #Temp_OrderItems A With (nolock)  
   where A.custombundlenameenabledflag = 0  
  ) Source  
  order by (RANK() OVER (ORDER BY renewalCount DESC,custombundlenameenabledflag DESC,productdisplayname ASC))  
  --------------------------------------------------------------------------------------  
  --Step 3 : Insert Only product Records with No pricing for Products for CustomBundles  
  --------------------------------------------------------------------------------------  
  set identity_insert #Temp_FinalOrderItems on;  
  
  Insert into #Temp_FinalOrderItems(  
                                    sortseq,orderidseq,ordergroupidseq,orderitemidseq,productcode,productdisplayname,  
                                    custombundlenameenabledflag,ordergroupname,renewalcount,chargetypecode,status,  
                                    frequencycode,frequencyname,measurecode,measurename,  
                                    quantity,extchargeamount,discountamount,netchargeamount,shippingandhandlingamount,  
                                    startdate,enddate,canceldate,accessexists,generateaccess,internalrecordtype  
                                   )  
  select Source.sortseq,Source.orderidseq,Source.ordergroupidseq,T.orderitemidseq,Source.productcode,T.productdisplayname,  
         NULL as custombundlenameenabledflag,NULL as ordergroupname,Source.renewalcount,NULL as chargetypecode,NULL as status,  
         NULL as frequencycode,NULL as frequencyname,NULL as measurecode,NULL as measurename,  
         NULL as quantity,NULL as extchargeamount,NULL as discountamount,NULL as netchargeamount,NULL as shippingandhandlingamount,  
         NULL as startdate,NULL as enddate,NULL as canceldate,Source.accessexists as accessexists,NULL as generateaccess,'PC' internalrecordtype  
  from #Temp_FinalOrderItems Source with (nolock)  
  inner join  
       #Temp_OrderItems      T with (nolock)  
  on   Source.Orderidseq                  = T.Orderidseq  
  and  Source.OrderGroupIDSeq             = T.OrderGroupIDSeq  
  and  Source.renewalCount                = T.renewalcount  
  and  Source.custombundlenameenabledflag = T.custombundlenameenabledflag  
  and  Source.Renewalcount                = T.Renewalcount  
  and  Source.custombundlenameenabledflag = 1  
  and  T.custombundlenameenabledflag      = 1  
  and  Source.internalrecordtype          = 'CB'  
  order by Source.sortseq asc  
  
  set identity_insert #Temp_FinalOrderItems off;  
  --------------------------------------------------------------------------------------       
  --Step 4 : Get Total records in a variable for final select  
  --------------------------------------------------------------------------------------  
  select @LBI_TotalRecords = Count(sortseq) from #Temp_FinalOrderItems with (nolock)  
  --------------------------------------------------------------------------------------       
  --Step 5 : Final Select to UI based on Range passed.  
  --------------------------------------------------------------------------------------  
  select tbl.ItemIDSeq,tbl.OrderIDSeq,tbl.OrderGroupIDSeq,tbl.ProductCode,tbl.renewalcount,
         tbl.Name,tbl.ChargeTypeCode,  
         tbl.FrequencyCode,tbl.Frequency,tbl.MeasureCode,UPPER(tbl.PricedBy) as PricedBy,tbl.Quantity,  
         tbl.ListPrice,tbl.Discount,tbl.NetPrice,tbl.status,tbl.StartDate,tbl.EndDate,tbl.canceldate,
         tbl.ShippingCharge,  
         tbl.ACSExists,tbl.BundleProductFlag,tbl.PreconfiguredBundleFlag,tbl.generateaccess  
  from  
    (  Select   
         row_number() OVER (ORDER BY SortSeq) as seq ,   
         orderitemidseq                     as ItemIDSeq,           
         orderidseq                         as OrderIDSeq,  
         ordergroupidseq                    as OrderGroupIDSeq,  
         productcode                        as ProductCode,
         renewalcount                       as renewalcount,  
         productdisplayname                 as Name,  
         chargetypecode                     as ChargeTypeCode,  
         frequencyname                      as FrequencyCode,  
         frequencyname                      as Frequency,  
         measurecode                        as MeasureCode,  
         measurecode                        as PricedBy,  
         quantity                           as Quantity,  
         Orders.DBO.fn_FormatCurrency (extchargeamount,2,2)           as ListPrice,  
         Orders.DBO.fn_FormatCurrency (discountamount,2,2)            as Discount,  
         Orders.DBO.fn_FormatCurrency (netchargeamount,2,2)           as NetPrice,  
         [status]                                                     as [status],  
         Convert(varchar(12),StartDate,101)                           as StartDate,  
         Convert(varchar(12),EndDate,101)                             as EndDate, 
         convert(varchar(12),canceldate,101)                          as canceldate,  
         Quotes.DBO.fn_FormatCurrency (shippingandhandlingamount,2,2) as ShippingCharge,  
         accessexists                       as ACSExists,  
         internalrecordtype                 as BundleProductFlag,  
         custombundlenameenabledflag        as PreconfiguredBundleFlag,         
         generateaccess                      as generateaccess  
       from  #Temp_FinalOrderItems S WITH (NOLOCK)  
       group by ordergroupidseq,orderitemidseq,orderidseq,productcode,productdisplayname,  
                chargetypecode,frequencyname,frequencyname,measurecode,measurecode,quantity,  
       Orders.DBO.fn_FormatCurrency (extchargeamount,2,2),  
       Orders.DBO.fn_FormatCurrency (discountamount,2,2),  
       Orders.DBO.fn_FormatCurrency (netchargeamount,2,2),  
       [status],Convert(varchar(12),StartDate,101),Convert(varchar(12),EndDate,101),
                convert(varchar(12),canceldate,101),  
                Quotes.DBO.fn_FormatCurrency (shippingandhandlingamount,2,2),  
       accessexists,internalrecordtype,custombundlenameenabledflag,renewalcount,sortseq,generateaccess  
    ) tbl  
  where  Seq >  (@IPI_PageNumber-1) * @IPI_RowsPerPage  
   and   Seq <= (@IPI_PageNumber)   * @IPI_RowsPerPage  
  order by Seq asc  
  --------------------------------------------------------------------------------------       
  --Step 6 : Final Select for Total Record count  
  select @LBI_TotalRecords as RecordCount  
  --------------------------------------------------------------------------------------  
  ---Final Cleanup  
  Drop table #Temp_FinalOrderItems  
  Drop table #Temp_OrderItems  
  --------------------------------------------------------------------------------------  
END
GO
