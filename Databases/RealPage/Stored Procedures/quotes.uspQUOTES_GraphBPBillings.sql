SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
---Syntax:
--------------------------------------------------------------------------------
----Net Billings in NUMBER :  @IPVC_ChargeType = 'ILF' or 'Y1' or 'Y2' or 'Y2'
--------------------------------------------------------------------------------
Exec uspQUOTES_GraphBPBillings @IPC_CompanyID = 'A0000022686',@IPVC_QuoteID = 104,
     @IPI_ScaleFactor=1,@IPVC_ChargeType='ILF',
     @IPVC_DisplayNumOrPercent='NUMBER',@IPVC_RETURNTYPE = 'RECORDSET'

Exec uspQUOTES_GraphBPBillings @IPC_CompanyID = 'A0000022686',@IPVC_QuoteID = 104,
     @IPI_ScaleFactor=1,@IPVC_ChargeType='Y3',
     @IPVC_DisplayNumOrPercent='NUMBER',@IPVC_RETURNTYPE = 'RECORDSET'
--------------------------------------------------------------------------------
----Net Billings in PERCENT : @IPVC_ChargeType = 'ILF' or 'Y1' or 'Y2' or 'Y2'
--------------------------------------------------------------------------------
Exec uspQUOTES_GraphBPBillings @IPC_CompanyID = 'A0000022686',@IPVC_QuoteID = 104,
     @IPI_ScaleFactor=1,@IPVC_ChargeType='Y2',
     @IPVC_DisplayNumOrPercent='PERCENT',@IPVC_RETURNTYPE = 'RECORDSET'
-----------------------------------------------------------------------------
*/
CREATE PROCEDURE [quotes].[uspQUOTES_GraphBPBillings] (@IPC_CompanyID             varchar(11),
                                                    @IPVC_QuoteID              varchar(50), 
                                                    @IPI_ScaleFactor           bigint = 1000,
                                                    @IPVC_ChargeType           varchar(20) = 'ILF',
                                                    @IPVC_DisplayNumOrPercent  varchar(50) = 'NUMBER',
                                                    @IPVC_RETURNTYPE           varchar(100)= 'XML'                                                      
                                                    )
