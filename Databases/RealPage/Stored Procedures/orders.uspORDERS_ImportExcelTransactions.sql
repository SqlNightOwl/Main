SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_ImportExcelTransactions]
-- Description     : This Proc Imports Valid Non Error Transactions passed from UI
--                   UI should call this proc only for ImportableTransactionFlag=1 and ValidationErrorFlag=0       

-- Input Parameters: As below
--                     
------------------------------------------------------------------------------------------------------
-- Revision History:
-- Author          : SRS #6120
-- 09/24/2009      : SRS #6120
-- 05/27/2010      : SRS #7491
------------------------------------------------------------------------------------------------------
Create Procedure [orders].[uspORDERS_ImportExcelTransactions]  (@OPVC_OrderIDSeq                   varchar(50)   output,     
                                                             @OPBI_OrderGroupIDSeq              bigint        output,
                                                             @OPBI_OrderItemIDSeq               bigint        output,
                                                             @OPBI_OrderItemTransactionID       bigint        output,
                                                             @OPI_DetailPostingStatusFlag       int           output,
                                                             @OPVC_DetailPostingErrorMessage    varchar(4000) output,
                                                             -------------------------------
                                                             @IPI_UserIDSeq                     bigint,          -->User ID of User Importing.UI knows this.
                                                             @IPI_TransactionImportIDSeq        bigint,          -->TransactionImportBatchID from UI after creating a batch record in TransactionImport table.
                                                             @IPI_TransactionImportDetailIDSeq  bigint,          -->TransactionImportBatchDetailID from BatchDetail Table after creating a records in TransactionImportItem table.
                                                             @IPDT_TransactionImportDate        datetime,        -->Exact DateTime of Import Batch Header CreatedDate,carried over from TransactionImportBatchHeader                                                            
                                                             @IPVC_CompanyIDSeq                 varchar(50),     -->CompanyIDSeq  from UI.
                                                             @IPVC_PropertyIDSeq                varchar(50)='',  -->PropertyIDSeq from UI.
                                                             @IPVC_AccountIDSeq                 varchar(50),     -->AccountIDSeq  from UI.
                                                             @IPVC_OrderIDSeq                   varchar(50)='',  -->OrderIDSeq    from UI when available.
                                                             @IPVC_OrderGroupIDSeq              varchar(50)='',  -->OrderGroupIDSeq from UI when available.
                                                             @IPVC_OrderItemIDSeq               varchar(50)='',  -->OrderItemIDSeq  from UI when available.
                                                             @IPVC_ProductCode                  varchar(50),     -->ProductCode from UI.
                                                             @IPN_PriceVersion                  numeric(30,0),   -->PriceVersion from UI.
                                                             @IPVC_SourceTransactionID          varchar(50),     -->SourceTransactionID from UI.
                                                             @IPVC_TransactionServiceDate       varchar(50),     -->TransactionServiceDate of the transaction from UI
                                                             @IPVC_TransactionItemName          varchar(max),    -->Transaction Description from UI.
                                                             @IPN_ListPrice                     numeric(30,5),   -->ListPrice of Transaction from UI.
                                                             @IPN_Quantity                      numeric(30,0),   -->Quantity of Transaction from UI.
                                                             @IPN_NetPrice                      numeric(30,5),   -->NetPrice of Transaction from UI.
                                                             @IPI_AmountOverrideFlag            int,             -->AmountOverrideFlag of the transaction from UI.
                                                             @IPN_SOCChargeAmount               numeric(30,5),   -->SOCChargeAmount of Transaction from UI.
                                                             @IPI_ImportableTransactionFlag     int,             -->ImportableTransactionFlag of the transaction from UI.
                                                             @IPI_TranEnablerRecordFoundFlag    int,             -->TranEnablerRecordFoundFlag of the transaction from UI.
                                                             @IPI_PreValidationErrorFlag        int,             -->ValidationErrorFlag of the transaction from UI.
                                                             @IPVC_ImportSource                 varchar(100)     -->Indicates ImportSource 'EXCEL', 'Appirio SalesForce' etc                                                                                                                          
                                                            )                                                            

