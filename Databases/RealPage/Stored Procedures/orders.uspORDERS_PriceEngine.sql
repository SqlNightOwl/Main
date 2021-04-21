SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec ORDERS.DBO.uspORDERS_PriceEngine @IPVC_OrderID='O0712078844',@IPI_GroupID=42405
CREATE PROCEDURE [orders].[uspORDERS_PriceEngine] (@IPVC_OrderID        varchar(50),
                                                @IPI_GroupID         bigint=-9999,
                                                @IPI_OrderItemID     bigint=-9999                                           
                                               )
AS
BEGIN   
  set nocount on 
  SET CONCAT_NULL_YIELDS_NULL OFF
  -------------------------------------------------------------------------------------------------
  --Declaring Local Temp Tables  
  create table #TEMP_PropertiesProductsHoldingTable 
                               (SEQ                           int not null identity(1,1),
                                orderid                       varchar(50),
                                groupid                       bigint, 
                                orderitemid                   bigint, 
                                statuscode                    varchar(50),
                                renewaltypecode               varchar(50),
                                propertyid                    varchar(50)   null,
                                pricetypecode                 varchar(50)   not null default 'Normal',
                                SOCpricetypecode              as (case when SOCunits < 100 then 'Small'
                                                                       Else 'Normal'
                                                                  end),
                                propertythresholdoverride     int           not null default 0,
                                pricecapflag                  int           not null default 0,
                                pricecapterm                  int           not null default 0,
                                pricecapbasiscode             varchar(50)   not null default 'LIST',
                                PriceCapPercent               numeric(30,5) not null default 0.00,
                                PriceCapStartDate             datetime      null,
                                PriceCapEndDate               datetime      null,
                                grouptype                     varchar(50)   not null default 'SITE',
                                productcode                   varchar(100),
                                productexpirationdate         varchar(50),
                                productdisplayname            varchar(500),
                                productcategorycode           varchar(50),                                
                                familycode                    varchar(50),                                                              
                                chargetypecode                varchar(50), 
                                chargetypename                as (case when chargetypecode='ILF' then 'Initial License Fee'
                                                                       when chargetypecode='ACS' then 'Access Fee'
                                                                     else ''
                                                                  end),
                                measurecode                   varchar(50),                                
                                frequencycode                 varchar(50),
                                frequencymultiplier           as (case when frequencycode = 'SG' then 1
                                                                       when frequencycode = 'OT' then 1
                                                                       when frequencycode = 'YR' then 1
                                                                       when frequencycode = 'QR' then 4
                                                                       when frequencycode = 'MN' then 12
                                                                       when frequencycode = 'DY' then 1
                                                                       when frequencycode = 'HR' then 1
                                                                       when frequencycode = 'OC' then 1
                                                                  end),
                                frequencyname                 as  (case  when frequencycode='DY' then 'Day'
                                                                         when frequencycode='HR' then 'Hourly'
                                                                         when frequencycode='MI' then 'Minutes'
                                                                         when frequencycode='MN' then 'Monthly'
                                                                         when frequencycode='OC' then 'Usage'
                                                                         when frequencycode='QR' then 'Quarterly'
                                                                         when frequencycode='SG' then 'Initial Fee'
                                                                         when frequencycode='OT' then 'One-time'
                                                                         when frequencycode='YR' then 'Annual'
                                                                         else ''
                                                                   end),
                                sites                         numeric(30,0) not null default 0,
                                units                         numeric(30,0) not null default 0,                                
                                SOCunits                      numeric(30,0) not null default 0,
                                oiunits                       numeric(30,0) not null default 0,
                                oibeds                        numeric(30,0) not null default 0,                                
                                ppupercentage                 numeric(30,2) not null default 100,
                                ppuadjustedunits              numeric(30,0) not null default 0,
                                ---ppuadjustedunits              as convert(numeric(30,0),round((convert(numeric(30,5),(units * ppupercentage))/(100)),0)),
                                SOCppuadjustedunits           as convert(numeric(30,0),round((convert(numeric(30,5),(SOCunits * ppupercentage))/(100)),0)),
                                quantity                      numeric(30,5) not null default 1,
                                unitbasis                     numeric(30,5) not null default 1,
                                minunits                      numeric(30,0) not null default 0,
                                maxunits                      numeric(30,0) not null default 0,
                                SOCminunits                   numeric(30,0) not null default 0,
                                SOCmaxunits                   numeric(30,0) not null default 0,
                                FlatPriceFlag                 int           not null default 0,
                                minthresholdoverride          int           not null default 1,
                                maxthresholdoverride          int           not null default 1,
                                quantityenabledflag           int           not null default 0,
                                explodequantityatorderflag    int           not null default 0,
                                quantitymultiplierflag        int           not null default 0,
                                dollarminimum                 money         not null default 0,
                                dollarminimumenabledflag      int           not null default 0,
                                dollarmaximum                 money         not null default 0,
                                dollarmaximumenabledflag      int           not null default 0,
                                --------------------------------------------------------------
                                SOCdollarminimum              money         not null default 0,
                                SOCdollarminimumenabledflag   int           not null default 0,
                                SOCdollarmaximum              money         not null default 0,
                                SOCdollarmaximumenabledflag   int           not null default 0,
                                --------------------------------------------------------------
                                chargeamount                  numeric(30,3) not null default 0,
                                SOCchargeamount               numeric(30,3) not null default 0,
                                discountpercent               float not null default 0.00,
                                discountamount                numeric(30,2) not null default 0,
                                totaldiscountpercent          float not null default 0.00,
                                totaldiscountamount           numeric(30,2) not null default 0,
                                unitofmeasure                 numeric(30,5) not null default 0.00,
                                multiplier                    decimal(18,6) not null default 0.00,                                 
                                extchargeamount               numeric(30,5) not null default 0,-->
                                extSOCchargeamount            numeric(30,5) not null default 0,-->
                                extyear1chargeamount          numeric(30,5) not null default 0,-->                               
                                netchargeamount               numeric(30,3) not null default 0,
                                netextchargeamount            numeric(30,5) not null default 0,-->
                                netextyear1chargeamount       numeric(30,5) not null default 0,-->                                
                                weightofProducttototal        numeric(30,5) not null default 1,
                                custombundlenameenabledflag   int           not null default 0,
                                custombundleTotalamount       numeric(30,2) not null default 0,
                                discallocationcode            varchar(50)   not null default 'SPR',
                                activationstartdate           datetime      null,
                                activationenddate             datetime      null,
                                renewalcount                  bigint        not null default 0,                                
                                -------------------------------------------------------
                                pricingtiers                  int           not null default 1,
                                pricebybedsflag               int           not null default 0,
                                PriceByPPUPercentageEnabledFlag int         not null default 0,
                                PricingLineItemNotes          varchar(8000) NULL  
                                -------------------------------------------------------
                               )                                      
  -------------------------------------------------------------------------------------------------  
  declare @LVC_CompanyID             varchar(50);
  declare @LI_ordersynchstartmonth   int;

  select @LVC_CompanyID       = O.CompanyIDSeq
  from   ORDERS.dbo.[Order] O with (nolock)
  where  O.OrderIDSeq = @IPVC_OrderID   

  select @LI_ordersynchstartmonth = C.ordersynchstartmonth
  from   CUSTOMERS.dbo.Company C with (nolock)
  where  C.IDSeq = @LVC_CompanyID
  -------------------------------------------------------------------------------------------------

  insert into #TEMP_PropertiesProductsHoldingTable
             (orderid,groupid,orderitemid,statuscode,renewaltypecode,
              propertyid,pricetypecode,propertythresholdoverride,
              grouptype,productcode,productexpirationdate,
              productdisplayname,
              productcategorycode,familycode,chargetypecode,measurecode,
              frequencycode,sites,units,SOCunits,oiunits,oibeds,
              ppupercentage,ppuadjustedunits,
              quantity,unitbasis,minunits,maxunits,SOCminunits,SOCmaxunits,FlatPriceFlag,
              minthresholdoverride,
              maxthresholdoverride,quantityenabledflag,explodequantityatorderflag,quantitymultiplierflag,
              dollarminimum,dollarminimumenabledflag,dollarmaximum,dollarmaximumenabledflag,
              SOCdollarminimum,SOCdollarminimumenabledflag,SOCdollarmaximum,SOCdollarmaximumenabledflag,
              chargeamount,SOCchargeamount,discountpercent,discountamount,netchargeamount,
              custombundlenameenabledflag,discallocationcode,activationstartdate,activationenddate,renewalcount,
              pricebybedsflag,PriceByPPUPercentageEnabledFlag,PricingLineItemNotes)
  Select     distinct
             OI.OrderIDSeq                               as orderid,
             OI.OrderGroupIDSeq                          as groupid,
             OI.IDSeq                                    as orderitemid,
             OI.statuscode                               as statuscode,
             OI.renewaltypecode                          as renewaltypecode,
             P.IDSeq                                     as propertyid,
             coalesce(GP.PriceTypeCode,'Normal')         as pricetypecode,
             coalesce(GP.thresholdoverrideflag,0)        as propertythresholdoverride,                          
             ltrim(rtrim(G.OrderGroupType))              as grouptype,
             ltrim(rtrim(OI.ProductCode))                as productcode,
             Convert(varchar(50),PR.EndDate,101)         as productexpirationdate,
             PR.displayname                              as productdisplayname,
             PR.CategoryCode                             as productcategorycode,
             ltrim(rtrim(PR.familycode))                 as familycode,
             ltrim(rtrim(OI.ChargeTypeCode))             as chargetypecode,
             ltrim(rtrim(OI.MeasureCode))                as measurecode,
             --------------------------------------------------------------             
             ltrim(rtrim(OI.FrequencyCode))              as frequencycode,
             --------------------------------------------------------------
             (case when (ltrim(rtrim(G.OrderGroupType)) <> 'PMC') and 
                        (P.IDSeq is not null)
                       then 1 
                   when (ltrim(rtrim(G.OrderGroupType)) <> 'PMC') and 
                        (P.IDSeq is  null)
                       then 0
                   when (ltrim(rtrim(G.OrderGroupType)) = 'PMC') 
                       then 1
                   else 0
              end
             )                                           as sites,       
             --------------------------------------------------------------     
             (case when ((P.StudentLivingFlag = 1)    and
                         (C.PriceByBedEnabledFlag = 1)
                        )                             and
                        (OI.CapMaxUnitsFlag = 1)      and
                        (coalesce(OI.Beds,P.Beds,0)  >= 
                         coalesce(OI.MaxUnits,C.MaxUnits,0)
                        )
                       then coalesce(OI.MaxUnits,C.MaxUnits,0)
                    when ((P.StudentLivingFlag = 1)    and
                          (C.PriceByBedEnabledFlag = 1)
                         )
                        then coalesce(OI.Beds,P.Beds,0)
                    when (OI.CapMaxUnitsFlag = 1)      and
                         (coalesce(OI.Units,P.Units,0) >= 
                          coalesce(OI.MaxUnits,C.MaxUnits,0)
                         )
                     then coalesce(OI.MaxUnits,C.MaxUnits,0)
                  else coalesce(OI.Units,P.Units,0)
              end
             )                                           as units,            
             --------------------------------------------------------------
             (case when ((P.StudentLivingFlag = 1)       and
                         (C.PriceByBedEnabledFlag = 1)
                        )
                      then coalesce(OI.Beds,P.Beds,0)
                   else
                      coalesce(OI.Units,P.Units,0)
              end
             )                                           as SOCunits,            
             --------------------------------------------------------------
             coalesce(OI.Units,P.Units,0)                as oiunits,
             coalesce(OI.Beds,P.Beds,0)                  as oibeds,
             --------------------------------------------------------------
             coalesce(OI.PPUPercentage,P.PPUPercentage,100)               as ppupercentage,
             (case when ((P.StudentLivingFlag = 1)    and
                         (C.PriceByBedEnabledFlag = 1)
                        )                             and
                        (OI.CapMaxUnitsFlag = 1)      and
                        (coalesce(convert(numeric(30,0),round((convert(numeric(30,5),(coalesce(OI.Beds,P.Beds,0) * coalesce(OI.PPUPercentage,P.PPUPercentage,100)))/(100)
                                                               )
                                                             ,0)
                                          )
                                 ,0)  >= 
                         coalesce(OI.MaxUnits,C.MaxUnits,0)
                        )
                       then coalesce(convert(numeric(30,0),round(OI.MaxUnits,C.MaxUnits,0)),0)
                    when ((P.StudentLivingFlag = 1)    and
                          (C.PriceByBedEnabledFlag = 1)
                         )
                        then coalesce(convert(numeric(30,0),round((convert(numeric(30,5),(coalesce(OI.Beds,P.Beds,0) * coalesce(OI.PPUPercentage,P.PPUPercentage,100)))/(100)
                                                               )
                                                             ,0)
                                          )
                                 ,0)
                    when (OI.CapMaxUnitsFlag = 1)      and
                         (coalesce(convert(numeric(30,0),round((convert(numeric(30,5),(coalesce(OI.Units,P.Units,0) * coalesce(OI.PPUPercentage,P.PPUPercentage,100)))/(100)
                                                               )
                                                             ,0)
                                          )
                                 ,0) >= 
                          coalesce(OI.MaxUnits,C.MaxUnits,0)
                         )
                     then coalesce(convert(numeric(30,0),round(OI.MaxUnits,C.MaxUnits,0)),0)
                  else coalesce(convert(numeric(30,0),round((convert(numeric(30,5),(Coalesce(OI.Units,P.Units,0) * coalesce(OI.PPUPercentage,P.PPUPercentage,100)))/(100)
                                                               )
                                                             ,0)
                                          )
                                 ,0)
              end
             )                                           as ppuadjustedunits,
             --------------------------------------------------------------
             coalesce(OI.Quantity,1)                     as Quantity,
             coalesce(C.UnitBasis,1)                     as unitbasis,
             coalesce(OI.MinUnits,C.MinUnits,0)          as minunits,
             coalesce(OI.MaxUnits,C.MaxUnits,0)          as maxunits,
             coalesce(C.MinUnits,0)                      as SOCminunits,
             coalesce(C.MaxUnits,0)                      as SOCmaxunits, 
             C.FlatPriceFlag                             as FlatPriceFlag,
             C.MinThresholdOverride                      as MinThresholdOverride,
             C.MaxThresholdOverride                      as MaxThresholdOverride,
             coalesce(C.quantityenabledflag,0)           as quantityenabledflag,
             coalesce(C.explodequantityatorderflag,0)    as explodequantityatorderflag,
             coalesce(C.quantitymultiplierflag,0)        as quantitymultiplierflag,

             coalesce(OI.dollarminimum,C.dollarminimum,0) as dollarminimum,
             coalesce(C.dollarminimumenabledflag,0)       as dollarminimumenabledflag,
             coalesce(OI.dollarmaximum,C.dollarmaximum,0) as dollarmaximum,
             coalesce(C.dollarmaximumenabledflag,0)       as dollarmaximumenabledflag,
             
             coalesce(C.dollarminimum,0)                  as SOCdollarminimum,
             coalesce(C.dollarminimumenabledflag,0)       as SOCdollarminimumenabledflag,
             coalesce(C.dollarmaximum,0)                  as SOCdollarmaximum,
             coalesce(C.dollarmaximumenabledflag,0)       as SOCdollarmaximumenabledflag,

             OI.ChargeAmount                             as chargeamount,             
             OI.ChargeAmount                             as SOCchargeamount,
             OI.DiscountPercent                          as discountpercent,
             OI.DiscountAmount                           as discountamount,
             OI.netchargeamount                          as netchargeamount,
             G.custombundlenameenabledflag               as custombundlenameenabledflag,
             G.discallocationcode                        as discallocationcode,
             OI.activationstartdate                      as activationstartdate,
             OI.activationenddate                        as activationenddate,
             OI.renewalcount                             as renewalcount, 
             -------------------------------------------------------------------
             (case when ((P.StudentLivingFlag = 1)    and
                         (C.PriceByBedEnabledFlag = 1)
                        )                     
                       then 1
               else 0 end)                               as pricebybedsflag,
             C.PriceByPPUPercentageEnabledFlag           as PriceByPPUPercentageEnabledFlag,
             ---PricingLineItemNotes
             (case when ((P.StudentLivingFlag = 1)    and
                         (C.PriceByBedEnabledFlag = 1)
                        )                             and
                        (OI.CapMaxUnitsFlag = 1)      and
                        (coalesce(OI.Beds,P.Beds,0)  >= 
                         coalesce(OI.MaxUnits,C.MaxUnits,0)
                        )
                       then 'Quantity is capped at ' + convert(varchar(50),coalesce(OI.MaxUnits,C.MaxUnits,0)) + ' beds.|'                    
                   when ((P.StudentLivingFlag = 1)     and
                         (C.PriceByBedEnabledFlag = 1) and
                         (OI.CapMaxUnitsFlag = 1)                              
                        )
                       then 'Quantity is capped at ' + convert(varchar(50),coalesce(OI.MaxUnits,0)) + ' beds.|'                     
                    when (OI.CapMaxUnitsFlag = 1)      and
                         (coalesce(OI.Units,P.Units,0) >= 
                          coalesce(OI.MaxUnits,C.MaxUnits,0)
                         )
                     then 'Quantity is capped at ' + convert(varchar(50),coalesce(OI.MaxUnits,C.MaxUnits,0)) + ' units.|'
                    when (OI.CapMaxUnitsFlag = 1)     
                     then 'Quantity is capped at ' + convert(varchar(50),coalesce(OI.MaxUnits,0)) + ' units.|'
                  else ''
              end
             )                                           as PricingLineItemNotes 
             ---------------------------------------------------------------
  from       ORDERS.DBO.[OrderGroup]   G  with (nolock) 
  ----------->>>>>>>>>>Inner Joins>>>>>>>>>>>>>>>>---------- 
  inner join ORDERS.DBO.OrderItem OI with (nolock) 
        on   G.OrderIDSeq   = OI.OrderIDSeq 
        and  G.IDSeq        = OI.OrderGroupIDSeq
        and  G.OrderIDSeq   = @IPVC_OrderID 
        and  G.IDSeq        = (case when @IPI_GroupID = -9999 then G.IDSeq else @IPI_GroupID end)
        and  OI.OrderIDSeq  = @IPVC_OrderID  
        and  OI.OrderGroupIDSeq  = (case when @IPI_GroupID = -9999 then OI.OrderGroupIDSeq else @IPI_GroupID end)  
        and  OI.IDSeq            = (case when @IPI_OrderItemID = -9999 then OI.IDSeq else @IPI_OrderItemID end)
        and  (OI.StatusCode <> 'EXPD' and OI.HistoryFlag <> 1)
        /*and  ((OI.StatusCode <> 'CNCL' and OI.StatusCode <> 'EXPD')
                    OR
                 (OI.Measurecode = 'TRAN')
                ) */ --- Commented Temporarily to price migrated orders. To Uncomment before production release.                
  inner join PRODUCTS.dbo.Charge  C  with (nolock) 
        on  ltrim(rtrim(C.ProductCode))   = ltrim(rtrim(OI.ProductCode))       
        and ltrim(rtrim(C.ChargeTypeCode))= ltrim(rtrim(OI.ChargeTypeCode))    
        and ltrim(rtrim(C.MeasureCode))   = ltrim(rtrim(OI.MeasureCode))       
        and ltrim(rtrim(C.FrequencyCode)) = ltrim(rtrim(OI.FrequencyCode))     
        and C.PriceVersion  = OI.PriceVersion
  inner join PRODUCTS.dbo.Product PR with (nolock) 
        on  ltrim(rtrim(PR.Code))         = ltrim(rtrim(C.ProductCode))        
        and ltrim(rtrim(PR.code))         = ltrim(rtrim(OI.productcode))
        and PR.PriceVersion = C.PriceVersion
        and PR.PriceVersion = OI.PriceVersion            
  ----------->>>>>>>>>>Left Joins>>>>>>>>>>>>>>>>-----------
  left join ORDERS.DBO.OrderGroupProperties GP with (nolock)  
        on   G.OrderIDSeq   = GP.OrderIDSeq  
        and  G.IDSeq        = GP.OrderGroupIDSeq  
        and  G.OrderIDSeq   = @IPVC_OrderID  
        and  G.IDSeq        = (case when @IPI_GroupID = -9999 then G.IDSeq else @IPI_GroupID end)       
        and  GP.OrderIDSeq  = @IPVC_OrderID 
        and  GP.OrderGroupIDSeq  = (case when @IPI_GroupID = -9999 then OI.OrderGroupIDSeq else @IPI_GroupID end)  
  left join CUSTOMERS.dbo.Property P with (nolock) 
        on  GP.PropertyIDSeq= P.IDSeq              
  where G.OrderIDSeq        = @IPVC_OrderID 
  and   G.IDSeq             = (case when @IPI_GroupID = -9999 then G.IDSeq else @IPI_GroupID end)   
  ----------------------------------------------------------------------------------------- 
  --Pricing: Step 1 : Get extchargeamount,extSOCchargeamount 
  --select * from #TEMP_PropertiesProductsHoldingTable
  --select productcode,chargetypecode,measurecode,acsmeasurecode,
  --chargeamount,units,ppuadjustedunits,ppupercentage,propertyid,propertythresholdoverride,pricetypecode,
  -- From #TEMP_PropertiesProductsHoldingTable
  -----------------------------------------------------------------------------------------
  Update T 
     set pricingtiers    = CASE WHEN  ((T.measurecode = 'UNIT')  and 
                                       (T.units > T.maxunits)    and
                                       (T.unitbasis <> 1 and T.unitbasis <> 100) and
                                       (T.quantityenabledflag = 0) and 1=1
                                      )
                                   THEN 2
                                ELSE 1
                           END,
         extchargeamount = CASE
                                --------------------------------------------------
                                --- If quantity enabled then Quantity X chargeamount
                                WHEN (T.quantityenabledflag = 1)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'SITE')         
                                   THEN (T.chargeamount) * (T.quantity) * T.Sites 
                                WHEN (T.quantityenabledflag = 1)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'UNIT')         
                                   THEN (T.chargeamount) * (T.quantity) *  T.units * T.Sites
                                WHEN (T.quantityenabledflag = 1)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'PMC')         
                                   THEN (T.chargeamount) * (T.quantity) * 1
                                WHEN (T.quantityenabledflag = 1)
                                   THEN (T.chargeamount) * (T.quantity) * T.Sites 
                                --------------------------------------------------
                                --- if measurecode <> PMC,SITE,UNIT and quantity is disabled 
                                ---    then flat chargeamount.
                                WHEN (T.quantityenabledflag = 0)      and
                                     (T.measurecode <> 'PMC')         and
                                     (T.measurecode <> 'SITE')        and
                                     (T.measurecode <> 'UNIT')
                                   THEN (T.chargeamount) * 1                                                                 
                                --------------------------------------------------
                                --- if measurecode = PMC then flat chargeamount
                                WHEN (T.measurecode = 'PMC') 
                                   THEN (T.chargeamount)* 1
                                --------------------------------------------------
                                --Flat Pricing
                                WHEN (T.quantityenabledflag = 0)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'SITE')         
                                   THEN (T.chargeamount) * T.Sites  
                                WHEN (T.quantityenabledflag = 0)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'UNIT')         
                                   THEN (T.chargeamount) * T.units * T.Sites
                                -------------------------------------------------- 
                                --- Special Case for Screening
                                WHEN (T.propertythresholdoverride=0) and (T.familycode = 'LSD')
                                     and (T.PriceByPPUPercentageEnabledFlag = 1) 
                                     and (T.measurecode = 'UNIT') 
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')            and 
                                                 (T.ppuadjustedunits <= T.minunits)  and                                                
                                                 (T.minthresholdoverride = 1)                                                
                                               then (T.chargeamount)* (T.ppuadjustedunits)
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits <= T.minunits)  and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (T.chargeamount)* 
                                                            (case when (T.ppuadjustedunits > 0) then (T.minunits)   
                                                              else 0
                                                             end)   
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits > T.minunits)   and
                                                 (T.ppuadjustedunits < T.unitbasis)                                          
                                               then (T.chargeamount)* (T.ppuadjustedunits)                                                                                       
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits >= T.unitbasis) and
                                                 (T.ppuadjustedunits <= T.maxunits)                                          
                                               then (T.chargeamount)* (T.ppuadjustedunits) 
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.ppuadjustedunits > T.maxunits)                                           
                                               then  (((T.chargeamount)* (T.maxunits)) +
                                                      ((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits))
                                                     )
                                       end)
                                WHEN (T.propertythresholdoverride=0)
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')            and   
                                                 (T.units <= T.minunits)             and                                              
                                                 (T.minthresholdoverride = 1)                                                
                                               then (T.chargeamount)* (T.units)
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units <= T.minunits)             and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (T.chargeamount)* 
                                                           (case when (T.units > 0) then (T.minunits)   
                                                              else 0
                                                            end)   
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units > T.minunits)              and
                                                 (T.units < T.unitbasis)                                                     
                                               then (T.chargeamount)* (T.units)                                                                                       
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units >= T.unitbasis)            and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount)* (T.units) 
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.units > T.maxunits)                                                      
                                               then (((T.chargeamount)* (T.maxunits)) +
                                                      ((T.chargeamount)/(T.unitbasis))* ((T.units)-(T.maxunits))
                                                     )
                                            -------------------------------------------                                              
                                            --Small Site ILF propertythresholdoverride=0
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.familycode = 'LSD')              and                                           
                                                 (T.minthresholdoverride = 1)          
                                               then (T.chargeamount) * T.Sites 
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.units       <= T.minunits)       and                                                
                                                 (T.minthresholdoverride = 1)                                                
                                               then (((T.chargeamount)/(T.unitbasis))*(T.units)) * T.Sites
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (((T.chargeamount)/(T.unitbasis))*(T.minunits)) * T.Sites
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.units >= T.minunits)             and
                                                 (T.units <= T.unitbasis)  
                                               then (((T.chargeamount)/(T.unitbasis))*(T.units)) * T.Sites
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount) * T.Sites                                           
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then (T.chargeamount) * T.Sites 
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then (T.chargeamount)*((T.units)/(T.maxunits)) * T.Sites
                                            -------------------------------------------  
                                            --Small Site ACS propertyThresholdoverride = 0                                          
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units       <= T.minunits)                                                                                               
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount) * T.Sites                                           
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then (T.chargeamount) * T.Sites 
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then (T.chargeamount)*((T.units)/(T.maxunits)) * T.Sites                                            
                                            ---------------************-----------------                                           
                                            --Normal Site ILF propertythresholdoverride=0                                           
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (T.chargeamount) * T.Sites 
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 1)                                                
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount) * T.Sites                                           
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then (T.chargeamount) * T.Sites 
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then (T.chargeamount)*((T.units)/(T.maxunits)) * T.Sites
                                            -------------------------------------------       
                                            --Normal Site ACS propertythresholdoverride=0                                      
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units       <= T.minunits)                                                                                               
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount) * T.Sites                                           
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                           
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                           
                                               then (T.chargeamount)*((T.units)/(T.maxunits)) * T.Sites
                                            ---------------************-----------------
                                       end) 
                                --------------------------------------------------------
                                --- Special Case for Screening
                                WHEN (T.propertythresholdoverride=1) and (T.familycode = 'LSD')
                                     and (T.PriceByPPUPercentageEnabledFlag = 1)
                                     and (T.measurecode = 'UNIT') 
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')            and   
                                                 (T.ppuadjustedunits <= T.minunits)  and                                              
                                                 (T.minthresholdoverride = 1)                                                
                                               then (T.chargeamount)* (T.ppuadjustedunits)
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits <= T.minunits)  and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (T.chargeamount)* (T.ppuadjustedunits)   
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits > T.minunits)   and
                                                 (T.ppuadjustedunits < T.unitbasis)                                          
                                               then (T.chargeamount)* (T.ppuadjustedunits)                                                                                       
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits >= T.unitbasis) and
                                                 (T.ppuadjustedunits <= T.maxunits)                                          
                                               then (T.chargeamount)* (T.ppuadjustedunits) 
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.ppuadjustedunits > T.maxunits)                                           
                                               then (((T.chargeamount)* (T.maxunits)) +
                                                      ((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits))
                                                     )
                                       end)
                                WHEN (T.propertythresholdoverride=1)
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')            and 
                                                 (T.units <= T.minunits)             and                                                
                                                 (T.minthresholdoverride = 1)                                                
                                               then (T.chargeamount)* (T.units)
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units <= T.minunits)             and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (T.chargeamount)* (T.units)   
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units > T.minunits)              and
                                                 (T.units < T.unitbasis)                                                     
                                               then (T.chargeamount)* (T.units)                                                                                       
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units >= T.unitbasis)            and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount)* (T.units) 
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.units > T.maxunits)                                                      
                                               then (((T.chargeamount)* (T.maxunits)) +
                                                      ((T.chargeamount)/(T.unitbasis))* ((T.units)-(T.maxunits))
                                                     )
                                            -------------------------------------------                                            
                                            --Small Site ILF propertythresholdoverride=1
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.familycode    = 'LSD')           and                                            
                                                 (T.minthresholdoverride = 1)          
                                               then (T.chargeamount) * T.Sites 
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.units       <= T.minunits)       and                                                
                                                 (T.minthresholdoverride = 1)                                                
                                               then (((T.chargeamount)/(T.unitbasis))*(T.units)) * T.Sites
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (((T.chargeamount)/(T.unitbasis))*(T.units)) * T.Sites
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)  
                                               then (((T.chargeamount)/(T.unitbasis))*(T.units)) * T.Sites
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount) * T.Sites                                           
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then (T.chargeamount) * T.Sites 
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then (T.chargeamount) * T.Sites
                                            -------------------------------------------    
                                            --Small Site ACS propertythresholdoverride=1                                           
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units       <= T.minunits)                                                                                               
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.minunits)              and          
                                                 (T.units <= T.unitbasis)                                                   
                                               then (T.chargeamount) * T.Sites

                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount) * T.Sites                                           
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                                  
                                               then (T.chargeamount) * T.Sites  
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                                  
                                               then (T.chargeamount)* T.Sites
                                            ---------------************-----------------                                              
                                            --Normal Site ILF propertythresholdoverride=1                                            
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 1)                                                
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount) * T.Sites                                           
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then (T.chargeamount) * T.Sites 
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then (T.chargeamount) * T.Sites 
                                            -------------------------------------------    
                                            --Normal Site ACS propertythresholdoverride=1                                          
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units       <= T.minunits)                                                                                               
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then (T.chargeamount) * T.Sites                                           
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                           
                                               then (T.chargeamount) * T.Sites
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                           
                                               then (T.chargeamount) * T.Sites 
                                            ---------------************-----------------
                                       end)                                 
                           END                                     
         , -->extchargeamount,
         -----------------------------------------------
         ---For extSOCchargeamount propertythresholdoverride
         ---    will not apply. Also amounts are calculated
         ---    as what SOC pricing Rules
         -----------------------------------------------
         extSOCchargeamount =
                            CASE
                                --------------------------------------------------
                                --- If quantity enabled then Quantity X SOCchargeamount
                                WHEN (T.quantityenabledflag = 1)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'SITE')         
                                   THEN (T.SOCchargeamount) * (T.quantity) * T.Sites 
                                WHEN (T.quantityenabledflag = 1)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'UNIT')         
                                   THEN (T.SOCchargeamount) * (T.quantity) *  T.SOCunits * T.Sites
                                WHEN (T.quantityenabledflag = 1)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'PMC')         
                                   THEN (T.SOCchargeamount) * (T.quantity) * 1
                                WHEN (T.quantityenabledflag = 1)
                                   THEN (T.SOCchargeamount) * (T.quantity)                                
                                --------------------------------------------------
                                --- if measurecode <> PMC,SITE,UNIT and quantity is disabled 
                                ---    then flat SOCchargeamount.
                                WHEN (T.quantityenabledflag = 0)      and
                                     (T.measurecode <> 'PMC')         and
                                     (T.measurecode <> 'SITE')        and
                                     (T.measurecode <> 'UNIT')
                                   THEN (T.SOCchargeamount) * 1                                                                 
                                --------------------------------------------------
                                --- if measurecode = PMC then flat SOCchargeamount
                                WHEN (T.measurecode = 'PMC') 
                                   THEN (T.SOCchargeamount)* 1
                                --------------------------------------------------
                                --Flat Pricing
                                WHEN (T.quantityenabledflag = 0)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'SITE')         
                                   THEN (T.SOCchargeamount) * T.Sites  
                                WHEN (T.quantityenabledflag = 0)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'UNIT')         
                                   THEN (T.SOCchargeamount) * T.SOCunits * T.Sites
                                -------------------------------------------------- 
                                --- Special Case for Screening
                                WHEN (T.familycode = 'LSD') and (T.measurecode = 'UNIT') 
                                     and (T.PriceByPPUPercentageEnabledFlag = 1)
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')                    and 
                                                 (T.ppuadjustedunits <= T.SOCminunits)       and                                                 
                                                 (T.minthresholdoverride = 1)                                                
                                               then (T.SOCchargeamount)* (T.SOCppuadjustedunits)
                                            when (T.measurecode = 'UNIT')                    and                                                           
                                                 (T.ppuadjustedunits <= T.SOCminunits)       and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (T.chargeamount)* (T.SOCminunits)                                                            
                                            when (T.measurecode = 'UNIT')                    and                                                           
                                                 (T.ppuadjustedunits > T.SOCminunits)        and
                                                 (T.ppuadjustedunits < T.unitbasis)                                          
                                               then (T.SOCchargeamount)* (T.SOCppuadjustedunits)                                                                                       
                                            when (T.measurecode = 'UNIT')                    and                                                           
                                                 (T.ppuadjustedunits >= T.unitbasis)         and
                                                 (T.ppuadjustedunits <= T.SOCmaxunits)                                          
                                               then (T.SOCchargeamount)* (T.SOCppuadjustedunits) 
                                            when (T.measurecode = 'UNIT')                    and                                                 
                                                 (T.ppuadjustedunits > T.SOCmaxunits)                                           
                                               then  (((T.SOCchargeamount)* (T.SOCmaxunits)) +
                                                      ((T.SOCchargeamount)/(T.unitbasis))* ((T.SOCppuadjustedunits)- (T.SOCmaxunits))
                                                     )
                                       end)
                                WHEN (T.measurecode = 'UNIT') 
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')                    and  
                                                 (T.units <= T.SOCminunits)                  and                                               
                                                 (T.minthresholdoverride = 1)                                                
                                               then (T.SOCchargeamount)* (T.SOCunits)
                                            when (T.measurecode = 'UNIT')                    and                                                           
                                                 (T.units <= T.SOCminunits)                  and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (T.SOCchargeamount)* (T.SOCminunits)                                                           
                                            when (T.measurecode = 'UNIT')                    and                                                           
                                                 (T.units > T.SOCminunits)                   and
                                                 (T.units < T.unitbasis)                                                     
                                               then (T.SOCchargeamount)* (T.SOCunits)                                                                                       
                                            when (T.measurecode = 'UNIT')                    and                                                           
                                                 (T.units >= T.unitbasis)                    and
                                                 (T.units <= T.SOCmaxunits)                                                     
                                               then (T.SOCchargeamount)* (T.SOCunits) 
                                            when (T.measurecode = 'UNIT')                    and                                                 
                                                 (T.units > T.SOCmaxunits)                                                      
                                               then (((T.SOCchargeamount)* (T.SOCmaxunits)) +
                                                      ((T.SOCchargeamount)/(T.unitbasis))* ((T.SOCunits)-(T.SOCmaxunits)))
                                         end)
                                    ELSE
                                         (case
                                            -------------------------------------------                                            
                                            --Small Site ILF
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and 
                                                 (T.familycode    = 'LSD')                and                                           
                                                 (T.minthresholdoverride = 1)          
                                               then (T.SOCchargeamount) * T.Sites 
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and 
                                                 (T.units       <= T.SOCminunits)         and                                                
                                                 (T.minthresholdoverride = 1)                                                
                                               then (((T.SOCchargeamount)/(T.unitbasis))*(T.SOCunits)) * T.Sites
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units       <= T.SOCminunits)         and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (((T.SOCchargeamount)/(T.unitbasis))*(T.SOCminunits)) * T.Sites
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and 
                                                 (T.units > T.SOCminunits)                and
                                                 (T.units <= T.unitbasis)  
                                               then (((T.SOCchargeamount)/(T.unitbasis))*(T.SOCunits)) * T.Sites
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units > T.unitbasis)                  and
                                                 (T.units <= T.SOCmaxunits)                                                     
                                               then (T.SOCchargeamount) * T.Sites                                           
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units > T.SOCmaxunits)                and
                                                 (T.maxthresholdoverride = 1)                             
                                               then (T.SOCchargeamount) * T.Sites 
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units > T.SOCmaxunits)                and
                                                 (T.maxthresholdoverride = 0)                             
                                               then (T.SOCchargeamount)*((T.SOCunits)/(T.SOCmaxunits)) * T.Sites
                                            -------------------------------------------    
                                            --Small Site ACS
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units       <= T.SOCminunits)                                                                                               
                                               then (T.SOCchargeamount) * T.Sites
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units > T.SOCminunits)                and
                                                 (T.units <= T.unitbasis)                                                   
                                               then (T.SOCchargeamount) * T.Sites
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units > T.unitbasis)                  and
                                                 (T.units <= T.SOCmaxunits)                                                     
                                               then (T.SOCchargeamount) * T.Sites                                           
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units > T.SOCmaxunits)                and
                                                 (T.maxthresholdoverride = 1)                                  
                                               then (T.SOCchargeamount) * T.Sites  
                                            when (T.SOCpricetypecode ='Small')            and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units > T.SOCmaxunits)                and
                                                 (T.maxthresholdoverride = 0)                                  
                                               then (T.SOCchargeamount)*((T.SOCunits)/(T.SOCmaxunits)) * T.Sites
                                            ---------------************-----------------                                                                                         
                                            --Normal Site ILF 
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units       <= T.SOCminunits)         and
                                                 (T.minthresholdoverride = 0)                                                
                                               then (T.SOCchargeamount) * T.Sites 
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units       <= T.SOCminunits)         and
                                                 (T.minthresholdoverride = 1)                                                
                                               then (T.SOCchargeamount) * T.Sites
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units > T.SOCminunits)                and
                                                 (T.units <= T.unitbasis)                                                   
                                               then (T.SOCchargeamount) * T.Sites
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units > T.unitbasis)                  and
                                                 (T.units <= T.SOCmaxunits)                                                     
                                               then (T.SOCchargeamount) * T.Sites                                           
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units > T.SOCmaxunits)                and
                                                 (T.maxthresholdoverride = 1)                             
                                               then (T.SOCchargeamount) * T.Sites 
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode= 'ILF')                and                                                        
                                                 (T.units > T.SOCmaxunits)                and
                                                 (T.maxthresholdoverride = 0)                             
                                               then (T.SOCchargeamount)*((T.SOCunits)/(T.SOCmaxunits)) * T.Sites
                                            -------------------------------------------    
                                             --Normal Site ACS propertythresholdoverride=0                                            
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units       <= T.SOCminunits)                                                                                               
                                               then (T.SOCchargeamount) * T.Sites
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units > T.SOCminunits)                and
                                                 (T.units <= T.unitbasis)                                                   
                                               then (T.SOCchargeamount) * T.Sites
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units > T.unitbasis)                  and
                                                 (T.units <= T.SOCmaxunits)                                                     
                                               then (T.SOCchargeamount) * T.Sites                                           
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units > T.SOCmaxunits)                and
                                                 (T.maxthresholdoverride = 1)                           
                                               then (T.SOCchargeamount) * T.Sites
                                            when (T.SOCpricetypecode ='Normal')           and
                                                 (T.measurecode   = 'SITE')               and   
                                                 (T.chargetypecode<> 'ILF')               and                                                        
                                                 (T.units > T.SOCmaxunits)                and
                                                 (T.maxthresholdoverride = 0)                           
                                               then (T.SOCchargeamount)*((T.SOCunits)/(T.SOCmaxunits)) * T.Sites
                                            ---------------************-----------------
                                       end)                   
                           END
          -->extSOCchargeamount                                       
  from #TEMP_PropertiesProductsHoldingTable T  with (nolock)
  -----------------------------------------------------------------------------------------  
  --Step 1.1 -- Update for netchargeamount,netextchargeamount
  Update T 
     set T.netchargeamount        = convert(float,T.chargeamount) -   ((convert(float,T.chargeamount) * convert(float,T.discountpercent))/100),                                                                                                       
         T.netextchargeamount     = convert(float,T.extchargeamount) -   ((convert(float,T.extchargeamount) * convert(float,T.discountpercent))/100),
         T.multiplier             = (case when (T.extchargeamount = T.chargeamount) then 1
                                         else (Convert(float,T.extchargeamount))/(case when (T.chargeamount)=0 then 1 else (Convert(float,T.chargeamount)) end)
                                    end)                                                       
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)
  -----------------------------------------------------------------------------------------  
  Update T 
     set  T.PricingLineItemNotes = T.PricingLineItemNotes +
                             CASE
                                --------------------------------------------------
                                --- If quantity enabled then Quantity X chargeamount
                                WHEN (T.quantityenabledflag = 1)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'SITE')         
                                   THEN (case when T.explodequantityatorderflag=1 then convert(varchar(50),convert(int,round(T.quantity,0)))
                                              else convert(varchar(50),T.quantity)
                                         end) +
                                        ' Quantity(s)' +
                                        ' charged at $' + 
                                        (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                             when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6))+3,50)=0
                                                then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,2)
                                             else (case when ((T.netextchargeamount)/(T.quantity * T.Sites)) < 1 then '0' else '' end ) +
                                                  substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6)))
                                                                     )
                                                                   )
                                         end) +
                                        ' per Site = $' + convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                WHEN (T.quantityenabledflag = 1)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'UNIT')         
                                   THEN (case when T.explodequantityatorderflag=1 then convert(varchar(50),convert(int,round(T.quantity,0)))
                                              else convert(varchar(50),T.quantity)
                                         end) +
                                        ' Quantity(s)' + 
                                        ' charged at $' + 
                                        (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                              when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.units)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.units)),1,6))+3,50)=0
                                                then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.units)),1,2)
                                              else (case when ((T.netextchargeamount)/(T.quantity * T.Units)) < 1 then '0' else '' end ) +
                                                   substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.units)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.units)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.units)),1,6)))
                                                                     )
                                                                   ) 
                                        end) +
                                        ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) +
                                        ' = $' + 
                                        convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                WHEN (T.quantityenabledflag = 1)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'PMC')         
                                   THEN (case when T.explodequantityatorderflag=1 then convert(varchar(50),convert(int,round(T.quantity,0)))
                                              else convert(varchar(50),T.quantity)
                                         end) +
                                        ' Quantity(s)'  + 
                                        ' charged at $' + 
                                        (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                              when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6))+3,50)=0
                                                then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,2)
                                              else (case when ((T.netextchargeamount)/(T.quantity * 1)) < 1 then '0' else '' end ) +
                                                   substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6)))
                                                                     )
                                                             )
                                          end) + 
                                        ' per PMC = $' + convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                WHEN (T.quantityenabledflag = 1)
                                   THEN (case when T.explodequantityatorderflag=1 then convert(varchar(50),convert(int,round(T.quantity,0)))
                                              else convert(varchar(50),T.quantity)
                                         end) + 
                                        ' Quantity(s)'  + 
                                        ' charged at $' + 
                                        (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                              when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6))+3,50)=0
                                                then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,2) 
                                              else (case when ((T.netextchargeamount)/(T.quantity * T.Sites)) < 1 then '0' else '' end ) +
                                                   substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * T.Sites)),1,6)))
                                                                     )
                                                            )
                                         end) +
                                        ' per ' + lower(T.Measurecode) + 
                                        ' = $' + convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                --------------------------------------------------
                                --- if measurecode <> PMC,SITE,UNIT and quantity is disabled 
                                ---    then flat chargeamount.
                                WHEN (T.quantityenabledflag = 0)      and
                                     (T.measurecode <> 'PMC')         and
                                     (T.measurecode <> 'SITE')        and
                                     (T.measurecode <> 'UNIT')
                                   THEN convert(varchar(50),convert(int,round(T.quantity,0))) + 
                                        ' Quantity(s)'  + 
                                        ' charged at $' + 
                                        (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                              when substring(ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6))+3,50)=0
                                                then ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2) 
                                              else (case when (T.netextchargeamount) < 1 then '0' else '' end ) +
                                                    substring(ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6)))
                                                                     )
                                                                   )
                                         end) +
                                        ' per ' + lower(T.Measurecode) +
                                        ' = $' + convert(varchar(50),(T.netextchargeamount))+ '|'
                                --------------------------------------------------
                                --- if measurecode = PMC then flat chargeamount
                                WHEN (T.measurecode = 'PMC') 
                                   THEN convert(varchar(50),convert(int,round(T.quantity,0))) + 
                                        ' Quantity(s)' +
                                        ' charged at $' + 
                                        (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                              when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6))+3,50)=0
                                                then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,2) 
                                              else (case when ((T.netextchargeamount)/(T.quantity * 1)) < 1 then '0' else '' end ) +
                                                   substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.quantity * 1)),1,6)))
                                                                     )
                                                                   )
                                         end) + 
                                        ' per PMC = $' + convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                --------------------------------------------------
                                --Flat Pricing
                                WHEN (T.quantityenabledflag = 0)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'SITE')         
                                   THEN 'Charged at a flat price of $' + 
                                        (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                              when substring(ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6))+3,50)=0
                                                then ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2) 
                                              else (case when (T.netextchargeamount) < 1 then '0' else '' end ) +
                                                   substring(ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,6)))
                                                                     )
                                                                   )
                                         end) +                      
                                        ' per Site = $' + convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                WHEN (T.quantityenabledflag = 0)      and
                                     (T.FlatpriceFlag = 1)            and
                                     (T.measurecode = 'UNIT')         
                                   THEN convert(varchar(50),T.units * T.Sites) + (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                        ' charged at a flat price of $' + 
                                        (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                              when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units * T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units * T.Sites)),1,6))+3,50)=0
                                                then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units * T.Sites)),1,2) 
                                              else (case when ((T.netextchargeamount)/(T.units * T.Sites)) < 1 then '0' else '' end ) +
                                                   substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units * T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units * T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units * T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units * T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units * T.Sites)),1,6)))
                                                                     )
                                                                   )
                                         end) + 
                                        ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + '' +
                                        ' = $' + convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                -------------------------------------------------- 
                                --- Special Case for Screening
                                WHEN (T.propertythresholdoverride=0) and (T.familycode = 'LSD')
                                     and (T.PriceByPPUPercentageEnabledFlag = 1)
                                     and (T.measurecode = 'UNIT') 
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')            and 
                                                 (T.ppuadjustedunits <= T.minunits)  and                                                
                                                 (T.minthresholdoverride = 1)                                                
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    ---convert(varchar(50),T.ppuadjustedunits) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len(T.minunits))
                                                            ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.minunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(T.ppuadjustedunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits <= T.minunits)  and
                                                 (T.minthresholdoverride = 0)                                                
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    'Quantity is subject to a ' + convert(varchar(50),(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits)   
                                                                                                            else 0
                                                                                                       end)
                                                                                          ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + ' minimum.' + '|' + 
                                                     --convert(varchar(50),(case when (T.ppuadjustedunits > 0) then (T.minunits) else 0 end)
                                                     --       ) +   
                                                     convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len((case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 0 end)))
                                                            ) + 
                                                     '-'      + 
                                                     convert(varchar(50),right(stuff('000000000000',12-len((case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 0 end)),10,(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 0 end)),len((case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 0 end)))
                                                            ) +                                                   
                                                     (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +          
                                                     ' charged at $' + 
                                                     (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                           when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 1 end)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 1 end)),1,2)  
                                                           else (case when ((T.netextchargeamount)/(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 1 end)) < 1 then '0' else '' end ) +
                                                                 substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when ((T.ppuadjustedunits > 0) and (T.minunits > 0)) then (T.minunits) else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                      end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits > T.minunits)   and
                                                 (T.ppuadjustedunits < T.unitbasis)                                          
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) +
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    --convert(varchar(50),T.ppuadjustedunits) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len(T.ppuadjustedunits))
                                                            ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.ppuadjustedunits))
                                                           ) +
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(T.ppuadjustedunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits >= T.unitbasis) and
                                                 (T.ppuadjustedunits <=  T.maxunits)                                          
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    ---convert(varchar(50),T.ppuadjustedunits) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len(T.ppuadjustedunits))
                                                            ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.ppuadjustedunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(T.ppuadjustedunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.ppuadjustedunits > T.maxunits)   and
                                                 (T.PricingTiers < 2)
                                               then  'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len(T.ppuadjustedunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.ppuadjustedunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.ppuadjustedunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) 
                                                    + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.ppuadjustedunits > T.maxunits)   and
                                                 (T.PricingTiers > 1)                                        
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    --'1'+ '-' + convert(varchar(50),T.maxunits)
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.maxunits = 0 then '0' else '1' end)),len(T.ppuadjustedunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.maxunits),10,T.maxunits),len(T.ppuadjustedunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.maxunits = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,2)  
                                                          else (case when (((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6)))
                                                                     )
                                                                   )
                                                     end)  + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency(
                                                                                  (((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))
                                                                                   ,1,2)
                                                            )+ '|'  +
                                                    --convert(varchar(50),(T.maxunits+1))+'-'+convert(varchar(50),(T.ppuadjustedunits))+
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.maxunits+1),10,(case when T.maxunits=0 then '0' else T.maxunits+1 end)),len(T.ppuadjustedunits))
                                                           ) +
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.ppuadjustedunits))
                                                           ) +                                                    
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when ((T.ppuadjustedunits)-(T.maxunits)) = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                             /(case when ((T.ppuadjustedunits)-(T.maxunits))=0 then 1 else ((T.ppuadjustedunits)-(T.maxunits)) end)),1,6),
                                                                         patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                             /(case when ((T.ppuadjustedunits)-(T.maxunits))=0 then 1 else ((T.ppuadjustedunits)-(T.maxunits)) end)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits) * (T.discountpercent)/100))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,2)  
                                                          else (case when ((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                             /(case when ((T.ppuadjustedunits)-(T.maxunits))=0 then 1 else ((T.ppuadjustedunits)-(T.maxunits)) end)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                             /(case when ((T.ppuadjustedunits)-(T.maxunits))=0 then 1 else ((T.ppuadjustedunits)-(T.maxunits)) end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                                                   /(case when ((T.ppuadjustedunits)-(T.maxunits))=0 then 1 else ((T.ppuadjustedunits)-(T.maxunits)) end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                                           /(case when ((T.ppuadjustedunits)-(T.maxunits))=0 then 1 else ((T.ppuadjustedunits)-(T.maxunits)) end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                                                     /(case when ((T.ppuadjustedunits)-(T.maxunits))=0 then 1 else ((T.ppuadjustedunits)-(T.maxunits)) end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                                                            /(case when ((T.ppuadjustedunits)-(T.maxunits))=0 then 1 else ((T.ppuadjustedunits)-(T.maxunits)) end)),1,6)))
                                                                     )
                                                                   )
                                                    end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency(
                                                                                            (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)-(T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)-(T.maxunits)) * (T.discountpercent)/100))
                                                                                            ,1,2)
                                                                            )+ '|'
                                       end)
                                WHEN (T.propertythresholdoverride=0)
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')            and   
                                                 (T.units <= T.minunits)             and                                              
                                                 (T.minthresholdoverride = 1)                                                
                                               then --convert(varchar(50),T.units) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.minunits))
                                                           )  + 
                                                     '-'      + 
                                                     convert(varchar(50),right(stuff('000000000000',12-len(T.units),10,T.units),len(T.minunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(T.units)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units <= T.minunits)             and
                                                 (T.minthresholdoverride = 0)                                                
                                               then 'Quantity is subject to a ' + convert(varchar(50),T.minunits ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + ' minimum.' + '|' + 
                                                    --- convert(varchar(50),(case when (T.units > 0) then (T.minunits) else 0 end)) 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.minunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(case when (T.units > 0) then (T.minunits) else 0 end),10,(case when (T.units > 0) then (T.minunits) else 0 end)),len(case when (T.units > 0) then (T.minunits) else 0 end))
                                                           ) + 
                                                    + (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units > 0 and T.minunits > 0) then (T.minunits) else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units > 0 and T.minunits > 0) then (T.minunits) else 1 end)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units > 0 and T.minunits > 0) then (T.minunits) else 1 end)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(case when (T.units > 0 and T.minunits > 0) then (T.minunits) else 1 end)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units > 0 and T.minunits > 0) then (T.minunits) else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units > 0 and T.minunits > 0) then (T.minunits) else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units > 0 and T.minunits > 0) then (T.minunits) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units > 0 and T.minunits > 0) then (T.minunits) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units > 0 and T.minunits > 0) then (T.minunits) else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units > T.minunits)              and
                                                 (T.units < T.unitbasis)                                                     
                                               then ---convert(varchar(50),T.units) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units=0 then '0' else '1' end)),len(T.units))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10,T.units),len(T.units))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units >= T.unitbasis)            and
                                                 (T.units <= T.maxunits)                                                     
                                               then --convert(varchar(50),T.units) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units=0 then '0' else '1' end)),len(T.units))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10,T.units),len(T.units))
                                                           ) +
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when T.units > 0 then T.units else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) +
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.pricingtiers < 2  )                                        
                                               then convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.units))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10,T.units),len(T.units))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.units)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) 
                                                    + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.pricingtiers > 1  )                                        
                                               then ---'1' + '-' + convert(varchar(50),T.maxunits)
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.maxunits=0 then '0' else '1' end)),len(T.units))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.maxunits),10,T.maxunits),len(T.units))
                                                           ) + 
                                                   (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.maxunits = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))/(T.maxunits)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))/(T.maxunits)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))/(T.maxunits)),1,2)
                                                          else (case when (((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))/(T.maxunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))/(T.maxunits)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))/(T.maxunits)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))/(T.maxunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))/(T.maxunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))/(T.maxunits)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) +
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency(
                                                                                       ((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100))
                                                                                       ,1,2)
                                                            )+ '|'+     
                                                    --convert(varchar(50),(T.maxunits+1))+'-'+convert(varchar(50),(T.units))                                                 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.maxunits+1),10,T.maxunits+1),len(T.units))
                                                           ) +
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10, T.units),len(T.units))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' +
                                                    (case when (T.units-T.maxunits)=0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                                       /(case when (T.units-T.maxunits)=0 then 1 else (T.units-T.maxunits) end),1,6),
                                                                           patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                                                         /(case when (T.units-T.maxunits)=0 then 1 else (T.units-T.maxunits) end),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency((((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                               /(case when (T.units-T.maxunits)=0 then 1 else (T.units-T.maxunits) end),1,2)
                                                          else (case when (((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                           /(case when (T.units-T.maxunits)=0 then 1 else (T.units-T.maxunits) end) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                           /(case when (T.units-T.maxunits)=0 then 1 else (T.units-T.maxunits) end),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                                                   /(case when (T.units-T.maxunits)=0 then 1 else (T.units-T.maxunits) end),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                                            /(case when (T.units-T.maxunits)=0 then 1 else (T.units-T.maxunits) end),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                                                     /(case when (T.units-T.maxunits)=0 then 1 else (T.units-T.maxunits) end),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                                                     /(case when (T.units-T.maxunits)=0 then 1 else (T.units-T.maxunits) end),1,6)))
                                                                     )
                                                                   )
                                                     end ) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency(
                                                                                     (((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))-(((T.chargeamount/T.unitbasis)*(T.units-T.maxunits))*(T.discountpercent)/100))
                                                                                      ,1,2)
                                                           )+ '|'
                                            -------------------------------------------                                              
                                            --Small Site ILF propertythresholdoverride=0
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.familycode    = 'LSD')           and                                           
                                                 (T.minthresholdoverride = 1)          
                                               then ' Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                    end) +  
                                                    ' per Site = $' + convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|' 
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.units       <= T.minunits)       and                                                
                                                 (T.minthresholdoverride = 1)                                               
                                               then ---'1' + '-' + convert(varchar(50),T.units * T.Sites) + 
                                                   convert(varchar(50),right(stuff('000000000000',12-len(1),10, (case when T.units = 0 then 0 else '1' end)),len(T.minunits*T.Sites))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units*T.Sites),10,(T.units*T.Sites)),len(T.minunits*T.Sites))
                                                           ) + 
                                                   (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.units*T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                    end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 0)                                                
                                               then 'Quantity is subject to a ' + convert(varchar(50),T.minunits ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + ' minimum.' + '|' + 
                                                    ---'1' + '-' + convert(varchar(50),T.minunits*T.Sites) +
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.minunits*T.Sites))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.minunits*T.Sites),10,(case when (T.units)=0 then 0 else (T.minunits*T.Sites) end )),len(T.minunits*T.Sites))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.minunits*T.Sites) > 0 then (T.minunits*T.Sites) else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.minunits*T.Sites) > 0 then (T.minunits*T.Sites) else 1 end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.minunits*T.Sites) > 0 then (T.minunits*T.Sites) else 1 end)),1,2)
                                                     else (case when ((T.netextchargeamount)/(T.minunits*T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.minunits*T.Sites) > 0 then (T.minunits*T.Sites) else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.minunits*T.Sites) > 0 then (T.minunits*T.Sites) else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.minunits*T.Sites) > 0 then (T.minunits*T.Sites) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.minunits*T.Sites) > 0 then (T.minunits*T.Sites) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.minunits*T.Sites) > 0 then (T.minunits*T.Sites) else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                    end ) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.units >= T.minunits)             and
                                                 (T.units <= T.unitbasis)  
                                               then ---'1' + '-' + convert(varchar(50),T.units * T.Sites) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.units*T.Sites))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units*T.Sites),10,T.units*T.Sites),len(T.units*T.Sites))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.units*T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units*T.Sites) > 0 then (T.units*T.Sites) else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) 
                                                    + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'+
                                                    'Fee includes Large Site Surcharge' + '.|'
                                            -------------------------------------------  
                                            --Small Site ACS propertyThresholdoverride = 0                                          
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units       <= T.minunits)                                                                                               
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|' + 
                                                    'Fee includes Large Site Surcharge' + '.|'
                                            ---------------************-----------------                                           
                                            --Normal Site ILF propertythresholdoverride=0                                           
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 0)                                                
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 1)                                                
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|' + 
                                                    'Fee includes Large Site Surcharge' + '.|'
                                            -------------------------------------------       
                                            --Normal Site ACS propertythresholdoverride=0                                      
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units       <= T.minunits)                                                                                               
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                           
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                           
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                           then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|' + 
                                                    'Fee includes Large Site Surcharge' + '.|'
                                            ---------------************-----------------
                                       end) 
                                --------------------------------------------------------
                                --- Special Case for Screening
                                WHEN (T.propertythresholdoverride=1) and (T.familycode = 'LSD')
                                     and (T.PriceByPPUPercentageEnabledFlag = 1)  
                                     and (T.measurecode = 'UNIT') 
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')            and   
                                                 (T.ppuadjustedunits <= T.minunits)  and                                              
                                                 (T.minthresholdoverride = 1)                                                
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    --convert(varchar(50),T.ppuadjustedunits) +
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len(T.minunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.minunits))
                                                           ) +
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(T.ppuadjustedunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits <= T.minunits)  and
                                                 (T.minthresholdoverride = 0)                                                
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    --convert(varchar(50),T.ppuadjustedunits) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len(T.minunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.minunits))
                                                           ) +
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(T.ppuadjustedunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) +
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits > T.minunits)   and
                                                 (T.ppuadjustedunits < T.unitbasis)                                          
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    --convert(varchar(50),T.ppuadjustedunits) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len(T.ppuadjustedunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.ppuadjustedunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(T.ppuadjustedunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.ppuadjustedunits >= T.unitbasis) and
                                                 (T.ppuadjustedunits <= T.maxunits)                                          
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    --convert(varchar(50),T.ppuadjustedunits) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len(T.maxunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.maxunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,2)  
                                                          else (case when ((T.netextchargeamount)/(T.ppuadjustedunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.ppuadjustedunits)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.ppuadjustedunits > T.maxunits)   and
                                                 (T.pricingtiers < 2)                                                        
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.ppuadjustedunits = 0 then '0' else '1' end)),len(T.ppuadjustedunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.ppuadjustedunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.ppuadjustedunits)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.ppuadjustedunits) > 0 then (T.ppuadjustedunits) else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) 
                                                    + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.ppuadjustedunits > T.maxunits)   and
                                                 (T.pricingtiers > 1)                                                         
                                               then 'Quantity ' + convert(varchar(50),T.SOCunits) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' is adjusted to ' + convert(varchar(50),T.ppuadjustedunits)   + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' based on a PPU of ' + convert(varchar(50),convert(numeric(30,0),T.ppupercentage)) + '%' + '|'+
                                                    --'1' + '-' + convert(varchar(50),T.maxunits) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.maxunits=0 then '0' else '1' end)),len(T.ppuadjustedunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.maxunits),10,T.maxunits),len(T.ppuadjustedunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.maxunits = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6)
                                                                                                       ,patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,2)
                                                          else (case when ((((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))/(case when T.maxunits=0 then 1 else T.maxunits end)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))/(case when T.maxunits=0 then 1 else T.maxunits end)),1,6)))
                                                                     )
                                                                   )
                                                    end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) +
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency(
                                                                                   (((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))
                                                                                   ,1,2)
                                                            )+ '|'  +
                                                    --convert(varchar(50),(T.maxunits+1))+'-'+convert(varchar(50),(T.ppuadjustedunits))+
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.maxunits+1),10, T.maxunits+1),len(T.ppuadjustedunits))
                                                           ) +
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.ppuadjustedunits),10,T.ppuadjustedunits),len(T.ppuadjustedunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when ((T.ppuadjustedunits)- (T.maxunits)) = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                                        /(case when ((T.ppuadjustedunits)- (T.maxunits))=0 then 1 else ((T.ppuadjustedunits)- (T.maxunits)) end)),1,6)
                                                                           ,patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                                                       /(case when ((T.ppuadjustedunits)- (T.maxunits))=0 then 1 else ((T.ppuadjustedunits)- (T.maxunits)) end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                                /(case when ((T.ppuadjustedunits)- (T.maxunits))=0 then 1 else ((T.ppuadjustedunits)- (T.maxunits)) end)),1,2)
                                                           else (case when ((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                         /(case when ((T.ppuadjustedunits)- (T.maxunits))=0 then 1 else ((T.ppuadjustedunits)- (T.maxunits)) end)) < 1 then '0' else '' end ) +
                                                                 substring(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                         /(case when ((T.ppuadjustedunits)- (T.maxunits))=0 then 1 else ((T.ppuadjustedunits)- (T.maxunits)) end)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                               /(case when ((T.ppuadjustedunits)- (T.maxunits))=0 then 1 else ((T.ppuadjustedunits)- (T.maxunits)) end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                              /(case when ((T.ppuadjustedunits)- (T.maxunits))=0 then 1 else ((T.ppuadjustedunits)- (T.maxunits)) end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                            /(case when ((T.ppuadjustedunits)- (T.maxunits))=0 then 1 else ((T.ppuadjustedunits)- (T.maxunits)) end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))
                                                                                             /(case when ((T.ppuadjustedunits)- (T.maxunits))=0 then 1 else ((T.ppuadjustedunits)- (T.maxunits)) end)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency(
                                                                                      (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.ppuadjustedunits)- (T.maxunits)) * (T.discountpercent)/100))                                                                                       
                                                                                      ,1,2)
                                                            )+ '|'
                                       end)
                                WHEN (T.propertythresholdoverride=1)
                                   THEN 
                                      (case when (T.measurecode = 'UNIT')            and 
                                                 (T.units <= T.minunits)             and                                                
                                                 (T.minthresholdoverride = 1)                                                
                                               then ---convert(varchar(50),T.units) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.minunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10,T.units),len(T.minunits))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.units)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) +
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units <= T.minunits)             and
                                                 (T.minthresholdoverride = 0)                                                
                                               then --convert(varchar(50),T.units) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.minunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10,T.units),len(T.minunits))
                                                           ) +  
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.units)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units > T.minunits)              and
                                                 (T.units < T.unitbasis)                                                     
                                               then --convert(varchar(50),T.units) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.units))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10,T.units),len(T.units))
                                                           ) +
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.units)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                           
                                                 (T.units >= T.unitbasis)            and
                                                 (T.units <= T.maxunits)                                                     
                                               then --convert(varchar(50),T.units) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.maxunits))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10,T.units),len(T.maxunits))
                                                           ) +
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.units)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.units > T.maxunits)              and
                                                 (T.pricingtiers < 2)                                                          
                                               then convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then '0' else '1' end)),len(T.units))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10,T.units),len(T.units))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) +
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.units)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6),
                                                                    patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(case when (T.units) > 0 then (T.units) else 1 end)),1,6)))
                                                                     )
                                                                   )
                                                     end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) 
                                                    + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.measurecode = 'UNIT')            and                                                 
                                                 (T.units > T.maxunits)              and
                                                 (T.pricingtiers > 1)                                         
                                               then ---'1' + '-' + convert(varchar(50),T.maxunits) +
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.maxunits = 0 then '0' else '1' end)),len(T.units))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.maxunits),10,T.maxunits),len(T.units))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.maxunits = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100)))/(case when T.maxunits > 0 then T.maxunits else 0 end)),1,6)
                                                                                 ,patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100)))/(case when T.maxunits > 0 then T.maxunits else 0 end)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100)))/(case when T.maxunits > 0 then T.maxunits else 0 end)),1,2)
                                                          else (case when ((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100)))/(case when T.maxunits > 0 then T.maxunits else 0 end)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100)))/(case when T.maxunits > 0 then T.maxunits else 0 end)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100)))/(case when T.maxunits > 0 then T.maxunits else 0 end)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100)))/(case when T.maxunits > 0 then T.maxunits else 0 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100)))/(case when T.maxunits > 0 then T.maxunits else 0 end)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((((T.chargeamount*T.maxunits)-((T.chargeamount*T.maxunits)*(T.discountpercent)/100)))/(case when T.maxunits > 0 then T.maxunits else 0 end)),1,6)))
                                                                     )
                                                                   )
                                                    end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency(
                                                                                (((T.chargeamount*T.maxunits) - ((T.chargeamount*T.maxunits) * (T.discountpercent)/100)))
                                                                                 ,1,2)
                                                            )+ '|'  +
                                                    ---convert(varchar(50),(T.maxunits+1))+'-'+convert(varchar(50),(T.units))+
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.maxunits+1),10,T.maxunits+1),len(T.units))
                                                           ) +
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units),10, T.units),len(T.units))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))-(((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))*(T.discountpercent)/100))
                                                                                                          /(case when ((T.units)-(T.maxunits))=0 then 1 else ((T.units)-(T.maxunits)) end),1,6),
                                                                            patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))-(((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))*(T.discountpercent)/100))
                                                                                                                           /(case when ((T.units)-(T.maxunits))=0 then 1 else ((T.units)-(T.maxunits)) end),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency((((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))-(((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))*(T.discountpercent)/100))
                                                                                 /(case when ((T.units)-(T.maxunits))=0 then 1 else ((T.units)-(T.maxunits)) end),1,2)
                                                          else (case when (((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))-(((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))*(T.discountpercent)/100))
                                                                                                        /(case when ((T.units)-(T.maxunits))=0 then 1 else ((T.units)-(T.maxunits)) end) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))-(((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))*(T.discountpercent)/100))
                                                                                                        /(case when ((T.units)-(T.maxunits))=0 then 1 else ((T.units)-(T.maxunits)) end),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))-(((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))*(T.discountpercent)/100))
                                                                                                                     /(case when ((T.units)-(T.maxunits))=0 then 1 else ((T.units)-(T.maxunits)) end),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))-(((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))*(T.discountpercent)/100))
                                                                                                           /(case when ((T.units)-(T.maxunits))=0 then 1 else ((T.units)-(T.maxunits)) end),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency((((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))-(((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))*(T.discountpercent)/100))
                                                                                                            /(case when ((T.units)-(T.maxunits))=0 then 1 else ((T.units)-(T.maxunits)) end),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency((((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))-(((T.chargeamount)/(T.unitbasis))*((T.units)-(T.maxunits))*(T.discountpercent)/100))
                                                                                                      /(case when ((T.units)-(T.maxunits))=0 then 1 else ((T.units)-(T.maxunits)) end),1,6)))
                                                                     )
                                                                   )
                                                    end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) +
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency(
                                                                                        (((T.chargeamount)/(T.unitbasis))* ((T.units)- (T.maxunits)) - (((T.chargeamount)/(T.unitbasis))* ((T.units)- (T.maxunits)) * (T.discountpercent)/100))                                                                                         
                                                                                         ,1,2)
                                                            )+ '|'
                                            -------------------------------------------                                            
                                            --Small Site ILF propertythresholdoverride=1
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.familycode    = 'LSD')           and                                            
                                                 (T.minthresholdoverride = 1)          
                                               then 'Charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                             then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.units       <= T.minunits)       and                                                
                                                 (T.minthresholdoverride = 1)                                                
                                               then --'1' + '-' + convert(varchar(50),T.units*T.Sites) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when (T.units*T.Sites)=0 then '0' else '1' end)),len(T.units*T.Sites))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units*T.Sites),10,(T.units*T.Sites)),len(T.units*T.Sites))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at $' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Units*T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                    end) + 
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 0)                                                
                                               then ---'1' + '-' + convert(varchar(50),T.units*T.Sites) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10, (case when T.units = 0 then 0  else '1' end)),len(T.minunits*T.Sites))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units*T.Sites),10,(T.units*T.Sites)),len(T.minunits*T.Sites))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at ' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Units*T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                    end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) +  
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and 
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)  
                                               then ---'1' + '-' + convert(varchar(50),T.units*T.Sites) + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(1),10,(case when T.units = 0 then 0  else '1' end)),len(T.units*T.Sites))
                                                           ) + 
                                                    '-'      + 
                                                    convert(varchar(50),right(stuff('000000000000',12-len(T.units*T.Sites),10,(T.units*T.Sites)),len(T.units*T.Sites))
                                                           ) + 
                                                    (case when T.pricebybedsflag=1 then ' Bed(s)' else ' Unit(s)' end) + 
                                                    ' charged at ' + 
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Units*T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.units*T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                    end) +
                                                    ' per' + (case when T.pricebybedsflag=1 then ' Bed' else ' Unit' end) + 
                                                    ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            -------------------------------------------    
                                            --Small Site ACS propertythresholdoverride=1                                           
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units       <= T.minunits)                                                                                               
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.minunits)              and          
                                                 (T.units <= T.unitbasis)                                                   
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                                  
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Small')          and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                                  
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            ---------------************-----------------                                              
                                            --Normal Site ILF propertythresholdoverride=1                                            
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 0)                                                
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units       <= T.minunits)       and
                                                 (T.minthresholdoverride = 1)                                                
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                             
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode= 'ILF')           and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                             
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            -------------------------------------------    
                                            --Normal Site ACS propertythresholdoverride=1                                          
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units       <= T.minunits)                                                                                               
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.minunits)              and
                                                 (T.units <= T.unitbasis)                                                   
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.unitbasis)             and
                                                 (T.units <= T.maxunits)                                                     
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 1)                           
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            when (T.pricetypecode ='Normal')         and
                                                 (T.measurecode   = 'SITE')          and   
                                                 (T.chargetypecode<> 'ILF')          and                                                        
                                                 (T.units > T.maxunits)              and
                                                 (T.maxthresholdoverride = 0)                           
                                               then 'Charged at $' +
                                                    (case when T.netextchargeamount = 0 then ORDERS.DBO.fn_FormatCurrency((0.00),1,2)
                                                          when substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),patindex('%[.]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))+3,50)=0
                                                            then ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,2)
                                                          else (case when ((T.netextchargeamount)/(T.Sites)) < 1 then '0' else '' end ) +
                                                                substring(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6),
                                                                     patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)),
                                                                     (2 + len(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6))
                                                                      -
                                                                      patindex('%[^0]%',reverse(ORDERS.DBO.fn_FormatCurrency(((T.netextchargeamount)/(T.Sites)),1,6)))
                                                                     )
                                                                   )
                                                     end) +
                                                    ' per Site' + ' = $' + 
                                                    convert(varchar(50),ORDERS.DBO.fn_FormatCurrency((T.netextchargeamount),1,2)) + '|'
                                            ---------------************-----------------
                                       end)                                 
                           END
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)
  where (T.measurecode <> 'TRAN')
  -----------------------------------------------------------------------------------------  
  --Step 1.2 -- Update for Dollar Minimum and Dollar maximum
  Update T
  Set    T.extchargeamount = (case 
                                  when (T.grouptype <> 'PMC')               and             
                                        (T.sites = 0 and T.units = 0)
                                      then 0.00                                
                                   ---------------------------------------
                                   when (T.propertythresholdoverride=1) 
                                      then T.extchargeamount
                                   ---------------------------------------
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarminimumenabledflag = 1)      and 
                                        (T.extchargeamount <= T.dollarminimum)
                                      then T.dollarminimum  
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarminimumenabledflag = 1)      and 
                                        (T.extchargeamount >= T.dollarminimum)
                                      then T.extchargeamount 
                                   ---------------------------------------
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarmaximumenabledflag = 1)      and 
                                        (T.extchargeamount <= T.dollarmaximum)
                                      then T.extchargeamount 
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarmaximumenabledflag = 1)      and 
                                        (T.extchargeamount >= T.dollarmaximum)
                                      then T.dollarmaximum
                                   --------------------------------------- 
                                   else T.extchargeamount
                                   ---------------------------------------
                                end),         
          T.netextchargeamount = (case when (T.grouptype <> 'PMC')               and             
                                        (T.sites = 0 and T.units = 0)
                                      then 0.00                                
                                   ---------------------------------------
                                   when (T.propertythresholdoverride=1) 
                                      then T.netextchargeamount
                                   ---------------------------------------
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarminimumenabledflag = 1)      and 
                                        (T.netextchargeamount <= T.dollarminimum)
                                      then T.dollarminimum  
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarminimumenabledflag = 1)      and 
                                        (T.netextchargeamount >= T.dollarminimum)
                                      then T.netextchargeamount 
                                   ---------------------------------------
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarmaximumenabledflag = 1)      and 
                                        (T.netextchargeamount <= T.dollarmaximum)
                                      then T.netextchargeamount 
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarmaximumenabledflag = 1)      and 
                                        (T.netextchargeamount >= T.dollarmaximum)
                                      then T.dollarmaximum
                                   --------------------------------------- 
                                   else T.netextchargeamount
                                   ---------------------------------------
                                end),
          T.extSOCchargeamount = 
                               (case 
                                   when (T.grouptype <> 'PMC')               and             
                                        (T.sites = 0 and T.units = 0)
                                      then 0.00                                
                                   ---------------------------------------                                   
                                   when (T.SOCdollarminimumenabledflag = 1)   and 
                                        (T.extSOCchargeamount <= T.SOCdollarminimum)
                                      then T.SOCdollarminimum  
                                   when (T.SOCdollarminimumenabledflag = 1)   and 
                                        (T.extSOCchargeamount >= T.SOCdollarminimum)
                                      then T.extSOCchargeamount 
                                   ---------------------------------------
                                   when (T.SOCdollarmaximumenabledflag = 1)   and 
                                        (T.extSOCchargeamount <= T.SOCdollarmaximum)
                                      then T.extSOCchargeamount 
                                   when (T.SOCdollarmaximumenabledflag = 1)   and 
                                        (T.extSOCchargeamount >= T.SOCdollarmaximum)
                                      then T.SOCdollarmaximum
                                   --------------------------------------- 
                                   else T.extSOCchargeamount
                                   ---------------------------------------
                                end),
          T.PricingLineItemNotes = T.PricingLineItemNotes + (case when (T.grouptype <> 'PMC')           and             
                                        (T.sites = 0 and T.units = 0)
                                      then ''                               
                                   ---------------------------------------
                                   when (T.propertythresholdoverride=1) 
                                      then ''
                                   ---------------------------------------
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarminimumenabledflag = 1)      and 
                                        (T.netextchargeamount <= T.dollarminimum) and
                                        (T.dollarminimum <> 0)
                                      then T.FrequencyName + ' ' + 'Fee is subject to a $' + convert(varchar(50),T.dollarminimum) + ' minimum' + '.|'
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarminimumenabledflag = 1)      and 
                                        (T.netextchargeamount >= T.dollarminimum) and
                                        (T.dollarminimum <> 0)
                                      then T.FrequencyName + ' ' + 'Fee is subject to a $' + convert(varchar(50),T.dollarminimum) + ' minimum' + '.|'
                                   ---------------------------------------
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarmaximumenabledflag = 1)      and 
                                        (T.netextchargeamount <= T.dollarmaximum) and
                                        (T.dollarmaximum <> 0)
                                      then T.FrequencyName + ' ' + 'Fee is subject to a $' + convert(varchar(50),T.dollarminimum) + ' minimum' + '.|'
                                   when (T.propertythresholdoverride=0)       and 
                                        (T.dollarmaximumenabledflag = 1)      and 
                                        (T.netextchargeamount >= T.dollarmaximum) and
                                        (T.dollarmaximum <> 0)
                                      then T.FrequencyName + ' ' + 'Fee is subject to a $' + convert(varchar(50),T.dollarminimum) + ' minimum' + '.|'
                                   --------------------------------------- 
                                   else ''
                                   ---------------------------------------
                                end) +
                                (case when (@LI_ordersynchstartmonth <> 0) and 
                                           (coalesce(datediff(m,T.activationstartdate,T.activationenddate+1),12) < 12) and
                                           (T.Chargetypecode= 'ACS')       and
                                           (T.frequencycode = 'YR')
                                         then 'Net Charge may be prorated based on contract length'+ '.|'
                                       else ''
                                 end)
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)  
  where (T.measurecode <> 'TRAN')


  Update T 
     set T.multiplier             = (Case when T.MeasureCode = 'UNIT' then T.Units
                                          when T.MeasureCode in ('SITE','PMC') then 1
                                          else  (case when (T.extchargeamount = T.chargeamount) then 1
                                                      else (Convert(float,T.extchargeamount))/(case when (T.chargeamount)=0 then 1 else (Convert(float,T.chargeamount)) end)
                                                 end)
                                    end )
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)
  where T.measurecode <> 'TRAN'
  and   T.propertythresholdoverride=0
  and   T.dollarminimumenabledflag =1
  and   T.netextchargeamount <= T.dollarminimum


  Update T
  set    T.PricingLineItemNotes = T.PricingLineItemNotes + ' ' + 'RealPage will no longer support this product after 08/31/2010. Please contact your sales representative at 1-87-REALPAGE to schedule your upgrade to OneSite prior to this date' + '.|'     
  from #TEMP_PropertiesProductsHoldingTable T with (nolock) 
  Where T.FamilyCode = 'LEG'
  and   T.ProductCode in ('PRM-LEG-LAF-HMG-LHCP', --HUDManager 2000 CP
                          'PRM-LEG-LAF-HMG-LHUD', --HUDManager 2000
                          'PRM-LEG-LAF-HUP-LHMP', --HUDManager 2000 Plus
                          'PRM-LEG-LAF-HMG-HSBF', --HUDManager 2000 Service Bureau        
                          'PRM-LEG-LAF-RHS-LRHS'  --RHSManager
                         )
  -----------------------------------------------------------------------------------------
  -- select netextchargeamount,extchargeamount,discountPercent
  -- from #TEMP_PropertiesProductsHoldingTable --
  --Pricing: Step 1.3 : Get weightofProducttototal and new netextchargeamount
  --                    For CustomBundle Only : This is revenue allocation 
  --                    based on  weightofProduct netextchargeamount to Bundle's Netextchargeamount.
  -----------------------------------------------------------------------------------------  
  --Step 1.3 -- Update for netchargeamount,netextchargeamount 
  ---            only for custombundlenameenabledflag = 1
  Update T 
     set T.netchargeamount       = convert(float,T.chargeamount) -   ((convert(float,T.chargeamount) * convert(float,T.discountpercent))/100),                                                                                                       
         T.netextchargeamount    = convert(float,T.extchargeamount) -   ((convert(float,T.extchargeamount) * convert(float,T.discountpercent))/100),
         T.multiplier             = (case when (T.extchargeamount = T.chargeamount) then 1
                                         else (Convert(float,T.extchargeamount))/(case when (T.chargeamount)=0 then 1 else (Convert(float,T.chargeamount)) end)
                                    end)                                                     
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)
  where T.custombundlenameenabledflag = 1
  -----------------------------------------------------------------------------------------  
  Update D
  set  D.weightofProducttototal = ((convert(float,D.extchargeamount))/
                                   (case when D.Chargetypecode = 'ILF' 
                                            then (case when S.ILFBundleTotalextchargeamount=0 then 1 else convert(float,S.ILFBundleTotalextchargeamount) end)
                                         when D.Chargetypecode = 'ACS' 
                                            then (case when S.ACSBundleTotalextchargeamount=0 then 1 else convert(float,S.ACSBundleTotalextchargeamount) end)
                                         else (case when D.extchargeamount=0 then 1 else convert(numeric(30,5),D.extchargeamount) end)
                                     end)
                                   ), --- Weightofproduct with respect to BundleTotal for customBundle.

       D.netextchargeamount     = Convert(numeric(30,2),
                                  ((convert(float,D.extchargeamount))/
                                   (case when D.Chargetypecode = 'ILF' 
                                            then (case when S.ILFBundleTotalextchargeamount=0 then 1 else convert(float,S.ILFBundleTotalextchargeamount) end)
                                         when D.Chargetypecode = 'ACS' 
                                            then (case when S.ACSBundleTotalextchargeamount=0 then 1 else convert(float,S.ACSBundleTotalextchargeamount) end)
                                         else (case when D.extchargeamount=0 then 1 else convert(numeric(30,5),D.extchargeamount) end)
                                     end)
                                   ) --- Weightofproduct with respect to BundleTotal for customBundle.
                                   *
                                   (case when D.Chargetypecode = 'ILF' 
                                            then S.ILFBundleTotalnetextchargeamount
                                         when D.Chargetypecode = 'ACS' 
                                            then S.ACSBundleTotalnetextchargeamount
                                         else D.netextchargeamount
                                     end)
                                   ),
       D.custombundleTotalamount = convert(numeric(30,2),
                                   (case when D.Chargetypecode = 'ILF' 
                                            then S.ILFBundleTotalnetextchargeamount
                                         when D.Chargetypecode = 'ACS' 
                                            then S.ACSBundleTotalnetextchargeamount
                                         else D.netextchargeamount
                                     end)
                                   )
  from #TEMP_PropertiesProductsHoldingTable D with (nolock)
  inner join
       (Select  X.groupid   as    groupid,
                X.orderid   as    orderid,
                X.custombundlenameenabledflag as custombundlenameenabledflag,
                X.statuscode                  as statuscode,
                X.RenewalCount                as RenewalCount,
                sum((case when X.ChargeTypecode  = 'ILF' then X.extchargeamount else 0 end))       as ILFBundleTotalextchargeamount,
                sum((case when X.ChargeTypecode  = 'ILF' then X.netextchargeamount else 0 end))    as ILFBundleTotalnetextchargeamount,
                sum((case when X.ChargeTypecode  = 'ACS' then X.extchargeamount else 0 end))       as ACSBundleTotalextchargeamount,
                sum((case when X.ChargeTypecode  = 'ACS' then X.netextchargeamount else 0 end))    as ACSBundleTotalnetextchargeamount
         from  #TEMP_PropertiesProductsHoldingTable X with (nolock)
         where X.custombundlenameenabledflag = 1
         GROUP BY X.orderid,X.groupid,X.custombundlenameenabledflag,
                  X.statuscode,X.RenewalCount
         ) S
  ON    D.groupid = S.groupid
  and   D.orderid = S.orderid
  and   D.orderid = @IPVC_OrderID  
  and   S.orderid = @IPVC_OrderID 
  and   D.RenewalCount = S.RenewalCount
  and   D.custombundlenameenabledflag = S.custombundlenameenabledflag  
  and   D.statuscode                  = S.statuscode  
  and   D.custombundlenameenabledflag = 1 
      
  -----------------------------------------------------------------------------------------
  ---Plug for last item (per Gwen)
  Update D
  set    D.netextchargeamount = convert(numeric(30,2),D.netextchargeamount) + 
                                (
                                   (case when D.Chargetypecode = 'ILF' 
                                            and (convert(numeric(30,2),D.custombundleTotalamount) <> convert(numeric(30,2),S.ILFBundleTotalnetextchargeamount))
                                              then  (convert(numeric(30,2),D.custombundleTotalamount) - convert(numeric(30,2),S.ILFBundleTotalnetextchargeamount))                           
                                         when D.Chargetypecode = 'ACS' 
                                             and (convert(numeric(30,2),D.custombundleTotalamount) <> convert(numeric(30,2),S.ACSBundleTotalnetextchargeamount))
                                              then  (convert(numeric(30,2),D.custombundleTotalamount) - convert(numeric(30,2),S.ACSBundleTotalnetextchargeamount))
                                         else 0
                                    end)
                                 )
  from #TEMP_PropertiesProductsHoldingTable D with (nolock)
  inner join
       (Select  X.groupid   as    groupid,
                X.orderid   as    orderid,
                X.custombundlenameenabledflag as custombundlenameenabledflag,                
                X.statuscode                  as statuscode,                
                sum((case when X.ChargeTypecode  = 'ILF' then X.netextchargeamount else 0 end))       as ILFBundleTotalnetextchargeamount,
                sum((case when X.ChargeTypecode  = 'ACS' then X.netextchargeamount else 0 end))       as ACSBundleTotalnetextchargeamount,
                X.renewalcount
         from  #TEMP_PropertiesProductsHoldingTable X with (nolock)  
         where X.custombundlenameenabledflag = 1       
         GROUP BY X.orderid,X.groupid,X.custombundlenameenabledflag,
                  X.statuscode,X.renewalcount
         ) S
  ON    D.groupid = S.groupid
  and   D.orderid = S.orderid
  and   D.renewalcount = S.renewalcount
  and   D.orderid = @IPVC_OrderID  
  and   S.orderid = @IPVC_OrderID 
  and   D.custombundlenameenabledflag = S.custombundlenameenabledflag  
  and   D.statuscode                  = S.statuscode 
  and   D.custombundlenameenabledflag = 1 
  Inner Join
        (select max(Y.orderitemid)  as maxorderitemid,
                Y.renewalcount      as maxrenewalcount,
                Y.orderid,Y.groupid,Y.ChargeTypeCode,
                Y.statuscode,Y.custombundlenameenabledflag
                from   #TEMP_PropertiesProductsHoldingTable Y with (nolock)
                where  Y.orderid = @IPVC_OrderID
                and    Y.custombundlenameenabledflag = 1
                group by Y.orderid,Y.groupid,Y.ChargeTypeCode,
                         Y.statuscode,Y.custombundlenameenabledflag,Y.renewalcount
        ) XOUT
  on     D.orderid           = XOUT.orderid
  and    D.groupid           = XOUT.groupid
  and    D.orderitemid       = XOUT.maxorderitemid                                                       
  and    D.renewalcount      = XOUT.maxrenewalcount
  and    D.ChargeTypeCode    = XOUT.ChargeTypeCode  
  and    D.statuscode        = XOUT.statuscode  
  and    D.custombundlenameenabledflag    = XOUT.custombundlenameenabledflag
  and    D.custombundlenameenabledflag    = 1
  and    XOUT.custombundlenameenabledflag = 1 
  -----------------------------------------------------------------------------------------
  --Pricing: Step 2 : Get NetchargeAmount,netextchargeamount,discountamount,multiplier,
  -----                   extyear1chargeamount,netextyear1chargeamount
  -----------------------------------------------------------------------------------------
  --Calculating NetchargeAmount and extyear1 amounts
  /* Update T 
     set T.netchargeamount        = (T.chargeamount - (T.chargeamount * (T.discountpercent)/100)),
         T.netextchargeamount     = (T.extchargeamount - (T.extchargeamount * (T.discountpercent)/100)),
         T.discountamount         = (T.extchargeamount * (T.discountpercent)/100),
         T.multiplier             = (T.extchargeamount)/(case when (T.chargeamount)=0 then 1 else (T.chargeamount) end)
               
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)
  */
  Update T
    set T.unitofmeasure          = (Case when (T.measurecode = 'SITE') and (T.Quantityenabledflag = 0)
                                           then T.Sites
                                         when (T.measurecode = 'UNIT') and (T.Quantityenabledflag = 0)
                                           then T.SOCunits
                                         when (T.measurecode = 'PMC')
                                           then (T.extchargeamount)/(case when (T.chargeamount)=0 then 1 else (T.chargeamount) end)
                                        else
                                           (T.extchargeamount)/(case when (T.chargeamount)=0 then 1 else (T.chargeamount) end)
                                    end),

        T.discountamount         = (T.extchargeamount - T.netextchargeamount),        
        T.extyear1chargeamount   = convert(numeric(30,2),(T.extchargeamount)) * ((case when (T.quantityenabledflag=1 and T.quantitymultiplierflag=0) then 1
                                                                    when (T.quantityenabledflag=1 and T.quantitymultiplierflag=1) then T.frequencymultiplier
                                                                    else T.frequencymultiplier 
                                                               end
                                                              )),
         T.netextyear1chargeamount= convert(numeric(30,2),(T.netextchargeamount)) * ((case when (T.quantityenabledflag=1 and T.quantitymultiplierflag=0) then 1
                                                                    when (T.quantityenabledflag=1 and T.quantitymultiplierflag=1) then T.frequencymultiplier
                                                                    else T.frequencymultiplier 
                                                               end
                                                              )),
         T.TotalDiscountAmount = ((T.extchargeamount)-(T.netextchargeamount)),
         T.TotalDiscountPercent= (((T.extchargeamount)-(T.netextchargeamount))*100) / (case when (T.extchargeamount)=0 then 1 
                                                                                               else (T.extchargeamount)
                                                                                          end
                                                                                          )
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)  
  -----------------------------------------------------------------------------------------
  --Final Select   
  -----------------------------------------------------------------------------------------
  select T.orderid                                           as orderid,
         T.groupid                                           as groupid,
         T.orderitemid                                       as orderitemid,
         -------------------------------------------------------------------
         T.statuscode                                        as statuscode,
         T.renewaltypecode                                   as renewaltypecode,
         -------------------------------------------------------------------
         T.productcode                                       as productcode,         
         -------------------------------------------------------------------
         T.productcategorycode                               as productcategorycode,
         T.familycode                                        as familycode,         
         T.chargetypecode                                    as chargetypecode,
         -------------------------------------------------------------------
         T.measurecode                                       as measurecode,         
         -------------------------------------------------------------------
         T.frequencycode                                     as frequencycode,          
         -------------------------------------------------------------------
         T.chargeamount                                      as chargeamount,
         ------------------------------------------------------------------- 
         T.discountpercent                                   as discountpercent,
         (case when (T.extchargeamount) > 0 
                  then ((T.extchargeamount)- (T.netextchargeamount)) 
               when (T.chargeamount) >= 0 
                  then ((T.chargeamount)- (T.netchargeamount))
          end
         )                                                   as discountamount,
         ----------------------------------------------------------------------
         (case when (T.extchargeamount) > 0 
                   then ((T.extchargeamount)- (T.netextchargeamount))*(100)/
                        (case when (T.extchargeamount)=0 then 1
                              else (T.extchargeamount)
                        end)  
                when (T.chargeamount) >= 0 
                   then (convert(float,(T.chargeamount))- convert(float,(T.netchargeamount)))*(100)/
                        (case when (T.chargeamount)=0 then 1
                              else convert(float,(T.chargeamount))
                        end) 
            end
           )                                                    as Totaldiscountpercent,
           (case when (T.extchargeamount) > 0 
                    then ((T.extchargeamount)- (T.netextchargeamount)) 
                 when (T.chargeamount) >= 0 
                    then ((T.chargeamount)- (T.netchargeamount))
            end
           )                                                    as Totaldiscountamount,
           -------------------------------------------------------------------
          convert(numeric(30,2),(T.extchargeamount))            as extchargeamount,
          convert(numeric(30,2),(T.extSOCchargeamount))         as extSOCchargeamount,
         ------------------------------------------------------------------------ 
          (T.unitofmeasure)                               as unitofmeasure, 
         /*(case when T.extchargeamount =T.chargeamount
                  then 1
               else (convert(decimal(18,6),T.extchargeamount))/
                      (case when (T.chargeamount)=0 then 1 
                         else (convert(decimal(18,6),T.chargeamount)) end)
          end
         )*/ 
         T.multiplier                                                  as multiplier,
         convert(numeric(30,2),(T.extyear1chargeamount))    as extyear1chargeamount,         
         convert(numeric(30,3),(T.netchargeamount))         as netchargeamount,
         convert(numeric(30,2),(T.netextchargeamount))      as netextchargeamount,
         convert(numeric(30,2),(T.netextyear1chargeamount)) as netextyear1chargeamount, 
         (T.oiunits)                                        as units,
         (T.oibeds)                                         as beds,
         (T.ppupercentage)                                  as ppupercentage,        
         (T.pricingtiers)                                   as pricingtiers,
         (T.PricingLineItemNotes)                           as PricingLineItemNotes
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)
  /*group by T.orderid,T.groupid,T.orderitemid,T.statuscode,T.renewaltypecode,T.productcode,T.productcategorycode,
           T.familycode,T.chargetypecode,T.measurecode,T.frequencycode
  */
  -----------------------------------------------------------------------------------------
  --Cleaning up after Final Select
  ----------------------------------------------------------------------------------------- 
  drop table #TEMP_PropertiesProductsHoldingTable
  -----------------------------------------------------------------------------------------
END
GO
