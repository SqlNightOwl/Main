SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-------------------------------------------------------------------------------------------------------------------------      
-- Database  Name  : QUOTES      
-- Procedure Name  : uspQUOTES_Rep_GetProformaInvoiceDetail      
-- Description     : This procedure gets details records for Proforma Invoice from Quote
-- Input Parameters: 
--            
-- Code Example    : 
/*
 Exec QUOTES.dbo.uspQUOTES_Rep_GetProformaInvoiceDetail      
          @IPVC_QuoteID='Q0905000433',@IPBI_GroupID=5376,@IPVC_CompanyID='C0901003377',@IPVC_OMSID='P0901015846'
*/
--       
--       
-- Revision History:      
-- Author          : SRS      
-- 08/26/2010      : Stored Procedure Created. Defect 8015
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [reports].[uspQUOTES_Rep_GetProformaInvoiceDetail] (@IPVC_QuoteID        varchar(50), --->QuoteID   from result of call Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice
                                                                 @IPBI_GroupID        bigint,      --->GroupID   from result of call Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice
                                                                 @IPVC_CompanyID      varchar(50), --->CompanyID from result of call Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice
                                                                 @IPVC_OMSID          varchar(50)  --->OMSID     from result of call Exec QUOTES.dbo.uspQUOTES_GetGroupsForProformaInvoice
                                                                )
