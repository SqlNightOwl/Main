SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec uspORDERS_GetOrderProductDetail    @IPVC_Orderid        = 'O0804070381',   
                                        @IPI_OrderGroupID    = '56307',  
                                        @IPVC_OrderItemIDSeq = ''  ,
                                        @IPVC_RenewalCount   = 0 , 
                                        @IPB_IsCustomPackage = 1  
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_GetOrderProductDetail
-- Description     : This procedure retrieves OrderItem details before generating access
-- Input Parameters: @IPVC_Orderid      varchar(50), 
--                   @IPI_OrderGroupID  bigint,
--                   @IPVC_ProductCode  varchar(50)
-- Code Example    : Exec uspORDERS_GetOrderProductDetail    @IPVC_Orderid = 'O0712000219', 
--                                                           @IPI_OrderGroupID = 77829,
--                                                           @IPVC_ProductCode = 'DMD-SBL-ECN-CNV-ESCV'
-- OUTPUT          : OrderItem details retrieved
-- Revision History:
-- Author          :  
-- 12/20/2007      : Stored Procedure Created.
-- 
--@IPVC_OrderID='O0806064621', @IPVC_OrderItemIDSeq = '',@IPVC_OrderGroupIDSeq = '69365',@IPB_IsCustomPackage = 1,@IPVC_RenewalCount =  '0'
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetOrderProductDetail] (
                                                      @IPVC_OrderID         varchar(50), 
                                                      @IPI_OrderGroupID     bigint, 
                                                      @IPVC_OrderItemIDSeq  bigint, 
                                                      @IPVC_RenewalCount    int = 0,                                                     
                                                      @IPB_IsCustomPackage  bit
                                                     )
