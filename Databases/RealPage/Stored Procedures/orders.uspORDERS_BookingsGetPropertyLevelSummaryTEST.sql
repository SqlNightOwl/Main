SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_BookingsGetPropertyLevelSummaryTEST
-- Description     : This procedure gets Property Level Summary of Bookings Number for the 
--                    passed FROM and TO dates for all Quotes that have turned into approved Orders.

-- Input Parameters: 1. @IPVC_FromDate varchar(50)
--                   2. @IPVC_ToDate   varchar(50)
--                   3. @IPVC_CompanyID    varchar(50)  = ''
--                   4. @IPVC_CompanyName  varchar(255) = ''
--                   5. @IPVC_PropertyID   varchar(50)  = ''
--                   6. @IPVC_PropertyName varchar(255) = ''
--                   
--                   
-- OUTPUT          : The recordset for Report
--
-- Code Example    : Exec ORDERS.DBO.uspORDERS_BookingsGetPropertyLevelSummaryTEST 
--                        @IPVC_FromDate = '04/01/2007',@IPVC_ToDate = '04/30/2007'
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 04/26/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_BookingsGetPropertyLevelSummaryTEST](@IPVC_FromDate     varchar(50),
                                                           @IPVC_ToDate       varchar(50),
                                                           @IPVC_CompanyID    varchar(50)  = '',
                                                           @IPVC_CompanyName  varchar(255) = '',
                                                           @IPVC_PropertyID   varchar(50)  = '',
                                                           @IPVC_PropertyName varchar(255) = ''
                                                          )

