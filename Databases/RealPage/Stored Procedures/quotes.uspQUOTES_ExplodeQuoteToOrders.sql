SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--exec uspQUOTES_ExplodeQuoteToOrders @IPVC_QuoteID = 3
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_ExplodeQuoteToOrders
-- Description     : This procedure creates Orders For a given approved quote.
-- Input Parameters: 1. @IPVC_QuoteID   as varchar(20)
--                   
-- OUTPUT          : None
--  
--                   
-- Code Example    : exec QUOTES.dbo.uspQUOTES_ExplodeQuoteToOrders @IPVC_QuoteID = 3
-- 
-- 
-- Author          : SRS
-- 12/11/2006      : Stored Procedure Created.
-- Revision History:
-- 20/12/2010	   : Surya Kiran Defect # 8867 - Correct end date on tran measure code order items to 2099
-- 07/01/2011      : SRS - TFS 738 Enhancement for AutoFulfill at Group Level
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_ExplodeQuoteToOrders]  (@IPVC_QuoteID           varchar(50),
                                                          @IPVC_ApprovedByIDSeq   bigint, --> This is UserID of person Name from Drop down used for Approval.      
                                                          @IPDT_ApprovalDate      datetime,
                                                          @IPBI_UserIDSeq         bigint  --> This is UserID of person logged on (Mandatory)            
                                                          )
