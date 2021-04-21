SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
---Syntax:
-----------------------------------------------------------------------------
----Average Per SITE
-----------------------------------------------------------------------------
Exec uspQUOTES_GraphBPDeal @IPC_CompanyID = 'A0000000006',@IPVC_QuoteID = 48,
     @IPI_ScaleFactor=1,@IPI_GetProductNames=0,@IPVC_DisplayType='AVGPERSITE',
     @IPVC_DisplayNumOrPercent='NUMBER',@IPVC_RETURNTYPE='RECORDSET'
-----------------------------------------------------------------------------
----Average Per UNIT
-----------------------------------------------------------------------------
Exec uspQUOTES_GraphBPDeal @IPC_CompanyID = 'A0000000006',@IPVC_QuoteID = 48,
     @IPI_ScaleFactor=1,@IPI_GetProductNames=0,@IPVC_DisplayType='AVGPERUNIT',
     @IPVC_DisplayNumOrPercent='NUMBER',@IPVC_RETURNTYPE='RECORDSET'
-----------------------------------------------------------------------------
----Deal Summary
-----------------------------------------------------------------------------
Exec uspQUOTES_GraphBPDeal @IPC_CompanyID = 'A0000000006',@IPVC_QuoteID = 48,
     @IPI_ScaleFactor=1,@IPI_GetProductNames=0,@IPVC_DisplayType='NET',
     @IPVC_DisplayNumOrPercent='NUMBER',@IPVC_RETURNTYPE='RECORDSET'
-------Get Product Names-----
Exec uspQUOTES_GraphBPDeal @IPC_CompanyID = 'A0000000006',@IPVC_QuoteID = 48,
     @IPI_ScaleFactor=1,@IPI_GetProductNames=1,@IPVC_DisplayType='NET',
     @IPVC_DisplayNumOrPercent='NUMBER',@IPVC_RETURNTYPE='RECORDSET'

-----------------------------------------------------------------------------
----Discount Percent
-----------------------------------------------------------------------------
Exec uspQUOTES_GraphBPDeal @IPC_CompanyID = 'A0000000006',@IPVC_QuoteID = 48,
     @IPI_ScaleFactor=1,@IPI_GetProductNames=0,@IPVC_DisplayType='DISCOUNT',
     @IPVC_DisplayNumOrPercent='PERCENT',@IPVC_RETURNTYPE='RECORDSET'
-------Get Product Names-----
Exec uspQUOTES_GraphBPDeal @IPC_CompanyID = 'A0000000006',@IPVC_QuoteID = 48,
     @IPI_ScaleFactor=1,@IPI_GetProductNames=1,@IPVC_DisplayType='DISCOUNT',
     @IPVC_DisplayNumOrPercent='PERCENT',@IPVC_RETURNTYPE='RECORDSET'
-----------------------------------------------------------------------------
----Discount in NUMBER
-----------------------------------------------------------------------------
Exec uspQUOTES_GraphBPDeal @IPC_CompanyID = 'A0000000006',@IPVC_QuoteID = 48,
     @IPI_ScaleFactor=1,@IPI_GetProductNames=0,@IPVC_DisplayType='DISCOUNT',
     @IPVC_DisplayNumOrPercent='NUMBER',@IPVC_RETURNTYPE='RECORDSET'
-------Get Product Names-----
Exec uspQUOTES_GraphBPDeal @IPC_CompanyID = 'A0000000006',@IPVC_QuoteID = 48,
     @IPI_ScaleFactor=1,@IPI_GetProductNames=1,@IPVC_DisplayType='DISCOUNT',
     @IPVC_DisplayNumOrPercent='NUMBER',@IPVC_RETURNTYPE='RECORDSET'
-----------------------------------------------------------------------------
*/
CREATE PROCEDURE [quotes].[uspQUOTES_GraphBPDeal] (@IPC_CompanyID            varchar(11),
                                                @IPVC_QuoteID             varchar(50), 
                                                @IPI_ScaleFactor          bigint      = 1000,
                                                @IPI_GetProductNames      int         = 0,
                                                @IPVC_DisplayType         varchar(100)= 'NET',
                                                @IPVC_DisplayNumOrPercent varchar(50) = 'NUMBER',
                                                @IPVC_RETURNTYPE          varchar(100)= 'XML'    
                                                )
