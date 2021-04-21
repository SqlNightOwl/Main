SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec ORDERS.dbo.uspORDERS_SyncOrderGroupAndOrderItem @IPVC_OrderID=10,@IPI_GroupID=10
*/

CREATE PROCEDURE [orders].[uspORDERS_SyncOrderGroupAndOrderItem] (@IPVC_OrderID       varchar(50),
                                                               @IPI_GroupID        bigint=NULL
                                                              )
AS
BEGIN   
  set nocount on 
  -----------------------------------------------------------------------------------
  --Declaring Local Variables
  declare @LI_Min              int
  declare @LI_Max              int
  declare @LI_GroupID          bigint

  declare @LVC_DelimitedNotes  varchar(8000)
  declare @LVC_LineItemNotes   varchar(8000)
  declare @LI_Imin             int
  declare @LI_IMax             int
  declare @LVC_OrderIDSeq      varchar(50)
  declare @LI_OrderItemIDSeq   bigint

  declare @LVC_accountidseq    varchar(50)
  declare @LVC_companyidseq    varchar(50)
  declare @LVC_propertyidseq   varchar(50)
  declare @LVC_DocumentIDSeq   varchar(50)  

  select @LI_Min=1,@LI_Max=0,@LI_Imin=1,@LI_IMax=0
  -----------------------------------------------------------------------------------
  --Declaring Local Variable Tables 
  create table #LT_OrderBundles (SEQ                      int not null identity(1,1),
                                 orderid                  varchar(50),
                                 groupid                  bigint
                                )                  
  create table #LT_OrderItem    (SEQ                      int not null identity(1,1),                                 
                                 orderid                  varchar(50),
                                 groupid                  bigint, 
                                 orderitemid              bigint,
                                 statuscode               varchar(50),
                                 renewaltypecode          varchar(50),
                                 productcode              varchar(100),                                 
                                 productcategorycode      varchar(50),
                                 familycode               varchar(20)   not null default '',                                 
                                 chargetypecode           varchar(50),
                                 measurecode              varchar(20)   not null default '',                                
                                 frequencycode            varchar(20)   not null default '',                                 
                                 chargeamount             money         not null default 0,
                                 discountpercent          float         not null default 0.00,
                                 discountamount           numeric(30,2) not null default 0,
                                 totaldiscountpercent     float         not null default 0.00,
                                 totaldiscountamount      numeric(30,2) not null default 0,
                                 extchargeamount          numeric(30,2) not null default 0,
                                 extSOCchargeamount       numeric(30,2) not null default 0,
                                 unitofmeasure            numeric(30,5) not null default 0.00,                    
                                 multiplier               decimal(18,6) not null default 0.00,
                                 extyear1chargeamount     numeric(30,2) not null default 0,                                
                                 netchargeamount          numeric(30,3) not null default 0,
                                 netextchargeamount       numeric(30,2) not null default 0,
                                 netextyear1chargeamount  numeric(30,2) not null default 0,
                                 units                    int           not null default 0,
                                 beds                     int           not null default 0,
                                 ppupercentage            int           not null default 100,                   
                                 pricingtiers             int           not null default 1,
                                 PricingLineItemNotes     varchar(8000) null
                                )

  create table #LT_PricingLineItemNotes (Seq                      int ,                                                                       
                                         LineItemNotes            varchar(8000) null
                                        )
  -------------------------------------------------------------------------------------------------  
  if exists (select top 1 1 from ORDERS.DBO.[OrderGroup] (nolock)
             where OrderIDSeq = @IPVC_OrderID and IDSeq = @IPI_GroupID 
            )
  and      (@IPI_GroupID is not null and @IPI_GroupID <> 0 and @IPI_GroupID <> '')
  begin 
    insert into #LT_OrderBundles(orderid,groupid)
    select distinct OrderIDSeq as orderid,IDSeq as groupid
    from   ORDERS.DBO.[OrderGroup]  with (nolock)
    where  OrderIDSeq = @IPVC_OrderID and IDSeq = @IPI_GroupID 
  end
  else if exists (select top 1 1 from ORDERS.DBO.[OrderGroup] (nolock)
                  where OrderIDSeq = @IPVC_OrderID
                  )
  begin
    insert into #LT_OrderBundles(orderid,groupid)
    select distinct OrderIDSeq as orderid,IDSeq as groupid
    from   ORDERS.DBO.[OrderGroup]  with (nolock)
    where  OrderIDSeq = @IPVC_OrderID
  end
  --------------------------------------------------------------------------------------------- 
  select @LI_Min=1,@LI_Max = count(*) from #LT_OrderBundles with (nolock)
  while  @LI_Min <= @LI_Max
  begin
    select @LI_GroupID=groupid from #LT_OrderBundles  with (nolock) where SEQ = @LI_Min
    insert into #LT_OrderItem(orderid,groupid,orderitemid,statuscode,renewaltypecode,
                              productcode,productcategorycode,
                              familycode,chargetypecode,
                              measurecode,frequencycode,
                              chargeamount,
                              discountpercent,discountamount,totaldiscountpercent,totaldiscountamount,
                              extchargeamount,extSOCchargeamount,unitofmeasure,multiplier,extyear1chargeamount,                              
                              netchargeamount,netextchargeamount,netextyear1chargeamount,
                              units,beds,ppupercentage,
                              pricingtiers,PricingLineItemNotes)
    exec ORDERS.DBO.uspORDERS_PriceEngine @IPVC_OrderID=@IPVC_OrderID,@IPI_GroupID=@LI_GroupID
    select @LI_Min = @LI_Min+1
  end  
  select @LI_Min=1,@LI_Max=0
  --------------------------------------------------------------------------------------------- 
  select @LVC_accountidseq = S.accountidseq,
         @LVC_companyidseq = S.companyidseq,
         @LVC_propertyidseq= S.propertyidseq
  from   ORDERS.DBO.[ORDER] S with (nolock) 
  where  S.orderIDseq = @IPVC_OrderID
  --------------------------------------------------------------------------------------------- 
  --Update OrderItem Table
  update OI
  set    OI.chargeamount               = T.chargeamount,
         --OI.discountpercent          = T.discountpercent,
         OI.discountamount             = T.discountamount,
         OI.totaldiscountpercent       = T.totaldiscountpercent,
         OI.totaldiscountamount        = T.totaldiscountamount,
         OI.unitofmeasure              = T.unitofmeasure,
         OI.EffectiveQuantity          = T.multiplier,
         OI.extchargeamount            = T.extchargeamount,
         OI.extSOCchargeamount         = T.extSOCchargeamount,         
         OI.netchargeamount            = T.netextchargeamount, 
         OI.extyear1chargeamount       = T.extyear1chargeamount,
         OI.netextyear1chargeamount    = T.netextyear1chargeamount,
         OI.units                      = T.units,
         OI.beds                       = T.beds,
         OI.ppupercentage              = T.ppupercentage,
         OI.pricingtiers               = T.pricingtiers
  from   ORDERS.dbo.OrderItem OI with (nolock) 
  inner join 
         #LT_OrderItem T with (nolock) 
  on     OI.OrderIDSeq       = T.orderid
  and    OI.OrderGroupIDSeq  = T.groupid
  and    OI.IDSeq            = T.orderitemid      
  and    OI.statuscode       = T.statuscode
  and    OI.renewaltypecode  = T.renewaltypecode
  and    OI.productcode      = T.productcode
  and    OI.chargetypecode   = T.chargetypecode
  and    OI.measurecode      = T.measurecode
  and    OI.frequencycode    = T.frequencycode
  ---------------------------------------------------------------------------------------------
  --Update OrderGroup Table from OrderItem
  Update G
  set    G.ILFDiscountamount           = S.ILFDiscountamount,    --> ILFDiscountamount
         G.ILFDiscountPercent          = S.ILFDiscountPercent,   --> ILFDiscountPercent      
         G.AccessDiscountamount        = S.AccessDiscountamount, --> AccessDiscountamount
         G.AccessDiscountPercent       = S.AccessDiscountPercent --> AccessDiscountPercent        
  from  ORDERS.dbo.[ordergroup]  G with (nolock)
  INNER JOIN 
         (Select X.OrderGroupIDSeq    as    OrderGroupIDSeq,
                 X.OrderIDSeq         as    OrderIDSeq,
                (sum((case when X.ChargeTypecode = 'ILF' then X.extchargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ILF' then X.netchargeamount else 0 end)) 
                )                                                                                     as ILFDiscountamount, 
                (sum((case when X.ChargeTypecode = 'ILF' then X.extchargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ILF' then X.netchargeamount else 0 end)) 
                )*100
                /
                (case when sum((case when X.ChargeTypecode = 'ILF' then X.extchargeamount else 0 end)) = 0 then 1
                      else sum((case when X.ChargeTypecode = 'ILF' then X.extchargeamount else 0 end))
                 end
                )                                                                                     as ILFDiscountPercent,
                (sum((case when X.ChargeTypecode = 'ACS' then X.extchargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.netchargeamount else 0 end)) 
                )                                                                                     as AccessDiscountamount, 
                (sum((case when X.ChargeTypecode = 'ACS' then X.extchargeamount else 0 end))- 
                 sum((case when X.ChargeTypecode = 'ACS' then X.netchargeamount else 0 end)) 
                )*100
                /
                (case when sum((case when X.ChargeTypecode = 'ACS' then X.extchargeamount else 0 end)) = 0 then 1
                      else sum((case when X.ChargeTypecode = 'ACS' then X.extchargeamount else 0 end))
                 end
                )                                                                                     as AccessDiscountPercent
           from      [Orders].dbo.OrderItem X  with (nolock) 
           inner Join
                     (Select max(OI.renewalcount) as maxrenewalcount,
                             OI.OrderIDSeq as OrderIDSeq,OI.OrderGroupIDSeq,OI.ProductCode,
                             OI.ChargeTypeCode,OI.MeasureCode,OI.FrequencyCode
                      from   ORDERS.dbo.OrderItem OI with (nolock)
                      where  OI.OrderIDSeq = @IPVC_OrderID
                      and    (OI.StatusCode <> 'CNCL' or OI.StatusCode <> 'EXPD')
                      group by OI.OrderIDSeq,OI.OrderGroupIDSeq,OI.ProductCode,
                               OI.ChargeTypeCode,OI.MeasureCode,OI.FrequencyCode,
                               OI.StatusCode
                      ) XOUT
           on   X.OrderIDSeq         = XOUT.OrderIDSeq
           and  X.OrderIDSeq         = @IPVC_OrderID           
           and  XOUT.OrderIDSeq      = @IPVC_OrderID
           and  X.renewalcount       = XOUT.maxrenewalcount
           and  X.OrderGroupIDSeq    = XOUT.OrderGroupIDSeq                                                      
           and  X.ProductCode        = XOUT.ProductCode
           and  X.ChargeTypeCode     = XOUT.ChargeTypeCode
           and  X.MeasureCode        = XOUT.MeasureCode
           and  X.FrequencyCode      = XOUT.FrequencyCode       
           group by  X.OrderGroupIDSeq,X.OrderIDSeq
          ) S
  ON   G.OrderIDSeq      = S.OrderIDSeq
  AND  G.IDSeq           = S.OrderGroupIDSeq
  AND  G.OrderIDSeq      = @IPVC_OrderID
  AND  S.OrderIDSeq      = @IPVC_OrderID
  ---------------------------------------------------------------------------------------------  
  ---Insert Mandatory Line Item PricingLineItemNotes into Orders.dbo.OrderItemNote
  select @LI_Min=1,@LI_Max = count(*) from #LT_OrderItem with (nolock)
  while  @LI_Min <= @LI_Max
  begin
    --step 1 : Get the Orderid,OrderItemID and Corresponding Delimited LineItemNotes Text
    --         in local variables.
    select @LVC_OrderIDSeq    =S.orderid,
           @LI_OrderItemIDSeq =S.orderitemid,
           @LVC_DelimitedNotes=S.PricingLineItemNotes 
    from   #LT_OrderItem  S with (nolock) where SEQ = @LI_Min  
    --step 2: Delete from ORDERS.dbo.OrderItemNote for Orderid,OrderItemID and MandatoryFlag=1
    Delete from ORDERS.dbo.OrderItemNote
    where  OrderIDSeq    = @LVC_OrderIDSeq
    and    OrderItemIDSeq= @LI_OrderItemIDSeq
    and    MandatoryFlag = 1
    --Step 3: For @LVC_OrderIDSeq,@LI_OrderItemIDSeq, get the | Delimited LineItemNotes as rows 
    --        and Insert into ORDERS.dbo.OrderItemNote
    Truncate table #LT_PricingLineItemNotes
    Insert into #LT_PricingLineItemNotes(Seq,LineItemNotes)
    select seq,Items from ORDERS.[dbo].[fn_SplitDelimitedStringIntoRows](@LVC_DelimitedNotes,'|')

    select @LI_Imin=1,@LI_Imax = count(*) from #LT_PricingLineItemNotes with (nolock)
    while @LI_Imin <= @LI_Imax
    begin
      select @LVC_LineItemNotes=S.LineItemNotes
      from   #LT_PricingLineItemNotes S with (nolock)
      where  Seq = @LI_Imin
      if (@LVC_LineItemNotes <> '' and @LVC_LineItemNotes is not null)
      begin
        Insert into ORDERS.dbo.OrderItemNote(OrderIDSeq,OrderItemIDSeq,Title,Description,MandatoryFlag,PrintOnInvoiceFlag,SortSeq)
        select @LVC_OrderIDSeq as OrderIDSeq,@LI_OrderItemIDSeq as OrderItemIDSeq,
               'Mandatory Pricing Line Note For OrderItem :'+convert(varchar(50),@LI_OrderItemIDSeq) + ':' + convert(varchar(50),@LI_Imin) as Title,
               @LVC_LineItemNotes as Description,
               1 as MandatoryFlag,1 as PrintOnInvoiceFlag,
               @LI_Imin as SortSeq
        select @LVC_LineItemNotes = NULL
        select @LI_Imin = @LI_Imin+1
      end
    end
    select @LI_Imin=1,@LI_Imax=0,@LVC_LineItemNotes = NULL,@LVC_DelimitedNotes=NULL
    select @LI_Min = @LI_Min+1
  end  
  select @LI_Min=1,@LI_Max=0
  ---------------------------------------------------------------------------------------------
  --Final Cleanup  
  drop table #LT_OrderBundles
  drop table #LT_OrderItem
  drop table #LT_PricingLineItemNotes
  ---------------------------------------------------------------------------------------------
END

GO
