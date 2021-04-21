SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec quotes.dbo.uspQUOTES_GetGroupDetailProducts @IPC_CompanyID = 'C0000000739',@IPVC_quoteid='',@IPI_GroupID = '',
@IPVC_GroupType = 'SITE',@IPVC_FamilyCode='',@IPVC_GroupStatus='edit',@IPI_PrePaidFlag= 1,@IPVC_RETURNTYPE = 'RECORDSET'
*/
-- Author          : Satya B
-- 07/18/2011      : Added new column PrePaidFlag with refence to TFS #295 Instant Invoice Transactions through OMS

CREATE PROCEDURE [quotes].[uspQUOTES_GetGroupDetailProducts] (@IPC_CompanyID               varchar(50),
                                                       @IPVC_quoteid                varchar(50)  = '0', 
                                                       @IPI_GroupID                 bigint       = 0,
                                                       @IPVC_GroupType              varchar(70)  = NULL, 
                                                       @IPVC_FamilyCode             varchar(50)  = '',                                                       
                                                       @IPI_InternalGroupID         varchar(100) = '', 
                                                       @IPVC_GroupStatus            varchar(50)  = 'EDIT',
                                                       @IPI_PrePaidFlag             int          = 0,
                                                       @IPI_ExternalQuoteIIFlag     int          = 0,
                                                       @IPVC_RETURNTYPE             varchar(100) = 'XML')
