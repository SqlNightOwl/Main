SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec QUOTES.dbo.uspQUOTES_PriceEngineTEST @IPVC_QuoteID='Q0000005841',@IPI_GroupID=6362,@IPVC_PropertyAmountAnnualized='NO'
exec QUOTES.dbo.uspQUOTES_PriceEngineTEST @IPVC_QuoteID='Q0000005841',@IPI_GroupID=6377,@IPVC_PropertyAmountAnnualized='NO'
exec QUOTES.dbo.uspQUOTES_PriceEngineTEST @IPVC_QuoteID='Q0000005841',@IPI_GroupID=6378,@IPVC_PropertyAmountAnnualized='NO'
*/
CREATE PROCEDURE [quotes].[uspQUOTES_PriceEngineTEST] (@IPVC_QuoteID                    varchar(50),
                                                @IPI_GroupID                     bigint=-9999,
                                                @IPI_QuoteItemID                 bigint=-9999,
                                                @IPVC_PropertyAmountAnnualized   varchar(10) = 'NO'                                         
                                               )
AS
BEGIN   
  set nocount on   
  -------------------------------------------------------------------------------------------------
  --Declaring Local Temp Tables  
  create table #TEMP_PropertiesProductsHoldingTable 
                               (SEQ                           int not null identity(1,1),
                                quoteid                       varchar(50),
                                groupid                       bigint,
                                quoteitemid                   bigint, 
                                propertyid                    varchar(50)   null,
                                pricetypecode                 varchar(50)   not null default 'Normal',
                                SOCpricetypecode              as (case when SOCunits < 100 then 'Small'
                                                                       Else 'Normal'
                                                                  end),
                                propertythresholdoverride     int           not null default 0,                                
                                grouptype                     varchar(50)   not null default 'SITE',
                                productcode                   varchar(100),
                                productcategorycode           varchar(50),                                
                                familycode                    varchar(50),                                                              
                                chargetypecode                varchar(50),                                
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
                                sites                         numeric(30,5) not null default 0,
                                units                         numeric(30,5) not null default 0,                                
                                SOCunits                      numeric(30,5) not null default 0,                                
                                ppupercentage                 numeric(30,5) not null default 100,
                                ppuadjustedunits              numeric(30,0) not null default 0,
                                --ppuadjustedunits              as as convert(numeric(30,0),round((convert(numeric(30,5),(units * ppupercentage))/(100)),0)),
                                SOCppuadjustedunits           as convert(numeric(30,0),round((convert(numeric(30,5),(SOCunits * ppupercentage))/(100)),0)),
                                quantity                      numeric(30,5) not null default 1,
                                unitbasis                     numeric(30,5) not null default 1,
                                minunits                      numeric(30,5) not null default 0,
                                maxunits                      numeric(30,5) not null default 0,
                                SOCminunits                   numeric(30,5) not null default 0,
                                SOCmaxunits                   numeric(30,5) not null default 0,
                                FlatPriceFlag                 int           not null default 0,
                                minthresholdoverride          int           not null default 1,
                                maxthresholdoverride          int           not null default 1,
                                quantityenabledflag           int           not null default 0,
                                quantitymultiplierflag        int           not null default 0,
                                dollarminimum                 money         not null default 0,
                                dollarminimumenabledflag      int           not null default 0,
                                dollarmaximum                 money         not null default 0,
                                dollarmaximumenabledflag      int           not null default 0,
               
                                SOCdollarminimum              money         not null default 0,
                                SOCdollarminimumenabledflag   int           not null default 0,
                                SOCdollarmaximum              money         not null default 0,
                                SOCdollarmaximumenabledflag   int           not null default 0,
  
                                chargeamount                  numeric(30,3) not null default 0,
                                SOCchargeamount               numeric(30,3) not null default 0,
                                discountpercent               float         not null default 0.00,
                                discountamount                numeric(30,2) not null default 0,
                                totaldiscountpercent          float         not null default 0.00,
                                totaldiscountamount           numeric(30,2) not null default 0,
                                unitofmeasure                 numeric(30,5) not null default 0.00,
                                mutliplier                    numeric(30,5) not null default 0.00,                                 
                                extchargeamount               numeric(30,2) not null default 0,
                                extSOCchargeamount            numeric(30,2) not null default 0,
                                extyear1chargeamount          numeric(30,2) not null default 0,
                                extyear2chargeamount          numeric(30,2) not null default 0,
                                extyear3chargeamount          numeric(30,2) not null default 0,
                                netchargeamount               numeric(30,3) not null default 0,
                                netextchargeamount            numeric(30,2) not null default 0,
                                netextyear1chargeamount       numeric(30,2) not null default 0,
                                netextyear2chargeamount       numeric(30,2) not null default 0,
                                netextyear3chargeamount       numeric(30,2) not null default 0,
                                weightofProducttototal        numeric(30,5) not null default 1,
                                custombundleTotalamount       numeric(30,2) not null default 0,
                                custombundlenameenabledflag   int           not null default 0,
                                discallocationcode            varchar(50)   not null default 'SPR',

                                pricecapflagyear1             int           not null default 0,
                                pricecaptermyear1             int           not null default 0,
                                pricecapbasiscodeyear1        varchar(50)   not null default 'LIST',
                                PriceCapPercentyear1          numeric(30,5) not null default 0.00,
                                PriceCapStartDateyear1        datetime      null,
                                PriceCapEndDateyear1          datetime      null,
                                
                                pricecapflagyear2             int           not null default 0,
                                pricecaptermyear2             int           not null default 0,
                                pricecapbasiscodeyear2        varchar(50)   not null default 'LIST',
                                PriceCapPercentyear2          numeric(30,5) not null default 0.00,
                                PriceCapStartDateyear2        datetime      null,
                                PriceCapEndDateyear2          datetime      null,
                                PriceByPPUPercentageEnabledFlag int           not null default 0
                               )
 
  create table #temp_priceCapholdingTable (propertyid                    varchar(50)   null,
                                           pricecapflag                  int           not null default 0,
                                           pricecapterm                  int           not null default 0,
                                           pricecapbasiscode             varchar(50)   not null default 'LIST',
                                           PriceCapPercent               numeric(30,5) not null default 0.00,
                                           PriceCapStartDate             datetime      null,
                                           PriceCapEndDate               datetime      null, 
                                           productcode                   varchar(100) 
                                          )                                  
  -------------------------------------------------------------------------------------------------
  declare @LDT_QuoteCreateDate  datetime
  declare @LVC_CompanyID        varchar(50)

  select @LDT_quotecreatedate = convert(datetime,convert(varchar(50),Q.createdate,101)),
         @LVC_CompanyID       = Q.CustomerIDSeq
  from   Quotes.dbo.Quote Q with (nolock)
  where  Q.Quoteidseq = @IPVC_QuoteID   
  -------------------------------------------------------------------------------------------------
  insert into #TEMP_PropertiesProductsHoldingTable
             (quoteid,groupid,quoteitemid,propertyid,pricetypecode,propertythresholdoverride,
              grouptype,productcode,
              productcategorycode,familycode,chargetypecode,measurecode,
              frequencycode,sites,units,SOCunits,
              ppupercentage,ppuadjustedunits,
              quantity,unitbasis,minunits,maxunits,SOCminunits,SOCmaxunits,FlatPriceFlag,
              minthresholdoverride,
              maxthresholdoverride,quantityenabledflag,quantitymultiplierflag,
              dollarminimum,dollarminimumenabledflag,dollarmaximum,dollarmaximumenabledflag,
              SOCdollarminimum,SOCdollarminimumenabledflag,SOCdollarmaximum,SOCdollarmaximumenabledflag,
              chargeamount,SOCchargeamount,discountpercent,discountamount,
              custombundlenameenabledflag,discallocationcode,PriceByPPUPercentageEnabledFlag)
  Select     distinct
             QI.QuoteIDSeq                               as quoteid,
             QI.GroupIDSeq                               as groupid,
             QI.IDSeq                                    as quoteitemidseq,
             P.IDSeq                                     as propertyid,
             coalesce(GP.PriceTypeCode,'Normal')         as pricetypecode,
             coalesce(GP.thresholdoverrideflag,0)        as propertythresholdoverride,                          
             ltrim(rtrim(G.GroupType))                   as grouptype,
             ltrim(rtrim(QI.ProductCode))                as productcode,
             PR.CategoryCode                             as productcategorycode,
             ltrim(rtrim(PR.familycode))                 as familycode,
             ltrim(rtrim(QI.ChargeTypeCode))             as chargetypecode,
             ltrim(rtrim(QI.MeasureCode))                as measurecode,             
             --------------------------------------------------------------
             ltrim(rtrim(QI.FrequencyCode))              as frequencycode,
             --------------------------------------------------------------
             (case when (ltrim(rtrim(G.GroupType)) <> 'PMC') and 
                        (P.IDSeq is not null)
                       then 1 
                   when (ltrim(rtrim(G.GroupType)) <> 'PMC') and 
                        (P.IDSeq is  null)
                       then 0
                   when (ltrim(rtrim(G.GroupType)) = 'PMC') 
                       then 1
                   else 0
              end
             )                                           as sites, 
             --------------------------------------------------------------       
             (case when ((P.StudentLivingFlag = 1)    and
                         (C.PriceByBedEnabledFlag = 1)
                        )                             and
                        (QI.CapMaxUnitsFlag = 1)      and
                        (coalesce(GP.Beds,P.Beds,0)  >= 
                         coalesce(QI.MaxUnits,C.MaxUnits,0)
                        )
                       then coalesce(QI.MaxUnits,C.MaxUnits,0)
                    when ((P.StudentLivingFlag = 1)    and
                         (C.PriceByBedEnabledFlag = 1)
                        )
                        then coalesce(GP.Beds,P.Beds,0)
                    when (QI.CapMaxUnitsFlag = 1)      and
                         (coalesce(GP.Units,P.Units,0) >= 
                          coalesce(QI.MaxUnits,C.MaxUnits,0)
                         )
                     then coalesce(QI.MaxUnits,C.MaxUnits,0)
                  else coalesce(GP.Units,P.Units,0)
              end
             )                                           as units,            
             --------------------------------------------------------------
             (case when ((P.StudentLivingFlag = 1)    and
                         (C.PriceByBedEnabledFlag = 1)
                        )
                      then coalesce(GP.Beds,P.Beds,0)
                   else
                      coalesce(GP.Units,P.Units,0)
              end
             )                                           as SOCunits,
             --------------------------------------------------------------
             coalesce(GP.PPUPercentage,P.PPUPercentage,100) 
                                                         as ppupercentage,
             (case when ((P.StudentLivingFlag = 1)    and
                         (C.PriceByBedEnabledFlag = 1)
                        )                             and
                        (QI.CapMaxUnitsFlag = 1)      and
                        (coalesce(convert(numeric(30,0),
                                             round((convert(numeric(30,5),(coalesce(GP.Beds,P.Beds,0) * coalesce(GP.PPUPercentage,P.PPUPercentage,100)))/(100)
                                          )
                                            ,0)
                                          )
                                 ,0)  >= 
                         coalesce(QI.MaxUnits,C.MaxUnits,0)
                        )
                       then coalesce(convert(numeric(30,0),round(QI.MaxUnits,C.MaxUnits,0)),0)
                    when ((P.StudentLivingFlag = 1)    and
                          (C.PriceByBedEnabledFlag = 1)
                         )
                        then coalesce(convert(numeric(30,0),round((convert(numeric(30,5),(coalesce(GP.Beds,P.Beds,0) * coalesce(GP.PPUPercentage,P.PPUPercentage,100)))/(100)
                                                               )
                                                             ,0)
                                          )
                                 ,0)
                    when (QI.CapMaxUnitsFlag = 1)      and
                         (coalesce(convert(numeric(30,0),round((convert(numeric(30,5),(coalesce(GP.Units,P.Units,0) * coalesce(GP.PPUPercentage,P.PPUPercentage,100)))/(100)
                                                               )
                                                             ,0)
                                          )
                                 ,0) >= 
                          coalesce(QI.MaxUnits,C.MaxUnits,0)
                         )
                     then coalesce(convert(numeric(30,0),round(QI.MaxUnits,C.MaxUnits,0)),0)
                  else coalesce(convert(numeric(30,0),round((convert(numeric(30,5),(coalesce(GP.Units,P.Units,0) * coalesce(GP.PPUPercentage,P.PPUPercentage,100)))/(100)
                                                               )
                                                             ,0)
                                          )
                                 ,0)
              end
             )                                           as ppuadjustedunits,
             --------------------------------------------------------------
             coalesce(QI.Quantity,1)                     as Quantity,
             coalesce(C.UnitBasis,1)                     as unitbasis,
             coalesce(QI.MinUnits,C.MinUnits,0)          as minunits,
             coalesce(QI.MaxUnits,C.MaxUnits,0)          as maxunits,
             coalesce(C.MinUnits,0)                      as SOCminunits,
             coalesce(C.MaxUnits,0)                      as SOCmaxunits,
             C.FlatPriceFlag                             as FlatPriceFlag,
             C.MinThresholdOverride                      as MinThresholdOverride,
             C.MaxThresholdOverride                      as MaxThresholdOverride,
             coalesce(C.quantityenabledflag,0)           as quantityenabledflag,
             coalesce(C.QuantityMultiplierFlag,0)        as quantitymultiplierflag,

             coalesce(QI.dollarminimum,C.dollarminimum,0) as dollarminimum,
             coalesce(C.dollarminimumenabledflag,0)       as dollarminimumenabledflag,
             coalesce(QI.dollarmaximum,C.dollarmaximum,0) as dollarmaximum,
             coalesce(C.dollarmaximumenabledflag,0)       as dollarmaximumenabledflag,

             coalesce(C.dollarminimum,0)                  as SOCdollarminimum,
             coalesce(C.dollarminimumenabledflag,0)       as SOCdollarminimumenabledflag,
             coalesce(C.dollarmaximum,0)                  as SOCdollarmaximum,
             coalesce(C.dollarmaximumenabledflag,0)       as SOCdollarmaximumenabledflag,

             QI.ChargeAmount                              as chargeamount,             
             C.ChargeAmount                               as SOCchargeamount,
             QI.DiscountPercent                           as discountpercent,
             QI.DiscountAmount                            as discountamount,
             G.custombundlenameenabledflag                as custombundlenameenabledflag,
             G.discallocationcode                         as discallocationcode,
             C.PriceByPPUPercentageEnabledFlag            as PriceByPPUPercentageEnabledFlag
  from       QUOTES.dbo.[Group]   G  with (nolock) 
  ----------->>>>>>>>>>Inner Joins>>>>>>>>>>>>>>>>---------- 
  inner join QUOTES.dbo.QuoteItem QI with (nolock) 
        on   G.QuoteIDSeq   = QI.QuoteIDSeq 
        and  G.IDSeq        = QI.GroupIDSeq
        and  G.QuoteIDSeq   = @IPVC_QuoteID 
        and  G.IDSeq        = (case when @IPI_GroupID = -9999 then G.IDSeq else @IPI_GroupID end)
        and  QI.QuoteIDSeq  = @IPVC_QuoteID  
        and  QI.GroupIDSeq  = (case when @IPI_GroupID = -9999 then QI.GroupIDSeq else @IPI_GroupID end)
        and  QI.IDSeq       = (case when @IPI_QuoteItemID = -9999 then QI.IDSeq else @IPI_QuoteItemID end)
  inner join PRODUCTS.dbo.Charge  C  with (nolock) 
        on  ltrim(rtrim(C.ProductCode))   = ltrim(rtrim(QI.ProductCode))       
        and ltrim(rtrim(C.ChargeTypeCode))= ltrim(rtrim(QI.ChargeTypeCode))    
        and ltrim(rtrim(C.MeasureCode))   = ltrim(rtrim(QI.MeasureCode))       
        and ltrim(rtrim(C.FrequencyCode)) = ltrim(rtrim(QI.FrequencyCode))
        and C.PriceVersion  = QI.PriceVersion
  inner join PRODUCTS.dbo.Product PR with (nolock) 
        on  ltrim(rtrim(PR.Code))         = ltrim(rtrim(C.ProductCode))        
        and ltrim(rtrim(PR.code))         = ltrim(rtrim(QI.productcode))
        and PR.PriceVersion  = C.PriceVersion
        and C.PriceVersion   = QI.PriceVersion
  ----------->>>>>>>>>>Left Joins>>>>>>>>>>>>>>>>-----------
  left join QUOTES.dbo.GroupProperties GP with (nolock)  
        on   G.QuoteIDSeq   = GP.QuoteIDSeq  
        and  G.IDSeq        = GP.GroupIDSeq  
        and  G.QuoteIDSeq   = @IPVC_QuoteID  
        and  G.IDSeq        = (case when @IPI_GroupID = -9999 then G.IDSeq  else @IPI_GroupID end)       
        and  GP.QuoteIDSeq  = @IPVC_QuoteID 
        and  GP.GroupIDSeq  = (case when @IPI_GroupID = -9999 then GP.GroupIDSeq else @IPI_GroupID end)
  left join CUSTOMERS.dbo.Property P with (nolock) 
        on  GP.PropertyIDSeq= P.IDSeq         
  where G.QuoteIDSeq        = @IPVC_QuoteID 
  and   G.IDSeq             = (case when @IPI_GroupID = -9999 then G.IDSeq  else @IPI_GroupID end)   
  -------------------------------------------------------------------------------------------------
  Insert into #temp_priceCapholdingTable(propertyid,pricecapflag,pricecapterm,pricecapbasiscode,
                                         PriceCapPercent,PriceCapStartDate,PriceCapEndDate,productcode)
  select distinct PCPRP.Propertyidseq,1 as pricecapflag,PC.pricecapterm,PC.pricecapbasiscode,PC.PriceCapPercent,
                  PC.PriceCapStartDate, PC.PriceCapEndDate,
                  ltrim(rtrim(PCP.ProductCode))
  From   CUSTOMERS.dbo.PriceCap PC With (nolock)
  inner join
         CUSTOMERS.dbo.PriceCapProducts PCP With (nolock)
  on     PC.IDSeq = PCP.PricecapIDSeq 
  and    PC.companyidseq = PCP.companyidseq
  and    PC.ActiveFlag = 1
  and    PC.companyidseq = @LVC_CompanyID
  and    exists (select top 1 1 from #TEMP_PropertiesProductsHoldingTable T with (nolock)
                 where T.productcode = ltrim(rtrim(PCP.ProductCode))
                )
  left outer join
         CUSTOMERS.dbo.PriceCapProperties PCPRP With (nolock)
  on     PC.IDSeq          = PCPRP.PricecapIDSeq
  and    PC.companyidseq   = PCPRP.companyidseq
  and    PC.companyidseq   = @LVC_CompanyID
  and    PCPRP.companyidseq= @LVC_CompanyID
  and    PC.ActiveFlag = 1
  and    PCP.PricecapIDSeq = PCPRP.PricecapIDSeq
  and    PCP.companyidseq  = PCPRP.companyidseq
  and    PCP.companyidseq   = @LVC_CompanyID
  -------------------------------------------------------------------------------------------------
  ---Update for PriceCap
  Update T
  set    T.pricecapflagyear1     = S.pricecapflag,
         T.pricecaptermyear1     = S.pricecapterm,
         T.pricecapbasiscodeyear1=S.pricecapbasiscode,
         T.PriceCapPercentyear1  =S.PriceCapPercent,
         T.PriceCapStartDateyear1=S.PriceCapStartDate,
         T.PriceCapEndDateyear1  =S.PriceCapEndDate
  from   #TEMP_PropertiesProductsHoldingTable T with (nolock) 
  inner join
         #temp_priceCapholdingTable S with (nolock)
  on     T.ProductCode = S.ProductCode
  and    Coalesce(T.propertyid,'') = Coalesce(S.propertyid,'')
  and   ((dateadd(yy,1,@LDT_quotecreatedate) >= S.PriceCapStartDate) 
                and   
         (dateadd(yy,1,@LDT_quotecreatedate) <= S.PriceCapEndDate)
         )
               

  Update T
  set    T.pricecapflagyear2     = S.pricecapflag,
         T.pricecaptermyear2     = S.pricecapterm,
         T.pricecapbasiscodeyear2=S.pricecapbasiscode,
         T.PriceCapPercentyear2  =S.PriceCapPercent,
         T.PriceCapStartDateyear2=S.PriceCapStartDate,
         T.PriceCapEndDateyear2  =S.PriceCapEndDate
  from   #TEMP_PropertiesProductsHoldingTable T with (nolock) 
  inner join
         #temp_priceCapholdingTable S with (nolock)
  on     T.ProductCode = S.ProductCode
  and    Coalesce(T.propertyid,'') = Coalesce(S.propertyid,'')
  and   ((dateadd(yy,2,@LDT_quotecreatedate) >= S.PriceCapStartDate) 
                and   
         (dateadd(yy,2,@LDT_quotecreatedate) <= S.PriceCapEndDate)
        )
        
  -----------------------------------------------------------------------------------------
  --Pricing: Step 1 : Get extchargeamount,extSOCchargeamount 
  --select * from #TEMP_PropertiesProductsHoldingTable
  --select productcode,chargetypecode,measurecode,
  --chargeamount,units,ppuadjustedunits,ppupercentage,propertyid,propertythresholdoverride,pricetypecode,
  -- From #TEMP_PropertiesProductsHoldingTable
  -----------------------------------------------------------------------------------------
  Update T 
     set  extchargeamount = CASE
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
  from #TEMP_PropertiesProductsHoldingTable T   
  -----------------------------------------------------------------------------------------
  --Step 1.1 -- Update for netchargeamount,netextchargeamount
  Update T 
     set T.netchargeamount        = (T.chargeamount - (T.chargeamount * (T.discountpercent)/100)),
         T.netextchargeamount     = (T.extchargeamount - (T.extchargeamount * (T.discountpercent)/100))               
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)
  -----------------------------------------------------------------------------------------
  --Step 1.2 -- Update for Dollar Minimum and Dollar maximum
  Update T
  Set    T.extchargeamount = (case when (T.grouptype <> 'PMC')               and             
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
                                end)
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)  
  -----------------------------------------------------------------------------------------
  --Pricing: Step 1.3 : Get weightofProducttototal and new netextchargeamount
  --                    For CustomBundle Only : This is revenue allocation 
  --                    based on  weightofProduct netextchargeamount to Bundle's Netextchargeamount.
  -----------------------------------------------------------------------------------------  
  --Step 1.3 -- Update for netchargeamount,netextchargeamount 
  ---            only for custombundlenameenabledflag = 1
  /* Update T 
     set T.netchargeamount        = (T.chargeamount - (T.chargeamount * (T.discountpercent)/100)),
         T.netextchargeamount     = (T.extchargeamount - (T.extchargeamount * (T.discountpercent)/100))               
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)
  where T.custombundlenameenabledflag = 1
  */
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

       D.netextchargeamount     = ((convert(float,D.extchargeamount))/
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
                                     end),
       D.custombundleTotalamount = (case when D.Chargetypecode = 'ILF' 
                                            then S.ILFBundleTotalnetextchargeamount
                                         when D.Chargetypecode = 'ACS' 
                                            then S.ACSBundleTotalnetextchargeamount
                                         else D.netextchargeamount
                                     end)
  from #TEMP_PropertiesProductsHoldingTable D with (nolock)
  inner join
       (Select  X.groupid   as    groupid,
                X.quoteid   as    quoteid,
                X.custombundlenameenabledflag as custombundlenameenabledflag,
                X.discallocationcode          as discallocationcode,
                X.propertyid                  as propertyid,
                sum((case when X.ChargeTypecode  = 'ILF' then X.extchargeamount else 0 end))          as ILFBundleTotalextchargeamount,
                sum((case when X.ChargeTypecode  = 'ILF' then X.netextchargeamount else 0 end))       as ILFBundleTotalnetextchargeamount,
                sum((case when X.ChargeTypecode  = 'ACS' then X.extchargeamount else 0 end))          as ACSBundleTotalextchargeamount,
                sum((case when X.ChargeTypecode  = 'ACS' then X.netextchargeamount else 0 end))       as ACSBundleTotalnetextchargeamount
         from  #TEMP_PropertiesProductsHoldingTable X with (nolock)
         Where X.quoteid = @IPVC_QuoteID         
         and   X.custombundlenameenabledflag=1
         GROUP BY X.groupid,X.quoteid,X.propertyid,
                  X.custombundlenameenabledflag,X.discallocationcode
         ) S
  ON    D.groupid    = S.groupid
  and   D.quoteid    = S.quoteid
  and   D.propertyid = S.propertyid
  and   D.quoteid = @IPVC_QuoteID  
  and   S.quoteid = @IPVC_QuoteID 
  and   D.custombundlenameenabledflag = S.custombundlenameenabledflag
  and   D.discallocationcode          = S.discallocationcode 
  and   D.custombundlenameenabledflag = 1
  ----------------------------------------------------------------------------------------
  ---Plug for Last quote item (per Gwen) 
  ----- for a property,product,chargetypecode,measurecode,frequencycode.
  Update D
  set    D.netextchargeamount = D.netextchargeamount + 
                                (
                                   (case when D.Chargetypecode = 'ILF' 
                                            and (D.custombundleTotalamount <> S.ILFBundleTotalnetextchargeamount)
                                              then  (D.custombundleTotalamount - S.ILFBundleTotalnetextchargeamount)                           
                                         when D.Chargetypecode = 'ACS' 
                                             and (D.custombundleTotalamount <> S.ACSBundleTotalnetextchargeamount)
                                              then  (D.custombundleTotalamount - S.ACSBundleTotalnetextchargeamount)
                                         else 0
                                    end)
                                 )
  from #TEMP_PropertiesProductsHoldingTable D with (nolock)
  inner join
       (Select  X.groupid   as    groupid,
                X.quoteid   as    quoteid,
                X.custombundlenameenabledflag as custombundlenameenabledflag,
                X.discallocationcode          as discallocationcode,
                X.propertyid                  as propertyid,
                sum((case when X.ChargeTypecode  = 'ILF' then X.extchargeamount else 0 end))          as ILFBundleTotalextchargeamount,
                sum((case when X.ChargeTypecode  = 'ILF' then X.netextchargeamount else 0 end))       as ILFBundleTotalnetextchargeamount,
                sum((case when X.ChargeTypecode  = 'ACS' then X.extchargeamount else 0 end))          as ACSBundleTotalextchargeamount,
                sum((case when X.ChargeTypecode  = 'ACS' then X.netextchargeamount else 0 end))       as ACSBundleTotalnetextchargeamount
         from  #TEMP_PropertiesProductsHoldingTable X with (nolock)
         Where X.quoteid = @IPVC_QuoteID         
         and   X.custombundlenameenabledflag=1
         GROUP BY X.groupid,X.quoteid,X.propertyid,
                  X.custombundlenameenabledflag,X.discallocationcode
         ) S
  ON    D.groupid    = S.groupid
  and   D.quoteid    = S.quoteid
  and   D.propertyid = S.propertyid
  and   D.quoteid    = @IPVC_QuoteID  
  and   S.quoteid    = @IPVC_QuoteID 
  and   D.discallocationcode          = S.discallocationcode
  and   D.custombundlenameenabledflag = S.custombundlenameenabledflag
  and   D.discallocationcode          = S.discallocationcode 
  and   D.custombundlenameenabledflag = 1
  Inner Join
        (select max(Y.quoteitemid) as maxquoteitemid,
                Y.propertyid,Y.quoteid,Y.groupid,Y.ChargeTypeCode,
                Y.discallocationcode,Y.custombundlenameenabledflag
         from   #TEMP_PropertiesProductsHoldingTable Y with (nolock)         
         where  Y.custombundlenameenabledflag = 1
         GROUP BY Y.propertyid,Y.quoteid,Y.groupid,Y.ChargeTypeCode,
                  Y.discallocationcode,Y.custombundlenameenabledflag
        ) Z
  ON   D.quoteitemid       = Z.maxquoteitemid
  and  D.quoteid           = Z.quoteid
  and  D.groupid           = Z.groupid                                                        
  and  D.ChargeTypeCode    = Z.ChargeTypeCode  
  and  D.propertyid        = Z.propertyid  
  and  D.discallocationcode= Z.discallocationcode                               
  and  D.custombundlenameenabledflag = Z.custombundlenameenabledflag
  and  D.custombundlenameenabledflag = 1
  and  Z.custombundlenameenabledflag = 1
  -----------------------------------------------------------------------------------------
  --Pricing: Step 2 : Get unitofmeasure,discountamount,mutliplier,
  -----                   extyear1chargeamount,netextyear1chargeamount
  -----                   TotalDiscountAmount,TotalDiscountPercent
  -----------------------------------------------------------------------------------------
  --Calculating NetchargeAmount and extyear1 amounts
  /*Update T 
     set T.netchargeamount        = (T.chargeamount - (T.chargeamount * (T.discountpercent)/100)),
         T.netextchargeamount     = (T.extchargeamount - (T.extchargeamount * (T.discountpercent)/100)),
         T.discountamount         = (T.extchargeamount * (T.discountpercent)/100),
         T.mutliplier             = (T.extchargeamount)/(case when (T.chargeamount)=0 then 1 else (T.chargeamount) end)               
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
        T.mutliplier             = (T.extchargeamount)/(case when (T.chargeamount)=0 then 1 else (T.chargeamount) end), 
        T.extyear1chargeamount   = (T.extSOCchargeamount * (case when (T.quantityenabledflag=1 and T.quantitymultiplierflag=0) then 1
                                                                   when (T.quantityenabledflag=1 and T.quantitymultiplierflag=1) then T.frequencymultiplier
                                                                   else T.frequencymultiplier 
                                                             end
                                                            )
                                     ), 
         T.netextyear1chargeamount= (T.netextchargeamount) * ((case when (T.quantityenabledflag=1 and T.quantitymultiplierflag=0) then 1
                                                                    when (T.quantityenabledflag=1 and T.quantitymultiplierflag=1) then T.frequencymultiplier
                                                                    else T.frequencymultiplier 
                                                               end
                                                              )),
         T.TotalDiscountAmount = ((T.extSOCchargeamount)-(T.netextchargeamount)),
         T.TotalDiscountPercent= (((T.extSOCchargeamount)-(T.netextchargeamount))*100) / (case when (T.extSOCchargeamount)=0 then 1 
                                                                                               else (T.extSOCchargeamount)
                                                                                          end
                                                                                          )
  from #TEMP_PropertiesProductsHoldingTable T with (nolock)
  -----------------------------------------------------------------------------------------
  --Pricing: Step 3 : Get extyear2chargeamount,netextyear2chargeamount
  -----------------------------------------------------------------------------------------
  Update T 
     set T.extyear2chargeamount  = (CASE when (T.chargetypecode = 'ILF')    then 0
                                         when (T.chargetypecode = 'ACS')    and 
                                              (T.quantityenabledflag = 1)   and 
                                              ((T.frequencycode = 'SG')     OR 
                                               (T.frequencycode = 'OT')
                                              )                             and
                                              ((T.measurecode <> 'PMC')     and
                                               (T.measurecode <> 'SITE')    and
                                               (T.measurecode <> 'UNIT')
                                              )                         
                                                                            then 0
                                         when ((T.chargetypecode = 'ACS')   and
                                               ((T.frequencycode = 'SG')    OR 
                                                (T.frequencycode = 'OT')
                                               )
                                              )                             then 0    
                                         when (T.chargetypecode = 'ACS')   
                                              then
                                                 (case when (T.pricecapflagyear1 = 1)    and
                                                            ((dateadd(yy,1,@LDT_quotecreatedate) >= T.PriceCapStartDateyear1)
                                                                                    and
                                                             (dateadd(yy,1,@LDT_quotecreatedate) <= T.PriceCapEndDateyear1) 
                                                            )                       and
                                                            (T.pricecapbasiscodeyear1='LIST')
                                                          then (T.extyear1chargeamount +
                                                               ((T.extyear1chargeamount * T.PriceCapPercentyear1)/100))
                                                        when (T.pricecapflagyear1 = 1)    and
                                                            ((dateadd(yy,1,@LDT_quotecreatedate) >= T.PriceCapStartDateyear1)
                                                                                    and
                                                             (dateadd(yy,1,@LDT_quotecreatedate) <= T.PriceCapEndDateyear1) 
                                                            )                       and
                                                            (T.pricecapbasiscodeyear1<>'LIST')
                                                          then (T.extyear1chargeamount) 
                                                       -------------------------------------------------------------
                                                       --- For Orders only. No hardcoding. 
                                                       ---else (T.extyear1chargeamount) 
                                                       -------------------------------------------------------------
                                                       -- harcoded to 10% pricecap LIST for Quotes
                                                       else (T.extyear1chargeamount +
                                                               ((T.extyear1chargeamount * 10)/100)) 
                                                       -------------------------------------------------------------
                                                  end
                                                 )
                                         else 0
                                   END
                                   ), 
         T.netextyear2chargeamount = (CASE when (T.chargetypecode = 'ILF')    then 0
                                           when (T.chargetypecode = 'ACS')    and 
                                                (T.quantityenabledflag = 1)   and 
                                                ((T.frequencycode = 'SG')     OR 
                                                 (T.frequencycode = 'OT')
                                                )                             and 
                                               ((T.measurecode <> 'PMC')      and
                                                (T.measurecode <> 'SITE')     and
                                                (T.measurecode <> 'UNIT')
                                               )                         
                                                                              then 0
                                           when ((T.chargetypecode = 'ACS')   and
                                                 ((T.frequencycode = 'SG')    OR 
                                                  (T.frequencycode = 'OT')
                                                 )
                                                )                             then 0
                                           when (T.chargetypecode = 'ACS')    
                                              then
                                                 (case when (T.pricecapflagyear1 = 1)    and
                                                            ((dateadd(yy,1,@LDT_quotecreatedate) >= T.PriceCapStartDateyear1)
                                                                                    and
                                                             (dateadd(yy,1,@LDT_quotecreatedate) <= T.PriceCapEndDateyear1) 
                                                            )                       and
                                                            (T.pricecapbasiscodeyear1='LIST')
                                                          then (T.extyear1chargeamount +
                                                               ((T.extyear1chargeamount * T.PriceCapPercentyear1)/100))
                                                       when (T.pricecapflagyear1 = 1)    and
                                                            ((dateadd(yy,1,@LDT_quotecreatedate) >= T.PriceCapStartDateyear1)
                                                                                    and
                                                             (dateadd(yy,1,@LDT_quotecreatedate) <= T.PriceCapEndDateyear1) 
                                                            )                       and
                                                            (T.pricecapbasiscodeyear1<>'LIST')
                                                          then (T.netextyear1chargeamount +
                                                               ((T.netextyear1chargeamount * T.PriceCapPercentyear1)/100))
                                                       -------------------------------------------------------------
                                                       --- For Orders only. No hardcoding. 
                                                       ---else (T.extyear1chargeamount)
                                                       -------------------------------------------------------------
                                                       -- harcoded to 10% pricecap LIST for Quotes
                                                       else (T.extyear1chargeamount +
                                                               ((T.extyear1chargeamount * 10)/100))
                                                  end
                                                 )
                                         else 0
                                   END
                                   )
  from #TEMP_PropertiesProductsHoldingTable T
  -----------------------------------------------------------------------------------------
  --Pricing: Step 4 : Get extyear3chargeamount,netextyear3chargeamount
  -----------------------------------------------------------------------------------------
  Update T 
     set T.extyear3chargeamount  = (CASE when (T.chargetypecode = 'ILF')    then 0
                                         when (T.chargetypecode = 'ACS')    and 
                                              (T.quantityenabledflag = 1)   and 
                                              ((T.frequencycode = 'SG')     OR 
                                               (T.frequencycode = 'OT')
                                              )                             and
                                              ((T.measurecode <> 'PMC')     and
                                               (T.measurecode <> 'SITE')    and
                                               (T.measurecode <> 'UNIT')
                                              )                         
                                                                            then 0
                                         when ((T.chargetypecode = 'ACS')   and
                                                 ((T.frequencycode = 'SG')  OR 
                                                  (T.frequencycode = 'OT')
                                                 )
                                              )                             then 0
                                         when (T.chargetypecode = 'ACS')    
                                              then
                                                 (case when (T.pricecapflagyear2 = 1)    and
                                                            ((dateadd(yy,2,@LDT_quotecreatedate) >= T.PriceCapStartDateyear2)
                                                                                    and
                                                             (dateadd(yy,2,@LDT_quotecreatedate) <= T.PriceCapEndDateyear2) 
                                                            )                       and
                                                            (T.pricecapbasiscodeyear2='LIST')
                                                          then (T.extyear2chargeamount +
                                                               ((T.extyear2chargeamount * T.PriceCapPercentyear2)/100))
                                                       when (T.pricecapflagyear2 = 1)    and
                                                            ((dateadd(yy,2,@LDT_quotecreatedate) >= T.PriceCapStartDateyear2)
                                                                                    and
                                                             (dateadd(yy,2,@LDT_quotecreatedate) <= T.PriceCapEndDateyear2) 
                                                            )                       and
                                                            (T.pricecapbasiscodeyear2<>'LIST')
                                                          then (T.extyear1chargeamount) 
                                                       -------------------------------------------------------------
                                                       --- For Orders only. No hardcoding. 
                                                       ---else (T.extyear1chargeamount)
                                                       -------------------------------------------------------------                                                       
                                                       -- harcoded to 10% pricecap LIST for Quotes
                                                       else (T.extyear2chargeamount +
                                                               ((T.extyear2chargeamount * 10)/100))
                                                  end
                                                 )
                                         else 0
                                   END
                                   ), 
         T.netextyear3chargeamount = (CASE when (T.chargetypecode = 'ILF')    then 0
                                           when (T.chargetypecode = 'ACS')    and 
                                                (T.quantityenabledflag = 1)   and 
                                                ((T.frequencycode = 'SG')     OR 
                                                 (T.frequencycode = 'OT')
                                                )                             and 
                                               ((T.measurecode <> 'PMC')      and
                                                (T.measurecode <> 'SITE')     and
                                                (T.measurecode <> 'UNIT')
                                               )                         
                                                                              then 0
                                           when ((T.chargetypecode = 'ACS')   and
                                                 ((T.frequencycode = 'SG')    OR 
                                                  (T.frequencycode = 'OT')
                                                 )
                                                )                             then 0 
                                           when (T.chargetypecode = 'ACS')    
                                              then
                                                 (case when (T.pricecapflagyear2 = 1)    and
                                                            ((dateadd(yy,2,@LDT_quotecreatedate) >= T.PriceCapStartDateyear2)
                                                                                    and
                                                             (dateadd(yy,2,@LDT_quotecreatedate) <= T.PriceCapEndDateyear2) 
                                                            )                       and
                                                            (T.pricecapbasiscodeyear2='LIST')
                                                          then (T.extyear2chargeamount +
                                                               ((T.extyear2chargeamount * T.PriceCapPercentyear2)/100))
                                                       when (T.pricecapflagyear2 = 1)    and
                                                            ((dateadd(yy,2,@LDT_quotecreatedate) >= T.PriceCapStartDateyear2)
                                                                                    and
                                                             (dateadd(yy,2,@LDT_quotecreatedate) <= T.PriceCapEndDateyear2) 
                                                            )                       and
                                                            (T.pricecapbasiscodeyear2<>'LIST')
                                                          then (T.netextyear2chargeamount +
                                                               ((T.netextyear2chargeamount * T.PriceCapPercentyear2)/100))
                                                       -------------------------------------------------------------
                                                       --- For Orders only. No hardcoding. 
                                                       ---else (T.extyear1chargeamount)
                                                       -------------------------------------------------------------                                                       
                                                       -- harcoded to 10% pricecap LIST for Quotes
                                                       else (T.extyear2chargeamount +
                                                               ((T.extyear2chargeamount * 10)/100))
                                                  end
                                                 )
                                         else 0
                                   END
                                   )
  from #TEMP_PropertiesProductsHoldingTable T
  -----------------------------------------------------------------------------------------
  --Final Select   
  IF (@IPVC_PropertyAmountAnnualized = 'Y' or @IPVC_PropertyAmountAnnualized = 'YES')
  begin
    select T.quoteid                                            as quoteid,
           T.groupid                                            as groupid,
           T.propertyid                                         as propertyid,
           coalesce((select sum(X.netextyear1chargeamount)
                     from   #TEMP_PropertiesProductsHoldingTable X with (nolock)
                     where  X.quoteid = T.quoteid
                     and    X.groupid = T.groupid
                     and    X.propertyid = T.propertyid
                     and    X.ChargeTypecode = 'ILF'),0)        as AnnualizedILFAmount,
           coalesce((select sum(X.netextyear1chargeamount)
                     from   #TEMP_PropertiesProductsHoldingTable X with (nolock)
                     where  X.quoteid = T.quoteid
                     and    X.groupid = T.groupid
                     and    X.propertyid = T.propertyid
                     and    X.ChargeTypecode = 'ACS'),0)        as AnnualizedAccessAmount
    from #TEMP_PropertiesProductsHoldingTable T with (nolock)
    group by T.quoteid,T.groupid,T.propertyid
  end
  -----------------------------------------------------------------------------------------
  else
  begin  
    -----------------------------------------------------------------------------------------
     select T.quoteid                                          as quoteid,
           T.groupid                                           as groupid,
           T.quoteitemid                                       as quoteitemid,
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
           sum(distinct T.chargeamount)                        as chargeamount,
           -------------------------------------------------------------------
           (case 
               when sum(T.chargeamount) >= 0 
                   then (sum(T.chargeamount)- sum(T.netchargeamount))*(100)/
                        (case when sum(T.chargeamount)=0 then 1
                              else sum(T.chargeamount)
                        end) 
                when sum(T.extchargeamount) > 0 
                   then (sum(T.extchargeamount)- sum(T.netextchargeamount))*(100)/
                        (case when sum(T.extchargeamount)=0 then 1
                              else sum(T.extchargeamount)
                        end)  
                
            end
           )                                                   as discountpercent,
           (case when sum(T.extchargeamount) > 0 
                    then (sum(T.extchargeamount)- sum(T.netextchargeamount)) 
                 when sum(T.chargeamount) >= 0 
                    then (sum(T.chargeamount)- sum(T.netchargeamount))
            end
           )                                                   as discountamount,
           -------------------------------------------------------------------
           (case when sum(T.extSOCchargeamount) > 0 
                   then (sum(T.extSOCchargeamount)- sum(T.netextchargeamount))*(100)/
                        (case when sum(T.extSOCchargeamount)=0 then 1
                              else sum(T.extSOCchargeamount)
                        end)  
                when sum(T.chargeamount) >= 0 
                   then (sum(T.chargeamount)- sum(T.netchargeamount))*(100)/
                        (case when sum(T.chargeamount)=0 then 1
                              else sum(T.chargeamount)
                        end) 
            end
           )                                                   as Totaldiscountpercent,
           (case when sum(T.extSOCchargeamount) > 0 
                    then (sum(T.extSOCchargeamount)- sum(T.netextchargeamount)) 
                 when sum(T.chargeamount) >= 0 
                    then (sum(T.chargeamount)- sum(T.netchargeamount))
            end
           )                                                   as Totaldiscountamount,
           -------------------------------------------------------------------
           sum(T.extchargeamount)                              as extchargeamount,
           sum(T.extSOCchargeamount)                           as extSOCchargeamount,
           ------------------------------------------------------------------------ 
           sum(T.unitofmeasure)                                as unitofmeasure,
           (sum(T.extchargeamount)/
            (case when sum(distinct T.chargeamount)=0 then 1 
                  else sum(distinct T.chargeamount) end)
           )                                                   as multiplier,
           sum(T.extyear1chargeamount)                         as extyear1chargeamount,
           sum(T.extyear2chargeamount)                         as extyear2chargeamount,
           sum(T.extyear3chargeamount)                         as extyear3chargeamount,
           sum(distinct T.netchargeamount)                     as netchargeamount,
           sum(T.netextchargeamount)                           as netextchargeamount,
           sum(T.netextyear1chargeamount)                      as netextyear1chargeamount,
           sum(T.netextyear2chargeamount)                      as netextyear2chargeamount,
           sum(T.netextyear3chargeamount)                      as netextyear3chargeamount
    from #TEMP_PropertiesProductsHoldingTable T with (nolock)
    group by T.quoteid,T.groupid,T.quoteitemid,T.productcode,T.productcategorycode,
             T.familycode,T.chargetypecode,T.measurecode,T.frequencycode 
  end
  -----------------------------------------------------------------------------------------
  --Cleaning up after Final Select
  ----------------------------------------------------------------------------------------- 
  drop table #TEMP_PropertiesProductsHoldingTable
  drop table #temp_priceCapholdingTable
END
GO