AS
BEGIN   
  set nocount on 
  -----------------------------------------------------------------------------------
  --Declaring Local Table Variable
  declare @LI_QuoteSites                      int
  declare @LI_QuoteUnits                      int  
  declare @LN_totalilfdiscountamount          money
  declare @LN_totalaccessyear1discountamount  money
  declare @LN_totalaccessyear2discountamount  money
  declare @LN_totalaccessyear3discountamount  money

  select  @LN_totalilfdiscountamount=0.00,@LN_totalaccessyear1discountamount = 0.00,
          @LN_totalaccessyear2discountamount = 0.00,@LN_totalaccessyear3discountamount = 0.00,
          @LI_QuoteSites=1,@LI_QuoteUnits=1
  ----------------------------------------------------------------------------------
  declare @LT_GraphBPDeal           TABLE (seq                      bigint        not null default 0,                                             
                                           quoteid                  varchar(50)   not null default '0',  
                                           productname              varchar(200)  not null default '',
                                           productdisplayname       varchar(200)  not null default '',
                                           productcode              varchar(50)   not null default '',     
                                           ilf                      numeric(30,2) not null default 0,
                                           y1                       numeric(30,2) not null default 0,
                                           y2                       numeric(30,2) not null default 0,
                                           y3                       numeric(30,2) not null default 0
                                          )
  declare @LT_BPQuoteProductdetails TABLE (seq                        bigint         not null identity(1,1),                                             
                                           quoteid                    varchar(50)    not null default '0',  
                                           productname                varchar(200)   not null default '',
                                           productdisplayname         varchar(200)   not null default '',
                                           productcode                varchar(50)    not null default '', 
                                           ilfextyearchargeamount     money          not null default 0,  
                                           ilfnetextyearchargeamount  money          not null default 0, 
                                           ilfdiscountpercent         as ((ilfextyearchargeamount-ilfnetextyearchargeamount)*(100)/
                                                                           (case when ilfextyearchargeamount=0 then 1 
                                                                                 else ilfextyearchargeamount
                                                                            end
                                                                           )
                                                                          ),
                                           ilfdiscountamount          as (ilfextyearchargeamount-ilfnetextyearchargeamount),
                                           ---------------------------------------------------------------------------
                                           accessextyear1chargeamount    money          not null default 0, 
                                           accessnetextyear1chargeamount money          not null default 0, 
                                           accessyear1discountpercent as ((accessextyear1chargeamount-accessnetextyear1chargeamount)*(100)/
                                                                           (case when accessextyear1chargeamount=0 then 1 
                                                                                 else accessextyear1chargeamount
                                                                            end
                                                                           )
                                                                          ), 
                                           accessyear1discountamount  as (accessextyear1chargeamount-accessnetextyear1chargeamount),
                                           ---------------------------------------------------------------------------
                                           accessextyear2chargeamount    money          not null default 0, 
                                           accessnetextyear2chargeamount money          not null default 0, 
                                           accessyear2discountpercent as ((accessextyear2chargeamount-accessnetextyear2chargeamount)*(100)/
                                                                           (case when accessextyear2chargeamount=0 then 1 
                                                                                 else accessextyear2chargeamount
                                                                            end
                                                                           )
                                                                          ), 
                                           accessyear2discountamount  as (accessextyear2chargeamount-accessnetextyear2chargeamount),
                                           --------------------------------------------------------------------------- 
                                           accessextyear3chargeamount    money          not null default 0, 
                                           accessnetextyear3chargeamount money          not null default 0, 
                                           accessyear3discountpercent as ((accessextyear3chargeamount-accessnetextyear3chargeamount)*(100)/
                                                                           (case when accessextyear3chargeamount=0 then 1 
                                                                                 else accessextyear3chargeamount
                                                                            end
                                                                           )
                                                                          ), 
                                           accessyear3discountamount  as (accessextyear3chargeamount-accessnetextyear3chargeamount),
                                           ----------------------------------------------------------------------------
                                           internalsortcolumn         money not null default 0
                                         )

  ----------------------------------------------------------------------------------
  if exists (select top 1 1 from QUOTES.DBO.[Quote] (nolock)
             where QuoteIDseq = @IPVC_QuoteID
            )
  begin --> Begining of @LT_BPQuoteProductdetails populate
    select @LI_QuoteSites = Sites,@LI_QuoteUnits = Units
    from   QUOTES.dbo.Quote (nolock) where QuoteIDseq = @IPVC_QuoteID 

    select @LI_QuoteUnits = (case when @LI_QuoteUnits = 0 then 1 else @LI_QuoteUnits end),
           @LI_QuoteSites = (case when @LI_QuoteSites = 0 then 1 else @LI_QuoteSites end) 
    --------------------------------------------------------------------------------------------- 
    insert into @LT_BPQuoteProductdetails(quoteid,productcode,productname,productdisplayname,
                                          ilfextyearchargeamount,ilfnetextyearchargeamount,
                                          accessextyear1chargeamount,accessnetextyear1chargeamount,
                                          accessextyear2chargeamount,accessnetextyear2chargeamount,
                                          accessextyear3chargeamount,accessnetextyear3chargeamount,
                                          internalsortcolumn
                                         )
    select distinct QI.QuoteIDseq                                              as quoteid,
                    QI.productcode                                             as productcode,
                    (select Top 1 ltrim(rtrim(X.Name)) 
                     from Products.dbo.Product X (nolock)
                     where ltrim(rtrim(X.code)) = ltrim(rtrim(QI.productcode))
                    )                                                          as productname,
                    (select Top 1 ltrim(rtrim(X.DisplayName)) 
                     from Products.dbo.Product X (nolock)
                     where ltrim(rtrim(X.code)) = ltrim(rtrim(QI.productcode))
                    )                                                          as productdisplayname,
                     -----------------------------------------------------------------
                     coalesce((select sum(B.extyear1chargeamount) 
                               from   QUOTES.dbo.quoteitem B (nolock)
                               where  B.quoteidseq     = QI.QuoteIDseq
                               and    B.productcode = QI.productcode
                               and    B.chargetypecode = 'ILF'),0)             as ilfextyearchargeamount,
                     coalesce((select sum(B.netextyear1chargeamount) 
                               from   QUOTES.dbo.quoteitem B (nolock)
                               where  B.quoteidseq     = QI.QuoteIDseq
                               and    B.productcode = QI.productcode
                               and    B.chargetypecode = 'ILF'),0)             as ilfnetextyearchargeamount,
                     ----------------------------------------------------------------- 
                     coalesce((select sum(B.extyear1chargeamount) 
                               from   QUOTES.dbo.quoteitem B (nolock)
                               where  B.quoteidseq     = QI.QuoteIDseq
                               and    B.productcode = QI.productcode
                               and    B.chargetypecode = 'ACS'),0)             as accessextyear1chargeamount,
                     coalesce((select sum(B.netextyear1chargeamount) 
                               from   QUOTES.dbo.quoteitem B (nolock)
                               where  B.quoteidseq     = QI.QuoteIDseq
                               and    B.productcode = QI.productcode
                               and    B.chargetypecode = 'ACS'),0)             as accessnetextyear1chargeamount,
                     -----------------------------------------------------------------
                     coalesce((select sum(B.extyear2chargeamount) 
                               from   QUOTES.dbo.quoteitem B (nolock)
                               where  B.quoteidseq     = QI.QuoteIDseq
                               and    B.productcode = QI.productcode
                               and    B.chargetypecode = 'ACS'),0)             as accessextyear2chargeamount,
                     coalesce((select sum(B.netextyear2chargeamount) 
                               from   QUOTES.dbo.quoteitem B (nolock)
                               where  B.quoteidseq     = QI.QuoteIDseq
                               and    B.productcode = QI.productcode
                               and    B.chargetypecode = 'ACS'),0)             as accessnetextyear2chargeamount,
                     -----------------------------------------------------------------
                     coalesce((select sum(B.extyear3chargeamount) 
                               from   QUOTES.dbo.quoteitem B (nolock)
                               where  B.quoteidseq     = QI.QuoteIDseq
                               and    B.productcode = QI.productcode
                               and    B.chargetypecode = 'ACS'),0)             as accessextyear3chargeamount,
                     coalesce((select sum(B.netextyear3chargeamount) 
                               from   QUOTES.dbo.quoteitem B (nolock)
                               where  B.quoteidseq     = QI.QuoteIDseq
                               and    B.productcode = QI.productcode
                               and    B.chargetypecode = 'ACS'),0)             as accessnetextyear3chargeamount,
                    -----------------------------------------------------------------  
                    (case when @IPVC_DisplayType = 'DISCOUNT' then
                                       coalesce((select sum(B.extyear1chargeamount) 
                                                 from   QUOTES.dbo.quoteitem B (nolock) 
                                                 where  B.quoteidseq     = QI.QuoteIDseq
                                                 and    B.productcode = QI.productcode
                                                 and    B.chargetypecode in ('ACS','ILF')),0)-
                                       coalesce((select sum(B.netextyear1chargeamount) 
                                                 from   QUOTES.dbo.quoteitem B (nolock) 
                                                 where  B.quoteidseq     = QI.QuoteIDseq
                                                 and    B.productcode = QI.productcode
                                                 and    B.chargetypecode in ('ACS','ILF')),0)                          
                          else         coalesce((select sum(B.extyear1chargeamount) 
                                                 from   QUOTES.dbo.quoteitem B (nolock) 
                                                 where  B.quoteidseq     = QI.QuoteIDseq
                                                 and    B.productcode = QI.productcode
                                                 and    B.chargetypecode in ('ACS','ILF')),0)
                     end
                     )                                                         as internalsortcolumn  
    from   QUOTES.dbo.quoteitem QI (nolock)
    where  QI.QuoteIDseq = @IPVC_QuoteID  
    group  by QI.QuoteIDseq,QI.productcode   
    order  by internalsortcolumn desc             
    ---------------------------------------------------------------------------------------------
    if @IPVC_DisplayType = 'NET'
    begin
      insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,
                                  ilf,y1,y2,y3)
      select seq,quoteid,productcode,productname,productdisplayname,sum(ilfnetextyearchargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear1chargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear2chargeamount)/@IPI_ScaleFactor,sum(accessnetextyear3chargeamount)/@IPI_ScaleFactor
      from @LT_BPQuoteProductdetails where seq <= 3
      group by  seq,quoteid,productcode,productname,productdisplayname
      order by  seq asc

      insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,
                                  ilf,y1,y2,y3)                
      select 99999,quoteid,'Others' as productcode, 'Others' as productname,'Others' as productdisplayname,
             sum(ilfnetextyearchargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear1chargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear2chargeamount)/@IPI_ScaleFactor,sum(accessnetextyear3chargeamount)/@IPI_ScaleFactor
      from @LT_BPQuoteProductdetails where seq > 3
      group by  quoteid 
    end  
    else if @IPVC_DisplayType = 'AVGPERSITE'  
    begin
      insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,
                                  ilf,y1,y2,y3)
      select 1 as seq,quoteid,'' as productcode,'' as productname,'' as productdisplayname,
             (sum(ilfnetextyearchargeamount)/(@LI_QuoteSites))/(@IPI_ScaleFactor),
             (sum(accessnetextyear1chargeamount)/(@LI_QuoteSites))/(@IPI_ScaleFactor),
             (sum(accessnetextyear2chargeamount)/(@LI_QuoteSites))/(@IPI_ScaleFactor),
             (sum(accessnetextyear3chargeamount)/(@LI_QuoteSites))/(@IPI_ScaleFactor)
      from @LT_BPQuoteProductdetails 
      group by  quoteid      
    end
    else if @IPVC_DisplayType = 'AVGPERUNIT'  
    begin
      insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,
                                  ilf,y1,y2,y3)
      select 1 as seq,quoteid,'' as productcode,'' as productname,'' as productdisplayname,
             (sum(ilfnetextyearchargeamount)/(@LI_QuoteUnits))/(@IPI_ScaleFactor),
             (sum(accessnetextyear1chargeamount)/(@LI_QuoteUnits))/(@IPI_ScaleFactor),
             (sum(accessnetextyear2chargeamount)/(@LI_QuoteUnits))/(@IPI_ScaleFactor),
             (sum(accessnetextyear3chargeamount)/(@LI_QuoteUnits))/(@IPI_ScaleFactor)
      from @LT_BPQuoteProductdetails 
      group by  quoteid      
    end
    else if @IPVC_DisplayType = 'DISCOUNT'  
    begin
      if @IPVC_DisplayNumOrPercent = 'PERCENT'
      begin
        select @LN_totalilfdiscountamount         =sum(ilfdiscountamount),
               @LN_totalaccessyear1discountamount =sum(accessyear1discountamount),
               @LN_totalaccessyear2discountamount =sum(accessyear2discountamount),
               @LN_totalaccessyear3discountamount =sum(accessyear3discountamount)
        from @LT_BPQuoteProductdetails
        -----------------------------------------------------------------------------------------------------------
        insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,ilf,y1,y2,y3)
        select seq,quoteid,productcode,productname,productdisplayname,
               sum(ilfdiscountamount)/(case when @LN_totalilfdiscountamount=0 then 1 else @LN_totalilfdiscountamount end),
               sum(accessyear1discountamount)/(case when @LN_totalaccessyear1discountamount=0 then 1 else @LN_totalaccessyear1discountamount end),
               sum(accessyear2discountamount)/(case when @LN_totalaccessyear2discountamount=0 then 1 else @LN_totalaccessyear2discountamount end),
               sum(accessyear3discountamount)/(case when @LN_totalaccessyear3discountamount=0 then 1 else @LN_totalaccessyear3discountamount end)
        from @LT_BPQuoteProductdetails where seq <= 3
        group by  seq,quoteid,productcode,productname,productdisplayname
        order by  seq asc

        insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,ilf,y1,y2,y3)                
        select 99999,quoteid,'Others' as productcode, 'Others' as productname,'Others' as productdisplayname,
               sum(ilfdiscountamount)/(case when @LN_totalilfdiscountamount=0 then 1 else @LN_totalilfdiscountamount end),
               sum(accessyear1discountamount)/(case when @LN_totalaccessyear1discountamount=0 then 1 else @LN_totalaccessyear1discountamount end),
               sum(accessyear2discountamount)/(case when @LN_totalaccessyear2discountamount=0 then 1 else @LN_totalaccessyear2discountamount end),
               sum(accessyear3discountamount)/(case when @LN_totalaccessyear3discountamount=0 then 1 else @LN_totalaccessyear3discountamount end)
        from @LT_BPQuoteProductdetails where seq > 3
        group by  quoteid     
      end  
      else
      begin
        insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,ilf,y1,y2,y3)
        select seq,quoteid,productcode,productname,productdisplayname,sum(ilfdiscountamount)/@IPI_ScaleFactor,
               sum(accessyear1discountamount)/@IPI_ScaleFactor,
               sum(accessyear2discountamount)/@IPI_ScaleFactor,sum(accessyear3discountamount)/@IPI_ScaleFactor
        from @LT_BPQuoteProductdetails where seq <= 3
        group by  seq,quoteid,productcode,productname,productdisplayname
        order by  seq asc

        insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,ilf,y1,y2,y3)                
        select 99999,quoteid,'Others' as productcode, 'Others' as productname,'Others' as productdisplayname,
               sum(ilfdiscountamount)/@IPI_ScaleFactor,
               sum(accessyear1discountamount)/@IPI_ScaleFactor,
               sum(accessyear2discountamount)/@IPI_ScaleFactor,sum(accessyear3discountamount)/@IPI_ScaleFactor
        from @LT_BPQuoteProductdetails where seq > 3
        group by  quoteid 
      end
    end
    ---------------------------------------------------------------------------------------------
  end  
  -----------------------------------------------------------------------------------------------
  if (select count(*) from @LT_GraphBPDeal)=0  
  begin
    insert into @LT_GraphBPDeal(seq,quoteid,productname,productdisplayname)
    select 1,@IPVC_QuoteID,'','' union select 2,@IPVC_QuoteID,'','' union 
    select 3,@IPVC_QuoteID,'','' union select 99999,@IPVC_QuoteID,'Others','Others'
  end
  ----------------------------------------------------------------------------------------
  ---Final Select
  --select * from @LT_BPQuoteProductdetails
  ----------------------------------------------------------------------------------------  
  --- Final Select
  ----------------------------------------------------------------------------------------  
  if @IPI_GetProductNames = 0
  begin   
    if @IPVC_RETURNTYPE = 'XML' 
    begin  
      WITH XMLNAMESPACES ('http://tempuri.org/data.xsd'  as nsl)
      select 'ILF'  as xvalue,
               coalesce((select ilf from @LT_GraphBPDeal where Seq = 1),0) as yvalue1,
               coalesce((select ilf from @LT_GraphBPDeal where Seq = 2),0) as yvalue2,
               coalesce((select ilf from @LT_GraphBPDeal where Seq = 3),0) as yvalue3,
               coalesce((select sum(ilf) from @LT_GraphBPDeal where Seq > 3),0) as yvalue4    
      union
      select 'Y1'  as xvalue,
               coalesce((select Y1 from @LT_GraphBPDeal where Seq = 1),0) as yvalue1,
               coalesce((select Y1 from @LT_GraphBPDeal where Seq = 2),0) as yvalue2,
               coalesce((select Y1 from @LT_GraphBPDeal where Seq = 3),0) as yvalue3,
               coalesce((select sum(Y1) from @LT_GraphBPDeal where Seq > 3),0) as yvalue4   
      union
      select 'Y2'  as xvalue,
               coalesce((select Y2 from @LT_GraphBPDeal where Seq = 1),0) as yvalue1,
               coalesce((select Y2 from @LT_GraphBPDeal where Seq = 2),0) as yvalue2,
               coalesce((select Y2 from @LT_GraphBPDeal where Seq = 3),0) as yvalue3,
               coalesce((select sum(Y2) from @LT_GraphBPDeal where Seq > 3),0) as yvalue4
      union
      select 'Y3'  as xvalue,
               coalesce((select Y3 from @LT_GraphBPDeal where Seq = 1),0) as yvalue1,
               coalesce((select Y3 from @LT_GraphBPDeal where Seq = 2),0) as yvalue2,
               coalesce((select Y3 from @LT_GraphBPDeal where Seq = 3),0) as yvalue3,
               coalesce((select sum(Y3) from @LT_GraphBPDeal where Seq > 3),0) as yvalue4     
      FOR XML raw ,ROOT('root'),TYPE,elements    
    end
    else
    begin
      select 'ILF'  as xvalue,
               coalesce((select ilf from @LT_GraphBPDeal where Seq = 1),0) as yvalue1,
               coalesce((select ilf from @LT_GraphBPDeal where Seq = 2),0) as yvalue2,
               coalesce((select ilf from @LT_GraphBPDeal where Seq = 3),0) as yvalue3,
               coalesce((select sum(ilf) from @LT_GraphBPDeal where Seq > 3),0) as yvalue4    
      union
      select 'Y1'  as xvalue,
               coalesce((select Y1 from @LT_GraphBPDeal where Seq = 1),0) as yvalue1,
               coalesce((select Y1 from @LT_GraphBPDeal where Seq = 2),0) as yvalue2,
               coalesce((select Y1 from @LT_GraphBPDeal where Seq = 3),0) as yvalue3,
               coalesce((select sum(Y1) from @LT_GraphBPDeal where Seq > 3),0) as yvalue4   
      union
      select 'Y2'  as xvalue,
               coalesce((select Y2 from @LT_GraphBPDeal where Seq = 1),0) as yvalue1,
               coalesce((select Y2 from @LT_GraphBPDeal where Seq = 2),0) as yvalue2,
               coalesce((select Y2 from @LT_GraphBPDeal where Seq = 3),0) as yvalue3,
               coalesce((select sum(Y2) from @LT_GraphBPDeal where Seq > 3),0) as yvalue4
      union
      select 'Y3'  as xvalue,
               coalesce((select Y3 from @LT_GraphBPDeal where Seq = 1),0) as yvalue1,
               coalesce((select Y3 from @LT_GraphBPDeal where Seq = 2),0) as yvalue2,
               coalesce((select Y3 from @LT_GraphBPDeal where Seq = 3),0) as yvalue3,
               coalesce((select sum(Y3) from @LT_GraphBPDeal where Seq > 3),0) as yvalue4 
    end
  end
  else 
  begin
    ----------------------------------------------------------------------------------------------- 
    --- This select only returns productnames when @IPI_GetProductNames = 1
    -----------------------------------------------------------------------------------------------
    if @IPVC_RETURNTYPE = 'XML' 
    begin  
      WITH XMLNAMESPACES ('http://tempuri.org/data.xsd' as nsl)
      select productname,productdisplayname from @LT_GraphBPDeal
      order by Seq asc FOR XML raw,ROOT('root'),TYPE 
    end
    else
    begin
      select productname,productdisplayname from @LT_GraphBPDeal
      order by Seq asc
    end
  end 
  -------------------------------------------------------------------------------------------------- 
END

GO
