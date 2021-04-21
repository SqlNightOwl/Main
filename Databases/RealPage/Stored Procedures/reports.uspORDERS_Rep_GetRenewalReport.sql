SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--Exec ORDERS.dbo.uspORDERS_Rep_GetRenewalReport 
----------------------------------------------------------------------------------------------------      
-- Database  Name  : ORDERS      
-- Procedure Name  : uspORDERS_Rep_GetRenewalReport      
-- Description     : This procedure gets all orders that comes up for renewal between the passed
--                   Start and End Date
-- Input Parameters: 
--            
-- Code Example    : Exec ORDERS.dbo.uspORDERS_Rep_GetRenewalReport     
          
--       
--       
-- Revision History:      
-- Author          : SRS      
-- 08/09/2007      : Stored Procedure Created.      
-- 06/09/2010      : ShashiBhushan Defect#7088 - Modified to get previous year renewal notes.
-- 06/21/2010      : ShashiBhushan Defect#7092 - Column indicating unit count change, similar to PPU change on the Renewal Forecast Report.
-- 07/21/2010      : Naval Kishore Defect#7088 - Changed the name of o/p columns.
-- 09/20/2010      : Naval Kishore Defect#8012 - Changed Column name from Current Base Price to SOC Origninal Price 
-- 07/06/2011      : SRS - Added pricebyppuflag based logic to show or not to show ppu% related columns 
--                       - Added to show Quoteidseq associated with Order if any. For Migrated orders QuoteID will be null.
-- 08/08/2011      : Naval Kishore TFS # 730 - Modified Columns Renewal Vs Current % and Effective Quantity.    
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [reports].[uspORDERS_Rep_GetRenewalReport] (
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
  SET CONCAT_NULL_YIELDS_NULL off;
  ------------------------------------------------------------------------------------
  -- Declare Local Variables 
  Declare @LBI_TotalRecords  bigint 
  Declare @LD_StartDate     datetime  
  Declare @LD_EndDate       datetime
  declare @LBI_Counter       bigint  
  
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
  Create table #TempSRSpriceCapholdingTable
                                         (SEQ                           int not null identity(1,1) primary key,
                                          companyidseq                  varchar(50)   null,
                                          propertyidseq                 varchar(50)   null,
                                          pricecapflag                  int           not null default 0,
                                          pricecapterm                  int           not null default 0,
                                          pricecapbasiscode             varchar(50)   not null default 'LIST',
                                          PriceCapPercent               float         not null default 0.00,
                                          PriceCapStartDate             datetime      null,
                                          PriceCapEndDate               datetime      null, 
                                          productcode                   varchar(100)  null                                         
                                          ) ON [PRIMARY]  

  Create table #TempSRSOrderItem (SortSeq                     bigint not null identity(1,1) primary key,
                                 companyidseq                varchar(50),
                                 companyname                 varchar(255),
                                 propertyidseq               varchar(50),
                                 propertyname                varchar(255),
                                 accountidseq                varchar(50),
                                 accountname                 as coalesce(propertyname,companyname),
                                 productdisplayname          varchar(255),
                                 -----------------------------------------
                                 maxbillingperiodToDate      datetime null,
                                 priorunitcount              int null,
                                 actualunitcount             int null,
                                 priorppu                    int null,
                                 currentppu                  int null,
                                 pricebyppuflag              int not null default(0),
                                 ----------------------------------------- 
                                 quoteidseq                  varchar(50),              
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
                                 yearlyadjustedcurrentchargeamount as (currentnetunitchargeamount * frequencymultiplier), 
                                 unitofmeasure               numeric(30,5) not null default (0.00),
                                 UnitEffectiveQuantity       numeric(30,5) not null default (0.00), 
                                 effectivequantity           numeric(30,5) not null default (0.00),                                   
                                 discountpercent             float not null default (0.00),
                                 currentnetextchargeamount   money not null default (0), 
                                 yearlycurrentnetextchargeamount as (currentnetextchargeamount * frequencymultiplier),                                 
                                 ------------------------------------------------------------------ 
                                 socpriceversion             numeric(18,0),
                                 socchargeamount             money  not null default (0),  
                                 yearlysocchargeamount       as (socchargeamount * frequencymultiplier), 
                                 ---socnetextchargeamount       as (socchargeamount * effectivequantity),
                                 ---yearlysocnetextchargeamount as (socchargeamount * effectivequantity) * (frequencymultiplier),
                                 socnetextchargeamount       as (case when  ((DollarMinimumEnabledFlag=1)
                                                                                           and  
                                                                                        (convert(numeric(30,2),
                                                                                                   (convert(money,socchargeamount) 
                                                                                                      *
                                                                                                    UnitEffectiveQuantity
                                                                                                   )
                                                                                                )
                                                                                        ) <= DollarMinimum
                                                                                      )                                                                                       
                                                                                  then (convert(numeric(30,2),
                                                                                                   (convert(money,socchargeamount) 
                                                                                                      *
                                                                                                    UnitEffectiveQuantity
                                                                                                   )
                                                                                                )
                                                                                        )
                                                                                 else convert(numeric(30,2),
                                                                                                   (convert(money,socchargeamount) 
                                                                                                      *
                                                                                                    effectivequantity
                                                                                                   )
                                                                                                )
                                                                            end),
                                 yearlysocnetextchargeamount as (case when  ((DollarMinimumEnabledFlag=1)
                                                                                           and  
                                                                                        (convert(numeric(30,2),
                                                                                                   (convert(money,socchargeamount) 
                                                                                                      *
                                                                                                    UnitEffectiveQuantity
                                                                                                   )
                                                                                                )
                                                                                        ) <= DollarMinimum
                                                                                      )                                                                                       
                                                                                  then (convert(numeric(30,2),
                                                                                                   (convert(money,socchargeamount) 
                                                                                                      *
                                                                                                    UnitEffectiveQuantity
                                                                                                   )
                                                                                                )
                                                                                        )
                                                                                 else convert(numeric(30,2),
                                                                                                   (convert(money,socchargeamount) 
                                                                                                      *
                                                                                                    effectivequantity
                                                                                                   )
                                                                                                )
                                                                            end) * (frequencymultiplier),
                                 ------------------------------------------------------------------
                                 renewalchargeamount         money null,
                                 renewaldiscchargeamount     money null,
                                 renewaladjustedchargeamount money null,
                                 renewalstartdate            datetime null,    
                                 renewaladjustedchargeamountdisplay  as   convert(money,coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)), 
                                 yearlyrenewaladjustedchargeamountdisplay
                                                                     as   convert(money,(coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount))
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
                                 LastModifiedbyUser          varchar(100)  null,
                                 LastModifiedDate            varchar(100)  null,
                                 PreviousYearRenewalNotes    varchar(8000) null,
                                 -----------------------------------------------------------------
                                 DollarMinimumEnabledFlag    int           not null default(0),
                                 SOCDollarMinimum            numeric(30,2) not null default(0.00),
                                 AnnualizedSOCDollarMinimum  as convert(numeric(30,2),(SOCDollarMinimum * frequencymultiplier)),
                                 DollarMinimum               numeric(30,2) not null default(0.00),
                                 AnnualizedDollarMinimum     as convert(numeric(30,2),(DollarMinimum * frequencymultiplier)),
                                 DollarMinimumAppliedRule    as (Case when (DollarMinimumEnabledFlag=1 and
                                                                            convert(numeric(30,2),(coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)
                                                                                                           * unitofmeasure
                                                                                                   )
                                                                                    ) <  DollarMinimum
                                                                            )
                                                                        then 'Dollar Minimum applies. This product order has Net Extended Charge that does not meet the Dollar Minimum.'
                                                                             +
                                                                          (case when (DollarMinimumEnabledFlag=1 and SOCDollarMinimum <> DollarMinimum)
                                                                                 then ' User had Overridden SOC Suggested Dollar Minimum: $'+convert(varchar(50),SOCDollarMinimum)+ ' to ' + convert(varchar(50),DollarMinimum)+ '.'
                                                                                else ''
                                                                           end)                                                                            
                                                                      when (DollarMinimumEnabledFlag=1 and
                                                                            convert(numeric(30,2),(coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)
                                                                                                           * unitofmeasure
                                                                                                   )
                                                                                    ) =  DollarMinimum
                                                                            )
                                                                        then 'Dollar Minimum exists and it does not play as role because Net Extended Charge is exactly same as Dollar Minimum.'
                                                                             +
                                                                          (case when (DollarMinimumEnabledFlag=1 and SOCDollarMinimum <> DollarMinimum)
                                                                                 then ' User had Overridden SOC Suggested Dollar Minimum: $'+convert(varchar(50),SOCDollarMinimum)+ ' to ' + convert(varchar(50),DollarMinimum)+ '.'
                                                                                else ''
                                                                           end)
                                                                      when (DollarMinimumEnabledFlag=1 and
                                                                            convert(numeric(30,2),(coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)
                                                                                                           * unitofmeasure
                                                                                                   )
                                                                                   ) >  DollarMinimum
                                                                            )
                                                                        then 'Dollar Minimum exists and it does not apply because Net Extended Charge already meets the Dollar Minimum.' 
                                                                             +
                                                                          (case when (DollarMinimumEnabledFlag=1 and SOCDollarMinimum <> DollarMinimum)
                                                                                 then ' User had Overridden SOC Suggested Dollar Minimum: $'+convert(varchar(50),SOCDollarMinimum)+ ' to ' + convert(varchar(50),DollarMinimum)+ '.'
                                                                                else ''
                                                                           end)
                                                                       else null
                                                                  end),
                                  DollarMinimumUsedFlag     as  (Case when (DollarMinimumEnabledFlag=1 and
                                                                            convert(numeric(30,2),(coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)
                                                                                                           * unitofmeasure
                                                                                                   ) 
                                                                                   ) <=  DollarMinimum
                                                                            )
                                                                        then 1
                                                                      when (DollarMinimumEnabledFlag=1 and
                                                                            convert(numeric(30,2),(coalesce(renewaladjustedchargeamount,renewaldiscchargeamount,renewalchargeamount,socchargeamount)
                                                                                                           * unitofmeasure
                                                                                                   )
                                                                                    ) >  DollarMinimum
                                                                            )
                                                                        then 0
                                                                       else 0
                                                                  end)
                                 -----------------------------------------------------------------
                                ) ON [PRIMARY]  

  
  /*
  CREATE NONCLUSTERED INDEX [INCX_#TempSRSOrderItem] on #TempSRSOrderItem([CompanyIDSeq] ASC,[PropertyIDSeq] ASC) 
  INCLUDE(companyname,propertyname,accountidseq,accountname,
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
  
  Create table #TempSRSRenewalOrderItemFinal
                                (RowNumber                   bigint not null default (0),
                                 SortSeq                     bigint not null identity(1,1),
                                 companyidseq                varchar(50),
                                 companyname                 varchar(255),
                                 companystate                varchar(50) null,
                                 propertyidseq               varchar(50),
                                 propertyname                varchar(255),
                                 accountidseq                varchar(50),
                                 accountname                 varchar(255),
                                 internalname                varchar(255),
                                 productdisplayname          varchar(255),
                                 -----------------------------------------                                 
                                 maxbillingperiodToDate      datetime null,
                                 priorunitcount              int null,
                                 actualunitcount             int null,
                                 priorppu                    int null,
                                 currentppu                  int null,
                                 pricebyppuflag              int not null default(0), 
                                 -----------------------------------------
                                 quoteidseq                  varchar(50),     
                                 orderidseq                  varchar(50), 
                                 ordergroupidseq             bigint,                                
                                 orderitemidseq              bigint,                                   
                                 frequencyname               varchar(50),
                                 measurename                 varchar(50),                                 
                                 recordtype                  varchar(5) not null default 'PR',
                                 custombundlenameenabledflag int not null default (0),                                
                                 --------------------------------------------------------
                                 currentactivationstartdate  datetime,
                                 currentactivationenddate    datetime, 
                                 renewalactivationstartdate  datetime,
                                 renewalactivationenddate    datetime, 
                                 -----------------------------------------------------------------  
                                 currentchargeamount         numeric(30,2) null,
                                 yearlycurrentchargeamount   numeric(30,2) null,
                                 currentnetunitchargeamount  money null, --->numeric(30,2) null,
                                 yearlyadjustedcurrentchargeamount money null, --->numeric(30,2) null,
                                 unitofmeasure               numeric(30,5) null,
                                 effectivequantity           numeric(30,5) null,                                   
                                 discountpercent             as (case when recordtype <> 'CR'
                                                                        then (convert(float,(socchargeamount - renewaladjustedchargeamountdisplay))* (100)
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
                                 renewaladjustedchargeamountdisplay  money null, --->numeric(30,2) null,
                                 yearlyrenewaladjustedchargeamountdisplay   money null, --->numeric(30,2) null,               
                                 renewalnetextchargeamount           numeric(30,2) null,
                                 yearlyrenewalnetextchargeamount     numeric(30,2) null,                                 
                                 -----------------------------------------------------------------
                                 RenewalUserOverrideFlag     int default (0),
                                 PriceCapFlag                int default (0),  
                                 renewaladjustmenttype       varchar(50) NULL default 'N/A',
                                 renewaltypecode             varchar(5), 
                                 renewaltypename             varchar(20), 
                                 renewalreviewedflag         bigint  null,      
                                 renewalcount                bigint  null,
                                 renewalnotes                varchar(1000) null,
                                 orderitemcount              bigint  null,
                                 -----------------------------------------------------------------
                                 productcode                 varchar(50),
                                 LastModifiedbyUser          varchar(100)  null,
                                 LastModifiedDate            varchar(100)  null,
                                 PreviousYearRenewalNotes    varchar(8000) null,
                                 -----------------------------------------------------------------
                                 SOCDollarMinimum            numeric(30,2)  null,
                                 AnnualizedSOCDollarMinimum  numeric(30,2)  null,
                                 DollarMinimum               numeric(30,2)  Null,
                                 AnnualizedDollarMinimum     numeric(30,2)  Null,
                                 DollarMinimumAppliedRule    varchar(1000)  Null

                                ) ON [PRIMARY] 
  ------------------------------------------------------------------------------------------------ 
  --Step 0 : Preparatory Steps
  --Step 0 : Preparatory Steps
  select XII.IDSeq as OrderItemIDSeq,
        Max(O.QuoteIDSeq)              as quoteidseq,
        Max(O.CompanyIDSeq)            as CompanyIDSeq,
        Max(COM.NAME)                  as companyname,
        Max(COM.ordersynchstartmonth)  as ordersynchstartmonth,
        ---NULL                        as companyname,
        Max(O.PropertyIDSeq)           as PropertyIDSeq,
        Max(PRPTY.Name)                as propertyname,
        ---NULL                        as propertyname,
        Max(PRPTY.Units)               as actualunitcount,
        Max(PRPTY.PPUPercentage)       as currentppu,
        Max(convert(int,OCHG.PriceByPPUPercentageEnabledFlag)) as  pricebyppuflag,             
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
  Into  #Temp_SRSOrderItemsfirst
  from   ORDERS.dbo.[Orderitem] XII with (nolock)  
  inner join 
               ORDERS.dbo.[OrderGroup] OG  with (nolock) 
        on     XII.Orderidseq      = OG.Orderidseq
        and    XII.Ordergroupidseq = OG.IDSeq        
        ---------------------------------------------------------------------------------------------  
        and     XII.ChargeTypeCode       = 'ACS'
        and     XII.Measurecode         <> 'TRAN'
        and     XII.FrequencyCode       <> 'OT'        
        and     XII.ActivationEndDate   >= @LD_StartDate       
        and     ((@IPI_SearchByBillingCyleFlag=0 and XII.ActivationEndDate   <= @LD_EndDate)
                   Or
                 (@IPI_SearchByBillingCyleFlag=1 and XII.ActivationEndDate   < @LD_EndDate)
                )
        and     XII.StatusCode           = 'FULF'          
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
  and     O.OrderIdSeq       = coalesce(@IPVC_OrderID,O.OrderIdSeq)
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
         Max(S.quoteidseq)                  as quoteidseq,
         Max(S.CompanyIDSeq)                as CompanyIDSeq,
         Max(S.companyname)                 as companyname,
         Max(S.ordersynchstartmonth)        as ordersynchstartmonth,         
         Max(S.PropertyIDSeq)               as PropertyIDSeq,
         Max(S.propertyname)                as propertyname,
         Max(S.actualunitcount)             as actualunitcount,
         Max(S.pricebyppuflag)              as pricebyppuflag,
         Max(S.currentppu)                  as currentppu,     
         Max(S.AccountIDSeq)                as AccountIDSeq,
         Max(S.OrderIDSeq)                  as OrderIDSeq,
         Max(S.custombundlenameenabledflag) as custombundlenameenabledflag,
         Max(S.ordergroupname)              as ordergroupname,
         Max(S.UnitEffectiveQuantity)       as UnitEffectiveQuantity  
  into #Temp_SRS_OrdersItemsToConsider
  from #Temp_SRSOrderItemsfirst S with (nolock)
  Where 
       S.Renewalcount >=
                      (select Max(XI.Renewalcount)
                       from   #Temp_SRSOrderItemsfirst XI with (nolock)
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
  Insert into #TempSRSOrderItem(companyidseq,companyname,ordersynchstartmonth,propertyidseq,propertyname,
                               maxbillingperiodToDate,actualunitcount,pricebyppuflag,currentppu,priorppu,priorunitcount,
                               accountidseq,
                               orderitemidseq,quoteidseq,orderidseq,ordergroupidseq, 
                               productcode,priceversion,
                               chargetypecode,frequencycode,frequencyname,measurecode,measurename,familycode,reportingtypecode,
                               productdisplayname,
                               custombundlenameenabledflag,ordergroupname,
                               frequencymultiplier,
                               currentactivationstartdate,currentactivationenddate,
                               renewalactivationstartdate,
                               currentchargeamount,currentnetunitchargeamount,ExtChargeAmount,unitofmeasure,UnitEffectiveQuantity,effectivequantity,discountpercent,currentnetextchargeamount, 
                               socpriceversion,socchargeamount,
                               renewalchargeamount,renewaladjustedchargeamount,renewalstartdate,
                               renewaltypecode,renewalcount,renewalnotes,masterorderitemidseq,renewalreviewedflag,
                               RenewalUserOverrideFlag,LastModifiedbyUser,LastModifiedDate,PreviousYearRenewalNotes,
                               DollarMinimumEnabledFlag,SOCDollarMinimum,DollarMinimum
                            )
  select 
         Max(TOIC.CompanyIDSeq)            as CompanyIDSeq,
         Max(TOIC.companyname)             as companyname,
         Max(TOIC.ordersynchstartmonth)    as ordersynchstartmonth,        
         Max(TOIC.PropertyIDSeq)           as PropertyIDSeq,
         Max(TOIC.propertyname)            as propertyname,
         Max(XII.LastbillingperiodToDate)  as maxbillingperiodToDate,
         Max(TOIC.actualunitcount)         as actualunitcount,
         Max(TOIC.pricebyppuflag)          as pricebyppuflag,
         Max(TOIC.currentppu)              as currentppu,
         MAX(XII.POIPPUPercentage)         as priorppu,
         MAX(XII.POIUnits)                 as priorunitcount, 
         Max(TOIC.AccountIDSeq)            as AccountIDSeq,
         XII.IDSeq                                                               as OrderItemIDSeq,
               Max(TOIC.quoteidseq)                                              as quoteidseq,
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
               ------------------------------------------------------------------------------------------
               /*
                (Max(XII.chargeamount)/
                (case when Max(XII.effectivequantity)=0 
                         then 1
                      else Max(XII.effectivequantity) 
                 end)
                )                                                           as currentchargeamount,
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
                --(select ORDERS.dbo.fn_GetRenewalNotes(XII.orderidseq,XII.ordergroupidseq,XII.IDSeq,XII.ProductCode,XII.RenewalCount+1,'GetRenewalNotes'))
                ''                                                           as renewalnotes,
                Coalesce(XII.MasterOrderItemIDSeq,XII.IDSeq)                 as MasterOrderItemIDSeq,
                Max(Convert(int,XII.renewalreviewedflag))                    as renewalreviewedflag,                
                Max(Convert(int,XII.RenewalUserOverrideFlag))                as RenewalUserOverrideFlag,
               ------------------------------------------------------------------------------------------
                --(select ORDERS.dbo.fn_GetRenewalNotes(XII.orderidseq,XII.ordergroupidseq,XII.IDSeq,XII.ProductCode,XII.RenewalCount+1,'GetRenewalUser'))
                ''                                                           as LastModifiedbyUser,
                --(select ORDERS.dbo.fn_GetRenewalNotes(XII.orderidseq,XII.ordergroupidseq,XII.IDSeq,XII.ProductCode,XII.RenewalCount+1,'GetRenewalReviewedDate'))
                ''                                                           as LastModifiedDate,
                --(select ORDERS.dbo.fn_GetRenewalNotes(XII.orderidseq,XII.ordergroupidseq,XII.IDSeq,XII.ProductCode,XII.RenewalCount-1,'GetRenewalNotes'))
                ''                                                           as PreviousYearRenewalNotes,                                                                   
               ------------------------------------------------------------------------------------------
               coalesce(Max(convert(int,CHG.DollarMinimumEnabledFlag)),Max(convert(int,OCHG.DollarMinimumEnabledFlag)),0) 
                                                                             as DollarMinimumEnabledFlag,
               coalesce(Max(CHG.DollarMinimum),Max(OCHG.DollarMinimum),0.00) 
                                                                             as SOCDollarMinimum,
               Max(coalesce(XII.DollarMinimum,CHG.DollarMinimum,OCHG.DollarMinimum,0.00))
                                                                             as DollarMinimum
               ------------------------------------------------------------------------------------------                
        from   ORDERS.dbo.[Orderitem] XII with (nolock)
        inner join 
               #Temp_SRS_OrdersItemsToConsider TOIC with (nolock)
        on     XII.IDseq           = TOIC.OrderItemIDSeq 
        and    XII.HistoryFlag     = 0       
        inner join
                Products.dbo.Product P with (nolock)
        on      XII.productcode = P.code
        and     XII.priceversion= P.Priceversion 
        and     P.familycode    = Coalesce(@IPVC_FamilyCode,P.familycode) 
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
  GROUP BY XII.IDSeq,XII.OrderIDSeq,XII.OrderGroupIDSeq,XII.MasterOrderItemIDSeq,XII.RenewalCount,XII.ProductCode
  --------------------------------------------------------------------------------------
  ---Step 1.1: update For Company Name,ordersynchstartmonth and PropertyName
  --------------------------------------------------------------------------------------
 /*
  Update D
  set    D.companyname          = S.Name,
         D.ordersynchstartmonth = S.ordersynchstartmonth
  from   #TempSRSOrderItem     D  with (nolock)
  inner join
         CUSTOMERS.DBO.Company S with (nolock)
  on     S.IDSeq = D.CompanyIDSeq

  if (@IPI_IncludeProperties = 1)
  begin
    Update D
    set    D.propertyname         = S.Name
    from   #TempSRSOrderItem     D  with (nolock)
    inner join
           CUSTOMERS.DBO.Property S with (nolock)
    on     S.IDSeq           = D.PropertyIDSeq
    and    S.PMCIDseq        = D.CompanyIDSeq
  end */
  
  if @IPVC_CompanyName <> '' 
  begin
    delete from #TempSRSOrderItem where not (companyname like '%'+@IPVC_CompanyName+'%')
  end;
  if @IPVC_AccountName <> '' 
  begin
    delete from #TempSRSOrderItem where not (accountname like '%'+@IPVC_AccountName+'%')
  end
  if @IPVC_ProductName <> '' 
  begin 
    delete from #TempSRSOrderItem 
    where custombundlenameenabledflag = 0 and not (productdisplayname like '%' + @IPVC_ProductName + '%')
  end 
  --------------------------------------------------------------------------------------
  ---Step 2: Get all Active Price caps for all Companies and Properties and Products in 
  ---        #TempSRSOrderItem
  --------------------------------------------------------------------------------------
  ---Defect Defect8890 : PricecapProperties will also include Corporate/PMCs and also Sites.
  /*
  Insert into #TempSRSpriceCapholdingTable(companyidseq,propertyidseq,pricecapflag,pricecapbasiscode,
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
        and    PC.companyidseq in (select X.CompanyIDSeq from #TempSRSOrderItem X with (nolock))
        and    ltrim(rtrim(PCP.ProductCode)) in (select ltrim(rtrim(T.productcode)) from #TempSRSOrderItem T with (nolock))
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
        and    PC.companyidseq in (select X.CompanyIDSeq from #TempSRSOrderItem X with (nolock))
        and    ltrim(rtrim(PCP.ProductCode)) in (select ltrim(rtrim(T.productcode)) from #TempSRSOrderItem T with (nolock))
        inner join
               CUSTOMERS.dbo.PriceCapProperties PCPRP With (nolock)
        on     PC.IDSeq          = PCPRP.PricecapIDSeq
        and    PC.companyidseq   = PCPRP.companyidseq  
        and    PCPRP.companyidseq  in (select X.CompanyIDSeq  from #TempSRSOrderItem X with (nolock))
        and    PCPRP.PropertyIDSeq in (select X.PropertyIDSeq from #TempSRSOrderItem X with (nolock))
        and    PC.ActiveFlag     = 1
        and    PCP.PricecapIDSeq = PCPRP.PricecapIDSeq
        and    PCP.companyidseq  = PCPRP.companyidseq
       ) S
  group by S.companyidseq,S.Propertyidseq,S.pricecapflag,S.pricecapbasiscode,S.PriceCapPercent,
         S.PriceCapStartDate,S.PriceCapEndDate,S.ProductCode
  */
  
  ---Defect Defect8890 : PricecapProperties will also include Corporate/PMCs and also Sites.
  Insert into #TempSRSpriceCapholdingTable(companyidseq,propertyidseq,pricecapflag,pricecapbasiscode,
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
         #TempSRSOrderItem X with (nolock)
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
  ---Step 3: Update #TempSRSOrderItem with Price caps from Step 2.
  -------------------------------------------------------------------------------------------------
  Update T
  set    T.pricecapflag     = 1,
         T.pricecapbasiscode= S.pricecapbasiscode,
         T.PriceCapPercent  = S.PriceCapPercent,
         T.PriceCapStartDate= S.PriceCapStartDate,
         T.PriceCapEndDate  = S.PriceCapEndDate
  from   #TempSRSpriceCapholdingTable S with (nolock)
  inner join
         #TempSRSOrderItem T  with (nolock)
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
  from #TempSRSOrderItem D with (nolock)
  ------------------------------------------------------------------------------------------------
  ---Step 5: Determine the new product discount percentage and update #TempSRSOrderItem  
  /*
  Update D
  set    D.DiscountPercent = (convert(float,(D.socnetextchargeamount - D.renewalnetextchargeamount))* (100)
                                  /
                              convert(float,(case when D.socnetextchargeamount=0 then 1 else D.socnetextchargeamount end))
                             )
  from #TempSRSOrderItem D with (nolock)
  */

  Update D
  set    D.DiscountPercent = (convert(float,(D.socchargeamount - D.renewaladjustedchargeamountdisplay))* (100)
                                  /
                              convert(float,(case when D.socchargeamount=0 then 1 else D.socchargeamount end))
                             )
  from #TempSRSOrderItem D with (nolock)
  -------------------------------------------------------------------------------------------------  
  Update #TempSRSOrderItem
  set    renewalnotes       = ORDERS.dbo.fn_GetRenewalNotes(orderidseq,ordergroupidseq,orderitemidseq,ProductCode,RenewalCount+1,'GetRenewalNotes'),
         LastModifiedbyUser = ORDERS.dbo.fn_GetRenewalNotes(orderidseq,ordergroupidseq,orderitemidseq,ProductCode,RenewalCount+1,'GetRenewalUser'),
         LastModifiedDate   = ORDERS.dbo.fn_GetRenewalNotes(orderidseq,ordergroupidseq,orderitemidseq,ProductCode,RenewalCount+1,'GetRenewalReviewedDate')

  Update #TempSRSOrderItem
  set    PreviousYearRenewalNotes = ORDERS.dbo.fn_GetRenewalNotes(orderidseq,ordergroupidseq,orderitemidseq,ProductCode,RenewalCount-1,'GetRenewalNotes')

  -------------------------------------------------------------------------------------------------
  -- Final Insert   
  -------------------------------------------
  ---Step 6.1: Final Insert into #TempSRSRenewalOrderItemFinal for all Custom Bundles.
  Insert into #TempSRSRenewalOrderItemFinal(companyidseq,companyname,propertyidseq,propertyname,accountidseq,accountname,
                                           quoteidseq,orderidseq,ordergroupidseq,orderitemidseq,
                                           frequencyname,measurename,internalname,productdisplayname,
                                           maxbillingperiodToDate,actualunitcount,pricebyppuflag,currentppu,priorppu,priorunitcount,
                                           recordtype,custombundlenameenabledflag,
                                           currentactivationstartdate,currentactivationenddate,renewalactivationstartdate,renewalactivationenddate,
                                           currentchargeamount,yearlycurrentchargeamount,currentnetunitchargeamount,yearlyadjustedcurrentchargeamount,
                                           unitofmeasure,effectivequantity,currentnetextchargeamount,yearlycurrentnetextchargeamount,
                                           socchargeamount,yearlysocchargeamount,socnetextchargeamount,yearlysocnetextchargeamount,
                                           renewalchargeamount,renewaladjustedchargeamountdisplay,yearlyrenewaladjustedchargeamountdisplay,
                                           renewalnetextchargeamount,yearlyrenewalnetextchargeamount,
                                           renewaladjustmenttype,renewaltypecode,renewaltypename,renewalreviewedflag,renewalcount,renewalnotes,
                                           orderitemcount,pricecapflag,RenewalUserOverrideFlag,productcode,
                                           LastModifiedbyUser,LastModifiedDate,PreviousYearRenewalNotes,
                                           SOCDollarMinimum,AnnualizedSOCDollarMinimum,DollarMinimum,AnnualizedDollarMinimum,DollarMinimumAppliedRule
                                          )
  select T.companyidseq,T.companyname,T.propertyidseq,T.propertyname,T.accountidseq,T.accountname,
         T.quoteidseq,T.orderidseq,T.ordergroupidseq,T.orderitemidseq,
         T.frequencyname,T.measurename,T.internalname,T.productdisplayname,
         T.maxbillingperiodToDate,T.actualunitcount,T.pricebyppuflag,T.currentppu,T.priorppu,T.priorunitcount, 
         T.recordtype,T.custombundlenameenabledflag,
         T.currentactivationstartdate,T.currentactivationenddate,T.renewalactivationstartdate,T.renewalactivationenddate,
         T.currentchargeamount,T.yearlycurrentchargeamount,T.currentnetunitchargeamount,T.yearlyadjustedcurrentchargeamount,
         T.unitofmeasure,convert(numeric(30,2),T.effectivequantity) as effectivequantity,
         T.currentnetextchargeamount,T.yearlycurrentnetextchargeamount,
         T.socchargeamount,T.yearlysocchargeamount,T.socnetextchargeamount,T.yearlysocnetextchargeamount,
         T.renewalchargeamount,T.renewaladjustedchargeamountdisplay,T.yearlyrenewaladjustedchargeamountdisplay,
         T.renewalnetextchargeamount,T.yearlyrenewalnetextchargeamount,
         T.renewaladjustmenttype,T.renewaltypecode,T.renewaltypename,T.renewalreviewedflag,T.renewalcount,T.renewalnotes,
         T.orderitemcount,T.pricecapflag,T.RenewalUserOverrideFlag,T.productcode,
         T.LastModifiedbyUser,T.LastModifiedDate,T.PreviousYearRenewalNotes,
         T.SOCDollarMinimum,T.AnnualizedSOCDollarMinimum,T.DollarMinimum,T.AnnualizedDollarMinimum,T.DollarMinimumAppliedRule
  from (
  select companyidseq,companyname,propertyidseq,propertyname,accountidseq,accountname,
         max(quoteidseq) as quoteidseq,orderidseq,ordergroupidseq,max(orderitemidseq) as orderitemidseq,
         max(frequencyname) as frequencyname,max(measurename) as measurename,
         min(productdisplayname) as internalname,max(ordergroupname) as productdisplayname,
         Max(maxbillingperiodToDate) as maxbillingperiodToDate,max(actualunitcount) as actualunitcount,
         Max(pricebyppuflag) as pricebyppuflag,max(currentppu) as currentppu,
         max(priorppu) as priorppu,Max(priorunitcount) as priorunitcount,
         'CB' as recordtype,1 as custombundlenameenabledflag,
         max(currentactivationstartdate) as currentactivationstartdate,max(currentactivationenddate) as currentactivationenddate,
         max(renewalactivationstartdate) as renewalactivationstartdate,max(renewalactivationenddate) as renewalactivationenddate,
         sum(currentchargeamount) as currentchargeamount,
         sum(yearlycurrentchargeamount) as yearlycurrentchargeamount,
         sum(currentnetunitchargeamount) as currentnetunitchargeamount,
         sum(yearlyadjustedcurrentchargeamount) as yearlyadjustedcurrentchargeamount,
         sum(distinct unitofmeasure) as unitofmeasure,
         ---sum(distinct effectivequantity)  as effectivequantity,
         /*
          convert(numeric(30,2),sum(yearlycurrentnetextchargeamount))/
            (Case when convert(numeric(30,2),sum(yearlyadjustedcurrentchargeamount)) =  0 then 1 else convert(numeric(30,2),sum(yearlyadjustedcurrentchargeamount)) end) 
                                        as effectivequantity,
         */
         convert(money,sum(currentnetextchargeamount))/
            (Case when convert(money,sum(currentnetunitchargeamount)) =  0 then 1 else convert(money,sum(currentnetunitchargeamount)) end) 
                                        as effectivequantity,         
         sum(currentnetextchargeamount) as currentnetextchargeamount,
         sum(yearlycurrentnetextchargeamount) as yearlycurrentnetextchargeamount,
         sum(socchargeamount) as socchargeamount,
         sum(yearlysocchargeamount) as yearlysocchargeamount,
         sum(socnetextchargeamount) as socnetextchargeamount,
         sum(yearlysocnetextchargeamount) as yearlysocnetextchargeamount,
         sum(renewalchargeamount)         as renewalchargeamount,
         sum(renewaladjustedchargeamountdisplay) as renewaladjustedchargeamountdisplay,
         sum(yearlyrenewaladjustedchargeamountdisplay) as yearlyrenewaladjustedchargeamountdisplay,
         sum(renewalnetextchargeamount) as renewalnetextchargeamount,
         sum(yearlyrenewalnetextchargeamount) as yearlyrenewalnetextchargeamount,
         (case when (max(S.renewaluseroverrideflag)=1)
                 then 'User Adjusted'
               when (max(S.pricecapflag)=1)
                 then 'Price Cap'               
               else 'N/A'
          end) as  renewaladjustmenttype,
         max(renewaltypecode)         as renewaltypecode,
         max(renewaltypename)         as renewaltypename,
         max(renewalreviewedflag)     as renewalreviewedflag,
         max(renewalcount)            as renewalcount,
         max(renewalnotes)            as renewalnotes,
         count(orderitemidseq)        as orderitemcount,
         max(pricecapflag)            as pricecapflag,
         max(RenewalUserOverrideFlag) as renewaluseroverrideflag,
         max(productcode)             as productcode,
         max(LastModifiedbyUser)      as LastModifiedbyUser,
         max(LastModifiedDate)        as LastModifiedDate,
         max(PreviousYearRenewalNotes) as PreviousYearRenewalNotes,
         
         NULL                          as SOCDollarMinimum,
         NULL                          as AnnualizedSOCDollarMinimum,
         NULL                          as DollarMinimum,
         NULL                          as AnnualizedDollarMinimum,
         (case when (Max(DollarMinimumUsedFlag)=1 and Max(DollarMinimumUsedFlag)=1)
                 then 'YES' --->'Custom bundle has one or more product(s) that have Dollar Minimum applied'
               when (Max(DollarMinimumUsedFlag)=1 and Max(DollarMinimumUsedFlag)=0)
                 then 'NO'
               else ''
          end)                         as DollarMinimumAppliedRule   

  from  #TempSRSOrderItem S with (nolock)
  where S.custombundlenameenabledflag = 1
  and   S.companyname like '%'+@IPVC_CompanyName+'%'
  and   S.accountname like '%'+@IPVC_AccountName+'%'
  and   (@IPVC_ProductName='' 
               OR
         exists (select top 1 1 from #TempSRSOrderItem XI with (nolock)
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
  --Step 6.3: Final Insert into #TempSRSRenewalOrderItemFinal for all NON Custom Bundle Products.
  --------------------------------------------------------------------
  select companyidseq,companyname,propertyidseq,propertyname,accountidseq,accountname,
         quoteidseq,orderidseq,ordergroupidseq,orderitemidseq,
         frequencyname,measurename,
         productdisplayname as internalname,productdisplayname as productdisplayname,
         maxbillingperiodToDate as maxbillingperiodToDate,actualunitcount as actualunitcount,pricebyppuflag as pricebyppuflag,currentppu as currentppu,
         priorppu as priorppu,priorunitcount as priorunitcount,
         'PR' as recordtype,0 as custombundlenameenabledflag,
         currentactivationstartdate,currentactivationenddate,renewalactivationstartdate,renewalactivationenddate,
         currentchargeamount,yearlycurrentchargeamount,currentnetunitchargeamount,yearlyadjustedcurrentchargeamount,
         unitofmeasure,
         --effectivequantity,
         /*
          convert(numeric(30,2),(yearlycurrentnetextchargeamount))/
            (Case when convert(numeric(30,2),(yearlyadjustedcurrentchargeamount)) =  0 then 1 else convert(numeric(30,2),(yearlyadjustedcurrentchargeamount)) end) 
                                        as effectivequantity,
         */
        convert(money,(currentnetextchargeamount))/
            (Case when convert(money,(currentnetunitchargeamount)) =  0 then 1 else convert(money,(currentnetunitchargeamount)) end) 
                                        as effectivequantity,
         currentnetextchargeamount,yearlycurrentnetextchargeamount,
         socchargeamount,yearlysocchargeamount,socnetextchargeamount,yearlysocnetextchargeamount,
         renewalchargeamount,renewaladjustedchargeamountdisplay,yearlyrenewaladjustedchargeamountdisplay,
         renewalnetextchargeamount,yearlyrenewalnetextchargeamount,
         (case when (S.renewaluseroverrideflag=1 )
                 then 'User Adjusted'
               when (S.pricecapflag=1 )
                 then 'Price Cap'
               else 'N/A'
          end) as  renewaladjustmenttype,
         renewaltypecode,renewaltypename,renewalreviewedflag,renewalcount,renewalnotes,1 as orderitemcount,
         pricecapflag,RenewalUserOverrideFlag,productcode,
         LastModifiedbyUser,LastModifiedDate,PreviousYearRenewalNotes,
         (case when (S.DollarMinimumEnabledFlag=1)
                 then S.SOCDollarMinimum
               else NULL
          end)                          as SOCDollarMinimum,
         (case when (S.DollarMinimumEnabledFlag=1)
                 then S.AnnualizedSOCDollarMinimum
               else NULL
          end)                          as AnnualizedSOCDollarMinimum,

         (case when (S.DollarMinimumEnabledFlag=1 and S.DollarMinimumUsedFlag=1)
                 then DollarMinimum
               else NULL
          end)                          as DollarMinimum,
         (case when (S.DollarMinimumEnabledFlag=1 and S.DollarMinimumUsedFlag=1)
                 then AnnualizedDollarMinimum
               else NULL
          end)                          as AnnualizedDollarMinimum,
         (case when (S.DollarMinimumEnabledFlag=1 and S.DollarMinimumUsedFlag=1)
                 then 'YES' --->DollarMinimumAppliedRule
                when (S.DollarMinimumEnabledFlag=1 and S.DollarMinimumUsedFlag=0)
                 then 'NO' 
               else ''
          end)                          as DollarMinimumAppliedRule
  from  #TempSRSOrderItem S with (nolock)
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
                 else (RANK() OVER (ORDER BY renewalactivationstartdate ASC,companyname ASC,accountname ASC,recordtype ASC,productdisplayname ASC))
             end)
  -----------------------------------------------------------------------------------------
  -------------------------------------------------------------------------------------------------------------
  --- The idea is to get the Unit,Beds,PPU corresponding to Orderitem of interest from Invoiceitem record 
  --   that has the maximum billing period and that it is on a Printed Invoice that is recently sent out to customer
  --------------------------------------------------------------------------------------------------------------
  /*Update D
  set    D.maxbillingperiodFromDate = X.BillingPeriodFromDate,
         D.maxbillingperiodToDate   = X.BillingPeriodToDate
  from   #TempSRSRenewalOrderItemFinal D with (nolock)
  inner join  ---> Below extra join is to eliminate costly Subquery if it had to be incorporated as part of above.
         (select T.orderidseq,T.ordergroupidseq,T.orderitemidseq,I.accountidseq,
                 Max(II.BillingPeriodFromDate) as BillingPeriodFromDate, 
                 Max(II.BillingPeriodToDate)   as BillingPeriodToDate
          from   Invoices.dbo.Invoice I with (nolock)
          inner join
                 Invoices.dbo.InvoiceItem II with (nolock)
          on     I.InvoiceIDSeq = II.InvoiceIDSeq
          and    I.Printflag    = 1
          and    II.OrderitemTransactionIDSeq is NULL
          and    II.Chargetypecode = 'ACS'  
          and    II.MeasureCode    <> 'TRAN'
          inner join
                 #TempSRSRenewalOrderItemFinal T with (nolock)
          on     II.orderidseq      = T.orderidseq 
          and    II.ordergroupidseq = T.ordergroupidseq
          and    II.orderitemidseq  = T.orderitemidseq
          group by T.orderidseq,T.ordergroupidseq,T.orderitemidseq,I.accountidseq
         ) X
  on     D.accountidseq    = X.accountidseq
  and    D.orderidseq      = X.orderidseq
  and    D.ordergroupidseq = X.ordergroupidseq
  and    D.orderitemidseq  = X.orderitemidseq 
  */
  

  /*update D
  set    D.priorppu       = S.ppupercentage,
         D.priorunitcount = S.Units
  from   #TempSRSRenewalOrderItemFinal D with (nolock)
  inner join
         (select T.orderidseq,T.ordergroupidseq,T.orderitemidseq,T.accountidseq,
                 Max(II.Units) as Units,Max(II.Beds) as Beds,Max(II.ppupercentage) as ppupercentage,
                 Max(II.BillingPeriodFromDate) as BillingPeriodFromDate, 
                 Max(II.BillingPeriodToDate)   as BillingPeriodToDate
          from   #TempSRSRenewalOrderItemFinal T with (nolock) --> This is reduce cost of join by looking at only items of iterest rather than entire Invoicing system
          inner join
                 Invoices.dbo.InvoiceItem II with (nolock)
          on     II.orderidseq      = T.orderidseq 
          and    II.ordergroupidseq = T.ordergroupidseq
          and    II.orderitemidseq  = T.orderitemidseq          
          and    II.BillingPeriodToDate   = T.maxbillingperiodToDate
          and    T.maxbillingperiodToDate is not null 
          and    II.OrderitemTransactionIDSeq is NULL           --> Renewals apply only to Access subscriptions.Transactions are eliminated for reduced filter set lookup. 
          and    II.Chargetypecode  = 'ACS'                     --> Renewals apply only to Access subscriptions.for extra reduced filter set lookup
          and    II.MeasureCode    <> 'TRAN'
          inner join
                 Invoices.dbo.Invoice I with (nolock)                 
          on     II.InvoiceIDSeq= I.InvoiceIDSeq
          and    I.accountidseq = T.accountidseq 
          and    I.Printflag    = 1                            --> This denotes the final lockdown invoice that was sent to customer.
          group by T.orderidseq,T.ordergroupidseq,T.orderitemidseq,T.accountidseq          
         ) S
  on     D.accountidseq    = S.accountidseq
  and    D.orderidseq      = S.orderidseq
  and    D.ordergroupidseq = S.ordergroupidseq
  and    D.orderitemidseq  = S.orderitemidseq   
  and    D.maxbillingperiodToDate   = S.BillingPeriodToDate   
  */
    
  -----------------------------------------------------------------------------------------
  set identity_insert #TempSRSRenewalOrderItemFinal on
  Insert into #TempSRSRenewalOrderItemFinal(sortseq,companyidseq,companyname,propertyidseq,propertyname,accountidseq,accountname,
                                           quoteidseq,orderidseq,ordergroupidseq,orderitemidseq,
                                           frequencyname,measurename,internalname,productdisplayname,
                                           actualunitcount,pricebyppuflag,currentppu,priorppu,priorunitcount,
                                           recordtype,custombundlenameenabledflag,
                                           currentactivationstartdate,currentactivationenddate,renewalactivationstartdate,renewalactivationenddate,
                                           currentchargeamount,yearlycurrentchargeamount,currentnetunitchargeamount,yearlyadjustedcurrentchargeamount,
                                           unitofmeasure,effectivequantity,currentnetextchargeamount,yearlycurrentnetextchargeamount,
                                           socchargeamount,yearlysocchargeamount,socnetextchargeamount,yearlysocnetextchargeamount,
                                           renewalchargeamount,renewaladjustedchargeamountdisplay,yearlyrenewaladjustedchargeamountdisplay,
                                           renewalnetextchargeamount,yearlyrenewalnetextchargeamount,
                                           renewaladjustmenttype,renewaltypecode,renewaltypename,renewalreviewedflag,renewalcount,renewalnotes,
                                           orderitemcount,pricecapflag,RenewalUserOverrideFlag,productcode,
                                           LastModifiedbyUser,LastModifiedDate,PreviousYearRenewalNotes,
                                           SOCDollarMinimum,AnnualizedSOCDollarMinimum,DollarMinimum,AnnualizedDollarMinimum,DollarMinimumAppliedRule
                                          )
  select S.sortseq,S.companyidseq,S.companyname,S.propertyidseq,S.propertyname,S.accountidseq,S.accountname,
         S.quoteidseq,S.orderidseq,S.ordergroupidseq,S.orderitemidseq as orderitemidseq,
         NULL as Frequencyname,NULL as measurename,
         T.productdisplayname as internalname,T.productdisplayname as productdisplayname,
         NULL actualunitcount,0 as pricebyppuflag, NULL as currentppu,NULL as priorppu,NULL as priorunitcount,
         'CR' as recordtype,1 as custombundlenameenabledflag,
         NULL as currentactivationstartdate,NULL as currentactivationenddate,
         NULL as renewalactivationstartdate,NULL as renewalactivationenddate,
         NULL as currentchargeamount,
         NULL as yearlycurrentchargeamount,
         NULL as currentnetunitchargeamount,
         NULL as yearlyadjustedcurrentchargeamount,
         NULL as unitofmeasure,
         NULL as effectivequantity,
         NULL as currentnetextchargeamount,         
         NULL as yearlycurrentnetextchargeamount,
         NULL as socchargeamount,
         NULL as yearlysocchargeamount,
         NULL as socnetextchargeamount,
         NULL as yearlysocnetextchargeamount,
         NULL as renewalchargeamount,
         NULL as renewaladjustedchargeamountdisplay,
         NULL as yearlyrenewaladjustedchargeamountdisplay, 
         NULL as renewalnetextchargeamount,
         NULL as yearlyrenewalnetextchargeamount,
         NULL as renewaladjustmenttype,
         NULL as renewaltypecode,
         NULL as renewaltypename,
         NULL as renewalreviewedflag,
         NULL as renewalcount,
         NULL as renewalnotes,
         NULL as orderitemcount,
         T.pricecapflag            as pricecapflag,
         T.RenewalUserOverrideFlag as renewaluseroverrideflag,
         T.productcode             as productcode,
         NULL                      as LastModifiedbyUser,
         NULL                      as LastModifiedDate,
         NULL                      as PreviousYearRenewalNotes,
         (case when (T.DollarMinimumEnabledFlag=1)
                 then T.SOCDollarMinimum
               else NULL
          end)                          as SOCDollarMinimum,
         (case when (T.DollarMinimumEnabledFlag=1)
                 then T.AnnualizedSOCDollarMinimum
               else NULL
          end)                          as AnnualizedSOCDollarMinimum,

         (case when (T.DollarMinimumEnabledFlag=1 and T.DollarMinimumUsedFlag=1)
                 then T.DollarMinimum
               else NULL
          end)                          as DollarMinimum,
         (case when (T.DollarMinimumEnabledFlag=1 and T.DollarMinimumUsedFlag=1)
                 then T.AnnualizedDollarMinimum
               else NULL
          end)                          as AnnualizedDollarMinimum,
         (case when (T.DollarMinimumEnabledFlag=1 and T.DollarMinimumUsedFlag=1)
                 then 'YES' --->DollarMinimumAppliedRule
               when (T.DollarMinimumEnabledFlag=1 and T.DollarMinimumUsedFlag=0)
                 then 'NO'
               else ''
          end)                          as DollarMinimumAppliedRule
  from  #TempSRSRenewalOrderItemFinal S with (nolock)
  inner join
        #TempSRSOrderItem T with (nolock) 
  on    S.orderidseq = T.orderidseq
  and   S.ordergroupidseq = T.ordergroupidseq
  and   S.custombundlenameenabledflag = T.custombundlenameenabledflag
  and   S.custombundlenameenabledflag = 1
  and   T.custombundlenameenabledflag = 1
  and   S.recordtype = 'CB'
  order by S.sortseq asc
  set identity_insert #TempSRSRenewalOrderItemFinal off;
  ----------------------------------------------------------------------------------------- 
  --Important : Creating Non clustered Index on sortseq,recordtype,RowNumber
  set ansi_warnings on;
  CREATE NONCLUSTERED INDEX [ix_seq_SRSRenewalOrderItemFinal] on #TempSRSRenewalOrderItemFinal(sortseq,recordtype)
  INCLUDE (RowNumber,companyname,accountname,productdisplayname,renewaladjustmenttype,
           currentactivationstartdate,currentactivationenddate,renewalactivationstartdate,renewalactivationenddate,
           renewaltypename,
           priorppu,currentppu,pricebyppuflag,actualunitcount,effectivequantity,measurename,frequencyname,
           currentchargeamount,yearlyadjustedcurrentchargeamount,
           currentnetunitchargeamount,currentnetextchargeamount,socchargeamount,socnetextchargeamount,
           renewaladjustedchargeamountdisplay,renewalnetextchargeamount,yearlycurrentchargeamount,
           yearlycurrentnetextchargeamount,yearlysocchargeamount,yearlysocnetextchargeamount,
           yearlyrenewaladjustedchargeamountdisplay,yearlyrenewalnetextchargeamount,
           renewalreviewedflag,renewalnotes,productcode,LastModifiedbyUser,LastModifiedDate,PreviousYearRenewalNotes
          );
  update #TempSRSRenewalOrderItemFinal SET @LBI_Counter = RowNumber = @LBI_Counter + 1  
  set ansi_warnings off;
  --select @LBI_TotalRecords = count(SortSeq) from  #TempSRSRenewalOrderItemFinal WITH (NOLOCK)
  ----------------------------------------------------------------------------------------- 
  ---Update for Company State Infomation
  Update D
  set    D.companystate = A.State
  from   #TempSRSRenewalOrderItemFinal D with (nolock)
  inner join
         Customers.dbo.Address A with (nolock)
  on     D.CompanyIDSeq    = A.CompanyIDSeq
  and    A.addresstypecode = 'COM'
  and    A.PropertyIDSeq   is null

  ----------------------------------------------------------------------------------------- 
  SELECT --@LBI_TotalRecords as TotalRecords,
         -------------------------------------
         -- Main SRS columns
         S.companyidseq                          as [Customer ID],
         S.companyname                           as [Customer (PMC)],
         S.companystate                          as [Company State],
         S.accountidseq                          as [Account ID],
         S.accountname                           as [Account (PMC/Site)],
         S.quoteidseq                            as [QuoteIDSeq],
         S.orderidseq                            as [OrderIDSeq],
         S.ordergroupidseq                       as [OrderGroupIDSeq],
         S.orderitemidseq                        as [OrderItemIDSeq], 
         S.productdisplayname                    as [Product],
         S.renewaladjustmenttype                 as [Renewal Adjustment Type],
         S.currentactivationstartdate            as [Contract Start Date],
         S.currentactivationenddate              as [Expires],
         S.renewalactivationstartdate            as [Renews],
         S.renewalactivationenddate              as [Renewal End Date],
         S.renewaltypename                       as [Renewal Type],
         (Case when S.pricebyppuflag=1
                 then S.priorppu
               else NULL
          end)                                   as [Prior PPU],
         (Case when S.pricebyppuflag=1
                 then S.currentppu
               else NULL
          end)                                   as [Current PPU],
         (case when (S.pricebyppuflag=1 and 
                     S.recordtype <> 'CR'
                    )
                then (coalesce(S.currentppu,0)-
                       coalesce(S.priorppu,0)
                     )
               else NULL
         end)                                    as [PPU Change],               
         S.priorunitcount                        as [Prior Unit Count],
         S.actualunitcount                       as [Current Unit Count],
         (case when S.recordtype <> 'CR'
                 then (coalesce(S.actualunitcount,0)-
                       coalesce(S.priorunitcount,0)
                      )
               else NULL
         end)                                    as [Unit Count Change],
         S.effectivequantity                     as [Effective Quantity],         
         ----------------------------------------------------------------
         S.measurename                           as [Price By],
         S.frequencyname                         as [Frequency],
         ----------------------------------------------------------------
         S.AnnualizedSOCDollarMinimum            as [SOC $ Minimum],          ---> Ann confirmed that this should be Annualized SOC $ min shown as [SOC $ Minimum]
         --->S.SOCDollarMinimum                  as [SOC $ Minimum],          ---> At this time we are not showing individual monthly $ SOC min. Commented.
         S.AnnualizedDollarMinimum               as [$ Minimum Applied],      ---> Ann confirmed that this should be Annualized $ min shown as [$ Minimum Applied]       
         --->S.DollarMinimum                     as [$ Minimum Applied],      ---> At this time we are not showing individual monthly $ min. Commented.
         S.DollarMinimumAppliedRule              as [$ Minimum Applied Rule], ---> This will show YES,NO and blank
         ----------------------------------------------------------------
         /*
         --Unadjusted to Yearly Columns
         S.currentchargeamount                   as [Current Base Price],
         S.currentnetextchargeamount             as [Current Extended Net],
         S.socchargeamount                       as [List Base Price],
         S.socnetextchargeamount                 as [List Extended Net],
         S.renewaladjustedchargeamountdisplay    as [Renewal Base Price],
         S.renewalnetextchargeamount             as [Renewal Extended Net],
         */
         --Adjusted to Yearly Columns
         S.yearlycurrentchargeamount                   as [SOC Origninal Price],
         S.yearlyadjustedcurrentchargeamount           as [Current Adjusted Base Price],
         S.yearlycurrentnetextchargeamount             as [Current Extended Net],
         S.yearlysocchargeamount                       as [List Base Price],
         S.yearlysocnetextchargeamount                 as [List Extended Net],
         S.yearlyrenewaladjustedchargeamountdisplay    as [Renewal Base Price],
         S.yearlyrenewalnetextchargeamount             as [Renewal Extended Net],
         ----------------------------------------------------------------
         ---calculated columns : Set 1
         (case when S.recordtype <> 'CR'
                then (S.yearlyrenewaladjustedchargeamountdisplay-S.yearlyadjustedcurrentchargeamount)
               else NULL
          end)                                         as [Renewal Vs Current Adjusted Base Price Difference],
         (case when S.recordtype <> 'CR'
                then (S.yearlyrenewalnetextchargeamount-S.yearlycurrentnetextchargeamount)
               else NULL
          end)                                         as [Renewal Vs Current Extended Net Difference],
         convert(numeric(30,4),(case when S.recordtype <> 'CR'
                then ((S.yearlyrenewalnetextchargeamount-S.yearlycurrentnetextchargeamount)*100)/
                     (case when S.yearlycurrentnetextchargeamount = 0 then 1
                           else S.yearlycurrentnetextchargeamount
                      end)     
               else NULL
          end))                                         as [Renewal Vs Current %],         
         ----------------------------------------------------------------
         ---calculated columns : Set 2
         (case when S.recordtype <> 'CR'
                then (S.yearlyrenewaladjustedchargeamountdisplay-S.yearlysocchargeamount)
               else NULL
          end)                                         as [Renewal Vs List Base Price Difference],
         (case when S.recordtype <> 'CR'
                then (S.yearlyrenewalnetextchargeamount-S.yearlysocnetextchargeamount)
               else NULL
          end)                                         as [Renewal Vs List Extended Net Difference],
         (case when S.recordtype <> 'CR'
                then ((S.yearlysocnetextchargeamount-S.yearlyrenewalnetextchargeamount)*100)/
                     (case when S.yearlysocnetextchargeamount = 0 then 1
                           else S.yearlysocnetextchargeamount 
                      end)     
               else NULL
          end)                                         as [Renewal Vs List %],         
         ----------------------------------------------------------------
         -- Other Columns         
         (Case when (S.pricecapflag=1) 
                 then 'YES'
               when (S.pricecapflag=0) 
                 then 'NO'
          else NULL end)                               as [PriceCap Available],
          (case when (S.recordtype <> 'CR' and S.renewaluseroverrideflag = 1)
                 then 'YES' 
               when (S.recordtype <> 'CR' and S.renewaluseroverrideflag = 0)
                 then 'NO'
          else NULL end)                               as [Overriden By User], 
         (case when (S.recordtype <> 'CR' and S.renewalreviewedflag = 1)
                 then 'YES' 
               when (S.recordtype <> 'CR' and S.renewalreviewedflag = 0)
                 then 'NO'
          else NULL end)                               as [Reviewed],
         S.renewalnotes                                as [Renewal Notes],
         ---------------------------------------                  
         S.PreviousYearRenewalNotes                    as [Previous Year Renewal Notes],
         S.LastModifiedbyUser                          as [Last Modified By User],
         S.LastModifiedDate                            as [Last Modified Date]
         ---------------------------------------                  
  FROM #TempSRSRenewalOrderItemFinal S WITH (NOLOCK) 
  order by  S.RowNumber asc,S.sortseq asc,S.recordtype ASC
  -----------------------------------------------------------------------------------------  
  ---Final Cleanup
  -----------------------------------------------------------------------------------------
  if (object_id('tempdb.dbo.#TempSRSpriceCapholdingTable') is not null) drop table #TempSRSpriceCapholdingTable;
  if (object_id('tempdb.dbo.#Temp_SRSOrderItemsfirst') is not null) drop table #Temp_SRSOrderItemsfirst;
  if (object_id('tempdb.dbo.#Temp_SRS_OrdersItemsToConsider') is not null) drop table #Temp_SRS_OrdersItemsToConsider;
  if (object_id('tempdb.dbo.#TempSRSOrderItem') is not null) drop table #TempSRSOrderItem;
  if (object_id('tempdb.dbo.#TempSRSRenewalOrderItemFinal') is not null) drop table #TempSRSRenewalOrderItemFinal; 
  -----------------------------------------------------------------------------------------
END
GO
