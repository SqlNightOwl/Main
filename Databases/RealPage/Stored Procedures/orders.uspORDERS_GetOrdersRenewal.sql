SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- Exec uspORDERS_GetOrdersRenewal @IPVC_CompanyID = 'C0804009675',@IPVC_AccountID = 'A0804000178'
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_GetOrdersRenewal
-- Description     : Get Detail of Upcoming Renewal
-- Input Parameters: 
-- Code Example    : Exec ORDERS.dbo.[uspORDERS_GetOrdersRenewal] '','A0000018460',2
-- Revision History:
-- Author          : SRS
-- 04/15/2007      : Stored Procedure Created.
-- 07/06/2011      : DNETHUNURI -Modifications for defect#729
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetOrdersRenewal](@IPI_PageNumber               bigint      =1, 
                                                    @IPI_RowsPerPage              bigint      =21,
                                                    @IPI_SearchByBillingCyleFlag  int         =1,
                                                    @IPVC_StartDate               varchar(50) ='',
                                                    @IPVC_EndDate                 varchar(50) ='',                                                   
                                                    @IPVC_BillingCycleDate        varchar(50) ='',
                                                    @IPVC_CompanyID               varchar(50) ='',
                                                    @IPVC_AccountID               varchar(50) ='',                                                   
                                                    @IPVC_CompanyName             varchar(255)='',
                                                    @IPVC_AccountName             varchar(255)='',	
                                                    @IPVC_ProductName             varchar(255)='',  
                                                    @IPVC_OrderID                 varchar(50) ='',	
                                                    @IPI_IncludeProperties        int         =1,				   
                                                    @IPVC_RenewalReviewedFlag     varchar(1)  ='',
                                                    @IPVC_RenewalTypeCode         varchar(5)  ='',
                                                    @IPVC_FamilyCode              varchar(10) ='',
                                                    @IPVC_SortBy                  varchar(100)='renewaldate'                                                    
                                                    )