AS
BEGIN   
  set nocount on   
  -----------------------------------------------------------------------------------
  --Declaring Local Table Variable  
  declare @LN_totalilfnetextyearchargeamount      money
  declare @LN_totalaccessnetextyear1chargeamount  money
  declare @LN_totalaccessnetextyear2chargeamount  money
  declare @LN_totalaccessnetextyear3chargeamount  money
  select @LN_totalilfnetextyearchargeamount=0.00,@LN_totalaccessnetextyear1chargeamount = 0.00,
         @LN_totalaccessnetextyear2chargeamount = 0.00,@LN_totalaccessnetextyear3chargeamount = 0.00   
  ----------------------------------------------------------------------------------
  declare @LT_GraphBPDeal           TABLE (seq                        bigint        not null default 0,                                             
                                           quoteid                    varchar(50)   not null default '0',  
                                           productname                varchar(200)  not null default '',
                                           productdisplayname         varchar(200)  not null default '',
                                           productcode                varchar(50)   not null default '',     
                                           ilf                        numeric(30,2) not null default 0,
                                           y1                         numeric(30,2) not null default 0,
                                           y2                         numeric(30,2) not null default 0,
                                           y3                         numeric(30,2) not null default 0
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
                    (case when @IPVC_ChargeType = 'ILF' then
                                       coalesce((select sum(B.netextyear1chargeamount) 
                                                 from   QUOTES.dbo.quoteitem B (nolock) 
                                                 where  B.quoteidseq     = QI.QuoteIDseq
                                                 and    B.productcode = QI.productcode
                                                 and    B.chargetypecode ='ILF'),0)
                          when @IPVC_ChargeType = 'Y1' then
                                       coalesce((select sum(B.netextyear1chargeamount) 
                                                 from   QUOTES.dbo.quoteitem B (nolock) 
                                                 where  B.quoteidseq     = QI.QuoteIDseq
                                                 and    B.productcode = QI.productcode
                                                 and    B.chargetypecode ='ACS'),0)
                          when @IPVC_ChargeType = 'Y2' then
                                       coalesce((select sum(B.netextyear2chargeamount) 
                                                 from   QUOTES.dbo.quoteitem B (nolock) 
                                                 where  B.quoteidseq     = QI.QuoteIDseq
                                                 and    B.productcode = QI.productcode
                                                 and    B.chargetypecode ='ACS'),0)
                           when @IPVC_ChargeType = 'Y3' then
                                       coalesce((select sum(B.netextyear3chargeamount) 
                                                 from   QUOTES.dbo.quoteitem B (nolock) 
                                                 where  B.quoteidseq     = QI.QuoteIDseq
                                                 and    B.productcode = QI.productcode
                                                 and    B.chargetypecode ='ACS'),0)

                          else         coalesce((select sum(B.netextyear1chargeamount) 
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
    if @IPVC_DisplayNumOrPercent = 'PERCENT'
    begin
      select @LN_totalilfnetextyearchargeamount     = sum(ilfnetextyearchargeamount),
             @LN_totalaccessnetextyear1chargeamount = sum(accessnetextyear1chargeamount),
             @LN_totalaccessnetextyear2chargeamount = sum(accessnetextyear2chargeamount),
             @LN_totalaccessnetextyear3chargeamount = sum(accessnetextyear3chargeamount)
      from @LT_BPQuoteProductdetails
       -----------------------------------------------------------------------------------------------------------
      insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,
                                  ilf,y1,y2,y3)
      select seq,quoteid,productcode,productname,productdisplayname,
             sum(ilfnetextyearchargeamount)*100/(case when @LN_totalilfnetextyearchargeamount=0 then 1 else @LN_totalilfnetextyearchargeamount end),
             sum(accessnetextyear1chargeamount)*100/(case when @LN_totalaccessnetextyear1chargeamount=0 then 1 else @LN_totalaccessnetextyear1chargeamount end),
             sum(accessnetextyear2chargeamount)*100/(case when @LN_totalaccessnetextyear2chargeamount=0 then 1 else @LN_totalaccessnetextyear2chargeamount end),
             sum(accessnetextyear3chargeamount)*100/(case when @LN_totalaccessnetextyear3chargeamount=0 then 1 else @LN_totalaccessnetextyear3chargeamount end)
      from @LT_BPQuoteProductdetails where seq <= 3
      group by  seq,quoteid,productcode,productname,productdisplayname
      order by  seq asc

      insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,
                                  ilf,y1,y2,y3)                
      select 99999,quoteid,'Others' as productcode, 'Others' as productname,'Others' as productdisplayname,
             sum(ilfnetextyearchargeamount)*100/(case when @LN_totalilfnetextyearchargeamount=0 then 1 else @LN_totalilfnetextyearchargeamount end),
             sum(accessnetextyear1chargeamount)*100/(case when @LN_totalaccessnetextyear1chargeamount=0 then 1 else @LN_totalaccessnetextyear1chargeamount end),
             sum(accessnetextyear2chargeamount)*100/(case when @LN_totalaccessnetextyear2chargeamount=0 then 1 else @LN_totalaccessnetextyear2chargeamount end),
             sum(accessnetextyear3chargeamount)*100/(case when @LN_totalaccessnetextyear3chargeamount=0 then 1 else @LN_totalaccessnetextyear3chargeamount end)
      from @LT_BPQuoteProductdetails where seq > 3
      group by  quoteid 
    end
    else
    begin
      insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,ilf,y1,y2,y3)
      select seq,quoteid,productcode,productname,productdisplayname,
             sum(ilfnetextyearchargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear1chargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear2chargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear3chargeamount)/@IPI_ScaleFactor
      from @LT_BPQuoteProductdetails where seq <= 3
      group by  seq,quoteid,productcode,productname,productdisplayname
      order by  seq asc

      insert into @LT_GraphBPDeal(seq,quoteid,productcode,productname,productdisplayname,ilf,y1,y2,y3)                
      select 99999,quoteid,'Others' as productcode, 'Others' as productname,'Others' as productdisplayname,
             sum(ilfnetextyearchargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear1chargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear2chargeamount)/@IPI_ScaleFactor,
             sum(accessnetextyear3chargeamount)/@IPI_ScaleFactor
      from @LT_BPQuoteProductdetails where seq > 3
      group by  quoteid 
    end
    -----------------------------------------------------------------------------------------------------------    
  end  --> End of @LT_BPQuoteProductdetails populate    
  -----------------------------------------------------------------------------------------------------------
  if (select count(*) from @LT_GraphBPDeal)=0 
  begin
    insert into @LT_GraphBPDeal(seq,quoteid,productname,productdisplayname)
    select 1,@IPVC_QuoteID,'','' union select 2,@IPVC_QuoteID,'','' union 
    select 3,@IPVC_QuoteID,'','' union select 99999,@IPVC_QuoteID,'Others','Others'
  end
  ----------------------------------------------------------------------------------------  
  --- Final Select
  ----------------------------------------------------------------------------------------  
  if @IPVC_RETURNTYPE = 'XML' 
  begin 
    WITH XMLNAMESPACES ('http://tempuri.org/data.xsd'  as nsl)
    select productdisplayname  as xvalue,
           (case when @IPVC_ChargeType = 'ILF' then ilf 
                 when @IPVC_ChargeType = 'Y1'  then Y1 
                 when @IPVC_ChargeType = 'Y2'  then Y2 
                 when @IPVC_ChargeType = 'Y3'  then Y3 
            end) as yvalue
    from   @LT_GraphBPDeal  
    order by Seq asc
    FOR XML raw ,ROOT('root'),TYPE,elements     
  end
  else 
  begin
    select productdisplayname  as xvalue,
           (case when @IPVC_ChargeType = 'ILF' then ilf 
                 when @IPVC_ChargeType = 'Y1'  then Y1 
                 when @IPVC_ChargeType = 'Y2'  then Y2 
                 when @IPVC_ChargeType = 'Y3'  then Y3 
            end) as yvalue
    from   @LT_GraphBPDeal  
    order by Seq asc
  end
  ---------------------------------------------------------------------------------------- 
END

GO