AS
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL ON;
  --------------------------------------------------------------
  declare @LVC_UserName                             varchar(70);  
  declare @LDT_TransactionServiceDate               datetime;
  declare @LDT_OrderApprovalDate                    datetime;
  declare @LDT_MaxEndDate                           datetime;
  declare @LDT_MinStartDate                         datetime;
  declare @LDT_NewStartDate                         datetime;  
  declare @LDT_NewEndDate                           datetime;  
  declare @LVC_TransactionItemName                  varchar(300);
  declare @LBI_NewlyGeneratedOrderItemTransactionID bigint;
  declare @LVC_PRVBatch                             varchar(50);
  declare @LI_ordersynchstartmonth                  int;
  --------------------------------------------------------------
  select  @IPVC_OrderIDSeq      = nullif(@IPVC_OrderIDSeq,''),
          @IPVC_OrderGroupIDSeq = nullif(@IPVC_OrderGroupIDSeq,''),
          @IPVC_OrderItemIDSeq  = nullif(@IPVC_OrderItemIDSeq,''),
          @IPVC_PropertyIDSeq   = nullif(@IPVC_PropertyIDSeq,'')          
  select  @LVC_TransactionItemName = substring(ltrim(rtrim(@IPVC_TransactionItemName)),1,300),
          @LVC_PRVBatch         = ''
  --------------------------------------------------------------
  if (@IPVC_TransactionServiceDate = '01/01/1900' Or isdate(@IPVC_TransactionServiceDate)=0)
  begin
    ---This Transaction is not valid for Import as @IPVC_TransactionServiceDate is not valid
    select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
           @OPBI_OrderItemIDSeq=@IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=-9999,
           @OPI_DetailPostingStatusFlag   =0,
           @OPVC_DetailPostingErrorMessage='Transaction Date ' + @IPVC_TransactionServiceDate + ' is invalid date. Batch Posting to OrderItemTransaction Failed.'
    return    
  end
  --------------------------------------------------------------
  if (@IPI_PreValidationErrorFlag = 1 or @IPI_ImportableTransactionFlag = 0)
  begin
    ---This Transaction is not valid for Import. Simply Return
    select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
           @OPBI_OrderItemIDSeq=@IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=-9999,
           @OPI_DetailPostingStatusFlag   =0,
           @OPVC_DetailPostingErrorMessage='This transaction has ValidationErrorFlag=1,ImportableTransactionFlag=0.Not a valid transaction for import. Batch Posting to OrderItemTransaction Failed.'
    return    
  end
  --------------------------------------------------------------
  select top 1 @LVC_UserName = NTUser
  from   Security.dbo.[User] with (nolock)
  where  IDSeq = @IPI_UserIDSeq

  if @LVC_UserName is null
  begin    
    select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
           @OPBI_OrderItemIDSeq=@IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=-9999,
           @OPI_DetailPostingStatusFlag   =0,
           @OPVC_DetailPostingErrorMessage='Invalid user ID (' + convert(varchar(70), @IPI_UserIDSeq) + '). Batch Posting to OrderItemTransaction Failed.'
    return
  end
  -------------------------------------------------------------  
  if (@IPI_ImportableTransactionFlag =1  and
      @IPI_TranEnablerRecordFoundFlag=1  and 
      @IPVC_OrderIDSeq is not null
     )
  begin
    ---This means all attributes  of TRAN Enabler Order to directly import the trasaction into OrderitemTransaction
    ---are prevalidated and readily available.
    GOTO FinalTransactionInsert
    return;
  end
  else if (@IPI_ImportableTransactionFlag =1  and
           @IPI_TranEnablerRecordFoundFlag=0  and 
           @IPVC_OrderIDSeq is null
          )
  begin
    select Top 1
           @LI_ordersynchstartmonth = ordersynchstartmonth 
    from   CUSTOMERS.dbo.Company with (nolock)
    where  IDSeq = @IPVC_CompanyIDSeq

    select @LI_ordersynchstartmonth = 0

    select @LDT_TransactionServiceDate = @IPVC_TransactionServiceDate
    ---This means all attributes of TRAN Enabler Order for Importable transactions are not readily available
    -- Hence Try and Find an Non Custom bundle Order for the Account to which a TRAN Enabler record order can be created
    -- else create a new one.
    if (@IPVC_OrderIDSeq is null)
    begin 
      ---Step 1 : Check to see all attributes can be got for all matching criteria
      select top 1 @IPVC_OrderIDSeq=OI.OrderIDSeq,@IPVC_OrderGroupIDSeq=OI.OrderGroupIDSeq,@IPVC_OrderItemIDSeq=OI.IDSeq,
                   @LDT_OrderApprovalDate = O.ApprovedDate
      from   Orders.dbo.[Order]       O  with (nolock)
      inner join
             Orders.dbo.[Orderitem]   OI with (nolock)
      on     O.OrderIDSeq      = OI.OrderIDSeq
      and    O.AccountIDSeq    = @IPVC_AccountIDSeq
      and    OI.ProductCode    = @IPVC_ProductCode
      and    OI.Chargetypecode = 'ACS'
      and    OI.Measurecode    = 'TRAN'
      and    OI.FrequencyCode  = 'OT'
      and    @LDT_TransactionServiceDate >= OI.Startdate
      and    @LDT_TransactionServiceDate <= coalesce(OI.Canceldate,OI.Enddate)
      --and    @LDT_TransactionServiceDate >= O.ApprovedDate
      inner join
             (Select Max(OI.IDSeq) as OrderitemIDSeq
              from   Orders.dbo.[Order]       O  with (nolock)
              inner join
                     Orders.dbo.[Orderitem]   OI with (nolock)
              on     O.OrderIDSeq      = OI.OrderIDSeq
              and    O.AccountIDSeq    = @IPVC_AccountIDSeq
              and    OI.ProductCode    = @IPVC_ProductCode
              and    OI.Chargetypecode = 'ACS'
              and    OI.Measurecode    = 'TRAN'
              and    OI.FrequencyCode  = 'OT'
              and    @LDT_TransactionServiceDate >= OI.Startdate
              and    @LDT_TransactionServiceDate <= coalesce(OI.Canceldate,OI.Enddate)
              --and    @LDT_TransactionServiceDate >= O.ApprovedDate
             ) Source
      on OI.IDSeq = Source.OrderitemIDSeq
      
      -------------------------------------
      if (@IPVC_OrderItemIDSeq is not null) --> Step 1 Success
      begin     
        GOTO FinalTransactionInsert
        return;
      end
    end
    -----------------------------------------------------------------
    --> Step 1 Failure
    --- Step 2: Check to see if existing order and ordergroup for the productcode can be got to create a TRAN orderitem 
    else if (@IPVC_OrderItemIDSeq is null) 
    begin      
      select top 1 @IPVC_OrderIDSeq=OI.OrderIDSeq,@IPVC_OrderGroupIDSeq=OI.OrderGroupIDSeq,
                   @LDT_OrderApprovalDate = O.ApprovedDate
      from   Orders.dbo.[Order]       O  with (nolock)
      inner join              
             Orders.dbo.[Orderitem]   OI with (nolock)
      on     O.OrderIDSeq      = OI.OrderIDSeq
      and    O.AccountIDSeq    = @IPVC_AccountIDSeq
      and    OI.ProductCode    = @IPVC_ProductCode
      and    @LDT_TransactionServiceDate >= OI.Startdate
      and    @LDT_TransactionServiceDate <= coalesce(OI.Canceldate,OI.Enddate)
      --and    @LDT_TransactionServiceDate >= O.ApprovedDate
      inner join
             (Select Max(OI.IDSeq) as OrderitemIDSeq
              from   Orders.dbo.[Order]       O  with (nolock)
              inner join
                     Orders.dbo.[Orderitem]   OI with (nolock)
              on     O.OrderIDSeq      = OI.OrderIDSeq
              and    O.AccountIDSeq    = @IPVC_AccountIDSeq
              and    OI.ProductCode    = @IPVC_ProductCode              
              and    @LDT_TransactionServiceDate >= OI.Startdate
              and    @LDT_TransactionServiceDate <= coalesce(OI.Canceldate,OI.Enddate)
              --and    @LDT_TransactionServiceDate >= O.ApprovedDate
             ) Source
      on OI.IDSeq = Source.OrderitemIDSeq
      --------------
      if (@IPVC_OrderIDSeq is not null) --> Step 2.1 Success
      begin
        GOTO GenerateNewTranEnablerOrderItem
        if (@IPVC_OrderItemIDSeq is not null) --> Step 2.2 Success
        begin     
          GOTO FinalTransactionInsert
          return;
        end
      end
    end 
    -----------------------------------------------------------------
    --> Step 2 Failure
    --- Step 3: check to see if existing order and ordergroup for a Non Custom Bundle for the account can be got to create a TRAN orderitem
    else if (@IPVC_OrderItemIDSeq is null) 
    begin
      select top 1 @IPVC_OrderIDSeq=O.OrderIDSeq,@IPVC_OrderGroupIDSeq=OG.IDSeq,
                   @LDT_OrderApprovalDate = O.ApprovedDate
      from   Orders.dbo.[Order]       O  with (nolock)
      inner join              
             ORDERS.dbo.[Ordergroup]  OG with (nolock)
      on     O.OrderIDSeq      = OG.OrderIDSeq
      and    O.AccountIDSeq    = @IPVC_AccountIDSeq
      and    OG.CustomBundleNameEnabledFlag = 0 
      --and    @LDT_TransactionServiceDate >= O.ApprovedDate
      inner join
             (Select Max(OG.IDSeq) as OrderGroupIDSeq
              from   Orders.dbo.[Order]       O  with (nolock)
              inner join              
                     ORDERS.dbo.[Ordergroup]  OG with (nolock)
              on     O.OrderIDSeq      = OG.OrderIDSeq
              and    O.AccountIDSeq    = @IPVC_AccountIDSeq
              and    OG.CustomBundleNameEnabledFlag = 0 
              --and    @LDT_TransactionServiceDate    >= O.ApprovedDate
             ) Source
      on OG.IDSeq = Source.OrderGroupIDSeq
  
      if (@IPVC_OrderIDSeq is not null) --> Step 3.1 Success
      begin
        GOTO GenerateNewTranEnablerOrderItem
        if (@IPVC_OrderItemIDSeq is not null) --> Step 3.2 Success
        begin     
          GOTO FinalTransactionInsert
          return;
        end
      end 
    end
    -----------------------------------------------------------------
    --> Step 3 Failure
    --- Step 4: Create a brand new Order,Ordergroup and Tran Enabler Orderitem
    else if (@IPVC_OrderItemIDSeq is null) 
    begin
      GOTO GenerateNewOrder
      GOTO GenerateNewOrderGroup
      GOTO GenerateNewTranEnablerOrderItem
      if (@IPVC_OrderItemIDSeq is not null) --> Step 3.2 Success
      begin     
        GOTO FinalTransactionInsert
        return;
      end 
    end     
  end

  ---------------------------------------------------------------------------------------------------- 
  ---Create New Order if not exists
  ----------------------------------------------------------------------------------------------------
  GenerateNewOrder:
  begin TRY
    BEGIN TRANSACTION O;
      update ORDERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
      set    IDSeq = IDSeq+1,
             GeneratedDate = CURRENT_TIMESTAMP
      
      select @IPVC_OrderIDSeq = OrderIDSeq
      from   ORDERS.DBO.IDGenerator with (NOLOCK)
      Insert into Orders.dbo.[Order](OrderIDSeq,AccountIDSeq,CompanyIDSeq,PropertyIDSeq,QuoteIDSeq,StatusCode,
                                     CreatedBy,ModifiedBy,ApprovedBy,CreatedDate,ModifiedDate,ApprovedDate
                                    )
      select @IPVC_OrderIDSeq    as OrderIDSeq,@IPVC_AccountIDSeq as AccountIDSeq,@IPVC_CompanyIDSeq as CompanyIDSeq,
             @IPVC_PropertyIDSeq as PropertyIDSeq,NULL as QuoteIDSeq,'APPR' as StatusCode,
             @LVC_UserName       as CreatedBy,@LVC_UserName as ModifiedBy,@LVC_UserName as ApprovedBy,
             @IPDT_TransactionImportDate as CreatedDate,@IPDT_TransactionImportDate as ModifiedDate,(case when @LDT_TransactionServiceDate < '01/01/2008' then @LDT_TransactionServiceDate
                                                                      else '01/01/2008'
                                                                 end) as ApprovedDate
      where  not exists (select top 1 1
                         from   Orders.dbo.[Order] O with (nolock)
                         where  O.AccountIDSeq = @IPVC_AccountIDSeq
                         and    O.OrderIDSeq   = @IPVC_OrderIDSeq
                        ) 

      select @LDT_OrderApprovalDate = (case when @LDT_TransactionServiceDate < '01/01/2008' then @LDT_TransactionServiceDate
                                            else '01/01/2008'
                                       end)
    COMMIT TRANSACTION O;
  end TRY
  begin CATCH    
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION O;
    end
    else 
    if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION O;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION O;
    select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
           @OPBI_OrderItemIDSeq=@IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=-9999,
           @OPI_DetailPostingStatusFlag   =0,
           @OPVC_DetailPostingErrorMessage='New Order Generation failed and hence TRAN Enabler OrderItem Not found. Batch Posting to OrderItemTransaction Failed.'
    return;                 
  end CATCH
  ----------------------------------------------------------------------------------------------------
  ---Create New Order if not exists
  ----------------------------------------------------------------------------------------------------
  GenerateNewOrderGroup:
  begin TRY
    BEGIN TRANSACTION OG;      
      Insert into Orders.dbo.[OrderGroup](OrderIDSeq,DiscAllocationCode,Name,Description,AllowProductCancelFlag,
                                          OrderGroupType,CustomBundleNameEnabledFlag 
                                         )
      select @IPVC_OrderIDSeq    as OrderIDSeq,'IND' as DiscAllocationCode,
             'Custom Bundle-Transaction Import' as Name,'Custom Bundle-Transaction Import' as Description,
             1 as AllowProductCancelFlag,
             (case when @IPVC_PropertyIDSeq is not null then 'SITE' else 'PMC' end) as OrderGroupType,
             0 as CustomBundleNameEnabledFlag
      where  not exists (select top 1 1
                         from   Orders.dbo.[OrderGroup] OG with (nolock)
                         where  OG.OrderIDSeq   = @IPVC_OrderIDSeq
                         and    OG.CustomBundleNameEnabledFlag = 0
                         and    OG.[Name] = 'Custom Bundle-Transaction Import'
                        )
      select @IPVC_OrderGroupIDSeq=SCOPE_IDENTITY(); 
    COMMIT TRANSACTION OG;
  end TRY
  begin CATCH
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OG;
    end
    else 
    if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION OG;
    end
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OG;
    select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
           @OPBI_OrderItemIDSeq=@IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=-9999,
           @OPI_DetailPostingStatusFlag   =0,
           @OPVC_DetailPostingErrorMessage='New Order Group Generation failed and hence TRAN Enabler OrderItem Not found. Batch Posting to OrderItemTransaction Failed.'
    return; 
  end CATCH
  ---------------------------------------------------------------------------------------------------- 
  ---Create New Tran Enabler OrderItem if not exists
  ----------------------------------------------------------------------------------------------------
  GenerateNewTranEnablerOrderItem:
  begin TRY
    BEGIN TRANSACTION OI;     
      select @LDT_MaxEndDate   = coalesce(Max(OI.Canceldate),NULL),
             @LDT_MinStartDate = coalesce(Min(OI.Startdate),NULL) 
      from   Orders.dbo.[Order]       O  with (nolock)
      inner join
             Orders.dbo.[Orderitem]   OI with (nolock)
      on     O.OrderIDSeq       = OI.OrderIDSeq
      and    O.AccountIDSeq     = @IPVC_AccountIDSeq
      and    OI.ProductCode     = @IPVC_ProductCode
      and    OI.Chargetypecode  = 'ACS'
      and    OI.Measurecode     = 'TRAN'
      and    OI.FrequencyCode   = 'OT'
      and    OI.OrderIDSeq      <> @IPVC_OrderIDSeq
      and    OI.OrderGroupIDSeq <> @IPVC_OrderGroupIDSeq 

      select @LDT_MaxEndDate = (case when isdate(@LDT_MaxEndDate) = 1 then @LDT_MaxEndDate
                                     else NULL
                                end
                               ),
             @LDT_MinStartDate = (case when isdate(@LDT_MinStartDate) = 1 then @LDT_MinStartDate
                                     else NULL
                                  end
                                  )

      select @LDT_NewStartDate = (case when (@LDT_TransactionServiceDate  <= coalesce(@LDT_MaxEndDate,@LDT_OrderApprovalDate) and 
                                             @LDT_OrderApprovalDate       <= @LDT_TransactionServiceDate
                                            )
                                       then @LDT_OrderApprovalDate
                                          else coalesce(@LDT_MaxEndDate+1,@LDT_OrderApprovalDate)
                                  end),
            @LDT_NewEndDate  = (case when (@LDT_TransactionServiceDate  <= @LDT_MaxEndDate and isdate(@LDT_MaxEndDate) = 1)
                                       then @LDT_MaxEndDate-1
                                      when (@LDT_TransactionServiceDate  <=  @LDT_MinStartDate and isdate(@LDT_MinStartDate) = 1)
                                       then @LDT_MinStartDate-1
                                      else NULL
                                 end)
      select @LDT_NewEndDate  = (case when isdate(@LDT_NewEndDate)=1 
                                        then @LDT_NewEndDate                                                                
                                      when (@LI_ordersynchstartmonth=0 and day(coalesce(@LDT_NewEndDate,@LDT_TransactionServiceDate)) = 1)
                                         then dateadd(year,1,coalesce(@LDT_NewEndDate,@LDT_TransactionServiceDate))-1
                                      when (@LI_ordersynchstartmonth=0 and day(coalesce(@LDT_NewEndDate,@LDT_TransactionServiceDate)) <> 1)
                                         then DATEADD(d,-1,DATEADD(mm, DATEDIFF(m,0,dateadd(year,1,coalesce(@LDT_NewEndDate,@LDT_TransactionServiceDate)))+1,0)) 
                                      when @LI_ordersynchstartmonth > 0 and @LI_ordersynchstartmonth <= month(coalesce(@LDT_NewEndDate,@LDT_TransactionServiceDate))
                                         then dateadd(day,-1,
                                                      convert(varchar(20),@LI_ordersynchstartmonth)+
                                                      '/01/'+
                                                      convert(varchar(20),year(coalesce(@LDT_NewEndDate,@LDT_TransactionServiceDate))+1)
                                                      )
                                      else dateadd(day,-1,
                                                   convert(varchar(20),@LI_ordersynchstartmonth)+
                                                   '/01/'+
                                                   convert(varchar(20),year(coalesce(@LDT_NewEndDate,@LDT_TransactionServiceDate)))
                                                  )
                                 end
                                 )

      Insert into Orders.dbo.Orderitem(OrderIDSeq,OrderGroupIDSeq,ProductCode,PriceVersion,ChargeTypeCode,FrequencyCode,MeasureCode,FamilyCode,
                                       Units,Beds,PPUPercentage,minunits,maxunits,dollarminimum,dollarmaximum,
                                       Quantity,AllowProductCancelFlag,ChargeAmount,ExtChargeAmount,DiscountPercent,
                                       NetChargeAmount,StatusCode,ActivationStartDate,ActivationEndDate,StartDate,EndDate,
                                       ReportingTypeCode,RenewalTypeCode,BillToAddressTypeCode,
                                       billtodeliveryoptioncode,
                                       CreatedDate,ModifiedDate,ModifiedByUserIDSeq
                                      )
      select TOP 1 
                 @IPVC_OrderIDSeq as OrderIDSeq,@IPVC_OrderGroupIDSeq as OrderGroupIDSeq,@IPVC_ProductCode as ProductCode,@IPN_PriceVersion as PriceVersion,
                 'ACS' as ChargeTypeCode,'OT' as FrequencyCode,'TRAN' as MeasureCode,P.FamilyCode,
                 NULL as Units,NULL as Beds,NULL as PPUPercentage,
                 C.minunits,C.maxunits,C.dollarminimum,C.dollarmaximum,
                 1 as Quantity,1 as AllowProductCancelFlag,C.ChargeAmount as ChargeAmount,C.ChargeAmount as ExtChargeAmount,
                 0 as DiscountPercent,C.ChargeAmount as NetChargeAmount,
                 'FULF' as StatusCode,
                 @LDT_NewStartDate as ActivationStartDate,
                 @LDT_NewEndDate  as ActivationEndDate,
                  --------------------------------------------                
                  @LDT_NewStartDate as StartDate,
                  @LDT_NewEndDate   as EndDate,              
                 C.ReportingTypeCode,'DRNW' as RenewalTypeCode,(case when @IPVC_PropertyIDSeq is not null then 'PBT' else 'CBT' end) as  BillToAddressTypeCode,
                 'SMAIL' as billtodeliveryoptioncode,
                 @IPDT_TransactionImportDate as CreatedDate,@IPDT_TransactionImportDate as ModifiedDate,@IPI_UserIDSeq as ModifiedByUserIDSeq
      from  Products.dbo.Product P with (nolock)
      inner join 
            Products.dbo.Charge   C with (nolock)
      on    C.ProductCode = P.Code
      and   C.PriceVersion= P.PriceVersion
      and   P.Code         = @IPVC_ProductCode 
      and   C.ProductCode  = @IPVC_ProductCode
      and   P.PriceVersion = @IPN_PriceVersion 
      and   C.PriceVersion = @IPN_PriceVersion
      and   P.DisabledFlag = 0         
      and   C.DisabledFlag = 0
      and   C.ChargeTypeCode = 'ACS'   
      and   C.Measurecode    = 'TRAN'  
      and   C.FrequencyCode  = 'OT'
      and   Not exists (select top 1 1 
                        from   ORDERS.dbo.OrderItem OI with (nolock)
                        where  OI.Orderidseq      = @IPVC_OrderIDSeq
                        and    OI.OrderGroupIDSeq = @IPVC_OrderGroupIDSeq
                        and    OI.ProductCode     = @IPVC_ProductCode
                        and    OI.ChargeTypeCode = 'ACS'   
                        and    OI.Measurecode    = 'TRAN'  
                        and    OI.FrequencyCode  = 'OT'                        
                        and    coalesce(OI.Canceldate,OI.Enddate) >= @LDT_NewEndDate
                       )
      select @IPVC_OrderItemIDSeq=SCOPE_IDENTITY();      
    COMMIT TRANSACTION OI;
    EXEC ORDERS.dbo.uspORDERS_ApplyMBADOExceptionRules  @IPVC_CompanyIDSeq=@IPVC_CompanyIDSeq
                                                       ,@IPBI_UserIDSeq   =@IPI_UserIDSeq;
  end TRY
  begin CATCH    
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OI;
    end
    else 
    if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION OI;
    end
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OI;
    select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
           @OPBI_OrderItemIDSeq=@IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=-9999,
           @OPI_DetailPostingStatusFlag   =0,
           @OPVC_DetailPostingErrorMessage='TRAN Enabler OrderItem Generation failed. Batch Posting to OrderItemTransaction Failed.'
    return; 
  end CATCH
  ---------------
  begin try
    exec ORDERS.dbo.uspORDERS_SyncOrderGroupAndOrderItem  @IPVC_OrderID=@IPVC_OrderIDSeq
                                                         ,@IPI_GroupID =@IPVC_OrderGroupIDSeq; 
  end try
  begin catch    
  end catch
  ---------------------------------------------------------------------------------------------------- 
  ---Final Transaction Insert
  ----------------------------------------------------------------------------------------------------
  FinalTransactionInsert:
  begin
    if exists (select top 1 1
               from   Orders.dbo.[Order] O with (nolock)
               inner Join
                      Orders.dbo.[OrderItem] OI with (nolock)
               on     O.OrderIDSeq   = OI.OrderIDSeq
               and    O.AccountIDSeq = @IPVC_AccountIDSeq
               and    OI.ProductCode = @IPVC_ProductCode
               and    OI.MeasureCode = 'TRAN'
               inner join
                      Orders.dbo.OrderItemTransaction OIT with (nolock)
               on     O.OrderIDSeq   = OIT.OrderIDSeq
               and    OI.OrderIDSeq  = OIT.OrderIDSeq
               and    OI.IDSeq       = OIT.OrderItemIDSeq
               and    OIT.ProductCode= @IPVC_ProductCode
               and    substring(ltrim(rtrim(TransactionItemName)),1,300) =@LVC_TransactionItemName
               and    ServiceDate           =@IPVC_TransactionServiceDate
               and    SourceTransactionID   =@IPVC_SourceTransactionID
               and    OIT.NetChargeAmount   =@IPN_NetPrice
               and    TransactionImportIDSeq <> @IPI_TransactionImportIDSeq
              )
    begin
      select @LVC_PRVBatch = Max(OIT.TransactionImportIDSeq)
      from   Orders.dbo.[Order] O with (nolock)
      inner Join
             Orders.dbo.[OrderItem] OI with (nolock)
      on     O.OrderIDSeq   = OI.OrderIDSeq
      and    O.AccountIDSeq = @IPVC_AccountIDSeq
      and    OI.ProductCode = @IPVC_ProductCode
      and    OI.MeasureCode = 'TRAN'
      inner join
             Orders.dbo.OrderItemTransaction OIT with (nolock)
      on     O.OrderIDSeq   = OIT.OrderIDSeq
      and    OI.OrderIDSeq  = OIT.OrderIDSeq
      and    OI.IDSeq       = OIT.OrderItemIDSeq
      and    OIT.ProductCode= @IPVC_ProductCode
      and    substring(ltrim(rtrim(TransactionItemName)),1,300) =@LVC_TransactionItemName
      and    ServiceDate           =@IPVC_TransactionServiceDate
      and    SourceTransactionID   =@IPVC_SourceTransactionID
      and    OIT.NetChargeAmount   =@IPN_NetPrice
      and    TransactionImportIDSeq <> @IPI_TransactionImportIDSeq

      select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
             @OPBI_OrderItemIDSeq=@IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=-9999,
             @OPI_DetailPostingStatusFlag   =0,
             @OPVC_DetailPostingErrorMessage='This transaction with same attributes has been previously imported as part of an different Batch:' + convert(varchar(50),@LVC_PRVBatch) + '. Batch Posting to OrderItemTransaction Failed.'
      return
    end
    else if exists (select top 1 1 
                    from   ORDERS.dbo.Orderitemtransaction with (nolock)
                    where  OrderIDSeq            =@IPVC_OrderIDSeq
                    and    OrderGroupIDSeq       =@IPVC_OrderGroupIDSeq
                    and    OrderItemIDSeq        =@IPVC_OrderItemIDSeq
                    and    ProductCode           =@IPVC_ProductCode
                    and    substring(ltrim(rtrim(TransactionItemName)),1,300) =@LVC_TransactionItemName
                    and    ServiceDate           =@IPVC_TransactionServiceDate
                    and    SourceTransactionID   =@IPVC_SourceTransactionID
                    and    TransactionImportIDSeq=@IPI_TransactionImportIDSeq
                    and    NetChargeAmount       =@IPN_NetPrice
                   )
    begin
      select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
             @OPBI_OrderItemIDSeq=@IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=-9999,
             @OPI_DetailPostingStatusFlag   =0,
             @OPVC_DetailPostingErrorMessage='This Transaction is duplicated in Current Batch. Batch Posting to OrderItemTransaction Failed.'
      return
    end
    else
    begin
      BEGIN TRY
        BEGIN TRANSACTION OITImport;
          Insert into ORDERS.dbo.Orderitemtransaction(OrderIDSeq,OrderGroupIDSeq,OrderItemIDSeq,ProductCode,PriceVersion,ServiceCode,
                                                      ChargeTypeCode,MeasureCode,FrequencyCode,TransactionItemName,
                                                      ExtChargeAmount,DiscountAmount,NetChargeAmount,Quantity,TransactionalFlag,ServiceDate,
                                                      SourceTransactionID,TransactionImportIDSeq,ImportDate,ImportSource,
                                                      CreatedByIDSeq,CreatedDate,SystemLogDate
                                                      )
          select   @IPVC_OrderIDSeq  as OrderIDSeq,@IPVC_OrderGroupIDSeq as OrderGroupIDSeq,@IPVC_OrderItemIDSeq as OrderItemIDSeq,
                   @IPVC_ProductCode as ProductCode,@IPN_PriceVersion as PriceVersion,@IPVC_ProductCode as ServiceCode,
                   'ACS' as ChargeTypeCode,'TRAN' as MeasureCode,'OT' as FrequencyCode,
                   @LVC_TransactionItemName as TransactionItemName,@IPN_ListPrice as ExtChargeAmount,0.00 as DiscountAmount,@IPN_NetPrice as NetChargeAmount,
                   @IPN_Quantity     as Quantity,1 as TransactionalFlag,@IPVC_TransactionServiceDate as ServiceDate,@IPVC_SourceTransactionID as SourceTransactionID,
                   @IPI_TransactionImportIDSeq as TransactionImportIDSeq,@IPDT_TransactionImportDate as ImportDate,@IPVC_ImportSource as ImportSource,
                   @IPI_UserIDSeq as CreatedByIDSeq,@IPDT_TransactionImportDate as CreatedDate,@IPDT_TransactionImportDate as SystemLogDate
      
          select @LBI_NewlyGeneratedOrderItemTransactionID = SCOPE_IDENTITY()
   
          select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
                 @OPBI_OrderItemIDSeq= @IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=@LBI_NewlyGeneratedOrderItemTransactionID,
                 @OPI_DetailPostingStatusFlag   =1,
                 @OPVC_DetailPostingErrorMessage=NULL 
        COMMIT TRANSACTION OITImport;
      END TRY
      BEGIN CATCH;    
        -- XACT_STATE:
        -- If 1, the transaction is committable.
        -- If -1, the transaction is uncommittable and should be rolled back.
        -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
        if (XACT_STATE()) = -1
        begin
          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OITImport;
        end
        else if (XACT_STATE()) = 1
        begin
          IF @@TRANCOUNT > 0 COMMIT TRANSACTION OITImport;
        end 
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OITImport;
        select @OPVC_OrderIDSeq    = @IPVC_OrderIDSeq,@OPBI_OrderGroupIDSeq=@IPVC_OrderGroupIDSeq,
             @OPBI_OrderItemIDSeq=@IPVC_OrderItemIDSeq,@OPBI_OrderItemTransactionID=-9999,
             @OPI_DetailPostingStatusFlag   =0,
             @OPVC_DetailPostingErrorMessage='Batch Posting to OrderItemTransaction Failed.'
        return;                  
      END CATCH;
    end 
  end
  ----------------------------------------------------------------------------------------------------
END
GO