AS
BEGIN
  set nocount on;  
  set quoted_identifier on;
  set ansi_warnings off;
  ------------------------------------------------------------------------------------
  -- Declare Local Variables 
  Declare @LBI_TotalRecords bigint
  Declare @LD_StartDate    datetime
  Declare @LD_EndDate      datetime
  declare @LBI_Counter      bigint  
  declare @LBI_MinRowNumber bigint
  declare @LBI_MaxRowNumber bigint
 
  ---local variable Initialization
  set @LBI_Counter = 0
  select @LD_StartDate = convert(datetime,convert(varchar(50),'01/01/1900',101)) ,
         @LD_EndDate   = convert(datetime,convert(varchar(50),'01/01/1900',101))
  -------------------------------------------------------   
  if (@IPI_SearchByBillingCyleFlag=1) --> Case 1: Search by Billing Cycle Date Only
  begin
    -- Since renewals are done 60 days in advance, Enddate will be @IPVC_BillingCycleDate+60
    if (isdate(@IPVC_BillingCycleDate)=1 and @IPVC_BillingCycleDate <> '')
    begin
      select @LD_StartDate = convert(datetime,convert(varchar(50),'01/01/1900',101))   
      select @IPVC_BillingCycleDate = convert(varchar(50),convert(datetime,@IPVC_BillingCycleDate),101)
      select @LD_EndDate   = (case when ((day(convert(datetime,@IPVC_BillingCycleDate))= 15))
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
      select @LD_StartDate = convert(datetime,convert(varchar(50),'01/01/1900',101)) 
      select @LD_EndDate   = convert(datetime,convert(varchar(50),'01/01/1900',101)) 
    end 
  end
  ----------------------------------------- 
  if (@IPI_SearchByBillingCyleFlag=0) --> Case 2 : Search by StartDate and End Date
  begin
    if (isdate(@IPVC_StartDate)=1 and @IPVC_StartDate <> '')
    begin
      select @LD_StartDate  = convert(datetime,convert(varchar(50),@IPVC_StartDate,101)) 
    end
    else
    begin
      select @LD_StartDate  = convert(datetime,convert(varchar(50),'01/01/1900',101)) 
    end

    if (isdate(@IPVC_EndDate)=1 and @IPVC_EndDate <> '')
    begin
      select @LD_EndDate = convert(datetime,convert(varchar(50),@IPVC_EndDate,101))
    end 
    else
    begin    
      select @LD_EndDate   = convert(datetime,convert(varchar(50),'01/01/1900',101)) 
    end
  end  
  ------------------------------------------------------------------------------------
  set @IPVC_CompanyID           = nullif(@IPVC_CompanyID, '')
  set @IPVC_AccountID           = nullif(@IPVC_AccountID, '')    
  set @IPVC_RenewalReviewedFlag = nullif(@IPVC_RenewalReviewedFlag,'') -- Values are 1,0 or '' 
  set @IPVC_OrderID             = nullif(@IPVC_OrderID,'')
  set @IPVC_FamilyCode          = nullif(@IPVC_FamilyCode,'')
  select @IPVC_RenewalTypeCode  = (Case when (@IPVC_RenewalTypeCode like 'All%') then NULL
                                        else nullif(@IPVC_RenewalTypeCode,'') 
                                   end) --> if @IPVC_RenewalTypeCode is All or ALL (Manual & Automatic), UI will already pass ''. This is just for sanity check.
  ------------------------------------------------------------------------------------ 
  Create table #TempUIpriceCapholdingTable
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

  Create table #TempUIOrderItem (SortSeq                     bigint not null identity(1,1) primary key,
                                 companyidseq                varchar(50),
                                 companyname                 varchar(255),
                                 propertyidseq               varchar(50),
                                 propertyname                varchar(255),
                                 accountidseq                varchar(50),
                                 accountname                 as coalesce(propertyname,companyname),
                                 productdisplayname          varchar(255),
                                 orderidseq                  varchar(50),
                                 ordergroupidseq             bigint,
                                 orderitemidseq              bigint,  
                                 productcode                 varchar(50),
                                 priceversion                numeric(18,0), 
                                 chargetypecode              varchar(3),
                                 frequencycode               varchar(6),
                                 frequencyname               varchar(50),
                                 measurecode                 varchar(6),
                                 measurename                 varchar(50),
                                 familycode                  varchar(3), 
                                 reportingtypecode           varchar(20),                                 
                                 custombundlenameenabledflag int    not null default (0),
                                 ordergroupname              varchar(255),
                                 frequencymultiplier         int    not null default (1),
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
                                 yearlycurrentchargeamount   as (currentchargeamount * frequencymultiplier), 
                                 ExtChargeAmount             money not null default (0),  
                                 currentnetunitchargeamount  money not null default (0),  
                                 unitofmeasure               numeric(30,5) not null default (0.00),
                                 UnitEffectiveQuantity       numeric(30,5) not null default (0.00), 
                                 effectivequantity           numeric(30,5) not null default (0.00),                                   
                                 discountpercent             float not null default (0.00),                                 
                                 currentnetextchargeamount   numeric(30,2) not null default (0), 
                                 yearlycurrentnetextchargeamount as (currentnetextchargeamount * frequencymultiplier),                                 
                                 ------------------------------------------------------------------ 
                                 socpriceversion             numeric(18,0),
                                 socchargeamount             money  not null default (0),  
                                 yearlysocchargeamount       as (socchargeamount * frequencymultiplier), 
                                 socnetextchargeamount       as (socchargeamount * effectivequantity),
                                 yearlysocnetextchargeamount as (socchargeamount * effectivequantity) * (frequencymultiplier),
                                 ------------------------------------------------------------------
                                 renewalchargeamount         money null,
                                 renewaldiscchargeamount     money null,
                                 renewaladjustedchargeamount money null,
                                 renewalstartdate            datetime null, 
                                 allowchangerenewalstartdateflag int not null default 0,
                                 nonuseradjustedchargeamountdisplay  as  convert(money,coalesce(renewaldiscchargeamount,renewalchargeamount,socchargeamount)),   
                                 renewaladjustedchargeamountdisplay  as  convert(money,coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)), 
                                 yearlyrenewaladjustedchargeamountdisplay
                                                                     as  convert(money,(coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount))
                                                                                    *
                                                                          (frequencymultiplier)
                                                                         ) ,
                                 /* renewalnetextchargeamount           as   convert(numeric(30,2),
                                                                                       (convert(money,coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)) 
                                                                                          *
                                                                                        effectivequantity
                                                                                       )
                                                                                     ),  
                                 yearlyrenewalnetextchargeamount     as   convert(numeric(30,2),
                                                                                 (convert(money,coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)) 
                                                                                      *
                                                                                  effectivequantity
                                                                                 )
                                                                               ) * (frequencymultiplier),
                                 */
                                 renewalnetextchargeamount          as    (case when  ((DollarMinimumEnabledFlag=1)
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

                                 yearlyrenewalnetextchargeamount    as    (case when  ((DollarMinimumEnabledFlag=1)
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
                                                                            end) * (frequencymultiplier),                               
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
                                 ---------------------------------------------------------------
                                 RenewalUserOverrideFlag     int default (0),
                                 PriceCapFlag                int default (0),
                                 pricecapbasiscode           varchar(50) null default 'LIST',
                                 PriceCapStartDate           datetime NULL,
                                 PriceCapEndDate             datetime NULL,
                                 PriceCapPercent             float not null default 0.00,
                                 ---------------------------------------------------------------
                                 DollarMinimumEnabledFlag    int           not null default(0),
                                 DollarMinimum               numeric(30,2)  Null,
                                ) ON [PRIMARY]  

  
 
  /*
  CREATE NONCLUSTERED INDEX [INCX_#TempUIOrderItem] on #TempUIOrderItem([CompanyIDSeq] ASC,[PropertyIDSeq] ASC,companyname,propertyname,accountname) 
  INCLUDE(accountidseq,
                                           orderidseq,ordergroupidseq,orderitemidseq,
                                           frequencyname,measurename,productdisplayname,                                           
                                           currentactivationstartdate,currentactivationenddate,renewalactivationstartdate,
                                           --renewalactivationenddate,
                                           currentchargeamount,unitofmeasure,effectivequantity,currentnetextchargeamount,yearlycurrentnetextchargeamount,
                                           socchargeamount,socnetextchargeamount,yearlysocnetextchargeamount,
                                           renewalchargeamount,renewaladjustedchargeamountdisplay,renewalnetextchargeamount,yearlyrenewalnetextchargeamount,
                                           renewaltypename,renewalreviewedflag,renewalcount,renewalnotes)
  WITH PAD_INDEX, FILLFACTOR = 100 
  */
  
  
  Create table #TempUIRenewalOrderItemFinal
                                (RowNumber                   bigint not null default (0),
                                 SortSeq                     bigint not null identity(1,1),       
                                 companyidseq                varchar(50),
                                 companyname                 varchar(255),
                                 propertyidseq               varchar(50),
                                 propertyname                varchar(255),
                                 accountidseq                varchar(50),
                                 accountname                 varchar(255),
                                 internalname                varchar(255),
                                 productdisplayname          varchar(255),
                                 orderidseq                  varchar(50), 
                                 ordergroupidseq             bigint,                                
                                 orderitemidseq              bigint,                                   
                                 frequencyname               varchar(50),
                                 measurename                 varchar(50),                                 
                                 recordtype                  varchar(5) not null default 'PR',
                                 custombundlenameenabledflag int not null default (0),                                
                                 --------------------------------------------------------
                                 currentactivationstartdate  varchar(50),
                                 currentactivationenddate    varchar(50), 
                                 renewalactivationstartdate  varchar(50),
                                 renewalactivationenddate    varchar(50), 
                                 allowchangerenewalstartdateflag int null,
                                 -----------------------------------------------------------------  
                                 currentchargeamount         numeric(30,2) null,
                                 yearlycurrentchargeamount   numeric(30,2) null,
                                 currentnetunitchargeamount  money null, ---> numeric(30,2) null,  
                                 unitofmeasure               numeric(30,5) null,
                                 effectivequantity           numeric(30,5) null,                                   
                                 discountpercent             as (case when recordtype <> 'CR'
                                                                        then ((-1)* convert(float,(socchargeamount - renewaladjustedchargeamountdisplay))* (100)
                                                                                     /
                                                                              convert(float,(case when socchargeamount=0 then 1 else socchargeamount end))
                                                                             )
                                                                      else NULL
                                                                  end),                                                                 
                                 currentnetextchargeamount   numeric(30,2) null, 
                                 yearlycurrentnetextchargeamount numeric(30,2) null,                               
                                 ------------------------------------------------------------------ 
                                 socchargeamount             numeric(30,2)  null,
                                 yearlysocchargeamount       numeric(30,2)  null,  
                                 socnetextchargeamount       numeric(30,2)  null,  
                                 yearlysocnetextchargeamount numeric(30,2)  null,  
                                 ------------------------------------------------------------------
                                 renewalchargeamount                 numeric(30,2) null,
                                 nonuseradjustedchargeamountdisplay  money null, ---> numeric(30,2) null,                           
                                 renewaladjustedchargeamountdisplay  money null, ---> numeric(30,2) null,
                                 yearlyrenewaladjustedchargeamountdisplay   money null, ---> numeric(30,2) null,              
                                 renewalnetextchargeamount           numeric(30,2) null,
                                 yearlyrenewalnetextchargeamount     numeric(30,2) null,                                 
                                 -----------------------------------------------------------------
                                 RenewalUserOverrideFlag     int default (0),
                                 PriceCapFlag                int default (0),
                                 nonuseradjustedrenewaladjustmenttype    varchar(50) NULL default 'N/A',   
                                 renewaladjustmenttype       varchar(50) NULL default 'N/A',
                                 renewaltypecode             varchar(5), 
                                 renewaltypename             varchar(20), 
                                 renewalreviewedflag         bigint  null,      
                                 renewalcount                bigint  null,
                                 renewalnotes                varchar(1000) null,
                                 orderitemcount              bigint  null,
                                 -----------------------------------------------------------------
                                ) ON [PRIMARY]   
  ------------------------------------------------------------------------------------
  --Step 0 : Preparatory Steps
  select XII.IDSeq as OrderItemIDSeq,
        Max(O.CompanyIDSeq)            as CompanyIDSeq,
        Max(COM.NAME)                  as companyname,
        Max(COM.ordersynchstartmonth)  as ordersynchstartmonth,
        ---NULL                        as companyname,
        Max(O.PropertyIDSeq)           as PropertyIDSeq,
        Max(PRPTY.Name)                as propertyname,
        ---NULL                        as propertyname,
        Max(O.AccountIDSeq)            as AccountIDSeq,
        Max(XII.OrderIDSeq) as OrderIDSeq,
        Max(convert(int,OG.custombundlenameenabledflag)) as custombundlenameenabledflag,
        Max(OG.Name)                                     as ordergroupname,
        MAX(OG.IDSeq)                                    as OrderGroupIDSeq,
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
  Into  #Temp_OrderItemsfirst
  from   ORDERS.dbo.[Orderitem] XII with (nolock)
  inner join 
               ORDERS.dbo.[OrderGroup] OG  with (nolock) 
        on     XII.Orderidseq      = OG.Orderidseq
        and    XII.Ordergroupidseq = OG.IDSeq        
        ---------------------------------------------------------------------------------------------  
        and     XII.ChargeTypeCode      =  'ACS'
        and     XII.Measurecode         <> 'TRAN'
        and     XII.FrequencyCode       <> 'OT'
        and     XII.ActivationEndDate   >= @LD_StartDate        
        and     ((@IPI_SearchByBillingCyleFlag=0 and XII.ActivationEndDate   <= @LD_EndDate)
                   Or
                 (@IPI_SearchByBillingCyleFlag=1 and XII.ActivationEndDate   < @LD_EndDate)
                )
        and     XII.StatusCode          = 'FULF'          
        --------------------------------------------------------------------------------------------- 
        and     XII.RenewalTypeCode     in (select R.Code 
                                            from   Orders.dbo.RenewalType R with (nolock)
                                            where  ((R.Code <> 'DRNW' and @IPVC_RenewalTypeCode is null)
                                                       OR
                                                    (R.Code = @IPVC_RenewalTypeCode)
                                                   )
                                            ) -- When @IPVC_RenewalTypeCode is null or '', then MRNW and ARNW.
                                              -- when @IPVC_RenewalTypeCode is valid value, only that will come into play.
        and     XII.RenewalReviewedFlag = coalesce(@IPVC_RenewalReviewedFlag,XII.RenewalReviewedFlag)
        ---------------------------------------------------------------------------------------------
  inner join
          Products.dbo.Charge OCHG with (nolock)       
  on      XII.productcode    = OCHG.productcode
  and     XII.priceversion   = OCHG.Priceversion       
  and     XII.Chargetypecode = OCHG.Chargetypecode
  and     XII.Measurecode    = OCHG.Measurecode
  and     XII.FrequencyCode  = OCHG.FrequencyCode 
  Inner Join
          ORDERS.DBO.[Order]       O  with (nolock)  
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
  where  
        ( (@IPI_IncludeProperties = 1)
                       OR
          (@IPI_IncludeProperties = 0 and coalesce(O.PropertyIDSeq,'ABC') = 'ABC')               
          )  
  and    COM.NAME like '%' +@IPVC_CompanyName+'%'
  and    (Coalesce(PRPTY.NAME,COM.NAME) like '%'+@IPVC_AccountName+'%') 
  and    XII.HistoryFlag     = 0
  and    XII.familycode      = Coalesce(@IPVC_FamilyCode,XII.familycode)
  group by XII.IDSeq, XII.ProductCode,XII.Measurecode,XII.Frequencycode,
           Coalesce(XII.MasterOrderItemIDSeq,XII.IDSeq),XII.Renewalcount


  select S.OrderItemIDSeq,
         Max(S.CompanyIDSeq)                as CompanyIDSeq,
         Max(S.companyname)                 as companyname,
         Max(S.ordersynchstartmonth)        as ordersynchstartmonth,         
         Max(S.PropertyIDSeq)               as PropertyIDSeq,
         Max(S.propertyname)                as propertyname,     
         Max(S.AccountIDSeq)                as AccountIDSeq,
         Max(S.OrderIDSeq)                  as OrderIDSeq,
         Max(S.custombundlenameenabledflag) as custombundlenameenabledflag,
         Max(S.ordergroupname)              as ordergroupname,
         Max(S.UnitEffectiveQuantity)       as UnitEffectiveQuantity   
  into #Temp_OrdersItemsToConsider
  from #Temp_OrderItemsfirst S with (nolock)
  Where 
       S.Renewalcount >=
                      (select Max(XI.Renewalcount)
                       from   #Temp_OrderItemsfirst XI with (nolock)
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
  Insert into #TempUIOrderItem(companyidseq,companyname,ordersynchstartmonth,propertyidseq,propertyname,accountidseq,
                               orderitemidseq,orderidseq,ordergroupidseq, 
                               productcode,priceversion,
                               chargetypecode,frequencycode,frequencyname,measurecode,measurename,familycode,reportingtypecode,
                               productdisplayname,
                               custombundlenameenabledflag,ordergroupname,
                               frequencymultiplier,
                               currentactivationstartdate,currentactivationenddate,
                               renewalactivationstartdate,allowchangerenewalstartdateflag,
                               currentchargeamount,currentnetunitchargeamount,ExtChargeAmount,unitofmeasure,UnitEffectiveQuantity,effectivequantity,discountpercent,currentnetextchargeamount, 
                               socpriceversion,socchargeamount,
                               renewalchargeamount,renewaladjustedchargeamount,renewalstartdate,
                               renewaltypecode,renewalcount,renewalnotes,masterorderitemidseq,
                               renewalreviewedflag,RenewalUserOverrideFlag,
                               DollarMinimumEnabledFlag,DollarMinimum
                            )

  select distinct
         Max(TOIC.CompanyIDSeq)            as CompanyIDSeq,
         Max(TOIC.companyname)             as companyname,
         Max(TOIC.ordersynchstartmonth)    as ordersynchstartmonth,        
         Max(TOIC.PropertyIDSeq)           as PropertyIDSeq,
         Max(TOIC.propertyname)            as propertyname,
         Max(TOIC.AccountIDSeq)            as AccountIDSeq,
         XII.IDSeq                                                               as OrderItemIDSeq,
               Max(XII.OrderIDSeq)                                               as OrderIDSeq,
               Max(XII.OrderGroupIDSeq)                                          as OrderGroupIDSeq,
               Max(ltrim(rtrim(XII.ProductCode)))                                as ProductCode,
               Max(XII.PriceVersion)                                             as PriceVersion,
               Max(XII.ChargeTypeCode)                                           as ChargeTypeCode,
               Max(XII.FrequencyCode)                                            as FrequencyCode,
               Max(FR.Name)                                                      as FrequencyName,
               Max(XII.MeasureCode)                                              as MeasureCode,
               Max(M.Name)                                                       as MeasureName,
               Max(P.FamilyCode)                                                 as FamilyCode,
               coalesce(Max(CHG.ReportingTypeCode),Max(XII.ReportingTypeCode))   as ReportingTypeCode,
               coalesce(Max(PRD.displayname),Max(P.displayname))                 as productdisplayname,
               Max(TOIC.custombundlenameenabledflag)                             as custombundlenameenabledflag,
               Max(TOIC.ordergroupname)                                          as ordergroupname,                
               ------------------------------------------------------------------------------------------
              (case when Max(XII.FrequencyCode) = 'SG' then 1
                    when Max(XII.FrequencyCode) = 'OT' then 1
                    when Max(XII.FrequencyCode) = 'YR' then 1
                    when Max(XII.FrequencyCode) = 'QR' then 4
                    when Max(XII.FrequencyCode) = 'MN' then 12
                    when Max(XII.FrequencyCode) = 'DY' then 1
                    when Max(XII.FrequencyCode) = 'HR' then 1
                    when Max(XII.FrequencyCode) = 'OC' then 1
              end)                                                               as frequencymultiplier,         
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
                          )  AND
                          (Max(XII.ActivationEndDate) < convert(datetime,convert(varchar(50),Getdate(),101))
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
               Max(XII.ExtChargeAmount)                                     as ExtChargeAmount,
               Max(XII.unitofmeasure)                                       as unitofmeasure,   
               Max(TOIC.UnitEffectiveQuantity)                              as UnitEffectiveQuantity,
               Max(XII.effectivequantity)                                   as effectivequantity,   
               0                                                            as discountpercent,            
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
                Max(XII.renewaltypecode)                                     as renewaltypecode,
                Max(XII.renewalcount)                                        as renewalcount,
                Max(XII.renewalnotes)                                        as renewalnotes,
                Coalesce(XII.MasterOrderItemIDSeq,XII.IDSeq)                 as MasterOrderItemIDSeq,
                Max(Convert(int,XII.renewalreviewedflag))                    as renewalreviewedflag,
                Max(Convert(int,XII.RenewalUserOverrideFlag))                as RenewalUserOverrideFlag,
               ------------------------------------------------------------------------------------------
               coalesce(Max(convert(int,CHG.DollarMinimumEnabledFlag)),Max(convert(int,OCHG.DollarMinimumEnabledFlag)),0) 
                                                                             as DollarMinimumEnabledFlag,
               Max(coalesce(XII.DollarMinimum,CHG.DollarMinimum,OCHG.DollarMinimum,0.00))
                                                                             as DollarMinimum
               ------------------------------------------------------------------------------------------
        from   ORDERS.dbo.[Orderitem] XII with (nolock)
        inner join 
               #Temp_OrdersItemsToConsider TOIC with (nolock)
        on     XII.IDseq           = TOIC.OrderItemIDSeq 
        and    XII.HistoryFlag     = 0      
        inner join
                Products.dbo.Product P with (nolock)
        on      XII.productcode = P.code
        and     XII.priceversion= P.Priceversion 
        and     P.familycode      = Coalesce(@IPVC_FamilyCode,P.familycode)
        inner join
                Products.dbo.Charge OCHG with (nolock)       
        on      XII.productcode    = OCHG.productcode
        and     XII.priceversion   = OCHG.Priceversion
        and     P.Code             = OCHG.productcode
        and     P.Priceversion     = OCHG.Priceversion
        and     XII.Chargetypecode = OCHG.Chargetypecode
        and     XII.Measurecode    = OCHG.Measurecode
        and     XII.FrequencyCode  = OCHG.FrequencyCode         
        inner join 
                PRODUCTS.dbo.Measure M  with (nolock)
        on      XII.MeasureCode   = M.Code           
        inner join 
               PRODUCTS.dbo.Frequency FR with (nolock)
        on     XII.FrequencyCode  = FR.Code  
        ---------------------------------------------------------------
        Left outer Join
              Products.dbo.Product PRD with (nolock)
        on    XII.ProductCode    = PRD.Code
        and   PRD.disabledflag   = 0
        Left outer Join 
              Products.dbo.Charge CHG with (nolock)
        on    XII.ProductCode    = CHG.ProductCode
        and   XII.ProductCode    = PRD.Code
        and   CHG.disabledflag   = PRD.disabledflag
        and   CHG.disabledflag   = 0
        and   XII.Chargetypecode = CHG.Chargetypecode
        and   XII.Measurecode    = CHG.Measurecode
        and   XII.FrequencyCode  = CHG.FrequencyCode                
  GROUP BY XII.IDSeq,XII.OrderIDSeq,XII.OrderGroupIDSeq,XII.MasterOrderItemIDSeq  
  --------------------------------------------------------------------------------------
  ---Step 1.1: update For Company Name,ordersynchstartmonth and PropertyName
  --------------------------------------------------------------------------------------
 /*
  Update D
  set    D.companyname          = S.Name,
         D.ordersynchstartmonth = S.ordersynchstartmonth
  from   #TempUIOrderItem     D  with (nolock)
  inner join
         CUSTOMERS.DBO.Company S with (nolock)
  on     S.IDSeq = D.CompanyIDSeq

  if (@IPI_IncludeProperties = 1)
  begin
    Update D
    set    D.propertyname         = S.Name
    from   #TempUIOrderItem     D  with (nolock)
    inner join
           CUSTOMERS.DBO.Property S with (nolock)
    on     S.IDSeq           = D.PropertyIDSeq
    and    S.PMCIDseq        = D.CompanyIDSeq
  end */
  
  if @IPVC_CompanyName <> '' 
  begin
    delete from #TempUIOrderItem where not (companyname like '%'+@IPVC_CompanyName+'%')
  end;
  if @IPVC_AccountName <> '' 
  begin
    delete from #TempUIOrderItem where not (accountname like '%'+@IPVC_AccountName+'%')
  end
  if @IPVC_ProductName <> '' 
  begin 
    delete from #TempUIOrderItem 
    where custombundlenameenabledflag = 0 and not (productdisplayname like '%' + @IPVC_ProductName + '%')
  end              
  --------------------------------------------------------------------------------------
  ---Step 2: Get all Active Price caps for all Companies and Properties and Products in 
  ---        #TempUIOrderItem
  --------------------------------------------------------------------------------------
  ---Defect Defect8890 : PricecapProperties will also include Corporate/PMCs and also Sites.
  /*
  Insert into #TempUIpriceCapholdingTable(companyidseq,propertyidseq,pricecapflag,pricecapbasiscode,
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
        and    PC.companyidseq in (select X.CompanyIDSeq from #TempUIOrderItem X with (nolock))
        and    ltrim(rtrim(PCP.ProductCode)) in (select ltrim(rtrim(T.productcode)) from #TempUIOrderItem T with (nolock))
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
        and    PC.companyidseq in (select X.CompanyIDSeq from #TempUIOrderItem X with (nolock))
        and    ltrim(rtrim(PCP.ProductCode)) in (select ltrim(rtrim(T.productcode)) from #TempUIOrderItem T with (nolock))
        inner join
               CUSTOMERS.dbo.PriceCapProperties PCPRP With (nolock)
        on     PC.IDSeq          = PCPRP.PricecapIDSeq
        and    PC.companyidseq   = PCPRP.companyidseq  
        and    PCPRP.companyidseq  in (select X.CompanyIDSeq  from #TempUIOrderItem X with (nolock))
        and    PCPRP.PropertyIDSeq in (select X.PropertyIDSeq from #TempUIOrderItem X with (nolock))
        and    PC.ActiveFlag     = 1
        and    PCP.PricecapIDSeq = PCPRP.PricecapIDSeq
        and    PCP.companyidseq  = PCPRP.companyidseq
       ) S
  group by S.companyidseq,S.Propertyidseq,S.pricecapflag,S.pricecapbasiscode,S.PriceCapPercent,
         S.PriceCapStartDate,S.PriceCapEndDate,S.ProductCode
  */
  ---Defect Defect8890 : PricecapProperties will also include Corporate/PMCs and also Sites.
  Insert into #TempUIpriceCapholdingTable(companyidseq,propertyidseq,pricecapflag,pricecapbasiscode,
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
         #TempUIOrderItem X with (nolock)
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
  ---Step 3: Update #TempUIOrderItem with Price caps from Step 2.
  -------------------------------------------------------------------------------------------------
  Update T
  set    T.pricecapflag     = 1,
         T.pricecapbasiscode= S.pricecapbasiscode,
         T.PriceCapPercent  = S.PriceCapPercent,
         T.PriceCapStartDate= S.PriceCapStartDate,
         T.PriceCapEndDate  = S.PriceCapEndDate
  from   #TempUIpriceCapholdingTable S with (nolock)
  inner join
         #TempUIOrderItem T  with (nolock)
  on     T.ProductCode    = S.ProductCode
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
                                      then convert(float, 
                                                     (convert(float,D.RenewalChargeAmount) + ((convert(float,D.RenewalChargeAmount)*D.PriceCapPercent)/(100)
                                                                                     )
                                                      )
                                                     )                                    
                                    else D.SOCChargeAmount
                               end),         
         D.PriceVersion         = D.SOCPriceVersion         
  from #TempUIOrderItem D with (nolock)
  ------------------------------------------------------------------------------------------
  ---Step 5: Determine the new product discount percentage and update #TempUIOrderItem  
  /*
  Update D
  set    D.DiscountPercent = (convert(float,(D.socnetextchargeamount - D.renewalnetextchargeamount))* (100)
                                  /
                              convert(float,(case when D.socnetextchargeamount=0 then 1 else D.socnetextchargeamount end))
                             )
  from #TempUIOrderItem D with (nolock)
  */

  Update D
  set    D.DiscountPercent = (convert(float,(D.socchargeamount - D.renewaladjustedchargeamountdisplay))* (100)
                                  /
                              convert(float,(case when D.socchargeamount=0 then 1 else D.socchargeamount end))
                             )
  from #TempUIOrderItem D with (nolock)
  -------------------------------------------------------------------------------------------------  
  -- Final Insert   
  -------------------------------------------
  ---Step 6.1: Final Insert into #TempUIRenewalOrderItemFinal for all Custom Bundles.
  Insert into #TempUIRenewalOrderItemFinal(companyidseq,companyname,propertyidseq,propertyname,accountidseq,accountname,
                                           orderidseq,ordergroupidseq,orderitemidseq,
                                           frequencyname,measurename,internalname,productdisplayname,
                                           recordtype,custombundlenameenabledflag,
                                           currentactivationstartdate,currentactivationenddate,renewalactivationstartdate,renewalactivationenddate,
                                           allowchangerenewalstartdateflag, 
                                           currentchargeamount,yearlycurrentchargeamount,currentnetunitchargeamount,unitofmeasure,effectivequantity,
                                           currentnetextchargeamount,yearlycurrentnetextchargeamount,
                                           socchargeamount,yearlysocchargeamount,socnetextchargeamount,yearlysocnetextchargeamount,
                                           renewalchargeamount,nonuseradjustedchargeamountdisplay,
                                           renewaladjustedchargeamountdisplay,yearlyrenewaladjustedchargeamountdisplay,
                                           renewalnetextchargeamount,yearlyrenewalnetextchargeamount,
                                           nonuseradjustedrenewaladjustmenttype,renewaladjustmenttype,renewaltypecode,renewaltypename,renewalreviewedflag,renewalcount,renewalnotes,
                                           orderitemcount,pricecapflag,RenewalUserOverrideFlag
                                          )
  select T.companyidseq,T.companyname,T.propertyidseq,T.propertyname,T.accountidseq,T.accountname,
         T.orderidseq,T.ordergroupidseq,T.orderitemidseq,
         T.frequencyname,T.measurename,T.internalname,T.productdisplayname,
         T.recordtype,T.custombundlenameenabledflag,
         convert(varchar(50),T.currentactivationstartdate,101) as currentactivationstartdate,
         convert(varchar(50),T.currentactivationenddate,101)   as currentactivationenddate,
         convert(varchar(50),T.renewalactivationstartdate,101) as renewalactivationstartdate,
         convert(varchar(50),T.renewalactivationenddate,101)   as renewalactivationenddate,
         T.allowchangerenewalstartdateflag,
         T.currentchargeamount,T.yearlycurrentchargeamount,T.currentnetunitchargeamount,
         T.unitofmeasure,convert(numeric(30,0),T.effectivequantity) as effectivequantity,
         T.currentnetextchargeamount,T.yearlycurrentnetextchargeamount,
         T.socchargeamount,T.yearlysocchargeamount,T.socnetextchargeamount,T.yearlysocnetextchargeamount,
         T.renewalchargeamount,T.nonuseradjustedchargeamountdisplay,
         T.renewaladjustedchargeamountdisplay,T.yearlyrenewaladjustedchargeamountdisplay,
         T.renewalnetextchargeamount,T.yearlyrenewalnetextchargeamount,
         T.nonuseradjustedrenewaladjustmenttype,T.renewaladjustmenttype,T.renewaltypecode,
         T.renewaltypename,T.renewalreviewedflag,T.renewalcount,T.renewalnotes,
         T.orderitemcount,T.pricecapflag,T.RenewalUserOverrideFlag
  from (
  select companyidseq,companyname,propertyidseq,propertyname,accountidseq,accountname,
         orderidseq,ordergroupidseq,max(orderitemidseq) as orderitemidseq,
         max(frequencyname) as frequencyname,max(measurename) as measurename,
         min(productdisplayname) as internalname,max(ordergroupname) as productdisplayname,
         'CB' as recordtype,1 as custombundlenameenabledflag,
         max(currentactivationstartdate) as currentactivationstartdate,max(currentactivationenddate) as currentactivationenddate,
         max(renewalactivationstartdate) as renewalactivationstartdate,max(renewalactivationenddate) as renewalactivationenddate,
         max(allowchangerenewalstartdateflag) as allowchangerenewalstartdateflag,
         sum(currentchargeamount) as currentchargeamount,
         sum(yearlycurrentchargeamount) as yearlycurrentchargeamount,
         sum(currentnetunitchargeamount) as currentnetunitchargeamount,
         sum(distinct unitofmeasure) as unitofmeasure,
         --sum(distinct effectivequantity)  as effectivequantity,
         convert(money,sum(currentnetextchargeamount))/
            (Case when convert(money,sum(currentnetunitchargeamount)) =  0 then 1 else convert(money,sum(currentnetunitchargeamount)) end) 
                                        as effectivequantity,
         /*sum(yearlycurrentnetextchargeamount)/
            (Case when sum(yearlyadjustedcurrentchargeamount) =  0 then 1 else sum(yearlyadjustedcurrentchargeamount) end) 
                                        as effectivequantity,
         */
         sum(currentnetextchargeamount) as currentnetextchargeamount,
         sum(yearlycurrentnetextchargeamount) as yearlycurrentnetextchargeamount,
         sum(socchargeamount) as socchargeamount,
         sum(yearlysocchargeamount) as yearlysocchargeamount,
         sum(socnetextchargeamount) as socnetextchargeamount,
         sum(yearlysocnetextchargeamount) as yearlysocnetextchargeamount,
         sum(renewalchargeamount)         as renewalchargeamount,
         sum(nonuseradjustedchargeamountdisplay) as nonuseradjustedchargeamountdisplay,
         sum(renewaladjustedchargeamountdisplay) as renewaladjustedchargeamountdisplay,
         sum(yearlyrenewaladjustedchargeamountdisplay) as yearlyrenewaladjustedchargeamountdisplay,
         sum(renewalnetextchargeamount) as renewalnetextchargeamount,
         sum(yearlyrenewalnetextchargeamount) as yearlyrenewalnetextchargeamount,
         (case  when (max(S.pricecapflag)=1)
                 then 'Price Cap'               
               else 'N/A'
          end)                      as nonuseradjustedrenewaladjustmenttype,          
         (case when (max(S.renewaluseroverrideflag)=1)
                 then 'User Adjusted'
               when (max(S.pricecapflag)=1)
                 then 'Price Cap'               
               else 'N/A'
          end)                    as renewaladjustmenttype,
         max(renewaltypecode)     as renewaltypecode,
         max(renewaltypename)     as renewaltypename,
         max(renewalreviewedflag) as renewalreviewedflag,
         max(renewalcount)        as renewalcount,
         max(renewalnotes)        as renewalnotes,
         count(orderitemidseq)    as orderitemcount,
         max(pricecapflag)            as pricecapflag,
         max(RenewalUserOverrideFlag) as renewaluseroverrideflag
  from  #TempUIOrderItem S with (nolock)
  where S.custombundlenameenabledflag = 1
  and   S.companyname like '%'+@IPVC_CompanyName+'%'
  and   S.accountname like '%'+@IPVC_AccountName+'%'
  and   (@IPVC_ProductName='' 
               OR
         exists (select top 1 1 from #TempUIOrderItem XI with (nolock)
                 where  XI.orderidseq      = S.orderidseq
                 and    XI.ordergroupidseq = S.ordergroupidseq
                 and    XI.custombundlenameenabledflag = S.custombundlenameenabledflag
                 and    XI.custombundlenameenabledflag = 1
                 and    XI.productdisplayname like '%' + @IPVC_ProductName + '%') 
         )
  group by companyidseq,companyname,propertyidseq,propertyname,accountidseq,accountname,
           orderidseq,ordergroupidseq  
  --------------------------------------------------------------------
  UNION
  --Step 6.3: Final Insert into #TempUIRenewalOrderItemFinal for all NON Custom Bundle Products.
  --------------------------------------------------------------------
  select companyidseq,companyname,propertyidseq,propertyname,accountidseq,accountname,
         orderidseq,ordergroupidseq,orderitemidseq,
         frequencyname,measurename,
         productdisplayname as internalname,productdisplayname as productdisplayname,
         'PR' as recordtype,0 as custombundlenameenabledflag,
         currentactivationstartdate,currentactivationenddate,renewalactivationstartdate,renewalactivationenddate,
         allowchangerenewalstartdateflag,
         currentchargeamount,yearlycurrentchargeamount,currentnetunitchargeamount,
         unitofmeasure,
         --effectivequantity,
         convert(money,(currentnetextchargeamount))/
            (Case when convert(money,(currentnetunitchargeamount)) =  0 then 1 else convert(money,(currentnetunitchargeamount)) end) 
                                        as effectivequantity,
         currentnetextchargeamount,yearlycurrentnetextchargeamount,
         socchargeamount,yearlysocchargeamount,socnetextchargeamount,yearlysocnetextchargeamount,
         renewalchargeamount,nonuseradjustedchargeamountdisplay,renewaladjustedchargeamountdisplay,yearlyrenewaladjustedchargeamountdisplay,
         renewalnetextchargeamount,yearlyrenewalnetextchargeamount,
         (case  when (S.pricecapflag=1)
                 then 'Price Cap'               
               else 'N/A'
          end)                      as nonuseradjustedrenewaladjustmenttype,
         (case when (S.renewaluseroverrideflag=1 )
                 then 'User Adjusted'
               when (S.pricecapflag=1 )
                 then 'Price Cap'
               else 'N/A'
          end) as  renewaladjustmenttype,
         renewaltypecode,renewaltypename,renewalreviewedflag,renewalcount,renewalnotes,1 as orderitemcount,
         pricecapflag,RenewalUserOverrideFlag
  from  #TempUIOrderItem S with (nolock)
  where S.custombundlenameenabledflag = 0
  and   S.companyname like '%'+@IPVC_CompanyName+'%'
  and   S.accountname like '%'+@IPVC_AccountName+'%'
  and   S.productdisplayname like '%' + @IPVC_ProductName + '%'
  ) T  
  order by (case when @IPVC_SortBy = 'companyid'   then (RANK() OVER (ORDER BY companyidseq ASC,recordtype ASC,productdisplayname ASC))
                 when @IPVC_SortBy = 'companyname' then (RANK() OVER (ORDER BY companyname  ASC,recordtype ASC,productdisplayname ASC))
                 when @IPVC_SortBy = 'accountid'   then (RANK() OVER (ORDER BY accountidseq ASC,recordtype ASC,productdisplayname ASC))
                 when @IPVC_SortBy = 'accountname' then (RANK() OVER (ORDER BY accountname  ASC,recordtype ASC,productdisplayname ASC))
                 when @IPVC_SortBy = 'productname' then (RANK() OVER (ORDER BY productdisplayname ASC,recordtype ASC,productdisplayname ASC))
                 when @IPVC_SortBy = 'renewaldate' then (RANK() OVER (ORDER BY renewalactivationstartdate ASC,accountname ASC,recordtype ASC,productdisplayname ASC)) 
                 else (RANK() OVER (ORDER BY renewalactivationstartdate ASC,accountname ASC,recordtype ASC,productdisplayname ASC))
             end)
  -----------------------------------------------------------------------------------------
  set identity_insert #TempUIRenewalOrderItemFinal on;
  Insert into #TempUIRenewalOrderItemFinal(sortseq,companyidseq,companyname,propertyidseq,propertyname,accountidseq,accountname,
                                           orderidseq,ordergroupidseq,orderitemidseq,
                                           frequencyname,measurename,internalname,productdisplayname,
                                           recordtype,custombundlenameenabledflag,
                                           currentactivationstartdate,currentactivationenddate,renewalactivationstartdate,renewalactivationenddate,
                                           allowchangerenewalstartdateflag,
                                           currentchargeamount,yearlycurrentchargeamount,currentnetunitchargeamount,unitofmeasure,effectivequantity,
                                           currentnetextchargeamount,yearlycurrentnetextchargeamount,
                                           socchargeamount,yearlysocchargeamount,socnetextchargeamount,yearlysocnetextchargeamount,
                                           renewalchargeamount,nonuseradjustedchargeamountdisplay,renewaladjustedchargeamountdisplay,yearlyrenewaladjustedchargeamountdisplay,
                                           renewalnetextchargeamount,yearlyrenewalnetextchargeamount,
                                           nonuseradjustedrenewaladjustmenttype,renewaladjustmenttype,renewaltypecode,renewaltypename,renewalreviewedflag,renewalcount,renewalnotes,
                                           orderitemcount,pricecapflag,RenewalUserOverrideFlag
                                          )
  select S.sortseq,S.companyidseq,S.companyname,S.propertyidseq,S.propertyname,S.accountidseq,S.accountname,
         S.orderidseq,S.ordergroupidseq,S.orderitemidseq as orderitemidseq,
         NULL as Frequencyname,NULL as measurename,
         T.productdisplayname as internalname,T.productdisplayname as productdisplayname,
         'CR' as recordtype,1 as custombundlenameenabledflag,
         NULL as currentactivationstartdate,NULL as currentactivationenddate,
         NULL as renewalactivationstartdate,NULL as renewalactivationenddate,
         S.allowchangerenewalstartdateflag as allowchangerenewalstartdateflag,
         NULL as currentchargeamount,NULL as currentnetunitchargeamount,NULL as unitofmeasure,
         NULL as effectivequantity,
         NULL as currentnetextchargeamount,
         NULL as yearlycurrentchargeamount,
         NULL as yearlycurrentnetextchargeamount,
         NULL as socchargeamount,
         NULL as yearlysocchargeamount,
         NULL as socnetextchargeamount,
         NULL as yearlysocnetextchargeamount,
         NULL as renewalchargeamount,
         NULL as nonuseradjustedchargeamountdisplay,
         NULL as renewaladjustedchargeamountdisplay,
         NULL as yearlyrenewaladjustedchargeamountdisplay, 
         NULL as renewalnetextchargeamount,
         NULL as yearlyrenewalnetextchargeamount,
         NULL as nonuseradjustedrenewaladjustmenttype,
         NULL as renewaladjustmenttype,
         NULL as renewaltypecode,
         NULL as renewaltypename,
         NULL as renewalreviewedflag,
         NULL as renewalcount,
         NULL as renewalnotes,
         NULL as orderitemcount,
         T.pricecapflag            as pricecapflag,
         T.RenewalUserOverrideFlag as renewaluseroverrideflag
  from  #TempUIRenewalOrderItemFinal S with (nolock)
  inner join
        #TempUIOrderItem T with (nolock) 
  on    S.orderidseq = T.orderidseq
  and   S.ordergroupidseq = T.ordergroupidseq
  and   S.custombundlenameenabledflag = T.custombundlenameenabledflag
  and   S.renewalcount = T.renewalcount
  and   S.custombundlenameenabledflag = 1
  and   T.custombundlenameenabledflag = 1
  and   S.recordtype = 'CB'
  order by S.sortseq asc
  set identity_insert #TempUIRenewalOrderItemFinal off;
  ----------------------------------------------------------------------------------------- 
  select @LBI_TotalRecords = count(SortSeq) from  #TempUIRenewalOrderItemFinal WITH (NOLOCK)
  -----------------------------------------------------------------------------------------
  --Important : Creating Non clustered Index on sortseq,recordtype,RowNumber
  set ansi_warnings on;
  CREATE NONCLUSTERED INDEX [ix_seq] on #TempUIRenewalOrderItemFinal(sortseq,recordtype)
  INCLUDE (RowNumber,accountidseq,companyidseq,propertyidseq,companyname,accountname,productdisplayname,
           currentactivationenddate,renewalactivationstartdate,renewaltypename,measurename,
           renewalchargeamount,discountpercent,nonuseradjustedchargeamountdisplay,renewaladjustedchargeamountdisplay,
           nonuseradjustedrenewaladjustmenttype,renewaladjustmenttype,renewalreviewedflag,
           renewalnotes,
           orderidseq,ordergroupidseq,orderitemidseq,renewalcount,orderitemcount,
           renewaltypecode,custombundlenameenabledflag,
           allowchangerenewalstartdateflag,effectivequantity
          );
  update #TempUIRenewalOrderItemFinal SET @LBI_Counter = RowNumber = @LBI_Counter + 1 
  set ansi_warnings off;
  -----------------------------------------------------------------------------------------
  select  @LBI_MinRowNumber = (@IPI_PageNumber-1) * @IPI_RowsPerPage,
          @LBI_MaxRowNumber = (@IPI_PageNumber)* @IPI_RowsPerPage;  
  --SET ROWCOUNT @LBI_MaxRowNumber;

  SELECT @LBI_TotalRecords as TotalRecords,
         S.accountidseq    as accountidseq,
         S.companyidseq    as companyidseq,
         S.propertyidseq   as propertyidseq,
         -------------------------------------
         -- Main UI columns
         S.companyname,
         S.accountname,
         S.productdisplayname,
         Convert(varchar(50),S.currentactivationstartdate,101) as currentactivationstartdate,
         Convert(varchar(50),S.currentactivationenddate,101)   as currentactivationenddate,
         convert(varchar(50),S.renewalactivationstartdate,101) as renewalactivationstartdate,
         convert(varchar(50),S.renewalactivationenddate,101)   as renewalactivationenddate,
         S.renewaltypename,
         S.measurename,
         S.frequencyname,
         S.renewalchargeamount,
         convert(numeric(30,5),S.discountpercent) as discountpercent,
         S.nonuseradjustedchargeamountdisplay,
         S.renewaladjustedchargeamountdisplay,
         S.nonuseradjustedrenewaladjustmenttype,
         S.renewaladjustmenttype,
         S.renewalreviewedflag,
         S.pricecapflag,
         S.renewaluseroverrideflag,
         ---------------------------------------
         -- Edit Renewal Modal UI columns
         -- S.productdisplayname,
         -- S.renewaltypecode,
         -- S.renewaltypename,
         -- S.renewalchargeamount,
         -- S.discountpercent,
         -- S.renewaladjustedchargeamountdisplay,
         S.renewalnotes,
         ---------------------------------------
         -- Other internal columns to be passed back for updating Orderitem         
         S.orderidseq,
         S.ordergroupidseq,
         S.orderitemidseq,  
         S.renewalcount,  
         S.orderitemcount,
         S.renewaltypecode,
         S.custombundlenameenabledflag,
         S.recordtype,
         S.allowchangerenewalstartdateflag,
         S.effectivequantity,
         S.currentnetunitchargeamount as currentbaseprice,
         S.socchargeamount            as listbaseprice    
  FROM #TempUIRenewalOrderItemFinal S WITH (NOLOCK)
  where  S.RowNumber >  @LBI_MinRowNumber
  and    S.RowNumber <= @LBI_MaxRowNumber  
  order by   S.RowNumber asc,S.sortseq asc,S.recordtype ASC
  -----------------------------------------------------------------------------------------  
  ---Final Cleanup  
  -----------------------------------------------------------------------------------------
  drop table #Temp_OrdersItemsToConsider
  drop table #Temp_OrderItemsfirst
  drop table #TempUIpriceCapholdingTable
  drop table #TempUIOrderItem
  drop table #TempUIRenewalOrderItemFinal
  --SET ROWCOUNT 0;
  -----------------------------------------------------------------------------------------
END
GO