AS
BEGIN
  set nocount on;
  set ansi_warnings off;
  -------------------------------------------------------------------------------------------------
  select @IPDT_ApprovalDate = convert(varchar(20),@IPDT_ApprovalDate,101);
  -------------------------------------------------------------------------------------------------
  Create Table #TempQuantity(Quantity     int not null
                             PRIMARY KEY CLUSTERED 
                            (Quantity  ASC
                             )
  WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
  ) ON [PRIMARY]
  --Generate 9000 Rows in #TempQuantity
  Insert into #TempQuantity(Quantity)
  select top 100 percent  d4*1000 + d3*100 + d2*10 + d1 as Quantity
  from      
  (select 0 as 'd4' union all select 1 union all select 2 union all select 3 union all select 4 union all select 5
 	          union all select 6 union all select 7 union all select 8 union all select 9) dt4,
  (select 0 as 'd3' union all select 1 union all select 2 union all select 3 union all select 4 union all select 5
 	          union all select 6 union all select 7 union all select 8 union all select 9) dt3,
  (select 0 as 'd2' union all select 1 union all select 2 union all select 3 union all select 4 union all select 5
 	          union all select 6 union all select 7 union all select 8 union all select 9) dt2,
  (select 0 as 'd1' union all select 1 union all select 2 union all select 3 union all select 4 union all select 5
 	          union all select 6 union all select 7 union all select 8 union all select 9) dt1
  order by Quantity asc
  -------------------------------------------------------------------------------------------------
  --Declaring Local Variables
  declare @LVC_OrderStatusCode        varchar(50),
          @LVC_GroupType              varchar(50),
          @LI_GroupID                 int,
          @LVC_CompanyIDSeq           varchar(50),
          @LVC_CompanyID              varchar(50),
          @LI_ordersynchstartmonth    int,
          @LDT_EndDate                datetime,          
          @LVC_CompanyAccountID       varchar(50),
          @LVC_PropertyAccountID      varchar(50),
          @LVC_OrderID                varchar(50),
          @LI_OrderGroupID            bigint,
          @LVC_PropertyIDSeq          varchar(50),  
          @LVC_PriceTypeCode          varchar(50),
          @LI_ThresholdOverrideFlag   int, 
          @LDT_ActivationStartDate    datetime,
          @LVC_ErrorCodeSection       varchar(1000),
          @LVC_QuoteTypecode          varchar(4);

  declare @LI_Units                   int,
          @LI_Beds                    int,
          @LI_PPUPercentage           int,
          @LI_PrePaidFlag             int,
          @LI_ExternalQuoteIIFlag     int,       
          @LDT_SystemDate             datetime;

  declare @LVC_ApprovedByUserName     varchar(100);

  select Top 1 @LVC_ApprovedByUserName = U.FirstName + ' ' + U.LastName
  from   Security.dbo.[User] U with (nolock)
  where  U.IDSeq = @IPVC_ApprovedByIDSeq
  ------------------------------------------------
  select @LDT_SystemDate = getdate()

  select @LDT_ActivationStartDate = Q.OrderActivationStartDate,
         @LVC_QuoteTypecode       = ltrim(rtrim(Q.QuoteTypecode)),
         @LVC_CompanyIDSeq        = ltrim(rtrim(Q.CustomerIDSeq)),
         @LVC_CompanyID           = ltrim(rtrim(Q.CustomerIDSeq)),
         @LI_PrePaidFlag          = Q.PrePaidFlag,
         @LI_ExternalQuoteIIFlag  = Q.ExternalQuoteIIFlag
  from   Quotes.dbo.Quote Q with (nolock)
  where  Q.QuoteIDSeq = @IPVC_QuoteID
  -------------------------------------------------------------------------------------------------
  If exists (select Top 1 1
             from   Orders.dbo.[Order] O with (nolock)
             where  O.CompanyIDSeq = @LVC_CompanyIDSeq
             and    O.QuoteIDSeq   = @IPVC_QuoteID
            )
  begin
    select @LVC_ErrorCodeSection = 'Order(s) already exists for this Quote : ' + @IPVC_QuoteID +
                                   '. Approval of this Quote is denied by system. If Error is noted, please rollback this Quote and Approve again.' 
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    return;
  end
  -------------------------------------------------------------------------------------------------
  select @LI_ordersynchstartmonth = C.ordersynchstartmonth 
  from   CUSTOMERS.dbo.Company C with (nolock)
  where  C.IDSeq = @LVC_CompanyIDSeq

  set @LVC_OrderStatusCode = 'PEND'

  set @LI_ordersynchstartmonth = 0 --- For TRAN Enabler.
  select @LDT_EndDate = (case                                                                 
                            when (@LI_ordersynchstartmonth=0 and day(@IPDT_ApprovalDate) = 1)
                                then dateadd(year,1,@IPDT_ApprovalDate)-1
                            when (@LI_ordersynchstartmonth=0 and day(@IPDT_ApprovalDate) <> 1)
                                then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,dateadd(year,1,@IPDT_ApprovalDate))+1,0)) 
                            when @LI_ordersynchstartmonth > 0 and @LI_ordersynchstartmonth <= month(@IPDT_ApprovalDate)
                                then dateadd(day,-1,
                                             convert(varchar(20),@LI_ordersynchstartmonth)+
                                             '/01/'+
                                             convert(varchar(20),year(@IPDT_ApprovalDate)+1)
                                            )
                            else dateadd(day,-1,
                                         convert(varchar(20),@LI_ordersynchstartmonth)+
                                         '/01/'+
                                         convert(varchar(20),year(@IPDT_ApprovalDate))
                                        )
                         end
                         )
  -------------------------------------------------------------------------------------------------
  --Declaring Local Temporary Tables  
  -------------------------------------------------------------------------------------------------
  declare @LI_GMin  bigint
         ,@LI_GMax  bigint
         ,@LI_GPMin bigint
         ,@LI_GPMax bigint

  declare @LT_MainGroup table
                                (IDRowNumber           bigint not null,
                                 quotegrouptype        varchar(20),
                                 quotegroupid          bigint,
                                 CompanyIDSeq          varchar(50)
                                );

  declare @LT_MainGroupProperties table
                                  (IDRowNumber            bigint not null,
                                   PropertyIDSeq          varchar(50),
                                   PriceTypeCode          varchar(50),
                                   ThresholdOverrideFlag  int, 
                                   Units                  int,
                                   Beds                   int,
                                   PPUPercentage          int
                                  );
  -------------------------------------------------------------------------------------------------
  Insert into @LT_MainGroup(IDRowNumber,quotegrouptype,quotegroupid,CompanyIDSeq)
  select  
         row_number() OVER(ORDER BY G.IDSeq ASC) as IDRowNumber
         ,ltrim(rtrim(G.grouptype))              as quotegrouptype
         ,G.IDSeq                                as quotegroupid
         ,ltrim(rtrim(G.CustomerIDSeq))          as CompanyIDSeq
  from   Quotes.dbo.[Group] G (nolock)
  where  G.QuoteIDSeq =  @IPVC_QuoteID

  select @LI_GMin=1,@LI_GMax = coalesce(Max(LTMG.IDRowNumber),0)
  from   @LT_MainGroup LTMG
 
  while @LI_GMin <= @LI_GMax ----> : Main Group While Loop
  begin
    select @LVC_GroupType   = LTMG.quotegrouptype
          ,@LI_GroupID      = LTMG.quotegroupid
          ,@LVC_CompanyIDSeq= LTMG.CompanyIDSeq
    from  @LT_MainGroup LTMG
    where LTMG.IDRowNumber  = @LI_GMin;
    ------------------------------------------------------------------------------------------------
    exec Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@IPVC_QuoteID,@IPI_GroupID=@LI_GroupID
    ------------------------------------------------------------------------------------------------
    if exists (select top 1 1 
               from   CUSTOMERS.dbo.Account A with (nolock) 
               where  A.CompanyIDSeq   =  @LVC_CompanyIDSeq
               and    A.AccountTypeCode= 'AHOFF'
               and    A.PropertyIDSeq is null
               and    A.ActiveFlag = 1
              )
    begin
      select Top 1 @LVC_CompanyAccountID = ltrim(rtrim(A.IDSeq))
      from   CUSTOMERS.dbo.Account A with (nolock) 
      where  A.CompanyIDSeq   =  @LVC_CompanyIDSeq
      and    A.AccountTypeCode= 'AHOFF'
      and    A.PropertyIDSeq is null
      and    A.ActiveFlag = 1
    end    
    --------------------------------------------------------------------------------
    ---Group Type = 'PMC'
    if @LVC_GroupType = 'PMC'
    begin
      ------------------------------------------------------------------------------
      if exists (select top 1 1 
                 from   Orders.dbo.[Order] O with (nolock)
                 where  O.AccountIDSeq = @LVC_CompanyAccountID
                 and    O.CompanyIDSeq = @LVC_CompanyIDSeq
                 and    O.PropertyIDSeq is null
                 and    O.QuoteIDSeq   = @IPVC_QuoteID
                )
      begin
        select @LVC_OrderID = O.OrderIDSeq
        from   Orders.dbo.[Order] O with (nolock)
        where  O.AccountIDSeq = @LVC_CompanyAccountID
        and    O.CompanyIDSeq = @LVC_CompanyIDSeq
        and    O.PropertyIDSeq is null
        and    O.QuoteIDSeq   = @IPVC_QuoteID
      end
      else
      begin
        ---Insert Order Record
        begin TRY;
          BEGIN TRANSACTION;
            update ORDERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
            set    IDSeq = IDSeq+1,
                   GeneratedDate =CURRENT_TIMESTAMP
          
            select @LVC_OrderID = OrderIDSeq
            from   ORDERS.DBO.IDGenerator with (NOLOCK)  
          
            Insert into Orders.dbo.[Order](OrderIDSeq,AccountIDSeq,CompanyIDSeq,PropertyIDSeq,
                                           QuoteIDSeq,StatusCode,
                                           CreatedByIDSeq,CreatedDate,ApprovedByIDSeq,ApprovedDate,
                                           CreatedBy,ApprovedBy)
            select Top 1 @LVC_OrderID as OrderIDSeq,
                         @LVC_CompanyAccountID as AccountIDSeq,@LVC_CompanyIDSeq as CompanyIDSeq,NULL as PropertyIDSeq,
                         @IPVC_QuoteID    as QuoteIDSeq,'APPR' as StatusCode,
                         @IPBI_UserIDSeq  as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,
                         @IPVC_ApprovedByIDSeq as ApprovedByIDSeq,Coalesce(@IPDT_ApprovalDate,Q.AcceptanceDate,Q.ApprovalDate,@LDT_SystemDate) as ApprovedDate,
                         coalesce(Q.CreatedByDisplayName,Q.CreatedBy) as CreatedBy,
                         @LVC_ApprovedByUserName as ApprovedBy
           from   QUOTES.dbo.Quote Q (nolock) 
           where Q.QuoteIDSeq = @IPVC_QuoteID         
         COMMIT TRANSACTION;       
        end TRY
        begin CATCH;
          select @LVC_ErrorCodeSection = 'GroupType=PMC: New OrderID Generation failed for Quote : ' + @IPVC_QuoteID + ';Company : ' + @LVC_CompanyIDSeq +
                                          ';Account:' + coalesce(@LVC_CompanyAccountID,'No Active Acount Found') + ';...'
          
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
          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; 
          
          -----------------------------------------------------------
          ---On Error Rollback Quote, before Throwing Error back to UI    
          begin try 
            Exec QUOTES.dbo.[uspQUOTES_RollbackQuote] @IPVC_QuoteIDSeq =@IPVC_QuoteID,@IPI_UserIDSeq = @IPBI_UserIDSeq;
          end try
          begin catch
          end catch
          -----------------------------------------------------------
          Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
          return;
        end CATCH; 
      end   
      ------------------------------------------------------------------------------
      ---Insert OrderGroup Record
      BEGIN TRANSACTION;
      Insert into Orders.dbo.[OrderGroup](OrderIDSeq,DiscAllocationCode,
                                          Name,Description,                                          
                                          AllowProductCancelFlag,OrderGroupType,CustomBundleNameEnabledFlag,
                                          AutoFulfillILFFlag,AutoFulfillACSANCFlag,AutoFulfillStartDate, 
                                          CreatedByIDSeq,CreatedDate                                       
                                          )
      select Top 1 @LVC_OrderID,G.DiscAllocationCode,G.Name,G.Name as Description,
                   G.AllowProductCancelFlag,@LVC_GroupType as OrderGroupType,
                   G.CustomBundleNameEnabledFlag as CustomBundleNameEnabledFlag,
                   G.AutoFulfillILFFlag,G.AutoFulfillACSANCFlag,G.AutoFulfillStartDate, 
                   @IPBI_UserIDSeq  as CreatedByIDSeq,@LDT_SystemDate as CreatedDate
      from    QUOTES.dbo.[Group] G (nolock)
      where   G.QuoteIDSeq    = @IPVC_QuoteID
      and     G.IDseq         = @LI_GroupID
      and     G.CustomerIDSeq = @LVC_CompanyIDSeq
      and     G.GroupType     = @LVC_GroupType

      select @LI_OrderGroupID =  SCOPE_IDENTITY() 
      COMMIT TRANSACTION; 
      ------------------------------------------------------------------------------
      ---Insert OrderItem Records
      if exists (select top 1 1 from Orders.dbo.[OrderGroup] (nolock)
                 where OrderIDSeq = @LVC_OrderID and IDSeq = @LI_OrderGroupID
                )
      begin
        ----------------------------------------------------------------------
        ---Step 1 : Insert into Orderitem from Quoteitem only records that 
        ---         have Products.dbo.Charge's ExplodeQuantityatOrderFlag = 0
        ----------------------------------------------------------------------
        Insert into Orders.dbo.OrderItem(OrderIDSeq,OrderGroupIDSeq,
                                       ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,
                                       PublicationYear,PublicationQuarter,PriceVersion,Units,Beds,PPUPercentage,
                                       minunits,maxunits,CapMaxUnitsFlag,
                                       dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                       excludeforbookingsflag,crossfiremaximumallowablecallvolume,
                                       Quantity,
                                       AllowProductCancelFlag,
                                       ChargeAmount,ExtChargeAmount,
                                       DiscountPercent,DiscountAmount,totaldiscountpercent,totaldiscountamount,
                                       NetUnitChargeamount,NetChargeAmount,                                       
                                       ILFStartDate,ILFEndDate,
                                       StatusCode,RenewalTypeCode,
                                       ActivationStartDate,ActivationEndDate,
                                       StartDate,EndDate,
                                       BillToAddressTypeCode,
                                       BillToDeliveryOptionCode,
                                       ReportingTypeCode,
                                       FulfilledByIDSeq,FulfilledDate,
                                       PrePaidFlag,ExternalQuoteIIFlag,
                                       CreatedByIDSeq,Createddate,SystemLogdate)
        select @LVC_OrderID as OrderIDSeq,@LI_OrderGroupID as OrderGroupIDSeq,
               QI.ProductCode,QI.ChargeTypeCode,QI.FrequencyCode,QI.MeasureCode,QI.FamilyCode,
               QI.PublicationYear,QI.PublicationQuarter,QI.PriceVersion,NULL AS Units,NULL AS Beds,NULL AS PPUPercentage,
               QI.minunits,QI.maxunits,QI.CapMaxUnitsFlag,
               QI.dollarminimum,QI.dollarmaximum,QI.credtcardpricingpercentage,
               QI.excludeforbookingsflag,QI.crossfiremaximumallowablecallvolume,
               QI.Quantity,
               QI.AllowProductCancelFlag,
               QI.ChargeAmount,
               0                     as ExtChargeAmount,
               QI.DiscountPercent,QI.DiscountAmount,
               QI.totaldiscountpercent,QI.totaldiscountamount,
               QI.NetChargeAmount    as NetUnitChargeamount,
               QI.NetChargeAmount    as NetChargeAmount,
               (case when QI.Measurecode         = 'TRAN'   then @IPDT_ApprovalDate                     
                     else NULL 
                end) as ILFStartDate,       --> ILFStartDate
               (case when QI.Measurecode         = 'TRAN'   then '12/31/2099'
                     else NULL 
                end) as ILFEndDate,         --> ILFEndDate
               (case when QI.Measurecode    = 'TRAN' then 'FULF'                     
                     when QI.ChargeTypeCode = 'ILF'  then @LVC_OrderStatusCode
                     else 'PEND' 
                end) as StatusCode,
               (case when (QI.FrequencyCode = 'OT' or QI.FrequencyCode = 'SG') then 'DRNW' else 'ARNW' end) as RenewalTypeCode,
               (case when (QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN')   then @IPDT_ApprovalDate                     
                     else NULL 
                end) as ActivationStartDate,--> ActivationStartDate
               (case when QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN' then '12/31/2099'
                     else NULL 
                end) as ActivationEndDate, -->  ActivationEndDate
               (case when QI.Measurecode    = 'TRAN' then @IPDT_ApprovalDate
                     else NULL 
                end) as StartDate,         --> StartDate
               (case when QI.Measurecode    = 'TRAN' then '12/31/2099'
                     else NULL 
                end) as EndDate,          --> EndDate
                'CBT'   as BillToAddressTypeCode,    --->Add Default
                'SMAIL' as BillToDeliveryOptionCode, --->Add Default
                C.ReportingTypeCode as ReportingTypeCode,
                (Case when (QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN') then @IPBI_UserIDSeq else NULL end) as  FulfilledByIDSeq,
                (Case when (QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN') then @LDT_Systemdate else NULL end) as  FulfilledDate,
                --------------------------------------
                (Case when (QI.Measurecode = 'TRAN')     then 0
                      when (@LI_ExternalQuoteIIFlag = 1) then 1
                      when (PRD.PrePaidFlag = 1)         then 1                      
                      when (@LI_PrePaidFlag = 1)         then 1
                      else 0
                 end)                                                  as PrePaidFlag,
                (Case when (@LI_ExternalQuoteIIFlag = 1) then 1
                      else 0
                 end)                                                  as ExternalQuoteIIFlag,
                --------------------------------------
                @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_Systemdate as Createddate,@LDT_Systemdate    as SystemLogdate
        from  QUOTES.dbo.[QuoteItem] QI with (nolock)
        inner join
              Products.dbo.Product PRD with (nolock)
        on    QI.ProductCode   = PRD.Code
        and   QI.PriceVersion  = PRD.PriceVersion
        and   QI.QuoteIDSeq    = @IPVC_QuoteID
        and   QI.GroupIDseq    = @LI_GroupID
        inner join
              Products.dbo.Charge C     with (nolock)
        on    QI.QuoteIDSeq    = @IPVC_QuoteID
        and   QI.GroupIDseq    = @LI_GroupID
        and   PRD.Code         = C.ProductCode
        and   PRD.PriceVersion = C.PriceVersion  
        and   QI.ProductCode   = C.ProductCode
        and   QI.PriceVersion  = C.PriceVersion
        and   QI.ChargeTypeCode= C.ChargeTypeCode
        and   QI.MeasureCode   = C.MeasureCode
        and   QI.FrequencyCode = C.FrequencyCode
        and   ( 
               (C.QuantityEnabledFlag = 0)
                 OR
               (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 0)
                 OR
               (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 1 and QI.Quantity = 1)
              )
        -------------
        and  not ((@LVC_QuoteTypecode = 'RPRQ' OR @LVC_QuoteTypecode = 'STFQ')
                             AND
                  (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
                 )
        -------------
        where QI.QuoteIDSeq    = @IPVC_QuoteID
        and   QI.GroupIDseq    = @LI_GroupID
        and   QI.ProductCode   = C.ProductCode
        and   QI.PriceVersion  = C.PriceVersion
        and   QI.ChargeTypeCode= C.ChargeTypeCode
        and   QI.MeasureCode   = C.MeasureCode
        and   QI.FrequencyCode = C.FrequencyCode
        and   ( 
               (C.QuantityEnabledFlag = 0)
                 OR
               (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 0)
                 OR
               (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 1 and QI.Quantity = 1)
              )
        -------------
        and  not ((@LVC_QuoteTypecode = 'RPRQ' OR @LVC_QuoteTypecode = 'STFQ')
                             AND
                  (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
                 )
        -------------
        ----------------------------------------------------------------------
        ---Step 2 : Insert into Orderitem from Quoteitem only records that 
        ---         have Products.dbo.Charge's ExplodeQuantityatOrderFlag = 1
        --- i.e Insert Orderitems exploded by number of Quantites
        ----------------------------------------------------------------------
        Insert into Orders.dbo.OrderItem(OrderIDSeq,OrderGroupIDSeq,
                                       ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,
                                       PublicationYear,PublicationQuarter,PriceVersion,Units,Beds,PPUPercentage,
                                       minunits,maxunits,CapMaxUnitsFlag,
                                       dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                       excludeforbookingsflag,crossfiremaximumallowablecallvolume,
                                       Quantity,
                                       AllowProductCancelFlag,
                                       ChargeAmount,ExtChargeAmount,
                                       DiscountPercent,DiscountAmount,totaldiscountpercent,totaldiscountamount,
                                       NetUnitChargeamount,NetChargeAmount,                                       
                                       ILFStartDate,ILFEndDate,
                                       StatusCode,RenewalTypeCode,
                                       ActivationStartDate,ActivationEndDate,
                                       StartDate,EndDate,
                                       BillToAddressTypeCode,
                                       BillToDeliveryOptionCode, 
                                       ReportingTypeCode,
                                       FulfilledByIDSeq,FulfilledDate,
                                       PrePaidFlag,ExternalQuoteIIFlag,
                                       CreatedByIDSeq,Createddate,SystemLogdate)
        select @LVC_OrderID as OrderIDSeq,@LI_OrderGroupID as OrderGroupIDSeq,
               QI.ProductCode,QI.ChargeTypeCode,QI.FrequencyCode,QI.MeasureCode,QI.FamilyCode,
               QI.PublicationYear,QI.PublicationQuarter,QI.PriceVersion,NULL as Units,NULL as Beds,NULL as PPUPercentage,
               QI.minunits,QI.maxunits,QI.CapMaxUnitsFlag,
               QI.dollarminimum,QI.dollarmaximum,QI.credtcardpricingpercentage,
               QI.excludeforbookingsflag,QI.crossfiremaximumallowablecallvolume,
               1 as Quantity,
               QI.AllowProductCancelFlag,
               QI.ChargeAmount,
               0    as ExtChargeAmount,
               QI.DiscountPercent,QI.DiscountAmount,
               QI.totaldiscountpercent,QI.totaldiscountamount,
               QI.NetChargeAmount   as NetUnitChargeamount,
               QI.NetChargeAmount   as NetChargeAmount,
               (case when QI.Measurecode         = 'TRAN'   then @IPDT_ApprovalDate                     
                     else NULL 
                end) as ILFStartDate,       --> ILFStartDate
               (case when QI.Measurecode         = 'TRAN'   then '12/31/2099'
                     else NULL 
                end) as ILFEndDate,         --> ILFEndDate
               (case when QI.Measurecode    = 'TRAN' then 'FULF'                     
                     when QI.ChargeTypeCode = 'ILF'  then @LVC_OrderStatusCode
                     else 'PEND' 
                end) as StatusCode,
               (case when (QI.FrequencyCode = 'OT' or QI.FrequencyCode = 'SG') then 'DRNW' else 'ARNW' end) as RenewalTypeCode,
               (case when QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN'   then @IPDT_ApprovalDate                     
                     else NULL 
                end) as ActivationStartDate,--> ActivationStartDate
               (case when QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN' then '12/31/2099'
                     else NULL 
                end) as ActivationEndDate, -->  ActivationEndDate
               (case when QI.Measurecode    = 'TRAN' then @IPDT_ApprovalDate
                     else NULL 
                end) as StartDate,         --> StartDate
               (case when QI.Measurecode    = 'TRAN' then '12/31/2099'
                     else NULL 
                end) as EndDate,          --> EndDate
                'CBT'   as BillToAddressTypeCode,    --->Add Default
                'SMAIL' as BillToDeliveryOptionCode, --->Add Default
                C.ReportingTypeCode as ReportingTypeCode,
                (Case when (QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN') then @IPBI_UserIDSeq else NULL end) as  FulfilledByIDSeq,
                (Case when (QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN') then @LDT_Systemdate else NULL end) as  FulfilledDate,
                --------------------------------------
                (Case when (QI.Measurecode = 'TRAN')     then 0
                      when (@LI_ExternalQuoteIIFlag = 1) then 1
                      when (PRD.PrePaidFlag = 1)         then 1                      
                      when (@LI_PrePaidFlag = 1)         then 1
                      else 0
                 end)                                                  as PrePaidFlag,
                (Case when (@LI_ExternalQuoteIIFlag = 1) then 1
                      else 0
                 end)                                                  as ExternalQuoteIIFlag,
                --------------------------------------
                @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_Systemdate as Createddate,@LDT_Systemdate as SystemLogdate
        from  QUOTES.dbo.[QuoteItem] QI with (nolock)
        inner join
              Products.dbo.Product PRD with (nolock)
        on    QI.ProductCode   = PRD.Code
        and   QI.PriceVersion  = PRD.PriceVersion
        and   QI.QuoteIDSeq    = @IPVC_QuoteID
        and   QI.GroupIDseq    = @LI_GroupID
        inner join
              Products.dbo.Charge C     with (nolock)
        on    QI.QuoteIDSeq    = @IPVC_QuoteID
        and   QI.GroupIDseq    = @LI_GroupID
        and   PRD.Code         = C.ProductCode
        and   PRD.PriceVersion = C.PriceVersion
        and   QI.ProductCode   = C.ProductCode
        and   QI.PriceVersion  = C.PriceVersion
        and   QI.ChargeTypeCode= C.ChargeTypeCode
        and   QI.MeasureCode   = C.MeasureCode
        and   QI.FrequencyCode = C.FrequencyCode
        and   (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 1 and QI.Quantity > 1)
         -------------
        and  not ((@LVC_QuoteTypecode = 'RPRQ' OR @LVC_QuoteTypecode = 'STFQ')
                             AND
                  (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
                 )
        -------------
        inner join    #TempQuantity TQ with (nolock)
        on    TQ.quantity      >  1
        and   TQ.quantity      <= QI.Quantity
        where QI.QuoteIDSeq    = @IPVC_QuoteID
        and   QI.GroupIDseq    = @LI_GroupID
        and   QI.ProductCode   = C.ProductCode
        and   QI.PriceVersion  = C.PriceVersion
        and   QI.ChargeTypeCode= C.ChargeTypeCode
        and   QI.MeasureCode   = C.MeasureCode
        and   QI.FrequencyCode = C.FrequencyCode
        and   (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 1 and QI.Quantity > 1)
        -------------
        and  not ((@LVC_QuoteTypecode = 'RPRQ' OR @LVC_QuoteTypecode = 'STFQ')
                             AND
                  (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
                 )
        -------------
        and   TQ.quantity      >  1
        and   TQ.quantity      <= QI.Quantity
      end
      ------------------------------------------------------------------------------
      ---Run Pricing Engine to Update Values correctly
      ------------------------------------------------------------------------------
      exec ORDERS.dbo.uspORDERS_SyncOrderGroupAndOrderItem @IPVC_OrderID=@LVC_OrderID,@IPI_GroupID=@LI_OrderGroupID;
      ------------------------------------------------------------------------------
    end -- :End for GroupType = 'PMC'
    --------------------------------------------------------------------------------
    else ---Group Type <> 'PMC'
    begin
      ---------------------------------------
      --Delete @LT_MainGroupProperties before inserting for this GroupID
      Delete from @LT_MainGroupProperties;
      Insert into @LT_MainGroupProperties(IDRowNumber,PropertyIDSeq,PriceTypeCode,ThresholdOverrideFlag,
                                          Units,Beds,PPUPercentage
                                         )
      select 
              row_number() OVER(ORDER BY GP.GroupIDSeq                  ASC
                                        ,ltrim(rtrim(GP.PropertyIDSeq)) ASC
                               )         as IDRowNumber
             ,ltrim(rtrim(GP.PropertyIDSeq))             as PropertyIDSeq
             ,Max(ltrim(rtrim(GP.PriceTypeCode)))        as PriceTypeCode
             ,Max(convert(int,GP.ThresholdOverrideFlag)) as ThresholdOverrideFlag
             ,Max(P.Units)                               as Units
             ,Max(P.Beds)                                as Beds
             ,Max(P.PPUPercentage)                       as PPUPercentage
      from  QUOTES.dbo.[GroupProperties] GP With (nolock)
      inner join
            CUSTOMERS.dbo.Property       P  With (nolock) 
      on    GP.PropertyIDSeq = P.IDSeq
      and   GP.CustomerIDSeq = P.PMCIDSeq
      and   GP.QuoteIDSeq    = @IPVC_QuoteID
      and   GP.GroupIDSeq    = @LI_GroupID
      and   GP.CustomerIDSeq = @LVC_CompanyIDSeq
      where GP.QuoteIDSeq    = @IPVC_QuoteID
      and   GP.GroupIDSeq    = @LI_GroupID
      and   GP.CustomerIDSeq = @LVC_CompanyIDSeq
      group by GP.GroupIDSeq,ltrim(rtrim(GP.PropertyIDSeq));  

      select @LI_GPMin=1,@LI_GPMax = coalesce(Max(LTMGP.IDRowNumber),0)
      from   @LT_MainGroupProperties LTMGP;
     
      while @LI_GPMin <= @LI_GPMax ----> : Sub Main Group Properties While Loop
      begin 
        select @LVC_PropertyIDSeq        = LTMGP.PropertyIDSeq
              ,@LVC_PriceTypeCode        = LTMGP.PriceTypeCode
              ,@LI_ThresholdOverrideFlag = LTMGP.ThresholdOverrideFlag
              ,@LI_Units                 = LTMGP.Units
              ,@LI_Beds                  = LTMGP.Beds
              ,@LI_PPUPercentage         = LTMGP.PPUPercentage
        from  @LT_MainGroupProperties LTMGP
        where LTMGP.IDRowNumber = @LI_GPMin; 
        ------------------------------------------------------
        if exists (select top 1 1 
                   from  CUSTOMERS.dbo.Account A (nolock) 
                   where A.CompanyIDSeq   = @LVC_CompanyIDSeq
                   and   A.PropertyIDSeq  = @LVC_PropertyIDSeq
                   and   A.AccountTypeCode= 'APROP' 
                   and   A.PropertyIDSeq is not null
                   and   A.ActiveFlag = 1
                )
        begin
          select Top 1 @LVC_PropertyAccountID = ltrim(rtrim(A.IDSeq)) 
          from  CUSTOMERS.dbo.Account A (nolock) 
          where A.CompanyIDSeq   = @LVC_CompanyIDSeq
          and   A.PropertyIDSeq  = @LVC_PropertyIDSeq
          and   A.AccountTypeCode= 'APROP' 
          and   A.PropertyIDSeq is not null
          and   A.ActiveFlag = 1;
        end        
        ------------------------------------------------------------------------------
        if exists (select top 1 1 
                   from   Orders.dbo.[Order] O with (nolock)
                   where  O.AccountIDSeq = @LVC_PropertyAccountID
                   and    O.CompanyIDSeq = @LVC_CompanyIDSeq
                   and    O.PropertyIDSeq= @LVC_PropertyIDSeq
                   and    O.PropertyIDSeq is not null
                   and    O.QuoteIDSeq   = @IPVC_QuoteID
                  )
        begin
          select @LVC_OrderID = O.OrderIDSeq
          from   Orders.dbo.[Order] O with (nolock)
          where  O.AccountIDSeq = @LVC_PropertyAccountID
          and    O.CompanyIDSeq = @LVC_CompanyIDSeq
          and    O.PropertyIDSeq= @LVC_PropertyIDSeq
          and    O.PropertyIDSeq is not null
          and    O.QuoteIDSeq   = @IPVC_QuoteID
        end
        else
        begin
          ---Insert Order Record
          begin TRY;
            BEGIN TRANSACTION;
              update ORDERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
              set    IDSeq = IDSeq+1,
                     GeneratedDate =CURRENT_TIMESTAMP
            
              select @LVC_OrderID= OrderIDSeq
              from   ORDERS.DBO.IDGenerator with (NOLOCK) 
  
              Insert into Orders.dbo.[Order](OrderIDSeq,AccountIDSeq,CompanyIDSeq,PropertyIDSeq,
                                           QuoteIDSeq,StatusCode,
                                           CreatedByIDSeq,CreatedDate,ApprovedByIDSeq,ApprovedDate,
                                           CreatedBy,ApprovedBy)
              select Top 1 @LVC_OrderID as OrderIDSeq,
                           @LVC_PropertyAccountID as AccountIDSeq,@LVC_CompanyIDSeq as CompanyIDSeq,@LVC_PropertyIDSeq as PropertyIDSeq,
                           @IPVC_QuoteID    as QuoteIDSeq,'APPR' as StatusCode,
                           @IPBI_UserIDSeq  as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,
                           @IPVC_ApprovedByIDSeq as ApprovedByIDSeq,Coalesce(@IPDT_ApprovalDate,Q.AcceptanceDate,Q.ApprovalDate,@LDT_SystemDate) as ApprovedDate,
                           coalesce(Q.CreatedByDisplayName,Q.CreatedBy) as CreatedBy,
                           @LVC_ApprovedByUserName as ApprovedBy
              from   QUOTES.dbo.Quote Q (nolock) 
              where Q.QuoteIDSeq = @IPVC_QuoteID
            COMMIT TRANSACTION;       
          end TRY
          begin CATCH;
            select @LVC_ErrorCodeSection = 'GroupType=SITE: New OrderID Generation failed for Quote : ' + @IPVC_QuoteID + ';Company : ' + @LVC_CompanyIDSeq +
                                           ';Property: ' + @LVC_PropertyIDSeq + ';Prop Account:' + coalesce(@LVC_PropertyAccountID,'No Active Acount Found') + ';...'                   
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
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;        
            -----------------------------------------------------------
            ---On Error Rollback Quote, before Throwing Error back to UI    
            begin try 
              Exec QUOTES.dbo.[uspQUOTES_RollbackQuote] @IPVC_QuoteIDSeq =@IPVC_QuoteID,@IPI_UserIDSeq = @IPBI_UserIDSeq;
            end try
            begin catch
            end catch
            -----------------------------------------------------------
            Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
            return;                  
          end CATCH;          
        end
        ------------------------------------------------------------------------------
        ---Insert OrderGroup Record
        BEGIN TRANSACTION;
        Insert into Orders.dbo.[OrderGroup](OrderIDSeq,DiscAllocationCode,
                                            Name,Description,                                            
                                            AllowProductCancelFlag,OrderGroupType,CustomBundleNameEnabledFlag,
                                            AutoFulfillILFFlag,AutoFulfillACSANCFlag,AutoFulfillStartDate, 
                                            CreatedByIDSeq,CreatedDate
                                            )
        select Top 1 @LVC_OrderID,G.DiscAllocationCode,G.Name,G.Name as Description,
                     G.AllowProductCancelFlag,@LVC_GroupType as OrderGroupType,
                     G.CustomBundleNameEnabledFlag as CustomBundleNameEnabledFlag,
                     G.AutoFulfillILFFlag,G.AutoFulfillACSANCFlag,G.AutoFulfillStartDate, 
                     @IPBI_UserIDSeq  as CreatedByIDSeq,@LDT_SystemDate as CreatedDate
        from    QUOTES.dbo.[Group] G (nolock)
        where   G.QuoteIDSeq    = @IPVC_QuoteID
        and     G.IDseq         = @LI_GroupID
        and     G.CustomerIDSeq = @LVC_CompanyIDSeq
        and     G.GroupType     = @LVC_GroupType

        select @LI_OrderGroupID =  SCOPE_IDENTITY() 
        COMMIT TRANSACTION; 
          ------------------------------------------------------------------------------
        if exists (select top 1 1 from Orders.dbo.[OrderGroup] (nolock)
                   where OrderIDSeq = @LVC_OrderID and IDSeq = @LI_OrderGroupID
                  )
        begin
          --Insert OrderGroupProperties
          Insert into Orders.dbo.OrderGroupProperties(AccountIDSeq,OrderIDSeq,OrderGroupIDSeq,
                                                      CompanyIDSeq,PropertyIDSeq,PriceTypeCode,ThresholdOverrideFlag,
                                                      CreatedByIDSeq,CreatedDate)
          select @LVC_PropertyAccountID as AccountIDSeq,@LVC_OrderID as OrderIDSeq,@LI_OrderGroupID as OrderGroupIDSeq,
                 @LVC_CompanyIDSeq as CompanyIDSeq,@LVC_PropertyIDSeq as PropertyIDSeq,
                 @LVC_PriceTypeCode as PriceTypeCode,@LI_ThresholdOverrideFlag as ThresholdOverrideFlag,
                 @IPBI_UserIDSeq  as CreatedByIDSeq,@LDT_SystemDate as CreatedDate
          ------------------------------------------------------------------------------          
          ---Step 1 : Insert into Orderitem from Quoteitem only records that 
          ---         have Products.dbo.Charge's ExplodeQuantityatOrderFlag = 0
          ----------------------------------------------------------------------
          Insert into Orders.dbo.OrderItem(OrderIDSeq,OrderGroupIDSeq,
                                         ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,
                                         PublicationYear,PublicationQuarter,PriceVersion,Units,Beds,PPUPercentage,
                                         minunits,maxunits,CapMaxUnitsFlag,
                                         dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                         excludeforbookingsflag,crossfiremaximumallowablecallvolume,
                                         Quantity,
                                         AllowProductCancelFlag,
                                         ChargeAmount,ExtChargeAmount,
                                         DiscountPercent,DiscountAmount,totaldiscountpercent,totaldiscountamount,
                                         NetUnitChargeamount,NetChargeAmount,                                       
                                         ILFStartDate,ILFEndDate,                                         
                                         StatusCode,RenewalTypeCode,
                                         ActivationStartDate,ActivationEndDate,
                                         StartDate,EndDate,
                                         BillToAddressTypeCode,
                                         BillToDeliveryOptionCode, 
                                         ReportingTypeCode,
                                         FulfilledByIDSeq,FulfilledDate,
                                         PrePaidFlag,ExternalQuoteIIFlag, 
                                         CreatedByIDSeq,Createddate,SystemLogdate)
          select @LVC_OrderID as OrderIDSeq,@LI_OrderGroupID as OrderGroupIDSeq,
                 QI.ProductCode,QI.ChargeTypeCode,QI.FrequencyCode,QI.MeasureCode,QI.FamilyCode,
                 QI.PublicationYear,QI.PublicationQuarter,QI.PriceVersion,
                 @LI_Units as units,@LI_Beds as Beds,@LI_PPUPercentage as PPUPercentage,
                 QI.minunits,QI.maxunits,QI.CapMaxUnitsFlag,
                 QI.dollarminimum,QI.dollarmaximum,QI.credtcardpricingpercentage,
                 QI.excludeforbookingsflag,QI.crossfiremaximumallowablecallvolume,
                 QI.Quantity,
                 QI.AllowProductCancelFlag,
                 QI.ChargeAmount,
                 0    as ExtChargeAmount,
                 QI.DiscountPercent,QI.DiscountAmount,
                 QI.totaldiscountpercent,QI.totaldiscountamount,
                 QI.NetChargeamount     as NetUnitChargeamount,
                 QI.NetChargeAmount     as NetChargeAmount,
                 (case when QI.Measurecode         = 'TRAN'   then @IPDT_ApprovalDate                     
                       else NULL 
                  end) as ILFStartDate,       --> ILFStartDate
                 (case when QI.Measurecode         = 'TRAN'   then '12/31/2099'
                       else NULL 
                  end) as ILFEndDate,         --> ILFEndDate
                 (case when QI.Measurecode    = 'TRAN' then 'FULF'                     
                       when QI.ChargeTypeCode = 'ILF'  then @LVC_OrderStatusCode
                       else 'PEND' 
                  end) as StatusCode,
                 (case when (QI.FrequencyCode = 'OT' or QI.FrequencyCode = 'SG') then 'DRNW' else 'ARNW' end) as RenewalTypeCode,
                 (case when QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN'   then @IPDT_ApprovalDate                       
                       else NULL 
                  end) as ActivationStartDate,--> ActivationStartDate
                 (case when QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN' then '12/31/2099'
                       else NULL 
                  end) as ActivationEndDate, -->  ActivationEndDate
                 (case when QI.Measurecode    = 'TRAN' then @IPDT_ApprovalDate
                       else NULL 
                  end) as StartDate,         --> StartDate
                 (case when QI.Measurecode    = 'TRAN' then '12/31/2099'
                       else NULL 
                  end) as EndDate,          --> EndDate 
                 'PBT'   as BillToAddressTypeCode,      -----> Add Default
                 'SMAIL' as BillToDeliveryOptionCode,   -----> Add Default
                 C.ReportingTypeCode as ReportingTypeCode,
                (Case when (QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN') then @IPBI_UserIDSeq else NULL end) as  FulfilledByIDSeq,
                (Case when (QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN') then @LDT_Systemdate else NULL end) as  FulfilledDate,
                --------------------------------------
                (Case when (QI.Measurecode = 'TRAN')     then 0
                      when (@LI_ExternalQuoteIIFlag = 1) then 1
                      when (PRD.PrePaidFlag = 1)         then 1                      
                      when (@LI_PrePaidFlag = 1)         then 1
                      else 0
                 end)                                                  as PrePaidFlag,
                (Case when (@LI_ExternalQuoteIIFlag = 1) then 1
                      else 0
                 end)                                                  as ExternalQuoteIIFlag,
                --------------------------------------
                 @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_Systemdate as Createddate,@LDT_Systemdate as SystemLogdate
            from  QUOTES.dbo.[QuoteItem] QI (nolock)
            inner join
                  Products.dbo.Product PRD with (nolock)
            on    QI.ProductCode   = PRD.Code
            and   QI.PriceVersion  = PRD.PriceVersion
            and   QI.QuoteIDSeq    = @IPVC_QuoteID
            and   QI.GroupIDseq    = @LI_GroupID
            inner join
                  Products.dbo.Charge C     with (nolock)
            on    QI.QuoteIDSeq    = @IPVC_QuoteID
            and   QI.GroupIDseq    = @LI_GroupID
            and   PRD.Code         = C.ProductCode
            and   PRD.PriceVersion = C.PriceVersion
            and   QI.ProductCode   = C.ProductCode
            and   QI.PriceVersion  = C.PriceVersion
            and   QI.ChargeTypeCode= C.ChargeTypeCode
            and   QI.MeasureCode   = C.MeasureCode
            and   QI.FrequencyCode = C.FrequencyCode
            and   ( 
                    (C.QuantityEnabledFlag = 0)
                       OR
                    (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 0)
                       OR
                    (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 1 and QI.Quantity = 1)
                  )
            -------------
            and  not ((@LVC_QuoteTypecode = 'RPRQ' OR @LVC_QuoteTypecode = 'STFQ')
                              AND
                      (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
                     )
            ------------- 
            where QI.QuoteIDSeq    = @IPVC_QuoteID
            and   QI.GroupIDseq    = @LI_GroupID
            and   QI.ProductCode   = C.ProductCode
            and   QI.PriceVersion  = C.PriceVersion
            and   QI.ChargeTypeCode= C.ChargeTypeCode
            and   QI.MeasureCode   = C.MeasureCode
            and   QI.FrequencyCode = C.FrequencyCode
            and   ( 
                    (C.QuantityEnabledFlag = 0)
                       OR
                    (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 0)
                       OR
                    (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 1 and QI.Quantity = 1)
                  )
            -------------
            and  not ((@LVC_QuoteTypecode = 'RPRQ' OR @LVC_QuoteTypecode = 'STFQ')
                              AND
                      (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
                     )
            -------------
            ----------------------------------------------------------------------
            ---Step 2 : Insert into Orderitem from Quoteitem only records that 
            ---         have Products.dbo.Charge's ExplodeQuantityatOrderFlag = 1
            --- i.e Insert Orderitems exploded by number of Quantites
            ----------------------------------------------------------------------
            Insert into Orders.dbo.OrderItem(OrderIDSeq,OrderGroupIDSeq,
                                         ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,
                                         PublicationYear,PublicationQuarter,PriceVersion,Units,Beds,PPUPercentage,
                                         minunits,maxunits,CapMaxUnitsFlag,
                                         dollarminimum,dollarmaximum,credtcardpricingpercentage,
                                         excludeforbookingsflag,crossfiremaximumallowablecallvolume,
                                         Quantity,
                                         AllowProductCancelFlag,
                                         ChargeAmount,ExtChargeAmount,
                                         DiscountPercent,DiscountAmount,totaldiscountpercent,totaldiscountamount,
                                         NetUnitChargeamount,NetChargeAmount,                                       
                                         ILFStartDate,ILFEndDate,
                                         StatusCode,RenewalTypeCode,
                                         ActivationStartDate,ActivationEndDate,
                                         StartDate,EndDate,
                                         BillToAddressTypeCode,
                                         BillToDeliveryOptionCode,
                                         ReportingTypeCode,
                                         FulfilledByIDSeq,FulfilledDate,
                                         PrePaidFlag,ExternalQuoteIIFlag,
                                         CreatedByIDSeq,Createddate,SystemLogdate)
            select @LVC_OrderID as OrderIDSeq,@LI_OrderGroupID as OrderGroupIDSeq,
                 QI.ProductCode,QI.ChargeTypeCode,QI.FrequencyCode,QI.MeasureCode,QI.FamilyCode,
                 QI.PublicationYear,QI.PublicationQuarter,QI.PriceVersion,
                 @LI_Units as units,@LI_Beds as Beds,@LI_PPUPercentage as PPUPercentage, 
                 QI.minunits,QI.maxunits,QI.CapMaxUnitsFlag,
                 QI.dollarminimum,QI.dollarmaximum,QI.credtcardpricingpercentage,
                 QI.excludeforbookingsflag,QI.crossfiremaximumallowablecallvolume,
                 1 as Quantity,
                 QI.AllowProductCancelFlag,
                 QI.ChargeAmount,
                 0    as ExtChargeAmount,
                 QI.DiscountPercent,QI.DiscountAmount,
                 QI.totaldiscountpercent,QI.totaldiscountamount,
                 QI.NetChargeamount     as NetUnitChargeamount,
                 QI.NetChargeAmount     as NetChargeAmount,
                 (case when QI.Measurecode         = 'TRAN'   then @IPDT_ApprovalDate                     
                       else NULL 
                  end) as ILFStartDate,       --> ILFStartDate
                 (case when QI.Measurecode         = 'TRAN'   then '12/31/2099'
                       else NULL 
                  end) as ILFEndDate,         --> ILFEndDate
                 (case when QI.Measurecode    = 'TRAN' then 'FULF'                     
                       when QI.ChargeTypeCode = 'ILF'  then @LVC_OrderStatusCode
                       else 'PEND' 
                  end) as StatusCode,
                 (case when (QI.FrequencyCode = 'OT' or QI.FrequencyCode = 'SG') then 'DRNW' else 'ARNW' end) as RenewalTypeCode,
                 (case when QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN'   then @IPDT_ApprovalDate                       
                       else NULL 
                  end) as ActivationStartDate,--> ActivationStartDate
                 (case when QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN' then '12/31/2099'
                       else NULL 
                  end) as ActivationEndDate, -->  ActivationEndDate
                 (case when QI.Measurecode    = 'TRAN' then @IPDT_ApprovalDate
                       else NULL 
                  end) as StartDate,         --> StartDate
                 (case when QI.Measurecode    = 'TRAN' then '12/31/2099'
                       else NULL 
                  end) as EndDate,          --> EndDate
                 'PBT' as BillToAddressTypeCode,      ----> Add Default
                 'SMAIL' as BillToDeliveryOptionCode, ---> Add Default
                 C.ReportingTypeCode as ReportingTypeCode,
                (Case when (QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN') then @IPBI_UserIDSeq else NULL end) as  FulfilledByIDSeq,
                (Case when (QI.ChargeTypeCode = 'ACS' AND QI.Measurecode = 'TRAN') then @LDT_Systemdate else NULL end) as  FulfilledDate,
                --------------------------------------
                (Case when (QI.Measurecode = 'TRAN')     then 0
                      when (@LI_ExternalQuoteIIFlag = 1) then 1
                      when (PRD.PrePaidFlag = 1)         then 1                      
                      when (@LI_PrePaidFlag = 1)         then 1
                      else 0
                 end)                                                  as PrePaidFlag,
                (Case when (@LI_ExternalQuoteIIFlag = 1) then 1
                      else 0
                 end)                                                  as ExternalQuoteIIFlag,
                --------------------------------------
                 @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_Systemdate as Createddate,@LDT_Systemdate as SystemLogdate
            from  QUOTES.dbo.[QuoteItem] QI (nolock)
            inner join
                  Products.dbo.Product PRD with (nolock)
            on    QI.ProductCode   = PRD.Code
            and   QI.PriceVersion  = PRD.PriceVersion
            and   QI.QuoteIDSeq    = @IPVC_QuoteID
            and   QI.GroupIDseq    = @LI_GroupID
            inner join
                  Products.dbo.Charge C     with (nolock)
            on    QI.QuoteIDSeq    = @IPVC_QuoteID
            and   QI.GroupIDseq    = @LI_GroupID
            and   PRD.Code         = C.ProductCode
            and   PRD.PriceVersion = C.PriceVersion
            and   QI.ProductCode   = C.ProductCode
            and   QI.PriceVersion  = C.PriceVersion
            and   QI.ChargeTypeCode= C.ChargeTypeCode
            and   QI.MeasureCode   = C.MeasureCode
            and   QI.FrequencyCode = C.FrequencyCode
            and   (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 1 and QI.Quantity > 1)
            -------------
            and  not ((@LVC_QuoteTypecode = 'RPRQ' OR @LVC_QuoteTypecode = 'STFQ')
                              AND
                      (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
                     )
            -------------
            inner join    #TempQuantity TQ with (nolock)
            on    TQ.quantity      >  1
            and   TQ.quantity      <= QI.Quantity
            where QI.QuoteIDSeq    = @IPVC_QuoteID
            and   QI.GroupIDseq    = @LI_GroupID
            and   QI.ProductCode   = C.ProductCode
            and   QI.PriceVersion  = C.PriceVersion
            and   QI.ChargeTypeCode= C.ChargeTypeCode
            and   QI.MeasureCode   = C.MeasureCode
            and   QI.FrequencyCode = C.FrequencyCode
            and   (C.QuantityEnabledFlag = 1 and C.ExplodeQuantityatOrderFlag = 1 and QI.Quantity > 1)
            -------------
            and  not ((@LVC_QuoteTypecode = 'RPRQ' OR @LVC_QuoteTypecode = 'STFQ')
                              AND
                      (QI.chargetypecode = 'ILF' and QI.discountpercent=100)
                     )
            -------------
            and   TQ.quantity      >  1
            and   TQ.quantity      <= QI.Quantity
        end
        ------------------------------------------------------------------------------
        ---Run Pricing Engine to Update Values correctly
        ------------------------------------------------------------------------------    
        exec ORDERS.dbo.uspORDERS_SyncOrderGroupAndOrderItem @IPVC_OrderID=@LVC_OrderID,@IPI_GroupID=@LI_OrderGroupID;
        ------------------------------------------------------------------------------
        select @LI_GPMin = @LI_GPMin + 1
      end      
    end ---> End for Sub Main Group Properties While Loop  
    -------------------------------------------------------------------------------- 
    select @LI_GMin = @LI_GMin + 1
  end ---> End for Main Group While Loop  
  -----------------------------------------------------------------
  ---Apply Special MBA Rules
  EXEC ORDERS.dbo.uspORDERS_ApplyMBADOExceptionRules  @IPVC_CompanyIDSeq=@LVC_CompanyID,@IPBI_UserIDSeq=@IPBI_UserIDSeq;  
  -----------------------------------------------------------------
  --Final Cleanup
  --IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
  if (object_id('tempdb.dbo.#TempQuantity') is not null) 
  begin
    drop table #TempQuantity;
  end;  
  -----------------------------------------------------------------
END -- :Main End
GO