AS
BEGIN
  set nocount on   
  select @IPC_CompanyID = ltrim(rtrim(@IPC_CompanyID))
  select @IPVC_quoteid  = ltrim(rtrim(@IPVC_quoteid))
  --------------------------------------------------------------------------------------------  
  declare @LT_DisplayType     TABLE (displaytype  varchar(20))   

  create table #LT_QUOTEITEM_FINAL 
              (seq                      int           not null   identity(1,1) Primary Key,                              
               measurecode              varchar(10)   not null default '',
               measurename              varchar(50)   not null default '',
               frequencycode            varchar(10)   not null default '',
               frequencyname            varchar(50)   not null default '',
              
               ilfmeasurecode           varchar(10)   not null default '',
               ilffrequencycode         varchar(10)   not null default '',

               familycode               varchar(3)    not null default '',
               familyname               varchar(50)   not null default '',
               productcode              varchar(50)   not null default '',
               productname              varchar(200)  not null default '',
               productdisplayname       varchar(200)  not null default '',

               publicationyear          varchar(100)  not null default '', 
               publicationquarter       varchar(100)  not null default '',
               mpfpublicationtype       varchar(100)  not null default '',
               mpfpublicationflag       int           not null default 0,

               ilfdiscountmaxpercent    numeric(30,5) not null default 0.00,
               accessdiscountmaxpercent numeric(30,5) not null default 0.00,

               quantity                 varchar(50)   not null default 1,
               quantityenabledflag      int           not null default 0,
               explodequantityatorderflag int         not null default 0,
               listpriceilf             numeric(30,2) not null default 0.00,
               listpriceaccess          numeric(30,2) not null default 0,  
             
               ilfdiscountpercent       as convert(float,
                                                       (convert(float,listpriceilf)-convert(float,ilfnetprice))*(100)/
                                                       (case when listpriceilf=0 then 1 else convert(float,listpriceilf) end) 
                                                   ),
 
               accessdiscountpercent    as convert(float,(convert(float,listpriceaccess)-convert(float,accessnetprice))*(100)/
                                                         (case when listpriceaccess=0 then 1 else convert(float,listpriceaccess) end)
                                                   ),
               ilfdiscountamount        as (listpriceilf-ilfnetprice),
               accessdiscountamount     as (listpriceaccess-accessnetprice),     
        
               ilfnetprice              numeric(30,2) not null default 0,
               accessnetprice           numeric(30,2) not null default 0,

               
               priceversion             numeric(18,0) not null default 0,
               optionflag               bit           not null default 0,              
               isselected               int           not null default 0,
               sortseq                  int           not null default 0,
               socflag                  int           not null default 1,               
               ilfminunits              int           not null default 0,
               ilfmaxunits              int           not null default 0,              
               acsminunits              int           not null default 0,
               acsmaxunits              int           not null default 0,      
               ilfcapmaxunitsflag       int           not null default 0,
               acscapmaxunitsflag       int           not null default 0,
               acsdollarminimum         money         not null default 0,
               ilfdollarminimum         money         not null default 0,
               acsdollarminimumenabledflag int        not null default 0,
               ilfdollarminimumenabledflag int        not null default 0,

               acsdollarmaximum            money      not null default 0,
               ilfdollarmaximum            money      not null default 0,
               acsdollarmaximumenabledflag int        not null default 0,
               ilfdollarmaximumenabledflag int        not null default 0,
 
               acsleaddays                 int        not null default 0,
               
               creditcardpercentageenabledflag   int           not null DEFAULT 0,
               credtcardpricingpercentage        numeric(30,2) not null DEFAULT 0.00, 
               ---------------------------------------------------------------------
               socexcludeforbookingsflag            int           not null default 0,
               excludeforbookingsflag               int           not null default 0,
               ---------------------------------------------------------------------
               crossfirecallpricingenabledflag      int           not null default 0,
               crossfiremaximumallowablecallvolume  bigint        not null default 0,

               stockbundleflag                      int           not null Default 0,
               ---------------------------------------------------------------------
               autofulfillflag                      int           not null Default 0,                
               internalgroupid                      varchar(100)  not null default '',
               prepaidflag                          int           not null Default 0
               );
  --------------------------------------------------------------------------------------------
  --If Quote @IPVC_quoteid, already exists in the system, then its values of Quote Header overrides
  if exists(select top 1 1 from QUOTES.dbo.[Quote] Q with (nolock)
            where  Q.QuoteIDSeq = @IPVC_quoteid
           )
  begin
    select @IPI_PrePaidFlag         = Q.PrePaidFlag
          ,@IPI_ExternalQuoteIIFlag = Q.ExternalQuoteIIFlag
    from   QUOTES.dbo.[Quote] Q with (nolock)
    where  Q.QuoteIDSeq = @IPVC_quoteid
  end

  select @IPI_PrePaidFlag = (Case when @IPI_ExternalQuoteIIFlag = 1 then 0 else @IPI_PrePaidFlag end);
  -----------------------------------------------------------------------------------------
  if @IPVC_GroupStatus <> 'READONLY'
  begin
    if exists(select top 1 1 from QUOTES.dbo.[Quote] Q with (nolock)
              where  Q.QuoteIDSeq = @IPVC_quoteid
              and    Q.QuoteStatusCode = 'APR'
             )
    begin
      Select @IPVC_GroupStatus = 'READONLY'
    end
    else if exists (select top 1  1 from   QUOTES.dbo.[Group] S with (nolock)
                    where   S.IDSeq        = @IPI_GroupID     
                    and     S.QuoteIDSeq   = @IPVC_quoteid
                    and     S.TransferredFlag = 1
                   )       
    begin
      select  @IPVC_GroupType             = S.grouptype,            
              @IPVC_GroupStatus           = 'READONLY'            
      from    QUOTES.dbo.[Group] S with (nolock)
      where   S.IDSeq        = @IPI_GroupID     
      and     S.QuoteIDSeq   = @IPVC_quoteid 
      and     S.TransferredFlag = 1   
    end
    else if exists (select top 1  1 from   QUOTES.dbo.[Group] S with (nolock)
                    where   S.IDSeq        = @IPI_GroupID     
                    and     S.QuoteIDSeq   = @IPVC_quoteid
                   )       
    begin
      select  @IPVC_GroupType             = S.grouptype,            
              @IPVC_GroupStatus           = 'EDIT'             
      from    QUOTES.dbo.[Group] S with (nolock)
      where   S.IDSeq        = @IPI_GroupID     
      and     S.QuoteIDSeq   = @IPVC_quoteid    
    end
    else 
    begin
      select @IPVC_GroupStatus= 'EDIT' 
    end
  end
  
  --------------------------------------------------------------------------------------------   
  if @IPVC_GroupType = 'PMC'
  begin
    insert into @LT_DisplayType(displaytype)
    select  'PMC' displaytype union Select 'BOTH' as displaytype
  end
  else
  begin
   insert into @LT_DisplayType(displaytype)
   select  'SITE' DisplayType union Select 'BOTH' as DisplayType
  end
  --------------------------------------------------------------------  


  --------------------------------------------------------------------  
  if (@IPVC_GroupStatus <> 'READONLY')
  begin
    insert into #LT_QUOTEITEM_FINAL(familycode,familyname,measurecode,measurename,frequencycode,frequencyname,
                                    ilfmeasurecode,ilffrequencycode,productcode,productname,productdisplayname,
                                    publicationyear,publicationquarter,mpfpublicationtype,mpfpublicationflag,
                                    ilfdiscountmaxpercent,accessdiscountmaxpercent,
                                    quantity,quantityenabledflag,explodequantityatorderflag,
                                    listpriceilf,
                                    listpriceaccess,
                                    ilfnetprice,accessnetprice,
                                    priceversion,
                                    optionflag,ilfminunits,ilfmaxunits,acsminunits,acsmaxunits,
                                    ilfcapmaxunitsflag,acscapmaxunitsflag,
                                    acsdollarminimum,ilfdollarminimum,acsdollarminimumenabledflag,ilfdollarminimumenabledflag,
                                    acsdollarmaximum,ilfdollarmaximum,acsdollarmaximumenabledflag,ilfdollarmaximumenabledflag,
                                    acsleaddays,
                                    creditcardpercentageenabledflag,credtcardpricingpercentage,
                                    sortseq,socflag,isselected,
                                    socexcludeforbookingsflag,excludeforbookingsflag,
                                    crossfirecallpricingenabledflag,crossfiremaximumallowablecallvolume,
                                    stockbundleflag,autofulfillflag,internalgroupid,prepaidflag)
    select distinct ltrim(rtrim(P.FamilyCode))                                                       as familycode,
                    ltrim(rtrim(F.Name))                                                             as familyname,
                    ltrim(rtrim(CACS.MeasureCode))                                                   as measurecode,
                    ltrim(rtrim(M.Name))                                                             as measurename, 
                    ltrim(rtrim(CACS.FrequencyCode))                                                 as frequencycode,
                    ltrim(rtrim(FR.Name))                                                            as frequencyname, 
 
                    ltrim(rtrim(Coalesce(CILF.MeasureCode,'')))                                      as ilfmeasurecode,
                    ltrim(rtrim(Coalesce(CILF.FrequencyCode,'')))                                    as ilffrequencycode,
                 
                    ltrim(rtrim(P.Code))                                                             as productcode, 
                    ltrim(rtrim(P.name))                                                             as productname,
                    ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                    Coalesce(QACS.publicationyear,'')                                                as publicationyear,
                    Coalesce(QACS.publicationquarter,'')                                             as publicationquarter,
                    /* (case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                            then 'Yearly'
                         when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                            then 'Quarterly'
                         else ''
                     end
                    )                                                                                as mpfpublicationtype,*/
                    coalesce(CACS.mpfpublicationName,'')                                             as mpfpublicationtype,
                    P.mpfpublicationflag                                                             as mpfpublicationflag,

                    coalesce(CILF.DiscountMaxPercent,0.00)                                           as ilfdiscountmaxpercent,
                    coalesce(CACS.DiscountMaxPercent,0.00)                                           as accessdiscountmaxpercent,                    
                    (case when (coalesce(CACS.quantityenabledflag,0) = 1 and coalesce(CACS.explodequantityatorderflag,0) = 1)
                             then convert(varchar(50),convert(decimal(18,0),coalesce(QACS.quantity,1)))
                          when (coalesce(CACS.quantityenabledflag,0) = 1 and coalesce(CACS.explodequantityatorderflag,0) = 0)
                             then convert(varchar(50),convert(decimal(18,3),coalesce(QACS.quantity,1.000)))
                          else convert(varchar(50),convert(decimal(18,0),coalesce(QACS.quantity,1)))
                     end
                    )                                                                                as quantity,
                    coalesce(CACS.quantityenabledflag,0)                                             as quantityenabledflag,
                    coalesce(CACS.explodequantityatorderflag,0)                                      as explodequantityatorderflag,
                    coalesce(CILF.ChargeAmount,QILF.ChargeAmount,0)                                  as listpriceilf,                                         
                    coalesce(CACS.ChargeAmount,QACS.ChargeAmount,0)                                  as listpriceaccess,                    
                    coalesce(QILF.NetChargeAmount,CILF.ChargeAmount,0)                               as ilfnetprice,
                    coalesce(QACS.NetChargeAmount,CACS.ChargeAmount,0)                               as accessnetprice,  
                    CACS.PriceVersion                                                                as priceversion,
                    P.optionflag                                                                     as optionflag,

                    (Case when (QACS.Productcode is not null)
                             then coalesce(QILF.minunits,CILF.minunits,0)                         
                         else  coalesce(CILF.minunits,0)
                    end)                                                                             as ilfminunits,
    
                    (Case when (QACS.Productcode is not null)
                            then coalesce(QILF.maxunits,CILF.maxunits,0)                         
                         else  coalesce(CILF.maxunits,0)
                    end)                                                                             as ilfmaxunits,
                    (Case when (QACS.Productcode is not null)
                             then coalesce(QACS.minunits,CACS.minunits,0)                         
                         else  coalesce(CACS.minunits,0)
                    end)                                                                             as acsminunits,
                    (Case when (QACS.Productcode is not null)
                          then coalesce(QACS.maxunits,CACS.maxunits,0)                        
                         else  coalesce(CACS.maxunits,0)
                    end)                                                                             as acsmaxunits,
                    coalesce(QILF.capmaxunitsflag,0)                                                 as ilfcapmaxunitsflag,
                    coalesce(QACS.capmaxunitsflag,0)                                                 as acscapmaxunitsflag,                    
                     
                    (Case when (QACS.Productcode is not null)
                             then coalesce(QACS.dollarminimum,CACS.dollarminimum,0)                         
                         else  coalesce(CACS.dollarminimum,0)
                    end)                                                                             as acsdollarminimum,
                    (Case when (QACS.Productcode is not null)
                            then coalesce(QILF.dollarminimum,CILF.dollarminimum,0)
                         else  coalesce(CILF.dollarminimum,0)
                    end)                                                                             as ilfdollarminimum,
                    coalesce(CACS.dollarminimumenabledflag,0)                                        as acsdollarminimumenabledflag,
                    coalesce(CILF.dollarminimumenabledflag,0)                                        as ilfdollarminimumenabledflag,

                   (Case when (QACS.Productcode is not null)
                            then coalesce(QACS.dollarmaximum,CACS.dollarmaximum,0)
                         else  coalesce(CACS.dollarmaximum,0)
                    end)                                                                             as acsdollarmaximum,
                    (Case when (QACS.Productcode is not null)
                             then coalesce(QILF.dollarmaximum,CILF.dollarmaximum,0)
                         else  coalesce(CILF.dollarmaximum,0)
                    end)                                                                             as ilfdollarmaximum,
                    coalesce(CACS.dollarmaximumenabledflag,0)                                        as acsdollarmaximumenabledflag,
                    coalesce(CILF.dollarmaximumenabledflag,0)                                        as ilfdollarmaximumenabledflag,

                    coalesce(CACS.LeadDays,0)                                                        as acsleaddays,
                    (case when ((coalesce(CACS.creditcardpercentageenabledflag,0)=1) or
                                (coalesce(CILF.creditcardpercentageenabledflag,0)=1)
                               )
                           then 1
                          else  0
                     end
                     )                                                                               as creditcardpercentageenabledflag,
                    (case when (coalesce(CACS.creditcardpercentageenabledflag,0)=1)
                             then coalesce(QACS.credtcardpricingpercentage,CACS.credtcardpricingpercentage,0.00)
                          when (coalesce(CILF.creditcardpercentageenabledflag,0)=1)
                             then coalesce(QILF.credtcardpricingpercentage,CILF.credtcardpricingpercentage,0.00)
                          else 0.00
                     end
                    )                                                                                as credtcardpricingpercentage,
                    P.sortseq                                                                        as sortseq,
                    P.socflag                                                                        as socflag,
                    (Case when QACS.Productcode is not null then 1 else 0 end)                       as isselected,

                    P.excludeforbookingsflag                                                         as socexcludeforbookingsflag,
                    (case when P.excludeforbookingsflag = 1 then 1 
                          else coalesce(QACS.excludeforbookingsflag,P.excludeforbookingsflag,0)
                     end
                    )                                                                                as excludeforbookingsflag,
                    CACS.crossfirecallpricingenabledflag                                             as crossfirecallpricingenabledflag,
                    coalesce(QACS.crossfiremaximumallowablecallvolume,0)                             as crossfiremaximumallowablecallvolume,

                    P.stockbundleflag                                                                as stockbundleflag,
                    convert(int,P.autofulfillflag)                                                   as autofulfillflag,
                    @IPI_InternalGroupID                                                             as internalgroupid,
                    P.prepaidflag                                                                    as prepaidflag
    from    PRODUCTS.dbo.Product P with (nolock)
    inner join
            PRODUCTS.dbo.Family F  with (nolock)
    on      P.FamilyCode = F.Code 
    and     P.DisabledFlag = 0
    and     PATINDEX('%'+@IPVC_FamilyCode+'%',P.FamilyCode) > 0
    and    (
            (P.PrePaidFlag = @IPI_PrePaidFlag and @IPI_ExternalQuoteIIFlag = 0)
                or
            (@IPI_ExternalQuoteIIFlag = 1)
           )
    inner join
            Products.dbo.Charge CACS with (nolock)
    on      P.Code              = CACS.ProductCode
    and     P.PriceVersion      = CACS.PriceVersion
    and     CACS.DisabledFlag   = 0
    and     CACS.ChargeTypeCode = 'ACS'
    and     CACS.DisplayType in (select displaytype from @LT_DisplayType)
    inner join 
           PRODUCTS.dbo.Measure M  with (nolock)
    ON     CACS.MeasureCode   = M.Code    
    inner join  PRODUCTS.dbo.Frequency FR with (nolock)
    ON     CACS.FrequencyCode = FR.Code 
    and    FR.DisplayFlag     = 1
    left outer join 
           Products.dbo.Charge CILF with (nolock)
    on     P.Code              = CILF.ProductCode
    and    P.PriceVersion      = CILF.PriceVersion
    and    CILF.DisabledFlag   = 0
    and    CACS.DisabledFlag   = 0
    and    CILF.ChargeTypeCode = 'ILF'
    and    CACS.ProductCode    = CILF.ProductCode
    and    CACS.PriceVersion   = CILF.PriceVersion
    and    CILF.DisplayType in (select displaytype from @LT_DisplayType)
    left outer join 
            Quotes.dbo.Quoteitem QACS with (nolock)
    on      QACS.GroupIDSeq     = @IPI_GroupID
    and     QACS.QuoteIDSeq     = @IPVC_quoteid
    and     QACS.ProductCode    = CACS.ProductCode
    and     QACS.measurecode    = CACS.measurecode
    and     QACS.Frequencycode  = CACS.Frequencycode
    and     QACS.ChargeTypeCode = CACS.ChargeTypeCode
    --and     QACS.PriceVersion   = CACS.PriceVersion
    and     CACS.DisabledFlag   = 0
    and     QACS.ChargeTypeCode = 'ACS'
    and     CACS.ChargeTypeCode = 'ACS'       
    left outer join 
            Quotes.dbo.Quoteitem QILF with (nolock)
    on      QILF.GroupIDSeq     = @IPI_GroupID
    and     QILF.QuoteIDSeq     = @IPVC_quoteid
    and     QILF.ProductCode    = CILF.ProductCode
    and     QILF.measurecode    = CILF.measurecode
    and     QILF.Frequencycode  = CILF.Frequencycode
    and     QILF.ChargeTypeCode = CILF.ChargeTypeCode
    --and     QILF.PriceVersion   = CILF.PriceVersion
    and     CILF.DisabledFlag   = 0
    and     CILF.ChargeTypeCode = 'ILF'
    and     QILF.ChargeTypeCode = 'ILF'
    Where  (
            (P.PrePaidFlag = @IPI_PrePaidFlag and @IPI_ExternalQuoteIIFlag = 0)
                or
            (@IPI_ExternalQuoteIIFlag = 1)
           )
    Order by P.sortseq asc,isselected desc,measurename asc,frequencyname asc
    --------------------------------------------------------------------  
    insert into #LT_QUOTEITEM_FINAL(familycode,familyname,measurecode,measurename,frequencycode,frequencyname,
                                    ilfmeasurecode,ilffrequencycode,productcode,productname,productdisplayname,
                                    publicationyear,publicationquarter,mpfpublicationtype,mpfpublicationflag,
                                    ilfdiscountmaxpercent,accessdiscountmaxpercent,
                                    quantity,quantityenabledflag,explodequantityatorderflag,
                                    listpriceilf,
                                    listpriceaccess,
                                    ilfnetprice,accessnetprice,
                                    priceversion,
                                    optionflag,ilfminunits,ilfmaxunits,acsminunits,acsmaxunits,
                                    ilfcapmaxunitsflag,acscapmaxunitsflag,
                                    acsdollarminimum,ilfdollarminimum,acsdollarminimumenabledflag,ilfdollarminimumenabledflag,
                                    acsdollarmaximum,ilfdollarmaximum,acsdollarmaximumenabledflag,ilfdollarmaximumenabledflag,
                                    creditcardpercentageenabledflag,credtcardpricingpercentage, 
                                    sortseq,socflag,isselected,
                                    socexcludeforbookingsflag,excludeforbookingsflag,
                                    crossfirecallpricingenabledflag,crossfiremaximumallowablecallvolume,
                                    stockbundleflag,autofulfillflag,internalgroupid,prepaidflag)
    select distinct ltrim(rtrim(P.FamilyCode))                                                       as familycode,
                    ltrim(rtrim(F.Name))                                                             as familyname,
                    ltrim(rtrim(CILF.MeasureCode))                                                   as measurecode,
                    ltrim(rtrim(M.Name))                                                             as measurename, 
                    ltrim(rtrim(CILF.FrequencyCode))                                                 as frequencycode,
                    ltrim(rtrim(FR.Name))                                                            as frequencyname, 
  
                    ltrim(rtrim(Coalesce(CILF.MeasureCode,'')))                                      as ilfmeasurecode,
                    ltrim(rtrim(Coalesce(CILF.FrequencyCode,'')))                                    as ilffrequencycode,
                 
                    ltrim(rtrim(P.Code))                                                             as productcode, 
                    ltrim(rtrim(P.name))                                                             as productname,
                    ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                    Coalesce(QILF.publicationyear,'')                                                as publicationyear,
                    Coalesce(QILF.publicationquarter,'')                                             as publicationquarter,
                    /*(case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                            then 'Yearly'
                         when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                            then 'Quarterly'
                         else ''
                     end
                    )                                                                                as mpfpublicationtype,*/
                    coalesce(CILF.mpfpublicationName,'')                                             as mpfpublicationtype,
                    P.mpfpublicationflag                                                             as mpfpublicationflag,
           
                    coalesce(CILF.DiscountMaxPercent,0.00)                                           as ilfdiscountmaxpercent,
                    0.00                                                                             as accessdiscountmaxpercent,                    
                    (case when (coalesce(CILF.quantityenabledflag,0) = 1 and  coalesce(CILF.explodequantityatorderflag,0) = 1)
                             then convert(varchar(50),convert(decimal(18,0),coalesce(QILF.quantity,1)))
                          when (coalesce(CILF.quantityenabledflag,0) = 1 and  coalesce(CILF.explodequantityatorderflag,0) = 0)
                             then convert(varchar(50),convert(decimal(18,3),coalesce(QILF.quantity,1.000)))
                          else convert(varchar(50),convert(decimal(18,0),coalesce(QILF.quantity,1)))
                     end
                    )                                                                                as quantity,                    
                    coalesce(CILF.quantityenabledflag,0)                                             as quantityenabledflag,
                    coalesce(CILF.explodequantityatorderflag,0)                                      as explodequantityatorderflag,
                    (Case when (QILF.Productcode is not null)
                             then coalesce(QILF.ChargeAmount,CILF.ChargeAmount,0)
                         else  coalesce(CILF.ChargeAmount,0)
                    end)                                                                             as listpriceilf,
                    0                                                                                as listpriceaccess,
                    (Case when (QILF.Productcode is not null)
                             then coalesce(QILF.NetChargeAmount,CILF.ChargeAmount,0)
                         else  coalesce(CILF.ChargeAmount,0)
                    end)                                                                             as ilfnetprice,
                    0                                                                                as accessnetprice,  
                    CILF.PriceVersion                                                                as priceversion,
                    P.optionflag                                                                     as optionflag,
                    (Case when (QILF.Productcode is not null)
                            then coalesce(QILF.minunits,CILF.minunits,0)
                         else  coalesce(CILF.minunits,0)
                    end)                                                                             as ilfminunits,
    
                    (Case when (QILF.Productcode is not null)
                             then coalesce(QILF.maxunits,CILF.maxunits,0)
                         else  coalesce(CILF.maxunits,0)
                    end)                                                                             as ilfmaxunits,
                    0                                                                                as acsminunits,
                    0                                                                                as acsmaxunits,
                    coalesce(QILF.capmaxunitsflag,0)                                                 as ilfcapmaxunitsflag,
                    0                                                                                as acscapmaxunitsflag,

                    0                                                                                as acsdollarminimum,
                    (Case when (QILF.Productcode is not null)
                             then coalesce(QILF.dollarminimum,CILF.dollarminimum,0)
                         else  coalesce(CILF.dollarminimum,0)
                    end)                                                                             as ilfdollarminimum,
                    0                                                                                as acsdollarminimumenabledflag,
                    coalesce(CILF.dollarminimumenabledflag,0)                                        as ilfdollarminimumenabledflag,
                    0                                                                                as acsdollarmaximum,
                    (Case when (QILF.Productcode is not null)
                             then coalesce(QILF.dollarmaximum,CILF.dollarmaximum,0)
                         else  coalesce(CILF.dollarmaximum,0)
                    end)                                                                             as ilfdollarmaximum,
                    0                                                                                as acsdollarmaximumenabledflag,
                    coalesce(CILF.dollarmaximumenabledflag,0)                                        as ilfdollarmaximumenabledflag,
           
                    (case when (coalesce(CILF.creditcardpercentageenabledflag,0)=1)                               
                           then 1
                          else  0
                     end
                     )                                                                               as creditcardpercentageenabledflag,
                    (case when (coalesce(CILF.creditcardpercentageenabledflag,0)=1)
                             then coalesce(QILF.credtcardpricingpercentage,CILF.credtcardpricingpercentage,0.00)
                          else 0.00
                     end
                    )                                                                                as credtcardpricingpercentage,

                    P.sortseq                                                                        as sortseq,
                    P.socflag                                                                        as socflag,
                    (Case when QILF.Productcode is not null then 1 else 0 end)                       as isselected,

                    P.excludeforbookingsflag                                                         as socexcludeforbookingsflag,
                    (case when P.excludeforbookingsflag = 1 then 1 
                          else coalesce(QILF.excludeforbookingsflag,P.excludeforbookingsflag,0)
                     end
                    )                                                                                as excludeforbookingsflag,
                    CILF.crossfirecallpricingenabledflag                                             as crossfirecallpricingenabledflag,
                    coalesce(QILF.crossfiremaximumallowablecallvolume,0)                             as crossfiremaximumallowablecallvolume,


                    P.stockbundleflag                                                                as stockbundleflag,
                    convert(int,P.autofulfillflag)                                                   as autofulfillflag,
                    @IPI_InternalGroupID                                                             as internalgroupid,
                    P.prepaidflag                                                                    as prepaidflag
    from    PRODUCTS.dbo.Product P with (nolock)
    inner join
            PRODUCTS.dbo.Family F  with (nolock)
    on      P.FamilyCode = F.Code and P.DisabledFlag = 0
    and     PATINDEX('%'+@IPVC_FamilyCode+'%',P.FamilyCode) > 0
    and     (
              (P.PrePaidFlag = @IPI_PrePaidFlag and @IPI_ExternalQuoteIIFlag = 0)
                 or
              (@IPI_ExternalQuoteIIFlag = 1)
            )
    and  not exists (select TOP 1 X.ProductCode as ProductCode
                     from   #LT_QUOTEITEM_FINAL X
                     where  X.productcode = P.Code
                    )
    inner join
           Products.dbo.Charge CILF with (nolock)
    on     P.Code              = CILF.ProductCode
    and    P.PriceVersion      = CILF.PriceVersion
    and    CILF.Disabledflag   = 0
    and    CILF.ChargeTypeCode = 'ILF'
    and    CILF.DisplayType in (select displaytype from @LT_DisplayType)
    inner join 
           PRODUCTS.dbo.Measure M with (nolock)
    ON     CILF.MeasureCode = M.Code 
    inner join  PRODUCTS.dbo.Frequency FR with (nolock)
    ON     CILF.FrequencyCode = FR.Code 
    and    FR.DisplayFlag     = 1  
    left outer join 
           Quotes.dbo.Quoteitem QILF with (nolock)
    on     QILF.GroupIDSeq     = @IPI_GroupID
    and    QILF.QuoteIDSeq     = @IPVC_quoteid
    and    QILF.ProductCode    = CILF.ProductCode
    and    QILF.measurecode    = CILF.measurecode
    and    QILF.Frequencycode  = CILF.Frequencycode
    and    QILF.ChargeTypeCode = CILF.ChargeTypeCode
    --and    QILF.PriceVersion   = CILF.PriceVersion
    and    CILF.Disabledflag   = 0
    and    QILF.ChargeTypeCode = 'ILF'
    and    CILF.ChargeTypeCode = 'ILF'
    Where  (
            (P.PrePaidFlag = @IPI_PrePaidFlag and @IPI_ExternalQuoteIIFlag = 0)
                or
            (@IPI_ExternalQuoteIIFlag = 1)
           )
    Order by P.sortseq asc,isselected desc,measurename asc,frequencyname asc
    ------------------------------------------------------------------------------------------------------
  end
  else if @IPVC_GroupStatus = 'READONLY'
  begin
    insert into #LT_QUOTEITEM_FINAL(familycode,familyname,measurecode,measurename,frequencycode,frequencyname,
                                    ilfmeasurecode,ilffrequencycode,productcode,productname,productdisplayname,
                                    publicationyear,publicationquarter,mpfpublicationtype,mpfpublicationflag,
                                    ilfdiscountmaxpercent,accessdiscountmaxpercent,
                                    quantity,quantityenabledflag,explodequantityatorderflag,
                                    listpriceilf,
                                    listpriceaccess,
                                    ilfnetprice,accessnetprice,
                                    priceversion,
                                    optionflag,ilfminunits,ilfmaxunits,acsminunits,acsmaxunits,
                                    ilfcapmaxunitsflag,acscapmaxunitsflag,
                                    acsdollarminimum,ilfdollarminimum,acsdollarminimumenabledflag,ilfdollarminimumenabledflag,
                                    acsdollarmaximum,ilfdollarmaximum,acsdollarmaximumenabledflag,ilfdollarmaximumenabledflag,
                                    acsleaddays,
                                    creditcardpercentageenabledflag,credtcardpricingpercentage,
                                    sortseq,socflag,isselected,
                                    socexcludeforbookingsflag,excludeforbookingsflag,
                                    crossfirecallpricingenabledflag,crossfiremaximumallowablecallvolume,  
                                    stockbundleflag,autofulfillflag,internalgroupid,prepaidflag)
    select distinct ltrim(rtrim(P.FamilyCode))                                                       as familycode,
                    ltrim(rtrim(F.Name))                                                             as familyname,
                    ltrim(rtrim(QACS.MeasureCode))                                                   as measurecode,
                    ltrim(rtrim(M.Name))                                                             as measurename, 
                    ltrim(rtrim(QACS.FrequencyCode))                                                 as frequencycode,
                    ltrim(rtrim(FR.Name))                                                            as frequencyname, 
 
                    ltrim(rtrim(Coalesce(QILF.MeasureCode,'')))                                      as ilfmeasurecode,
                    ltrim(rtrim(Coalesce(QILF.FrequencyCode,'')))                                    as ilffrequencycode,
                 
                    ltrim(rtrim(P.Code))                                                             as productcode, 
                    ltrim(rtrim(P.name))                                                             as productname,
                    ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                    Coalesce(QACS.publicationyear,'')                                                as publicationyear,
                    Coalesce(QACS.publicationquarter,'')                                             as publicationquarter,
                    /*(case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                            then 'Yearly'
                         when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                            then 'Quarterly'
                         else ''
                     end
                    )                                                                                as mpfpublicationtype,*/
                    coalesce(CACS.mpfpublicationName,'')                                             as mpfpublicationtype,
                    P.mpfpublicationflag                                                             as mpfpublicationflag,

                    0.00                                                                             as ilfdiscountmaxpercent,
                    0.00                                                                             as accessdiscountmaxpercent,                    
                    (case when (coalesce(CACS.quantityenabledflag,0) = 1 and coalesce(CACS.explodequantityatorderflag,0)=1)
                             then convert(varchar(50),convert(decimal(18,0),coalesce(QACS.quantity,1)))
                          when (coalesce(CACS.quantityenabledflag,0) = 1 and coalesce(CACS.explodequantityatorderflag,0)=0)
                             then convert(varchar(50),convert(decimal(18,3),coalesce(QACS.quantity,1.00)))
                          else convert(varchar(50),convert(decimal(18,0),coalesce(QACS.quantity,1)))
                     end
                    )                                                                                as quantity,                     
                    coalesce(CACS.quantityenabledflag,0)                                             as quantityenabledflag,
                    coalesce(CACS.explodequantityatorderflag,0)                                      as explodequantityatorderflag,
                    coalesce(QILF.ChargeAmount,QILF.ChargeAmount,0)                                  as listpriceilf,
                    coalesce(QACS.ChargeAmount,QACS.ChargeAmount,0)                                  as listpriceaccess,
                    coalesce(QILF.NetChargeAmount,QILF.ChargeAmount,0)                               as ilfnetprice,
                    coalesce(QACS.NetChargeAmount,QACS.ChargeAmount,0)                               as accessnetprice,  
                    QACS.PriceVersion                                                                as priceversion,
                    P.optionflag                                                                     as optionflag,
                    coalesce(QILF.minunits,0)                                                        as ilfminunits,
                    coalesce(QILF.maxunits,0)                                                        as ilfmaxunits,
                    coalesce(QACS.minunits,0)                                                        as acsminunits,
                    coalesce(QACS.maxunits,0)                                                        as acsmaxunits,
                    coalesce(QILF.capmaxunitsflag,0)                                                 as ilfcapmaxunitsflag,
                    coalesce(QACS.capmaxunitsflag,0)                                                 as acscapmaxunitsflag,

                    coalesce(QACS.dollarminimum,0)                                                   as acsdollarminimum,
                    coalesce(QILF.dollarminimum,0)                                                   as ilfdollarminimum,
                    coalesce(CACS.dollarminimumenabledflag,0)                                        as acsdollarminimumenabledflag,
                    coalesce(CILF.dollarminimumenabledflag,0)                                        as ilfdollarminimumenabledflag,
                    coalesce(QACS.dollarmaximum,0)                                                   as acsdollarmaximum,
                    coalesce(QILF.dollarmaximum,0)                                                   as ilfdollarmaximum,
                    coalesce(CACS.dollarmaximumenabledflag,0)                                        as acsdollarmaximumenabledflag,
                    coalesce(CILF.dollarmaximumenabledflag,0)                                        as ilfdollarmaximumenabledflag,

                    coalesce(CACS.LeadDays,0)                                                        as acsleaddays,
            
                    (case when ((coalesce(CACS.creditcardpercentageenabledflag,0)=1) or
                                (coalesce(CILF.creditcardpercentageenabledflag,0)=1)
                               )
                           then 1
                          else  0
                     end
                     )                                                                               as creditcardpercentageenabledflag,
                    (case when (coalesce(CACS.creditcardpercentageenabledflag,0)=1)
                             then coalesce(QACS.credtcardpricingpercentage,0.00)
                          when (coalesce(CILF.creditcardpercentageenabledflag,0)=1)
                             then coalesce(QILF.credtcardpricingpercentage,0.00)
                          else 0.00
                     end
                    )                                                                                as credtcardpricingpercentage,

                    P.sortseq                                                                        as sortseq,
                    P.socflag                                                                        as socflag,
                    (Case when QACS.Productcode is not null then 1 else 0 end)                       as isselected,

                    P.excludeforbookingsflag                                                         as socexcludeforbookingsflag,
                    (case when P.excludeforbookingsflag = 1 then 1 
                          else coalesce(QACS.excludeforbookingsflag,P.excludeforbookingsflag,0)
                     end
                    )                                                                                as excludeforbookingsflag,
                    CACS.crossfirecallpricingenabledflag                                             as crossfirecallpricingenabledflag,
                    coalesce(QACS.crossfiremaximumallowablecallvolume,0)                             as crossfiremaximumallowablecallvolume,


                    P.stockbundleflag                                                                as stockbundleflag,
                    convert(int,P.autofulfillflag)                                                   as autofulfillflag,
                    @IPI_InternalGroupID                                                             as internalgroupid,
                    P.prepaidflag                                                                    as prepaidflag
    from    PRODUCTS.dbo.Product P with (nolock)
    inner join
            PRODUCTS.dbo.Family F  with (nolock)
    on      P.FamilyCode = F.Code     
    inner join 
            Quotes.dbo.Quoteitem QACS with (nolock)
    on      QACS.GroupIDSeq     = @IPI_GroupID
    and     QACS.QuoteIDSeq     = @IPVC_quoteid 
    and     QACS.ProductCode    = P.Code
    and     QACS.PriceVersion   = P.PriceVersion    
    and     QACS.ChargeTypeCode = 'ACS'   
    inner join
            Products.dbo.Charge CACS with (nolock)
    on      P.Code              = CACS.ProductCode
    and     P.PriceVersion      = CACS.PriceVersion
    and     QACS.ProductCode    = CACS.ProductCode
    and     QACS.PriceVersion   = CACS.PriceVersion               
    and     QACS.measurecode    = CACS.measurecode
    and     QACS.Frequencycode  = CACS.Frequencycode
    and     QACS.ChargeTypeCode = CACS.ChargeTypeCode
    and     CACS.ChargeTypeCode = 'ACS' 
    inner join 
           PRODUCTS.dbo.Measure M  with (nolock)
    ON     QACS.MeasureCode    = M.Code         
    inner join  PRODUCTS.dbo.Frequency FR with (nolock)
    ON     QACS.FrequencyCode  = FR.Code        
    left outer join 
           Quotes.dbo.Quoteitem QILF with (nolock)
    on     QILF.GroupIDSeq     = @IPI_GroupID
    and    QILF.QuoteIDSeq     = @IPVC_quoteid
    and    QILF.ProductCode    = QACS.ProductCode
    and    QILF.PriceVersion   = QACS.PriceVersion
    and    QILF.ProductCode    = P.Code 
    and    QILF.PriceVersion   = P.PriceVersion    
    and    QILF.ChargeTypeCode = 'ILF'    
    left outer join 
           Products.dbo.Charge CILF with (nolock)
    on     P.Code              = CILF.ProductCode
    and    P.PriceVersion      = CILF.PriceVersion    
    and    CILF.ChargeTypeCode = 'ILF'
    and    CACS.ProductCode    = CILF.ProductCode
    and    CACS.PriceVersion   = CILF.PriceVersion
    and    QILF.ProductCode    = CILF.ProductCode
    and    QILF.measurecode    = CILF.measurecode
    and    QILF.Frequencycode  = CILF.Frequencycode
    and    QILF.ChargeTypeCode = CILF.ChargeTypeCode
    Order by P.sortseq asc,isselected desc,measurename asc,frequencyname asc
    -------------------------------------------------------------------------------------
    insert into #LT_QUOTEITEM_FINAL(familycode,familyname,measurecode,measurename,frequencycode,frequencyname,
                                    ilfmeasurecode,ilffrequencycode,productcode,productname,productdisplayname,
                                    publicationyear,publicationquarter,mpfpublicationtype,mpfpublicationflag,
                                    ilfdiscountmaxpercent,accessdiscountmaxpercent,
                                    quantity,quantityenabledflag,explodequantityatorderflag,
                                    listpriceilf,
                                    listpriceaccess,
                                    ilfnetprice,accessnetprice,
                                    priceversion,
                                    optionflag,ilfminunits,ilfmaxunits,acsminunits,acsmaxunits,
                                    ilfcapmaxunitsflag,acscapmaxunitsflag,
                                    acsdollarminimum,ilfdollarminimum,acsdollarminimumenabledflag,ilfdollarminimumenabledflag,
                                    acsdollarmaximum,ilfdollarmaximum,acsdollarmaximumenabledflag,ilfdollarmaximumenabledflag,
                                    creditcardpercentageenabledflag,credtcardpricingpercentage,
                                    sortseq,socflag,isselected,
                                    socexcludeforbookingsflag,excludeforbookingsflag,
                                    crossfirecallpricingenabledflag,crossfiremaximumallowablecallvolume,
                                    stockbundleflag,autofulfillflag,internalgroupid,prepaidflag)
    select distinct ltrim(rtrim(P.FamilyCode))                                                       as familycode,
                    ltrim(rtrim(F.Name))                                                             as familyname,
                    ltrim(rtrim(QILF.MeasureCode))                                                   as measurecode,
                    ltrim(rtrim(M.Name))                                                             as measurename, 
                    ltrim(rtrim(QILF.FrequencyCode))                                                 as frequencycode,
                    ltrim(rtrim(FR.Name))                                                            as frequencyname, 
  
                    ltrim(rtrim(Coalesce(QILF.MeasureCode,'')))                                      as ilfmeasurecode,
                    ltrim(rtrim(Coalesce(QILF.FrequencyCode,'')))                                    as ilffrequencycode,
                 
                    ltrim(rtrim(P.Code))                                                             as productcode, 
                    ltrim(rtrim(P.name))                                                             as productname,
                    ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                    Coalesce(QILF.publicationyear,'')                                                as publicationyear,
                    Coalesce(QILF.publicationquarter,'')                                             as publicationquarter,
                    /*(case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                            then 'Yearly'
                         when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                            then 'Quarterly'
                         else ''
                     end
                    )                                                                                as mpfpublicationtype,*/
                    coalesce(CILF.mpfpublicationName,'')                                             as mpfpublicationtype,
                    P.mpfpublicationflag                                                             as mpfpublicationflag,

                    0.00                                                                             as ilfdiscountmaxpercent,
                    0.00                                                                             as accessdiscountmaxpercent,                    
                    (case when (coalesce(CILF.quantityenabledflag,0) = 1 and coalesce(CILF.explodequantityatorderflag,0)=1)
                             then convert(varchar(50),convert(decimal(18,0),coalesce(QILF.quantity,1)))
                          when (coalesce(CILF.quantityenabledflag,0) = 1 and coalesce(CILF.explodequantityatorderflag,0)=0)
                             then convert(varchar(50),convert(decimal(18,3),coalesce(QILF.quantity,1.000)))
                          else convert(varchar(50),convert(decimal(18,0),coalesce(QILF.quantity,1)))
                     end
                    )                                                                                as quantity,                        
                    coalesce(CILF.quantityenabledflag,0)                                             as quantityenabledflag,
                    coalesce(CILF.explodequantityatorderflag,0)                                      as explodequantityatorderflag,
                    coalesce(QILF.ChargeAmount,QILF.ChargeAmount,0)                                  as listpriceilf,
                    0                                                                                as listpriceaccess,
                    coalesce(QILF.NetChargeAmount,QILF.ChargeAmount,0)                               as ilfnetprice,
                    0                                                                                as accessnetprice,  
                    QILF.PriceVersion                                                                as priceversion,
                    P.optionflag                                                                     as optionflag,
                    coalesce(QILF.minunits,0)                                                        as ilfminunits,
                    coalesce(QILF.maxunits,0)                                                        as ilfmaxunits,
                    0                                                                                as acsminunits,
                    0                                                                                as acsmaxunits,
                    coalesce(QILF.capmaxunitsflag,0)                                                 as ilfcapmaxunitsflag,
                    0                                                                                as acscapmaxunitsflag,

                    0                                                                                as acsdollarminimum,
                    coalesce(QILF.dollarminimum,0)                                                   as ilfdollarminimum,
                    0                                                                                as acsdollarminimumenabledflag,
                    coalesce(CILF.dollarminimumenabledflag,0)                                        as ilfdollarminimumenabledflag,
                    0                                                                                as acsdollarmaximum,
                    coalesce(QILF.dollarmaximum,0)                                                   as ilfdollarmaximum,
                    0                                                                                as acsdollarmaximumenabledflag,
                    coalesce(CILF.dollarmaximumenabledflag,0)                                        as ilfdollarmaximumenabledflag,

                    (case when (coalesce(CILF.creditcardpercentageenabledflag,0)=1)                               
                           then 1
                          else  0
                     end
                     )                                                                               as creditcardpercentageenabledflag,
                    (case when (coalesce(CILF.creditcardpercentageenabledflag,0)=1)
                             then coalesce(QILF.credtcardpricingpercentage,0.00)
                          else 0.00
                     end
                    )                                                                                as credtcardpricingpercentage,

                    P.sortseq                                                                        as sortseq,
                    P.socflag                                                                        as socflag,
                    (Case when QILF.Productcode is not null then 1 else 0 end)                       as isselected,

                    P.excludeforbookingsflag                                                         as socexcludeforbookingsflag,
                    (case when P.excludeforbookingsflag = 1 then 1 
                          else coalesce(QILF.excludeforbookingsflag,P.excludeforbookingsflag,0)
                     end
                    )                                                                                as excludeforbookingsflag,
                    CILF.crossfirecallpricingenabledflag                                             as crossfirecallpricingenabledflag,
                    coalesce(QILF.crossfiremaximumallowablecallvolume,0)                             as crossfiremaximumallowablecallvolume,


                    P.stockbundleflag                                                                as stockbundleflag,
                    convert(int,P.autofulfillflag)                                                   as autofulfillflag,
                    @IPI_InternalGroupID                                                             as internalgroupid,
                    P.prepaidflag                                                                    as prepaidflag
    from    PRODUCTS.dbo.Product P with (nolock)
    inner join
            PRODUCTS.dbo.Family F  with (nolock)
    on      P.FamilyCode = F.Code     
    and  not exists (select TOP 1 X.ProductCode as ProductCode
                     from   #LT_QUOTEITEM_FINAL X
                     where  X.productcode = P.Code
                    )
    inner join 
           Quotes.dbo.Quoteitem QILF with (nolock)
    on     QILF.GroupIDSeq     = @IPI_GroupID
    and    QILF.QuoteIDSeq     = @IPVC_quoteid
    and    QILF.ProductCode    = P.code
    and    QILF.PriceVersion   = P.PriceVersion    
    and    QILF.ChargeTypeCode = 'ILF'        
    and  not exists (select TOP 1 X.ProductCode as ProductCode
                     from   #LT_QUOTEITEM_FINAL X
                     where  QILF.ProductCode = X.productcode                   
                    )
    inner join
           Products.dbo.Charge CILF with (nolock)
    on     P.Code              = CILF.ProductCode
    and    P.PriceVersion      = CILF.PriceVersion 
    and    QILF.PriceVersion   = CILF.PriceVersion  
    and    CILF.ChargeTypeCode = 'ILF'  
    and    QILF.ProductCode    = CILF.ProductCode
    and    QILF.measurecode    = CILF.measurecode
    and    QILF.Frequencycode  = CILF.Frequencycode
    and    QILF.ChargeTypeCode = CILF.ChargeTypeCode  
    inner join 
           PRODUCTS.dbo.Measure M with (nolock)
    ON     QILF.MeasureCode = M.Code    
    inner join  PRODUCTS.dbo.Frequency FR with (nolock)
    ON     QILF.FrequencyCode = FR.Code                
    Order by P.sortseq asc,isselected desc,measurename asc,frequencyname asc
  end
  -----------------------------------------------------------------------------------------
  --Final Select 
  -----------------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin    
      SELECT  F.code                                                           as familycode,
              F.name					                     as familyname,								
             (select distinct  
                     Z.familycode                                                  as familycode,
                     Z.familyname                                                  as familyname,
                     Z.measurecode                                                 as measurecode,
                     Z.measurename                                                 as measurename,
                     Z.frequencycode                                               as frequencycode,
                     Z.frequencyname                                               as frequencyname,
                     Z.ilfmeasurecode                                              as ilfmeasurecode,
                     Z.ilffrequencycode                                            as ilffrequencycode,
                     Z.productcode                                                 as productcode,
                     Z.productname                                                 as productname,
                     Z.productdisplayname                                          as productdisplayname,
                     Z.publicationyear                                             as publicationyear,
                     Z.publicationquarter                                          as publicationquarter,
                     Z.mpfpublicationtype                                          as mpfpublicationtype,
                     Z.mpfpublicationflag                                          as mpfpublicationflag,
                     Quotes.DBO.fn_FormatCurrency(Z.ilfdiscountmaxpercent,1,3)     as ilfdiscountmaxpercent,
                     Quotes.DBO.fn_FormatCurrency(Z.accessdiscountmaxpercent,1,3)  as accessdiscountmaxpercent,
                     Z.quantity                                                    as quantity,
                     Z.quantityenabledflag                                         as quantityenabledflag,
                     Z.explodequantityatorderflag                                  as explodequantityatorderflag,
                     Quotes.DBO.fn_FormatCurrency(Z.listpriceilf,1,2)              as listpriceilf,
                     --Quotes.DBO.fn_FormatCurrency(Z.ilfdiscountpercent,1,3)        as ilfdiscountpercent,
                     Z.ilfdiscountpercent                                          as ilfdiscountpercent,
                     Quotes.DBO.fn_FormatCurrency(Z.listpriceaccess,1,2)           as listpriceaccess,
                     --Quotes.DBO.fn_FormatCurrency(Z.accessdiscountpercent,1,3)     as accessdiscountpercent,
                     Z.accessdiscountpercent                                       as accessdiscountpercent,
                     Quotes.DBO.fn_FormatCurrency(Z.ilfnetprice,1,2)               as ilfnetprice,
                     Quotes.DBO.fn_FormatCurrency(Z.accessnetprice,1,2)            as accessnetprice,
                     Z.priceversion                                                as priceversion,
                     Z.optionflag                                                  as optionflag,
                     Z.ilfminunits                                                 as ilfminunits,
                     Z.ilfmaxunits                                                 as ilfmaxunits,
                     Z.acsminunits                                                 as acsminunits,
                     Z.acsmaxunits                                                 as acsmaxunits,
                     Z.ilfcapmaxunitsflag                                          as ilfcapmaxunitsflag,
                     Z.acscapmaxunitsflag                                          as acscapmaxunitsflag,
                     Z.acsdollarminimum                                            as acsdollarminimum,
                     Z.ilfdollarminimum                                            as ilfdollarminimum,
                     Z.acsdollarminimumenabledflag                                 as acsdollarminimumenabledflag,
                     Z.ilfdollarminimumenabledflag                                 as ilfdollarminimumenabledflag,
                     Z.acsdollarmaximum                                            as acsdollarmaximum,
                     Z.ilfdollarmaximum                                            as ilfdollarmaximum,
                     Z.acsdollarmaximumenabledflag                                 as acsdollarmaximumenabledflag,
                     Z.ilfdollarmaximumenabledflag                                 as ilfdollarmaximumenabledflag,
                     Z.acsleaddays                                                 as acsleaddays,
                     Z.creditcardpercentageenabledflag                             as creditcardpercentageenabledflag,
                     Z.credtcardpricingpercentage                                  as credtcardpricingpercentage,
                     Z.sortseq                                                     as sortseq,
                     Z.socflag                                                     as socflag,
                     Z.isselected                                                  as isselected,
                     Z.socexcludeforbookingsflag                                   as socexcludeforbookingsflag,
                     Z.excludeforbookingsflag                                      as excludeforbookingsflag, 
                     Z.crossfirecallpricingenabledflag                             as crossfirecallpricingenabledflag,
                     Z.crossfiremaximumallowablecallvolume                         as crossfiremaximumallowablecallvolume,
                     Z.stockbundleflag                                             as stockbundleflag,
                     Z.autofulfillflag                                             as autofulfillflag,
                     Z.internalgroupid                                             as internalgroupid,
                     Z.prepaidflag                                                 as prepaidflag
              from #LT_QUOTEITEM_FINAL Z with (nolock)
              where Z.familycode = f.code              
              order by Z.productdisplayname asc, Z.sortseq asc,Z.isselected desc,Z.measurename asc,Z.frequencyname asc
              for xml raw ,root('familyproducts'),type
              )
      from products.dbo.family f  with (nolock)  
      where exists (select top 1 1
                    from   Products.dbo.Product P with (nolock)
                    where  P.FamilyCode = F.Code
                    and    P.prepaidflag= @IPI_PrePaidFlag 
                   )
      for xml raw ,root('products'), type 
  end
  else
  begin
    select distinct  
                   Z.familycode                                                  as familycode,
                   Z.familyname                                                  as familyname,
                   Z.measurecode                                                 as measurecode,
                   Z.measurename                                                 as measurename,
                   Z.frequencycode                                               as frequencycode,
                   Z.frequencyname                                               as frequencyname,
                   Z.ilfmeasurecode                                              as ilfmeasurecode,
                   Z.ilffrequencycode                                            as ilffrequencycode,
                   Z.productcode                                                 as productcode,
                   Z.productname                                                 as productname,
                   Z.productdisplayname                                          as productdisplayname,
                   Z.publicationyear                                             as publicationyear,
                   Z.publicationquarter                                          as publicationquarter,
                   Z.mpfpublicationtype                                          as mpfpublicationtype,
                   Z.mpfpublicationflag                                          as mpfpublicationflag,
                   Quotes.DBO.fn_FormatCurrency(Z.ilfdiscountmaxpercent,1,3)     as ilfdiscountmaxpercent,
                   Quotes.DBO.fn_FormatCurrency(Z.accessdiscountmaxpercent,1,3)  as accessdiscountmaxpercent,
                   Z.quantity                                                    as quantity,
                   Z.quantityenabledflag                                         as quantityenabledflag,
                   Z.explodequantityatorderflag                                  as explodequantityatorderflag,
                   Quotes.DBO.fn_FormatCurrency(Z.listpriceilf,1,2)              as listpriceilf,
                   --Quotes.DBO.fn_FormatCurrency(Z.ilfdiscountpercent,1,3)      as ilfdiscountpercent,
                   Z.ilfdiscountpercent                                          as ilfdiscountpercent,
                   Quotes.DBO.fn_FormatCurrency(Z.listpriceaccess,1,2)           as listpriceaccess,
                   --Quotes.DBO.fn_FormatCurrency(Z.accessdiscountpercent,1,3)   as accessdiscountpercent,
                   Z.accessdiscountpercent                                       as accessdiscountpercent,
                   Quotes.DBO.fn_FormatCurrency(Z.ilfnetprice,1,2)               as ilfnetprice,
                   Quotes.DBO.fn_FormatCurrency(Z.accessnetprice,1,2)            as accessnetprice,
                   Z.priceversion                                                as priceversion,
                   Z.optionflag                                                  as optionflag,
                   Z.ilfminunits                                                 as ilfminunits,
                   Z.ilfmaxunits                                                 as ilfmaxunits,
                   Z.acsminunits                                                 as acsminunits,
                   Z.acsmaxunits                                                 as acsmaxunits,
                   Z.ilfcapmaxunitsflag                                          as ilfcapmaxunitsflag,
                   Z.acscapmaxunitsflag                                          as acscapmaxunitsflag,
                   Z.acsdollarminimum                                            as acsdollarminimum,
                   Z.ilfdollarminimum                                            as ilfdollarminimum,
                   Z.acsdollarminimumenabledflag                                 as acsdollarminimumenabledflag,
                   Z.ilfdollarminimumenabledflag                                 as ilfdollarminimumenabledflag,
                   Z.acsdollarmaximum                                            as acsdollarmaximum,
                   Z.ilfdollarmaximum                                            as ilfdollarmaximum,
                   Z.acsdollarmaximumenabledflag                                 as acsdollarmaximumenabledflag,
                   Z.ilfdollarmaximumenabledflag                                 as ilfdollarmaximumenabledflag,
                   Z.acsleaddays                                                 as acsleaddays,
                   Z.creditcardpercentageenabledflag                             as creditcardpercentageenabledflag,
                   Z.credtcardpricingpercentage                                  as credtcardpricingpercentage,
                   Z.sortseq                                                     as sortseq,
                   Z.socflag                                                     as socflag,
                   Z.isselected                                                  as isselected,
                   Z.socexcludeforbookingsflag                                   as socexcludeforbookingsflag,
                   Z.excludeforbookingsflag                                      as excludeforbookingsflag, 
                   Z.crossfirecallpricingenabledflag                             as crossfirecallpricingenabledflag,
                   Z.crossfiremaximumallowablecallvolume                         as crossfiremaximumallowablecallvolume,
                   Z.stockbundleflag                                             as stockbundleflag,
                   Z.autofulfillflag                                             as autofulfillflag,
                   Z.internalgroupid                                             as internalgroupid,
                   Z.prepaidflag                                                 as prepaidflag
    from #LT_QUOTEITEM_FINAL Z with (nolock)    
    order by Z.productdisplayname asc, Z.sortseq asc,Z.isselected desc,Z.measurename asc,Z.frequencyname asc
  end
  --------------------------------------------------------------------------------
  -- Final Cleanup
  if (object_id('tempdb.dbo.#LT_QUOTEITEM_FINAL') is not null) 
  begin
    drop table #LT_QUOTEITEM_FINAL;
  end; 
  --------------------------------------------------------------------------------
END
GO
