SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec uspQUOTES_GetGroupDetailProducts @IPC_CompanyID = 'A0000000001',@IPVC_quoteid=2,@IPI_GroupID =1,
                                        @IPVC_GroupType = 'PMC1',@IPVC_RETURNTYPE = 'RECORDSET'
*/
CREATE PROCEDURE [quotes].[uspQUOTES_GetSiteGroupDetailProducts] (@IPC_CompanyID            char(11),
                                                       @IPVC_quoteid             varchar(50) = '0', 
                                                       @IPI_GroupID              bigint = 0,
                                                       @IPVC_GroupType           varchar(70)  = NULL, 
                                                       @IPVC_FamilyCode          varchar(50)  = '',                                                      
                                                       @IPI_InternalGroupID      varchar(100) = '',                                                       
                                                       @IPVC_RETURNTYPE          varchar(100) = 'XML')
AS
BEGIN
  set nocount on   
  select @IPC_CompanyID = ltrim(rtrim(@IPC_CompanyID))
  --------------------------------------------------------------------------------------------  
  declare @LT_DisplayType     TABLE (displaytype  varchar(20)) 
  declare @LI_allowproductcancelflag  int

  declare @LT_QUOTEITEM_FINAL TABLE
              (seq                      int           not null   identity(1,1),
               companyid                varchar(11),
               quoteid                  varchar(50)   not null default '0',
               groupid                  bigint        not null default 0,
               measurecode              varchar(6)    not null default '',
               measurename              varchar(50)   not null default '',
               frequencycode            varchar(6)    not null default '',
               frequencyname            varchar(50)   not null default '',
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
               prodminunits             int           not null default 100,
               prodmaxunits             int           not null default 500,
               minunits                 int           not null default 100,
               maxunits                 int           not null default 500,
               internaluidisplay        int           not null default 0,              
               internalgroupid          varchar(100)  not null default ''
               )    
  -------------------------------------------------------------------------------------------- 
  select @LI_allowproductcancelflag = 1
  --------------------------------------------------------------------------------------------
  if exists (select top 1  1 from   QUOTES.dbo.[Group] S (nolock)
             where   S.IDSeq        = @IPI_GroupID     
             and     S.QuoteIDSeq   = @IPVC_quoteid
            )
  begin
    select  @IPVC_GroupType = S.grouptype,
            @LI_allowproductcancelflag = S.allowproductcancelflag  
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
  insert into @LT_QUOTEITEM_FINAL(companyid,quoteid,groupid,
                                  measurecode,measurename,frequencycode,frequencyname,familycode,familyname,
                                  productcode,productname,productdisplayname,mpfpublicationtype,
                                  quantity,quantityenabledflag,
                                  ilfdiscountmaxpercent,accessdiscountmaxpercent,listpriceilf,listpriceaccess,
                                  ilfdiscountpercent,accessdiscountpercent,
                                  priceversion,optionflag,
                                  prodminunits,prodmaxunits,
                                  sortseq,socflag,internalgroupid)
  select distinct ltrim(rtrim(@IPC_CompanyID))                                                     as companyid,
                  @IPVC_quoteid                                                                    as quoteid,
                  @IPI_GroupID                                                                     as groupid,
                  ltrim(rtrim(C.MeasureCode))                                                      as MeasureCode,
                  ltrim(rtrim(M.Name))                                                             as MeasureName, 
                  ltrim(rtrim(C.FrequencyCode))                                                    as FrequencyCode,
                  ltrim(rtrim(FR.Name))                                                            as FrequencyName,
                  ltrim(rtrim(P.FamilyCode))                                                       as FamilyCode,
                  ltrim(rtrim(F.Name))                                                             as FamilyName,
                  ltrim(rtrim(P.Code))                                                             as ProductCode, 
                  ltrim(rtrim(P.name))                                                             as ProductName,
                  ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                  (case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                          then 'Yearly'
                       when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                          then 'Quarterly'
                       else ''
                   end
                  )                                                                                as mpfpublicationtype, 
                  1                                                                                as quantity,
                  C.quantityenabledflag                                                            as quantityenabledflag,
                  coalesce((select Sum(distinct Z.DiscountMaxPercent) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0          
                            and    Z.ChargeTypeCode = 'ILF'                        
                            and    Z.MeasureCode    = C.MeasureCode   
                            and    Z.FrequencyCode  = C.FrequencyCode                   
                            ),
                           (select Sum(distinct Z.DiscountMaxPercent) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                              
                            and    Z.ChargeTypeCode = 'ILF'
                            and    Z.MeasureCode    = C.MeasureCode                                           
                           ),
                          (select Sum(distinct Z.DiscountMaxPercent) 
                           from   PRODUCTS.dbo.Charge Z (nolock) 
                           where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                           and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                              
                           and    Z.ChargeTypeCode = 'ILF' 
                           and    Z.MeasureCode    = 'SITE'),
                          (select Top 1   Z.DiscountMaxPercent
                           from   PRODUCTS.dbo.Charge Z (nolock) 
                           where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code                      
                           and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0          
                           and    Z.ChargeTypeCode = 'ILF'                                                             
                          ),                      
                          0.00)                                                                    as ILFDiscountMaxPercent,
                  coalesce((select Sum(distinct Z.DiscountMaxPercent) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                               
                            and    Z.ChargeTypeCode = 'ACS'                      
                            and    Z.MeasureCode    = C.MeasureCode
                            and    Z.FrequencyCode  = C.FrequencyCode                      
                           ),0.00)                                                                 as AccessDiscountMaxPercent,
                  coalesce((select Sum(distinct Z.ChargeAmount) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0          
                            and    Z.ChargeTypeCode = 'ILF'                     
                            and    Z.MeasureCode    = C.MeasureCode   
                            and    Z.FrequencyCode  = C.FrequencyCode                   
                            ),
                           (select Sum(distinct Z.ChargeAmount) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                               
                            and    Z.ChargeTypeCode = 'ILF'
                            and    Z.MeasureCode    = C.MeasureCode                                           
                           ),
                           (select Sum(distinct Z.ChargeAmount) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                               
                            and    Z.ChargeTypeCode = 'ILF' 
                            and    Z.MeasureCode    = 'SITE'),
                           (select Top 1   Z.ChargeAmount
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                                
                            and    Z.ChargeTypeCode = 'ILF'                                                             
                           ),                      
                           0.00)                                                                   as ListPriceILF,
                  coalesce((select Sum(distinct Z.ChargeAmount)
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode  = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag = 0 and Z.DisabledFlag = 0          
                            and    Z.ChargeTypeCode = 'ACS'                      
                            and    Z.MeasureCode    = C.MeasureCode 
                            and    Z.FrequencyCode  = C.FrequencyCode                     
                           ),0.00)                                                                 as ListPriceAccess,
                         0.00                                                                      as ilfdiscountpercent,
                         0.00                                                                      as accessdiscountpercent,                           
                  C.PriceVersion                                                                   as PriceVersion,
                  P.OptionFlag                                                                     as OptionFlag,
                  coalesce((select Top 1 MinUnits
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode  = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag = 0 and Z.DisabledFlag = 0                                                
                           ),100)                                                                  as MinUnits,
                  coalesce((select Top 1 MaxUnits
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode  = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag = 0 and Z.DisabledFlag = 0                                                
                           ),500)                                                                  as MaxUnits,
                  P.SortSeq                                                                        as SortSeq, 
                  P.socflag                                                                        as socflag,
                  @IPI_InternalGroupID                                                             as internalgroupid
  from   PRODUCTS.dbo.PRODUCT P (nolock) 
         INNER JOIN PRODUCTS.dbo.Family F  (nolock)
         on   P.FamilyCode = F.Code and P.DisabledFlag = 0
         and  P.FamilyCode  = (case when (@IPVC_FamilyCode is null or @IPVC_FamilyCode = '')
                                     then P.FamilyCode
                                   else @IPVC_FamilyCode
                              end)
         and  F.Code  = (case when (@IPVC_FamilyCode is null or @IPVC_FamilyCode = '')
                                     then F.Code
                                   else @IPVC_FamilyCode
                              end)                                
         INNER JOIN PRODUCTS.dbo.Charge C (nolock)
         on   P.Code         = C.ProductCode              
         and  P.DisabledFlag = 0 and  C.DisabledFlag = 0                
         and  (C.ChargeTypeCode = 'ACS')          
         and  C.DisplayType in (select displaytype from @LT_DisplayType) 
         INNER JOIN PRODUCTS.dbo.Measure M (nolock)
         ON   C.MeasureCode = M.Code and M.DisplayFlag = 1       
         INNER JOIN PRODUCTS.dbo.Frequency FR(nolock)
         ON   C.FrequencyCode = FR.Code and FR.DisplayFlag = 1
  -----------------------------------------------------------------------------------------------------------
  insert into @LT_QUOTEITEM_FINAL(companyid,quoteid,groupid,
                                  measurecode,measurename,frequencycode,frequencyname,familycode,familyname,
                                  productcode,productname,productdisplayname,mpfpublicationtype,
                                  quantity,quantityenabledflag,
                                  ilfdiscountmaxpercent,accessdiscountmaxpercent,listpriceilf,listpriceaccess,
                                  ilfdiscountpercent,accessdiscountpercent,
                                  priceversion,optionflag,
                                  prodminunits,prodmaxunits,
                                  sortseq,socflag,internalgroupid)
  select distinct ltrim(rtrim(@IPC_CompanyID))                                                     as companyid,
                  @IPVC_quoteid                                                                    as quoteid,
                  @IPI_GroupID                                                                     as groupid,
                  ltrim(rtrim(C.MeasureCode))                                                      as MeasureCode,
                  ltrim(rtrim(M.Name))                                                             as MeasureName, 
                  ltrim(rtrim(C.FrequencyCode))                                                    as FrequencyCode,
                  ltrim(rtrim(FR.Name))                                                            as FrequencyName,
                  ltrim(rtrim(P.FamilyCode))                                                       as FamilyCode,
                  ltrim(rtrim(F.Name))                                                             as FamilyName,
                  ltrim(rtrim(P.Code))                                                             as ProductCode, 
                  ltrim(rtrim(P.name))                                                             as ProductName,
                  ltrim(rtrim(P.DisplayName))                                                      as productdisplayname,
                  (case when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Yearly',P.name) > 0)
                          then 'Yearly'
                       when (ltrim(rtrim(P.FamilyCode)) = 'YLD' and charindex('Quarterly',P.name) > 0)
                          then 'Quarterly'
                       else ''
                   end
                  )                                                                                as mpfpublicationtype,
                  1                                                                                as quantity,
                  C.quantityenabledflag                                                            as quantityenabledflag,
                  coalesce((select Sum(distinct Z.DiscountMaxPercent) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0          
                            and    Z.ChargeTypeCode = 'ILF'                        
                            and    Z.MeasureCode    = C.MeasureCode   
                            and    Z.FrequencyCode  = C.FrequencyCode                   
                            ),
                           (select Sum(distinct Z.DiscountMaxPercent) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                              
                            and    Z.ChargeTypeCode = 'ILF'
                            and    Z.MeasureCode    = C.MeasureCode                                           
                           ),
                          (select Sum(distinct Z.DiscountMaxPercent) 
                           from   PRODUCTS.dbo.Charge Z (nolock) 
                           where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                           and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                              
                           and    Z.ChargeTypeCode = 'ILF' 
                           and    Z.MeasureCode    = 'SITE'),
                          (select Top 1   Z.DiscountMaxPercent
                           from   PRODUCTS.dbo.Charge Z (nolock) 
                           where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code                      
                           and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0          
                           and    Z.ChargeTypeCode = 'ILF'                                                             
                          ),                      
                          0.00)                                                                    as ILFDiscountMaxPercent,
                  0.00                                                                             as AccessDiscountMaxPercent,
                  coalesce((select Sum(distinct Z.ChargeAmount) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0          
                            and    Z.ChargeTypeCode = 'ILF'                     
                            and    Z.MeasureCode    = C.MeasureCode   
                            and    Z.FrequencyCode  = C.FrequencyCode                   
                            ),
                           (select Sum(distinct Z.ChargeAmount) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                               
                            and    Z.ChargeTypeCode = 'ILF'
                            and    Z.MeasureCode    = C.MeasureCode                                           
                           ),
                           (select Sum(distinct Z.ChargeAmount) 
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                               
                            and    Z.ChargeTypeCode = 'ILF' 
                            and    Z.MeasureCode    = 'SITE'),
                           (select Top 1   Z.ChargeAmount
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode    = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag   = 0 and Z.DisabledFlag = 0                                
                            and    Z.ChargeTypeCode = 'ILF'                                                             
                           ),                      
                           0.00)                                                                   as ListPriceILF,
                  0.00                                                                             as ListPriceAccess,
                  0.00                                                                             as ilfdiscountpercent,
                  0.00                                                                             as accessdiscountpercent,
                  C.PriceVersion                                                                   as PriceVersion,
                  P.OptionFlag                                                                     as OptionFlag,
                  coalesce((select Top 1 MinUnits
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode  = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag = 0 and Z.DisabledFlag = 0                                                
                           ),100)                                                                  as MinUnits,
                  coalesce((select Top 1 MaxUnits
                            from   PRODUCTS.dbo.Charge Z (nolock) 
                            where  Z.ProductCode  = C.ProductCode and Z.ProductCode = P.Code
                            and    P.DisabledFlag = 0 and Z.DisabledFlag = 0                                                
                           ),500)                                                                  as MaxUnits,
                  P.SortSeq                                                                        as SortSeq, 
                  P.socflag                                                                        as socflag,
                  @IPI_InternalGroupID                                                             as internalgroupid  
  from   PRODUCTS.dbo.PRODUCT P (nolock) 
         INNER JOIN PRODUCTS.dbo.Family F  (nolock)
         on   P.FamilyCode = F.Code and P.DisabledFlag = 0
         and  P.FamilyCode  = (case when (@IPVC_FamilyCode is null or @IPVC_FamilyCode = '')
                                     then P.FamilyCode
                                   else @IPVC_FamilyCode
                              end)
         and  F.Code  = (case when (@IPVC_FamilyCode is null or @IPVC_FamilyCode = '')
                                     then F.Code
                                   else @IPVC_FamilyCode
                              end)  
         INNER JOIN PRODUCTS.dbo.Charge C (nolock)
         on   P.Code         = C.ProductCode              
         and  P.DisabledFlag = 0 and  C.DisabledFlag = 0                
         and  (C.ChargeTypeCode = 'ILF')   
         and  C.DisplayType in (select displaytype from @LT_DisplayType)                       
         INNER JOIN PRODUCTS.dbo.Measure M (nolock)
         ON   C.MeasureCode = M.Code and M.DisplayFlag = 1       
         INNER JOIN PRODUCTS.dbo.Frequency FR(nolock)
         ON   C.FrequencyCode = FR.Code and FR.DisplayFlag = 1
  and  not exists (select TOP 1 X.ProductCode as ProductCode
                   from   @LT_QUOTEITEM_FINAL X
                   where  P.Code = X.productcode                   
                  )
  order by P.sortseq asc,MeasureName asc,FrequencyName asc
  -------------------------------------------------------------------------
  ---Initially the NetPrice is equal to ListPrice coming from productmaster.
  Update @LT_QUOTEITEM_FINAL
  set    ilfnetprice=listpriceilf,
         accessnetprice=listpriceaccess,
         minunits      = prodminunits,
         maxunits      = prodmaxunits
  ------------------------------------------------------------------------------------------  
  if (select count(*) from @LT_QUOTEITEM_FINAL) = 0
  begin
   insert into @LT_QUOTEITEM_FINAL(companyid,quoteid,groupid,MeasureCode,measurename,FrequencyCode,FrequencyName,FamilyCode,Familyname,
                                   quantity,internalgroupid) 
   select ltrim(rtrim(@IPC_CompanyID)) as companyid,@IPVC_quoteid as quoteid,@IPI_GroupID as groupid,          
          --'SITE' as MeasureCode,
          @IPVC_GroupType as MeasureCode,
          coalesce((select top 1 ltrim(rtrim(Z.Name)) from PRODUCTS.DBO.Measure Z (nolock)
            where ltrim(rtrim(Z.Code)) = @IPVC_GroupType),'') as measurename,
          'YR' as FrequencyCode,
          (select top 1 ltrim(rtrim(Z.Name)) from PRODUCTS.DBO.Frequency Z (nolock)
           where ltrim(rtrim(Z.Code)) = 'YR') as FrequencyName,
          (select top 1 F.Code from PRODUCTS.dbo.Family F (nolock) where F.Name = 'Onesite') as FamilyCode,
          'Onesite' as Familyname,
          1         as quantity,
          @IPI_InternalGroupID as internalgroupid
  end
  --------------------------------------------------------------------------------------------  
  if exists (select TOP 1 1 
             from   QUOTES.dbo.QuoteItem S (nolock)
             where   S.GroupIDSeq     = @IPI_GroupID     
             and     S.QuoteIDSeq     = @IPVC_quoteid) and
     exists (select TOP 1 1 from @LT_QUOTEITEM_FINAL)
  begin
    update D 
    set D.quoteid               = coalesce(@IPVC_quoteid,'0'),                                     
        D.groupid               = coalesce(@IPI_GroupID,0),
        D.publicationyear       = coalesce((select TOP 1 convert(varchar(50),publicationyear)                                                          
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid                                         
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                          
                                           ),''),
        D.publicationquarter    = coalesce((select TOP 1 convert(varchar(50),publicationquarter)                                                          
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid                                         
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                          
                                           ),''),
        D.quantity              = coalesce((select TOP 1 convert(varchar(50),quantity)                                                          
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid                                         
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                          
                                           ),''),
        D.ListPriceILF          = coalesce((select TOP 1 S.ChargeAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = D.MeasureCode   
                                            and    S.FrequencyCode  = D.FrequencyCode
                                           ),
                                           (select TOP 1 S.ChargeAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = D.MeasureCode                                               
                                           ),
                                           (select TOP 1 S.ChargeAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = 'SITE'),
                                           (select TOP 1 S.ChargeAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            ),0.00),                                           
        D.ListPriceAccess       = coalesce((select TOP 1 S.ChargeAmount
                                           from    QUOTES.dbo.QuoteItem S (nolock)
                                           where   S.GroupIDSeq     = D.groupid
                                           and     S.QuoteIDSeq     = D.quoteid
                                           and     S.GroupIDSeq     = @IPI_GroupID
                                           and     S.QuoteIDSeq     = @IPVC_quoteid
                                           and     S.ChargeTypeCode = 'ACS'
                                           and     S.ProductCode    = D.ProductCode 
                                           and     S.MeasureCode    = D.MeasureCode
                                           and     S.FrequencyCode  = D.FrequencyCode                                            
                                           ),0.00),
        D.ILFDiscountPercent    = coalesce((select TOP 1 S.DiscountPercent
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = D.MeasureCode   
                                            and    S.FrequencyCode  = D.FrequencyCode
                                           ),
                                           (select TOP 1 S.DiscountPercent
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = D.MeasureCode                                               
                                           ),
                                           (select TOP 1 S.DiscountPercent
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = 'SITE'),
                                           (select TOP 1 S.DiscountPercent
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            ),0.00),                                           
        D.ILFDiscountAmount     = coalesce((select TOP 1 S.DiscountAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = D.MeasureCode   
                                            and    S.FrequencyCode  = D.FrequencyCode
                                           ),
                                           (select TOP 1 S.DiscountAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = D.MeasureCode                                               
                                           ),
                                           (select TOP 1 S.DiscountAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = 'SITE'),
                                           (select TOP 1 S.DiscountAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            ),0.00),                                           
        D.AccessDiscountPercent = coalesce((select TOP 1 S.DiscountPercent
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ACS'
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                            
                                            ),0.00), 
        D.AccessDiscountAmount  = coalesce((select TOP 1 S.DiscountAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ACS'
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                           
                                          ),0.00),
        D.ilfnetprice           = coalesce((select TOP 1 S.NetChargeAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = D.MeasureCode   
                                            and    S.FrequencyCode  = D.FrequencyCode
                                           ),
                                           (select TOP 1 S.NetChargeAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = D.MeasureCode                                               
                                           ),
                                           (select TOP 1 S.NetChargeAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            and    S.MeasureCode    = 'SITE'),
                                           (select TOP 1 S.NetChargeAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                      
                                            ),0.00),
        D.accessnetprice        = coalesce((select TOP 1 S.NetChargeAmount
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ACS'
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                            
                                           ),0.00), 
        D.MinUnits              = coalesce((select TOP 1 S.MinUnits
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ACS'
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                                                                      
                                           ),
                                           (select TOP 1 S.MinUnits
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                                                                      
                                           ),D.prodminunits),
        D.MaxUnits              = coalesce((select TOP 1 S.MaxUnits
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ACS'
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                                                                      
                                           ),
                                           (select TOP 1 S.MaxUnits
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                                                                      
                                           ),D.prodmaxunits),

        D.IsSelected            = coalesce((select TOP 1 1
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid                                         
                                            and    S.ProductCode    = D.ProductCode 
                                            and    S.MeasureCode    = D.MeasureCode
                                            and    S.FrequencyCode  = D.FrequencyCode                                          
                                           ),0)
    from @LT_QUOTEITEM_FINAL D
    where D.groupid     = @IPI_GroupID
    and   D.quoteid     = @IPVC_quoteid 
    and   exists (select TOP 1 1 
                  from   QUOTES.dbo.QuoteItem S (nolock)
                  where   S.GroupIDSeq     = @IPI_GroupID     
                  and     S.QuoteIDSeq     = @IPVC_quoteid                                    
                  and     S.ProductCode    = D.ProductCode 
                  and     S.MeasureCode    = D.MeasureCode
                  and     S.FrequencyCode  = D.FrequencyCode                   
                 )
   -----------------------------------------------------------------------------------------  
  end  
  -----------------------------------------------------------------------------------------
  --Final Update for internaluidisplay  
  /* update D
  set    D.internaluidisplay = 1
  from   @LT_QUOTEITEM_FINAL D 
  where  not exists(select top 1 1 from @LT_QUOTEITEM_FINAL Z
                    where  Z.productcode = D.productcode
                    and    convert(varchar(50),Z.seq)+
                           convert(varchar(50),Z.sortseq)+ convert(varchar(50),Z.isselected)                            
                           <
                           convert(varchar(50),D.seq)+
                           convert(varchar(50),D.sortseq)+ convert(varchar(50),D.isselected)                     
                   )  */
  update D
  set   D.MinUnits              = coalesce((select TOP 1 S.MinUnits
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ACS'
                                            and    S.ProductCode    = D.ProductCode                                                                                                                                 
                                           ),
                                           (select TOP 1 S.MinUnits
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                                                                  
                                           ),D.prodminunits),
        D.MaxUnits              = coalesce((select TOP 1 S.MaxUnits
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ACS'
                                            and    S.ProductCode    = D.ProductCode                                                                                                                                 
                                           ),
                                           (select TOP 1 S.MaxUnits
                                            from   QUOTES.dbo.QuoteItem S (nolock)
                                            where  S.GroupIDSeq     = D.groupid
                                            and    S.QuoteIDSeq     = D.quoteid
                                            and    S.GroupIDSeq     = @IPI_GroupID
                                            and    S.QuoteIDSeq     = @IPVC_quoteid
                                            and    S.ChargeTypeCode = 'ILF'
                                            and    S.ProductCode    = D.ProductCode                                                                                                                                 
                                           ),D.prodmaxunits)
  from @LT_QUOTEITEM_FINAL D
  where D.groupid     = @IPI_GroupID
  and   D.quoteid     = @IPVC_quoteid 
  and   D.IsSelected  = 0

  update D
  set    D.internaluidisplay = 1
  from   @LT_QUOTEITEM_FINAL D 
  where  D.isselected  = 1 

  update D
  set    D.internaluidisplay = 1
  from   @LT_QUOTEITEM_FINAL D 
  where  D.isselected  = 0
  and  not exists(select top 1 1 from @LT_QUOTEITEM_FINAL Z
                  where  Z.productcode = D.productcode
                  and    Z.isselected = 1)
  and  D.seq = (select top 1 min(seq) from @LT_QUOTEITEM_FINAL Z
                where  Z.productcode = D.productcode
                and    Z.isselected  = 0
               )
  -----------------------------------------------------------------------------------------
  --Final Select 
  -----------------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    SELECT  F.code                                                       as familycode,
            F.Name					                 as familyname,								
           (select distinct 
            Z.companyid                                                  as companyid,
            Z.quoteid                                                    as quoteid,
            Z.groupid                                                    as groupid,
            Z.measurecode                                                as measurecode,
            Z.measurename                                                as measurename,
            Z.frequencycode                                              as frequencycode,
            Z.frequencyname                                              as frequencyname,
            Z.familycode                                                 as familycode,
            Z.familyname                                                 as familyname,
            Z.productcode                                                as productcode,
            Z.productname                                                as productname,
            Z.productdisplayname                                         as productdisplayname,
            Z.publicationyear                                            as publicationyear,
            Z.publicationquarter                                         as publicationquarter,
            Z.mpfpublicationtype                                         as mpfpublicationtype,

            Z.ilfdiscountmaxpercent                                      as ilfdiscountmaxpercent,
            QUOTES.dbo.fn_formatcurrency(Z.ilfdiscountmaxpercent,1,2)    as displayilfdiscountmaxpercent,
        
            Z.accessdiscountmaxpercent                                   as accessdiscountmaxpercent,
            QUOTES.dbo.fn_formatcurrency(Z.accessdiscountmaxpercent,1,2) as displayaccessdiscountmaxpercent,

            Z.quantity                                                   as quantity,
            Z.quantityenabledflag                                        as quantityenabledflag,
            Z.listpriceilf                                               as listpriceilf,
            QUOTES.dbo.fn_formatcurrency(Z.listpriceilf,1,2)             as displaylistpriceilf,

            Z.listpriceaccess                                            as listpriceaccess,
            QUOTES.dbo.fn_formatcurrency(Z.listpriceaccess,1,2)          as displaylistpriceaccess,

            Z.ilfdiscountpercent                                         as ilfdiscountpercent,
            QUOTES.dbo.fn_formatcurrency(Z.ilfdiscountpercent,1,2)       as displayilfdiscountpercent,
  
            Z.accessdiscountpercent                                      as accessdiscountpercent,
            QUOTES.dbo.fn_formatcurrency(Z.accessdiscountpercent,1,2)    as displayaccessdiscountpercent,
         
            Z.ilfdiscountamount                                          as ilfdiscountamount,
            QUOTES.dbo.fn_formatcurrency(Z.ilfdiscountamount,1,2)        as displayilfdiscountamount,

            Z.accessdiscountamount                                       as accessdiscountamount,
            QUOTES.dbo.fn_formatcurrency(Z.accessdiscountamount,1,2)     as displayaccessdiscountamount,

            Z.ilfnetprice                                                as ilfnetprice, 
            QUOTES.dbo.fn_formatcurrency(Z.ilfnetprice,1,2)              as displayilfnetprice,

            Z.accessnetprice                                             as accessnetprice,
            QUOTES.dbo.fn_formatcurrency(Z.accessnetprice,1,2)           as displayaccessnetprice,
            Z.priceversion                                               as priceversion,
            Z.optionflag                                                 as optionflag,
            Z.isselected                                                 as isselected,
            Z.sortseq                                                    as sortseq,
            Z.socflag                                                    as socflag,
            Z.prodminunits                                               as prodminunits,
            Z.prodmaxunits                                               as prodmaxunits,
            Z.minunits                                                   as minunits,
            Z.maxunits                                                   as maxunits,                        
            (case when  Z.FamilyCode = 'SBL' then 0
               else @LI_allowproductcancelflag 
            end)                                                         as allowproductcancelflag,
            (case when  Z.FamilyCode = 'SBL' then 1
                  else 0 
            end)                                                         as preconfiguredbundleflag,
            Z.internaluidisplay                                          as internaluidisplay,
            Z.internalgroupid                                            as internalgroupid 
            from @lt_quoteitem_final Z
            where Z.familycode = F.code 
            order by sortseq asc,isselected desc,measurename asc,frequencyname asc
            for xml raw ,root('familyproducts'),type
           )
    from Products.dbo.Family F (nolock)  
    for xml raw ,root('products'), type
  end
  else
  begin
    select distinct 
         Z.companyid                                                  as companyid,
         Z.quoteid                                                    as quoteid,
         Z.productcode                                                as productcode,
         Z.productname                                                as productname,
         Z.productdisplayname                                         as productdisplayname,

         QUOTES.dbo.fn_formatcurrency(Z.listpriceilf,1,2)             as ilflistprice,

         QUOTES.dbo.fn_formatcurrency(Z.listpriceaccess,1,2)          as accesslistprice,

         QUOTES.dbo.fn_formatcurrency(Z.ilfdiscountpercent,1,2)       as discountpercent,
  
         QUOTES.dbo.fn_formatcurrency(Z.ilfdiscountamount,1,2)        as discountamount,

         QUOTES.dbo.fn_formatcurrency(Z.ilfnetprice,1,2)              as ilfnetprice,

         QUOTES.dbo.fn_formatcurrency(Z.accessnetprice,1,2)           as accessnetprice
    from @lt_quoteitem_final Z    
    ---where Z.productcode in (select productcode from @lt_quoteitem_final where isselected = 1)   
    order by quoteid
  end
END

GO