AS
BEGIN
  set nocount on;
  -------------------------------------------------------
  --Creating Temp Table
  -------------------------------------------------------
  create table #temp_OrderGroupProducts
                                       (
                                        IDSeq        int identity(1,1) not null,
                                        ProductCode  varchar(30)  null
                                       )   
  -------------------------------------------------------
  --Declaration of local variables
  -------------------------------------------------------   
  declare @LVC_GroupType        varchar(20)
  declare @LVC_GroupName        varchar(255)
  declare @LVC_GroupDescription varchar(255)
  declare @LVC_measurecode      varchar(10)
  declare @LVC_frequencycode    varchar(10)
  declare @LI_ProductCount      int
  ------------------------------------------------------- 
  if(@IPB_IsCustomPackage = 0)
  begin
    insert into #temp_OrderGroupProducts(productcode)
    select distinct productcode
    from   Orders.dbo.Orderitem with (nolock)
    where  Orderidseq      = @IPVC_OrderID
    and    Ordergroupidseq = @IPI_OrderGroupID 
    and    IDSeq           = @IPVC_OrderItemIDSeq
    and    Renewalcount    = @IPVC_RenewalCount 
    and    Chargetypecode  = 'ILF'  
  end
  else if(@IPB_IsCustomPackage = 1)
  begin
    insert into #temp_OrderGroupProducts(productcode)
    select distinct productcode
    from   Orders.dbo.Orderitem with (nolock)
    where  Orderidseq      = @IPVC_OrderID
    and    Ordergroupidseq = @IPI_OrderGroupID            
    and    Renewalcount    = @IPVC_RenewalCount
    and    Chargetypecode  = 'ILF'     		
  end
  select @LI_ProductCount = count(IDSeq) from #temp_OrderGroupProducts with (nolock)
  -------------------------------------------------------
  -- Declaring Table Variables  
  -------------------------------------------------------
  declare @LT_DisplayType     TABLE (displaytype  varchar(20))   

  declare @LT_QUOTEITEM_FINAL TABLE
              (seq                               int           not null identity(1,1),
               familycode                        varchar(10)   not null default '',
               familyname                        varchar(50)   not null default '',                              
               measurecode                       varchar(10)   not null default '',
               measurename                       varchar(50)   not null default '',
               frequencycode                     varchar(10)   not null default '',
               frequencyname                     varchar(50)   not null default '',               
               productcode                       varchar(50)   not null default '',
               productdisplayname                varchar(255)  ,
               quantity                          varchar(50)   not null default 1,
               quantityenabledflag               int           not null default 0,
               listpriceaccess                   money         not null default 0,  
               accessdiscountpercent             as convert(float,(convert(float,listpriceaccess)-convert(float,accessnetprice))*(100)/
                                                                  (case when listpriceaccess=0 then 1 else convert(float,listpriceaccess) end)
                                                           ),
               accessdiscountamount             as (listpriceaccess-accessnetprice),     
               accessnetprice                    money         not null default 0,               
               priceversion                      numeric(18,0) not null default 0,              
               acsminunits                       int           not null default 0,
               acsmaxunits                       int           not null default 0,      
               acscapmaxunitsflag                int           not null default 0,
               acsdollarminimum                  money         not null default 0,
               acsdollarminimumenabledflag       int           not null default 0,              
               acsdollarmaximum                  money         not null default 0,
               acsdollarmaximumenabledflag       int           not null default 0,
               creditcardpercentageenabledflag   int           not null default 0,
               credtcardpricingpercentage        numeric(30,2) not null default 0.00 
               )
   
  declare @LT_ValidVombination table
                               (IDSeq         int not null identity(1,1),
                                measurecode   varchar(20),
                                measurename   varchar(50),
                                frequencycode varchar(20),
                                frequencyname varchar(50)
                               )
  -------------------------------------------------------
  -- Retrieving the GroupType for the OrderID Passed  
  -------------------------------------------------------   
  if exists (select top 1  1 
             from Orders.dbo.OrderGroup S with (nolock)
             where S.IDSeq           = @IPI_OrderGroupID     
             and   S.OrderIDSeq      = @IPVC_Orderid
            )       
    begin
      select  @LVC_GroupType = S.OrderGroupType,
              @LVC_GroupName = S.[Name],
              @LVC_GroupDescription = S.[Description]   
      from    Orders.dbo.OrderGroup S with (nolock)
      where   S.IDSeq        = @IPI_OrderGroupID     
      and     S.OrderIDSeq   = @IPVC_Orderid
    end  
  -------------------------------------------------------
  -- Inserting data into table variable @LT_DisplayType
  -------------------------------------------------------    
  if @LVC_GroupType = 'PMC'
    begin
      insert into @LT_DisplayType(displaytype)
      select  'PMC' displaytype union Select 'BOTH' as displaytype
    end
  else
    begin
      insert into @LT_DisplayType(displaytype)
      select  'SITE' DisplayType union Select 'BOTH' as DisplayType
    end
  -------------------------------------------------------
  -- Inserting data into table variable @LT_QUOTEITEM_FINAL
  -- based on CustomBundle bit flag
  -------------------------------------------------------   
  insert into @LT_QUOTEITEM_FINAL(familycode,familyname,measurecode,
								  measurename,
								  frequencycode,
								  frequencyname,
								  productcode,
                                  productdisplayname,                                  
								  quantity,
								  quantityenabledflag,
								  listpriceaccess,
								  accessnetprice,
								  priceversion,
								  acsminunits,
								  acsmaxunits,
								  acscapmaxunitsflag,
								  acsdollarminimum,
								  acsdollarminimumenabledflag,
								  acsdollarmaximum,
								  acsdollarmaximumenabledflag,
								  creditcardpercentageenabledflag,
								  credtcardpricingpercentage)
    select distinct ltrim(rtrim(P.familycode))                                                       as familycode,
                    ltrim(rtrim(F.Name))                                                             as familyname,
                    ltrim(rtrim(CACS.MeasureCode))                                                   as measurecode,
                    ltrim(rtrim(M.Name))                                                             as measurename, 
                    ltrim(rtrim(CACS.FrequencyCode))                                                 as frequencycode,
                    ltrim(rtrim(FR.Name))                                                            as frequencyname, 
                    ltrim(rtrim(P.Code))                                                             as productcode,
                    ltrim(rtrim(P.Displayname))                                                      as productdisplayname,
                    1.00                                                                             as quantity,
                    coalesce(CACS.quantityenabledflag,0)                                             as quantityenabledflag,                                    
                    coalesce(CACS.ChargeAmount,0)                                                    as listpriceaccess,    
                    coalesce(CACS.ChargeAmount,0)                                                    as accessnetprice,  
                    CACS.PriceVersion                                                                as priceversion,
                    coalesce(CACS.minunits,0)                                                        as acsminunits,
                    coalesce(CACS.maxunits,0)                                                        as acsmaxunits,
                    0                                                                                as acscapmaxunitsflag,                    
                    coalesce(CACS.dollarminimum,0)                                                   as acsdollarminimum,
                    coalesce(CACS.dollarminimumenabledflag,0)                                        as acsdollarminimumenabledflag,
                    coalesce(CACS.dollarmaximum,0)                                                   as acsdollarmaximum,
                    coalesce(CACS.dollarmaximumenabledflag,0)                                        as acsdollarmaximumenabledflag,
                    coalesce(CACS.creditcardpercentageenabledflag,0)                                 as creditcardpercentageenabledflag,
                    (case when (coalesce(CACS.creditcardpercentageenabledflag,0)=1)
                             then coalesce(CACS.credtcardpricingpercentage,0.00)
                          else 0.00
                     end
                    )                                                                                as credtcardpricingpercentage
    from    PRODUCTS.dbo.Product P with (nolock)
    inner join
            #temp_OrderGroupProducts TP with (nolock)
    on      TP.Productcode = P.Code
    and     P.disabledflag = 0
    inner join
            PRODUCTS.dbo.Family F  with (nolock)
    on      P.FamilyCode = F.Code
    inner join
            Products.dbo.Charge CACS (nolock)
    on      P.Code              = CACS.ProductCode    
    and     P.PriceVersion      = CACS.PriceVersion 
    and     P.disabledflag      = 0    
    and     CACS.disabledflag   = 0
    and     CACS.ChargeTypeCode = 'ACS'
    and     CACS.DisplayType in (select displaytype from @LT_DisplayType)
    and     not exists (select top 1 1 
                        from   ORDERS.dbo.OrderItem OI with (nolock)
                        where  OI.OrderIDSeq      = @IPVC_Orderid
                        and    OI.OrderGroupIDSeq = @IPI_OrderGroupID
                        and    OI.ProductCode     = TP.Productcode
                        and    OI.ChargeTypecode  = 'ACS'
                       )
    inner join 
           PRODUCTS.dbo.Measure M  (nolock)
    ON     CACS.MeasureCode    = M.Code 
    and    M.DisplayFlag       = 1       
    inner join  PRODUCTS.dbo.Frequency FR (nolock)
    ON     CACS.FrequencyCode  = FR.Code 
    and    FR.DisplayFlag      = 1
    where  P.disabledflag      = 0    
    and    CACS.disabledflag   = 0
    and    CACS.ChargeTypeCode = 'ACS'          
    Order by  measurename asc,frequencyname asc
  -------------------------------------------------------
   -- Checking the valid combinations from the list
  ------------------------------------------------------- 
  Insert into @LT_ValidVombination(MeasureCode,measurename,FrequencyCode,Frequencyname)
  select distinct S.MeasureCode,S.measurename,S.FrequencyCode,S.Frequencyname
  from
        (select MeasureCode,Max(measurename)     as measurename,
                FrequencyCode,Max(Frequencyname) as Frequencyname,
                count(*) as Availablecount
         from   @LT_QUOTEITEM_FINAL
         group  by MeasureCode,FrequencyCode         
        ) S
  where S.Availablecount = @LI_ProductCount 
  order by S.measurename ASC,S.Frequencyname ASC

  select @LVC_measurecode     =S.MeasureCode,
         @LVC_FrequencyCode   =S.FrequencyCode
  from   @LT_ValidVombination S
  where  S.IDSeq = 1

  -------------------------------------------------------
   -- combinations to fill the UI drop downs
  -------------------------------------------------------
  select S.FrequencyCode as frequencycode,S.Frequencyname as frequencyname 
  from   @LT_ValidVombination S 
  where  S.IDSeq = (select Min(D.IDSeq) 
                    from   @LT_ValidVombination D
                    where  D.FrequencyCode = S.FrequencyCode
                    )
  order by S.IDSeq ASC


  select S.MeasureCode   as measurecode,S.measurename     as measurename   
  from   @LT_ValidVombination S
  where  S.IDSeq = (select Min(D.IDSeq) 
                    from   @LT_ValidVombination D
                    where  D.MeasureCode = S.MeasureCode
                    )
  order by S.IDSeq ASC
  -----------------------------------------------------------------------------------------
  --Final Select statement
  ----------------------------------------------------------------------------------------- 
	  select distinct  Z.seq,  
					   Z.measurecode                                                 as measurecode,  
					   Z.measurename                                                 as measurename,  
					   Z.frequencycode                                               as frequencycode,  
					   Z.frequencyname                                               as frequencyname,  
					   Z.productcode                                                 as productcode,  
					   Z.familycode                                                  as familycode,  
					   Z.measurecode + ',' + Z.frequencycode                         as Measure_Freq_Comb,  
					   Z.quantity                                                    as quantity,  
					   Z.quantityenabledflag                                         as quantityenabledflag,  
					   Quotes.DBO.fn_FormatCurrency(Z.listpriceaccess,1,4)           as listpriceaccess,  
					   Z.accessdiscountpercent                                       as accessdiscountpercent,  
					   Z.accessdiscountamount                                        as accessdiscountamount,  
					   Quotes.DBO.fn_FormatCurrency(Z.accessnetprice,1,4)            as accessnetprice,  
					   Z.priceversion                                                as priceversion,  
					   Z.acsminunits                                                 as acsminunits,  
					   Z.acsmaxunits                                                 as acsmaxunits,  
					   Z.acscapmaxunitsflag                                          as acscapmaxunitsflag,  
					   Z.acsdollarminimum                                            as acsdollarminimum,  
					   Z.acsdollarminimumenabledflag                                 as acsdollarminimumenabledflag,  
					   Z.acsdollarmaximum                                            as acsdollarmaximum,  
					   Z.acsdollarmaximumenabledflag                                 as acsdollarmaximumenabledflag,  
					   Z.creditcardpercentageenabledflag                             as creditcardpercentageenabledflag,  
					   Z.credtcardpricingpercentage                                  as credtcardpricingpercentage  
	  from @lt_quoteitem_final Z
          inner join
               @LT_ValidVombination R
          on   Z.measurecode=R.measurecode and Z.frequencycode=R.frequencycode
	  order by Z.productcode ASC,Z.measurename ASC,Z.Frequencyname ASC
  -----------------------------------------------------------------------------------------
  -- Select ListPrice and AccessPrice 
  ----------------------------------------------------------------------------------------- 
  select sum(listpriceaccess) as listpriceaccess,
         sum(accessnetprice)  as accessnetprice
  from  @lt_quoteitem_final Z            
  where Z.measurecode   = @LVC_measurecode
  and   Z.frequencycode = @LVC_frequencycode
  -----------------------------------------------------------------------------------------
  -- Select ProductCodes
  ----------------------------------------------------------------------------------------- 
   select distinct Z.productcode as ProductCode,Z.productdisplayname,@LVC_GroupName as Ordergroupname,
                   @LVC_GroupDescription as  Ordergroupdescription
   from   @lt_quoteitem_final Z
   inner join
          @LT_ValidVombination R
   on   Z.measurecode=R.measurecode and Z.frequencycode=R.frequencycode 
   order by Z.productcode ASC
  -----------------------------------------------------------------------------------------
  -- Dropping Temporary Table 
  ----------------------------------------------------------------------------------------- 
  drop table #temp_OrderGroupProducts
END
GO