AS
BEGIN 
  set nocount on
  ------------------------------------------------------------------------------------------------------
  --declaring Local Variable
  declare @LT_PaymentsBillingsMultiplier   decimal(15,5)
  declare @LT_ExlcudedPMCs TABLE (CompanyIDSeq   varchar(50))

  select @LT_PaymentsBillingsMultiplier = 1.75

  Insert into @LT_ExlcudedPMCs(CompanyIDSeq) select 'C0000000924' -- Exlcude C0000000924 LYND COMPANY
  Insert into @LT_ExlcudedPMCs(CompanyIDSeq) 
  select IDSeq from Customers.dbo.Company where (Name like '%TEST%' or Name like '%SAMPLE%')
  ------------------------------------------------------------------------------------------------------
  create table #TEMPLT_QuoteSalesAgent (QuoteID           varchar(50),
                                    SalesAgentName1   varchar(255),
                                    SalesAgentName2   varchar(255),
                                    SalesAgentName3   varchar(255)
                                   )

  create table #TEMPLT_OrdersToConsider (OrderIDSeq       varchar(50),
                                     QuoteIDSeq       varchar(50),                                     
                                     ApprovedDate     varchar(50),
                                     OrderLastModifiedby     varchar(50),
                                     OrderLastModifiedDate   varchar(50),
                                     AccountID        varchar(50),
                                     PMCID            varchar(50),
                                     CompanyID        varchar(50),
                                     CompanyName      varchar(255),
                                     SiteID           varchar(50),
                                     PropertyID       varchar(50),
                                     PropertyName     varchar(255),
                                     sites            int not null default 0,
                                     units            int not null default 0,
                                     PPUPercentage    int not null default 100
                                    )
                                      
  create table #TEMPLT_QuoteTotal     (QuoteIDSeq              varchar(50),
                                   NetExtYear1ChargeAmount money
                                  )


  create table #TEMPLT_HoldingTable    (QuoteIDSeq              varchar(50),
                                    OrderIDSeq              varchar(50),                                                               
                                    OrderGroupIDSeq         bigint,                                   
                                    ProductCode             varchar(100),
                                    ProductDisplayName      varchar(255),
                                    FamilyCode              varchar(20),
                                    FamilyName              varchar(50),
                                    CategoryCode            varchar(20),
                                    CategoryName            varchar(50),
                                    CapMaxUnitsFlag         int not null     default 0,
                                    QuantityEnabledFlag     int not null     default 0,
                                    CappedUnits             bigint not null  default 0,                                                                                                         
                                    FrequencyCode           varchar(20),                                    
                                    ILFMeasureCode          varchar(20),
                                    ILFActualNetAmount      numeric(30,3),
                                    AccessMeasureCode       varchar(20), 
                                    AccessActualNetAmount   numeric(30,3),
                                    ILFUnitPrice            numeric(30,3),
                                    AccessUnitPrice         numeric(30,3),
                                    ILFUnitOfMeasure        numeric(30,5),
                                    AccessUnitOfMeasure     numeric(30,5)             
                                   )

  create table #TEMPLT_BookingsReport  (seq                   bigint not null identity(1,1),
                                    QuoteID               varchar(50), 
                                    QuoteDescription      varchar(500),
                                    OrderID               varchar(50),   
                                    LineNumber            bigint     not null default 1,
                                    QuoteIDLineNumber     as QuoteID + '-' + convert(varchar(50),LineNumber)+'B',  
                                    TranType              varchar(50) Not null default 'Booking',                                    
                                    ApprovedMonth         as convert(varchar(50),year(ApprovedDate)) + '-'+ 
                                                             convert(varchar(50),Month(ApprovedDate)), 
                                    ActivationException   varchar(50) NULL,                             
                                    ApprovedDate          varchar(50),
                                    QuotaPeriod           as convert(varchar(50),year(ApprovedDate)) + '-'+ 
                                                             (case when convert(varchar(50),Month(ApprovedDate)) in ('1','2','3')    then 'Q1'
                                                                  when convert(varchar(50),Month(ApprovedDate))  in ('4','5','6')    then 'Q2'
                                                                  when convert(varchar(50),Month(ApprovedDate))  in ('7','8','9')    then 'Q3'
                                                                  when convert(varchar(50),Month(ApprovedDate))  in ('10','11','12') then 'Q4'
                                                              end),
                                                             
                                    
                                    PMCID                 varchar(50),
                                    CompanyID             varchar(50),
                                    CompanyName           varchar(255),
                                    SiteID                varchar(50),
                                    PropertyID            varchar(50),
                                    PropertyName          varchar(255),
                                    ProductCode           varchar(100),
                                    ProductDisplayName    varchar(255),                                    
                                    FamilyName            varchar(50),                                    
                                    CategoryName          varchar(50),
                                    Sites                 int not null default 0,
                                    Units                 int not null default 0,
                                    PPUPercentage         int not null default 100,                                                                        
                                    FrequencyName         varchar(50),
                                    ILFMeasureCode        varchar(20),
                                    ILFActualNetAmount    numeric(30,3),
                                    ILFAdjustedNetAmount  numeric(30,3),
                                    AccessMeasureCode     varchar(20), 
                                    AccessActualNetAmount numeric(30,3),
                                    AccessAdjustedNetAmount numeric(30,3),
                                    NetGrossActualAmount    as (ILFActualNetAmount+AccessActualNetAmount),                                    
                                    NetGrossAdjustedAmountDisplay  numeric(30,3),
                                    ILFUnitPrice            numeric(30,3),
                                    AccessUnitPrice         numeric(30,3),                                      
                                    OrderTotal              varchar(100)  NULL,
                                    OrderLastModifiedby     varchar(50),
                                    OrderLastModifiedDate   varchar(50),
                                    SalesAgentName1         varchar(255),
                                    SalesAgentName2         varchar(255),
                                    SalesAgentName3         varchar(255)
                                   )

  ------------------------------------------------------------------------------------------------------
  select @IPVC_FromDate = convert(datetime,@IPVC_FromDate)
  select @IPVC_ToDate   = convert(datetime,@IPVC_ToDate)
  ------------------------------------------------------------------------------------------------------
  Insert into #TEMPLT_OrdersToConsider(OrderIDSeq,QuoteIDSeq,AccountID,ApprovedDate,
                                   OrderLastModifiedby,OrderLastModifiedDate,
                                   PMCID,CompanyID,CompanyName,SiteID,PropertyID,PropertyName,
                                   Sites,Units,PPUPercentage)
  select distinct O.OrderIDSeq,O.QuoteIDSeq,O.AccountIDSeq,
                  Convert(varchar(50),O.ApprovedDate,101)       as ApprovedDate,
                  coalesce(Q.ModifiedBy,O.ModifiedBy,Q.Createdby,O.CreatedBy,O.ApprovedBy)       
                                                                as OrderLastModifiedby,
                  Convert(varchar(50),coalesce(Q.ModifiedDate,O.ModifiedDate,Q.CreateDate,O.CreatedDate,O.ApprovedDate),101) 
                                                                as OrderLastModifiedDate,
                  COM.SiteMasterID                              as PMCID,
                  O.CompanyIDSeq                                as CompanyID,
                  COM.Name                                      as CompanyName,
                  PRP.SiteMasterID                              as SiteID,
                  O.PropertyIDSeq                               as PropertyID,
                  PRP.Name                                      as PropertyName,
                  (case when O.PropertyIDSeq is not null then 1 else 0 end ) as Sites,
                  Coalesce(PRP.units,0)                         as units, 
                  Coalesce(PRP.PPUPercentage,0)                 as PPUPercentage
  from       ORDERS.dbo.[ORDER] O with (nolock)
  inner join CUSTOMERS.dbo.Company COM with (nolock)
         on    COM.IDSeq = O.CompanyIDSeq
         and   O.CompanyIDSeq   not in (select CompanyIDSeq from @LT_ExlcudedPMCs)
         and   Coalesce(COM.IDSeq,'')     like '%'+ @IPVC_CompanyID   + '%'
         and   Coalesce(COM.Name,'')      like '%'+ @IPVC_CompanyName + '%'
         and   O.statuscode     = 'APPR'
         and   convert(datetime,convert(varchar(50),O.ApprovedDate,101))   >= @IPVC_FromDate
         and   convert(datetime,convert(varchar(50),O.ApprovedDate,101))   <= @IPVC_ToDate
  Left outer join
               CUSTOMERS.dbo.Property PRP with (nolock)
         on    O.PropertyIDSeq = PRP.IDSeq       
         and   Coalesce(PRP.IDSeq,'')     like '%'+ @IPVC_PropertyID   + '%'
         and   Coalesce(PRP.Name,'')      like '%'+ @IPVC_PropertyName + '%' 
  left outer join
               QUOTES.dbo.Quote Q with (nolock)
         on    coalesce(O.Quoteidseq,'') = Q.Quoteidseq
  where O.CompanyIDSeq   not in (select CompanyIDSeq from @LT_ExlcudedPMCs)
         and   Coalesce(COM.IDSeq,'')     like '%'+ @IPVC_CompanyID   + '%'
         and   Coalesce(COM.Name,'')      like '%'+ @IPVC_CompanyName + '%'
         and   Coalesce(PRP.IDSeq,'')     like '%'+ @IPVC_PropertyID   + '%'
         and   Coalesce(PRP.Name,'')      like '%'+ @IPVC_PropertyName + '%'  
  ------------------------------------------------------------------------------------------------------
  Insert into #TEMPLT_QuoteTotal(QuoteIDSeq,NetExtYear1ChargeAmount)
  select S.QuoteIDSeq,sum(S.NetExtYear1ChargeAmount)
  from
      (
       select QI.QuoteIDSeq,sum(QI.NetExtYear1ChargeAmount) as NetExtYear1ChargeAmount
       from   Quotes.dbo.QuoteItem QI With (nolock)
       where  exists (select top 1 1 
                      from #TEMPLT_OrdersToConsider A
                      where QI.QuoteIDSeq = A.Quoteidseq
                     )
       and  QI.GroupIDseq not in (select X.IDSeq
                                  from   Quotes.dbo.[Group] X with (nolock)
                                  where  X.QuoteIDSeq      = QI.QuoteIDSeq
                                  and    X.TransferredFlag = 1
                                  )
       group by QI.QuoteIDSeq
       ------------------------
       UNION
       ------------------------
       select QI.QuoteIDSeq,sum(QI.NetExtYear1ChargeAmount) as NetExtYear1ChargeAmount
       from   Quotes.dbo.QuoteItem QI With (nolock)
       where  exists (select top 1 1 
                      from #TEMPLT_OrdersToConsider A
                      where QI.QuoteIDSeq = A.Quoteidseq
                     )
       and  QI.GroupIDseq  in (select X.GroupIDseq
                               from   Quotes.dbo.QuoteItem X with (nolock)
                               where  X.QuoteIDSeq = QI.QuoteIDSeq
                               and    X.productcode='DMD-PSR-ADM-ADM-AMTF'
                               )        
       and  QI.productcode='DMD-PSR-ADM-ADM-AMTF'
       group by QI.QuoteIDSeq
       ------------------------
       UNION
       ------------------------       
       select QI.QuoteIDSeq,sum(QI.NetExtYear1ChargeAmount) as NetExtYear1ChargeAmount
       from   Quotes.dbo.QuoteItem QI With (nolock)
       inner join
              PRODUCTS.dbo.Product P with (nolock)
       on      QI.productcode   = P.code
       and     QI.PriceVersion  = P.PriceVersion
       and exists (select top 1 1 
                   from #TEMPLT_OrdersToConsider A
                   where QI.QuoteIDSeq = A.Quoteidseq
                   )
       and  QI.GroupIDseq  in (select X.IDSeq
                               from   Quotes.dbo.[Group] X with (nolock)
                               where  X.QuoteIDSeq      = QI.QuoteIDSeq
                               and    X.TransferredFlag = 1
                               )
       and  QI.productcode<>'DMD-PSR-ADM-ADM-AMTF'
       and    (P.Categorycode = 'SCR' OR
               QI.productcode in (select Y.ProductCode 
                                  from   Quotes.dbo.QuoteItem Y with (nolock)
                                  where  Y.QuoteIDSeq      = QI.QuoteIDSeq
                                  and    Y.GroupIDseq      = QI.GroupIDseq
                                  and    (Y.Chargetypecode = 'ILF' and Y.NetExtYear1ChargeAmount > 0)
                                  )
               
               )
       group by QI.QuoteIDSeq 
      ) S
   group by S.QuoteIDSeq
  ------------------------------------------------------------------------------------------------------
  Insert into #TEMPLT_QuoteSalesAgent(QuoteID,SalesAgentName1,SalesAgentName2,SalesAgentName3)
  select S.QUOTEIDSeq, 
       S.SalesAgentName1,
       NULLIF(S.SalesAgentName2,S.SalesAgentName1)   as  SalesAgentName2,
       NULLIF(S.SalesAgentName3,S.SalesAgentName2)   as  SalesAgentName3     
  FROM
     (select QuoteIDSeq,
              (Select Top 1 X.SalesAgentName from QUOTES.dbo.QuoteSaleAgent X with (nolock) 
               where X.QUOTEIDSEQ = QSA.QUOTEIDSEQ
               and X.IDSEQ = MIN(QSA.IDSEQ) 
              )  as SalesAgentName1,
             (Select Top 1 X.SalesAgentName from QUOTES.dbo.QuoteSaleAgent X with (nolock) 
              where X.QUOTEIDSEQ = QSA.QUOTEIDSEQ
              and X.IDSEQ > MIN(QSA.IDSEQ) and X.IDSEQ <= MAX(QSA.IDSEQ)
             ) as SalesAgentName2,    
             case when MIN(QSA.IDSEQ) = MAX(QSA.IDSEQ) then NULL
                  else (Select Top 1 X.SalesAgentName from QUOTES.dbo.QuoteSaleAgent X with (nolock) 
                        where X.QUOTEIDSEQ = QSA.QUOTEIDSEQ
                        and  X.IDSEQ = MAX(QSA.IDSEQ)
                       )
             end  as SalesAgentName3 
      from QUOTES.dbo.QuoteSaleAgent QSA with (nolock) 
      where Exists (select Top 1 1
                    from  ORDERS.dbo.[ORDER] O with (nolock)
                    inner join
                    QUOTES.dbo.Quote   Q with (nolock)
                    on    O.QuoteIDSeq     = Q.QuoteIDSeq
                    and   O.QuoteIDSeq     = QSA.QuoteIDSeq
                    and   O.CompanyIDSeq   = Q.CustomerIDSeq
                    and   O.CompanyIDSeq   not in (select CompanyIDSeq from @LT_ExlcudedPMCs)
                    and   Q.QuoteStatusCode= 'APR'
                    and   O.statuscode     = 'APPR'
                    and   convert(datetime,convert(varchar(50),O.ApprovedDate,101))   >= @IPVC_FromDate
                    and   convert(datetime,convert(varchar(50),O.ApprovedDate,101))   <= @IPVC_ToDate
                   )
      group by QSA.QuoteIDSeq
     ) S
  ------------------------------------------------------------------------------------------------------
  insert into #TEMPLT_HoldingTable(QuoteIDSeq,OrderIDSeq,OrderGroupIDSeq,ProductCode,ProductDisplayName,
                               FamilyCode,FamilyName,CategoryCode,CategoryName,
                               CapMaxUnitsFlag,QuantityEnabledFlag,CappedUnits,
                               FrequencyCode,ILFMeasureCode,ILFActualNetAmount,
                               AccessMeasureCode,AccessActualNetAmount,ILFUnitPrice,AccessUnitPrice,
                               ILFUnitOfMeasure,AccessUnitOfMeasure)
  select   OTC.QuoteIDSeq,
           OI.OrderIDSeq,
           OI.OrderGroupIDSeq,
           OI.ProductCode                                 as ProductCode,           
           P.DisplayName                                  as ProductDisplayName,
           P.FamilyCode                                   as FamilyCode,
           F.Name                                         as FamilyName,
           P.CategoryCode                                 as CategoryCode,
           CT.Name                                        as CategoryName,
           MAX(convert(int,OI.CapMaxUnitsFlag))           as CapMaxUnitsFlag,
           MAX(convert(int,C.QuantityEnabledFlag))        as QuantityEnabledFlag,
           coalesce(max(OI.MaxUnits),max(C.MaxUnits),500) as CappedUnits,
           COALESCE(MAX(case when OI.chargetypecode = 'ACS' then OI.FrequencyCode else NULL end),
                    MAX(case when OI.chargetypecode = 'ILF' then OI.FrequencyCode else NULL end)
                   )                                                                         as FrequencyCode,
           MAX(case when OI.chargetypecode = 'ILF' then OI.MeasureCode else NULL end)        as ILFMeasureCode,
           SUM(case OI.ChargetypeCode when 'ILF' then OI.NetExtYear1ChargeAmount Else 0 END) as ILFActualNetAmount,
           MAX(case when OI.chargetypecode = 'ACS' then OI.MeasureCode else NULL end)        as AccessMeasureCode,
           SUM(case OI.ChargetypeCode when 'ACS' then OI.NetExtYear1ChargeAmount Else 0 END) as AccessActualNetAmount,
           SUM(case OI.ChargetypeCode when 'ILF' then OI.NetChargeAmount Else 0 END)         as ILFUnitPrice,
           SUM(case OI.ChargetypeCode when 'ACS' then OI.NetChargeAmount Else 0 END)         as AccessUnitPrice,
           SUM(case OI.ChargetypeCode when 'ILF' then OI.UnitOfMeasure Else 0 END)           as ILFUnitOfMeasure,
           SUM(case OI.ChargetypeCode when 'ACS' then OI.UnitOfMeasure Else 0 END)           as AccessUnitOfMeasure
  from   ORDERS.dbo.OrderItem OI with (nolock)    
  inner join #TEMPLT_OrdersToConsider  OTC 
  on    OI.OrderIDSeq = OTC.OrderIDSeq        
        ------------------------------------ 
         --Exclude all products that are  in the OrderGroup that 
         --  has TransferredFlag = 1   
         and  OI.OrderGroupIDseq not in (select X.IDSeq
                                         from   ORDERS.dbo.[OrderGroup] X with (nolock)
                                         where  X.OrderIDSeq      = OI.OrderIDSeq
                                         and    X.TransferredFlag = 1
                                        ) 
         ------------------------------------
  inner join
          PRODUCTS.dbo.Product P with (nolock)
  on      OI.productcode   = P.code
  and     OI.PriceVersion  = P.PriceVersion    
  inner join
          PRODUCTS.dbo.Charge C with (nolock)
  on      OI.productcode   = C.productcode
  and     OI.PriceVersion  = C.PriceVersion
  and     P.code           = C.productcode
  and     P.PriceVersion   = C.PriceVersion
  and     OI.Chargetypecode= C.Chargetypecode
  and     OI.MeasureCode   = C.MeasureCode
  and     OI.Frequencycode = C.FrequencyCode
  inner join
          PRODUCTS.dbo.Family F with (nolock)
  on      P.FamilyCode = F.Code
  inner join
          PRODUCTS.dbo.Category CT with (nolock)
  on      P.CategoryCode = CT.Code
  group by OTC.QuoteIDSeq,OI.OrderIDSeq,OI.OrderGroupIDSeq,OI.ProductCode,P.DisplayName,P.FamilyCode,
           F.Name,P.CategoryCode,CT.Name
  -----------------------------------------------------------------------------------------
  UNION
  -----------------------------------------------------------------------------------------
  select   OTC.QuoteIDSeq,
           OI.OrderIDSeq,
           OI.OrderGroupIDSeq,
           OI.ProductCode                                 as ProductCode,           
           P.DisplayName                                  as ProductDisplayName,
           P.FamilyCode                                   as FamilyCode,
           F.Name                                         as FamilyName,
           P.CategoryCode                                 as CategoryCode,
           CT.Name                                        as CategoryName,
           MAX(convert(int,OI.CapMaxUnitsFlag))           as CapMaxUnitsFlag,
           MAX(convert(int,C.QuantityEnabledFlag))        as QuantityEnabledFlag,
           coalesce(max(OI.MaxUnits),max(C.MaxUnits),500) as CappedUnits,
           COALESCE(MAX(case when OI.chargetypecode = 'ACS' then OI.FrequencyCode else NULL end),
                    MAX(case when OI.chargetypecode = 'ILF' then OI.FrequencyCode else NULL end)
                   )                                                                         as FrequencyCode,
           MAX(case when OI.chargetypecode = 'ILF' then OI.MeasureCode else NULL end)        as ILFMeasureCode,
           SUM(case OI.ChargetypeCode when 'ILF' then OI.NetExtYear1ChargeAmount Else 0 END) as ILFActualNetAmount,
           MAX(case when OI.chargetypecode = 'ACS' then OI.MeasureCode else NULL end)        as ACSMeasureCode,
           SUM(case OI.ChargetypeCode when 'ACS' then OI.NetExtYear1ChargeAmount Else 0 END) as ACSActualNetAmount,
           SUM(case OI.ChargetypeCode when 'ILF' then OI.NetChargeAmount Else 0 END)         as ILFUnitPrice,
           SUM(case OI.ChargetypeCode when 'ACS' then OI.NetChargeAmount Else 0 END)         as AccessUnitPrice,
           SUM(case OI.ChargetypeCode when 'ILF' then OI.UnitOfMeasure Else 0 END)           as ILFUnitOfMeasure,
           SUM(case OI.ChargetypeCode when 'ACS' then OI.UnitOfMeasure Else 0 END)           as AccessUnitOfMeasure
  from   ORDERS.dbo.OrderItem OI with (nolock) 
  inner join #TEMPLT_OrdersToConsider  OTC 
  on     OI.OrderIDSeq = OTC.OrderIDSeq        
         ------------------------------------ 
         --Include Groups that has  ONLY Management/Owner Transfer Fee
         --1. Include Product Management/Owner Transfer Fee         
         and OI.OrderGroupIDseq  in (select X.OrderGroupIDseq
                                     from   ORDERS.dbo.orderitem X with (nolock)
                                     where  X.OrderIDSeq = OI.OrderIDSeq
                                     and    X.productcode='DMD-PSR-ADM-ADM-AMTF' 
                                     )       
         and OI.productcode='DMD-PSR-ADM-ADM-AMTF' 
         ------------------------------------
  inner join
          PRODUCTS.dbo.Product P with (nolock)
  on      OI.productcode   = P.code
  and     OI.PriceVersion  = P.PriceVersion  
  inner join
          PRODUCTS.dbo.Charge C with (nolock)
  on      OI.productcode   = C.productcode
  and     OI.PriceVersion  = C.PriceVersion
  and     P.code           = C.productcode
  and     P.PriceVersion   = C.PriceVersion
  and     OI.Chargetypecode= C.Chargetypecode
  and     OI.MeasureCode   = C.MeasureCode
  and     OI.Frequencycode = C.FrequencyCode
  inner join
          PRODUCTS.dbo.Family F with (nolock)
  on      P.FamilyCode = F.Code
  inner join
          PRODUCTS.dbo.Category CT with (nolock)
  on      P.CategoryCode = CT.Code
  group by OTC.QuoteIDSeq,OI.OrderIDSeq,OI.OrderGroupIDSeq,OI.ProductCode,P.DisplayName,P.FamilyCode,
           F.Name,P.CategoryCode,CT.Name
  -----------------------------------------------------------------------------------------
  UNION
  -----------------------------------------------------------------------------------------
  select   OTC.QuoteIDSeq,
           OI.OrderIDSeq,
           OI.OrderGroupIDSeq,
           OI.ProductCode                                 as ProductCode,           
           P.DisplayName                                  as ProductDisplayName,
           P.FamilyCode                                   as FamilyCode,
           F.Name                                         as FamilyName,
           P.CategoryCode                                 as CategoryCode,
           CT.Name                                        as CategoryName,
           MAX(convert(int,OI.CapMaxUnitsFlag))           as CapMaxUnitsFlag,
           MAX(convert(int,C.QuantityEnabledFlag))        as QuantityEnabledFlag,
           coalesce(max(OI.MaxUnits),max(C.MaxUnits),500) as CappedUnits,
           COALESCE(MAX(case when OI.chargetypecode = 'ACS' then OI.FrequencyCode else NULL end),
                    MAX(case when OI.chargetypecode = 'ILF' then OI.FrequencyCode else NULL end)
                   )                                                                         as FrequencyCode,
           MAX(case when OI.chargetypecode = 'ILF' then OI.MeasureCode else NULL end)        as ILFMeasureCode,
           SUM(case OI.ChargetypeCode when 'ILF' then OI.NetExtYear1ChargeAmount Else 0 END) as ILFActualNetAmount,
           MAX(case when OI.chargetypecode = 'ACS' then OI.MeasureCode else NULL end)        as ACSMeasureCode,
           SUM(case OI.ChargetypeCode when 'ACS' then OI.NetExtYear1ChargeAmount Else 0 END) as ACSActualNetAmount,
           SUM(case OI.ChargetypeCode when 'ILF' then OI.NetChargeAmount Else 0 END)         as ILFUnitPrice,
           SUM(case OI.ChargetypeCode when 'ACS' then OI.NetChargeAmount Else 0 END)         as AccessUnitPrice,
           SUM(case OI.ChargetypeCode when 'ILF' then OI.UnitOfMeasure Else 0 END)           as ILFUnitOfMeasure,
           SUM(case OI.ChargetypeCode when 'ACS' then OI.UnitOfMeasure Else 0 END)           as AccessUnitOfMeasure
  from   ORDERS.dbo.OrderItem OI with (nolock) 
  inner join #TEMPLT_OrdersToConsider  OTC 
  on     OI.OrderIDSeq = OTC.OrderIDSeq        
         ------------------------------------ 
         --Include all products that are  in the OrderGroup that 
         --  has TransferredFlag = 1 and satisfy the following         
         --2. All Screening Products in the group that has Product Management/Owner Transfer Fee
         --3. All Products that have only NetExtYear1ChargeAmount > 0 in the group that has Product Management/Owner Transfer Fee
         and  OI.OrderGroupIDseq  in (select X.IDSeq
                                      from   ORDERS.dbo.[OrderGroup] X with (nolock)
                                      where  X.OrderIDSeq      = OI.OrderIDSeq
                                      and    X.TransferredFlag = 1
                                     )
         and OI.productcode<>'DMD-PSR-ADM-ADM-AMTF'      
         ------------------------------------
  inner join
          PRODUCTS.dbo.Product P with (nolock)
  on      OI.productcode   = P.code
  and     OI.PriceVersion  = P.PriceVersion
  and    (P.Categorycode = 'SCR' OR
          OI.productcode in (select Y.ProductCode 
                            from   ORDERS.dbo.orderitem Y with (nolock)
                            where  Y.OrderIDSeq      = OI.OrderIDSeq
                            and    Y.OrderGroupIDseq = OI.OrderGroupIDseq
                            and    (Y.Chargetypecode = 'ILF' and Y.NetExtYear1ChargeAmount > 0)        
                            )
           
               )
  inner join
          PRODUCTS.dbo.Charge C with (nolock)
  on      OI.productcode   = C.productcode
  and     OI.PriceVersion  = C.PriceVersion
  and     P.code           = C.productcode
  and     P.PriceVersion   = C.PriceVersion
  and     OI.Chargetypecode= C.Chargetypecode
  and     OI.MeasureCode   = C.MeasureCode
  and     OI.Frequencycode = C.FrequencyCode
  inner join
          PRODUCTS.dbo.Family F with (nolock)
  on      P.FamilyCode = F.Code
  inner join
          PRODUCTS.dbo.Category CT with (nolock)
  on      P.CategoryCode = CT.Code
  group by OTC.QuoteIDSeq,OI.OrderIDSeq,OI.OrderGroupIDSeq,OI.ProductCode,P.DisplayName,P.FamilyCode,
           F.Name,P.CategoryCode,CT.Name
  -----------------------------------------------------------------------------------------------
  Insert into #TEMPLT_BookingsReport(QuoteID,OrderID,ApprovedDate,OrderLastModifiedby,OrderLastModifiedDate,
                                 PMCID,CompanyID,CompanyName,SiteID,PropertyID,PropertyName,
                                 ProductCode,ProductDisplayName,FamilyName,CategoryName,
                                 Sites,Units,PPUPercentage,FrequencyName,
                                 ILFMeasureCode,ILFActualNetAmount,ILFAdjustedNetAmount,
                                 AccessMeasureCode,AccessActualNetAmount,AccessAdjustedNetAmount,
                                 NetGrossAdjustedAmountDisplay,ILFUnitPrice,AccessUnitPrice,LineNumber)
  select S.QuoteID,S.OrderID,S.ApprovedDate,S.OrderLastModifiedby,S.OrderLastModifiedDate,
                                 S.PMCID,S.CompanyID,S.CompanyName,S.SiteID,S.PropertyID,S.PropertyName,
                                 S.ProductCode,S.ProductDisplayName,S.FamilyName,S.CategoryName,
                                 S.Sites,S.Units,S.PPUPercentage,S.FrequencyName,
                                 S.ILFMeasureCode,S.ILFActualNetAmount,S.ILFAdjustedNetAmount,
                                 S.AccessMeasureCode,S.AccessActualNetAmount,S.AccessAdjustedNetAmount,
                                 S.NetGrossAdjustedAmountDisplay,S.ILFUnitPrice,S.AccessUnitPrice, 
         ROW_NUMBER() OVER (PARTITION BY  S.QuoteID
                             Order by S.ProductDisplayName ASC,
                                      S.CompanyName        ASC,
                                      S.PropertyName       ASC,
                                      Convert(varchar(50),S.ApprovedDate,101) ASC,S.QuoteID ASC) 
                                                       as LineNumber
  --------------------------------------------------------------
  from (select distinct A.QuoteIDSeq         as QuoteID, 
                        A.OrderIDSeq         as OrderID,
                        A.ApprovedDate       as ApprovedDate,
                        A.OrderLastModifiedby   as OrderLastModifiedby,
                        A.OrderLastModifiedDate as OrderLastModifiedDate,
                        A.PMCID              as PMCID,
                        A.CompanyID          as CompanyID,
                        A.CompanyName        as CompanyName,
                        A.SiteID             as SiteID,
                        A.PropertyID         as PropertyID,
                        A.PropertyName       as PropertyName,
                        B.ProductCode        as ProductCode,
                        B.ProductDisplayName as ProductDisplayName,
                        B.FamilyName         as FamilyName,
                        B.CategoryName       as CategoryName,
                        sum(A.Sites)         as Sites,
                        (case 
                           when MAX(B.CapMaxUnitsFlag) = 1      and
                                (Coalesce(sum(A.units),0) >= 
                                 coalesce(sum(B.CappedUnits),500)
                                )
                              then coalesce(sum(B.CappedUnits),500)
                           else Coalesce(sum(A.units),0)
                         end                                      
                        )                    as Units,
                        sum(A.PPUPercentage) as PPUPercentage,
                        F.Name               as FrequencyName,
                        -----------------------------------------------------
                        B.ILFMeasureCode                as ILFMeasureCode,
                        sum(B.ILFActualNetAmount)       as ILFActualNetAmount,
                        (case when (B.CategoryCode = 'SCR' and max(B.QuantityEnabledFlag)=1)
                                 then  sum(B.ILFActualNetAmount) * sum(A.units)
                              when (B.CategoryCode = 'PAY' and max(B.QuantityEnabledFlag)=0 and B.productcode <> 'DMD-OSD-PAY-PAY-POPY')
                                 then  sum(B.ILFActualNetAmount) + (sum(A.units)* @LT_PaymentsBillingsMultiplier)
                              else sum(B.ILFActualNetAmount)
                         end)                           as ILFAdjustedNetAmount,
                        -----------------------------------------------------
                        B.AccessMeasureCode             as AccessMeasureCode,
                        sum(B.AccessActualNetAmount)    as AccessActualNetAmount,
                        (case when (B.CategoryCode = 'SCR' and max(B.QuantityEnabledFlag)=1)
                                 then  sum(B.AccessActualNetAmount) * sum(A.units)
                              when (B.CategoryCode = 'PAY' and max(B.QuantityEnabledFlag)=0 and B.productcode <> 'DMD-OSD-PAY-PAY-POPY')
                                 then  sum(B.AccessActualNetAmount) + (sum(A.units)* @LT_PaymentsBillingsMultiplier)
                              else sum(B.AccessActualNetAmount)
                         end)                            as AccessAdjustedNetAmount,
                        -----------------------------------------------------
                        (case when (B.CategoryCode = 'SCR' and max(B.QuantityEnabledFlag)=1)
                                 then  0 --- For Screening with QuantityEnabledFlag display 0 as adjustedGross
                              when (B.CategoryCode = 'PAY' and max(B.QuantityEnabledFlag)=0 and B.productcode <> 'DMD-OSD-PAY-PAY-POPY')
                                 then  sum(B.ILFActualNetAmount) + (sum(A.units)* @LT_PaymentsBillingsMultiplier)
                              else sum(B.ILFActualNetAmount)
                         end)  +
                         (case when (B.CategoryCode = 'SCR' and max(B.QuantityEnabledFlag)=1)
                                 then  0 --- For Screening with QuantityEnabledFlag display 0 as adjustedGross
                              when (B.CategoryCode = 'PAY' and max(B.QuantityEnabledFlag)=0 and B.productcode <> 'DMD-OSD-PAY-PAY-POPY')
                                 then  sum(B.AccessActualNetAmount) + (sum(A.units)* @LT_PaymentsBillingsMultiplier)
                              else sum(B.AccessActualNetAmount)
                         end)                             as NetGrossAdjustedAmountDisplay,
                         --------------------------------------------------------------------
                         sum(B.ILFUnitPrice)/(Case when SUM(B.ILFUnitOfMeasure) =0 
                                                      then 1 else SUM(B.ILFUnitOfMeasure)
                                              end)              as ILFUnitPrice,
                         sum(B.AccessUnitPrice)/(Case when SUM(B.AccessUnitOfMeasure) =0 
                                                      then 1 else SUM(B.AccessUnitOfMeasure)
                                              end)              as AccessUnitPrice
        from #TEMPLT_OrdersToConsider A
        inner join
             #TEMPLT_HoldingTable B
        on   A.OrderIDSeq = B.OrderIDSeq
        inner join
             Products.dbo.Frequency F  with (nolock)
        on   B.FrequencyCode = F.Code
        group by A.QuoteIDSeq,A.OrderIDSeq,A.ApprovedDate,A.AccountID,A.PMCID,A.CompanyID,A.CompanyName,
                 A.SiteID,A.PropertyID,A.PropertyName,B.productcode,B.ProductDisplayName,B.FamilyCode,B.FamilyName,
                 B.CategoryCode,B.CategoryName,B.FrequencyCode,F.Name,B.ILFMeasureCode,B.AccessMeasureCode,
                 A.OrderLastModifiedby,A.OrderLastModifiedDate
        )S
  Order by S.CompanyName ASC,S.ProductDisplayName ASC,S.PropertyName ASC,
           Convert(varchar(50),S.ApprovedDate,101) ASC,S.QuoteID ASC
  ------------------------------------------------------------------------------------------------------------
  Update D 
  set    D.SalesAgentName1 = S.SalesAgentName1,
         D.SalesAgentName2 = S.SalesAgentName2,
         D.SalesAgentName3 = S.SalesAgentName3
  from   #TEMPLT_BookingsReport D inner join #TEMPLT_QuoteSalesAgent S
  on     D.QuoteID = S.QuoteID
  ------------------------------------------------------------------------------------------------------------
  Update D
  set    D.QuoteDescription = S.[Description]
  from   #TEMPLT_BookingsReport D 
  inner join
         Quotes.dbo.Quote S with (nolock)         
  on     D.QuoteID = S.QuoteIDSeq  
  ------------------------------------------------------------------------------------------------------------
  Update D
  set    D.OrderTotal       = S.NetExtYear1ChargeAmount
  from   #TEMPLT_BookingsReport D 
  inner join
         #TEMPLT_QuoteTotal S
  on     D.QuoteID = S.QuoteIDSeq  
  ------------------------------------------------------------------------------------------------------------ 
  ---Final Select  
  select 
         QuoteID                 as [Doc #],
         QuoteDescription        as [Doc Description], 
         LineNumber              as [Line #],
         QuoteIDLineNumber       as [O-L #],
         TranType                as [Tran Type],
         ApprovedMonth           as [Month],  
         ActivationException     as [Activation Exception],
         ApprovedDate            as [Booking Entry Date],
         QuotaPeriod             as [Quota Period],
         PMCID                   as [PMCID],
         CompanyID               as [CompanyID],
         CompanyName             as [PMC Name],
         SiteID                  as [SiteID],
         PropertyID              as [PropertyID],
         PropertyName            as [Site Name],
         ProductDisplayName      as [Product Name],
         FamilyName              as [Market],         
         CategoryName            as [Sub-Market],
         Sites                   as [Sites],        
         Units                   as [Units],
         PPUPercentage           as [PPUPercentage],         
         FrequencyName           as Period,
         ILFMeasureCode          as [ILF Base],
         ILFUnitPrice            as [ILF UnitPrice],  
         ILFAdjustedNetAmount    as [ILF Net Amount],
         AccessMeasureCode       as [Access Base],
         AccessUnitPrice         as [Access UnitPrice], 
         AccessAdjustedNetAmount as [Access Net Amount],         
         NetGrossAdjustedAmountDisplay  as [Gross Net Amount],
         OrderTotal              as [Order Total],
         OrderLastModifiedby     as [Order LastModifiedby],
         OrderLastModifiedDate   as [Order LastModifiedDate],
         SalesAgentName1         as [SalesAgentName1],
         SalesAgentName2         as [SalesAgentName2],
         SalesAgentName3         as [SalesAgentName3]
  from #TEMPLT_BookingsReport 
  Order by CompanyName ASC,ProductDisplayName ASC,PropertyName ASC
  ------------------------------------------------------------------------------------------------------------  
END

GO
