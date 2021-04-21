SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Exec Orders.dbo.uspORDERS_RenewOrderEngine @IPVC_BillingCycleDate = '11/15/2009'
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_RenewOrderEngine
-- Description     : Get Detail of Upcoming Renewal
-- Input Parameters: 
-- Code Example    : Exec ORDERS.dbo.[uspORDERS_RenewOrderEngine] @IPI_RenewalDays = 60
-- Revision History:
-- Author          : SRS
-- 04/15/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_RenewOrderEngine](@IPI_RenewalDays       int = 60,                                                    
                                                    @IPI_FulfillDays       int = 45,
                                                    @IPVC_BillingCycleDate varchar(50) ='',
                                                    @IPVC_CompanyID        varchar(50) ='',
                                                    @IPVC_AccountID        varchar(50) ='',
                                                    @IPVC_OrderID          varchar(50) ='',
                                                    @IPI_GroupID           varchar(50) ='',
                                                    @IPI_OrderItemID       varchar(50) ='',
                                                    @IPVC_FamilyCode       varchar(10) ='',
                                                    @IPBI_UserIDSeq        varchar(50) ='' ---This is the UserID of user who is initiating the renewal.
                                                   )
AS
BEGIN  
  set nocount on;  
  set quoted_identifier on;
  set ansi_warnings off;
  ----------------------------------------------------------------------
  -- Declare Local Variables
  declare @LI_Min                         int
  declare @LI_Max                         int
  declare @LI_OrderItemsRenewedCount      int
  declare @LVC_OrderID                    varchar(50)
  declare @LI_GroupID                     bigint
  Declare @IPD_EndDate                    datetime   
  Declare @IPD_FullFillDate               datetime
  declare @LI_custombundlenameenabledflag int
  declare @LDT_SystemDate                 datetime
  ----------------------------------------------------------------------
  --Renewals are usually done 60 days in advance. But user can still pass
  -- it as a parameter. The default is 60 days
  if (@IPI_RenewalDays = '' or @IPI_RenewalDays is null)
  begin
    select @IPI_RenewalDays = 60
  end
  -----------------------
  --Renewals are done 60 days in advance. If @IPVC_BillingCycleDate or @IPI_RenewalDays are not passed,
  -- RenewalOrderEngine defaults to 60 days.
  --Fulfilling of OrderItems ie (status change from PENR to FULF is set 45 in advance)
  --These 2 @IPI_RenewalDays,@IPI_FulfillDays are hardcoded to 60 and 45 respectively,
  --  although these are parameterized to override for future changes in Business needs.
  if (isdate(@IPVC_BillingCycleDate)=0)--> if @IPVC_BillingCycleDate is not passed,then go with current OPEN BillingCycleDate from INVOICES.DBO.InvoiceEOMServiceControl 
  begin
    select  Top 1 @IPVC_BillingCycleDate = B.BillingCycleDate,
                  @IPD_EndDate           =(case when ((day(B.BillingCycleDate)= 15))
                                                  then convert(datetime,
                                                               convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0))))+
                                                               '/15/'+
                                                               convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0))))
                                                               )                                                                                  --> Middle Day of forward 2 Month from BillingCycleDate 
                                                 when ((day(B.BillingCycleDate)<> 15))
                                                        then convert(datetime,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,B.BillingCycleDate)+3,0)))    --> Last Day of forward 2 Month from BillingCycleDate
                                           end)
    from    INVOICES.DBO.InvoiceEOMServiceControl B with (nolock)
    where   B.BillingCycleClosedFlag = 0 
  end
  else if (isdate(@IPVC_BillingCycleDate)=1) 
  begin    
    select @IPVC_BillingCycleDate = convert(varchar(50),convert(datetime,@IPVC_BillingCycleDate),101)
    select @IPD_EndDate   = (case when ((day(convert(datetime,@IPVC_BillingCycleDate))= 15))
                                    then convert(datetime,
                                                 convert(varchar(50),Month(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,convert(datetime,@IPVC_BillingCycleDate))+3,0))))+
                                                 '/15/'+
                                                 convert(varchar(50),Year(DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,convert(datetime,@IPVC_BillingCycleDate))+3,0))))
                                                )                                                                                                    --> Middle Day of forward 2 Month from BillingCycleDate 
                                   when ((day(convert(datetime,@IPVC_BillingCycleDate))<> 15))
                                     then convert(datetime,DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,convert(datetime,@IPVC_BillingCycleDate))+3,0)))    --> Last Day of forward 2 Month from BillingCycleDate
                             end)
  end
  else
  begin    
    select @IPD_EndDate   = convert(datetime,convert(varchar(50),'01/01/1900',101)) 
  end 
  ----------------------------------------------------------------------
  set @IPD_FullFillDate = convert(datetime,convert(varchar(50),
                                                   dateadd(day, @IPI_FulfillDays, getdate()),101)
                                 )
  ----------------------------------------------------------------------
  set @IPVC_CompanyID    =  nullif(@IPVC_CompanyID, '')
  set @IPVC_AccountID    =  nullif(@IPVC_AccountID, '') 
  set @IPVC_OrderID      =  nullif(@IPVC_OrderID,'')
  set @IPI_GroupID       =  nullif(@IPI_GroupID,'')
  set @IPI_OrderItemID   =  nullif(@IPI_OrderItemID,'')
  set @IPVC_FamilyCode   =  nullif(@IPVC_FamilyCode,'')
  set @IPBI_UserIDSeq    =  nullif(@IPBI_UserIDSeq,'')
  set @LDT_SystemDate    =  getdate()
  
  if @IPI_OrderItemID is not null
  begin
    select @LI_custombundlenameenabledflag = OG.custombundlenameenabledflag,
           @IPI_GroupID = OG.IDSeq           
    from   ORDERS.dbo.OrderItem OI with (nolock)
    inner join
           ORDERS.dbo.OrderGroup OG with (nolock)
    on     OI.OrderGroupIDseq = OG.IdSeq
    and    OI.IDSeq           = @IPI_OrderItemID
    
    if @LI_custombundlenameenabledflag = 1
    begin
      select @IPI_OrderItemID = NULL
    end
  end
  ----------------------------------------------------------------------
  --Create Temp Tables
  ----------------------------------------------------------------------  
  create table #LT_Bundles  (SEQ                      int not null identity(1,1) primary key,
                             orderid                  varchar(50),
                             groupid                  bigint
                             ) 

  Create table #TempREpriceCapholdingTable
                                         (SEQ                           int not null identity(1,1) primary key,
                                          companyidseq                  varchar(50)   null,
                                          propertyidseq                 varchar(50)   null,
                                          pricecapflag                  int           not null default 0,
                                          pricecapterm                  int           not null default 0,
                                          pricecapbasiscode             varchar(50)   not null default 'LIST',
                                          PriceCapPercent               float not null default 0.00,
                                          PriceCapStartDate             datetime      null,
                                          PriceCapEndDate               datetime      null, 
                                          productcode                   varchar(100)  null                                         
                                          ) ON [PRIMARY]

  Create table #TempREOrderItem (SortSeq                     bigint not null identity(1,1) primary key,
                                 companyidseq                varchar(50),                                 
                                 propertyidseq               varchar(50),                                 
                                 accountidseq                varchar(50),                                                     
                                 orderidseq                  varchar(50),
                                 ordergroupidseq             bigint,
                                 orderitemidseq              bigint, 
                                 neworderitemidseq           bigint,                                  
                                 productcode                 varchar(50),
                                 priceversion                numeric(18,0),
                                 ------------------------------------------
                                 units                       int,
                                 beds                        int,
                                 ppupercentage               int,
                                 ------------------------------------------                                  
                                 chargetypecode              varchar(3),
                                 frequencycode               varchar(6),                                 
                                 measurecode                 varchar(6),                                 
                                 familycode                  varchar(3), 
                                 ReportingTypeCode           varchar(20),
                                 custombundlenameenabledflag int    not null default (0),  
                                 ------------------------------------------                                 
                                 Quantity                    decimal(18,3),
                                 MinUnits                    int,
                                 MaxUnits                    int,
                                 AllowProductCancelFlag      bit,
                                 CredtCardPricingPercentage  numeric(30,3),                                 
                                 ShippingAndHandlingAmount   money, 
                                 DollarMaximum               money,
                                 PrintedOnInvoiceFlag        bit,
                                 AttachmentFlag              bit,                                 
                                 CrossFireMaximumAllowableCallVolume bigint,
                                 ExcludeForBookingsFlag      bigint not null default (0),                                
                                 ------------------------------------------------------
                                 StatusCode                  varchar(5),
                                 CapMaxUnitsFlag             bit,
                                 BillToAddressTypeCode       varchar(10),
                                 BillToDeliveryOptionCode    varchar(10),
                                 ------------------------------------------------------                               
                                 ILFStartDate                datetime,
                                 ILFEndDate                  datetime,   
                                 --------------------------------------------------------
                                 ordersynchstartmonth        int    not null default (0), 
                                 currentactivationstartdate  datetime,
                                 currentactivationenddate    datetime, 
                                 renewalactivationstartdate  datetime,
                                 renewalactivationenddate        as (case when (ordersynchstartmonth=0 and Charindex('PRM-LEG-',Productcode) > 0)
                                                                             then dateadd(year,1,renewalactivationstartdate)-1                                                           
                                                                          when (ordersynchstartmonth=0 and day(renewalactivationstartdate) = 1)
                                                                             then dateadd(year,1,renewalactivationstartdate)-1
                                                                          when (ordersynchstartmonth=0 and day(renewalactivationstartdate) <> 1)
                                                                             then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,dateadd(year,1,renewalactivationstartdate))+1,0)) 
                                                                          when ordersynchstartmonth > 0 and ordersynchstartmonth <= month(renewalactivationstartdate)
                                                                             then dateadd(day,-1,
                                                                                          convert(varchar(20),ordersynchstartmonth)+
                                                                                          '/01/'+
                                                                                          convert(varchar(20),year(renewalactivationstartdate)+1)
                                                                                         )
                                                                             else dateadd(day,-1,
                                                                                          convert(varchar(20),ordersynchstartmonth)+
                                                                                          '/01/'+
                                                                                          convert(varchar(20),year(renewalactivationstartdate))
                                                                                         )
                                                                     end
                                                                     ),
                                 -----------------------------------------------------------------  
                                 currentchargeamount         money not null default (0),
                                 currentnetunitchargeamount  money not null default (0),
                                 unitofmeasure               numeric(30,5) not null default (0.00),
                                 UnitEffectiveQuantity       numeric(30,5) not null default (0.00),
                                 effectivequantity           numeric(30,5) not null default (0.00),                                   
                                 discountpercent             float not null default (0.00),
                                 currentnetextchargeamount   money not null default (0),                                                               
                                 ------------------------------------------------------------------ 
                                 socpriceversion             numeric(18,0),
                                 socchargeamount             float  not null default (0),  
                                 socnetextchargeamount       as (convert(float,socchargeamount) * effectivequantity),                                 
                                 ------------------------------------------------------------------
                                 renewalchargeamount         money null,
                                 renewaldiscchargeamount     money null,
                                 renewaladjustedchargeamount money null,
                                 renewalstartdate            datetime null,                                                                
                                 renewaladjustedchargeamountdisplay  as  convert(money,coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)),                                  
                                 renewalnetextchargeamount           as  (case when  ((DollarMinimumEnabledFlag=1)
                                                                                           and  
                                                                                        (convert(numeric(30,2),
                                                                                                   (convert(money,coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)) 
                                                                                                      *
                                                                                                    UnitEffectiveQuantity
                                                                                                   )
                                                                                                )
                                                                                        ) <= DollarMinimum
                                                                                      )                                                                                       
                                                                                  then DollarMinimum
                                                                                 else convert(numeric(30,2),
                                                                                                   (convert(money,coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)) 
                                                                                                      *
                                                                                                    effectivequantity
                                                                                                   )
                                                                                                )
                                                                            end),  
                                 ------------------------------------------------------------------ 
                                 DollarMinimumEnabledFlag    int           not null default(0),
                                 DollarMinimum               numeric(30,2) not null default(0.00),                                                                                                             
                                 ------------------------------------------------------------------ 
                                 renewaltypecode             varchar(5), 
                                 renewaltypename             as (case when renewaltypecode = 'ARNW' then 'Automatic'
                                                                      when renewaltypecode = 'MRNW' then 'Manual'
                                                                      when renewaltypecode = 'DRNW' then 'Do Not Renew'
                                                                      else 'Unknown'
                                                                 end),             
                                 renewalcount                bigint not null default 0,
                                 renewalnotes                varchar(1000) null,
                                 masterorderitemidseq        bigint,                     
                                 renewalreviewedflag         bigint not null default (0),
                                 renewedbyuseridseq          bigint null,
                                 fulfilledbyidseq            bigint null,
                                 ---------------------------------------------------------------
                                 FirstActivationStartDate    varchar(50) NULL,
                                 ---------------------------------------------------------------
                                 PriceCapFlag                int default (0),
                                 pricecapbasiscode           varchar(50) null default 'LIST',
                                 PriceCapStartDate           datetime NULL,
                                 PriceCapEndDate             datetime NULL,
                                 PriceCapPercent             float not null default 0.00,
                                 ---------------------------------------------------------------
                                 ModifiedByUserIDSeq         bigint   NULL                
                                ) ON [PRIMARY]  
  ------------------------------------------------------------------------------------------------
  --Step 0 : Preparatory Steps
  select XII.IDSeq as OrderItemIDSeq,
        Max(O.CompanyIDSeq)            as CompanyIDSeq,       
        Max(COM.ordersynchstartmonth)  as ordersynchstartmonth,       
        Max(O.PropertyIDSeq)           as PropertyIDSeq,
        O.AccountIDSeq                 as AccountIDSeq,
        Max(XII.OrderIDSeq) as OrderIDSeq,
        Max(convert(int,OG.custombundlenameenabledflag)) as custombundlenameenabledflag,
        Max(OG.Name)                                     as ordergroupname,
        MAX(OG.IDSeq)                                    as OrderGroupIDSeq,
        MAX(PRPTY.Units)                                 as Units,
        MAX(PRPTY.Beds)                                  as Beds,
        Max(PRPTY.PPUPercentage)                         as PPUPercentage,             
        XII.ProductCode,XII.Measurecode,XII.Frequencycode,
        Coalesce(XII.MasterOrderItemIDSeq,XII.IDSeq) as MasterOrderItemIDSeq,XII.Renewalcount,
        Max((case when (XII.Measurecode='UNIT') then
                   (case when ((PRPTY.StudentLivingFlag = 1)    and
                         (OCHG.PriceByBedEnabledFlag = 1)
                         )                                  and
                        (XII.CapMaxUnitsFlag = 1)            and
                        (coalesce(XII.Beds,PRPTY.Beds,0)  >= 
                         coalesce(XII.MaxUnits,OCHG.MaxUnits,0)
                        )
                       then coalesce(XII.MaxUnits,OCHG.MaxUnits,0)
                    when ((PRPTY.StudentLivingFlag = 1)    and
                          (OCHG.PriceByBedEnabledFlag = 1)
                         )
                        then coalesce(XII.Beds,PRPTY.Beds,0)
                    when (XII.CapMaxUnitsFlag = 1)      and
                         (coalesce(XII.Units,PRPTY.Units,0) >= 
                          coalesce(XII.MaxUnits,OCHG.MaxUnits,0)
                         )
                     then coalesce(XII.MaxUnits,OCHG.MaxUnits,0)
                     else coalesce(XII.Units,PRPTY.Units,0)
                   end
                  )
             else 1
            end))                                        as UnitEffectiveQuantity
  Into  #Temp_REOrderItemsfirst
  from   ORDERS.dbo.[Orderitem] XII with (nolock)
        inner join 
               ORDERS.dbo.[OrderGroup] OG  with (nolock) 
        on     XII.Orderidseq      = OG.Orderidseq
        and    XII.Ordergroupidseq = OG.IDSeq               
        and    OG.IDseq            = coalesce(@IPI_GroupID,OG.IDseq)
        and    XII.IDSeq           = coalesce(@IPI_OrderItemID,XII.IDSeq) 
        ---------------------------------------------------------------------------------------------  
        and     XII.ChargeTypeCode      =  'ACS'
        and     XII.Measurecode         <> 'TRAN'
        and     XII.FrequencyCode       <> 'OT'
        and     XII.RenewalTypeCode     =  'ARNW'                
        and     XII.ActivationEndDate   <  @IPD_EndDate
        and     XII.StatusCode          =  'FULF'        
        ---------------------------------------------------------------------------------------------
  inner join
                Products.dbo.Charge OCHG with (nolock)       
  on      XII.productcode    = OCHG.productcode
  and     XII.priceversion   = OCHG.Priceversion       
  and     XII.Chargetypecode = OCHG.Chargetypecode
  and     XII.Measurecode    = OCHG.Measurecode
  and     XII.FrequencyCode  = OCHG.FrequencyCode 
  Inner Join
          ORDERS.DBO.[Order]  O  with (nolock)  
  on      XII.Orderidseq     = O.Orderidseq  
  and     O.AccountIDseq     = coalesce(@IPVC_AccountID,O.AccountIDseq) 
  and     O.OrderIDseq       = coalesce(@IPVC_OrderID,O.OrderIDseq)   
  inner join
          CUSTOMERS.DBO.Company COM with (nolock)
  on      O.CompanyIDSeq = COM.IDSeq
  and     COM.IDSeq     = coalesce(@IPVC_CompanyID,COM.IDSeq)  
  left outer Join
          CUSTOMERS.DBO.Property PRPTY with (nolock)
  on     O.PropertyIDSeq  = PRPTY.IDSeq
  where  XII.HistoryFlag     = 0 
  and    XII.familycode      = Coalesce(@IPVC_FamilyCode,XII.familycode)
  group by XII.IDSeq, XII.ProductCode,XII.Measurecode,XII.Frequencycode,
           Coalesce(XII.MasterOrderItemIDSeq,XII.IDSeq),XII.Renewalcount,
           O.AccountIDSeq


  select S.OrderItemIDSeq,
         Max(S.CompanyIDSeq)                as CompanyIDSeq,        
         Max(S.ordersynchstartmonth)        as ordersynchstartmonth,         
         Max(S.PropertyIDSeq)               as PropertyIDSeq,        
         Max(S.AccountIDSeq)                as AccountIDSeq,
         Max(S.OrderIDSeq)                  as OrderIDSeq,
         Max(S.custombundlenameenabledflag) as custombundlenameenabledflag,
         MAX(S.Units)                       as Units,
         MAX(S.Beds)                        as Beds,
         Max(S.PPUPercentage)               as PPUPercentage,
         Max(S.UnitEffectiveQuantity)       as UnitEffectiveQuantity          
  into #Temp_REOrdersItemsToConsider
  from #Temp_REOrderItemsfirst S with (nolock)
  Where 
       S.Renewalcount >=
                      (select Max(XI.Renewalcount)
                       from   #Temp_REOrderItemsfirst XI with (nolock)
                       where  XI.OrderIDSeq      = S.OrderIDSeq
                       and    XI.OrderGroupIDSeq = S.OrderGroupIDSeq
                       and    XI.ProductCode     = S.ProductCode                                             
                       and    XI.Measurecode     = S.Measurecode
                       and    XI.Frequencycode   = S.Frequencycode                      
                       and    XI.MasterOrderItemIDSeq = S.MasterOrderItemIDSeq                          
                     )         
  group by S.OrderItemIDSeq
  ------------------------------------------------------------------------------------
  ---Step 1 : Get all Records from OrderItem that qualifies for Renewal.
  Insert into #TempREOrderItem(companyidseq,ordersynchstartmonth,propertyidseq,accountidseq,
                               orderitemidseq,orderidseq,ordergroupidseq, 
                               productcode,priceversion,
                               Units,Beds,PPUPercentage,
                               chargetypecode,frequencycode,measurecode,familycode,reportingtypecode,
                               custombundlenameenabledflag, 
                               -------------------------------------------
                               Quantity,MinUnits,MaxUnits,AllowProductCancelFlag,CredtCardPricingPercentage,
                               ShippingAndHandlingAmount,DollarMaximum,
                               PrintedOnInvoiceFlag,AttachmentFlag,CrossFireMaximumAllowableCallVolume,
                               ExcludeForBookingsFlag, 
                               StatusCode,CapMaxUnitsFlag,BillToAddressTypeCode,BillToDeliveryOptionCode,
                               ILFStartDate,ILFEndDate,  
                               -------------------------------------------                               
                               currentactivationstartdate,currentactivationenddate,
                               renewalactivationstartdate,
                               currentchargeamount,currentnetunitchargeamount,unitofmeasure,UnitEffectiveQuantity,effectivequantity,discountpercent,currentnetextchargeamount, 
                               socpriceversion,socchargeamount,
                               renewalchargeamount,renewaladjustedchargeamount,renewalstartdate,
                               DollarMinimumEnabledFlag,DollarMinimum,renewaltypecode,renewalcount,renewalnotes,masterorderitemidseq,renewalreviewedflag,renewedbyuseridseq,
                               fulfilledbyidseq,
                               FirstActivationStartDate,ModifiedByUserIDSeq
                            )
  select distinct
         OI.CompanyIDSeq           as CompanyIDSeq, 
         OI.ordersynchstartmonth   as ordersynchstartmonth,        
         OI.PropertyIDSeq          as PropertyIDSeq,         
         OI.AccountIDSeq           as AccountIDSeq,
         OI.OrderItemIDSeq         as OrderItemIDSeq,OI.OrderIDSeq          as OrderIDSeq          ,
         OI.OrderGroupIDSeq        as OrderGroupIDSeq,
         OI.ProductCode            as ProductCode   ,OI.PriceVersion        as PriceVersion        ,
         OI.Units                  as Units         ,OI.Beds                as Beds                , OI.PPUPercentage as PPUPercentage,
         OI.ChargeTypeCode         as ChargeTypeCode,OI.FrequencyCode       as FrequencyCode       ,
         OI.MeasureCode            as MeasureCode   ,
         OI.FamilyCode             as FamilyCode    ,OI.ReportingTypeCode   as ReportingTypeCode, 
         OI.custombundlenameenabledflag as custombundlenameenabledflag,                 
         ------------------------------------------------------------------------------------------
         OI.Quantity               as Quantity      ,
         OI.MinUnits               as MinUnits            ,OI.MaxUnits        as MaxUnits,
         OI.AllowProductCancelFlag as AllowProductCancelFlag,
         OI.CredtCardPricingPercentage as CredtCardPricingPercentage,
         OI.ShippingAndHandlingAmount  as ShippingAndHandlingAmount,
         OI.DollarMaximum              as DollarMaximum,
         OI.PrintedOnInvoiceFlag       as PrintedOnInvoiceFlag,OI.AttachmentFlag  as AttachmentFlag,        
         OI.CrossFireMaximumAllowableCallVolume as CrossFireMaximumAllowableCallVolume,
         1                                      as ExcludeForBookingsFlag,
         'PENR'                                 as StatusCode,
         OI.CapMaxUnitsFlag           as CapMaxUnitsFlag,
         OI.BillToAddressTypeCode     as BillToAddressTypeCode,  
         OI.BillToDeliveryOptionCode  as BillToDeliveryOptionCode,   
         OI.ILFStartDate                                             as ILFStartDate,
         OI.ILFEndDate                                               as ILFEndDate,         
         ------------------------------------------------------------------------------------------
         OI.currentactivationstartdate                               as currentactivationstartdate,
         OI.currentactivationenddate                                 as currentactivationenddate,
         OI.RenewalActivationStartDate                               as RenewalActivationStartDate,         
         ------------------------------------------------------------------------------------------
         OI.currentchargeamount                                      as currentchargeamount,
         OI.currentnetunitchargeamount                               as currentnetunitchargeamount,
         OI.unitofmeasure                                            as unitofmeasure,
         OI.UnitEffectiveQuantity                                    as UnitEffectiveQuantity,   
         OI.effectivequantity                                        as effectivequantity,
         0                                                           as discountpercent,
         OI.currentnetextchargeamount                                as currentnetextchargeamount, 
         ------------------------------------------------------------------------------------------
         OI.socpriceversion                                          as socpriceversion,
         OI.socchargeamount                                          as socchargeamount,
         ------------------------------------------------------------------------------------------
         OI.RenewalChargeAmount                                      as RenewalChargeAmount,
         OI.RenewalAdjustedChargeAmount                              as RenewalAdjustedChargeAmount,
         OI.RenewalStartDate                                         as RenewalStartDate,
         ------------------------------------------------------------------------------------------  
         OI.DollarMinimumEnabledFlag                                 as DollarMinimumEnabledFlag,
         OI.DollarMinimum                                            as DollarMinimum,
         OI.renewaltypecode                                          as renewaltypecode,
         OI.renewalcount                                             as renewalcount,
         OI.renewalnotes                                             as renewalnotes,
         OI.MasterOrderItemIDSeq                                     as MasterOrderItemIDSeq,
         OI.renewalreviewedflag                                      as renewalreviewedflag,
         OI.renewedbyuseridseq                                       as renewedbyuseridseq,
         OI.fulfilledbyidseq                                         as fulfilledbyidseq,
         ------------------------------------------------------------------------------------------
         OI.FirstActivationStartDate                                 as FirstActivationStartDate,
         OI.ModifiedByUserIDSeq                                      as ModifiedByUserIDSeq
  from (select distinct
               Max(TOIC.CompanyIDSeq)            as CompanyIDSeq, 
               Max(TOIC.ordersynchstartmonth)    as ordersynchstartmonth,        
               Max(TOIC.PropertyIDSeq)           as PropertyIDSeq,         
               Max(TOIC.AccountIDSeq)            as AccountIDSeq,
               XII.IDSeq                         as OrderItemIDSeq,
               Max(XII.OrderIDSeq)               as OrderIDSeq,
               Max(XII.OrderGroupIDSeq)          as OrderGroupIDSeq,
               Max(ltrim(rtrim(XII.ProductCode))) as ProductCode,
               Max(XII.PriceVersion)             as PriceVersion,
               Max(TOIC.Units)                   as Units,
               Max(TOIC.Beds)                    as Beds,
               Max(TOIC.PPUPercentage)           as PPUPercentage,
               Max(XII.ChargeTypeCode)           as ChargeTypeCode,
               Max(XII.FrequencyCode)            as FrequencyCode,
               Max(XII.MeasureCode)              as MeasureCode,
               Max(XII.FamilyCode)               as FamilyCode,               
               coalesce(Max(CHG.ReportingTypeCode),Max(XII.ReportingTypeCode))   as ReportingTypeCode,   
               Max(TOIC.custombundlenameenabledflag)                             as custombundlenameenabledflag,             
               ------------------------------------------------------------------------------------------
               Max(XII.Quantity)                       as Quantity,
               Max(XII.MinUnits)                       as MinUnits,
               Max(XII.MaxUnits)                       as MaxUnits,
               Max(convert(int,XII.AllowProductCancelFlag)) as AllowProductCancelFlag,
               Max(XII.CredtCardPricingPercentage)          as CredtCardPricingPercentage,              
               Max(XII.ShippingAndHandlingAmount)           as ShippingAndHandlingAmount,
               Max(XII.DollarMaximum)                       as DollarMaximum,
               Max(convert(int,XII.PrintedOnInvoiceFlag))   as PrintedOnInvoiceFlag,
               Max(convert(int,XII.AttachmentFlag))         as AttachmentFlag,
               Max(XII.CrossFireMaximumAllowableCallVolume) as CrossFireMaximumAllowableCallVolume,
               Max(convert(int,XII.CapMaxUnitsFlag))        as CapMaxUnitsFlag,
               Max(XII.BillToAddressTypeCode)               as BillToAddressTypeCode,
               Max(XII.BillToDeliveryOptionCode)            as BillToDeliveryOptionCode,     
               Max(XII.ILFStartDate)                        as ILFStartDate,
               Max(XII.ILFEndDate)                          as ILFEndDate, 
               ------------------------------------------------------------------------------------------ 
               Max(XII.activationstartdate)                                      as currentactivationstartdate,
               Max(XII.activationenddate)                                        as currentactivationenddate,
               (case when (Max(XII.RenewalStartDate) is not null and 
                           Max(XII.RenewalStartDate) >= Max(XII.ActivationEndDate)
                          )
                       then Max(XII.RenewalStartDate)
                     else dateadd(day,1,Max(XII.ActivationEndDate)) 
                end)                                                       as RenewalActivationStartDate,
               (case when (Max(XII.RenewalStartDate) is not null OR
                           Max(XII.renewaltypecode) = 'MRNW'
                          ) 
                       then 1
                      else 0
                end)                                                       as allowchangerenewalstartdateflag,
               ------------------------------------------------------------------------------------------
               /*
                (Max(XII.chargeamount)/
                (case when Max(XII.effectivequantity)=0 
                         then 1
                      else Max(XII.effectivequantity) 
                 end)
                )                                                            as currentchargeamount,
               */
               Max(XII.chargeamount)                                        as currentchargeamount,
               Max(convert(float,(convert(float,XII.chargeamount) - ((convert(float,XII.chargeamount) * convert(float,XII.discountpercent))/100))))
                                                                            as currentnetunitchargeamount,
               Max(XII.unitofmeasure)                                       as unitofmeasure,
               Max(TOIC.UnitEffectiveQuantity)                              as UnitEffectiveQuantity,   
               Max(XII.effectivequantity)                                   as effectivequantity,               
               Max(XII.netchargeamount)                                     as currentnetextchargeamount, 
               ------------------------------------------------------------------------------------------
               coalesce(Max(CHG.priceversion),Max(XII.priceversion))        as socpriceversion,
               coalesce(Max(CHG.chargeamount),Max(XII.chargeamount))        as socchargeamount,
               ------------------------------------------------------------------------------------------
               (case when  (Max(convert(int,XII.RenewalFlag)) = 0) and 
                            (Max(XII.RenewedFromOrderItemIDSeq) is null)
                         then Max(XII.Chargeamount)
                      else  Max(XII.RenewalChargeAmount)
                 end)                                                        as RenewalChargeAmount,
                Max(XII.RenewalAdjustedChargeAmount)                         as RenewalAdjustedChargeAmount,
                Max(XII.RenewalStartDate)                                    as RenewalStartDate,
               ------------------------------------------------------------------------------------------ 
                coalesce(Max(convert(int,CHG.DollarMinimumEnabledFlag)),Max(convert(int,OCHG.DollarMinimumEnabledFlag)),0) 
                                                                             as DollarMinimumEnabledFlag, 
                Max(coalesce(XII.DollarMinimum,CHG.DollarMinimum,OCHG.DollarMinimum,0.00))
                                                                             as DollarMinimum,
                Max(XII.renewaltypecode)                                     as renewaltypecode,
                Max(XII.renewalcount)                                        as renewalcount,
                Max(XII.renewalnotes)                                        as renewalnotes,
                Coalesce(XII.MasterOrderItemIDSeq,XII.IDSeq)                 as MasterOrderItemIDSeq,
                Max(Convert(int,XII.renewalreviewedflag))                    as renewalreviewedflag,
                Max(convert(int,XII.renewedbyuseridseq))                     as renewedbyuseridseq,
                Max(convert(int,XII.fulfilledbyidseq))                       as fulfilledbyidseq,
               ------------------------------------------------------------------------------------------
                Min(XII.FirstActivationStartDate)                            as FirstActivationStartDate,
                Max(XII.ModifiedByUserIDSeq)                                 as ModifiedByUserIDSeq
        from   ORDERS.dbo.[Orderitem] XII with (nolock)
        inner join 
               #Temp_REOrdersItemsToConsider TOIC with (nolock)
        on     XII.IDseq           = TOIC.OrderItemIDSeq 
        and    XII.HistoryFlag     = 0
        inner join
                Products.dbo.Charge OCHG with (nolock)       
        on      XII.productcode    = OCHG.productcode
        and     XII.priceversion   = OCHG.Priceversion        
        and     XII.Chargetypecode = OCHG.Chargetypecode
        and     XII.Measurecode    = OCHG.Measurecode
        and     XII.FrequencyCode  = OCHG.FrequencyCode             
        Left outer Join 
              Products.dbo.Charge CHG with (nolock)
        on    XII.ProductCode    = CHG.ProductCode        
        and   CHG.disabledflag   = 0
        and   XII.Chargetypecode = CHG.Chargetypecode
        and   XII.Measurecode    = CHG.Measurecode
        and   XII.FrequencyCode  = CHG.FrequencyCode            
        GROUP BY XII.IDSeq,XII.OrderIDSeq,XII.OrderGroupIDSeq,XII.MasterOrderItemIDSeq
       ) OI    
  --------------------------------------------------------------------------------------
  ---Step 2: Get all Active Price caps for all Companies and Properties and Products in 
  ---        #TempREOrderItem
  --------------------------------------------------------------------------------------
  ---Defect Defect8890 : PricecapProperties will also include Corporate/PMCs and also Sites.
  /*
  Insert into #TempREpriceCapholdingTable(companyidseq,propertyidseq,pricecapflag,pricecapbasiscode,
                                          PriceCapPercent,PriceCapStartDate,PriceCapEndDate,productcode)
  select S.companyidseq,S.Propertyidseq,S.pricecapflag,S.pricecapbasiscode,S.PriceCapPercent,
         S.PriceCapStartDate,S.PriceCapEndDate,S.ProductCode
  from (select    PC.companyidseq as companyidseq,
                  NULL as propertyidseq,1 as pricecapflag,PC.pricecapbasiscode,PC.PriceCapPercent,
                  PC.PriceCapStartDate, PC.PriceCapEndDate,
                  ltrim(rtrim(PCP.ProductCode)) as ProductCode
        From   CUSTOMERS.dbo.PriceCap PC With (nolock)
        inner join
               CUSTOMERS.dbo.PriceCapProducts PCP With (nolock)
        on     PC.IDSeq = PCP.PricecapIDSeq 
        and    PC.companyidseq = PCP.companyidseq
        and    PC.ActiveFlag = 1
        and    PC.companyidseq in (select X.CompanyIDSeq from #TempREOrderItem X with (nolock))
        and    ltrim(rtrim(PCP.ProductCode)) in (select ltrim(rtrim(T.productcode)) from #TempREOrderItem T with (nolock))
        where  PC.ActiveFlag = 1
        ---------------------
        UNION
        ---------------------
        select    PC.companyidseq as companyidseq,
                  PCPRP.Propertyidseq as propertyidseq,1 as pricecapflag,PC.pricecapbasiscode,PC.PriceCapPercent,
                  PC.PriceCapStartDate, PC.PriceCapEndDate,
                  ltrim(rtrim(PCP.ProductCode)) as ProductCode
        From   CUSTOMERS.dbo.PriceCap PC With (nolock)
        inner join
               CUSTOMERS.dbo.PriceCapProducts PCP With (nolock)
        on     PC.IDSeq = PCP.PricecapIDSeq 
        and    PC.companyidseq = PCP.companyidseq
        and    PC.ActiveFlag = 1
        and    PC.companyidseq in (select X.CompanyIDSeq from #TempREOrderItem X with (nolock))
        and    ltrim(rtrim(PCP.ProductCode)) in (select ltrim(rtrim(T.productcode)) from #TempREOrderItem T with (nolock))
        inner join
               CUSTOMERS.dbo.PriceCapProperties PCPRP With (nolock)
        on     PC.IDSeq          = PCPRP.PricecapIDSeq
        and    PC.companyidseq   = PCPRP.companyidseq  
        and    PCPRP.companyidseq  in (select X.CompanyIDSeq  from #TempREOrderItem X with (nolock))
        and    PCPRP.PropertyIDSeq in (select X.PropertyIDSeq from #TempREOrderItem X with (nolock))
        and    PC.ActiveFlag     = 1
        and    PCP.PricecapIDSeq = PCPRP.PricecapIDSeq
        and    PCP.companyidseq  = PCPRP.companyidseq
       ) S
  group by S.companyidseq,S.Propertyidseq,S.pricecapflag,S.pricecapbasiscode,S.PriceCapPercent,
         S.PriceCapStartDate,S.PriceCapEndDate,S.ProductCode
  */

  ---Defect Defect8890 : PricecapProperties will also include Corporate/PMCs and also Sites.
  Insert into #TempREpriceCapholdingTable(companyidseq,propertyidseq,pricecapflag,pricecapbasiscode,
                                          PriceCapPercent,PriceCapStartDate,PriceCapEndDate,productcode)
  select    PC.companyidseq as companyidseq,
            coalesce(PCPRP.Propertyidseq,PC.companyidseq) as propertyidseq,1 as pricecapflag,PC.pricecapbasiscode,PC.PriceCapPercent,
            PC.PriceCapStartDate, PC.PriceCapEndDate,
            ltrim(rtrim(PCP.ProductCode)) as ProductCode
  From   CUSTOMERS.dbo.PriceCap PC With (nolock)
  inner join
         CUSTOMERS.dbo.PriceCapProducts PCP With (nolock)
  on     PC.IDSeq = PCP.PricecapIDSeq 
  and    PC.companyidseq = PCP.companyidseq
  and    PC.ActiveFlag = 1
  inner join
         #TempREOrderItem X with (nolock)
  on     PC.companyidseq = X.companyidseq  
  and    ltrim(rtrim(PCP.ProductCode)) = X.ProductCode  
  inner join
         CUSTOMERS.dbo.PriceCapProperties PCPRP With (nolock)
  on     PC.IDSeq          = PCPRP.PricecapIDSeq
  and    PC.companyidseq   = PCPRP.companyidseq  
  and    PCPRP.companyidseq  = X.companyidseq
  and    coalesce(PCPRP.Propertyidseq,PC.companyidseq,'') = coalesce(X.Propertyidseq,X.companyidseq,'')
  and    PC.ActiveFlag     = 1
  and    PCP.PricecapIDSeq = PCPRP.PricecapIDSeq
  and    PCP.companyidseq  = PCPRP.companyidseq
  group by PC.companyidseq,coalesce(PCPRP.Propertyidseq,PC.companyidseq),PC.pricecapbasiscode,PC.PriceCapPercent,
           PC.PriceCapStartDate, PC.PriceCapEndDate,ltrim(rtrim(PCP.ProductCode))
  -------------------------------------------------------------------------------------------------
  ---Step 3: Update #TempREOrderItem with Price caps from Step 2.
  -------------------------------------------------------------------------------------------------
  Update T
  set    T.pricecapflag     = 1,
         T.pricecapbasiscode= S.pricecapbasiscode,
         T.PriceCapPercent  = S.PriceCapPercent,
         T.PriceCapStartDate= S.PriceCapStartDate,
         T.PriceCapEndDate  = S.PriceCapEndDate
  from   #TempREpriceCapholdingTable S with (nolock)
  inner join
         #TempREOrderItem T  with (nolock)
  on     T.ProductCode = S.ProductCode
  and    S.CompanyIDSeq   = T.CompanyIDSeq
  and    Coalesce(S.Propertyidseq,S.companyidseq,'')=Coalesce(T.propertyidseq,T.companyidseq,'')
  and    (T.RenewalActivationStartDate >= S.PriceCapStartDate) 
  and    (T.RenewalActivationStartDate <= S.PriceCapEndDate)
  -------------------------------------------------------------------------------------------------
  ---Step 4: Depending on Nature of price cap,   
  Update D
  set   D.renewaldiscchargeamount = (case 
                                       when (D.pricecapflag = 1)                                   and
                                            (D.pricecapbasiscode<>'LIST')                          and
                                            (D.RenewalActivationStartDate >= D.PriceCapStartDate)  and
                                            (D.RenewalActivationStartDate <= D.PriceCapEndDate)    
                                            --->and (D.currentnetextchargeamount > 0) --> PriceCapPercent 0 is allowable.
                                        then convert(float, 
                                                     (convert(float,D.currentnetunitchargeamount) + ((convert(float,D.currentnetunitchargeamount)*D.PriceCapPercent)/(100)
                                                                                     )
                                                      )
                                                     )
                                       else NULL
                                      end),
        D.RenewalChargeAmount = 
                                (case when (D.pricecapflag = 1)                               and
                                        (D.pricecapbasiscode='LIST')                          and
                                        (D.RenewalActivationStartDate >= D.PriceCapStartDate) and
                                        (D.RenewalActivationStartDate <= D.PriceCapEndDate)
                                      then  convert(float, 
                                                     (convert(float,D.RenewalChargeAmount) + ((convert(float,D.RenewalChargeAmount)*D.PriceCapPercent)/(100)
                                                                                     )
                                                      )
                                                     )                                      
                                    else D.SOCChargeAmount
                               end), 
       D.PriceVersion         = D.SOCPriceVersion                
  from #TempREOrderItem D with (nolock)
  ------------------------------------------------------------------------------------------
  ---Step 5: Determine the new product discount percentage and update #TempREOrderItem  
  /*
  Update D
  set    D.DiscountPercent = (convert(float,(D.socnetextchargeamount - D.renewalnetextchargeamount))* (100)
                                  /
                              convert(float,(case when D.socnetextchargeamount=0 then 1 else D.socnetextchargeamount end))
                             )
  from #TempREOrderItem D with (nolock)
  */


  Update D
  set    D.DiscountPercent = (convert(float,(D.socchargeamount - D.renewaladjustedchargeamountdisplay))* (100)
                                  /
                              convert(float,(case when D.socchargeamount=0 then 1 else D.socchargeamount end))
                             )
  from #TempREOrderItem D with (nolock)
  -------******************************************************************-------------
  ---Step 6 : Insert Renewal Records into Orders.dbo.OrderItem Table.
  -------******************************************************************-------------
  insert into ORDERS.dbo.OrderItem 
                        (OrderIDSeq,OrderGroupIDSeq,
                         ProductCode,PriceVersion,units,beds,ppupercentage,
                         ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,ReportingTypeCode,
                         ------------------------------------------------------
                         Quantity,MinUnits,MaxUnits,AllowProductCancelFlag,CredtCardPricingPercentage,
                         ShippingAndHandlingAmount,DollarMinimum,DollarMaximum,
                         PrintedOnInvoiceFlag,AttachmentFlag,CrossFireMaximumAllowableCallVolume,
                         ExcludeForBookingsFlag,
                         StatusCode,CapMaxUnitsFlag,BillToAddressTypeCode,BillToDeliveryOptionCode,
                         ILFStartDate,ILFEndDate,
                         ------------------------------------------------------
                         ChargeAmount,UnitOfMeasure,EffectiveQuantity,ExtChargeAmount,DiscountPercent,DiscountAmount,NetUnitChargeAmount,NetChargeAmount,
                         ActivationStartDate,ActivationEndDate,StartDate,EndDate,
                         LastBillingPeriodFromDate,LastBillingPeriodToDate,
                         TotalDiscountPercent,TotalDiscountAmount,
                         ------------------------------------------------------
                         RenewalTypeCode,RenewalReviewedFlag,RenewalFlag,RenewalCount,MasterOrderItemIDSeq,RenewedFromOrderItemIDSeq,
                         RenewalChargeAmount,RenewalAdjustedChargeAmount,RenewalStartDate,RenewedByUserIDSeq,RenewalNotes,
                         ------------------------------------------------------
                         FirstActivationStartDate,
                         fulfilledbyidseq,FulfilledDate,
                         CreatedByIDSeq,CreatedDate,ModifiedByUserIDSeq,ModifiedDate,SystemLogDate 
                        )
  select D.OrderIDSeq,D.OrderGroupIDSeq,
         D.ProductCode,D.PriceVersion,
         D.units,D.beds,D.ppupercentage,
         D.ChargeTypeCode,D.FrequencyCode,D.MeasureCode,D.FamilyCode,D.ReportingTypeCode,
         ------------------------------------------------------
         D.Quantity,D.MinUnits,D.MaxUnits,D.AllowProductCancelFlag,
         D.CredtCardPricingPercentage,
         D.ShippingAndHandlingAmount,D.DollarMinimum,D.DollarMaximum,
         D.PrintedOnInvoiceFlag,D.AttachmentFlag,
         D.CrossFireMaximumAllowableCallVolume,
         D.ExcludeForBookingsFlag,
         'PENR' as StatusCode,D.CapMaxUnitsFlag,
         D.BillToAddressTypeCode,D.BillToDeliveryOptionCode,
         D.ILFStartDate,D.ILFEndDate,
         ------------------------------------------------------
         D.socchargeamount                            as ChargeAmount,
         D.UnitOfMeasure                              as UnitOfMeasure,
         D.EffectiveQuantity                          as EffectiveQuantity,
         convert(numeric(30,2),D.socnetextchargeamount)
                                                      as ExtChargeAmount,
         D.DiscountPercent                            as DiscountPercent,
         convert(numeric(30,2),
                  (D.socnetextchargeamount
                     -
                   D.renewalnetextchargeamount
                   ) 
                 )                                    as DiscountAmount,
         D.renewaladjustedchargeamountdisplay         as NetUnitChargeAmount,
         convert(numeric(30,2),D.renewalnetextchargeamount)
                                                      as NetChargeAmount,
         D.renewalactivationstartdate                 as ActivationStartDate,
         D.renewalactivationenddate                   as ActivationEndDate,
         D.renewalactivationstartdate                 as StartDate,
         D.renewalactivationenddate                   as EndDate,
         NULL                                         as LastBillingPeriodFromDate,
         NULL                                         as LastBillingPeriodToDate,
         D.DiscountPercent                            as TotalDiscountPercent,
         convert(numeric(30,2),
                  (D.socnetextchargeamount
                     -
                   D.renewalnetextchargeamount
                   ) 
                 )                                    as TotalDiscountAmount,
         ------------------------------------------------------
         D.RenewalTypeCode                            as RenewalTypeCode,
         0                                            as RenewalReviewedFlag,
         1                                            as RenewalFlag,
         (D.RenewalCount+1)                           as RenewalCount,
         D.MasterOrderItemIDSeq                       as MasterOrderItemIDSeq,
         D.orderitemidseq                             as RenewedFromOrderItemIDSeq,
         D.RenewalChargeAmount                        as RenewalChargeAmount,
         NULL                                         as RenewalAdjustedChargeAmount,
         NULL                                         as RenewalStartDate,
         NULL                                         as RenewedByUserIDSeq,
         NULL                                         as RenewalNotes,
         ------------------------------------------------------         
         D.FirstActivationStartDate                   as FirstActivationStartDate,
         coalesce(D.RenewedByUserIDSeq,@IPBI_UserIDSeq,D.fulfilledbyidseq,-1)
                                                      as fulfilledbyidseq,
         @LDT_SystemDate                              as FulfilledDate,
         coalesce(D.RenewedByUserIDSeq,@IPBI_UserIDSeq,D.fulfilledbyidseq,-1) 
                                                      as CreatedByIDSeq,
         @LDT_SystemDate                              as CreatedDate,
         NULL                                         as ModifiedByUserIDSeq,
         NULL                                         as ModifiedDate,
         @LDT_SystemDate                              as SystemLogDate
  from #TempREOrderItem D with (nolock)  

  select @LI_OrderItemsRenewedCount = count(1) from #TempREOrderItem D with (nolock);
  ----------------------------------------------------------------------
  -- END OF Create renewal entries
  ---------------------------------------------------------------------- 
  update OIHistory
  set    RenewalTypeCode = 'DRNW',
         HistoryFlag     = 1, 
         HistoryDate     = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate
  from   ORDERS.dbo.OrderItem OIHistory with (nolock)
  inner join
         #TempREOrderItem       TOI  with (nolock)
  on     OIHistory.OrderIDSeq       = TOI.OrderIDSeq
  and    OIHistory.OrderGroupIDSeq  = TOI.OrderGroupIDSeq
  and    OIHistory.renewalcount     = TOI.renewalcount
   and    ((TOI.custombundlenameenabledflag  = 1)
            OR
           (OIHistory.IDSeq = TOI.OrderItemIDSeq and TOI.custombundlenameenabledflag  = 0)
          );  
  --Step 7 : Expire OLD Order Items 
  Exec ORDERS.dbo.uspORDERS_ExpireOldOrdersandFulfillRenewals @IPI_FulfillDays=@IPI_FulfillDays;
  ----------------------------------------------------------------------
  --Step 8: Pricing Engine Call is Integrated here
  ----------------------------------------------------------------------
  Insert into #LT_Bundles(orderid,groupid)
  select OrderIDSeq as orderid,OrderGroupIDSeq as groupid
  from   #TempREOrderItem (nolock)
  group by OrderIDSeq,OrderGroupIDSeq
  order  by OrderIDSeq ASC,OrderGroupIDSeq ASC
  select @LI_Min=1,@LI_Max = count(*) from #LT_Bundles with (nolock)
  while  @LI_Min <= @LI_Max
  begin
    select @LVC_OrderID=orderid,@LI_GroupID=groupid 
    from  #LT_Bundles with (nolock)
    where SEQ = @LI_Min
    exec ORDERS.dbo.uspORDERS_SyncOrderGroupAndOrderItem @IPVC_OrderID=@LVC_OrderID,@IPI_GroupID=@LI_GroupID
    select @LVC_OrderID=NULL,@LI_GroupID=NULL
    select @LI_Min = @LI_Min+1
  end  
  select @LI_Min=1,@LI_Max=0
  ---------------------------------------------------------------------- 
  UPDATE D
  set    D.neworderitemidseq = S.IDSeq
  from   #TempREOrderItem     D with (nolock)
  inner join
         ORDERS.dbo.Orderitem S with (nolock)
  on     D.OrderIDSeq           = S.OrderIDSeq
  and    D.ordergroupidseq      = S.ordergroupidseq
  and    D.MasterOrderItemIDSeq = S.MasterOrderItemIDSeq
  and    D.orderitemidseq       = S.RenewedFromOrderItemIDSeq
  and    (D.renewalcount+1)     = S.renewalcount

  DELETE OIN
  from   Orders.dbo.OrderItemNote  OIN with (nolock)
  Inner join
         #TempREOrderItem          S   with (nolock)
  on     OIN.OrderIDSeq       = S.OrderIDSeq
  and    OIN.OrderItemIDSeq   = S.NewOrderItemIDSeq
  and    S.NewOrderItemIDSeq  is not null
  and    OIN.MandatoryFlag    = 0

  Insert into Orders.dbo.OrderItemNote(OrderIDSeq,OrderItemIDSeq,OrderItemTransactionIDSeq,
                                       Title,Description,MandatoryFlag,PrintOnInvoiceFlag,SortSeq,CreatedDate)
  select OIN.OrderIDSeq,S.NewOrderItemIDSeq,null OrderItemTransactionIDSeq,
         OIN.Title,OIN.Description,OIN.MandatoryFlag,OIN.PrintOnInvoiceFlag,OIN.SortSeq,@LDT_SystemDate AS CreatedDate
  from   Orders.dbo.OrderItemNote  OIN with (nolock)
  Inner join
         #TempREOrderItem         S   with (nolock)
  on     OIN.OrderIDSeq       = S.OrderIDSeq
  and    OIN.OrderItemIDSeq   = S.OrderItemIDSeq
  and    S.NewOrderItemIDSeq  is not null
  and    OIN.MandatoryFlag    = 0
  order  by OIN.OrderIDSeq ASC,S.NewOrderItemIDSeq ASC,OIN.SortSeq ASC
  -----------------------------------------------------------------------------------------  
  --Step 10:Final Cleanup  
  -----------------------------------------------------------------------------------------
  drop table #TempREpriceCapholdingTable
  drop table #Temp_REOrderItemsfirst
  drop table #Temp_REOrdersItemsToConsider
  drop table #TempREOrderItem  
  drop table #LT_Bundles 
  -----------------------------------------------------------------------------------------
  ---Final Select to UI:
  select @LI_OrderItemsRenewedCount as OrderItemsRenewedCount
  -----------------------------------------------------------------------------------------
END
GO
