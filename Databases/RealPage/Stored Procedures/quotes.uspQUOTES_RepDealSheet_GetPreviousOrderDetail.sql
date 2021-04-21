SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec uspQUOTES_RepDealSheet_GetPreviousOrderDetail 
@IPC_CompanyID='C0000000951',@IPVC_QuoteID='Q0000000560'
----------------------------------------------------------------------
*/
CREATE PROCEDURE [quotes].[uspQUOTES_RepDealSheet_GetPreviousOrderDetail]  (@IPC_CompanyID     varchar(50),
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
  declare @LT_Finalbpquotedetail table (sortseq          bigint        not null default 0,
                                  productcode            varchar(100)  not null default '',
                                  productname            varchar(500)  not null default '',
                                  measurecode            varchar(20)   not null default '',
                                  sites                  int           not null default 0,
                                  units                  int           not null default 0,
                                  ListAccess             money         not null default 0,                       
                                  NetListAccess          as 
                                                         ListAccess - ((ListAccess * (((ListExtAccess)-(NetExtAccess))*100/
                                                                                       (case when (ListExtAccess)=0 then 1
                                                                                             else (ListExtAccess)
                                                                                        end)
                                                                                      )
                                                                        )/100),  
                                  ListExtAccess          money         not null default 0,                                  
                                  NetExtAccess           money         not null default 0,                                   
                                  Accessdiscountpercent  as ((ListExtAccess)-(NetExtAccess))*100/
                                                            (case when (ListExtAccess)=0 then 1
                                                                  else (ListExtAccess)
                                                              end),
                                  Accessdiscountamount   as  ((ListExtAccess)-(NetExtAccess))
                                  
                                  )
 
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
    and not exists  (select O1.OrderIDSeq
                       from   Orders.dbo.[Order] O1 with (nolock) 
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
  
  if (select count(*) from @LT_bporderdetail)=0 
  begin
    Insert into @LT_bporderdetail(companyid,propertyid)
    select @IPC_CompanyID as companyid, NULL as propertyid
  end
  -----------------------------------------------------------------------------------  
  if (select count(*) from @LT_bporderdetail)>0 
  begin
    insert into @LT_Finalbpquotedetail(sortseq,productcode,productname,measurecode,units,sites,
                                       ListAccess,ListExtAccess,NetExtAccess)
    select distinct (SELECT TOP 1 X.sortseq FROM @LT_bporderdetail X
            WHERE X.productcode = Z.productcode) as sortseq, 
           Z.productcode,Z.productdisplayname,Z.measurecode,sum(Z.units),count(distinct Z.PropertyID),
           sum(distinct ListAccess) as ListAccess,
           sum(Z.ExtYear1ChargeAmount) as ListExtAccess,sum(Z.NetExtYear1ChargeAmount) as NetExtAccess
    from @LT_bporderdetail Z
    group by Z.productcode,Z.productdisplayname,Z.measurecode  
    order by  sortseq
  end
  else
  begin
    insert into @LT_Finalbpquotedetail(sortseq,productcode,productname,units,sites,ListAccess,
                                       ListExtAccess,NetExtAccess)
    select 0 as sortseq,'' as productcode,'' as productname,0 as units,0 as sites,0 as ListAccess,
           0 as ListExtAccess,0 as NetExtAccess
  end
  -----------------------------------------------------------------------------------  
  insert into @LT_Finalbpquotedetail(sortseq,productcode,productname,units,sites,ListAccess,ListExtAccess,NetExtAccess)
  select 999999 as sortseq,'Total' as  productcode,'Total' as productname,
         sum(units) as units,sum(sites) as sites,sum(ListAccess) as ListAccess,
         sum(ListExtAccess) as ListExtAccess,sum(NetExtAccess) as NetExtAccess
  from   @LT_Finalbpquotedetail
  -----------------------------------------------------------------------------------  
  -- Final Select 
  ----select * from @LT_bporderdetail
  -----------------------------------------------------------------------------------
  select   A.productname                                                   as productname,
           Quotes.DBO.fn_FormatCurrency(A.sites,0,0)                       as sites, 
           Quotes.DBO.fn_FormatCurrency(A.units,0,0)                       as units,
           A.measurecode                                                   as priceby,
           Quotes.DBO.fn_FormatCurrency(A.NetListAccess,1,2)               as price,
           Quotes.DBO.fn_FormatCurrency(A.ListExtAccess,0,0)               as ListAccess,
           Quotes.DBO.fn_FormatCurrency(A.Accessdiscountpercent,0,0)       as discountpercent,
           Quotes.DBO.fn_FormatCurrency(A.Accessdiscountamount,0,0)        as discountamount,                  
           Quotes.DBO.fn_FormatCurrency(A.NetExtAccess,0,0)                as NetAccess
  from   @LT_Finalbpquotedetail A
  order by A.SortSeq asc,A.productname asc
  -----------------------------------------------------------------------------------
END

GO
