SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec uspQUOTES_GetGroupDetailProductsTEST @IPC_CompanyID = 'A0000000001',@IPVC_quoteid=2,@IPI_GroupID =1,
                                        @IPVC_GroupType = 'PMC1',@IPVC_RETURNTYPE = 'RECORDSET'
*/
CREATE PROCEDURE [quotes].[uspQUOTES_GetGroupDetailProductsTEST] (@IPC_CompanyID        char(11),
                                                           @IPVC_quoteid             varchar(50) = '0', 
                                                           @IPI_GroupID              bigint = 0,
                                                           @IPVC_GroupType           varchar(70)  = NULL, 
                                                           @IPVC_FamilyCode          varchar(50)  = '',                                                       
                                                           @IPI_InternalGroupID      varchar(100) = '', 
                                                           @IPVC_GroupStatus         varchar(50)  = 'EDIT',
                                                           @IPVC_RETURNTYPE          varchar(100) = 'XML')
AS
BEGIN
  set nocount on   
  select @IPC_CompanyID = ltrim(rtrim(@IPC_CompanyID))
  --------------------------------------------------------------------------------------------  
  declare @LT_DisplayType     TABLE (displaytype  varchar(20))   

  declare @LT_QUOTEITEM_FINAL TABLE
              (seq                      int           not null   identity(1,1),                              
               measurecode              varchar(10)   not null default '',
               measurename              varchar(50)   not null default '',
               frequencycode            varchar(10)   not null default '',
               frequencyname            varchar(50)   not null default '',
              
               ilfmeasurecode           varchar(10)   null,
               ilffrequencycode         varchar(10)   null,

               familycode               varchar(3)    not null default '',
               familyname               varchar(50)   not null default '',
               productcode              varchar(50)   not null default '',
               productname              varchar(200)  not null default '',
               productdisplayname       varchar(200)  not null default '',

               publicationyear          varchar(100)  not null default '', 
               publicationquarter       varchar(100)  not null default '',
               mpfpublicationtype       varchar(100)  not null default '',

               ilfdiscountmaxpercent    numeric(30,5) not null default 0.00,
               accessdiscountmaxpercent numeric(30,5) not null default 0.00,

               quantity                 varchar(50)   not null default 1,
               quantityenabledflag      int           not null default 0,
 
               listpriceilf             money         not null default 0,
               listpriceaccess          money         not null default 0,  
             
               ilfdiscountpercent       numeric(30,5) not null default 0.00,
               accessdiscountpercent    numeric(30,5) not null default 0.00,

               ilfdiscountamount        money         not null default 0,
               accessdiscountamount     money         not null default 0,      
        
               ilfnetprice              money         not null default 0,
               accessnetprice           money         not null default 0,

               
               priceversion             numeric(18,0) not null default 0,
               optionflag               bit           not null default 0,              
               isselected               int           not null default 0,
               sortseq                  int           not null default 0,
               socflag                  int           not null default 1,               
               minunits                 int           not null default 100,
               maxunits                 int           not null default 500,                           
               internalgroupid          varchar(100)  not null default ''
               )    
  -------------------------------------------------------------------------------------------- 
  if exists (select top 1  1 from   QUOTES.dbo.[Group] S (nolock)
             where   S.IDSeq        = @IPI_GroupID     
             and     S.QuoteIDSeq   = @IPVC_quoteid
            )
  begin
    select  @IPVC_GroupType = S.grouptype             
    from    QUOTES.dbo.[Group] S (nolock)
    where   S.IDSeq        = @IPI_GroupID     
    and     S.QuoteIDSeq   = @IPVC_quoteid    
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
  if (@IPVC_GroupStatus <> 'READONLY')
  begin
    insert into @LT_QUOTEITEM_FINAL(familycode,familyname,measurecode,measurename,frequencycode,frequencyname,
                                    ilfmeasurecode,ilffrequencycode,productcode,productname,productdisplayname,
                                    publicationyear,publicationquarter,mpfpublicationtype,
                                    ilfdiscountmaxpercent,accessdiscountmaxpercent,
                                    quantity,quantityenabledflag,
                                    listpriceilf,ilfdiscountpercent,
                                    listpriceaccess,accessdiscountpercent,
                                    ilfnetprice,accessnetprice,
                                    priceversion,
                                    optionflag,minunits,maxunits,
                                    sortseq,socflag,isselected,internalgroupid)
    select distinct ltrim(rtrim(P.FamilyCode))                                                       as familycode,
                    ltrim(rtrim(F.Name))                                                             as familyname,
                    ltrim(rtrim(CACS.MeasureCode))                                                   as measurecode,
                    ltrim(rtrim(M.Name))                                                             as measurename, 
                    ltrim(rtrim(CACS.FrequencyCode))                                                 as frequencycode,
                    ltrim(rtrim(FR.Name))                                                            as frequencyname, 
 
                    ltrim(rtrim(CILF.MeasureCode))                                                   as ilfmeasurecode,
                    ltrim(rtrim(CILF.FrequencyCode))                                                 as ilffrequencycode,
                 
                    ltrim(rtrim(P.Code))                                                             as productcode, 
                    ltrim(rtrim(P.name))                                                             as productname,
                    ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                    Coalesce(QACS.publicationyear,'')                                                as publicationyear,
                    Coalesce(QACS.publicationquarter,'')                                             as publicationquarter,
                    (case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                            then 'Yearly'
                         when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                            then 'Quarterly'
                         else ''
                     end
                    )                                                                                as mpfpublicationtype,
                    coalesce(CILF.DiscountMaxPercent,0.00)                                           as ilfdiscountmaxpercent,
                    coalesce(CACS.DiscountMaxPercent,0.00)                                           as accessdiscountmaxpercent,                    
                    coalesce(QACS.quantity,1)                                                        as quantity,
                    coalesce(CACS.quantityenabledflag,0)                                             as quantityenabledflag,
                    coalesce(QILF.ChargeAmount,CILF.ChargeAmount,0)                                  as listpriceilf,
                    coalesce(QILF.DiscountPercent,0.00)                                              as ilfdiscountpercent,
                    coalesce(QACS.ChargeAmount,CACS.ChargeAmount,0)                                  as listpriceaccess,
                    coalesce(QACS.DiscountPercent,0.00)                                              as accessdiscountpercent, 
                    coalesce(QILF.NetChargeAmount,CILF.ChargeAmount,0)                               as ilfnetprice,
                    coalesce(QACS.NetChargeAmount,CACS.ChargeAmount,0)                               as accessnetprice,  
                    CACS.PriceVersion                                                                as priceversion,
                    P.optionflag                                                                     as optionflag,
                    coalesce(QACS.minunits,CACS.minunits,100)                                        as minunits,
                    coalesce(QACS.maxunits,CACS.maxunits,100)                                        as maxunits,
                    P.sortseq                                                                        as sortseq,
                    P.socflag                                                                        as socflag,
                    (Case when QACS.Productcode is not null then 1 else 0 end)                       as isselected,
                    @IPI_InternalGroupID                                                             as internalgroupid
    from    PRODUCTS.dbo.Product P (nolock)
    inner join
            PRODUCTS.dbo.Family F  (nolock)
    on      P.FamilyCode = F.Code and P.DisabledFlag = 0
    and     PATINDEX('%'+@IPVC_FamilyCode+'%',P.FamilyCode) > 0
    inner join
            Products.dbo.Charge CACS with (nolock)
    on      P.Code = CACS.ProductCode
    and     CACS.ChargeTypeCode = 'ACS'
    and     CACS.DisplayType in (select displaytype from @LT_DisplayType)
    inner join 
           PRODUCTS.dbo.Measure M (nolock)
    ON     CACS.MeasureCode = M.Code 
    and    M.DisplayFlag = 1       
    inner join  PRODUCTS.dbo.Frequency FR(nolock)
    ON     CACS.FrequencyCode = FR.Code 
    and    FR.DisplayFlag = 1
    left outer join 
           Products.dbo.Charge CILF with (nolock)
    on     P.Code = CILF.ProductCode
    and    CILF.ChargeTypeCode = 'ILF'
    and    CACS.ProductCode  = CILF.ProductCode
    and    CACS.PriceVersion = CILF.PriceVersion
    and    CACS.DisplayType in (select displaytype from @LT_DisplayType)
    left outer join 
            Quotes.dbo.Quoteitem QACS with (nolock)
    on      QACS.ProductCode    = CACS.ProductCode
    and     QACS.measurecode    = CACS.measurecode
    and     QACS.Frequencycode  = CACS.Frequencycode
    and     QACS.ChargeTypeCode = CACS.ChargeTypeCode
    and     QACS.PriceVersion   = CACS.PriceVersion
    and     QACS.ChargeTypeCode = 'ACS'
    and     CACS.ChargeTypeCode = 'ACS'
    and     QACS.GroupIDSeq     = @IPI_GroupID
    and     QACS.QuoteIDSeq     = @IPVC_quoteid   
    left outer join 
            Quotes.dbo.Quoteitem QILF with (nolock)
    on      QILF.ProductCode    = CILF.ProductCode
    and     QILF.measurecode    = CILF.measurecode
    and     QILF.Frequencycode  = CILF.Frequencycode
    and     QILF.ChargeTypeCode = CILF.ChargeTypeCode
    and     QILF.PriceVersion   = CILF.PriceVersion
    and     QILF.ChargeTypeCode = 'ILF'
    and     QILF.ChargeTypeCode = 'ILF'
    and     QILF.GroupIDSeq     = @IPI_GroupID
    and     QILF.QuoteIDSeq     = @IPVC_quoteid
    Order by P.Sortseq asc
    --------------------------------------------------------------------  
    insert into @LT_QUOTEITEM_FINAL(familycode,familyname,measurecode,measurename,frequencycode,frequencyname,
                                    ilfmeasurecode,ilffrequencycode,productcode,productname,productdisplayname,
                                    publicationyear,publicationquarter,mpfpublicationtype,
                                    ilfdiscountmaxpercent,accessdiscountmaxpercent,
                                    quantity,quantityenabledflag,
                                    listpriceilf,ilfdiscountpercent,
                                    listpriceaccess,accessdiscountpercent,
                                    ilfnetprice,accessnetprice,
                                    priceversion,
                                    optionflag,minunits,maxunits,
                                    sortseq,socflag,isselected,internalgroupid)
    select distinct ltrim(rtrim(P.FamilyCode))                                                       as familycode,
                    ltrim(rtrim(F.Name))                                                             as familyname,
                    ltrim(rtrim(CILF.MeasureCode))                                                   as measurecode,
                    ltrim(rtrim(M.Name))                                                             as measurename, 
                    ltrim(rtrim(CILF.FrequencyCode))                                                 as frequencycode,
                    ltrim(rtrim(FR.Name))                                                            as frequencyname, 
  
                    ltrim(rtrim(CILF.MeasureCode))                                                   as ilfmeasurecode,
                    ltrim(rtrim(CILF.FrequencyCode))                                                 as ilffrequencycode,
                 
                    ltrim(rtrim(P.Code))                                                             as productcode, 
                    ltrim(rtrim(P.name))                                                             as productname,
                    ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                    Coalesce(QILF.publicationyear,'')                                                as publicationyear,
                    Coalesce(QILF.publicationquarter,'')                                             as publicationquarter,
                    (case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                            then 'Yearly'
                         when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                            then 'Quarterly'
                         else ''
                     end
                    )                                                                                as mpfpublicationtype,
                    coalesce(CILF.DiscountMaxPercent,0.00)                                           as ilfdiscountmaxpercent,
                    0.00                                                                             as accessdiscountmaxpercent,                    
                    coalesce(QILF.quantity,1)                                                        as quantity,
                    coalesce(CILF.quantityenabledflag,0)                                             as quantityenabledflag,
                    coalesce(QILF.ChargeAmount,CILF.ChargeAmount,0)                                  as listpriceilf,
                    coalesce(QILF.DiscountPercent,0.00)                                              as ilfdiscountpercent,
                    0                                                                                as listpriceaccess,
                    0.00                                                                             as accessdiscountpercent, 
                    coalesce(QILF.NetChargeAmount,CILF.ChargeAmount,0)                               as ilfnetprice,
                    0                                                                                as accessnetprice,  
                    CILF.PriceVersion                                                                as priceversion,
                    P.optionflag                                                                     as optionflag,
                    coalesce(QILF.minunits,CILF.minunits,100)                                        as minunits,
                    coalesce(QILF.maxunits,CILF.maxunits,100)                                        as maxunits,
                    P.sortseq                                                                        as sortseq,
                    P.socflag                                                                        as socflag,
                    (Case when QILF.Productcode is not null then 1 else 0 end)                       as isselected,
                    @IPI_InternalGroupID                                                             as internalgroupid
    from    PRODUCTS.dbo.Product P (nolock)
    inner join
            PRODUCTS.dbo.Family F  (nolock)
    on      P.FamilyCode = F.Code and P.DisabledFlag = 0
    and     PATINDEX('%'+@IPVC_FamilyCode+'%',P.FamilyCode) > 0
    and  not exists (select TOP 1 X.ProductCode as ProductCode
                     from   @LT_QUOTEITEM_FINAL X
                     where  P.Code = X.productcode                   
                    )
    inner join
           Products.dbo.Charge CILF with (nolock)
    on     P.Code = CILF.ProductCode
    and    CILF.ChargeTypeCode = 'ILF'
    and    CILF.DisplayType in (select displaytype from @LT_DisplayType)
    inner join 
           PRODUCTS.dbo.Measure M (nolock)
    ON     CILF.MeasureCode = M.Code 
    and    M.DisplayFlag = 1       
    inner join  PRODUCTS.dbo.Frequency FR(nolock)
    ON     CILF.FrequencyCode = FR.Code 
    and    FR.DisplayFlag = 1  
    left outer join 
           Quotes.dbo.Quoteitem QILF with (nolock)
    on      QILF.ProductCode    = CILF.ProductCode
    and     QILF.measurecode    = CILF.measurecode
    and     QILF.Frequencycode  = CILF.Frequencycode
    and     QILF.ChargeTypeCode = CILF.ChargeTypeCode
    and     QILF.PriceVersion   = CILF.PriceVersion
    and     QILF.ChargeTypeCode = 'ILF'
    and     CILF.ChargeTypeCode = 'ILF'
    and     QILF.GroupIDSeq     = @IPI_GroupID
    and     QILF.QuoteIDSeq     = @IPVC_quoteid
    Order by P.Sortseq asc
    ------------------------------------------------------------------------------------------------------
  end
  else if @IPVC_GroupStatus = 'READONLY'
  begin
    insert into @LT_QUOTEITEM_FINAL(familycode,familyname,measurecode,measurename,frequencycode,frequencyname,
                                    ilfmeasurecode,ilffrequencycode,productcode,productname,productdisplayname,
                                    publicationyear,publicationquarter,mpfpublicationtype,
                                    ilfdiscountmaxpercent,accessdiscountmaxpercent,
                                    quantity,quantityenabledflag,
                                    listpriceilf,ilfdiscountpercent,
                                    listpriceaccess,accessdiscountpercent,
                                    ilfnetprice,accessnetprice,
                                    priceversion,
                                    optionflag,minunits,maxunits,
                                    sortseq,socflag,isselected,internalgroupid)
    select distinct ltrim(rtrim(P.FamilyCode))                                                       as familycode,
                    ltrim(rtrim(F.Name))                                                             as familyname,
                    ltrim(rtrim(QACS.MeasureCode))                                                   as measurecode,
                    ltrim(rtrim(M.Name))                                                             as measurename, 
                    ltrim(rtrim(QACS.FrequencyCode))                                                 as frequencycode,
                    ltrim(rtrim(FR.Name))                                                            as frequencyname, 
 
                    ltrim(rtrim(QILF.MeasureCode))                                                   as ilfmeasurecode,
                    ltrim(rtrim(QILF.FrequencyCode))                                                 as ilffrequencycode,
                 
                    ltrim(rtrim(P.Code))                                                             as productcode, 
                    ltrim(rtrim(P.name))                                                             as productname,
                    ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                    Coalesce(QACS.publicationyear,'')                                                as publicationyear,
                    Coalesce(QACS.publicationquarter,'')                                             as publicationquarter,
                    (case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                            then 'Yearly'
                         when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                            then 'Quarterly'
                         else ''
                     end
                    )                                                                                as mpfpublicationtype,
                    0.00                                                                             as ilfdiscountmaxpercent,
                    0.00                                                                             as accessdiscountmaxpercent,                    
                    coalesce(QACS.quantity,1)                                                        as quantity,
                    coalesce(QACS.quantityenabledflag,0)                                             as quantityenabledflag,
                    coalesce(QILF.ChargeAmount,QILF.ChargeAmount,0)                                  as listpriceilf,
                    coalesce(QILF.DiscountPercent,0.00)                                              as ilfdiscountpercent,
                    coalesce(QACS.ChargeAmount,QACS.ChargeAmount,0)                                  as listpriceaccess,
                    coalesce(QACS.DiscountPercent,0.00)                                              as accessdiscountpercent, 
                    coalesce(QILF.NetChargeAmount,QILF.ChargeAmount,0)                               as ilfnetprice,
                    coalesce(QACS.NetChargeAmount,QACS.ChargeAmount,0)                               as accessnetprice,  
                    QACS.PriceVersion                                                                as priceversion,
                    P.optionflag                                                                     as optionflag,
                    coalesce(QACS.minunits,QACS.minunits,100)                                        as minunits,
                    coalesce(QACS.maxunits,QACS.maxunits,100)                                        as maxunits,
                    P.sortseq                                                                        as sortseq,
                    P.socflag                                                                        as socflag,
                    (Case when QACS.Productcode is not null then 1 else 0 end)                       as isselected,
                    @IPI_InternalGroupID                                                             as internalgroupid
    from    PRODUCTS.dbo.Product P (nolock)
    inner join
            PRODUCTS.dbo.Family F  (nolock)
    on      P.FamilyCode = F.Code  
    inner join 
            Quotes.dbo.Quoteitem QACS with (nolock)
    on      QACS.ProductCode    = P.Code    
    and     QACS.ChargeTypeCode = 'ACS'   
    and     QACS.GroupIDSeq     = @IPI_GroupID
    and     QACS.QuoteIDSeq     = @IPVC_quoteid 
    inner join 
           PRODUCTS.dbo.Measure M (nolock)
    ON     QACS.MeasureCode = M.Code         
    inner join  PRODUCTS.dbo.Frequency FR(nolock)
    ON     QACS.FrequencyCode = FR.Code      
    inner join 
            Quotes.dbo.Quoteitem QILF with (nolock)
    on      QILF.ProductCode    = QACS.ProductCode
    and     QILF.ProductCode    = P.Code    
    and     QILF.ChargeTypeCode = 'ILF'
    and     QILF.ChargeTypeCode = 'ILF'
    and     QILF.GroupIDSeq     = @IPI_GroupID
    and     QILF.QuoteIDSeq     = @IPVC_quoteid
    Order by P.Sortseq asc 
    -------------------------------------------------------------------------------------
    insert into @LT_QUOTEITEM_FINAL(familycode,familyname,measurecode,measurename,frequencycode,frequencyname,
                                    ilfmeasurecode,ilffrequencycode,productcode,productname,productdisplayname,
                                    publicationyear,publicationquarter,mpfpublicationtype,
                                    ilfdiscountmaxpercent,accessdiscountmaxpercent,
                                    quantity,quantityenabledflag,
                                    listpriceilf,ilfdiscountpercent,
                                    listpriceaccess,accessdiscountpercent,
                                    ilfnetprice,accessnetprice,
                                    priceversion,
                                    optionflag,minunits,maxunits,
                                    sortseq,socflag,isselected,internalgroupid)
    select distinct ltrim(rtrim(P.FamilyCode))                                                       as familycode,
                    ltrim(rtrim(F.Name))                                                             as familyname,
                    ltrim(rtrim(QILF.MeasureCode))                                                   as measurecode,
                    ltrim(rtrim(M.Name))                                                             as measurename, 
                    ltrim(rtrim(QILF.FrequencyCode))                                                 as frequencycode,
                    ltrim(rtrim(FR.Name))                                                            as frequencyname, 
  
                    ltrim(rtrim(QILF.MeasureCode))                                                   as ilfmeasurecode,
                    ltrim(rtrim(QILF.FrequencyCode))                                                 as ilffrequencycode,
                 
                    ltrim(rtrim(P.Code))                                                             as productcode, 
                    ltrim(rtrim(P.name))                                                             as productname,
                    ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                    Coalesce(QILF.publicationyear,'')                                                as publicationyear,
                    Coalesce(QILF.publicationquarter,'')                                             as publicationquarter,
                    (case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                            then 'Yearly'
                         when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                            then 'Quarterly'
                         else ''
                     end
                    )                                                                                as mpfpublicationtype,
                    0.00                                                                             as ilfdiscountmaxpercent,
                    0.00                                                                             as accessdiscountmaxpercent,                    
                    coalesce(QILF.quantity,1)                                                        as quantity,
                    coalesce(QILF.quantityenabledflag,0)                                             as quantityenabledflag,
                    coalesce(QILF.ChargeAmount,QILF.ChargeAmount,0)                                  as listpriceilf,
                    coalesce(QILF.DiscountPercent,0.00)                                              as ilfdiscountpercent,
                    0                                                                                as listpriceaccess,
                    0.00                                                                             as accessdiscountpercent, 
                    coalesce(QILF.NetChargeAmount,QILF.ChargeAmount,0)                               as ilfnetprice,
                    0                                                                                as accessnetprice,  
                    QILF.PriceVersion                                                                as priceversion,
                    P.optionflag                                                                     as optionflag,
                    coalesce(QILF.minunits,QILF.minunits,100)                                        as minunits,
                    coalesce(QILF.maxunits,QILF.maxunits,100)                                        as maxunits,
                    P.sortseq                                                                        as sortseq,
                    P.socflag                                                                        as socflag,
                    (Case when QILF.Productcode is not null then 1 else 0 end)                       as isselected,
                    @IPI_InternalGroupID                                                             as internalgroupid
    from    PRODUCTS.dbo.Product P (nolock)
    inner join
            PRODUCTS.dbo.Family F  (nolock)
    on      P.FamilyCode = F.Code and P.DisabledFlag = 0    
    and  not exists (select TOP 1 X.ProductCode as ProductCode
                     from   @LT_QUOTEITEM_FINAL X
                     where  P.Code = X.productcode                   
                    )
    inner join 
           Quotes.dbo.Quoteitem QILF with (nolock)
    on     QILF.ProductCode    = P.code    
    and    QILF.ChargeTypeCode = 'ILF'
    and    QILF.GroupIDSeq     = @IPI_GroupID
    and    QILF.QuoteIDSeq     = @IPVC_quoteid
    and  not exists (select TOP 1 X.ProductCode as ProductCode
                     from   @LT_QUOTEITEM_FINAL X
                     where  QILF.ProductCode = X.productcode                   
                    )
    inner join 
           PRODUCTS.dbo.Measure M (nolock)
    ON     QILF.MeasureCode = M.Code    
    inner join  PRODUCTS.dbo.Frequency FR(nolock)
    ON     QILF.FrequencyCode = FR.Code        
    Order by P.Sortseq asc
  end
  -----------------------------------------------------------------------------------------
  --Final Select 
  -----------------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    SELECT  F.code                                                       as familycode,
            F.Name					                 as familyname,								
           (select distinct  
                   Z.familycode                                            as familycode,
                   Z.familyname                                            as familyname,
                   Z.measurecode                                           as measurecode,
                   Z.measurename                                           as measurename,
                   Z.frequencycode                                         as frequencycode,
                   Z.frequencyname                                         as frequencyname,
                   Z.ilfmeasurecode                                        as ilfmeasurecode,
                   Z.ilffrequencycode                                      as ilffrequencycode,
                   Z.productcode                                           as productcode,
                   Z.productname                                           as productname,
                   Z.productdisplayname                                    as productdisplayname,
                   Z.publicationyear                                       as publicationyear,
                   Z.publicationquarter                                    as publicationquarter,
                   Z.mpfpublicationtype                                    as mpfpublicationtype,
                   Z.ilfdiscountmaxpercent                                 as ilfdiscountmaxpercent,
                   Z.accessdiscountmaxpercent                              as accessdiscountmaxpercent,
                   Z.quantity                                              as quantity,
                   Z.quantityenabledflag                                   as quantityenabledflag,
                   Z.listpriceilf                                          as listpriceilf,
                   Z.ilfdiscountpercent                                    as ilfdiscountpercent,
                   Z.listpriceaccess                                       as listpriceaccess,
                   Z.accessdiscountpercent                                 as accessdiscountpercent,
                   Z.ilfnetprice                                           as ilfnetprice,
                   Z.accessnetprice                                        as accessnetprice,
                   Z.priceversion                                          as priceversion,
                   Z.optionflag                                            as optionflag,
                   Z.minunits                                              as minunits,
                   Z.maxunits                                              as maxunits,
                   Z.sortseq                                               as sortseq,
                   Z.socflag                                               as socflag,
                   Z.isselected                                            as isselected,
                   Z.internalgroupid                                       as internalgroupid
            from @lt_quoteitem_final Z
            where Z.familycode = F.code 
            order by Z.sortseq asc,Z.isselected desc,Z.measurename asc,Z.frequencyname asc
            for xml raw ,root('familyproducts'),type
            )
    from Products.dbo.Family F (nolock)  
    for xml raw ,root('products'), type 
  end
  else
  begin
    select distinct  
                   Z.familycode                                            as familycode,
                   Z.familyname                                            as familyname,
                   Z.measurecode                                           as measurecode,
                   Z.measurename                                           as measurename,
                   Z.frequencycode                                         as frequencycode,
                   Z.frequencyname                                         as frequencyname,
                   Z.ilfmeasurecode                                        as ilfmeasurecode,
                   Z.ilffrequencycode                                      as ilffrequencycode,
                   Z.productcode                                           as productcode,
                   Z.productname                                           as productname,
                   Z.productdisplayname                                    as productdisplayname,
                   Z.publicationyear                                       as publicationyear,
                   Z.publicationquarter                                    as publicationquarter,
                   Z.mpfpublicationtype                                    as mpfpublicationtype,
                   Z.ilfdiscountmaxpercent                                 as ilfdiscountmaxpercent,
                   Z.accessdiscountmaxpercent                              as accessdiscountmaxpercent,
                   Z.quantity                                              as quantity,
                   Z.quantityenabledflag                                   as quantityenabledflag,
                   Z.listpriceilf                                          as listpriceilf,
                   Z.ilfdiscountpercent                                    as ilfdiscountpercent,
                   Z.listpriceaccess                                       as listpriceaccess,
                   Z.accessdiscountpercent                                 as accessdiscountpercent,
                   Z.ilfnetprice                                           as ilfnetprice,
                   Z.accessnetprice                                        as accessnetprice,
                   Z.priceversion                                          as priceversion,
                   Z.optionflag                                            as optionflag,
                   Z.minunits                                              as minunits,
                   Z.maxunits                                              as maxunits,
                   Z.sortseq                                               as sortseq,
                   Z.socflag                                               as socflag,
                   Z.isselected                                            as isselected,
                   Z.internalgroupid                                       as internalgroupid
    from @lt_quoteitem_final Z
    order by Z.sortseq asc,Z.isselected desc,Z.measurename asc,Z.frequencyname asc
  end
END
GO
