SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_ImportTransactionBatchDoPost]
-- Description     : This Proc Posts Records from TransactionImportBatchDetail into Final Orders.dbo.OrderItemTransactionDetail for TransactionImportIDSeq
--                 : This is STEP 3
-- Input Parameters: @IPI_TransactionImportIDSeq
------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- Revision History:
-- Author          : SRS (Defect 7491)
-- 05/14/2010
------------------------------------------------------------------------------------------------------------------------------------
Create Procedure [orders].[uspORDERS_ImportTransactionBatchDoPost]  (@IPI_TransactionImportIDSeq bigint
                                                                  )
AS
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL ON;
  ------------------------------------------------------------------------
  --local variables declaration
  ------------------------------------------------------------------------
  declare  @LVC_CodeSection   varchar(4000);
  declare  @LVC_ImportSource  varchar(100);
  declare  @LI_Min            bigint,
           @LI_Max            bigint;
  declare  @LI_UserIDSeq                          bigint,
           @LI_TransactionImportIDSeq             bigint,
           @LI_TransactionImportBatchDetailIDSeq  bigint,
           @LDT_TransactionImportDate        datetime,
           @LVC_CompanyIDSeq                 varchar(50),
           @LVC_PropertyIDSeq                varchar(50),
           @LVC_AccountIDSeq                 varchar(50),
           @LVC_OrderIDSeq                   varchar(50),
           @LVC_OrderGroupIDSeq              varchar(50),
           @LVC_OrderItemIDSeq               varchar(50),
           @LVC_ProductCode                  varchar(50),
           @LN_PriceVersion                  numeric(30,0),
           @LVC_SourceTransactionID          varchar(50),
           @LVC_TransactionServiceDate       varchar(50),
           @LVC_TransactionItemName          varchar(max),
           @LN_ListPrice                     numeric(30,5),
           @LN_Quantity                      numeric(30,0),
           @LN_NetPrice                      numeric(30,5),
           @LI_AmountOverrideFlag            int,
           @LN_SOCChargeAmount               numeric(30,5),
           @LI_ImportableTransactionFlag     int,
           @LI_TranEnablerRecordFoundFlag    int,
           @LI_PreValidationErrorFlag        int

  declare  @LOPVC_OrderIDSeq                   varchar(50),     
           @LOPBI_OrderGroupIDSeq              bigint,
           @LOPBI_OrderItemIDSeq               bigint,
           @LOPBI_OrderItemTransactionID       bigint,
           @LOPI_DetailPostingStatusFlag       int,
           @LOPVC_DetailPostingErrorMessage    varchar(4000)

  declare  @LI_ErrorCount                    bigint,
           @LI_EstimatedImportCount          bigint,
           @LI_ToBeImportedCount             bigint,
           @LI_ActualImportCount             bigint,
           @LM_TotalNetChargeAmount          money
  ------------------------------------------------------------------------
  --Reinitializing local variables
  select @LI_ErrorCount=0,@LI_EstimatedImportCount=0,@LI_ActualImportCount=0,
         @LI_ToBeImportedCount = 0

  select @LOPVC_OrderIDSeq=NULL,@LOPBI_OrderGroupIDSeq=NULL,@LOPBI_OrderItemIDSeq=NULL,
         @LOPBI_OrderItemTransactionID= NULL,@LOPI_DetailPostingStatusFlag=0,
         @LOPVC_DetailPostingErrorMessage = NULL
  ------------------------------------------------------------------------
  if (object_id('tempdb.dbo.#LT_PrePostBatchDetail') is not null) 
  begin
    drop table #LT_PrePostBatchDetail;
  end;  
  ------------------------------------------------------------------------
  --Temporary Table Creation #LT_PrePostBatchDetail
  create table #LT_PrePostBatchDetail(SortSeq                  BigInt Not Null identity(1,1),
                                      TransactionImportIDSeq   Bigint Not Null,
                                      TransactionImportBatchDetailIDSeq  Bigint Not Null,
                                      UserIDSeq                Bigint        Not Null,
                                      TransactionImportDate    datetime      Not Null,
                                      CompanyIDSeq             varchar(50)   Not Null,
                                      PropertyIDSeq            varchar(50)   Null,
                                      AccountIDSeq             varchar(50)   Not Null,
                                      OrderIDSeq               varchar(50)   Null,
                                      OrderGroupIDSeq          varchar(50)   Null,
                                      OrderItemIDSeq           varchar(50)   Null,
                                      ProductCode              varchar(50)   Not Null,
                                      PriceVersion             numeric(18,0) Not Null,
                                      SourceTransactionID      varchar(50)   Null,
                                      TransactionServiceDate   varchar(50)   Not Null,
                                      TransactionItemName      varchar(4000) Not Null,
                                      ListPrice                numeric(30,5) Not Null,
                                      Quantity                 numeric(30,0) Not Null,
                                      NetPrice                 numeric(30,5) Not Null,
                                      AmountOverrideFlag       int           Not Null,
                                      SOCChargeAmount          numeric(30,5) Not Null,
                                      ImportableTransactionFlag  int         Not Null,
                                      TranEnablerRecordFoundFlag int         Not Null,
                                      PreValidationErrorFlag     int         Not Null,
                                      ------------------------------------------------- 
                                      ---Return Columnns
                                      OrderItemTransactionIDSeq   varchar(50)   Not Null default(-9999),
                                      DetailPostingStatusFlag     int           Not Null default(0),
                                      DetailPostingErrorMessage   varchar(max)  NULL,                                     
                                      -------------------------------------------------
                                      ModifiedDate                datetime,  
                                      PRIMARY KEY CLUSTERED 
                                      (
	                                [SortSeq] ASC
                                      )WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON, FILLFACTOR = 100) ON [PRIMARY]
                                     ) ON [PRIMARY];
  ------------------------------------------------------------------------
  --Initial Validation 1: If Batch Header is already failed, throw error.
  if exists (select top 1 1
             from  ORDERS.dbo.TransactionImportBatchHeader with (nolock)
             where IDSeq      = @IPI_TransactionImportIDSeq
             and   BatchPostingStatusFlag = 2
            )
  begin
    select @LVC_CodeSection = 'Import Batch Header : ' + convert(varchar(100),@IPI_TransactionImportIDSeq) + ' is already Posted and Failed. This Batch cannot be posted again.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  ------------------------------------------------------------------------
  --Initial Validation 2: If Batch Header is already posted, throw error.
  if exists (select top 1 1
             from  ORDERS.dbo.TransactionImportBatchHeader with (nolock)
             where IDSeq      = @IPI_TransactionImportIDSeq
             and   BatchPostingStatusFlag = 1
            )
  begin
    select @LVC_CodeSection = 'Import Batch Header : ' + convert(varchar(100),@IPI_TransactionImportIDSeq) + ' is already successfully posted. This Batch cannot be posted again.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;
  end
  ------------------------------------------------------------------------
  --Initial Validation 3: If Batch Header is Not Posted, Proceed with Posting.
  if exists (select top 1 1
             from  ORDERS.dbo.TransactionImportBatchHeader with (nolock)
             where IDSeq      = @IPI_TransactionImportIDSeq
             and   BatchPostingStatusFlag = 0
            )
  begin
    select Top 1 @LVC_ImportSource        = ImportSource,
                 @LI_EstimatedImportCount = EstimatedImportCount
    from   ORDERS.dbo.TransactionImportBatchHeader with (nolock)
    where  IDSeq      = @IPI_TransactionImportIDSeq
    and    BatchPostingStatusFlag = 0

    select @LI_ToBeImportedCount    = S.ActualImportCount
    from  (select count(1)             as ActualImportCount                
           from   ORDERS.dbo.TransactionImportBatchDetail IBD with (nolock)
           where  IBD.TransactionImportIDSeq    = @IPI_TransactionImportIDSeq
           and    IBD.DetailPostingStatusFlag   = 0
           and    IBD.ImportableTransactionFlag = 1
          ) S

    Insert into #LT_PrePostBatchDetail(TransactionImportIDSeq,TransactionImportBatchDetailIDSeq,
                                       UserIDSeq,TransactionImportDate,
                                       CompanyIDSeq,PropertyIDSeq,AccountIDSeq,OrderIDSeq,OrderGroupIDSeq,OrderItemIDSeq,
                                       ProductCode,PriceVersion,SourceTransactionID,TransactionServiceDate,TransactionItemName,
                                       ListPrice,Quantity,NetPrice,AmountOverrideFlag,SOCChargeAmount,ImportableTransactionFlag,TranEnablerRecordFoundFlag,PreValidationErrorFlag,
                                       ModifiedDate
                                      )
    select IBD.TransactionImportIDSeq as TransactionImportIDSeq, IBD.IDSeq as TransactionImportBatchDetailIDSeq,
           IBD.CreatedByIDSeq     as UserIDSeq,IBD.CreatedDate as  TransactionImportDate,
           IBD.CompanyIDSeq,IBD.PropertyIDSeq,IBD.AccountIDSeq,IBD.OrderIDSeq,IBD.OrderGroupIDSeq,IBD.OrderItemIDSeq,
           IBD.ProductCode,IBD.PriceVersion,IBD.SourceTransactionID,IBD.TransactionServiceDate,IBD.TransactionItemName,
           IBD.ListPrice,IBD.Quantity,IBD.NetChargeAmount as NetPrice,IBD.UserAmountOverrideFlag as AmountOverrideFlag,
           IBD.SOCChargeAmount,IBD.ImportableTransactionFlag,IBD.TranEnablerRecordFoundFlag,IBD.PreValidationErrorFlag,
           getdate()
    from   ORDERS.dbo.TransactionImportBatchDetail IBD with (nolock)
    where  IBD.TransactionImportIDSeq  = @IPI_TransactionImportIDSeq
    and    IBD.DetailPostingStatusFlag = 0    
    Order by IBD.IDSeq ASC;
   -----------------------------------------------------------------------
    --Begin Loop to Post to Final Orders.dbo.OrderItemTransaction table
    select @LI_Min=1,@LI_Max = count(1)from #LT_PrePostBatchDetail with (nolock)
    while @LI_Min <= @LI_Max
    begin
      if (@LI_EstimatedImportCount = @LI_ToBeImportedCount)
      begin
        select @LI_UserIDSeq                   =S.UserIDSeq,
               @LI_TransactionImportIDSeq      =S.TransactionImportIDSeq,
               @LI_TransactionImportBatchDetailIDSeq=S.TransactionImportBatchDetailIDSeq,
               @LDT_TransactionImportDate      =S.TransactionImportDate,
               @LVC_CompanyIDSeq               =S.CompanyIDSeq,
               @LVC_PropertyIDSeq              =S.PropertyIDSeq,
               @LVC_AccountIDSeq               =S.AccountIDSeq,
               @LVC_OrderIDSeq                 =S.OrderIDSeq,
               @LVC_OrderGroupIDSeq            =S.OrderGroupIDSeq,
               @LVC_OrderItemIDSeq             =S.OrderItemIDSeq,
               @LVC_ProductCode                =S.ProductCode,
               @LN_PriceVersion                =S.PriceVersion,
               @LVC_SourceTransactionID        =S.SourceTransactionID,
               @LVC_TransactionServiceDate     =S.TransactionServiceDate,
               @LVC_TransactionItemName        =S.TransactionItemName,
               @LN_ListPrice                   =S.ListPrice,
               @LN_Quantity                    =S.Quantity,
               @LN_NetPrice                    =S.NetPrice,
               @LI_AmountOverrideFlag          =S.AmountOverrideFlag,
               @LN_SOCChargeAmount             =S.SOCChargeAmount,
               @LI_ImportableTransactionFlag   =S.ImportableTransactionFlag,
               @LI_TranEnablerRecordFoundFlag  =S.TranEnablerRecordFoundFlag,
               @LI_PreValidationErrorFlag      =S.PreValidationErrorFlag,
               @LVC_ImportSource               =@LVC_ImportSource
        from   #LT_PrePostBatchDetail S with (nolock)
        where  S.SortSeq =  @LI_Min
        --Call uspORDERS_ImportExcelTransactions to Post record in the loop        
        exec   Orders.dbo.uspORDERS_ImportExcelTransactions 
                                 @LOPVC_OrderIDSeq                output,     
                                 @LOPBI_OrderGroupIDSeq           output,
                                 @LOPBI_OrderItemIDSeq            output,
                                 @LOPBI_OrderItemTransactionID    output,
                                 @LOPI_DetailPostingStatusFlag    output,
                                 @LOPVC_DetailPostingErrorMessage output,
                                 @IPI_UserIDSeq                   =@LI_UserIDSeq,
                                 @IPI_TransactionImportIDSeq      =@LI_TransactionImportIDSeq,
                                 @IPI_TransactionImportDetailIDSeq=@LI_TransactionImportBatchDetailIDSeq,
                                 @IPDT_TransactionImportDate      =@LDT_TransactionImportDate,
                                 @IPVC_CompanyIDSeq               =@LVC_CompanyIDSeq,
                                 @IPVC_PropertyIDSeq              =@LVC_PropertyIDSeq,
                                 @IPVC_AccountIDSeq               =@LVC_AccountIDSeq,
                                 @IPVC_OrderIDSeq                 =@LVC_OrderIDSeq,
                                 @IPVC_OrderGroupIDSeq            =@LVC_OrderGroupIDSeq,
                                 @IPVC_OrderItemIDSeq             =@LVC_OrderItemIDSeq,
                                 @IPVC_ProductCode                =@LVC_ProductCode,
                                 @IPN_PriceVersion                =@LN_PriceVersion,
                                 @IPVC_SourceTransactionID        =@LVC_SourceTransactionID,
                                 @IPVC_TransactionServiceDate     =@LVC_TransactionServiceDate,
                                 @IPVC_TransactionItemName        =@LVC_TransactionItemName,
                                 @IPN_ListPrice                   =@LN_ListPrice,
                                 @IPN_Quantity                    =@LN_Quantity,
                                 @IPN_NetPrice                    =@LN_NetPrice,
                                 @IPI_AmountOverrideFlag          =@LI_AmountOverrideFlag,
                                 @IPN_SOCChargeAmount             =@LN_SOCChargeAmount,
                                 @IPI_ImportableTransactionFlag   =@LI_ImportableTransactionFlag,
                                 @IPI_TranEnablerRecordFoundFlag  =@LI_TranEnablerRecordFoundFlag,
                                 @IPI_PreValidationErrorFlag      =@LI_PreValidationErrorFlag,
                                 @IPVC_ImportSource               =@LVC_ImportSource
        --Update to record the results back from Post
        Update D
        set    D.OrderIDSeq                  = @LOPVC_OrderIDSeq,
               D.OrderGroupIDSeq             = @LOPBI_OrderGroupIDSeq,
               D.OrderItemIDSeq              = @LOPBI_OrderItemIDSeq,
               D.OrderItemTransactionIDSeq   = @LOPBI_OrderItemTransactionID,
               D.DetailPostingStatusFlag     = (Case when @LOPBI_OrderItemTransactionID = -9999 then 2 else @LOPI_DetailPostingStatusFlag end),
               D.DetailPostingErrorMessage   = @LOPVC_DetailPostingErrorMessage,
               D.ModifiedDate                = getdate()
        from   #LT_PrePostBatchDetail D with (nolock)
        where  D.SortSeq                           = @LI_Min
        and    D.TransactionImportIDSeq            = @LI_TransactionImportIDSeq
        and    D.TransactionImportBatchDetailIDSeq = @LI_TransactionImportBatchDetailIDSeq
      end  

      --Reinitializing output variables before next loop    
      select @LOPVC_OrderIDSeq=NULL,@LOPBI_OrderGroupIDSeq=NULL,@LOPBI_OrderItemIDSeq=NULL,
             @LOPBI_OrderItemTransactionID= NULL,@LOPI_DetailPostingStatusFlag=0,
             @LOPVC_DetailPostingErrorMessage = NULL
      --Loop back to next row
      select @LI_Min = @LI_Min + 1
    end
  end
  ------------------------------------------------------------------------
  --Post Batch Posting Operations
  ------------------------------------------------------------------------  
  select @LI_ActualImportCount    = S.ActualImportCount,
         @LM_TotalNetChargeAmount = S.TotalNetChargeAmount
  from  (select count(1)             as ActualImportCount,
                sum(NetChargeAmount) as TotalNetChargeAmount
         from   Orders.dbo.OrderItemTransaction OIT with (nolock)
         where  TransactionImportIDSeq = @IPI_TransactionImportIDSeq
         and    ImportSource           = @LVC_ImportSource
        ) S
  --------------------------------------------------------------  
  --Step 1 : If atleast 1 UnPosted record with Error, OR
  --         If @LI_EstimatedImportCount <> @LI_ActualImportCount
  --         then Rollback the entire batch 
  --         and hold only Error Records in The Batch 
  --         and mark as Error
  if exists (select top 1 1 
             from   #LT_PrePostBatchDetail D with (nolock)
             where  D.TransactionImportIDSeq  = @IPI_TransactionImportIDSeq
             and    D.DetailPostingStatusFlag = 0
             )
             OR
            (@LI_EstimatedImportCount <> @LI_ActualImportCount)
  begin
    select @LI_ErrorCount = count(1)           
    from   #LT_PrePostBatchDetail D with (nolock)
    where  D.TransactionImportIDSeq  = @IPI_TransactionImportIDSeq
    and    D.DetailPostingStatusFlag in (0,2)

    delete from Orders.dbo.OrderItemTransaction 
    where TransactionImportIDSeq = @IPI_TransactionImportIDSeq
    and   ImportSource           = @LVC_ImportSource

    Update D
    set    D.DetailPostingStatusFlag   = 2,
           D.DetailPostingErrorMessage = coalesce(S.DetailPostingErrorMessage,'Batch Posting to OrderItemTransaction Failed.'),
           D.ModifiedByIDSeq           = D.CreatedByIDSeq,
           D.ModifiedDate              = S.ModifiedDate,
           D.SystemLogDate             = Getdate()
    from   Orders.dbo.TransactionImportBatchDetail D with (nolock)
    inner Join
           #LT_PrePostBatchDetail S with (nolock)
    on     D.IDSeq                  = S.TransactionImportBatchDetailIDSeq
    and    D.TransactionImportIDSeq = S.TransactionImportIDSeq
    and    D.TransactionImportIDSeq = @IPI_TransactionImportIDSeq
    and    (S.DetailPostingStatusFlag in (0,2)
              AND
            (@LI_EstimatedImportCount <> @LI_ActualImportCount)
           )  

    Delete D
    from   Orders.dbo.TransactionImportBatchDetail D with (nolock)
    inner Join
           #LT_PrePostBatchDetail S with (nolock)
    on     D.IDSeq                  = S.TransactionImportBatchDetailIDSeq
    and    D.TransactionImportIDSeq = S.TransactionImportIDSeq
    and    D.TransactionImportIDSeq = @IPI_TransactionImportIDSeq
    and    (S.DetailPostingStatusFlag = 1              
           )    

    Update Orders.dbo.TransactionImportBatchHeader
    set    ActualImportCount      = 0,
           ErrorCount             = (case when @LI_ErrorCount > 0 then @LI_ErrorCount
                                          when (@LI_EstimatedImportCount <> @LI_ActualImportCount) then @LI_ActualImportCount
                                          else 0
                                     end),
           TotalNetChargeAmount   = 0.00,
           BatchPostingStatusFlag = 2,
           ErrorMessage           = 'Import Transactions Batch Posting Failure' +
                                    (case when @LI_ErrorCount > 0 then ',with alteast One Transaction(s) Failed.'
                                          when (@LI_EstimatedImportCount <> @LI_ActualImportCount) then ',with Estimated Count: ' + Convert(varchar(100),@LI_EstimatedImportCount) +
                                                                                                        'and Actual Count: ' + Convert(varchar(100),@LI_ActualImportCount)
                                          else ''
                                     end),
           ModifiedByIDSeq       = CreatedByIDSeq,
           ModifiedDate          = Getdate(),
           SystemLogDate         = Getdate()
    where  IDSeq                 = @IPI_TransactionImportIDSeq
  end
  else
  begin
    Update D
    set    D.DetailPostingStatusFlag   = S.DetailPostingStatusFlag,
           D.DetailPostingErrorMessage = S.DetailPostingErrorMessage,
           D.OrderIDSeq                = S.OrderIDSeq,
           D.OrderGroupIDSeq           = S.OrderGroupIDSeq,
           D.OrderItemIDSeq            = S.OrderItemIDSeq,
           D.OrderItemTransactionIDSeq = S.OrderItemTransactionIDSeq,
           D.ModifiedByIDSeq           = D.CreatedByIDSeq,
           D.ModifiedDate              = S.ModifiedDate,
           SystemLogDate               = Getdate()
    from   Orders.dbo.TransactionImportBatchDetail D with (nolock)
    inner Join
           #LT_PrePostBatchDetail S with (nolock)
    on     D.IDSeq                   = S.TransactionImportBatchDetailIDSeq
    and    D.TransactionImportIDSeq  = S.TransactionImportIDSeq
    and    D.TransactionImportIDSeq  = @IPI_TransactionImportIDSeq
    and    S.DetailPostingStatusFlag = 1

    Update Orders.dbo.TransactionImportBatchHeader
    set    ActualImportCount       = @LI_ActualImportCount,
           ErrorCount              = 0,
           TotalNetChargeAmount    = @LM_TotalNetChargeAmount,
           BatchPostingStatusFlag  = 1,
           ErrorMessage            = NULL,
           ModifiedByIDSeq         = CreatedByIDSeq,
           ModifiedDate            = Getdate(),
           SystemLogDate           = Getdate()
    where  IDSeq                   = @IPI_TransactionImportIDSeq
  end 
  ------------------------------------------------------------------------
  --Final Cleanup
  if (object_id('tempdb.dbo.#LT_PrePostBatchDetail') is not null) 
  begin
    drop table #LT_PrePostBatchDetail;
  end;  
  ------------------------------------------------------------------------
END
GO
