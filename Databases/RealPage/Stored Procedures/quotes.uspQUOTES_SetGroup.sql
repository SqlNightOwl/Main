SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [quotes].[uspQUOTES_SetGroup] (@IPT_SetGroupXML  TEXT = NULL                                                 
                                            )
AS
BEGIN --: Main BEGIN
  set nocount on; 
  set XACT_ABORT on; -- set XACT_ABORT on will render the transaction uncommittable
                     -- when the constraint violation occurs.
  -----------------------------------------------------------------------------------
  --Declaring Local Variables
  -----------------------------------------------------------------------------------
  declare @LI_Min                         int
  declare @LI_Max                         int  
  declare @LVC_companyid                  varchar(50),
          @LVC_quoteid                    varchar(50),
          @LI_groupid                     int,
          @LVC_GroupCounter               varchar(50),
          @LVC_CustomGroupName            varchar(200),
          @LVC_Description                varchar(255),
          @LI_sites                       int,
          @LI_units                       int,
          @LI_ppupercentage               int,
          @LI_beds                        int,
          @LVC_productcode                varchar(50),  
          @LN_priceversion                numeric(18,0),
          @LVC_frequencycode              varchar(6),
          @LVC_measurecode                varchar(6), 
          @LVC_ilffrequencycode           varchar(6),
          @LVC_ilfmeasurecode             varchar(6), 
          @LVC_discallocationcode         varchar(6),
          @LVC_internalgroupid            varchar(100),
          @LI_isselected                  int,
          @LI_custombundlenameenabledflag int,
          @LI_autofulfillilfflag          int, 
          @LI_autofulfillacsancflag       int
  declare @LVC_ErrorCodeSection           varchar(500)

  select @LI_sites=0,@LI_units=0,@LI_ppupercentage=100,@LI_Min=0,@LI_Max=0,@LI_isselected=1
  -----------------------------------------------------------------------------------
  --Declaring Local Table Variable
  -----------------------------------------------------------------------------------  
  create table #LT_groupmaster    (SEQ                      int not null identity(1,1),
                                   companyid                varchar(11),
                                   quoteid                  varchar(50),
                                   groupid                  bigint,
                                   groupname                varchar(60),
                                   description              varchar(255),                                                                     
                                   discallocationcode       char(3) not null       default 'SPR',                                   
                                   sites                    int not null           default  0,
                                   units                    int not null           default  0, 
                                   beds                     int not null           default  0,   
                                   ppupercentage            int not null           default  100,                               
                                   ilfdiscountpercent       float not null         default 0.00,
                                   ilfdiscountamount        money not null         default 0,
                                   accessdiscountpercent    float not null         default 0.00,
                                   accessdiscountamount     money not null         default 0,                                   
                                   showdetailpriceflag      bit not null           default 0,                                   
                                   allowproductcancelflag   bit          not null  default 1,
                                   custombundlenameenabledflag bit       not null  default 0,
                                   autofulfillilfflag       int          not null  default 1,
                                   autofulfillacsancflag    int          not null  default 0,                                    
                                   grouptype                varchar(70)  not null  default '',
                                   internalgroupid          varchar(100) not null  default ''
                                  )

  create table  #LT_quoteitem     (SEQ                      int not null identity(1,1),
                                   quoteid                  varchar(50),
                                   groupid                  bigint,
                                   productcode              varchar(50),                                                                      
                                   frequencycode            varchar(6),
                                   familycode               varchar(6)   NULL,                                   
                                   allowproductcancelflag   bit          not null  default 1, 
                                   measurecode              varchar(6),    
                                   ilffrequencycode         varchar(6),
                                   ilfmeasurecode           varchar(6),                    
                                   priceversion             numeric(18,0) null,
                                   publicationyear          varchar(100)  null,
                                   publicationquarter       varchar(100)  null, 
                                   ilfminunits              int           not null default 0,
                                   ilfmaxunits              int           not null default 0, 
                                   acsminunits              int           not null default 0,
                                   acsmaxunits              int           not null default 0,                        
                                   quantity                 decimal(18,3) not null default 1,                                   
                                   listpriceilf             numeric(30,2) not null default 0,
                                   listpriceaccess          numeric(30,2) not null default 0,
                                   ilfdiscountpercent       float not null default 0,
                                   accessdiscountpercent    float not null default 0,                                   
                                   ilfnetprice              numeric(30,2) not null default 0,
                                   accessnetprice           numeric(30,2) not null default 0,
                                   ilfcapmaxunitsflag       bit   not null default ((0)),
                                   acscapmaxunitsflag       bit   not null default ((0)),
                                   acsdollarminimum         money         not null default 0,
                                   ilfdollarminimum         money         not null default 0,
                                   acsdollarminimumenabledflag bit        not null default 0,
                                   ilfdollarminimumenabledflag bit        not null default 0,

                                   acsdollarmaximum         money         not null default 0,
                                   ilfdollarmaximum         money         not null default 0,
                                   acsdollarmaximumenabledflag bit        not null default 0,
                                   ilfdollarmaximumenabledflag bit        not null default 0,
    
                                   creditcardpercentageenabledflag   int           not null DEFAULT 0,
                                   credtcardpricingpercentage        numeric(30,3) not null DEFAULT 0.00,
                                  
                                   excludeforbookingsflag              bit           not null Default 0,
                                   crossfiremaximumallowablecallvolume bigint        not null Default 0                                                            
                                  )   
                                   
  CREATE TABLE #TEMPQuoteItemSnapShot
                           (QuoteIDSeq                 varchar(22)    NOT NULL,
                            GroupIDSeq                 bigint         NOT NULL,
                            ProductCode                varchar(30)    NOT NULL,
                            chargeTypeCode             varchar(3)     NOT NULL,
                            FrequencyCode              varchar(6)     NOT NULL,
                            MeasureCode                varchar(6)     NOT NULL,
                            FamilyCode                 varchar(6)     NULL,
                            publicationyear            varchar(100)   NULL,
                            publicationquarter         varchar(100)   NULL,                                                        
                            AllowProductCancelFlag     int            NOT NULL   DEFAULT ((1)),
                            PriceVersion               numeric(18, 0) NULL,
                            Sites                      int   NOT NULL  DEFAULT ((0)),
                            Units                      int   NOT NULL  DEFAULT ((0)),
                            Beds                       int   NOT NULL  DEFAULT ((0)),
                            PPUPercentage              int   NOT NULL  DEFAULT ((100)),
                            minunits                   int         not null default 0,
                            maxunits                   int         not null default 0,
                            Quantity                   decimal(18,3) NOT NULL  DEFAULT ((1)),
                            Multiplier                 numeric(30,5)    NOT NULL   DEFAULT ((1)),                            
                            chargeAmount               money NOT NULL   DEFAULT ((0)),
                            ExtchargeAmount            money NOT NULL   DEFAULT ((0)),
                            ExtYear1chargeAmount       money NOT NULL   DEFAULT ((0)),
                            ExtYear2chargeAmount       money NOT NULL   DEFAULT ((0)),
                            ExtYear3chargeAmount       money NOT NULL   DEFAULT ((0)),
                            DiscountPercent            float NOT NULL   DEFAULT ((0)),
                            DiscountAmount             money NOT NULL   DEFAULT ((0)),
                            TotalDiscountPercent       float NOT NULL   DEFAULT ((0)),
                            TotalDiscountAmount        money NOT NULL   DEFAULT ((0)),
                            NetchargeAmount            money NOT NULL   DEFAULT ((0)),
                            NetExtchargeAmount         money NOT NULL   DEFAULT ((0)),
                            NetExtYear1chargeAmount    money NOT NULL   DEFAULT ((0)),
                            NetExtYear2chargeAmount    money NOT NULL   DEFAULT ((0)),
                            NetExtYear3chargeAmount    money NOT NULL   DEFAULT ((0)),
                            capmaxunitsflag            int   NOT NULL   DEFAULT ((0)),
                            dollarminimum              money not null default ((0)),                            
                            dollarmaximum              money not null default ((0)),                            
                            credtcardpricingpercentage numeric(30,3) not null DEFAULT 0.000,
                            excludeforbookingsflag              bit           not null Default 0,
                            crossfiremaximumallowablecallvolume bigint        null Default 0                                                  
                           )
  -----------------------------------------------------------------------------------
  declare @idoc  int
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPT_SetGroupXML
  -----------------------------------------------------------------------------------  
  --OPENXML to read XML and Insert Data into #LT_groupmaster
  ----------------------------------------------------------------------------------- 
  begin TRY
    insert into #LT_groupmaster(companyid,quoteid,groupid,groupname,description,sites,units,beds,ppupercentage,
                                discallocationcode,ilfdiscountpercent,ilfdiscountamount,accessdiscountpercent,
                                accessdiscountamount,showdetailpriceflag,
                                allowproductcancelflag,custombundlenameenabledflag,
                                autofulfillilfflag,autofulfillacsancflag,
                                grouptype,internalgroupid)
    select A.companyid,A.quoteid,A.groupid,A.groupname,A.description,A.sites,A.units,A.beds,A.ppupercentage,
           A.discallocationcode,A.ilfdiscountpercent,A.ilfdiscountamount,A.accessdiscountpercent,
           A.accessdiscountamount,A.showdetailpriceflag,
           A.allowproductcancelflag,A.custombundlenameenabledflag,
           A.autofulfillilfflag,A.autofulfillacsancflag,
           A.grouptype,A.internalgroupid
    from (select coalesce(ltrim(rtrim(companyid)),'0')           as companyid,
                 coalesce(ltrim(rtrim(quoteid)),'0')             as quoteid,
                 coalesce(ltrim(rtrim(groupid)),0)               as groupid,
                 coalesce(ltrim(rtrim(groupname)),'')            as groupname,                 
                 coalesce(ltrim(rtrim(description)),'')          as description,                 
                 coalesce(convert(int,sites),0)                  as sites, 
                 coalesce(convert(int,units),0)                  as units,
                 coalesce(convert(int,beds),0)                   as beds,
                 coalesce(convert(int,ppupercentage),0)          as ppupercentage,
                 ltrim(rtrim(discallocationcode))                as discallocationcode,
                 coalesce(ilfdiscountpercent,0.00)               as ilfdiscountpercent,
                 coalesce(convert(money,ilfdiscountamount),0)    as ilfdiscountamount,
                 coalesce(accessdiscountpercent,0.00)            as accessdiscountpercent,
                 coalesce(convert(money,accessdiscountamount),0) as accessdiscountamount,                 
                 coalesce(showdetailpriceflag,0)                 as showdetailpriceflag,                 
                 coalesce(allowproductcancelflag,1)              as allowproductcancelflag,
                 coalesce(custombundlenameenabledflag,0)         as custombundlenameenabledflag,
                 coalesce(autofulfillilfflag,1)                  as autofulfillilfflag,
                 coalesce(autofulfillacsancflag,0)               as autofulfillacsancflag,
                 coalesce(grouptype,'')                          as grouptype,
                 ltrim(rtrim(internalgroupid))                   as internalgroupid
          from OPENXML (@idoc,'//groupmaster/row',1) 
          with (companyid                varchar(11),
                quoteid                  varchar(50),
                groupid                  bigint,
                groupname                varchar(60),
                description              varchar(255),                
                sites                    money,
                units                    money,
                beds                     money,
                ppupercentage            money,
                discallocationcode       varchar(3),
                ilfdiscountpercent       float,
                ilfdiscountamount        numeric(30,5),
                accessdiscountpercent    float,
                accessdiscountamount     numeric(30,5),                
                showdetailpriceflag         bit,                
                allowproductcancelflag      bit, 
                custombundlenameenabledflag bit,
                autofulfillilfflag          int,
                autofulfillacsancflag       int,
                grouptype                   varchar(70),
                internalgroupid             varchar(100)
                )
          ) A
  end TRY
  begin CATCH
    select @LVC_ErrorCodeSection = '//groupmaster/row XML ReadSection'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end
    return
  end CATCH;  
  ------------------------------------------------------------------
  ---select * from #LT_groupmaster --:Validation
  if (select count(*) from #LT_groupmaster) > 0
  begin
    ----------------------------------------------------------------------------------------
    --Insert / Update QUOTES.DBO.Group
    ----------------------------------------------------------------------------------------
    select @LI_Min = Min(SEQ),@LI_Max = Max(SEQ) from #LT_groupmaster
    while @LI_Min <= @LI_Max
    begin --: begin while
      select @LVC_companyid = companyid,@LVC_quoteid=quoteid,@LI_groupid=groupid,
             @LI_sites=sites,@LI_units=units,@LI_beds=beds,@LI_ppupercentage=ppupercentage,
             @LVC_discallocationcode = discallocationcode,
             @LVC_Description = description,
             @LI_custombundlenameenabledflag = custombundlenameenabledflag,
             @LI_autofulfillilfflag    = autofulfillilfflag,
             @LI_autofulfillacsancflag = autofulfillacsancflag,
             @LVC_internalgroupid = internalgroupid
      from #LT_groupmaster where SEQ = @LI_Min

      if (@LI_groupid = 0 and  @LVC_quoteid > '0')
         --and (@LVC_internalgroupid is not null and @LVC_internalgroupid <> '')
         and not exists (select Top 1 1 from QUOTES.DBO.[Group]  with (nolock) 
                         where  QuoteIDSeq = @LVC_quoteid  and IDSeq = @LI_groupid)  
         and exists (select Top 1 1 from QUOTES.DBO.Quote  with (nolock) where  QuoteIDSeq = @LVC_quoteid)
      begin
        begin TRY
          if (select top 1 groupname from #LT_groupmaster where SEQ = @LI_Min) <> ''
          begin
            select @LVC_CustomGroupName=groupname from #LT_groupmaster where SEQ = @LI_Min
          end
          else
          begin
            select @LVC_GroupCounter = coalesce(max((case when charindex('Custom Bundle',name)=0 
                                                             then '0'
                                                          else ltrim(rtrim(replace(Name,'Custom Bundle','')))
                                                     end)
                                                    ),0)+1
            from   QUOTES.DBO.[Group]  with (nolock) where QuoteIDSeq = @LVC_quoteid
            select @LVC_CustomGroupName = 'Custom Bundle ' + @LVC_GroupCounter
          end
          BEGIN TRANSACTION;  
          ------------------------------
          --- New Group : Insert
          ------------------------------ 
          insert into QUOTES.DBO.[Group](quoteidseq,discallocationcode,
                                name,Description,CustomerIDSeq,sites,units,beds,
                                ilfdiscountpercent,ilfdiscountamount,accessdiscountpercent,
                                accessdiscountamount,grouptype,showdetailpriceflag,
                                allowproductcancelflag,custombundlenameenabledflag,
                                autofulfillilfflag,autofulfillacsancflag)
          select @LVC_quoteid,discallocationcode,
                 @LVC_CustomGroupName,@LVC_Description,@LVC_companyid,sites,units,beds,
                 ilfdiscountpercent,ilfdiscountamount,
                 accessdiscountpercent,accessdiscountamount,
                 grouptype,showdetailpriceflag,
                 allowproductcancelflag,@LI_custombundlenameenabledflag,
                 @LI_autofulfillilfflag,@LI_autofulfillacsancflag
          from #LT_groupmaster where SEQ = @LI_Min
           
          select @LI_groupid=SCOPE_IDENTITY()          
          COMMIT TRANSACTION;
        end TRY
        begin CATCH 
          select @LVC_ErrorCodeSection = 'Group Insert Section' 
          Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection               
          -- XACT_STATE:
             -- If 1, the transaction is committable.
             -- If -1, the transaction is uncommittable and should be rolled back.
             -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
          if (XACT_STATE()) = -1
          begin
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
          end
          else if (XACT_STATE()) = 1
          begin
            IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
          end          
        end CATCH
      end --:Group Insert end
      else
      begin --:Group Update begin
        begin TRY                             
          ------------------------------
          --- Existing Group : Update
          ------------------------------          
          Update  C
          set     C.DiscAllocationCode       =(select top 1 DiscAllocationCode    from #LT_groupmaster where SEQ = @LI_Min),
                  C.[Name]                   =(select top 1 (case when groupname='' 
                                                                   then 'Custom Bundle ' + convert(varchar(50),@LI_groupid) 
                                                                 else groupname
                                                            end)
                                               from #LT_groupmaster where SEQ = @LI_Min), 
                  C.[Description]            = @LVC_Description , 
                  C.CustomerIDSeq            = @LVC_companyid,                  
                  C.Sites                    = @LI_sites,
                  C.Units                    = @LI_units,
                  C.beds                     = @LI_beds,
                  C.PPUPercentage            = @LI_ppupercentage,
                  C.ILFDiscountPercent       =(select top 1 ilfdiscountpercent        from #LT_groupmaster where SEQ = @LI_Min), 
                  C.ILFDiscountAmount        =(select top 1 ilfdiscountamount         from #LT_groupmaster where SEQ = @LI_Min), 
                  C.AccessDiscountPercent    =(select top 1 accessdiscountpercent     from #LT_groupmaster where SEQ = @LI_Min), 
                  C.AccessDiscountAmount     =(select top 1 accessdiscountamount      from #LT_groupmaster where SEQ = @LI_Min), 
                  C.grouptype                =(select top 1 grouptype                 from #LT_groupmaster where SEQ = @LI_Min), 
                  C.ShowDetailPriceFlag      =(select top 1 showdetailpriceflag       from #LT_groupmaster where SEQ = @LI_Min),
                  C.allowproductcancelflag   =(select top 1 allowproductcancelflag    from #LT_groupmaster where SEQ = @LI_Min),
                  C.custombundlenameenabledflag=@LI_custombundlenameenabledflag,
                  C.autofulfillilfflag       =@LI_autofulfillilfflag,
                  C.autofulfillacsancflag    =@LI_autofulfillacsancflag
          from    QUOTES.DBO.[Group] C  with (nolock)
          where   C.quoteidseq = @LVC_quoteid 
          and     C.IDSeq      = @LI_groupid                    
        end TRY
        begin CATCH
          select @LVC_ErrorCodeSection = 'Group Update Section' 
          Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection            
        end CATCH
      end --:Group Update end
      -------------------------------------------------------------
      ---Final Update to realign GroupNames for the current Quote
      -------------------------------------------------------------
      if exists (select Top 1 1 
                 from   QUOTES.DBO.[Group]  with (nolock) 
                 where  QuoteIDSeq = @LVC_quoteid  
                 and    charindex('Custom Bundle',name)=1
                ) 
      begin
        begin TRY 
          Update G
          set    G.Name        = S.NewName
          from   QUOTES.DBO.[Group] G  with (nolock)
          Inner Join
                 (select T2.QuoteIDSeq,
                         T2.IDSeq as GroupID,
                         T2.Name  as OldName,
         	         'Custom Bundle ' + 
                         convert(varchar(50),(select count(*) 
                                              from QUOTES.DBO.[Group] T1 with (nolock)  
                                              where T1.QuoteIDSeq = T2.QuoteIDSeq
                                              and   T1.QuoteIDSeq = @LVC_quoteid
                                              and   T2.QuoteIDSeq = @LVC_quoteid
                                              and   T1.IDSeq     <= T2.IDSeq
                                              and   charindex('Custom Bundle',T1.name)=1 
                                              and   T1.CustomBundleNameEnabledFlag    =0
                                             )
                                 )        as NewName
                  from  QUOTES.DBO.[Group] T2 with (nolock) 
                  where QuoteIDSeq = @LVC_quoteid
                  and   charindex('Custom Bundle',T2.name)=1
                  and   T2.CustomBundleNameEnabledFlag    =0
                  ) S
          On    G.QuoteIDSeq = S.QuoteIDSeq
          and   G.IDSeq      = S.GroupID
          and   G.Name       = S.OldName
          and   G.QuoteIDSeq = @LVC_quoteid
          where G.QuoteIDSeq = @LVC_quoteid
        end TRY
        begin CATCH
          select @LVC_ErrorCodeSection = 'Group Update To realign GroupNames Section'
          Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection            
        end CATCH
      end
      -------------------------------------------------------------
      exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@LVC_quoteid,@IPI_GroupID=@LI_groupid
      select @LI_Min = @LI_Min + 1
    end --: end while
  end
  -----------------------------------------------------------------------------------
  --Reinitializing Variable for further Use below
  select @LI_Min=0,@LI_Max=0
  -----------------------------------------------------------------------------------  
  -----------------------------------------------------------------------------------
  --OPENXML to read XML and Insert Data into #LT_quoteitem
  ----------------------------------------------------------------------------------- 
  begin TRY
    insert into #LT_quoteitem(quoteid,groupid,productcode,frequencycode,measurecode,ilffrequencycode,ilfmeasurecode,
                              familycode,
                              allowproductcancelflag, 
                              priceversion,publicationyear,publicationquarter,
                              ilfminunits,ilfmaxunits,acsminunits,acsmaxunits,
                              quantity,
                              listpriceilf,listpriceaccess,
                              ilfdiscountpercent,accessdiscountpercent,
                              ilfnetprice,accessnetprice,
                              ilfcapmaxunitsflag,acscapmaxunitsflag,
                              acsdollarminimum,ilfdollarminimum,acsdollarminimumenabledflag,ilfdollarminimumenabledflag,
                              acsdollarmaximum,ilfdollarmaximum,acsdollarmaximumenabledflag,ilfdollarmaximumenabledflag,
                              creditcardpercentageenabledflag,credtcardpricingpercentage,
                              excludeforbookingsflag,crossfiremaximumallowablecallvolume
                              )
    select A.quoteid,A.groupid,A.productcode,A.frequencycode,A.measurecode,ilffrequencycode,ilfmeasurecode,
           A.familycode,
           A.allowproductcancelflag,
           A.priceversion,A.publicationyear,A.publicationquarter,
           A.ilfminunits,A.ilfmaxunits,A.acsminunits,A.acsmaxunits,
           (case when A.quantity > 0 then A.quantity else 1 end) as quantity,
           A.listpriceilf,A.listpriceaccess,
           A.ilfdiscountpercent,A.accessdiscountpercent,
           A.ilfnetprice,A.accessnetprice,
           A.ilfcapmaxunitsflag,A.acscapmaxunitsflag,
           A.acsdollarminimum,A.ilfdollarminimum,A.acsdollarminimumenabledflag,A.ilfdollarminimumenabledflag,
           A.acsdollarmaximum,A.ilfdollarmaximum,A.acsdollarmaximumenabledflag,A.ilfdollarmaximumenabledflag,
           A.creditcardpercentageenabledflag,A.credtcardpricingpercentage,
           A.excludeforbookingsflag,A.crossfiremaximumallowablecallvolume
     from (select coalesce(ltrim(rtrim(quoteid)),'0')                   as quoteid,
                  coalesce(ltrim(rtrim(groupid)),0)                     as groupid,
                  ltrim(rtrim(productcode))                             as productcode,
                  ltrim(rtrim(frequencycode))                           as frequencycode,
                  ltrim(rtrim(measurecode))                             as measurecode,
                  ltrim(rtrim(ilffrequencycode))                        as ilffrequencycode,
                  ltrim(rtrim(ilfmeasurecode))                          as ilfmeasurecode, 
                  ltrim(rtrim(familycode))                              as familycode,                  
                  coalesce(allowproductcancelflag,1)                    as allowproductcancelflag,
                  coalesce(priceversion,0)                              as priceversion,
                  coalesce(ltrim(rtrim(publicationyear)),'')            as publicationyear,
                  coalesce(ltrim(rtrim(publicationquarter)),'')         as publicationquarter,
                  coalesce(ilfminunits,0)                               as ilfminunits,
                  coalesce(ilfmaxunits,0)                               as ilfmaxunits, 
                  coalesce(acsminunits,0)                               as acsminunits,
                  coalesce(acsmaxunits,0)                               as acsmaxunits,                   
                  coalesce(quantity,1)                                  as quantity,                  
                  coalesce(convert(numeric(30,2),listpriceilf),0.00)    as listpriceilf,
                  coalesce(convert(numeric(30,2),listpriceaccess),0.00) as listpriceaccess,
                  coalesce(ilfdiscountpercent,0.00)                     as ilfdiscountpercent,
                  coalesce(accessdiscountpercent,0.00)                  as accessdiscountpercent,
                  coalesce(convert(numeric(30,2),ilfnetprice),0.00)     as ilfnetprice,
                  coalesce(convert(numeric(30,2),accessnetprice),0.00)  as accessnetprice,
                  coalesce(ilfcapmaxunitsflag,0)                        as ilfcapmaxunitsflag,               
                  coalesce(acscapmaxunitsflag,0)                        as acscapmaxunitsflag,
                  coalesce(acsdollarminimum,0.00)                       as acsdollarminimum,
                  coalesce(ilfdollarminimum,0.00)                       as ilfdollarminimum,
                  coalesce(acsdollarminimumenabledflag,0)               as acsdollarminimumenabledflag,
                  coalesce(ilfdollarminimumenabledflag,0)               as ilfdollarminimumenabledflag,
                  coalesce(acsdollarmaximum,0.00)                       as acsdollarmaximum,
                  coalesce(ilfdollarmaximum,0.00)                       as ilfdollarmaximum,
                  coalesce(acsdollarmaximumenabledflag,0)               as acsdollarmaximumenabledflag,
                  coalesce(ilfdollarmaximumenabledflag,0)               as ilfdollarmaximumenabledflag,
                  coalesce(creditcardpercentageenabledflag,0)           as creditcardpercentageenabledflag,
                  coalesce(credtcardpricingpercentage,0)                as credtcardpricingpercentage,
                  coalesce(excludeforbookingsflag,0)                    as excludeforbookingsflag,
                  coalesce(crossfiremaximumallowablecallvolume,0)       as crossfiremaximumallowablecallvolume
          from OPENXML (@idoc,'//familyproducts/row[@isselected = "1"]',1) 
          with (quoteid                 varchar(50),
                groupid                 bigint,
                productcode             varchar(50),
                frequencycode           varchar(6),
                measurecode             varchar(6),
                ilffrequencycode        varchar(6),
                ilfmeasurecode          varchar(6),
                familycode              varchar(6),                
                allowproductcancelflag  bit, 
                priceversion            numeric(18,0),
                publicationyear         varchar(100),
                publicationquarter      varchar(100), 
                ilfminunits             int,
                ilfmaxunits             int,  
                acsminunits             int,
                acsmaxunits             int,                
                quantity                numeric(18,3),
                listpriceilf            numeric(30,5),
                listpriceaccess         numeric(30,5),
                ilfdiscountpercent      float,
                accessdiscountpercent   float,                          
                ilfnetprice             numeric(30,5),
                accessnetprice          numeric(30,5),
                ilfcapmaxunitsflag      bit,
                acscapmaxunitsflag      bit,
                acsdollarminimum         money,
                ilfdollarminimum         money,
                acsdollarminimumenabledflag bit,
                ilfdollarminimumenabledflag bit,
                acsdollarmaximum         money,
                ilfdollarmaximum         money,
                acsdollarmaximumenabledflag bit,
                ilfdollarmaximumenabledflag bit,
                creditcardpercentageenabledflag   bit,
                credtcardpricingpercentage        numeric(30,3),
                excludeforbookingsflag      bit,
                crossfiremaximumallowablecallvolume bigint        
                )
          ) A  
  end TRY
  begin CATCH
    select @LVC_ErrorCodeSection = '//products/row XML QuoteItem Read Section'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection    
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end
    -----------------------------------------------------------------
    --Clean up Bundle if no records associated with Quoteitem
    if not exists (select top 1 1 from Quotes.dbo.Quoteitem  with (nolock)
                   where quoteidseq=@LVC_quoteid and groupidseq=@LI_groupid)
    begin
      exec Quotes.dbo.uspQUOTES_DeleteBundle @IPVC_QuoteID=@LVC_quoteid,@IPBI_BundleID=@LI_groupid
    end
    -----------------------------------------------------------------
    return
  end CATCH;  
  ------------------------------------------------------------------
  --- Deleting Records from Quoteitem for current GroupID after taking snapshot
  begin TRY
    ----------------------------------------------------------------------------------------
    --Take a snapshot of current quoteitem values 
    ---  for QuoteIDSeq = @LVC_quoteid  and GroupIDSeq = @LI_groupid
    ---------------------------------------------------------------------------------------- 
    Insert into #TEMPQuoteItemSnapShot(QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,familycode,
                                       publicationyear,publicationquarter,minunits,maxunits,
                                       AllowProductCancelFlag,PriceVersion,Sites,Units,Beds,PPUPercentage,Quantity,
                                       Multiplier,ChargeAmount,
                                       ExtChargeAmount,ExtYear1ChargeAmount,ExtYear2ChargeAmount,ExtYear3ChargeAmount,
                                       DiscountPercent,DiscountAmount,TotalDiscountPercent,TotalDiscountAmount,
                                       NetChargeAmount,NetExtChargeAmount,NetExtYear1ChargeAmount,
                                       NetExtYear2ChargeAmount,NetExtYear3ChargeAmount,
                                       capmaxunitsflag,dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                       excludeforbookingsflag,crossfiremaximumallowablecallvolume)
    select QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,familycode,
                                       publicationyear,publicationquarter,minunits,maxunits,                                       
                                       AllowProductCancelFlag,PriceVersion,Sites,Units,Beds,PPUPercentage,Quantity,
                                       Multiplier,ChargeAmount,
                                       ExtChargeAmount,ExtYear1ChargeAmount,ExtYear2ChargeAmount,ExtYear3ChargeAmount,
                                       DiscountPercent,DiscountAmount,TotalDiscountPercent,TotalDiscountAmount,
                                       NetChargeAmount,NetExtChargeAmount,NetExtYear1ChargeAmount,
                                       NetExtYear2ChargeAmount,NetExtYear3ChargeAmount,
                                       capmaxunitsflag,dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                       excludeforbookingsflag,crossfiremaximumallowablecallvolume
    from QUOTES.DBO.[quoteitem]  with (nolock) 
    where  QuoteIDSeq = @LVC_quoteid  and GroupIDSeq = @LI_groupid
    ----------------------------------------------------------------------------------------
    --Delete all existing records from QUOTES.DBO.[quoteitem]  with (nolock) 
    -- for QuoteIDSeq = @LVC_quoteid  and GroupIDSeq = @LI_groupid    
    Delete from QUOTES.DBO.[quoteitem] where QuoteIDSeq = @LVC_quoteid  and GroupIDSeq = @LI_groupid
  end TRY
  begin CATCH
    select @LVC_ErrorCodeSection = 'QuoteItem Delete Section 1'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection     
    drop table #TEMPQuoteItemSnapShot
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end
    return         
  end CATCH
  -------------------------------------------------------------------------------------------
  ---select * from #LT_quoteitem --:Validation
  if (select count(*) from #LT_quoteitem) > 0
  begin    
    ----------------------------------------------------------------------------------------
    --Insert QUOTES.DBO.QuoteItem
    ----------------------------------------------------------------------------------------
    begin TRY      
      select @LI_Min = Min(SEQ),@LI_Max = Max(SEQ) from #LT_quoteitem
      while @LI_Min <= @LI_Max
      begin --: begin while      
        --------------------------
        select @LVC_productcode=productcode,
               @LN_priceversion=priceversion,
               @LVC_frequencycode=frequencycode,
               @LVC_measurecode=measurecode,
               @LVC_ilffrequencycode=ilffrequencycode,
               @LVC_ilfmeasurecode=ilfmeasurecode              
        from #LT_quoteitem where SEQ = @LI_Min
        --------------------------       
        /*if exists (select Top 1 1 from PRODUCTS.dbo.Charge  with (nolock)
                   where  ProductCode    = @LVC_productcode 
                   and    priceversion   = @LN_priceversion
                   and    chargetypecode = 'ILF'
                   and    frequencycode  = @LVC_frequencycode
                   and    measurecode    = @LVC_measurecode    
                  )
        begin
          select @LVC_ilffrequencycode = @LVC_frequencycode,@LVC_ilfmeasurecode = @LVC_measurecode
        end
        else if exists (select Top 1 1 from PRODUCTS.dbo.Charge  with (nolock)
                        where  ProductCode    = @LVC_productcode 
                        and    priceversion   = @LN_priceversion
                        and    chargetypecode = 'ILF'
                        and    measurecode    = @LVC_measurecode                        
                        )
        begin
          select Top 1 @LVC_ilffrequencycode = FrequencyCode,@LVC_ilfmeasurecode = measurecode
          from PRODUCTS.dbo.Charge  with (nolock) where ProductCode = @LVC_productcode 
          and    priceversion   = @LN_priceversion
          and    chargetypecode = 'ILF'
          and    measurecode    = @LVC_measurecode 
        end
        else if exists (select Top 1 1 from PRODUCTS.dbo.Charge  with (nolock)
                        where  ProductCode    = @LVC_productcode 
                        and    priceversion   = @LN_priceversion
                        and    chargetypecode = 'ILF'
                        and    measurecode    = 'SITE'                        
                        )
        begin
          select Top 1 @LVC_ilffrequencycode = FrequencyCode,@LVC_ilfmeasurecode = measurecode
          from   PRODUCTS.dbo.Charge  with (nolock) 
          where  ProductCode    = @LVC_productcode 
          and    Disabledflag   = 0
          and    chargetypecode = 'ILF'
          and    measurecode    = 'SITE' 
        end
        else
        begin
          select Top 1 @LVC_ilffrequencycode = FrequencyCode,@LVC_ilfmeasurecode = measurecode
          from   PRODUCTS.dbo.Charge  with (nolock) 
          where ProductCode = @LVC_productcode and chargetypecode = 'ILF'          
        end
        */
        ---------~~~~~~~~~~~~~~~~~~~~~~~~~ILF Insert Section begins~~~~~~~~~-------------------
        if  not exists (select Top 1 1 from QUOTES.DBO.[quoteitem]  with (nolock) 
                        where  QuoteIDSeq = @LVC_quoteid  and GroupIDSeq = @LI_groupid
                        and    ProductCode = @LVC_productcode and frequencycode = @LVC_ilffrequencycode
                        and    measurecode = @LVC_ilfmeasurecode and chargetypecode ='ILF')
        and exists (select Top 1 1 from QUOTES.DBO.[Group]   with (nolock) where  QuoteIDSeq = @LVC_quoteid  and IDSeq = @LI_groupid)
        and exists (select Top 1 1 from QUOTES.DBO.[Quote]   with (nolock) where  QuoteIDSeq = @LVC_quoteid)
        and exists (select Top 1 1 from PRODUCTS.dbo.Charge  with (nolock) 
                    where  ProductCode    = @LVC_productcode    
                    and    priceversion   = @LN_priceversion
                    and    chargetypecode = 'ILF'
                    and    FrequencyCode  = @LVC_ilffrequencycode 
                    and    measurecode    = @LVC_ilfmeasurecode)
        begin 
          insert into QUOTES.DBO.[quoteitem](QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,familycode,
                                             allowproductcancelflag,
                                             publicationyear,publicationquarter,minunits,maxunits,
                                             PriceVersion,quantity,
                                             Sites,Units,beds,ppupercentage,
                                             ChargeAmount,DiscountPercent,NetChargeAmount,capmaxunitsflag,
                                             dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                             excludeforbookingsflag,crossfiremaximumallowablecallvolume)
          select @LVC_quoteid,@LI_groupid,@LVC_productcode,'ILF' as chargetypecode,
                 @LVC_ilffrequencycode,@LVC_ilfmeasurecode,familycode,
                 allowproductcancelflag,
                 publicationyear,publicationquarter,ilfminunits,ilfmaxunits,
                 priceversion,quantity as quantity,                  
                 @LI_Sites,@LI_Units,@LI_beds,@LI_ppupercentage,                                    
                 listpriceilf as  chargeamount,
                 --ilfdiscountpercent as ilfdiscountpercent,                 
                 convert(float,
                              (convert(float,listpriceilf)-convert(float,ilfnetprice))*(100)/
                              (case when listpriceilf=0 then 1 else convert(float,listpriceilf) end) 
                        )   as ilfdiscountpercent,                
                 ilfnetprice as NetChargeAmount,
                 ilfcapmaxunitsflag as capmaxunitsflag,
                 ilfdollarminimum,ilfdollarmaximum,credtcardpricingpercentage,
                 excludeforbookingsflag,crossfiremaximumallowablecallvolume                 
          from #LT_quoteitem with (nolock) where SEQ = @LI_Min 
          and exists (select Top 1 1 from PRODUCTS.dbo.Charge  with (nolock) 
                      where  ProductCode    = @LVC_productcode    
                      and    priceversion   = @LN_priceversion
                      and    chargetypecode = 'ILF'
                      and    FrequencyCode  = @LVC_ilffrequencycode 
                      and    measurecode    = @LVC_ilfmeasurecode)        
        end
        ---------~~~~~~~~~~~~~~~~~~~~~~~~~ILF Insert Section ends~~~~~~~~~-------------------
        ---------~~~~~~~~~~~~~~~~~~~~~~~~~ACS Insert Section begins~~~~~~~~~-------------------
        if  not exists (select Top 1 1 from QUOTES.DBO.[quoteitem]  with (nolock) 
                        where  QuoteIDSeq = @LVC_quoteid  and GroupIDSeq = @LI_groupid
                        and    ProductCode = @LVC_productcode and frequencycode = @LVC_frequencycode
                        and    measurecode = @LVC_measurecode and chargetypecode ='ACS')   
        and exists (select Top 1 1 from QUOTES.DBO.[Group]   with (nolock) where  QuoteIDSeq = @LVC_quoteid  and IDSeq = @LI_groupid)
        and exists (select Top 1 1 from QUOTES.DBO.[Quote]   with (nolock) where  QuoteIDSeq = @LVC_quoteid) 
        and exists (select Top 1 1 from PRODUCTS.dbo.Charge  with (nolock) 
                    where  ProductCode = @LVC_productcode     
                    and    priceversion   = @LN_priceversion
                    and    chargetypecode = 'ACS'
                    and    FrequencyCode  = @LVC_frequencycode   
                    and    measurecode    = @LVC_measurecode)    
        begin
          insert into QUOTES.DBO.[quoteitem](QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,familycode,
                                             allowproductcancelflag,
                                             publicationyear,publicationquarter,minunits,maxunits,
                                             PriceVersion,quantity,
                                             Sites,Units,beds,ppupercentage,
                                             ChargeAmount,DiscountPercent,NetChargeAmount,
                                             capmaxunitsflag,
                                             dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                             excludeforbookingsflag,crossfiremaximumallowablecallvolume
                                             )
          select @LVC_quoteid,@LI_groupid,productcode,'ACS' as chargetypecode,
                 @LVC_frequencycode,@LVC_measurecode,familycode,
                 allowproductcancelflag,
                 publicationyear,publicationquarter,acsminunits,acsmaxunits,
                 priceversion,quantity as quantity,                 
                 @LI_Sites,@LI_Units,@LI_beds,@LI_ppupercentage,                                      
                 listpriceaccess as  chargeamount,                
                 --accessdiscountpercent as accessdiscountpercent,
                 convert(float,(convert(float,listpriceaccess)-convert(float,accessnetprice))*(100)/
                               (case when listpriceaccess=0 then 1 else convert(float,listpriceaccess) end)
                        )  as accessdiscountpercent,                 
                 accessnetprice as NetChargeAmount,
                 acscapmaxunitsflag   as capmaxunitsflag,
                 acsdollarminimum,acsdollarmaximum,credtcardpricingpercentage,
                 excludeforbookingsflag,crossfiremaximumallowablecallvolume                
          from #LT_quoteitem with (nolock) where SEQ = @LI_Min
          and exists (select Top 1 1 from PRODUCTS.dbo.Charge  with (nolock) 
                      where  ProductCode    = @LVC_productcode     
                      and    priceversion   = @LN_priceversion
                      and    chargetypecode = 'ACS'
                      and    FrequencyCode  = @LVC_frequencycode   
                      and    measurecode    = @LVC_measurecode) 
        end 
        ---------~~~~~~~~~~~~~~~~~~~~~~~~~ACS Insert Section ends~~~~~~~~~-------------------                
        select @LI_Min = @LI_Min + 1
      end --: end while
      exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@LVC_quoteid,@IPI_GroupID=@LI_groupid      
    end TRY
    begin CATCH
       select @LVC_ErrorCodeSection = 'QuoteItem Insert Section'
       Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection      
       ---------------------------------------------------
        ---Error has occured while inserting new Records into Quoteitem.
        ---Hence Reverting back to Previously existing configuration.
        Delete from QUOTES.DBO.[quoteitem] where QuoteIDSeq = @LVC_quoteid  and GroupIDSeq = @LI_groupid

        Insert into QUOTES.DBO.[quoteitem](QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,familycode,
                                       publicationyear,publicationquarter,minunits,maxunits,
                                       AllowProductCancelFlag,PriceVersion,Sites,Units,Beds,PPUPercentage,Quantity,
                                       Multiplier,ChargeAmount,
                                       ExtChargeAmount,ExtYear1ChargeAmount,ExtYear2ChargeAmount,ExtYear3ChargeAmount,
                                       DiscountPercent,DiscountAmount,TotalDiscountPercent,TotalDiscountAmount,
                                       NetChargeAmount,NetExtChargeAmount,NetExtYear1ChargeAmount,
                                       NetExtYear2ChargeAmount,NetExtYear3ChargeAmount,
                                       capmaxunitsflag,dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                       excludeforbookingsflag,crossfiremaximumallowablecallvolume)
        select QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,familycode,
                                       publicationyear,publicationquarter,minunits,maxunits,
                                       AllowProductCancelFlag,PriceVersion,Sites,Units,Beds,PPUPercentage,Quantity,
                                       Multiplier,ChargeAmount,
                                       ExtChargeAmount,ExtYear1ChargeAmount,ExtYear2ChargeAmount,ExtYear3ChargeAmount,
                                       DiscountPercent,DiscountAmount,TotalDiscountPercent,TotalDiscountAmount,
                                       NetChargeAmount,NetExtChargeAmount,NetExtYear1ChargeAmount,
                                       NetExtYear2ChargeAmount,NetExtYear3ChargeAmount,
                                       capmaxunitsflag,dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                       excludeforbookingsflag,crossfiremaximumallowablecallvolume
        from #TEMPQuoteItemSnapShot  with (nolock) 
    end CATCH
  end 
  ---------------------------------------------------------------------------------------
  IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end 
  ---------------------------------------------------------------------------------------
  --Clean up Bundle if no records associated with Quoteitem
  if not exists (select top 1 1 from Quotes.dbo.Quoteitem  with (nolock)
                 where quoteidseq=@LVC_quoteid and groupidseq=@LI_groupid)
  begin
    exec Quotes.dbo.uspQUOTES_DeleteBundle @IPVC_QuoteID=@LVC_quoteid,@IPBI_BundleID=@LI_groupid
  end
  -----------------------------------------------------------------
  --Final Clean Up
  drop table #TEMPQuoteItemSnapShot
  drop table #LT_groupmaster
  drop table #LT_quoteitem
  -----------------------------------------------------------------
END--: Main END
GO
