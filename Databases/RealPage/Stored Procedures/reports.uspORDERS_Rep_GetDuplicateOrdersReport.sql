SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : uspORDERS_Rep_GetDuplicateOrdersReport      
-- Description     : This procedure gets all duplicate orders that have contracts between start and enddate range
---                  when left to default (which is the preferred search), 
---                       @IPVC_StartDate will be 01/01/1900 and enddate will be 12/31/2099
-- Input Parameters: Except @IPVC_StartDate and @IPVC_EndDate 
--            
-- Code Example    : Exec [dbo].[uspORDERS_Rep_GetDuplicateOrdersReport] 
--       
-- Revision History:      
-- Author          : SRS
-- 03/20/2009      : Stored Procedure Created.      
-------------------------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspORDERS_Rep_GetDuplicateOrdersReport] 
AS      
BEGIN         
  SET NOCOUNT ON;   
  set ANSI_WARNINGS off;  
  declare @LI_MIN           bigint
  declare @LI_MAX           bigint     
  ------------------------------------------------------------
  Create table #LT_DuplicateOrders (SortSeq                       int not null identity(1,1) Primary Key,
                                    InternalRecordIndicator       int   NOT NULL default (100),   -- 100= Summary;1000=Detail
                                    DetailInternalRecordIndicator int,
                                    ConflictSortSeq               int not null default(1),
                                    IdentifierProductCode         varchar(50),
                                    IdentifierProductName         varchar(255),
                                    AccountID         varchar(50),
                                    CompanyID         varchar(50),
                                    PropertyID        varchar(50),
                                    CompanyName       varchar(255),
                                    PropertyName      varchar(255),
                                    FamilyName        varchar(255),
                                    DuplicateFoundOnProductName  varchar(255),
                                    DuplicateCount    varchar(50), 
                                    ProductCode       varchar(50),                                    
                                   
                                    OrderID           varchar(50),
                                    OrderItemID       varchar(50),
                                    OrderGroupID      varchar(50),
                                    CustomBundleFlag  varchar(3),
                                    CustomBundleName  varchar(255),
                                    DetailProductName varchar(255),
                                    ChargeTypeCode    varchar(50),
                                    MeasureCode       varchar(50),
                                    FrequencyCode     varchar(50),
                                    ContractStartdate varchar(50),
                                    ContractEndDate   varchar(50),
                                    LastBilledFrom    varchar(50),
                                    LastBilledTo      varchar(50),                                    
                                    ReportComments    varchar(4000)
                                   )
  Create table #TEMPInvalidProduct(SortSeq            int not null identity(1,1) Primary Key,
                                   PrimaryProductCode varchar(50),
                                   InvalidProductCode varchar(50)
                                  )
 
  Create table #TempHoldingTable  (SortSeq                 int not null identity(1,1) Primary Key,
                                   AccountID               varchar(50),
                                   CompanyID               varchar(50),
                                   PropertyID              varchar(50), 
                                   CompanyName             varchar(255),
                                   PropertyName            varchar(255),                            
                                   PrimaryOrderID          varchar(50),
                                   PrimaryOrderGroupID     bigint,
                                   PrimaryOrderitemID      bigint,
                                   PrimaryProductCode      varchar(50),
                                   PrimaryProductName      varchar(255),
                                   PrimaryFamily           varchar(255),
                                   PrimaryCustomBundleFlag int,
                                   PrimaryCustomBundleName varchar(255),
                                   PrimaryChargetypeCode   varchar(20),
                                   PrimaryMeasureCode      varchar(20),
                                   PrimaryFrequencyCode    varchar(20),
                                   PrimaryStartDate        datetime,
                                   PrimaryEndDate          datetime,
                                   PrimaryLastBilledFrom   datetime,
                                   PrimaryLastBilledTo     datetime,

                                   ConflictOrderID          varchar(50),
                                   ConflictOrderGroupID     bigint,
                                   ConflictOrderitemID      bigint,
                                   ConflictProductCode      varchar(50),
                                   ConflictProductName      varchar(255),
                                   ConflictFamily           varchar(255),
                                   ConflictCustomBundleFlag int,
                                   ConflictCustomBundleName varchar(255),
                                   ConflictChargetypeCode   varchar(20),
                                   ConflictMeasureCode      varchar(20),
                                   ConflictFrequencyCode    varchar(20),
                                   ConflictStartDate        datetime,
                                   ConflictEndDate          datetime,
                                   ConflictLastBilledFrom   datetime,
                                   ConflictLastBilledTo     datetime,

                                   DetailInternalRecordIndicator int   NOT NULL default (1),   -- 1= SameProductCode Conflict;2= Invalid Product Combo Conflict
                                  )
  ---------------------------------------------------------------
  ---Step 1 : Construct InvalidProduct Combo distinct Set
  ;WITH S AS
  (select distinct PIC.FirstProductCode as PrimaryProduct,PIC.SecondProductCode as InvalidProduct
                   ,DENSE_RANK() over (order by FirstProductCode asc,SecondProductCode asc) as Rank                   
   from   Products.dbo.ProductInvalidCombo PIC with (nolock)
   where  not exists (select top 1 1
                      from   Products.dbo.ProductInvalidCombo P with (nolock)
                      where  (P.SecondProductCode = PIC.FirstProductCode
                      and
                              P.FirstProductCode  = PIC.SecondProductCode
                             )
                     )
   group by PIC.FirstProductCode,PIC.SecondProductCode
   union
   select distinct PIC.SecondProductCode as PrimaryProduct,PIC.FirstProductCode as InvalidProduct
                   ,DENSE_RANK() over (order by FirstProductCode asc,SecondProductCode asc) as Rank                   
   from   Products.dbo.ProductInvalidCombo PIC with (nolock)
   where  not exists (select top 1 1
                      from   Products.dbo.ProductInvalidCombo P with (nolock)
                      where  (P.FirstProductCode = PIC.SecondProductCode
                              and
                              P.SecondProductCode  = PIC.FirstProductCode
                             )
                     )
   group by PIC.FirstProductCode,PIC.SecondProductCode
  ) 
  Insert into #TEMPInvalidProduct(PrimaryProductCode,InvalidProductCode)
  select X.PrimaryProduct,X.InvalidProduct
  from (SELECT distinct S.PrimaryProduct,S.InvalidProduct as InvalidProduct,S.Rank
                       ,DENSE_RANK() over (order by PrimaryProduct asc) as Rank1         
        FROM       S
        ) X
  where X.Rank1 = (select Min(T.Rank1) from 
                     (SELECT distinct S.PrimaryProduct,S.InvalidProduct as InvalidProduct,S.Rank
                                      ,DENSE_RANK() over (order by PrimaryProduct asc) as Rank1         
                      FROM       S
                      ) T
                   where T.Rank = X.Rank                   
                   )
  ---------------------------------------------------------------
  --Step 2 : Get Same Product Code Conflict
  Insert into #TempHoldingTable(DetailInternalRecordIndicator,AccountID,CompanyID,PropertyID,
                                PrimaryOrderID,PrimaryOrderGroupID,PrimaryOrderitemID,
                                PrimaryProductCode,PrimaryProductName,PrimaryFamily,PrimaryCustomBundleFlag,PrimaryCustomBundleName,
                                PrimaryChargetypeCode,PrimaryMeasureCode,PrimaryFrequencyCode,PrimaryStartDate,PrimaryEndDate,PrimaryLastBilledFrom,PrimaryLastBilledTo,
                                ConflictOrderID,ConflictOrderGroupID,ConflictOrderitemID,
                                ConflictProductCode,ConflictProductName,ConflictFamily,ConflictCustomBundleFlag,ConflictCustomBundleName,
                                ConflictChargetypeCode,ConflictMeasureCode,ConflictFrequencyCode,ConflictStartDate,ConflictEndDate,ConflictLastBilledFrom,ConflictLastBilledTo
                               )
  select  1 as DetailInternalRecordIndicator,O.AccountIDSeq as AccountID,O.Companyidseq as CompanyID,O.PropertyIDSeq as PropertyID
          ,OI.Orderidseq as PrimaryOrderID,OI.OrderGroupIDSeq as PrimaryOrderGroupID,OI.IDSeq as PrimaryOrderitemID
          ,OI.Productcode as PrimaryProductCode,PRD.DisplayName as PrimaryProductName,F.Name as PrimaryFamily,convert(int,OG.CustomBundleNameEnabledFlag) as PrimaryCustomBundleFlag
          ,OG.Name as PrimaryCustomBundleName,OI.Chargetypecode as PrimaryChargetypeCode,OI.MeasureCode as PrimaryMeasureCode,OI.FrequencyCode as PrimaryFrequencyCode
          ,OI.StartDate as PrimaryStartDate,OI.Enddate as PrimaryEndDate,OI.LastBillingPeriodFromDate as PrimaryLastBilledFrom,OI.LastBillingPeriodToDate as PrimaryLastBilledTo
          ----------------------------
          ,S.ConflictOrderID,S.ConflictOrderGroupID,S.ConflictOrderitemID 
          ,S.ConflictProductCode,S.ConflictProductName,S.ConflictFamily,S.ConflictCustomBundleFlag,S.ConflictCustomBundleName
          ,S.ConflictChargetypeCode,S.ConflictMeasureCode,S.ConflictFrequencyCode,S.ConflictStartDate,S.ConflictEndDate,S.ConflictLastBilledFrom,S.ConflictLastBilledTo
  from   Orders.dbo.[Order] O with (nolock)
  inner join
         Orders.dbo.[OrderGroup] OG with (nolock)
  on     O.Orderidseq = OG.Orderidseq
  inner join
         Orders.dbo.[Orderitem] OI with (nolock)
  on     O.Orderidseq = OI.Orderidseq
  and    O.Orderidseq = OG.Orderidseq
  and    OG.IDSeq     = OI.OrderGroupIDSeq
  inner join
         Products.dbo.Product PRD with (nolock)
  on     OI.ProductCode   = PRD.Code
  and    OI.Priceversion  = PRD.Priceversion
  inner join
         Products.dbo.Family F with (nolock)
  on     PRD.FamilyCode = F.Code
  inner join
         Products.dbo.Charge CHG with (nolock)
  on     OI.ProductCode   = CHG.ProductCode
  and    OI.Priceversion  = CHG.Priceversion
  and    OI.Measurecode   = CHG.measurecode
  and    OI.Frequencycode = CHG.Frequencycode 
  and    OI.Chargetypecode= CHG.Chargetypecode
  and    CHG.QuantityEnabledFlag = 0
  and    CHG.ReportingTypecode   = 'ACSF'
  and    OI.Chargetypecode = 'ACS' 
  and    OI.Statuscode in ('FULF')
  inner join
      (select XO.Companyidseq,XO.PropertyIDSeq,XO.AccountIDSeq,XOI.ProductCode,
              XOI.Chargetypecode,XCHG.ReportingTypecode,
              XOI.Orderidseq as ConflictOrderID,XOI.OrderGroupIDSeq as ConflictOrderGroupID,XOI.IDSeq   as ConflictOrderitemID
              ,XOI.Productcode as ConflictProductCode,XPRD.DisplayName as ConflictProductName,XF.Name as ConflictFamily,convert(int,XOG.CustomBundleNameEnabledFlag) as ConflictCustomBundleFlag
              ,XOG.Name as ConflictCustomBundleName,XOI.Chargetypecode as ConflictChargetypeCode,XOI.MeasureCode as ConflictMeasureCode,XOI.FrequencyCode as ConflictFrequencyCode
              ,XOI.StartDate  as ConflictStartdate,XOI.Enddate as ConflictEnddate
              ,XOI.Canceldate as ConflictCanceldate
              ,XOI.LastBillingPeriodFromDate as ConflictLastBilledFrom,XOI.LastBillingPeriodToDate as ConflictLastBilledTo              
              from   Orders.dbo.[Order] XO with (nolock)
              inner join
                     Orders.dbo.[OrderGroup] XOG with (nolock)
              on     XO.Orderidseq = XOG.Orderidseq
              inner join
                     Orders.dbo.[Orderitem] XOI with (nolock)
              on     XO.Orderidseq = XOI.Orderidseq
              and    XO.Orderidseq = XOG.Orderidseq
              and    XOG.IDSeq     = XOI.OrderGroupIDSeq
              inner join
                     Products.dbo.Product XPRD with (nolock)
              on     XOI.ProductCode   = XPRD.Code
              and    XOI.Priceversion  = XPRD.Priceversion
              inner join
                     Products.dbo.Family XF with (nolock)
              on     XPRD.FamilyCode = XF.Code              
              inner join
                     Products.dbo.Charge XCHG with (nolock)
              on     XOI.ProductCode   = XCHG.ProductCode
              and    XOI.Priceversion  = XCHG.Priceversion
              and    XOI.Measurecode   = XCHG.measurecode
              and    XOI.Frequencycode = XCHG.Frequencycode 
              and    XOI.Chargetypecode= XCHG.Chargetypecode
              and    XCHG.QuantityEnabledFlag = 0
              and    XCHG.ReportingTypecode   = 'ACSF'
              and    XOI.Chargetypecode       = 'ACS'
              and    XOI.Statuscode in ('FULF')            
             ) S
  on     O.AccountIDSeq      = S.AccountIDSeq
  and    OI.ProductCode      = S.ProductCode
  and    OI.Chargetypecode   = S.Chargetypecode
  and    OI.ReportingTypecode= S.ReportingTypecode
  and    OI.IDSeq        <> S.ConflictOrderitemID
  and    OI.Startdate >= S.ConflictStartdate
  and    OI.Startdate <= coalesce(S.ConflictCanceldate-1,S.ConflictEnddate)
  order by OI.Startdate asc,OI.Enddate asc,ConflictStartdate asc,ConflictEndDate asc
  ---------------------------------------------------------------
  --Step 2 : Get Invalid Product Combo Conflict
  Insert into #TempHoldingTable(DetailInternalRecordIndicator,AccountID,CompanyID,PropertyID,
                                PrimaryOrderID,PrimaryOrderGroupID,PrimaryOrderitemID,
                                PrimaryProductCode,PrimaryProductName,PrimaryFamily,PrimaryCustomBundleFlag,PrimaryCustomBundleName,
                                PrimaryChargetypeCode,PrimaryMeasureCode,PrimaryFrequencyCode,PrimaryStartDate,PrimaryEndDate,PrimaryLastBilledFrom,PrimaryLastBilledTo,
                                ConflictOrderID,ConflictOrderGroupID,ConflictOrderitemID,
                                ConflictProductCode,ConflictProductName,ConflictFamily,ConflictCustomBundleFlag,ConflictCustomBundleName,
                                ConflictChargetypeCode,ConflictMeasureCode,ConflictFrequencyCode,ConflictStartDate,ConflictEndDate,ConflictLastBilledFrom,ConflictLastBilledTo
                               )
  select  2 as DetailInternalRecordIndicator,O.AccountIDSeq as AccountID,O.Companyidseq as CompanyID,O.PropertyIDSeq as PropertyID
          ,OI.Orderidseq as PrimaryOrderID,OI.OrderGroupIDSeq as PrimaryOrderGroupID,OI.IDSeq as PrimaryOrderitemID
          ,OI.Productcode as PrimaryProductCode,PRD.DisplayName as PrimaryProductName,F.Name as PrimaryFamily,convert(int,OG.CustomBundleNameEnabledFlag) as PrimaryCustomBundleFlag
          ,OG.Name as PrimaryCustomBundleName,OI.Chargetypecode as PrimaryChargetypeCode,OI.MeasureCode as PrimaryMeasureCode,OI.FrequencyCode as PrimaryFrequencyCode
          ,OI.StartDate as PrimaryStartDate,OI.Enddate as PrimaryEndDate,OI.LastBillingPeriodFromDate as PrimaryLastBilledFrom,OI.LastBillingPeriodToDate as PrimaryLastBilledTo
          ----------------------------
          ,S.ConflictOrderID,S.ConflictOrderGroupID,S.ConflictOrderitemID 
          ,S.ConflictProductCode,S.ConflictProductName,S.ConflictFamily,S.ConflictCustomBundleFlag,S.ConflictCustomBundleName
          ,S.ConflictChargetypeCode,S.ConflictMeasureCode,S.ConflictFrequencyCode,S.ConflictStartDate,S.ConflictEndDate,S.ConflictLastBilledFrom,S.ConflictLastBilledTo
  from   Orders.dbo.[Order] O with (nolock)
  inner join
         Orders.dbo.[OrderGroup] OG with (nolock)
  on     O.Orderidseq = OG.Orderidseq
  inner join
         Orders.dbo.[Orderitem] OI with (nolock)
  on     O.Orderidseq = OI.Orderidseq
  and    O.Orderidseq = OG.Orderidseq
  and    OG.IDSeq     = OI.OrderGroupIDSeq
  inner join
         Products.dbo.Product PRD with (nolock)
  on     OI.ProductCode   = PRD.Code
  and    OI.Priceversion  = PRD.Priceversion
  inner join
         Products.dbo.Family F with (nolock)
  on     PRD.FamilyCode = F.Code
  inner join
         Products.dbo.Charge CHG with (nolock)
  on     OI.ProductCode   = CHG.ProductCode
  and    OI.Priceversion  = CHG.Priceversion
  and    OI.Measurecode   = CHG.measurecode
  and    OI.Frequencycode = CHG.Frequencycode 
  and    OI.Chargetypecode= CHG.Chargetypecode
  and    CHG.QuantityEnabledFlag = 0
  and    CHG.ReportingTypecode   = 'ACSF'
  and    OI.Chargetypecode = 'ACS' 
  and    OI.Statuscode in ('FULF')
  inner join
      (select XO.Companyidseq,XO.PropertyIDSeq,XO.AccountIDSeq,
              XOI.Chargetypecode,XCHG.ReportingTypecode,
              XOI.Orderidseq as ConflictOrderID,XOI.OrderGroupIDSeq as ConflictOrderGroupID,XOI.IDSeq   as ConflictOrderitemID,
              T.PrimaryProductCode as PrimaryProductCode,
              T.InvalidProductCode as ConflictProductCode
              ,XPRD.DisplayName as ConflictProductName,XF.Name as ConflictFamily,convert(int,XOG.CustomBundleNameEnabledFlag) as ConflictCustomBundleFlag
              ,XOG.Name as ConflictCustomBundleName,XOI.Chargetypecode as ConflictChargetypeCode,XOI.MeasureCode as ConflictMeasureCode,XOI.FrequencyCode as ConflictFrequencyCode
              ,XOI.StartDate  as ConflictStartdate,XOI.Enddate as ConflictEnddate,
              XOI.Canceldate as ConflictCanceldate
              ,XOI.LastBillingPeriodFromDate as ConflictLastBilledFrom,XOI.LastBillingPeriodToDate as ConflictLastBilledTo              
              from   Orders.dbo.[Order] XO with (nolock)
              inner join
                     Orders.dbo.[OrderGroup] XOG with (nolock)
              on     XO.Orderidseq = XOG.Orderidseq
              inner join
                     Orders.dbo.[Orderitem] XOI with (nolock)
              on     XO.Orderidseq = XOI.Orderidseq
              and    XO.Orderidseq = XOG.Orderidseq
              and    XOG.IDSeq     = XOI.OrderGroupIDSeq
              inner join
                     #TEMPInvalidProduct T with (nolock)
              on     XOI.ProductCode = T.InvalidProductCode
              inner join
                     Products.dbo.Product XPRD with (nolock)
              on     XOI.ProductCode   = XPRD.Code
              and    XOI.Priceversion  = XPRD.Priceversion
              inner join
                     Products.dbo.Family XF with (nolock)
              on     XPRD.FamilyCode = XF.Code              
              inner join
                     Products.dbo.Charge XCHG with (nolock)
              on     XOI.ProductCode   = XCHG.ProductCode
              and    XOI.Priceversion  = XCHG.Priceversion
              and    XOI.Measurecode   = XCHG.measurecode
              and    XOI.Frequencycode = XCHG.Frequencycode 
              and    XOI.Chargetypecode= XCHG.Chargetypecode
              and    XCHG.QuantityEnabledFlag = 0
              and    XCHG.ReportingTypecode   = 'ACSF'
              and    XOI.Chargetypecode       = 'ACS'
              and    XOI.Statuscode in ('FULF')            
             ) S
  on     O.AccountIDSeq      = S.AccountIDSeq
  and    OI.ProductCode      = S.PrimaryProductCode
  and    OI.Chargetypecode   = S.Chargetypecode
  and    OI.ReportingTypecode= S.ReportingTypecode
  and    OI.IDSeq            <> S.ConflictOrderitemID
  and    OI.Startdate >= S.ConflictStartdate
  and    OI.Startdate <= coalesce(S.ConflictCanceldate-1,S.ConflictEnddate)
  order by OI.Startdate asc,OI.Enddate asc,ConflictStartdate asc,ConflictEndDate asc
  ---------------------------------------------------------------
  ---Update For Company Name and Property Name
  Update T
  set    T.CompanyName = C.Name
  from   #TempHoldingTable T with (nolock)
  inner join
         Customers.dbo.Company C with (nolock)
  on     T.CompanyID = C.IDSeq

  Update T
  set    T.PropertyName = P.Name
  from   #TempHoldingTable T with (nolock)
  inner join
         Customers.dbo.Property P with (nolock)
  on     T.PropertyID = P.IDSeq
  ---------------------------------------------------------------
  ---Populate Summary Records
  ---------------------------------------------------------------
  Insert into #LT_DuplicateOrders(InternalRecordIndicator,DetailInternalRecordIndicator,IdentifierProductCode,IdentifierProductName,ConflictSortSeq,
                                  AccountID,CompanyID,PropertyID,CompanyName,PropertyName,
                                  FamilyName,DuplicateFoundOnProductName,DuplicateCount,
                                  ProductCode,OrderID,OrderItemID,OrderGroupID,CustomBundleFlag,CustomBundleName,DetailProductName,
                                  ChargeTypeCode,MeasureCode,FrequencyCode,ContractStartdate,ContractEndDate,LastBilledFrom,LastBilledTo,
                                  ReportComments)
  select 100 as InternalRecordIndicator,T.DetailInternalRecordIndicator,T.PrimaryProductCode as IdentifierProductCode,
         Max(T.PrimaryProductName) as IdentifierProductName,1 as ConflictSortSeq,
         T.AccountID,T.CompanyID,coalesce(T.PropertyID,''),Max(T.CompanyName),Max(coalesce(T.PropertyName,'')),
         T.PrimaryFamily,
         (case when T.DetailInternalRecordIndicator = 1 then Max(T.PrimaryProductName) 
               when T.DetailInternalRecordIndicator = 2 then Max(T.PrimaryProductName)  + ' with Invalid Product(s)'
          end)  as DuplicateFoundOnProductName,
         (Case when count(distinct T.PrimaryOrderitemID) = 1 then 2 ---> This is counting primary and conflict
               else count(distinct T.PrimaryOrderitemID)
          end) as DuplicateCount,
         '' as ProductCode,'' as OrderID,'' as OrderItemID,'' as OrderGroupID,'' as CustomBundleFlag,'' as CustomBundleName,'' as DetailProductName,
         '' as ChargeTypeCode,'' as MeasureCode,'' as FrequencyCode,'' as ContractStartdate,'' as ContractEndDate,'' as LastBilledFrom,'' as LastBilledTo,
         (case when T.DetailInternalRecordIndicator = 1 then 'Same Products for the account with Overlapping Start and Enddate'
               when T.DetailInternalRecordIndicator = 2 then 'Invalid Product(s) combination for the account with Overlapping Start and Enddate'
          end)  as ReportComments
  from  #TempHoldingTable T with (nolock)
  group by T.DetailInternalRecordIndicator,T.PrimaryProductCode,T.AccountID,T.CompanyID,coalesce(T.PropertyID,''),
           T.PrimaryFamily
  
  ---------------------------------------------------------------
  ---Populate Detail Records
  ---------------------------------------------------------------
  ---Primary
  Insert into #LT_DuplicateOrders(InternalRecordIndicator,DetailInternalRecordIndicator,IdentifierProductCode,IdentifierProductName,ConflictSortSeq,
                                  AccountID,CompanyID,PropertyID,CompanyName,PropertyName,
                                  FamilyName,DuplicateFoundOnProductName,DuplicateCount,
                                  ProductCode,OrderID,OrderItemID,OrderGroupID,CustomBundleFlag,CustomBundleName,DetailProductName,
                                  ChargeTypeCode,MeasureCode,FrequencyCode,ContractStartdate,ContractEndDate,LastBilledFrom,LastBilledTo,
                                  ReportComments)
  select distinct
         1000 as InternalRecordIndicator,T.DetailInternalRecordIndicator,T.PrimaryProductCode as IdentifierProductCode,T.PrimaryProductName as IdentifierProductName,2 as ConflictSortSeq,
         T.AccountID,T.CompanyID,coalesce(T.PropertyID,''),T.CompanyName,coalesce(T.PropertyName,''),
         T.PrimaryFamily as FamilyName,
         ''  as DuplicateFoundOnProductName,
         '' as DuplicateCount,
         T.PrimaryProductCode as ProductCode,T.PrimaryOrderID as OrderID,T.PrimaryOrderitemID as OrderItemID,T.PrimaryOrderGroupID as OrderGroupID,
         (Case when T.PrimaryCustomBundleFlag = 1 then 'YES' else 'NO' end) as CustomBundleFlag,
         (Case when T.PrimaryCustomBundleFlag = 1 then T.PrimaryCustomBundleName else '' end) as CustomBundleName,
         T.PrimaryProductName as DetailProductName,
         T.PrimaryChargeTypeCode as ChargeTypeCode,T.PrimaryMeasureCode as MeasureCode,T.PrimaryFrequencyCode as FrequencyCode,
         Convert(varchar(50),T.PrimaryStartDate,101) as ContractStartdate, Convert(varchar(50),T.PrimaryEndDate,101) as ContractEndDate,
         Convert(varchar(50),T.PrimaryLastBilledFrom,101) as LastBilledFrom,Convert(varchar(50),T.PrimaryLastBilledTo,101) as LastBilledTo,
         (Case when T.PrimaryCustomBundleFlag = 1 then 'Part of Custom Bundle' else 'Alcarte Product' end)  as ReportComments
  from  #TempHoldingTable T with (nolock)
  ---------------------------------------------------------------
  ---Conflict
  Insert into #LT_DuplicateOrders(InternalRecordIndicator,DetailInternalRecordIndicator,IdentifierProductCode,IdentifierProductName,ConflictSortSeq,
                                  AccountID,CompanyID,PropertyID,CompanyName,PropertyName,
                                  FamilyName,DuplicateFoundOnProductName,DuplicateCount,
                                  ProductCode,OrderID,OrderItemID,OrderGroupID,CustomBundleFlag,CustomBundleName,DetailProductName,
                                  ChargeTypeCode,MeasureCode,FrequencyCode,ContractStartdate,ContractEndDate,LastBilledFrom,LastBilledTo,
                                  ReportComments)
  select distinct 
         2000 as InternalRecordIndicator,T.DetailInternalRecordIndicator,T.PrimaryProductCode as IdentifierProductCode,T.PrimaryProductName as IdentifierProductName,3 as ConflictSortSeq,
         T.AccountID,T.CompanyID,coalesce(T.PropertyID,''),T.CompanyName,coalesce(T.PropertyName,''),
         T.ConflictFamily as FamilyName,
         ''  as DuplicateFoundOnProductName,
         ''  as DuplicateCount,
         T.ConflictProductCode as ProductCode,T.ConflictOrderID as OrderID,T.ConflictOrderitemID as OrderItemID,T.ConflictOrderGroupID as OrderGroupID,
         (Case when T.ConflictCustomBundleFlag = 1 then 'YES' else 'NO' end) as CustomBundleFlag,
         (Case when T.ConflictCustomBundleFlag = 1 then T.ConflictCustomBundleName else '' end) as CustomBundleName,
         T.ConflictProductName as DetailProductName,
         T.ConflictChargeTypeCode as ChargeTypeCode,T.ConflictMeasureCode as MeasureCode,T.ConflictFrequencyCode as FrequencyCode,
         Convert(varchar(50),T.ConflictStartDate,101) as ContractStartdate, Convert(varchar(50),T.ConflictEndDate,101) as ContractEndDate,
         Convert(varchar(50),T.ConflictLastBilledFrom,101) as LastBilledFrom,Convert(varchar(50),T.ConflictLastBilledTo,101) as LastBilledTo,
         (Case when T.ConflictCustomBundleFlag = 1 then 'Part of Custom Bundle' else 'Alcarte Product' end)  as ReportComments
  from  #TempHoldingTable T with (nolock)
  where not exists (select top 1 1
                    from   #LT_DuplicateOrders X with (nolock)
                    where  X.AccountID = T.AccountID
                    and    X.IdentifierProductCode = T.PrimaryProductCode
                    and    X.DetailInternalRecordIndicator = T.DetailInternalRecordIndicator
                    and    X.OrderID = T.ConflictOrderID
                    and    X.OrderGroupID = T.ConflictOrderGroupID
                    and    X.OrderItemID  = T.ConflictOrderItemID
                   )
  ---------------------------------------------------------------
  ---Final select to UI 
  ---------------------------------------------------------------
  select  CompanyID,CompanyName,PropertyID,PropertyName,AccountID, 
          FamilyName,DuplicateFoundOnProductName,DuplicateCount,
          ProductCode,OrderID,OrderItemID,OrderGroupID,CustomBundleFlag,CustomBundleName,DetailProductName,
          ChargeTypeCode,MeasureCode,FrequencyCode,ContractStartdate,ContractEndDate,LastBilledFrom,LastBilledTo,
          ReportComments
  from  #LT_DuplicateOrders with (nolock)
  order by CompanyName asc,PropertyName asc,IdentifierProductName asc,
           InternalRecordIndicator asc,DetailInternalRecordIndicator asc,ConflictSortSeq asc
  ---------------------------------------------------------------
END
GO
