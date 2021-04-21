SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec uspQUOTES_RepDealSheet_GetPreviousOrderSummary 
@IPC_CompanyID='C0000000389',@IPVC_QuoteID='Q0000000050'       

----------------------------------------------------------------------
*/
CREATE PROCEDURE [quotes].[uspQUOTES_RepDealSheet_GetPreviousOrderSummary] (@IPC_CompanyID     varchar(50),
                                                                 @IPVC_QuoteID      varchar(8000), 
                                                                 @IPVC_Delimiter    varchar(1)= '|'                                                                                                                                                                   
                                                                )
AS
BEGIN   
  set nocount on   
  -----------------------------------------------------------------------------------
  declare @LT_Quotes  TABLE (QuoteID varchar(50)) 
  -----------------------------------------------------------------------------------
  --Parse the string to get all the Quotes.
  insert into @LT_Quotes(QuoteID)
  select Items as QuoteID from QUOTES.dbo.fnSplitDelimitedString(@IPVC_QuoteID,@IPVC_Delimiter)
  -----------------------------------------------------------------------------------
  declare @LT_TempQuoteGroupProperties table (CompanyIDseq     varchar(50) NOT NULL default '0',
                                              PropertyIDSeq    varchar(50) NULL,
                                              Sites            bigint      NOT NULL default 0,
                                              Units            bigint      NOT NULL default 0
                                              )  
 
  declare @LT_bporderdetail  TABLE (SEQ                      int not null identity(1,1),
                                    companyid                varchar(50)   NOT NULL default '',
                                    propertyid               varchar(50)   NULL default '',
                                    Sites                    bigint        NOT NULL default 0,
                                    units                    bigint        NOT NULL default 0,
                                    productcode              varchar(100)  NOT NULL default '',
                                    productdisplayname       varchar(500)  NOT NULL default '',
                                    measurecode              varchar(20)   NOT NULL default '',
                                    sortseq                  bigint        not null default 0,
                                    quantity                 numeric(30,2) NOT NULL default 0.00,
                                    ListAccess               money         NOT NULL default 0.00,
                                    extchargeamount          money         NOT NULL default 0.00,
                                    Netprice                 money         NOT NULL default 0.00,
                                    extyear1chargeamount     money         NOT NULL default 0.00,
                                    netextyear1chargeamount  money         NOT NULL default 0.00
                                   )
  -----------------------------------------------------------------------------------
  insert into @LT_TempQuoteGroupProperties(CompanyIDseq,PropertyIDSeq,Sites,Units)
  select distinct G.CustomerIDSeq as CompanyIDseq,
         GP.PropertyIDSeq         as PropertyIDSeq,
         1                        as Sites,
         coalesce(P.Units,0)      as units
  from   Quotes.dbo.[Group] G with (nolock) 
  inner join
         @LT_Quotes S
  on      G.QuoteIDSeq    = S.QuoteID
  and     G.CustomerIDSeq = @IPC_CompanyID
  left outer Join 
         Quotes.dbo.[GroupProperties] GP with (nolock)
  on     G.QuoteIDSeq     = GP.QuoteIDSeq
  and    G.IDSeq          = GP.GroupIDSeq
  and    G.CustomerIDSeq  = GP.CustomerIDSeq 
  and    G.CustomerIDSeq  = @IPC_CompanyID
  and    GP.CustomerIDSeq = @IPC_CompanyID
  and    G.QuoteIDSeq     = S.QuoteID
  and    GP.QuoteIDSeq    = S.QuoteID
  left join CUSTOMERS.dbo.Property P (nolock) 
        on  GP.PropertyIDSeq= P.IDSeq         
  where G.QuoteIDSeq        = S.QuoteID 
  and   G.CustomerIDSeq     = @IPC_CompanyID

  update D
  set    D.Sites = coalesce((select count(S.IDSeq)
                             from CUSTOMERS.dbo.Property S
                             where S.PMCIDSeq = @IPC_CompanyID
                             and   S.PMCIDSeq = D.CompanyIDseq),0),
         D.units = coalesce((select sum(S.units)
                             from CUSTOMERS.dbo.Property S
                             where S.PMCIDSeq = @IPC_CompanyID
                             and   S.PMCIDSeq = D.CompanyIDseq),0)
  from   @LT_TempQuoteGroupProperties D
  where  PropertyIDSeq is null
  -----------------------------------------------------------------------------------  
  if (select count(*) from @LT_TempQuoteGroupProperties) > 0
  begin
    insert into @LT_bporderdetail(companyid,propertyid,
                                  sites,units,productcode,productdisplayname,measurecode,sortseq,
                                  quantity,ListAccess,extchargeamount,netprice,
                                  extyear1chargeamount,netextyear1chargeamount
                                 )
    select O.CompanyIDseq                  as CompanyIDseq,  
           O.PropertyIDseq                 as PropertyIDseq,
           sum(T.Sites)                    as Sites,
           sum(T.Units)                    as Units,
           OI.productcode                  as productcode,                  
           ltrim(rtrim(P.displayname))     as productdisplayname,
           OI.measurecode                  as measurecode, 
           P.sortseq                       as sortseq,
           sum(OI.Quantity)                as Quantity,                             
           sum(OI.chargeamount)            as ListAccess,
           sum(OI.ExtChargeAmount)         as ExtChargeAmount,
           sum(OI.NetChargeAmount)         as NetPrice,
           sum(OI.extyear1chargeamount)    as extyear1chargeamount,
           sum(OI.netextyear1chargeamount) as netextyear1chargeamount
    from   Orders.dbo.[Order] O with (nolock)
    inner join @LT_TempQuoteGroupProperties T 
    on    O.CompanyIDseq = T.CompanyIDseq
    and   isnull(O.PropertyIDSeq,'P') = isnull(T.PropertyIDSeq,'P') 
    and   not exists (select top 1 1 
                      from   @LT_Quotes S
                      where  isnull(O.QuoteIDSeq,'Q') = S.QuoteID 
                      )    
    inner join Orders.dbo.[OrderItem] OI with (nolock)
    on    O.OrderIDSeq = OI.OrderIDSeq 
    and   OI.ChargeTypeCode = 'ACS'       
    and   convert(datetime,convert(varchar(50),isnull(OI.ActivationEnddate,getdate()),101)) >= 
          convert(datetime,convert(varchar(50),getdate(),101))
    and not exists  (select  O1.OrderIDSeq
                       from  Orders.dbo.[Order] O1 with (nolock) 
                       inner join Orders.dbo.[OrderItem] B with (nolock)   
                       on    O1.CompanyIDseq = O.CompanyIDseq
                       and   isnull(O1.PropertyIDSeq,'P') = isnull(O.PropertyIDSeq,'P') 
                       and   not exists (select top 1 1 
                                         from   @LT_Quotes S
                                         where  isnull(O1.QuoteIDSeq,'Q') = S.QuoteID 
                                         ) 
                       and   O1.OrderIDSeq = B.OrderIDSeq
                       and   B.ChargeTypeCode = OI.ChargeTypeCode
                       and   B.productcode    = OI.productcode
                       and   B.PriceVersion   = OI.PriceVersion
                       and   B.ChargeTypeCode = 'ACS' 
                       and   convert(datetime,convert(varchar(50),isnull(B.ActivationEnddate,getdate()),101)) >  
                             convert(datetime,convert(varchar(50),isnull(OI.ActivationEnddate,getdate()),101)) 
                      ) 
    inner join Products.dbo.Product P with (nolock)
    on    OI.productcode  = P.Code
    and   OI.PriceVersion = P.PriceVersion   
    group by O.CompanyIDseq,O.PropertyIDseq,OI.productcode,ltrim(rtrim(P.displayname)),P.SortSeq,
             OI.measurecode 
    order by sortseq asc
  end
  else 
  begin
    Insert into @LT_bporderdetail(companyid,propertyid)
    select @IPC_CompanyID as companyid, NULL as propertyid
  end
  -----------------------------------------------------------------------------------
  declare @LT_BPOrderSummary TABLE (seq                       bigint        not null default 1,                                     
                                     fees                     varchar(100)  not null default 'Access Fees - Year I',
                                     sites                    int           not null default 0,
                                     units                    int           not null default 0,
                                     listprice                money         not null default 0,  
                                     discountpercent          as  ((listprice-netprice)* (100)/
                                                                   (case when listprice=0 then 1 
                                                                         else listprice 
                                                                    end
                                                                   )                                                        
                                                                  ),
                                     discountamount           as (listprice-netprice),
                                     netprice                 money         not null default 0,
                                     averagespersite          as ((netprice)/(case when sites = 0 then 1 else sites end)),
                                     averagesperunit          as ((netprice)/(case when units = 0 then 1 else units end))
                                    )
  if (select count(*) from @LT_bporderdetail) >0
  begin
    insert into @LT_BPOrderSummary(seq,fees,sites,units,listprice,netprice)
    select 1 as seq,           
             'Access Fees - Current Year'          as fees,
             coalesce(count(S.PropertyID),0)       as sites,
             coalesce(sum(S.units),0)              as units,
             sum(S.ExtYear1ChargeAmount)           as listprice,         
             sum(S.NetExtYear1ChargeAmount)        as netprice  
    from   @LT_bporderdetail S
  end

  if (select count(*) from @LT_BPOrderSummary) = 0
  begin 
    insert into @LT_BPOrderSummary(seq,fees,sites,units,listprice,netprice)
    select 1 as Seq,
           'Access Fees - Current Year' as fees,0 as sites,0 as units,0 as listprice,0 as netprice      
  end  
  
  -----------------------------------------------------------------------------------
  -- Final Select 
  ----select * from @LT_bporderdetail
  -----------------------------------------------------------------------------------
  select Z.fees                                               as fees,
         Quotes.DBO.fn_FormatCurrency(Z.listprice,0,0)        as listprice,
         Quotes.DBO.fn_FormatCurrency(Z.discountpercent,0,0)  as discountpercent,
         Quotes.DBO.fn_FormatCurrency(Z.discountamount,0,0)   as discountamount,
         Quotes.DBO.fn_FormatCurrency(Z.netprice,0,0)         as netprice,
         Quotes.DBO.fn_FormatCurrency(Z.averagespersite,0,01) as averagespersite,
         Quotes.DBO.fn_FormatCurrency(Z.averagesperunit,1,2)  as averagesperunit
  from @LT_BPOrderSummary Z
  order by Z.seq asc  
END

GO
