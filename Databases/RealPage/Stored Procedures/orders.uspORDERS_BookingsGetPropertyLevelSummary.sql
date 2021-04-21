SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_BookingsGetPropertyLevelSummary
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
-- Code Example    : Exec ORDERS.DBO.uspORDERS_BookingsGetPropertyLevelSummary 
--                        @IPVC_FromDate = '04/01/2007',@IPVC_ToDate = '04/30/2007'
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 04/26/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_BookingsGetPropertyLevelSummary](@IPVC_FromDate     varchar(50),
                                                           @IPVC_ToDate       varchar(50),
                                                           @IPVC_CompanyID    varchar(50)  = '',
                                                           @IPVC_CompanyName  varchar(255) = '',
                                                           @IPVC_PropertyID   varchar(50)  = '',
                                                           @IPVC_PropertyName varchar(255) = ''
                                                          )
AS
BEGIN 
  set nocount on;
  ------------------------------------------------------------------------------------------------------
  --declaring Local Variable
  declare @LT_PaymentsBillingsMultiplier   decimal(15,5)
  declare @LT_ExlcudedPMCs TABLE (CompanyIDSeq   varchar(50))

  select @LT_PaymentsBillingsMultiplier = 2.50

  ---Insert into @LT_ExlcudedPMCs(CompanyIDSeq) select 'C0000000924' -- Exlcude C0000000924 LYND COMPANY
  Insert into @LT_ExlcudedPMCs(CompanyIDSeq) 
  select IDSeq from Customers.dbo.Company with (nolock) where (Name like '%TEST%' or Name like '%SAMPLE%')

  select @IPVC_CompanyID = nullif(@IPVC_CompanyID,''),
         @IPVC_PropertyID= nullif(@IPVC_PropertyID,'')
  ------------------------------------------------------------------------------------------------------
  create table #TEMPLT_QuoteSalesAgent (QuoteIDSeq        varchar(50),
                                        SalesAgentName1   varchar(255),
                                        SalesAgentName2   varchar(255),
                                        SalesAgentName3   varchar(255)
                                        )

  create table #TEMPLT_OrdersToConsider 
                                    (OrderIDSeq              varchar(50),
                                     QuoteIDSeq              varchar(50), 
                                     QuoteTypecode           varchar(20),                                     
                                     ApprovedDate            varchar(50),
                                     OrderLastModifiedby     varchar(50),
                                     OrderLastModifiedDate   varchar(50),
                                     AccountID               varchar(50),
                                     PMCID                   varchar(50),
                                     CompanyID               varchar(50),
                                     CompanyName             varchar(255),
                                     SiteID                  varchar(50),
                                     PropertyID              varchar(50),
                                     PropertyName            varchar(255),
                                     StudentLivingFlag       int not null default 0,
                                     sites                   int not null default 0,
                                     units                   int not null default 0,
                                     beds                    int not null default 0,
                                     PPUPercentage           int not null default 100
                                    )
                                      
  create table #TEMPLT_QuoteTotal     (QuoteIDSeq              varchar(50),
                                       NetExtYear1ChargeAmount numeric(30,2)
                                      )  

  create table #TEMPLT_BookingsReport 
                                   (seq                   bigint not null identity(1,1),
                                    QuoteIDSeq            varchar(50), 
                                    QuoteDescription      varchar(500),
                                    OrderIDSeq            varchar(50),   
                                    LineNumber            bigint     not null default 1,
                                    QuoteIDLineNumber     as QuoteIDSeq + '-' + convert(varchar(50),LineNumber)+'B',  
                                    TranType              varchar(50) Not null default 'Booking',                                    
                                    ActivationException   varchar(50) NULL,                             
                                    ApprovedDate          varchar(50),
                                    ApprovedMonth         as convert(varchar(50),year(ApprovedDate)) + '-'+ 
                                                             convert(varchar(50),Month(ApprovedDate)), 
                                    QuotaPeriod           as convert(varchar(50),year(ApprovedDate)) + '-'+ 
                                                             (case when convert(varchar(50),Month(ApprovedDate)) in ('1','2','3')    then 'Q1'
                                                                  when convert(varchar(50),Month(ApprovedDate))  in ('4','5','6')    then 'Q2'
                                                                  when convert(varchar(50),Month(ApprovedDate))  in ('7','8','9')    then 'Q3'
                                                                  when convert(varchar(50),Month(ApprovedDate))  in ('10','11','12') then 'Q4'
                                                              end),   
                                    OrderLastModifiedby   varchar(50),
                                    OrderLastModifiedDate varchar(50),
                                    AccountID             varchar(50),                                  
                                    PMCID                 varchar(50),                                    
                                    CompanyID             varchar(50),
                                    CompanyName           varchar(255),
                                    SiteID                varchar(50),
                                    PropertyID            varchar(50),
                                    PropertyName          varchar(255),
                                    ProductCode           varchar(100),
                                    ProductDisplayName    varchar(255),  
                                    FamilyCode            varchar(50),                                  
                                    FamilyName            varchar(255),   
                                    CategoryCode          varchar(50),                                 
                                    CategoryName          varchar(255),
                                    FrequencyCode         varchar(50),                                                                        
                                    FrequencyName         varchar(255),
                                    displayperiod         as (case when FrequencyName = 'Annual'      then '1'
                                                                   when FrequencyName = 'Monthly'     then '12'
                                                                   when FrequencyName = 'One-time'    then '1'
                                                                   when FrequencyName = 'Initial fee' then '1'
                                                               else '1'
                                                              end),
                                    Sites                 int not null default 0,
                                    Units                 int not null default 0,
                                    Beds                  int not null default 0,
                                    PPUPercentage         int not null default 100,
                                    StudentLivingFlag     int not null default 0,
                                    StudentLiving         as (case when StudentLivingFlag = 1 then 'YES' else 'NO' end),
                                    PriceByBedFlag        int not null default 0, 
                                    PriceByBed            as (case when PriceByBedFlag = 1 then 'YES' else 'NO' end),
                                    AccessAdjustedUnits   numeric(30,0) not null default 0,
                                    ILFAdjustedUnits      numeric(30,0) not null default 0,
                                    AdjustedUnits           as  convert(numeric(30,0),
                                                                          round((case when AccessAdjustedUnits > 0 then AccessAdjustedUnits
                                                                                      else ILFAdjustedUnits end
                                                                                 ),0)),
                                    ----------------------------------
                                    ILFMeasureCode          varchar(20),
                                    ILFActualNetAmount      numeric(30,2),
                                    ILFUnitPrice            numeric(30,3),
                                    ILFUnitOfMeasure        numeric(30,5),
                                    ILFAdjustedNetAmount    numeric(30,2),
                                    
                                    AccessMeasureCode       varchar(20),
                                    AccessActualNetAmount   numeric(30,2),
                                    AccessNetChargeAmount   numeric(30,5),
                                    AccessUnitPrice         numeric(30,3), 
                                    AccessUnitOfMeasure     numeric(30,5),
                                    AccessAdjustedNetAmount numeric(30,2), 

                                    AncillaryMeasureCode       varchar(20),
                                    AncillaryActualNetAmount   numeric(30,2),
                                    AncillaryNetChargeAmount   numeric(30,5),
                                    AncillaryUnitPrice         numeric(30,3),                                                                         
                                    AncillaryUnitOfMeasure     numeric(30,5),
                                    AncillaryAdjustedNetAmount numeric(30,2), 
                                    -----------------------------------------                                    
                                    NetGrossActualAmount    as (ILFActualNetAmount+AccessActualNetAmount+AncillaryActualNetAmount),                                    
                                    NetGrossAdjustedAmount  as (ILFAdjustedNetAmount+AccessAdjustedNetAmount+AncillaryAdjustedNetAmount),
                                    -----------------------------------------                                                                      
                                    OrderTotal              varchar(100)  NULL,
                                    -----------------------------------------                                    
                                    SalesAgentName1         varchar(255),
                                    SalesAgentName2         varchar(255),
                                    SalesAgentName3         varchar(255)
                                   )

  ------------------------------------------------------------------------------------------------------
  select @IPVC_FromDate = convert(datetime,@IPVC_FromDate)
  select @IPVC_ToDate   = convert(datetime,@IPVC_ToDate)
  ------------------------------------------------------------------------------------------------------
  Insert into #TEMPLT_OrdersToConsider(OrderIDSeq,QuoteIDSeq,QuoteTypecode,AccountID,ApprovedDate,
                                   OrderLastModifiedby,OrderLastModifiedDate,
                                   PMCID,CompanyID,CompanyName,SiteID,PropertyID,PropertyName,
                                   StudentLivingFlag,Sites,Units,Beds,PPUPercentage)
  select distinct O.OrderIDSeq,coalesce(O.QuoteIDSeq,''),coalesce(Q.QuoteTypecode,'NEWQ') as QuoteTypecode,
                  O.AccountIDSeq,
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
                  coalesce(PRP.StudentLivingFlag,0)             as StudentLivingFlag,
                  (case when O.PropertyIDSeq is not null 
                          then 1 
                        else 0
                  end )                                         as Sites,
                  Coalesce(PRP.units,0)                         as units, 
                  Coalesce(PRP.Beds,0)                          as Beds,
                  Coalesce(PRP.PPUPercentage,0)                 as PPUPercentage
  from       ORDERS.dbo.[ORDER] O with (nolock)
  inner join ORDERS.dbo.OrderGroup OG with (nolock)
         on  O.OrderIDSeq = OG.OrderIDSeq         
         and   O.statuscode     = 'APPR'
         and   convert(datetime,convert(varchar(50),O.ApprovedDate,101))   >= @IPVC_FromDate
         and   convert(datetime,convert(varchar(50),O.ApprovedDate,101))   <= @IPVC_ToDate
         and   exists (select top 1 1 from ORDERS.dbo.OrderItem OII with (nolock)
                       where  OII.Orderidseq = O.Orderidseq
                       and    OII.MigratedFlag <> 1
                      )
  inner join CUSTOMERS.dbo.Company COM with (nolock)
         on    COM.IDSeq = O.CompanyIDSeq
         and   O.CompanyIDSeq   not in (select CompanyIDSeq from @LT_ExlcudedPMCs)
         and   Coalesce(COM.IDSeq,'') = coalesce(@IPVC_CompanyID,Coalesce(COM.IDSeq,''))
         and   Coalesce(COM.Name,'')      like '%'+ @IPVC_CompanyName + '%'         
  Left outer join
               CUSTOMERS.dbo.Property PRP with (nolock)
         on    O.PropertyIDSeq = PRP.IDSeq       
         and   Coalesce(PRP.IDSeq,'') = coalesce(@IPVC_PropertyID,Coalesce(PRP.IDSeq,''))
         and   Coalesce(PRP.Name,'')      like '%'+ @IPVC_PropertyName + '%' 
  left outer join
               QUOTES.dbo.Quote Q with (nolock)
         on    coalesce(O.Quoteidseq,'') = Q.Quoteidseq
  where O.CompanyIDSeq   not in (select CompanyIDSeq from @LT_ExlcudedPMCs)
         and   Coalesce(COM.IDSeq,'')   = coalesce(@IPVC_CompanyID,Coalesce(COM.IDSeq,''))
         and   Coalesce(COM.Name,'')      like '%'+ @IPVC_CompanyName + '%'
        and   Coalesce(PRP.IDSeq,'')   = coalesce(@IPVC_PropertyID,Coalesce(PRP.IDSeq,''))
         and   Coalesce(PRP.Name,'')      like '%'+ @IPVC_PropertyName + '%'  
         and   coalesce(O.Quoteidseq,'') <> '' 
  ------------------------------------------------------------------------------------------------------
  Insert into #TEMPLT_QuoteTotal(QuoteIDSeq,NetExtYear1ChargeAmount)
  select S.QuoteIDSeq,sum(S.NetExtYear1ChargeAmount)
  from
      (
       select QI.QuoteIDSeq,sum(QI.NetExtYear1ChargeAmount) as NetExtYear1ChargeAmount
       from   Quotes.dbo.QuoteItem QI With (nolock)
       inner join
              Quotes.dbo.Quote     Q with (nolock)
       on     QI.QuoteIDSeq = Q.QuoteIDSeq
       and    exists (select top 1 1 
                      from #TEMPLT_OrdersToConsider A with (nolock)
                      where QI.QuoteIDSeq = A.Quoteidseq
                      and   Q.QuoteIDSeq  = A.Quoteidseq
                     )
       inner join
              Products.dbo.Product P with (nolock)
       on     QI.Productcode = P.Code
       and    QI.Priceversion= P.PriceVersion
       and    P.ExcludeForBookingsFlag = 0
       -------------
       and  not ((Q.QuoteTypecode = 'RPRQ' OR Q.QuoteTypecode = 'STFQ')
                             AND
                 (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
                 )                
       -------------
       and     QI.ExcludeForBookingsFlag = 0
       -------------       
    group by QI.QuoteIDSeq 
      ) S
   group by S.QuoteIDSeq
  ------------------------------------------------------------------------------------------------------
  Insert into #TEMPLT_QuoteSalesAgent(QuoteIDSeq,SalesAgentName1,SalesAgentName2,SalesAgentName3)
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
                    from  #TEMPLT_OrdersToConsider X with (nolock)
                    where X.QuoteIDSeq = QSA.QuoteIDSeq
                   )
      group by QSA.QuoteIDSeq
     ) S
  ------------------------------------------------------------------
  update #TEMPLT_QuoteSalesAgent 
  set    SalesAgentName1 = replace(SalesAgentName1,'[House]','House'),
         SalesAgentName2 = replace(SalesAgentName2,'[House]','House'),
         SalesAgentName3 = replace(SalesAgentName3,'[House]','House')
  ------------------------------------------------------------------------------------------------------
  Insert into #TEMPLT_BookingsReport
                                (QuoteIDSeq,OrderIDSeq,ApprovedDate,OrderLastModifiedby,OrderLastModifiedDate,
                                 AccountID,PMCID,CompanyID,CompanyName,SiteID,PropertyID,PropertyName,
                                 ProductCode,ProductDisplayName,FamilyCode,FamilyName,CategoryCode,CategoryName,
                                 FrequencyCode,FrequencyName,
                                 Sites,Units,Beds,PPUPercentage,
                                 StudentLivingFlag,PriceByBedFlag,
                                 AccessAdjustedUnits,ILFAdjustedUnits, 
                                 ILFMeasureCode,ILFActualNetAmount,ILFUnitPrice,ILFUnitOfMeasure,
                                 AccessMeasureCode,AccessActualNetAmount,AccessNetChargeAmount,AccessUnitPrice,AccessUnitOfMeasure,
                                 AncillaryMeasureCode,AncillaryActualNetAmount,AncillaryNetChargeAmount,AncillaryUnitPrice,AncillaryUnitOfMeasure,
                                 ILFAdjustedNetAmount,AccessAdjustedNetAmount,AncillaryAdjustedNetAmount,
                                 LineNumber)
  select S.QuoteIDSeq,S.OrderIDSeq,S.ApprovedDate,S.OrderLastModifiedby,S.OrderLastModifiedDate,
         S.AccountID,S.PMCID,S.CompanyID,S.CompanyName,S.SiteID,S.PropertyID,S.PropertyName,
         S.ProductCode,S.ProductDisplayName,S.FamilyCode,S.FamilyName,S.CategoryCode,S.CategoryName,
         S.FrequencyCode,S.FrequencyName,
         S.Sites,S.Units,S.Beds,S.PPUPercentage,
         S.StudentLivingFlag,S.PriceByBedFlag,
         S.AccessAdjustedUnits,S.ILFAdjustedUnits, 
         S.ILFMeasureCode,S.ILFActualNetAmount,S.ILFUnitPrice,S.ILFUnitOfMeasure,
         S.AccessMeasureCode,S.AccessActualNetAmount,S.AccessNetChargeAmount,S.AccessUnitPrice,S.AccessUnitOfMeasure,
         S.AncillaryMeasureCode,S.AncillaryActualNetAmount,S.AncillaryNetChargeAmount,S.AncillaryUnitPrice,S.AncillaryUnitOfMeasure,
         S.ILFAdjustedNetAmount,S.AccessAdjustedNetAmount,S.AncillaryAdjustedNetAmount,
         ROW_NUMBER() OVER (PARTITION BY  S.QuoteIDSeq
                             Order by S.ProductDisplayName ASC,
                                      S.CompanyName        ASC,
                                      S.PropertyName       ASC,
                                      Convert(varchar(50),S.ApprovedDate,101) ASC,S.QuoteIDSeq ASC) 
                            as LineNumber
  from (select
           OTC.QuoteIDSeq         as QuoteIDSeq, 
           OTC.OrderIDSeq         as OrderIDSeq,
           OTC.ApprovedDate       as ApprovedDate,
           OTC.OrderLastModifiedby   as OrderLastModifiedby,
           OTC.OrderLastModifiedDate as OrderLastModifiedDate,
           OTC.AccountID          as AccountID,
           OTC.PMCID              as PMCID,
           OTC.CompanyID          as CompanyID,
           OTC.CompanyName        as CompanyName,
           OTC.SiteID             as SiteID,
           OTC.PropertyID         as PropertyID,
           OTC.PropertyName       as PropertyName,           
           OI.ProductCode         as ProductCode,           
           P.DisplayName          as ProductDisplayName,
           P.FamilyCode           as FamilyCode,
           F.Name                 as FamilyName,
           P.CategoryCode         as CategoryCode,
           CT.Name                as CategoryName,
           ------------------
           COALESCE(MAX(case when OI.chargetypecode = 'ACS' then OI.FrequencyCode else NULL end),
                    MAX(case when OI.chargetypecode = 'ILF' then OI.FrequencyCode else NULL end)
                   )                                      as FrequencyCode,
           (select top 1 ltrim(rtrim(F.Name))
            from   Products.dbo.Frequency F with (nolock)
            where  F.Code = COALESCE(MAX(case when OI.chargetypecode = 'ACS' then OI.FrequencyCode else NULL end),
                                     MAX(case when OI.chargetypecode = 'ILF' then OI.FrequencyCode else NULL end)
                                    ) 
           )                                              as FrequencyName,
           ------------------
           OTC.Sites              as Sites,
           coalesce(OI.Units,OTC.Units,0)    as Units,
           coalesce(OI.Beds,OTC.Beds,0)      as Beds,
           coalesce(OI.PPUPercentage,OTC.PPUPercentage,100)  as PPUPercentage,
           OTC.StudentLivingFlag  as StudentLivingFlag,
           ------------------
           (case when OTC.StudentLivingFlag=1 and Max(convert(int,C.PriceByBedEnabledFlag)) = 1
                   then 1
                 else 0
            end)                  as PriceByBedFlag,
           round(sum((case when C.reportingtypecode <> 'ILFF' then 1 else 0 end)*
                      (case when ((OTC.StudentLivingFlag = 1)    and
                                  (C.PriceByBedEnabledFlag = 1)
                                 )                              and
                                 (OI.CapMaxUnitsFlag = 1)       and
                                 (coalesce(OI.Beds,OTC.Beds,0)  >= 
                                  coalesce(OI.MaxUnits,C.MaxUnits,0)
                                 )
                              then coalesce(OI.MaxUnits,C.MaxUnits,0)
                            when ((OTC.StudentLivingFlag = 1)    and
                                  (C.PriceByBedEnabledFlag = 1)
                                 )
                              then coalesce(OI.Beds,OTC.Beds,0)
                            when (OI.CapMaxUnitsFlag = 1)      and
                                 (coalesce(OI.Units,OTC.Units,0) >= 
                                  coalesce(OI.MaxUnits,C.MaxUnits,0)
                                 )
                              then coalesce(OI.MaxUnits,C.MaxUnits,0)
                            else coalesce(OI.Units,OTC.Units,0)
                       end
                       ) *
                (case when (P.familycode = 'LSD' and C.PriceByPPUPercentageEnabledFlag = 1) 
                         then (convert(numeric(30,5),Coalesce(OI.PPUPercentage,OTC.PPUPercentage,100))/100)
                      when (C.QuantityEnabledFlag = 1)  
                         then 0
                      else 1
                 end)                                          
            ),0)                                                  as AccessAdjustedUnits,
           sum((case when C.reportingtypecode = 'ILFF' then 1 else 0 end)*
                      (case when ((OTC.StudentLivingFlag = 1)    and
                                  (C.PriceByBedEnabledFlag = 1)
                                 )                              and
                                 (OI.CapMaxUnitsFlag = 1)       and
                                 (coalesce(OI.Beds,OTC.Beds,0)  >= 
                                  coalesce(OI.MaxUnits,C.MaxUnits,0)
                                 )
                              then coalesce(OI.MaxUnits,C.MaxUnits,0)
                            when ((OTC.StudentLivingFlag = 1)    and
                                  (C.PriceByBedEnabledFlag = 1)
                                 )
                              then coalesce(OI.Beds,OTC.Beds,0)
                            when (OI.CapMaxUnitsFlag = 1)      and
                                 (coalesce(OI.Units,OTC.Units,0) >= 
                                  coalesce(OI.MaxUnits,C.MaxUnits,0)
                                 )
                              then coalesce(OI.MaxUnits,C.MaxUnits,0)
                            else coalesce(OI.Units,OTC.Units,0)
                       end
                       )*
                (case when (P.familycode = 'LSD' and C.PriceByPPUPercentageEnabledFlag = 1) 
                         then (convert(numeric(30,5),Coalesce(OI.PPUPercentage,OTC.PPUPercentage,100))/100)
                      when (C.QuantityEnabledFlag = 1)  
                         then 0
                      else 1
                 end)                                                  
            )                                          as ILFAdjustedUnits,
           ------------------
           MAX(case when ((C.reportingtypecode = 'ILFF') and
                          (OTC.StudentLivingFlag = 1)    and
                          (C.PriceByBedEnabledFlag = 1)  and
                          (ltrim(rtrim(OI.MeasureCode)) = 'UNIT')
                         )
                      then 'BED'
                    when  (C.reportingtypecode = 'ILFF') 
                      then ltrim(rtrim(OI.MeasureCode))
                    else NULL
               end)                                       as ILFMeasureCode,
           SUM(case C.reportingtypecode  
                    when 'ILFF' then OI.NetExtYear1ChargeAmount
                 else 0
               end)                                       as ILFActualNetAmount,
           SUM(case C.reportingtypecode  
                    when 'ILFF' then OI.NetUnitChargeAmount
                 else 0
               end)                                       as ILFUnitPrice,
           SUM(case when (C.reportingtypecode  ='ILFF' and (ltrim(rtrim(OI.MeasureCode)) = 'UNIT') and C.Quantityenabledflag = 0)
                       then OI.EffectiveQuantity
                    when (C.reportingtypecode  ='ILFF' and C.Quantityenabledflag = 1)
                       then OI.EffectiveQuantity
                    when (C.reportingtypecode  ='ILFF')
                       then OI.UnitOfMeasure
                 else 0
               end)                                        as ILFUnitOfMeasure,
           --------------------
           MAX(case when ((C.reportingtypecode = 'ACSF') and
                          (OTC.StudentLivingFlag = 1)    and
                          (C.PriceByBedEnabledFlag = 1)  and
                          (ltrim(rtrim(OI.MeasureCode)) = 'UNIT')
                         )
                      then 'BED'
                    when  (C.reportingtypecode = 'ACSF') 
                      then ltrim(rtrim(OI.MeasureCode))
                    else NULL
               end)                                       as AccessMeasureCode,
           SUM(case C.reportingtypecode  
                    when 'ACSF' then OI.NetExtYear1ChargeAmount
                 else 0
               end)                                       as AccessActualNetAmount,
           SUM(case C.reportingtypecode  
                    when 'ACSF' then OI.NetChargeAmount
                 else 0
               end)                                       as AccessNetChargeAmount,
           SUM(case C.reportingtypecode  
                    when 'ACSF' then OI.NetUnitChargeAmount
                 else 0
               end)                                       as AccessUnitPrice,
           SUM(case when (C.reportingtypecode  ='ACSF' and (ltrim(rtrim(OI.MeasureCode)) = 'UNIT') and C.Quantityenabledflag = 0)
                       then OI.EffectiveQuantity
                    when (C.reportingtypecode  ='ACSF' and C.Quantityenabledflag = 1)
                       then OI.EffectiveQuantity
                    when (C.reportingtypecode  ='ACSF')
                       then OI.UnitOfMeasure
                 else 0
               end)                                       as AccessUnitOfMeasure,
           --------------------  
           MAX(case when ((C.reportingtypecode = 'ANCF') and
                          (OTC.StudentLivingFlag = 1)    and
                          (C.PriceByBedEnabledFlag = 1)  and
                          (ltrim(rtrim(OI.MeasureCode)) = 'UNIT')
                         )
                      then 'BED'
                    when  (C.reportingtypecode = 'ANCF') 
                      then ltrim(rtrim(OI.MeasureCode))
                    else NULL
               end)                                       as AncillaryMeasureCode,
           SUM(case C.reportingtypecode  
                    when 'ANCF' then OI.NetExtYear1ChargeAmount
                 else 0
               end)                                       as AncillaryActualNetAmount,
           SUM(case C.reportingtypecode  
                    when 'ANCF' then OI.NetChargeAmount
                 else 0
               end)                                       as AncillaryNetChargeAmount,
           SUM(case C.reportingtypecode  
                    when 'ANCF' then OI.NetUnitChargeAmount
                 else 0
               end)                                       as AncillaryUnitPrice,
           SUM(case when (C.reportingtypecode  ='ANCF' and (ltrim(rtrim(OI.MeasureCode)) = 'UNIT') and C.Quantityenabledflag = 0)
                       then OI.EffectiveQuantity
                    when (C.reportingtypecode  ='ANCF' and C.Quantityenabledflag = 1)
                       then OI.EffectiveQuantity
                    when (C.reportingtypecode  ='ANCF')
                       then OI.UnitOfMeasure
                 else 0
               end)                                         as AncillaryUnitOfMeasure,
           --------------------  
           SUM(case C.reportingtypecode  
                    when 'ILFF' 
                      then (case  when (C.Measurecode = 'TRAN')
                                     then 0
                                  when (P.FamilyCode = 'LSD' and  C.QuantityEnabledFlag=1)
                                    then OI.NetExtYear1ChargeAmount * OTC.Units
                                  /*when (P.CategoryCode = 'PAY'  and 
                                        C.QuantityEnabledFlag=0 and
                                        OI.productcode <> 'DMD-OSD-PAY-PAY-POPY')
                                    then OI.NetExtYear1ChargeAmount + (OTC.Units*@LT_PaymentsBillingsMultiplier)
                                    ---Special case for Payment products alone
                                  */
                                  else OI.NetExtYear1ChargeAmount
                            end)
                 else 0
               end)                                        as ILFAdjustedNetAmount,

           SUM(case C.reportingtypecode  
                    when 'ACSF' 
                      then (case when (C.Measurecode = 'TRAN')
                                     then 0
                                 when (P.FamilyCode = 'LSD'    and 
                                       C.QuantityEnabledFlag=1)
                                     then OI.NetExtYear1ChargeAmount * OTC.Units
                                 /*when (P.CategoryCode = 'PAY'  and 
                                        C.QuantityEnabledFlag=0 and
                                        OI.productcode <> 'DMD-OSD-PAY-PAY-POPY')
                                    then OI.NetExtYear1ChargeAmount + (OTC.Units*@LT_PaymentsBillingsMultiplier)
                                    ---Special case for Payment products alone
                                  */
                                else OI.NetExtYear1ChargeAmount
                            end)
                 else 0
               end)                                        as AccessAdjustedNetAmount,
           SUM(case when (C.reportingtypecode in ('ILFF','ACSF') and
                          (P.CategoryCode = 'PAY'  and 
                           C.QuantityEnabledFlag=0 and
                           OI.productcode <> 'DMD-OSD-PAY-PAY-POPY') 
                         )
                         then (OTC.Units*@LT_PaymentsBillingsMultiplier) ------Special case for Payment products alone
   
                    when C.reportingtypecode = 'ANCF' 
                      then (case when (C.Measurecode = 'TRAN')
                                     then 0
                                 when (P.FamilyCode = 'LSD'    and 
                                       C.QuantityEnabledFlag=1)
                                     then OI.NetExtYear1ChargeAmount * OTC.Units
                                 when (P.CategoryCode = 'PAY'  and 
                                       C.QuantityEnabledFlag=0 and
                                       OI.productcode <> 'DMD-OSD-PAY-PAY-POPY')
                                     then OI.NetExtYear1ChargeAmount + (OTC.Units*@LT_PaymentsBillingsMultiplier)---Special case for Payment products alone
                                else OI.NetExtYear1ChargeAmount
                            end)
                 else 0
               end)                                        as AncillaryAdjustedNetAmount
           ------------------------          
        from   ORDERS.dbo.OrderItem          OI with (nolock)    
        inner join #TEMPLT_OrdersToConsider  OTC  with (nolock)
        on    OI.OrderIDSeq = OTC.OrderIDSeq 
        and   OI.MigratedFlag <> 1
        and  (OI.StatusCode <> 'CNCL' or OI.StatusCode <> 'EXPD')    
        inner join
              PRODUCTS.dbo.Product P with (nolock)
        on    OI.productcode   = P.code
        and   OI.PriceVersion  = P.PriceVersion    
        and   P.ExcludeForBookingsFlag = 0
        -------------
        and  not ((OTC.QuoteTypecode = 'RPRQ' OR OTC.QuoteTypecode = 'STFQ')
                              AND
                  (OI.chargetypecode = 'ILF' and OI.discountpercent=100)
                 ) 
       -------------
       and     OI.ExcludeForBookingsFlag = 0
       -------------
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
       group by OTC.QuoteIDSeq,OTC.OrderIDSeq,OTC.ApprovedDate,
                OTC.OrderLastModifiedby,OTC.OrderLastModifiedDate,
                OTC.AccountID,OTC.PMCID,OTC.CompanyID,OTC.CompanyName,OTC.SiteID,
                OTC.PropertyID,OTC.PropertyName,OI.ProductCode,P.DisplayName,
                P.FamilyCode,F.Name,P.CategoryCode,CT.Name,
                OTC.Sites,coalesce(OI.Units,OTC.Units,0),coalesce(OI.Beds,OTC.Beds,0),coalesce(OI.PPUPercentage,OTC.PPUPercentage,100)
               ,OTC.StudentLivingFlag
  )S
  Order by S.CompanyName ASC,S.ProductDisplayName ASC,S.PropertyName ASC,
           Convert(varchar(50),S.ApprovedDate,101) ASC,S.QuoteIDSeq ASC  
  ------------------------------------------------------------------------------------------------------------
  Update D 
  set    D.SalesAgentName1 = S.SalesAgentName1,
         D.SalesAgentName2 = S.SalesAgentName2,
         D.SalesAgentName3 = S.SalesAgentName3
  from   #TEMPLT_BookingsReport D   with (nolock) 
  inner join 
         #TEMPLT_QuoteSalesAgent S  with (nolock)
  on     D.QuoteIDSeq = S.QuoteIDSeq
  ------------------------------------------------------------------------------------------------------------
  Update D
  set    D.QuoteDescription = S.[Description]
  from   #TEMPLT_BookingsReport D with (nolock)
  inner join
         Quotes.dbo.Quote       S with (nolock)         
  on     D.QuoteIDSeq = S.QuoteIDSeq  
  ------------------------------------------------------------------------------------------------------------
  Update D
  set    D.OrderTotal       = S.NetExtYear1ChargeAmount
  from   #TEMPLT_BookingsReport D with (nolock)
  inner join
         #TEMPLT_QuoteTotal     S with (nolock)
  on     D.QuoteIDSeq = S.QuoteIDSeq  
  ------------------------------------------------------------------------------------------------------------ 
  ---Final Select  
  select 
         QuoteIDSeq              as [Doc #],
         QuoteDescription        as [Doc Description], 
         LineNumber              as [Line #],
         QuoteIDLineNumber       as [O-L #],
         TranType                as [Tran Type],
         ApprovedMonth           as [Month],  
         ActivationException     as [Activation Exception],
         ApprovedDate            as [Booking Entry Date],
         QuotaPeriod             as [Quota Period],
         AccountID               as [AccountID],
         PMCID                   as [PMCID],
         CompanyID               as [CompanyID],
         CompanyName             as [PMC Name],
         SiteID                  as [SiteID],
         PropertyID              as [PropertyID],         
         PropertyName            as [Site Name],
         ProductCode             as [ProductCode],
         ProductDisplayName      as [Product Name],
         FamilyName              as [Market],         
         CategoryName            as [Sub-Market],
         Sites                   as [Sites],        
         Units                   as [Units],
         Beds                    as [Beds],
         PPUPercentage           as [PPUPercentage],
         StudentLiving           as [Student Living],
         PriceByBed              as [Priced By Bed], 
         AdjustedUnits           as [Adjusted Units/Beds],        
         displayperiod           as Period,
         ILFMeasureCode          as [ILF Base],
         ILFUnitPrice            as [ILF UnitPrice],
         ILFUnitOfMeasure        as [ILF Effective Quantity],
         ILFActualNetAmount      as [ILF Actual Net Amount],
         ILFAdjustedNetAmount    as [ILF Adjusted Net Amount],
         AccessMeasureCode       as [Access Base],
         AccessUnitPrice         as [Access UnitPrice],
         AccessUnitOfMeasure     as [Access Effective Quantity], 
         AccessActualNetAmount   as [Access Actual Net Amount],
         AccessAdjustedNetAmount as [Access Adjusted Net Amount], 
         AncillaryMeasureCode       as [Ancillary Base],
         AncillaryUnitPrice         as [Ancillary UnitPrice],
         AncillaryUnitOfMeasure     as [Ancillary Effective Quantity], 
         AncillaryActualNetAmount   as [Ancillary Actual Net Amount],
         AncillaryAdjustedNetAmount as [Ancillary Adjusted Net Amount], 
         NetGrossActualAmount       as [Actual Gross Net Amount],        
         NetGrossAdjustedAmount     as [Adjusted Gross Net Amount],
         OrderTotal              as [Order Total],
         OrderLastModifiedby     as [Order LastModifiedby],
         OrderLastModifiedDate   as [Order LastModifiedDate],
         SalesAgentName1         as [SalesAgentName1],
         SalesAgentName2         as [SalesAgentName2],
         SalesAgentName3         as [SalesAgentName3]
  from #TEMPLT_BookingsReport with (nolock) 
  ---->where quoteidseq in('Q0804000020','Q0805000117')
  Order by CompanyName ASC,ProductDisplayName ASC,PropertyName ASC
  ------------------------------------------------------------------------------------------------------------ 
  ---Final Cleanup
  Drop table #TEMPLT_BookingsReport
  Drop table #TEMPLT_QuoteSalesAgent
  Drop table #TEMPLT_OrdersToConsider
  Drop table #TEMPLT_QuoteTotal  
  ------------------------------------------------------------------------------------------------------------ 
END
GO
