SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=10,@IPI_GroupID=10
exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=2,@IPI_GroupID=3
exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=1,@IPI_GroupID=1
*/
-- Revision History:
-- Author          : Satya B
-- 07/18/2011      : Added new column PrePaidFlag with refence to TFS #295 Instant Invoice Transactions through OMS

CREATE PROCEDURE [quotes].[uspQUOTES_SyncGroupAndQuote] (@IPVC_QuoteID       varchar(50),
                                                      @IPI_GroupID        bigint=NULL
                                                      )
AS
BEGIN   
  set nocount on 
  -----------------------------------------------------------------------------------
  --Declaring Local Variables
  declare @LN_PriorRecordCRC   numeric(30,0)
  declare @LN_AfterRecordCRC   numeric(30,0)  
  declare @LI_Min              int
  declare @LI_Max              int
  declare @LI_GroupID          bigint
  select  @LN_PriorRecordCRC=0,@LN_AfterRecordCRC=0,@LI_Min=1,@LI_Max=0,@LI_GroupID=0
  -----------------------------------------------------------------------------------
  --Declaring Local Variable Tables 
  create table #LT_Quotes_Bundles (SEQ                      int not null identity(1,1),
                                   quoteid                  varchar(50),
                                   groupid                  bigint
                                   )                  

  create table #LT_Quote_QuoteItem
                                (SEQ                      int not null identity(1,1),
                                 quoteid                  varchar(50),
                                 groupid                  bigint,
                                 quoteitemid              bigint,
                                 productcode              varchar(100),                                 
                                 productcategorycode      varchar(50),
                                 familycode               varchar(20)   not null default '',
                                 chargetypecode           varchar(50),
                                 measurecode              varchar(20)   not null default '',
                                 frequencycode            varchar(20)   not null default '',
                                 chargeamount             numeric(30,3) not null default 0,
                                 discountpercent          float         not null default 0.00,
                                 discountamount           numeric(30,2) not null default 0,
                                 totaldiscountpercent     float         not null default 0.00,
                                 totaldiscountamount      numeric(30,2) not null default 0,
                                 extchargeamount          numeric(30,2) not null default 0,
                                 extSOCchargeamount       numeric(30,2) not null default 0,
                                 unitofmeasure            numeric(30,5) not null default 0.00,
                                 multiplier               numeric(30,5) not null default 0.00,
                                 extyear1chargeamount     numeric(30,2) not null default 0,
                                 extyear2chargeamount     numeric(30,2) not null default 0,
                                 extyear3chargeamount     numeric(30,2) not null default 0,
                                 netchargeamount          numeric(30,3) not null default 0,
                                 netextchargeamount       numeric(30,2) not null default 0,
                                 netextyear1chargeamount  numeric(30,2) not null default 0,
                                 netextyear2chargeamount  numeric(30,2) not null default 0,
                                 netextyear3chargeamount  numeric(30,2) not null default 0
                                )
  create table #LT_GroupPropertiesAnnualized (SEQ        int not null identity(1,1),
                                              quoteid    varchar(50),
                                              groupid    bigint,
                                              propertyid varchar(50),
                                              AnnualizedILFAmount    numeric(30,2) not null default 0,
                                              AnnualizedAccessAmount numeric(30,2) not null default 0
                                              ) 
  -------------------------------------------------------------------------------------------------  
  --Get RecordCRC for Quote Record before Update
  -------------------------------------------------------------------- 
  if exists (select Top 1 1 from  QUOTES.DBO.[Quote] Q with (nolock) where Q.Quoteidseq = @IPVC_QuoteID)
  begin 
    select @LN_PriorRecordCRC   = Q.RecordCRC
    from   QUOTES.DBO.[Quote] Q with (nolock) where Q.Quoteidseq = @IPVC_QuoteID
  end  
  else 
  begin
    select @LN_PriorRecordCRC=0
  end
  -------------------------------------------------------------------- 
  if exists (select top 1 1 from QUOTES.DBO.[Group] with (nolock)
             where QuoteIDSeq = @IPVC_QuoteID and IDSeq = @IPI_GroupID 
            )
  and      (@IPI_GroupID is not null and @IPI_GroupID <> 0 and @IPI_GroupID <> '')
  begin 
    insert into #LT_Quotes_Bundles(quoteid,groupid)
    select distinct QuoteIDSeq as quoteid,IDSeq as groupid
    from   QUOTES.DBO.[Group] with (nolock)
    where  QuoteIDSeq = @IPVC_QuoteID and IDSeq = @IPI_GroupID 
  end
  else if exists (select top 1 1 from QUOTES.DBO.[Group] with (nolock)
                  where QuoteIDSeq = @IPVC_QuoteID
                  )
  begin
    insert into #LT_Quotes_Bundles(quoteid,groupid)
    select distinct QuoteIDSeq as quoteid,IDSeq as groupid
    from   QUOTES.DBO.[Group] with (nolock) 
    where  QuoteIDSeq = @IPVC_QuoteID
  end
  --------------------------------------------------------------------------------------------- 
  select @LI_Max = count(*) from #LT_Quotes_Bundles with (nolock)
  while  @LI_Min <= @LI_Max
  begin
    select @LI_GroupID=groupid from #LT_Quotes_Bundles with (nolock) where SEQ = @LI_Min
    insert into #LT_Quote_QuoteItem
                             (quoteid,groupid,quoteitemid,productcode,productcategorycode,
                              familycode,chargetypecode,
                              measurecode,frequencycode,
                              chargeamount,
                              discountpercent,discountamount,totaldiscountpercent,totaldiscountamount,
                              extchargeamount,extSOCchargeamount,unitofmeasure,multiplier,extyear1chargeamount,
                              extyear2chargeamount,extyear3chargeamount,
                              netchargeamount,netextchargeamount,netextyear1chargeamount,
                              netextyear2chargeamount,netextyear3chargeamount)
    exec QUOTES.dbo.uspQUOTES_PriceEngine @IPVC_QuoteID=@IPVC_QuoteID,
                                          @IPI_GroupID =@LI_GroupID,
                                          @IPVC_PropertyAmountAnnualized='NO'    

    insert into #LT_GroupPropertiesAnnualized(quoteid,groupid,propertyid,
                                              AnnualizedILFAmount,AnnualizedAccessAmount)
    exec QUOTES.dbo.uspQUOTES_PriceEngine @IPVC_QuoteID=@IPVC_QuoteID,
                                          @IPI_GroupID =@LI_GroupID,
                                          @IPVC_PropertyAmountAnnualized='YES' 
    select @LI_Min = @LI_Min+1
  end  
  select @LI_Min=1,@LI_Max=0
  ---------------------------------------------------------------------------------------------  
  --Update QuoteItem Table
  update QI
  set    QI.chargeamount               = T.chargeamount,
         --QI.discountpercent            = T.discountpercent,
         QI.discountamount             = T.discountamount,
         QI.totaldiscountpercent       = T.totaldiscountpercent,
         QI.totaldiscountamount        = T.totaldiscountamount,         
         QI.extchargeamount            = T.extchargeamount,
         QI.extSOCchargeamount         = T.extSOCchargeamount,
         QI.unitofmeasure              = T.unitofmeasure,
         QI.multiplier                 = T.multiplier,
         QI.extyear1chargeamount       = T.extyear1chargeamount,
         QI.extyear2chargeamount       = T.extyear2chargeamount,
         QI.extyear3chargeamount       = T.extyear3chargeamount,
         ---QI.netchargeamount         = T.netchargeamount,
         QI.netextchargeamount         = T.netextchargeamount,
         QI.netextyear1chargeamount    = T.netextyear1chargeamount,
         QI.netextyear2chargeamount    = T.netextyear2chargeamount,
         QI.netextyear3chargeamount    = T.netextyear3chargeamount
  from   QUOTES.dbo.QuoteItem QI with (nolock) 
  inner join 
         #LT_Quote_QuoteItem T  with (nolock)
  on     QI.QuoteIDSeq       = T.quoteid
  and    QI.GroupIDSeq       = T.groupid
  and    QI.IDSeq            = T.quoteitemid
  and    QI.productcode      = T.productcode
  and    QI.chargetypecode   = T.chargetypecode
  and    QI.measurecode      = T.measurecode
  and    QI.frequencycode    = T.frequencycode
  ---------------------------------------------------------------------------------------------
  --Update GroupProperties Table
  Update GP
  set    GP.AnnualizedILFAmount    = S.AnnualizedILFAmount,
         GP.AnnualizedAccessAmount = S.AnnualizedAccessAmount
  from   QUOTES.dbo.GroupProperties    GP with (nolock) 
  inner join
         #LT_GroupPropertiesAnnualized S  with (nolock)
  on     GP.QuoteIDSeq = S.quoteid
  and    GP.GroupIDSeq = S.groupid
  and    GP.PropertyIDSeq = S.propertyid
  --------------------------------------------------------------------------------------------
  --Update Group Table from QuoteItem
  Update G
  set    G.ILFExtYearChargeAmount       = S.ILFExtYearChargeAmount,        -->ILFExtYearChargeAmount
         G.ILFDiscountamount            = S.ILFDiscountamount,             -->ILFDiscountamount
         G.ILFDiscountPercent           = S.ILFDiscountPercent,            -->ILFDiscountPercent
         G.ILFNetExtYearChargeAmount    = S.ILFNetExtYearChargeAmount,     -->ILFNetExtYearChargeAmount
         G.AccessExtYear1ChargeAmount   = S.AccessExtYear1ChargeAmount,    -->AccessExtYear1ChargeAmount
         G.AccessExtYear2ChargeAmount   = S.AccessExtYear2ChargeAmount,    -->AccessExtYear2ChargeAmount
         G.AccessExtYear3ChargeAmount   = S.AccessExtYear3ChargeAmount,    -->AccessExtYear3ChargeAmount
         G.AccessDiscountamount         = S.AccessDiscountamount,          -->AccessDiscountamount
         G.AccessDiscountPercent        = s.AccessDiscountPercent,         -->AccessDiscountPercent
         G.AccessNetExtYear1ChargeAmount= S.AccessNetExtYear1ChargeAmount, -->AccessNetExtYear1ChargeAmount
         G.AccessNetExtYear2ChargeAmount= S.AccessNetExtYear2ChargeAmount, -->AccessNetExtYear2ChargeAmount
         G.AccessNetExtYear3ChargeAmount= S.AccessNetExtYear3ChargeAmount  -->AccessNetExtYear3ChargeAmount
  from  Quotes.dbo.[Group] G with (nolock)
  INNER JOIN
        (Select X.GroupIDSeq   as    GroupIDSeq,
                X.QuoteIDSeq   as    QuoteIDSeq,
                sum((case when X.ChargeTypecode  = 'ILF' then X.extyear1chargeamount else 0 end))     as ILFExtYearChargeAmount,
                sum((case when X.ChargeTypecode  = 'ILF' then X.NetExtYear1Chargeamount else 0 end))  as ILFNetExtYearChargeAmount,
                (sum((case when X.ChargeTypecode = 'ILF' then X.extyear1chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ILF' then X.NetExtYear1Chargeamount else 0 end)) 
                )                                                                                     as ILFDiscountamount, 
                (sum((case when X.ChargeTypecode = 'ILF' then X.extyear1chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ILF' then X.NetExtYear1Chargeamount else 0 end)) 
                )*100
                /
                (case when sum((case when X.ChargeTypecode = 'ILF' then X.extyear1chargeamount else 0 end)) = 0 then 1
                      else sum((case when X.ChargeTypecode = 'ILF' then X.extyear1chargeamount else 0 end))
                 end
                )                                                                                     as ILFDiscountPercent,
                sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end))      as AccessExtYear1ChargeAmount,
                sum((case when X.ChargeTypecode = 'ACS' then X.extyear2chargeamount else 0 end))      as AccessExtYear2ChargeAmount, 
                sum((case when X.ChargeTypecode = 'ACS' then X.extyear3chargeamount else 0 end))      as AccessExtYear3ChargeAmount, 
                (sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear1Chargeamount else 0 end)) 
                )                                                                                     as AccessDiscountamount, 

                (sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear1Chargeamount else 0 end)) 
                )*100
                /
                (case when sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end)) = 0 then 1
                      else sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end))
                 end
                )                                                                                      as AccessDiscountPercent,

                sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear1Chargeamount else 0 end))    as AccessNetExtYear1ChargeAmount,
                sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear2Chargeamount else 0 end))    as AccessNetExtYear2ChargeAmount, 
                sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear3Chargeamount else 0 end))    as AccessNetExtYear3ChargeAmount
         from  Quotes.dbo.QuoteItem X with (nolock)
         Where X.QuoteIDSeq = @IPVC_QuoteID
         GROUP BY X.GroupIDSeq,X.QuoteIDSeq 
         ) S
  ON    G.IDSEQ      = S.GroupIDSeq
  AND   G.QuoteIDSeq = S.QuoteIDSeq
  AND   G.QuoteIDSeq = @IPVC_QuoteID  
  AND   S.QuoteIDSeq = @IPVC_QuoteID  
  ---------------------------------------------------------------------------------------------
  --Update Quote Table from QuoteItem
  Update Q
  set    Q.ILFExtYearChargeAmount      = S.ILFExtYearChargeAmount, -->ILFExtYearChargeAmount
         Q.ILFDiscountamount           = S.ILFDiscountamount,      -->ILFDiscountamount
         Q.ILFDiscountPercent          = S.ILFDiscountPercent, -->ILFDiscountPercent
         Q.ILFNetExtYearChargeAmount   = S.ILFNetExtYearChargeAmount, -->ILFNetExtYearChargeAmount
         -----------------------------------------------------------------------------------
         Q.AccessExtYear1ChargeAmount   = S.AccessExtYear1ChargeAmount, -->AccessExtYearChargeAmount
         Q.AccessExtYear2ChargeAmount   = S.AccessExtYear2ChargeAmount, -->AccessExtYear2ChargeAmount
         Q.AccessExtYear3ChargeAmount   = S.AccessExtYear3ChargeAmount, -->AccessExtYear3ChargeAmount
         -----------------------------------------------------------------------------------
         Q.AccessYear1DiscountAmount   = S.AccessYear1DiscountAmount, -->AccessYear1DiscountAmount
         Q.AccessYear1DiscountPercent  = S.AccessYear1DiscountPercent, -->AccessYear1DiscountPercent
         -----------------------------------------------------------------------------------
         Q.AccessYear2DiscountAmount   = S.AccessYear2DiscountAmount, -->AccessYear2DiscountAmount
         Q.AccessYear2DiscountPercent  = S.AccessYear2DiscountPercent, -->AccessYear2DiscountPercent 
         -----------------------------------------------------------------------------------
         Q.AccessYear3DiscountAmount   = S.AccessYear3DiscountAmount, -->AccessYear3DiscountAmount
         Q.AccessYear3DiscountPercent  = S.AccessYear3DiscountPercent, -->AccessYear3DiscountPercent  
         -----------------------------------------------------------------------------------
         Q.AccessNetExtYear1ChargeAmount  = S.AccessNetExtYear1ChargeAmount, -->AccessNetExtYear1ChargeAmount
         Q.AccessNetExtYear2ChargeAmount  = S.AccessNetExtYear2ChargeAmount, -->AccessNetExtYear2ChargeAmount
         Q.AccessNetExtYear3ChargeAmount  = S.AccessNetExtYear3ChargeAmount -->AccessNetExtYear3ChargeAmount
  from  Quotes.dbo.[Quote] Q with (nolock)
  INNER JOIN
        (Select X.QuoteIDSeq   as    QuoteIDSeq,
                sum((case when X.ChargeTypecode  = 'ILF' then X.extyear1chargeamount else 0 end))     as ILFExtYearChargeAmount,
                sum((case when X.ChargeTypecode  = 'ILF' then X.NetExtYear1Chargeamount else 0 end))  as ILFNetExtYearChargeAmount,
                (sum((case when X.ChargeTypecode = 'ILF' then X.extyear1chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ILF' then X.NetExtYear1Chargeamount else 0 end)) 
                )                                                                                     as ILFDiscountamount, 
                (sum((case when X.ChargeTypecode = 'ILF' then X.extyear1chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ILF' then X.NetExtYear1Chargeamount else 0 end)) 
                )*100
                /
                (case when sum((case when X.ChargeTypecode = 'ILF' then X.extyear1chargeamount else 0 end)) = 0 then 1
                      else sum((case when X.ChargeTypecode = 'ILF' then X.extyear1chargeamount else 0 end))
                 end
                )                                                                                     as ILFDiscountPercent,
                -----------------------------------------------------------------------------------------------------------------
                sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end))      as AccessExtYear1ChargeAmount,
                sum((case when X.ChargeTypecode = 'ACS' then X.extyear2chargeamount else 0 end))      as AccessExtYear2ChargeAmount, 
                sum((case when X.ChargeTypecode = 'ACS' then X.extyear3chargeamount else 0 end))      as AccessExtYear3ChargeAmount, 
                -----------------------------------------------------------------------------------------------------------------
                (sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear1Chargeamount else 0 end)) 
                )                                                                                     as AccessYear1DiscountAmount, 

                (sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear1Chargeamount else 0 end)) 
                )*100
                /
                (case when sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end)) = 0 then 1
                      else sum((case when X.ChargeTypecode = 'ACS' then X.extyear1chargeamount else 0 end))
                 end
                )                                                                                      as AccessYear1DiscountPercent,
                (sum((case when X.ChargeTypecode = 'ACS' then X.extyear2chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.NetExtyear2Chargeamount else 0 end)) 
                )                                                                                     as Accessyear2DiscountAmount, 

                (sum((case when X.ChargeTypecode = 'ACS' then X.extyear2chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.NetExtyear2Chargeamount else 0 end)) 
                )*100
                /
                (case when sum((case when X.ChargeTypecode = 'ACS' then X.extyear2chargeamount else 0 end)) = 0 then 1
                      else sum((case when X.ChargeTypecode = 'ACS' then X.extyear2chargeamount else 0 end))
                 end
                )                                                                                      as Accessyear2DiscountPercent,
                (sum((case when X.ChargeTypecode = 'ACS' then X.extyear3chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.NetExtyear3Chargeamount else 0 end)) 
                )                                                                                     as Accessyear3DiscountAmount, 

                (sum((case when X.ChargeTypecode = 'ACS' then X.extyear3chargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.NetExtyear3Chargeamount else 0 end)) 
                )*100
                /
                (case when sum((case when X.ChargeTypecode = 'ACS' then X.extyear3chargeamount else 0 end)) = 0 then 1
                      else sum((case when X.ChargeTypecode = 'ACS' then X.extyear3chargeamount else 0 end))
                 end
                )                                                                                      as Accessyear3DiscountPercent,
                -----------------------------------------------------------------------------------------------------------------  
                sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear1Chargeamount else 0 end))    as AccessNetExtYear1ChargeAmount,
                sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear2Chargeamount else 0 end))    as AccessNetExtYear2ChargeAmount, 
                sum((case when X.ChargeTypecode = 'ACS' then X.NetExtYear3Chargeamount else 0 end))    as AccessNetExtYear3ChargeAmount
                -----------------------------------------------------------------------------------------------------------------  
         from  Quotes.dbo.QuoteItem X with (nolock)
         Where X.QuoteIDSeq = @IPVC_QuoteID
         GROUP BY X.QuoteIDSeq 
         ) S
  ON    Q.QuoteIDSeq = S.QuoteIDSeq
  AND   Q.QuoteIDSeq = @IPVC_QuoteID  
  AND   S.QuoteIDSeq = @IPVC_QuoteID    
  -------------------------------------------------------------------------------------------------  
  --Get RecordCRC for Quote Record After Update
  -------------------------------------------------------------------- 
  if exists (select Top 1 1 from  QUOTES.DBO.[Quote] Q with (nolock) where Q.QuoteIDSeq = @IPVC_QuoteID)
  begin 
    select @LN_AfterRecordCRC = Q.RecordCRC
    from  QUOTES.DBO.[Quote] Q with (nolock) where Q.QuoteIDSeq = @IPVC_QuoteID
  end  
  else 
  begin
    select @LN_AfterRecordCRC=0
  end
  -------------------------------------------------------------------------------------------------
  --Recording the Quote Update activity to Quotes.dbo.QuoteLog Table
  ---- when @LN_PriorRecordCRC and @LN_AfterRecordCRC differ
  --------------------------------------------------------------------  
  if @LN_PriorRecordCRC <> @LN_AfterRecordCRC
  begin
    insert into Quotes.dbo.QuoteLog(QuoteIDSeq,CustomerIDSeq,CompanyName,Sites,Units,beds,
                                    OverrideFlag,OverrideSites,OverrideUnits,
                                    ILFExtYearChargeAmount,ILFDiscountPercent,ILFDiscountAmount,ILFNetExtYearChargeAmount,
                                    AccessExtYear1ChargeAmount,AccessExtYear2ChargeAmount,AccessExtYear3ChargeAmount,
                                    AccessYear1DiscountPercent,AccessYear1DiscountAmount,
                                    AccessYear2DiscountPercent,AccessYear2DiscountAmount,
                                    AccessYear3DiscountPercent,AccessYear3DiscountAmount,
                                    AccessNetExtYear1ChargeAmount,AccessNetExtYear2ChargeAmount,AccessNetExtYear3ChargeAmount,                                    
                                    QuoteStatusCode,QuoteTypeCode,CreatedBy,ModifiedBy,CreatedByDisplayName,ModifiedByDisplayName,
                                    ExpirationDate,CreateDate,ModifiedDate,SQLActivityType,
                                    DealDeskReferenceLevel,DealDeskCurrentLevel,DealDeskStatusCode,DealDeskQueuedDate,DealDeskQueuedByIDSeq,
                                    DealDeskDecisionMadeBy,DealDeskNote,DealDeskResolvedByIDSeq,DealDeskResolvedDate,
                                    RollbackReasonCode,RollBackByIDseq,RollBackDate,
                                    PrePaidFlag,RequestedBy,ExternalQuoteIIFlag
                                    ) 
    select Q.QuoteIDSeq as QuoteIDSeq,Q.CustomerIDSeq,Q.CompanyName,Q.Sites,Q.Units,Q.beds,
           Q.OverrideFlag,Q.OverrideSites,Q.OverrideUnits,
           Q.ILFExtYearChargeAmount,Q.ILFDiscountPercent,Q.ILFDiscountAmount,Q.ILFNetExtYearChargeAmount,
           Q.AccessExtYear1ChargeAmount,Q.AccessExtYear2ChargeAmount,Q.AccessExtYear3ChargeAmount,
           Q.AccessYear1DiscountPercent,Q.AccessYear1DiscountAmount,
           Q.AccessYear2DiscountPercent,Q.AccessYear2DiscountAmount,
           Q.AccessYear3DiscountPercent,Q.AccessYear3DiscountAmount,
           Q.AccessNetExtYear1ChargeAmount,Q.AccessNetExtYear2ChargeAmount,Q.AccessNetExtYear3ChargeAmount,           
           Q.QuoteStatusCode,Q.QuoteTypeCode,Q.CreatedBy,Q.ModifiedBy,Q.CreatedByDisplayName,Q.ModifiedByDisplayName,
           Q.ExpirationDate,Q.CreateDate,getdate() as ModifiedDate,'U' as SQLActivityType,
           Q.DealDeskReferenceLevel,Q.DealDeskCurrentLevel,Q.DealDeskStatusCode,Q.DealDeskQueuedDate,Q.DealDeskQueuedByIDSeq,
           Q.DealDeskDecisionMadeBy,Q.DealDeskNote,Q.DealDeskResolvedByIDSeq,Q.DealDeskResolvedDate,Q.RollbackReasonCode,Q.RollBackByIDseq,Q.RollBackDate,
           Q.PrePaidFlag,Q.RequestedBy,Q.ExternalQuoteIIFlag 
    from Quotes.dbo.Quote Q with (nolock) 
    where Q.QuoteIDSeq = @IPVC_QuoteID   
  end
  select @LN_PriorRecordCRC=0,@LN_AfterRecordCRC=0
  ------------------------------------------------------------------------------------------------- 
  ---Final Clean up
  drop table #LT_Quotes_Bundles
  drop table #LT_Quote_QuoteItem
  drop table #LT_GroupPropertiesAnnualized
  ------------------------------------------------------------------------------------------------- 
END
GO