AS
BEGIN
  set nocount on;
  --------------------------------------------------------------------------------------------
  declare @LI_Min              int,
          @LI_Max              int
  declare @LI_RPDSeq           int, 
          @LBI_quoteitemid          bigint,     
          @LVC_productcode          varchar(50),
          @LI_custombundlenameenabledflag int,
          @LVC_chargetypecode       varchar(50),
          @LVC_reportingtypecode    varchar(50),
          @LVC_measurecode          varchar(50),
          @LVC_frequencycode        varchar(50),
          @LVC_PricingLineItemNotes varchar(8000)

  select @LI_Min=1,@LI_Max=0
  --------------------------------------------------------------------------------------------
  create table #LT_RawPricingData    (SEQ                      int not null identity(1,1) primary Key,                                 
                                      quoteid                  varchar(50),
                                      groupid                  bigint, 
                                      quoteitemid              bigint,
                                      companyid                varchar(50),
                                      omsid                    varchar(50),
                                      productcode              varchar(100),
                                      productname              varchar(255), 
                                      custombundlename         varchar(255),
                                      custombundlenameenabledflag int,                                                                      
                                      productcategorycode      varchar(50),
                                      familycode               varchar(20)   not null,
                                      chargetypecode           varchar(50),
                                      reportingtypecode        varchar(50),
                                      FeeType                  as            (case when (chargetypecode = 'ACS' and measurecode = 'TRAN')
                                                                                      then 'TRX'                                                                                   
                                                                                   else  substring(reportingtypecode,1,3)
                                                                              end), 
                                      sortorder                as            (case when chargetypecode='ILF' 
                                                                                     then 1
                                                                                   when (substring(reportingtypecode,1,3) = 'ACS' and measurecode <> 'TRAN')
                                                                                     then 2
                                                                                   when (chargetypecode = 'ACS' and measurecode = 'TRAN')
                                                                                     then 4
                                                                                   else 3
                                                                              end),
                                      measurecode              varchar(20)   not null,
                                      measurename              varchar(100),
                                      DisplayTransactionalProductPriceOnInvoiceFlag int not null default(1),                                
                                      frequencycode            varchar(20)   not null,
                                      frequencyname            varchar(100),
                                      chargeamount             money         not null default 0,
                                      discountpercent          float         not null default 0.00,
                                      discountamount           numeric(30,2) not null default 0,
                                      totaldiscountpercent     float         not null default 0.00,
                                      totaldiscountamount      numeric(30,2) not null default 0,
                                      extchargeamount          numeric(30,2) not null default 0,
                                      extSOCchargeamount       numeric(30,2) not null default 0,
                                      unitofmeasure            numeric(30,5) not null default 0.00,                    
                                      multiplier               decimal(18,6) not null default 0.00,
                                      extyear1chargeamount     numeric(30,2) not null default 0,                                
                                      netchargeamount          numeric(30,3) not null default 0,
                                      netextchargeamount       numeric(30,2) not null default 0, 
                                      ItemAmt                  as            convert(numeric(30,4),(
                                                                                                   convert(float,netextchargeamount) 
                                                                                                      /
                                                                                                   convert(float,(case when (familycode = 'LSD' and measurecode = 'UNIT')
                                                                                                                         then (case when Multiplier=0 then 1 else Multiplier end)
                                                                                                                       else (case when unitofmeasure=0 then 1 else unitofmeasure end)
                                                                                                                  end)
                                                                                                           )
                                                                                                    )
                                                                                     ),                                                                                  
                                      netextyear1chargeamount  numeric(30,2) not null default 0,
                                      pricingtiers             int           not null default 1,
                                      PricingLineItemNotes     varchar(8000) null
                                      )

  create table #LT_PricingNotes         (SEQ                      int not null identity(1,1) primary Key,
                                         RPDSeq                   int not null,
                                         quoteid                  varchar(50),
                                         groupid                  bigint, 
                                         quoteitemid              bigint,
                                         omsid                    varchar(50),
                                         productcode              varchar(100),
                                         chargetypecode           varchar(50),
                                         reportingtypecode        varchar(50),
                                         FeeType                  as            (case when (chargetypecode = 'ACS' and measurecode = 'TRAN')
                                                                                         then 'TRX'                                                                                   
                                                                                      else  substring(reportingtypecode,1,3)
                                                                                 end), 
                                         sortorder                as            (case when chargetypecode='ILF' 
                                                                                        then 1
                                                                                      when (substring(reportingtypecode,1,3) = 'ACS' and measurecode <> 'TRAN')
                                                                                        then 2
                                                                                      when (chargetypecode = 'ACS' and measurecode = 'TRAN')
                                                                                        then 4
                                                                                      else 3
                                                                                 end),  
                                         measurecode              varchar(20)   not null,                                
                                         frequencycode            varchar(20)   not null,                                                                      
                                         LineItemNotes            varchar(8000) null
                                        )

  CREATE Table #TEMP_BillingRecords
        (
                IDSeq                    int not null identity(1,1) primary key,
		quoteid                  varchar(50),
                groupid                  bigint, 
                quoteitemid              bigint,
                omsid                    varchar(50),
                sortorder                int,
                RecType                  char(2),
                FeeType                  varchar(4),
                custombundlenameenabledflag int,
                productcode              varchar(100),
                Product                  varchar(255),
                Description              varchar(1000),
                Qty                      decimal(30,2),
                ItemAmt                  numeric(30,4),
                NetAmt                   numeric(30,2),
                PricingTiers             int,
                FamilyCode               char(3)
        )
  
  CREATE Table  #TEMP_ListRecords 
        (
                IDSeq                          int not null identity (1,1),
		quoteid                        varchar(50),
                groupid                        bigint, 
                quoteitemid                    bigint,
                omsid                          varchar(50),
                productcode                    varchar(50),
                custombundlenameenabledflag    int,
                RecType                        char(1),
                FeeType                        varchar(4),                
                PSeq                           int not null default 0,
                BSeq                           int not null default 0,
                NSeq                           int not null default 0,
                TSeq                           int not null default 0,
                Description                    varchar(8000),
                Qty                            decimal(18,2),
                ItemAmt                        numeric(18,4),
                NetAmt                         numeric(18,5),                
                PricingTiers                   int,
                FamilyCode                     char(3),
                SortOrder                      int
       )
  ----------------------------------------------------------------------------------------------- 
  --Step 1 : Get Raw Pricing Data for @IPVC_QuoteID,@IPBI_GroupID,@IPVC_OMSID
  -----------------------------------------------------------------------------------------------
  insert into #LT_RawPricingData(quoteid,groupid,quoteitemid,companyid,omsid,
                                 productcode,productname,custombundlename,custombundlenameenabledflag,
                                 productcategorycode,
                                 familycode,chargetypecode,reportingtypecode,
                                 measurecode,measurename,frequencycode,frequencyname,DisplayTransactionalProductPriceOnInvoiceFlag,
                                 chargeamount,
                                 discountpercent,discountamount,totaldiscountpercent,totaldiscountamount,
                                 extchargeamount,extSOCchargeamount,unitofmeasure,multiplier,extyear1chargeamount,                              
                                 netchargeamount,netextchargeamount,netextyear1chargeamount,
                                 pricingtiers,PricingLineItemNotes)
  exec QUOTES.dbo.uspQUOTES_PriceEngine @IPVC_QuoteID=@IPVC_QuoteID,@IPI_GroupID=@IPBI_GroupID,
                                        @IPVC_PropertyAmountAnnualized='NO',@IPI_ProformaInvoice=1
  ----> Remove other records that does not pertain to @IPVC_OMSID
  delete from #LT_RawPricingData where omsid <> @IPVC_OMSID 
  -----------------------------------------------------------------------------------------------
  --Step 2:Get Pricing Notes
  -----------------------------------------------------------------------------------------------
  select @LI_Min=1,@LI_Max=Max(SEQ) from #LT_RawPricingData with (nolock)
  while @LI_Min <= @LI_Max
  begin
    select @LI_RPDSeq = T.SEQ,@LBI_quoteitemid=T.quoteitemid,@LVC_productcode = T.productcode,
           @LI_custombundlenameenabledflag=T.custombundlenameenabledflag,
           @LVC_chargetypecode = T.chargetypecode,@LVC_reportingtypecode=reportingtypecode,
           @LVC_measurecode = T.measurecode,@LVC_frequencycode=T.frequencycode,
           @LVC_PricingLineItemNotes = coalesce(T.PricingLineItemNotes,'')
    from   #LT_RawPricingData T with (nolock)
    where  T.SEQ = @LI_Min

    insert into #LT_PricingNotes(RPDSeq,quoteid,groupid,quoteitemid,omsid,productcode,chargetypecode,reportingtypecode,measurecode,frequencycode,
                                 LineItemNotes)
    select @LI_RPDSeq as RPDSeq,@IPVC_QuoteID as quoteid,@IPBI_GroupID as groupid,@LBI_quoteitemid as quoteitemid,@IPVC_OMSID as omsid,
           @LVC_productcode as productcode,@LVC_chargetypecode as chargetypecode,@LVC_reportingtypecode as reportingtypecode,
           @LVC_measurecode as measurecode,@LVC_frequencycode as frequencycode,
           Items 
    from   ORDERS.[dbo].[fn_SplitDelimitedStringIntoRows](@LVC_PricingLineItemNotes,'|')
    where (@LI_custombundlenameenabledflag = 0)
    and   (@LVC_PricingLineItemNotes <> '')
    and   (Items <> '' and Items is not null) 
    order by seq asc
    
    select  @LVC_PricingLineItemNotes=null
    select @LI_Min = @LI_Min + 1
  end
  -----------------------------------------------------------------------------------------------
  --Step 3: Determine @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG value to show products for custom bundle.
  -----------------------------------------------------------------------------------------------
  declare @LVB_CMPBUNDLEFLAG                  int,
          @LVB_CMPBUNDLEEXPFLAG               int,
          @LVB_PRPBUNDLEEXPFLAG               int,
          @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG   int

  select @LVB_CMPBUNDLEFLAG=0,@LVB_CMPBUNDLEEXPFLAG=0,@LVB_PRPBUNDLEEXPFLAG=0,@LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG=0

  select @LVB_CMPBUNDLEEXPFLAG = (case CMP.CustomBundlesProductBreakDownTypeCode When 'YEBR' Then 1 Else 0 End)
  from   Customers.dbo.Company CMP with (nolock)
  where  CMP.IDSeq = @IPVC_CompanyID

  if (@IPVC_CompanyID = @IPVC_OMSID) -- Then this is a company bundle.
  begin
    select @LVB_CMPBUNDLEFLAG = 1
  end
  else
  begin
    select @LVB_PRPBUNDLEEXPFLAG = (case PRP.CustomBundlesProductBreakDownTypeCode When 'NOBR' Then 0 Else 1 End)
    from   Customers.dbo.Property PRP with (nolock)
    where  PRP.IDSeq = @IPVC_OMSID
  end
  
  If ((@LVB_CMPBUNDLEEXPFLAG & @LVB_PRPBUNDLEEXPFLAG = 1) OR (@LVB_CMPBUNDLEFLAG & @LVB_CMPBUNDLEEXPFLAG = 1) OR (~@LVB_CMPBUNDLEFLAG & @LVB_PRPBUNDLEEXPFLAG = 1))
  begin
   set @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG = 1
  end
  -----------------------------------------------------------------------------------------------
  --Step 4: get Billing Records
  ----------------------------------------------------------------------------------------------- 
  Insert into #TEMP_BillingRecords(omsid,quoteid,groupid,quoteitemid,sortorder,RecType,FeeType,custombundlenameenabledflag,productcode,Product,Description,Qty,ItemAmt,NetAmt,PricingTiers,FamilyCode)
  select @IPVC_OMSID as omsid,S.quoteid,S.groupid,Max(S.quoteitemid) as quoteitemid,
         Max(S.sortorder) as sortorder,'B' as RecType,S.FeeType as FeeType,
         S.custombundlenameenabledflag                                                  as  custombundlenameenabledflag, 
         (case when  (S.custombundlenameenabledflag =1) then NULL
                else productcode
          end)                                                                           as productcode,
         coalesce(S.custombundlename,S.productname)                                      as Product,
         ------------------------------------------
         (case when (S.FeeType <> 'TRX' and S.FrequencyCode in ('SG','YR','MN'))
                then ltrim(rtrim(replace(max(S.FrequencyName),'Fee',''))) + ' Fees;'
               when (S.FeeType <> 'TRX' and S.FrequencyCode not in ('SG','YR','MN'))
                then ltrim(rtrim(replace(max(S.FrequencyName),'Fee',''))) + ';'
               else ''
          end) +
         -------
         (case when (S.FeeType <> 'TRX')
                then ' ' + max(S.MeasureName) + ' Pricing;'               
               else ''
          end) + ' ' +
          -------
         Max(convert(varchar(50),convert(int,
                                        (case when (S.FeeType <> 'TRX' and S.familycode = 'LSD' and S.measurecode = 'UNIT')
                                                then  S.Multiplier    
                                              else    S.unitofmeasure 
                                        end)
                ))
             ) +
          -------
         (case when (S.FeeType <> 'TRX')
                then ' ' + max(S.MeasureName) + '(s);'               
               else '' 
          end)                                                                           as Description,
         ------------------------------------------
         sum(convert(numeric(30,2),
                                  (case when (S.FeeType <> 'TRX' and S.familycode = 'LSD' and S.measurecode = 'UNIT')
                                          then  S.Multiplier    
                                        else    S.unitofmeasure 
                                   end)
                     )
            )                                                                            as Qty,
         sum(S.ItemAmt)                                                                  as ItemAmt,
         convert(numeric(30,2),sum(S.netextchargeamount))                                as NetAmt,
         (case when (S.custombundlenameenabledflag =1) then 1
                else Max(S.PricingTiers)
          end)                                                                           as PricingTiers,
         (case when  (S.custombundlenameenabledflag =1) then NULL
                else FamilyCode
          end)                                                                           as FamilyCode
  from  #LT_RawPricingData S with (nolock)
  group by S.quoteid,S.groupid,S.FeeType,
           (case when  (S.custombundlenameenabledflag =1) then NULL
                 else S.productcode
            end),
           coalesce(S.custombundlename,S.productname),
           S.chargetypecode,S.measurecode,S.frequencycode,
           (case when (S.FeeType <> 'TRX' and S.familycode = 'LSD' and S.measurecode = 'UNIT')
                   then  S.Multiplier    
                 else    S.unitofmeasure 
            end),S.custombundlenameenabledflag,
           (case when  (S.custombundlenameenabledflag =1) then NULL
                  else FamilyCode
            end) 
  order by sortorder asc,Product asc
  -----------------------------------------------------------------------------------------------
  --Step 5: Create Final List Products (details for Proforma Invoice)
  -----------------------------------------------------------------------------------------------
  ---Step 5.1 : Product Records
  -----------------------------------------------------------------------------------------------
  Insert into #TEMP_ListRecords(omsid,quoteid,groupid,quoteitemid,productcode,custombundlenameenabledflag,
                                RecType,FeeType,PSeq,BSeq,NSeq,TSeq,Description,Qty,ItemAmt,NetAmt,PricingTiers,FamilyCode,SortOrder)
  select T.omsid,T.quoteid,T.groupid,T.quoteitemid,T.productcode,T.custombundlenameenabledflag,
         'P'            as RecType,
         T.FeeType      as FeeType,
         ROW_NUMBER() OVER (ORDER BY T.sortorder asc,T.Product asc
                           ) 
                        as PSeq,
         0              as BSeq,
         0              as NSeq,
         0              as TSeq,
         T.Product      as Description,
         T.Qty          as Qty,
         T.ItemAmt      as ItemAmt,
         T.NetAmt       as NetAmt,
         T.PricingTiers as PricingTiers,
         (case when T.FeeType = 'TRX' 
                then T.FamilyCode
               else  NULL
          end)          as FamilyCode,
         T.SortOrder    as SortOrder
  from   #TEMP_BillingRecords T with (nolock)
  order by PSeq asc
  -----------------------------------------------------------------------------------------------
  ---Step 5.2 : Billing Records for Non Transactional Products
  -----------------------------------------------------------------------------------------------
  Insert into #TEMP_ListRecords(omsid,quoteid,groupid,quoteitemid,productcode,custombundlenameenabledflag,
                                RecType,FeeType,PSeq,BSeq,NSeq,TSeq,Description,Qty,ItemAmt,NetAmt,PricingTiers,FamilyCode,SortOrder)
  select T.omsid,T.quoteid,T.groupid,T.quoteitemid,T.productcode,T.custombundlenameenabledflag,
         'B'            as RecType,
         T.FeeType      as FeeType,
         T.PSeq         as PSeq,
         ROW_NUMBER() OVER (PARTITION BY T.PSeq ORDER BY T.PSeq,S.sortorder asc,S.Product asc
                           )     
                        as BSeq,
         0              as NSeq,
         0              as TSeq,
         S.Description  as Description,
         S.Qty          as Qty,
         S.ItemAmt      as ItemAmt,
         S.NetAmt       as NetAmt,
         S.PricingTiers as PricingTiers,
         S.FamilyCode   as FamilyCode,
         S.SortOrder    as SortOrder
  from   #TEMP_ListRecords T with (nolock)
  inner join
         #TEMP_BillingRecords S with (nolock)
  on     T.omsid   = S.omsid
  and    T.quoteid = S.quoteid
  and    T.groupid = S.groupid
  and    T.quoteitemid = S.quoteitemid
  and    coalesce(T.productcode,'') = coalesce(S.productcode,'')
  and    T.Description  = S.product
  and    T.FeeType  = S.FeeType
  and    T.FeeType  <> 'TRX'
  and    T.SortOrder= S.SortOrder
  and    T.RecType = 'P'
  and    S.RecType = 'B'
  order by PSeq asc,BSeq asc
  -----------------------------------------------------------------------------------------------
  ---Step 5.3 : Notes Records -- Alacarte.
  -----------------------------------------------------------------------------------------------
  Insert into #TEMP_ListRecords(omsid,quoteid,groupid,quoteitemid,productcode,custombundlenameenabledflag,
                                RecType,FeeType,PSeq,BSeq,NSeq,TSeq,Description,Qty,ItemAmt,NetAmt,PricingTiers,FamilyCode,SortOrder)
  select T.omsid,T.quoteid,T.groupid,T.quoteitemid,T.productcode,T.custombundlenameenabledflag,
         'N'            as RecType,
         T.FeeType      as FeeType,
         T.PSeq         as PSeq,             
         T.BSeq         as BSeq,
         ROW_NUMBER() OVER (PARTITION BY T.PSeq,T.BSeq ORDER BY  T.PSeq asc,T.BSeq asc,S.SEQ asc
                           )
                          as NSeq,
         0                as TSeq,
         S.LineItemNotes  as Description,
         NULL             as Qty,
         NULL             as ItemAmt,
         NULL             as NetAmt,
         T.PricingTiers   as PricingTiers,
         NULL             as FamilyCode,
         T.SortOrder      as SortOrder
  from   #TEMP_ListRecords T with (nolock)
  inner join
         #LT_PricingNotes S with (nolock)
  on     T.omsid   = S.omsid
  and    T.quoteid = S.quoteid
  and    T.groupid = S.groupid
  and    T.quoteitemid = S.quoteitemid
  and    coalesce(T.productcode,'') = coalesce(S.productcode,'')
  and    T.custombundlenameenabledflag = 0
  and    T.FeeType  = S.FeeType
  and    T.FeeType  <> 'TRX'
  and    T.SortOrder= S.SortOrder
  and    T.RecType = 'B'
  order by PSeq asc,BSeq asc,NSeq asc
  -----------------------------------------------------------------------------------------------
  ---Step 5.4 : Notes Records -- Custom Bundle.  
  ---            Product becomes Notes if @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG=1
  -----------------------------------------------------------------------------------------------
  Insert into #TEMP_ListRecords(omsid,quoteid,groupid,quoteitemid,productcode,custombundlenameenabledflag,
                                RecType,FeeType,PSeq,BSeq,NSeq,TSeq,Description,Qty,ItemAmt,NetAmt,PricingTiers,FamilyCode,SortOrder)
  select T.omsid,T.quoteid,T.groupid,T.quoteitemid,T.productcode,T.custombundlenameenabledflag,
         'N'            as RecType,
         T.FeeType      as FeeType,
         T.PSeq         as PSeq,             
         T.BSeq         as BSeq,
         ROW_NUMBER() OVER (PARTITION BY T.PSeq,T.BSeq ORDER BY T.PSeq asc,T.BSeq asc,S.Productname asc
                           )
                          as NSeq,
         0                as TSeq,
         S.Productname    as Description,
         NULL             as Qty,
         NULL             as ItemAmt,
         NULL             as NetAmt,
         T.PricingTiers   as PricingTiers,
         NULL             as FamilyCode,
         T.SortOrder      as SortOrder
  from   #TEMP_ListRecords T with (nolock)
  inner join
         #LT_RawPricingData S with (nolock)
  on     T.omsid   = S.omsid
  and    T.quoteid = S.quoteid
  and    T.groupid = S.groupid  
  and    T.FeeType  = S.FeeType
  and    T.SortOrder= S.SortOrder
  and    T.RecType = 'B'
  and    T.custombundlenameenabledflag = S.custombundlenameenabledflag
  and    (@LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG=1)
  and    (S.custombundlenameenabledflag=1)
  and    (T.custombundlenameenabledflag=1)
  order by PSeq asc,BSeq asc,NSeq asc
  -----------------------------------------------------------------------------------------------
  ---Step 5.5 : Notes Records -- For Transactions.  
  ---           Sample Transactions
  -----------------------------------------------------------------------------------------------
  Insert into #TEMP_ListRecords(omsid,quoteid,groupid,quoteitemid,productcode,custombundlenameenabledflag,
                                RecType,FeeType,PSeq,BSeq,NSeq,TSeq,Description,Qty,ItemAmt,NetAmt,PricingTiers,FamilyCode,SortOrder)
  select T.omsid,T.quoteid,T.groupid,T.quoteitemid,T.productcode,T.custombundlenameenabledflag,
         'N'            as RecType,
         T.FeeType      as FeeType,
         T.PSeq         as PSeq,             
         T.BSeq         as BSeq,
         ROW_NUMBER() OVER (PARTITION BY T.PSeq,T.BSeq ORDER BY T.PSeq asc,T.BSeq asc,T.SortOrder asc
                           )
                          as NSeq,
         1                as TSeq,
         'MM/DD/YYYY - Sample Transaction'
                          as Description,
         (case when S.DisplayTransactionalProductPriceOnInvoiceFlag=1
                 then T.Qty
               else null
          end)            as Qty,
         (case when S.DisplayTransactionalProductPriceOnInvoiceFlag=1
                 then T.ItemAmt
               else null
          end)            as ItemAmt,
         (case when S.DisplayTransactionalProductPriceOnInvoiceFlag=1
                 then T.NetAmt
               else null
          end)            as NetAmt,
         T.PricingTiers   as PricingTiers,
         NULL             as FamilyCode,
         T.SortOrder      as SortOrder
  from   #TEMP_ListRecords T with (nolock)
  inner join
         #LT_RawPricingData S with (nolock)
  on     T.omsid   = S.omsid
  and    T.quoteid = S.quoteid
  and    T.groupid = S.groupid
  and    T.quoteitemid = S.quoteitemid
  and    coalesce(T.productcode,'') = coalesce(S.productcode,'')
  and    T.FeeType  = S.FeeType
  and    T.SortOrder= S.SortOrder
  and    T.FeeType  = 'TRX'  
  and    T.RecType  = 'P'
  order by PSeq asc,BSeq asc,NSeq asc
  -----------------------------------------------------------------------------------------------
  --Step 6: Total Records
  -----------------------------------------------------------------------------------------------
  Insert into #TEMP_ListRecords(omsid,quoteid,groupid,quoteitemid,productcode,custombundlenameenabledflag,
                                RecType,FeeType,PSeq,BSeq,NSeq,TSeq,Description,Qty,ItemAmt,NetAmt,PricingTiers,FamilyCode,SortOrder)
  select T.omsid,T.quoteid,T.groupid,
         null               as quoteitemid,
         null               as productcode,
         0                  as custombundlenameenabledflag,
         'T' RecType,T.FeeType,
          Max(T.PSeq)       as PSeq,
          max(T.BSeq)+99999 as BSeq,
          max(T.NSeq)+99999 as NSeq,
          max(T.TSeq)+99999 as TSeq,
          null              as Description,
          null              as Qty,
          null              as ItemAmt,
          sum(T.NetAmt)     as NetAmt,
          null              as PricingTiers,
          null              as FamilyCode,
          T.SortOrder       as SortOrder
  from    #TEMP_ListRecords T with (nolock)  
  where   T.RecType = 'P'
  group by T.omsid,T.quoteid,T.groupid,
           T.FeeType,T.SortOrder
  ORDER BY PSeq asc,T.SortOrder asc,T.FeeType asc
  -----------------------------------------------------------------------------------------------
  Update T
  set    T.Qty = null,T.ItemAmt=null,T.NetAmt=null
  from   #TEMP_ListRecords T with (nolock)
  inner join
         #LT_RawPricingData S with (nolock)
  on     T.omsid   = S.omsid
  and    T.quoteid = S.quoteid
  and    T.groupid = S.groupid
  and    T.quoteitemid = S.quoteitemid
  and    T.FeeType     = S.FeeType
  and    T.SortOrder   = S.SortOrder
  and    ((T.RecType = 'P' and T.FeeType <> 'TRX')
            OR
          (T.RecType = 'P' and T.FeeType = 'TRX' and S.DisplayTransactionalProductPriceOnInvoiceFlag=1)
         )
  where  ((T.RecType = 'P' and T.FeeType <> 'TRX')
            OR
          (T.RecType = 'P' and T.FeeType = 'TRX' and S.DisplayTransactionalProductPriceOnInvoiceFlag=1)
         )
  -----------------------------------------------------------------------------------------------
  --Step 9: Final Select 
  -----------------------------------------------------------------------------------------------        
  select T.IDseq,T.RecType,T.FeeType,T.PSeq,T.BSeq,T.NSeq,T.TSeq,T.Description,T.Qty,T.ItemAmt,T.NetAmt,
         (case when T.Qty is not null then '(e)' else null end) as TaxAmt,
         T.PricingTiers,T.FamilyCode,T.SortOrder 
  from   #TEMP_ListRecords T with (nolock)
  order by T.SortOrder ASC,T.PSeq ASC,T.BSeq ASC,T.NSeq ASC,T.TSeq ASC
  ----------------------------------------------------------------------------------------------- 
  --Step 10 : Final Cleanup
  if (object_id('tempdb.dbo.#LT_RawPricingData') is not null) 
  begin
    drop table #LT_RawPricingData
  end
  if (object_id('tempdb.dbo.#LT_PricingNotes') is not null) 
  begin
    drop table #LT_PricingNotes
  end
  if (object_id('tempdb.dbo.#TEMP_BillingRecords') is not null) 
  begin
    drop table #TEMP_BillingRecords
  end
  if (object_id('tempdb.dbo.#TEMP_ListRecords') is not null) 
  begin
    drop table #TEMP_ListRecords
  end
  ----------------------------------------------------------------------------------------------- 
END
GO
