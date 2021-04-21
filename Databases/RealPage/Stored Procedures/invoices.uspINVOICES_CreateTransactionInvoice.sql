SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901017539',@IPVC_CompanyID='C0901010426',@IPVC_PropertyID='P0901011067',@LBI_OrderID='O0901089317',@LDT_TargetDate='12/30/2009',@IPI_TargetDays=45
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901009149',@IPVC_CompanyID='C0901007842',@IPVC_PropertyID='P0901035239',@LBI_OrderID='O0901073728',@LDT_TargetDate='03/15/2009',@IPI_TargetDays=45
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901023769',@IPVC_CompanyID='C0901007842',@IPVC_PropertyID='P0901036155',@LBI_OrderID='O0901114229',@LDT_TargetDate='03/15/2009',@IPI_TargetDays=45
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901000199',@IPVC_CompanyID='C0901005076',@IPVC_PropertyID='P0901000069',@LBI_OrderID='O0901114235',@LDT_TargetDate='03/15/2009',@IPI_TargetDays=45
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901026876',@IPVC_CompanyID='C0901006985',@IPVC_PropertyID='P0901048536',@LBI_OrderID='O0901114226',@LDT_TargetDate='03/15/2009',@IPI_TargetDays=45
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901016879',@IPVC_CompanyID='C0901006805',@IPVC_PropertyID='P0901008506',@LBI_OrderID='O0901114233',@LDT_TargetDate='03/15/2009',@IPI_TargetDays=45
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901026835',@IPVC_CompanyID='C0901009716',@IPVC_PropertyID='P0901048462',@LBI_OrderID='O0901114225',@LDT_TargetDate='03/15/2009',@IPI_TargetDays=45
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901027486',@IPVC_CompanyID='C0901003853',@IPVC_PropertyID='P0901050517',@LBI_OrderID='O0901114227',@LDT_TargetDate='03/15/2009',@IPI_TargetDays=45
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901003538',@IPVC_CompanyID='C0901004070',@IPVC_PropertyID='P0901012629',@LBI_OrderID='O0901114232',@LDT_TargetDate='03/15/2009',@IPI_TargetDays=45
Exec uspINVOICES_CreateTransactionInvoice @IPVC_AccountID = 'A0901027710',@IPVC_CompanyID='C0901006985',@IPVC_PropertyID='P0901051398',@LBI_OrderID='O0901114228',@LDT_TargetDate='03/15/2009',@IPI_TargetDays=45

*/
---------------------------------------------------------------------------------------------
-- database  name  : Invoices
-- procedure name  : [uspINVOICES_CreateTransactionInvoice]
-- description     : This procedure creates Transaction Invoice for a given Account and Order
-- input parameters: @IPVC_AccountID    as  varchar(50) 
--                   @IPVC_CompanyID    as  varchar(50)
--                   @IPVC_PropertyID   as  varchar(50)
--					 @LBI_OrderID      varchar(50)
-- output          : InvoiceIDSeq
-- code example    : 
--                  Exec INVOICES.DBO.[uspINVOICES_CreateTransactionInvoice] @IPVC_AccountID  = 'A0712000093',
--									     @IPVC_CompanyID   = 'C0000004021', 
--									     @IPVC_PropertyID  = 'P0000012472',
--									     @LBI_OrderID    = 'O0712000207'   

-- 11/07/2011      : TFS 1514 : Transaction is moved to SP code from UI
----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_CreateTransactionInvoice] (
                                                               @IPVC_AccountID   VARCHAR(50),
							       @IPVC_CompanyID   VARCHAR(50),
							       @IPVC_PropertyID  VARCHAR(50)=NULL,
							       @LBI_OrderID      VARCHAR(50)
							      ) 
AS
BEGIN --: Main Procedure Begin
  SET NOCOUNT ON;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  ------------------------------------------------------------------------------------------------
  declare @LI_SeparateInvoiceByFamilyFlag     int,
          @LI_CMPFlag                         int,
          @LI_CMPSeparateInvoiceByFamilyFlag  int,
          @LI_PRPSeparateInvoiceByFamilyFlag  int

  select @LI_SeparateInvoiceByFamilyFlag = 0
  -------------------------------------------------------------------------------------------------
  set @IPVC_PropertyID= nullif(@IPVC_PropertyID,'')
  -------------------------------------------------------------------------------------------------
  --Declaring Local Variables
  -------------------------------------------------------------------------------------------------
  DECLARE @LVC_InvoiceID                   VARCHAR(50)
  DECLARE @LVC_InvoiceStatusCode           VARCHAR(50)
  DECLARE @LI_InvoiceTerms                 INT
  DECLARE @LI_PriceTerms                   INT
  DECLARE @LDT_InvoiceDate                 DATETIME
  DECLARE @LVC_AccountTypeCode             VARCHAR(5)
  DECLARE @LDT_RunDateTime                 DATETIME
  DECLARE @LI_MIN                          BIGINT
  DECLARE @LI_MAX                          BIGINT  
  DECLARE @LI_OrderIDSeq                   VARCHAR(50)
  DECLARE @LI_OrderGroupIDSeq              BIGINT
  Declare @LBI_GroupID                     BIGINT
  Declare @LI_CBEnabledFlag                INT  
  DECLARE @LVC_OrderGroupName              VARCHAR(500)
  DECLARE @LI_InvoiceGroupIDSeq            BIGINT
  DECLARE @LM_TransactionChargeAmount      MONEY
  DECLARE @LVC_EpicorCustomerCode          VARCHAR(8)
  DECLARE @LVC_CustomBundleNameEnabledFlag SMALLINT
  DECLARE @LI_TransactionLineItemCount     INT
--  DECLARE @LI_OrderLineItemCount           int

  
  DECLARE @LVC_CompanyName                 VARCHAR(255)
  DECLARE @LVC_PropertyName                VARCHAR(255)
  DECLARE @LI_OrderLineItemCount           INT 
  DECLARE @LI_MonthlyLineItemCount         INT -- used to determine Monthly Invoices.
  DECLARE @LI_ILFLineItemCount             INT -- IF 1, thereISatleast ILF to process, IF 0, dON't create an Invoice.
  DECLARE @LI_AccessYearlyLineItemCount    INT
  DECLARE @LI_MinValue                     INT
  DECLARE @LI_MaxValue                     INT
  DECLARE @LVC_SeparateInvoiceProductFamilyCode   Varchar(50)
  DECLARE @LVC_EpicorPostingCode           Varchar(10)
  DECLARE @LVC_TaxwareCompanyCode          Varchar(10)
  DECLARE @LVBI_OrderItemIDSeq             BIGINT
  DECLARE @LVC_BillToAddressTypeCode       VARCHAR(20)
  DECLARE @LVC_BillToDeliveryOptionCode    VARCHAR(20)
  DECLARE @LVBI_SeparateInvoiceGroupNumber BIGINT
  DECLARE @LVB_MarkAsPrintedFlag           INT
  DECLARE @LI_PrePaidFlag                  INT
  DECLARE @LDT_BillingCycleDate            DATETIME
  -------------------------------------------------------------------------------------------------
  --for error handling 
  DECLARE @SQLErrorCode                    INT
  DECLARE @SQLRowCount                     INT 
  DECLARE @ErrorDescription                VARCHAR(300)
  DECLARE @LVC_CodeSection                 VARCHAR(500) 
  ----------------------------------------------------------------------------------------
  -- Validation Query to check if "@IPVC_AccountID" is related to OrderID "@LBI_OrderID".
  ----------------------------------------------------------------------------------------
  IF NOT Exists (SELECT top 1 1
                 FROM   Orders.dbo.[Order] WITH (nolock)
                 WHERE OrderIDSeq = @LBI_OrderID and AccountIDSeq = @IPVC_AccountID )
    BEGIN 
      SELECT @LVC_CodeSection = 'Order ' + @LBI_OrderID   + ' does not belong to AccountID ' +  @IPVC_AccountID
      EXEC   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection =   @LVC_CodeSection
      RETURN -- quit procedure! 
    END
 -------------------------------------------------------------------------------------------------
  --Declaring Local Table Variables
 -------------------------------------------------------------------------------------------------
  CREATE TABLE #TEMP_InvoiceIDHoldingTable (IDSeq          int not null identity(1,1),
                                            SQLErrorCode   varchar(50),
                                            InvoiceID      varchar(50)
                                           )
  CREATE TABLE #TEMPCompany 
                            (
                             [IDSeq]                   [VARCHAR](22)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [Name]                    [VARCHAR](100)       COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [PMCFlag]                 [BIT]                NOT NULL,
	                     [PriceTerm]               [INT]                NULL,
                             [SendInvoiceToClientFlag] [INT]                NOT NULL default(1)
                            )

  CREATE TABLE #TEMPProperty 
                            (
                             [IDSeq]                   [VARCHAR](22)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
                             [Name]                    [VARCHAR](100)       COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [PMCIDSeq]                [VARCHAR](22)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [OwnerIDSeq]              [VARCHAR](22)        COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [Units]                   [INT]                NOT NULL,
                             [Beds]                    [INT]                NOT NULL,
	                     [PPUPercentage]           [INT]                NULL,
	                     [PriceTerm]               [INT]                NULL,
                             [SendInvoiceToClientFlag] [INT]                NOT NULL default(1)
                            )

  CREATE TABLE #TEMPAccount 
                            (
                             [IDSeq]                  [VARCHAR](22)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
                             [AccountTypeCode]        [VARCHAR](5)         COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
                             [CompanyIDSeq]           [VARCHAR](22)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [PropertyIDSeq]          [VARCHAR](22)        COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [EpicorCustomerCode]     [VARCHAR](8)         COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [PriceTerm]              [INT]                NULL,
                            )

  CREATE TABLE #TEMPAddress 
                            (
                             [IDSeq]                  [INT]                NOT NULL,
	                     [CompanyIDSeq]           [VARCHAR](22)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [PropertyIDSeq]          [VARCHAR](22)        COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [AccountName]            [VARCHAR](100)       COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [AddressTypeCode]        [CHAR](3)            COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [AddressLine1]           [VARCHAR](200)       COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [AddressLine2]           [VARCHAR](100)       COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [City]                   [VARCHAR](70)        COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [County]                 [VARCHAR](70)        COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [State]                  [CHAR](2)            COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [Zip]                    [VARCHAR](10)        COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
	                     [Country]                [VARCHAR](30)        COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
                             [SameAsPMCAddressFlag]   [BIT]                NOT NULL,
			     [CountryCode]            [VARCHAR](3),
                             [Email]                  VARCHAR(MAX)         NULL           
                            )

  CREATE TABLE #TEMPInvoiceGroup 
                           (
                             [InvoiceIDSeq]                [VARCHAR](22)   COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
     	                     [OrderIDSeq]                  [VARCHAR](50)   NOT NULL,
                             [OrderGroupIDSeq]             [BIGINT]        NOT NULL,
	                     [Name]                        [VARCHAR](70)   COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
                             [CustomBundleNameEnabledFlag] [BIT] 
                           )

  CREATE TABLE #TEMPInvoiceGroupFinal 
                          (
                             [SEQ]                         [BIGINT]        IDENTITY(1,1) NOT NULL,
                             [InvoiceIDSeq]                [VARCHAR](22)   COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
     	                     [OrderIDSeq]                  [VARCHAR](50)   NOT NULL,
	                     [OrderGroupIDSeq]             [BIGINT]        NOT NULL,
	                     [Name]                        [VARCHAR](70)   COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
                             [CustomBundleNameEnabledFlag] [BIT] 
                          )

  CREATE TABLE #TEMPInvoiceItem 
                         (
                             [InvoiceIDSeq]               [VARCHAR](22)    COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
                             [OrderIDSeq]                 [VARCHAR](50)    NOT NULL,
	                     [OrderGroupIDSeq]            [BIGINT]         NOT NULL,
 	                     [OrderItemIDSeq]             [BIGINT]         NOT NULL,                              
	                     [ProductCode]                [VARCHAR](30)    COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [ChargeTypeCode]             [CHAR](3)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [FrequencyCode]              [CHAR](6)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [MeasureCode]                [CHAR](6)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [Quantity]                   [numeric](30, 5) NULL,                
	                     [ChargeAmount]               [numeric](30, 5) NULL,
	                     [EffectiveQuantity]          [numeric](30, 5),
	                     [ExtChargeAmount]            [MONEY]          NOT NULL,
	                     [DiscountAmount]             [MONEY]          NOT NULL,	                      
	                     [NetChargeAmount]            [MONEY]          NOT NULL,
	                     [BillingPeriodFromDate]      [DATETIME]       NOT NULL,
	                     [BillingPeriodToDate]        [DATETIME]           NULL,
                             [PriceVersion]               [NUMERIC](18, 0)     NULL,
			     [RevenueTierCode]            [VARCHAR](50),
			     [RevenueAccountCode]         [VARCHAR](50),
			     [DeferredRevenueAccountCode] [VARCHAR](50),
			     [RevenueRecognitionCode]     [VARCHAR](50),
			     [TaxwareCode]                [VARCHAR](50),
                             [DefaultTaxwareCode]         [VARCHAR](50),
			     [ShippingAndHandlingAmount]  [MONEY]          NOT NULL,  
                             [UnitOfMeasure]              [DECIMAL](18, 5),
                             [ReportingTypeCode]          [VARCHAR](4),
                             [PricingTiers]               [INT],
                             OrderItemTransactionIDseq    bigint,
			     TransactionItemName          varchar(300),
			     ServiceCode                  varchar(30),
			     TransactionDate              datetime,
                             [BillToAddressTypeCode]      [VARCHAR](20),
                             [BillToDeliveryOptionCode]   [VARCHAR](20),
                             [Units]                      [INT],
                             [Beds]                       [INT],
                             [PPUPercentage]              [INT]
                          ) 

  -- *** used to Identify order line items for invoicing *** -- 
  CREATE TABLE #TEMPOrderItem  
                         (	
                             [InvoiceIDSeq]               [VARCHAR](22),
                             [OrderItemIDSeq]             [BIGINT]      NOT NULL,
                             [OrderIDSeq]                 [VARCHAR](50) NOT NULL,
                             [OrderGroupIDSeq]            [BIGINT]      NOT NULL,
                             [ProductCode]                [CHAR](30), 
                             [ChargeTypeCode]             [CHAR](3),
                             [FrequencyCode]              [CHAR](6), 
                             [MeasureCode]                [CHAR](6), 
                             [FamilyCode]                 [CHAR](3), 
                             [PriceVersion]               [numeric](18, 0) NULL,
                             [Quantity]                   [numeric](30, 5) NULL,
                             [ChargeAmount]               [numeric](30, 5) NULL, 
                             [EffectiveQuantity]          [numeric](30, 5), 
                             [ExtChargeAmount]            [MONEY]          NOT NULL, 
                             [DiscountPercent]            [numeric](30, 5),
                             [DiscountAmount]             [MONEY]          NOT NULL, 
                             [NetChargeAmount]            [MONEY]          NOT NULL, 
                             [ILFStartDate]               [DATETIME]           NULL,
                             [ILFEndDate]                 [DATETIME]           NULL,
                             [ActivationStartDate]        [DATETIME]           NULL,
                             [ActivationEndDate]          [DATETIME]           NULL,
                             [StatusCode]                 [VARCHAR](5)         NULL,
                             [StartDate]                  [DATETIME]           NULL,
                             [EndDate]                    [DATETIME]           NULL,
                             [LastBillingPeriodFromDate]  [DATETIME]           NULL,
                             [LastBillingPeriodToDate]    [DATETIME]           NULL,
                             [BillToAddressTypeCode]      [VARCHAR](20),
                             [BillToDeliveryOptionCode]   [VARCHAR](20),
                             [CancelDate]                 [DATETIME]           NULL,
                             [CapMaxUnitsFlag]            [BIT]            NOT NULL,
                             [NewActivationStartDate]     [DATETIME]           NULL, 
                             [NewActivationEndDate]       [DATETIME]           NULL, 
                             [AccountIDSeq]               [CHAR](11),
                             [QuoteIDSeq]                 [VARCHAR](50),
                             [NewILFStartDate]            [DATETIME]           NULL, 
                             [NewILFEndDate]              [DATETIME]           NULL, 
                             [OrderstatusCode]            [VARCHAR](5),
                             [RevenueTierCode]            [VARCHAR](50),
                             [RevenueAccountCode]         [VARCHAR](50),
                             [DeferredRevenueAccountCode] [VARCHAR](50),
                             [RevenueRecognitionCode]     [VARCHAR](50),
                             [TaxwareCode]                [VARCHAR](50),
                             [DefaultTaxwareCode]         [VARCHAR](50),
                             [ShippingAndHandlingAmount]  [MONEY]          NOT NULL,
                             [UnitOfMeasure]              [decimal](18, 5),
                             [SeparateInvoiceGroupNumber] [BIGINT],
			     [ReportingTypeCode]          [VARCHAR](4),
                             [PricingTiers]               [INT],
                             OrderItemTransactionIDseq    bigint, 
                             TransactionItemName          varchar(500),
                             ServiceCode                  varchar(30),
                             TransactionDate              datetime,
                             [Units]                      [INT],
                             [Beds]                       [INT],
                             [PPUPercentage]              [INT],
                             [TargetDate]                 [DATETIME]        NOT NULL
                         )
  
  CREATE TABLE #TEMPAddrType_InvGroupNumber 
                        (
                             [SEQ]                        [BIGINT] IDENTITY(1,1) NOT NULL,
                             [OrderItemIDSeq]             [BIGINT]               NOT NULL,
                             [OrderGroupIDSeq]            [BIGINT]               NOT NULL,
                             [CBEnabledFlag]              [BIGINT]               NOT NULL, 
                             [BillToAddressTypeCode]      [VARCHAR](20),
                             [BillToDeliveryOptionCode]   [VARCHAR](20),
                             [SeparateInvoiceGroupNumber] [BIGINT],
                             [MarkAsPrintedFlag]          [INT],
                             [SeparateInvoiceProductFamilyCode]  [VARCHAR](10) NULL,
                             [EpicorPostingCode]          [VARCHAR](10) NULL,
                             [TaxwareCompanyCode]         [VARCHAR](10) NULL,
                             [PrePaidFlag]                [INT]
                        )
  -------------------------------------------------------------------------------------------------      
  ---Initialization of local Variables
  -------------------------------------------------------------------------------------------------      
  SELECT 
          @LI_MIN                       = 1
         ,@LI_MAX                       = 0
         ,@LVC_InvoiceStatusCode        = 'PENDG'
         ,@LI_InvoiceTerms              = 30
         ,@LDT_RunDateTime              = getdate()
         ,@LDT_InvoiceDate              = @LDT_RunDateTime 
         ,@LI_TransactionLineItemCount  = 0 
  -------------------------------------------------------------------------------------------------      
  ---Initialization of Input Parameters IF NOT passed
  ------------------------------------------------------------------------------------------------- 
  IF (@IPVC_PropertyID IS NULL or @IPVC_PropertyID = '') --When PropertyIDSeq is not supplied as parameter.
  BEGIN
    SELECT @IPVC_PropertyID = (SELECT PropertyIDSeq FROM Orders.dbo.[Order] WITH (NOLOCK) WHERE OrderIDSeq=@LBI_OrderID)
  END
  
  SELECT TOP 1 @LDT_BillingCycleDate = BillingCycleDate
  FROM   INVOICES.dbo.InvoiceEOMServiceControl with (nolock)
  WHERE  BillingCycleClosedFlag = 0
  ------------------------------------------------------------------------------------------------- 
  -- Retrieving the count of Transaction items that should be Inserted into #TEMPOrderItem table - 
  -- IF 0 order items were found, THEN quit the procedure (Nothing to process).
  ------------------------------------------------------------------------------------------------- 
  SELECT @LI_TransactionLineItemCount = Count(OIT.IDSeq)
  FROM   Orders.dbo.[Orderitem] OI with (nolock)
  ------------
  inner Join
         Products.dbo.Charge C with (nolock)
  on      OI.ProductCode       = C.ProductCode
  and     OI.PriceVersion      = C.PriceVersion
  and     OI.ChargeTypeCode    = C.ChargeTypeCode
  and     OI.MeasureCode       = C.MeasureCode
  and     OI.FrequencyCode     = C.FrequencyCode
  and     OI.MeasureCode       = 'TRAN'
  and     OI.DoNotInvoiceFlag  = 0
  and     OI.OrderIDSeq        = @LBI_OrderID 
  Inner Join
          INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
  on      C.LeadDays           = BTM.LeadDays
  and     BTM.BillingCycleDate = @LDT_BillingCycleDate
  ----------------
  Inner Join
        Orders.dbo.[OrderItemTransaction] OIT with (nolock)
  on      OIT.OrderIDSeq = OI.OrderIDSeq 
  and     OI.OrderIDSeq  = @LBI_OrderID 
  and     OIT.OrderIDSeq = @LBI_OrderID 
  and     OI.IDseq       = OIT.OrderItemIDSeq
  and     OIT.TransactionalFlag = 1
  and     OIT.InvoicedFlag      = 0 
  and     OIT.ServiceDate       <= BTM.TargetDate  
  ---and    ServiceDate       <= @LDT_TargetDate  
  -- Note : All Transactions with TransactionalFlag=1 and InvoicedFlag=0 should be invoiced
  --        irrespective of dates.
  -------------------------------------------------------------------------------------------------
  -- IF 0 order items were found, then quit this procedure.
  -------------------------------------------------------------------------------------------------
  IF @LI_TransactionLineItemCount = 0 
    BEGIN 
      SELECT 0 as SQLErrorcode, 'ABCDEFGHIJK' as InvoiceID --> Dummy Returned to UI 
      RETURN -- There is nothing to process.
    END 
  -------------------------------------------------------------------------------------------------
  -- Populating Table #TEMPAddrType_InvGroupNumber 
  -- to get values of OrderItemIDSeq,BillToAddressTypeCode, SeparateInvoiceGroupNumber,MarkAsPrintedFlag columns 
  -- based on the OrderID passed
  ---------------------------------------------------------------------------------------------------------------------
  SELECT @LVC_CompanyName     = [Name],@LI_CMPSeparateInvoiceByFamilyFlag = SeparateInvoiceByFamilyFlag FROM Customers.dbo.Company     WITH (nolock)  WHERE IDSeq = @IPVC_CompanyID
  SELECT @LVC_PropertyName    = [Name],@LI_PRPSeparateInvoiceByFamilyFlag = SeparateInvoiceByFamilyFlag FROM Customers.dbo.[Property]  WITH (nolock)  WHERE IDSeq = @IPVC_PropertyID
  SELECT @LVC_AccountTypeCode = AccountTypeCode,
         @LI_CMPFlag          = (CASE  AccountTypeCode
                                   WHEN 'AHOFF' THEN 1
                                   ELSE 0
                                 END)
  FROM Customers.dbo.Account WITH (nolock)  WHERE IDSeq = @IPVC_AccountID
  --------------------------------------------------------------
  --Finalize Logic to @LI_SeparateInvoiceByFamilyFlag
  IF (
       (@LI_CMPSeparateInvoiceByFamilyFlag & @LI_PRPSeparateInvoiceByFamilyFlag = 1)
         OR
       (@LI_CMPFlag & @LI_CMPSeparateInvoiceByFamilyFlag = 1)
         OR
       (~@LI_CMPFlag & @LI_PRPSeparateInvoiceByFamilyFlag = 1)
     )
  begin
    SET @LI_SeparateInvoiceByFamilyFlag = 1
  end
  ---------------------------------------------------------------------------------------------------------------------
  if (@LI_SeparateInvoiceByFamilyFlag = 0)
  begin
    INSERT INTO #TEMPAddrType_InvGroupNumber(OrderItemIDSeq,
                                             OrderGroupIDSeq,
                                             CBEnabledFlag, 
                                             BillToAddressTypeCode,
                                             BillToDeliveryOptionCode, 
                                             SeparateInvoiceGroupNumber,
                                             MarkAsPrintedFlag,
                                             SeparateInvoiceProductFamilyCode,
                                             EpicorPostingCode,
                                             TaxwareCompanyCode,
                                             PrePaidFlag
                                             )
    SELECT          OI.IDSeq,
                    OI.OrderGroupIDSeq  as OrderGroupIDSeq,
                    Max(Convert(int,OG.CustomBundleNameEnabledFlag)) as CBEnabledFlag,
                    OI.BillToAddressTypeCode,
                    OI.BillToDeliveryOptionCode,
                    C.SeparateInvoiceGroupNumber,
                    CONVERT(INT,C.MarkAsPrintedFlag),
                    NULL       as SeparateInvoiceProductFamilyCode,
                    FAM.EpicorPostingCode,
                    FAM.TaxwareCompanyCode,
                    PRD.PrePaidFlag 
    FROM            Orders.dbo.OrderItem OI     WITH (nolock)
    Inner Join
                    Orders.dbo.[OrderGroup] OG  with (nolock)
    on              OI.OrderIDSeq      = OG.OrderIDSeq
    and             OI.OrderGroupIDSeq = OG.IDSeq
    and             OI.OrderIDSeq      = @LBI_OrderID
    and             OG.OrderIDSeq      = @LBI_OrderID
    Inner Join
                    Products.dbo.Family  FAM    with (nolock)
    on              OI.OrderIDSeq      = @LBI_OrderID
    and             OI.FamilyCode      = FAM.Code
    AND             OI.MeasureCode    = 'TRAN'
    Inner Join
                    Products.dbo.Product PRD      WITH (nolock)
    on              OI.OrderIDSeq     = @LBI_OrderID
    AND             OI.ProductCode    = PRD.Code
    AND             OI.PriceVersion   = PRD.PriceVersion
    INNER JOIN
                    Orders.dbo.OrderItemTransaction OIT WITH (nolock)
    ON  OI.IDSeq           = OIT.OrderItemIDSeq
    AND OI.OrderIDSeq      = OIT.OrderIDSeq 
    AND OI.OrderGroupIDSeq = OIT.OrderGroupIDSeq  
    AND OIT.OrderIDSeq     = @LBI_OrderID     
    and OIT.TransactionalFlag = 1
    and OIT.InvoicedFlag      = 0 
    ---and OIT.ServiceDate       <= @LDT_TargetDate
    INNER JOIN      
           Products.dbo.Charge C       WITH (nolock)
    ON  OI.OrderIDSeq     = @LBI_OrderID
    AND OI.ProductCode    = C.ProductCode
    AND OI.PriceVersion   = C.PriceVersion
    AND OI.ChargeTypeCode = C.ChargeTypeCode 
    AND OI.FrequencyCode  = C.FrequencyCode 
    AND OI.MeasureCode    = C.MeasureCode 
    AND OI.ProductCode    = PRD.Code
    AND OI.PriceVersion   = PRD.PriceVersion
    AND OI.MeasureCode    = 'TRAN'
    AND OI.BillToAddressTypeCode IS NOT NULL
    AND OI.DoNotInvoiceFlag=0
    Inner Join
          INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
    on      C.LeadDays           = BTM.LeadDays
    and     BTM.BillingCycleDate = @LDT_BillingCycleDate    
    and     OIT.ServiceDate      <= BTM.TargetDate  
    WHERE OIT.TransactionalFlag  = 1
    and   OIT.InvoicedFlag       = 0 
    and     OIT.ServiceDate      <= BTM.TargetDate  
    ---and   OIT.ServiceDate       <= @LDT_TargetDate
    GROUP BY OI.IDSeq,OI.OrderGroupIDSeq,OI.BillToAddressTypeCode,OI.BillToDeliveryOptionCode,C.SeparateInvoiceGroupNumber,CONVERT(INT,C.MarkAsPrintedFlag),FAM.EpicorPostingCode,FAM.TaxwareCompanyCode,PRD.PrePaidFlag 
    ORDER BY OI.IDSeq,OI.OrderGroupIDSeq,OI.BillToAddressTypeCode,OI.BillToDeliveryOptionCode,C.SeparateInvoiceGroupNumber,CONVERT(INT,C.MarkAsPrintedFlag),FAM.EpicorPostingCode,FAM.TaxwareCompanyCode,PRD.PrePaidFlag 
  end
  else if (@LI_SeparateInvoiceByFamilyFlag = 1)
  begin
    INSERT INTO #TEMPAddrType_InvGroupNumber 
                          (
                           OrderItemIDSeq,
                           OrderGroupIDSeq,
                           CBEnabledFlag, 
                           BillToAddressTypeCode,
                           BillToDeliveryOptionCode,
                           SeparateInvoiceGroupNumber,
                           MarkAsPrintedFlag,
                           SeparateInvoiceProductFamilyCode,
                           EpicorPostingCode,
                           TaxwareCompanyCode,
                           PrePaidFlag
                          ) 
     SELECT         OI.IDSeq,
                    OI.OrderGroupIDSeq  as OrderGroupIDSeq,
                    Max(Convert(int,OG.CustomBundleNameEnabledFlag)) as CBEnabledFlag, 
                    OI.BillToAddressTypeCode,
                    OI.BillToDeliveryOptionCode,
                    C.SeparateInvoiceGroupNumber,
                    CONVERT(INT,C.MarkAsPrintedFlag),
                    (Case when Max(Convert(int,OG.CustomBundleNameEnabledFlag)) = 1 then NULL
                          else Max(OI.FamilyCode)
                     end)       as SeparateInvoiceProductFamilyCode,
                    FAM.EpicorPostingCode,
                    FAM.TaxwareCompanyCode,
                    PRD.PrePaidFlag
    FROM            Orders.dbo.OrderItem OI     WITH (nolock)
    Inner Join
                    Products.dbo.Family  FAM    with (nolock)
    on              OI.OrderIDSeq      = @LBI_OrderID
    and             OI.FamilyCode      = FAM.Code
    AND             OI.MeasureCode    = 'TRAN' 
    Inner Join
                    Products.dbo.Product PRD      WITH (nolock)
    on              OI.OrderIDSeq     = @LBI_OrderID
    AND             OI.ProductCode    = PRD.Code
    AND             OI.PriceVersion   = PRD.PriceVersion
    Inner Join
                    Orders.dbo.[OrderGroup] OG with (nolock)
    on              OI.OrderIDSeq      = OG.OrderIDSeq
    and             OI.OrderGroupIDSeq = OG.IDSeq
    and             OI.OrderIDSeq      = @LBI_OrderID
    and             OG.OrderIDSeq      = @LBI_OrderID
    INNER JOIN
                    Orders.dbo.OrderItemTransaction OIT WITH (nolock)
    ON  OI.IDSeq           = OIT.OrderItemIDSeq
    AND OI.OrderIDSeq      = OIT.OrderIDSeq 
    AND OI.OrderGroupIDSeq = OIT.OrderGroupIDSeq  
    AND OIT.OrderIDSeq     = @LBI_OrderID     
    and OIT.TransactionalFlag = 1
    and OIT.InvoicedFlag      = 0 
    ---and OIT.ServiceDate       <= @LDT_TargetDate
    INNER JOIN      
           Products.dbo.Charge C       WITH (nolock)
    ON  OI.OrderIDSeq     = @LBI_OrderID
    AND OI.ProductCode    = C.ProductCode
    AND OI.PriceVersion   = C.PriceVersion
    AND OI.ChargeTypeCode = C.ChargeTypeCode 
    AND OI.FrequencyCode  = C.FrequencyCode 
    AND OI.MeasureCode    = C.MeasureCode 
    AND OI.ProductCode    = PRD.Code
    AND OI.PriceVersion   = PRD.PriceVersion
    AND OI.MeasureCode    = 'TRAN'
    AND OI.BillToAddressTypeCode IS NOT NULL
    AND OI.DoNotInvoiceFlag=0
    Inner Join
          INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
    on    C.LeadDays           = BTM.LeadDays
    and   BTM.BillingCycleDate = @LDT_BillingCycleDate    
    and   OIT.ServiceDate      <= BTM.TargetDate  
    WHERE OIT.TransactionalFlag = 1
    and   OIT.InvoicedFlag      = 0 
    and   OIT.ServiceDate      <= BTM.TargetDate  
    ---and   OIT.ServiceDate       <= @LDT_TargetDate
    GROUP BY OI.IDSeq,OI.OrderGroupIDSeq,OI.BillToAddressTypeCode,OI.BillToDeliveryOptionCode,C.SeparateInvoiceGroupNumber,CONVERT(INT,C.MarkAsPrintedFlag),
             OG.IDSeq,FAM.EpicorPostingCode,FAM.TaxwareCompanyCode,PRD.PrePaidFlag
    ORDER BY OI.IDSeq,OI.OrderGroupIDSeq,OI.BillToAddressTypeCode,OI.BillToDeliveryOptionCode,C.SeparateInvoiceGroupNumber,CONVERT(INT,C.MarkAsPrintedFlag),FAM.EpicorPostingCode,FAM.TaxwareCompanyCode,PRD.PrePaidFlag
  end
  -------------------------------------------------------------------------------------------------
  -- Now Starting the loop to Insert the data into all temp tables
  -------------------------------------------------------------------------------------------------
  SELECT @LI_MinValue = 1
  SELECT @LI_MaxValue = count(SEQ) FROM #TEMPAddrType_InvGroupNumber WITH (nolock)

  WHILE  @LI_MinValue <= @LI_MaxValue --Parent while loop Start
    BEGIN --> BEGIN for while loop - AddressType and InvoiceGroupNumber
      ---------------------------------------------------------------------------------------------------------------------
      -- Retrieving 1st row OrderItemIDSeq,BillToAddressTypeCode,SeparateInvoiceGroupNumber values from #TEMPAddrType_InvGroupNumber table
      ---------------------------------------------------------------------------------------------------------------------
      SELECT @LVBI_OrderItemIDSeq             = OrderItemIDSeq,
             @LBI_GroupID                     = OrderGroupIDSeq,
             @LI_CBEnabledFlag                = CBEnabledFlag, 
             @LVC_BillToAddressTypeCode       = BillToAddressTypeCode,
             @LVC_BillToDeliveryOptionCode    = BillToDeliveryOptionCode,
             @LVBI_SeparateInvoiceGroupNumber = SeparateInvoiceGroupNumber,
             @LVB_MarkAsPrintedFlag           = MarkAsPrintedFlag,
             @LVC_SeparateInvoiceProductFamilyCode   = SeparateInvoiceProductFamilyCode,
             @LVC_EpicorPostingCode                  = EpicorPostingCode,
             @LVC_TaxwareCompanyCode                 = TaxwareCompanyCode,
             @LI_PrePaidFlag                         = PrePaidFlag
      FROM   #TEMPAddrType_InvGroupNumber WITH (nolock)
      WHERE  SEQ = @LI_MinValue  
  -------------------------------------------------------------------------------------------------
  -- Now populate #TempOrderItems table - 
  -------------------------------------------------------------------------------------------------
     IF @LI_TransactionLineItemCount <> 0 
      BEGIN 
       INSERT INTO #TEMPOrderItem 
				    (
		      [OrderItemIDSeq],
                      [OrderIDSeq],
                      [OrderGroupIDSeq],
                      [ProductCode],
                      [ChargeTypeCode],
                      [FrequencyCode],
                      [MeasureCode],
                      [FamilyCode],
                      [PriceVersion],
                      [Quantity],
                      [ChargeAmount],
                      [EffectiveQuantity],
                      [ExtChargeAmount],
                      [DiscountPercent],
                      [DiscountAmount],
                      [NetChargeAmount],
                      [ILFStartDate], 
                      [ILFEndDate],
                      [ActivationStartDate],
                      [ActivationEndDate],
                      [StatusCode],
                      [StartDate],
                      [EndDate],
                      [LastBillingPeriodFromDate],
                      [LastBillingPeriodToDate],
                      BillToAddressTypeCode,
                      BillToDeliveryOptionCode,
                      [CancelDate],
                      [CapMaxUnitsFlag],
                      [NewActivationStartDate],
                      [NewActivationEndDate],
                      [AccountIDSeq],
                      [QuoteIDSeq],
                      [NewILFStartDate],
                      [NewILFEndDate],
                      [OrderstatusCode],
                      [RevenueTierCode],
                      [RevenueAccountCode],
                      [DeferredRevenueAccountCode],
                      [RevenueRecognitionCode],
                      [TaxwareCode],
                      [DefaultTaxwareCode],
                      [ShippingAndHandlingAmount],
                      [SeparateInvoiceGroupNumber],
                      [UnitOfMeasure],
                      [ReportingTypeCode],
                      [PricingTiers],
                      OrderItemTransactionIDseq, 
                      TransactionItemName,
                      ServiceCode,
                      TransactionDate,
		      Units,Beds,PPUPercentage,
                      TargetDate
		     )


      select OI.[IDSeq]
			,OIT.[OrderIDSeq]
			,OIT.[OrderGroupIDSeq] 
			,OIT.[ProductCode]
			,OI.[ChargeTypeCode] --'TRX' as ChargeTypeCode --OI.[ChargeTypeCode]
			,OI.[FrequencyCode]
			,OI.[MeasureCode]
			,OI.[FamilyCode]
			,OI.[PriceVersion] 
			,OIT.[Quantity] 
			,convert(numeric(30,5),OIT.[ExtChargeAmount]) as Chargeamount-- No charge amount in the trans table
			,OIT.[Quantity]         as Quantity-- No [Effective Quantity] in the trans table
			,convert(numeric(30,2),(OIT.[ExtChargeAmount]* OIT.[Quantity])) as  ExtChargeAmount
			,(convert(float,(convert(numeric(30,2),(OIT.[ExtChargeAmount]* OIT.[Quantity])) - convert(numeric(30,2),OIT.[NetChargeAmount]))
                                 ) * 100
                          ) /
                            (case when (OIT.[ExtChargeAmount]* OIT.[Quantity])>0 then (OIT.[ExtChargeAmount]* OIT.[Quantity])
                                     else 1
                              end)  as DiscountPercent
			,(convert(numeric(30,2),(OIT.[ExtChargeAmount]* OIT.[Quantity])) - convert(numeric(30,2),OIT.[NetChargeAmount])) as DiscountAmount
			,convert(numeric(30,2),OIT.[NetChargeAmount]) as  NetChargeAmount
			,null as ILFStartDate 
			,null as ILFEndDate
			,null as ActivationStartDate
			,null as ActivationEndDate
			,'FULF' as StatusCode
			,OIT.[ServiceDate] as StartDate
			,OIT.[ServiceDate] as EndDate
			,Invoices.DBO.fn_SetFirstDayOfMonth([ServiceDate]) as LastBillingPeriodFromDate --[LastBillingPeriodFromDate]--change to 1st  day of month
			,Invoices.DBO.fn_SetLastDayOfMonth([ServiceDate])  as LastBillingPeriodToDate   --[LastBillingPeriodToDate]  --change to last day of month
                        ,OI.BillToAddressTypeCode
                        ,OI.BillToDeliveryOptionCode
			,null as CancelDate
			,OI.[CapMaxUnitsFlag]  as CapMaxUnitsFlag
			,NULL as NewActivationStartDate 
			,NULL as NewActivationEndDate
			,O.[AccountIDSeq]
			,O.[QuoteIDSeq]
			,Invoices.DBO.fn_SetFirstDayOfMonth([ServiceDate])  as [NewILFStartDate]
			,Invoices.DBO.fn_SetLastDayOfMonth([ServiceDate])   as [NewILFEndDate]
			,O.StatusCode as [OrderStatusCode]
			,C.RevenueTierCode
			,C.RevenueAccountCode
			,C.DeferredRevenueAccountCode
			,C.RevenueRecognitionCode
			,C.TaxwareCode
                        ,C.[TaxwareCode] as DefaultTaxwareCode
			,OI.[ShippingAndHandlingAmount]
                        ,C.[SeparateInvoiceGroupNumber]
                        ,OI.[UnitOfMeasure]
                        ,OI.[ReportingTypeCode]
                        ,OI.[PricingTiers]
			,OIT.IDseq 
			,(Case when (OIT.SourceTransactionID is null or OIT.SourceTransactionID = '') then ''
                               when P.familycode = 'LSD' then 'AppID ' + convert(varchar(100),OIT.SourceTransactionID) + ':' 
                               else ''
                          end) + coalesce(OIT.TransactionItemName,'') 
			,OIT.ServiceCode 
			,OIT.ServiceDate
                        ,OI.Units,OI.Beds,OI.PPUPercentage
                        ,BTM.TargetDate
          from       Orders.dbo.OrderItem OI WITH (nolock)
          INNER JOIN 
                     Orders.dbo.[Order] O WITH (nolock)
              ON     OI.OrderIDSeq            = O.OrderIDSeq 
              AND    OI.OrderIDSeq            = @LBI_OrderID 
              AND    OI.IDSeq                 = @LVBI_OrderItemIDSeq
              AND    OI.BillToAddressTypeCode = @LVC_BillToAddressTypeCode
              AND    OI.BillToDeliveryOptionCode= @LVC_BillToDeliveryOptionCode
              AND    OI.FamilyCode            = coalesce(@LVC_SeparateInvoiceProductFamilyCode,OI.FamilyCode)
              AND    OI.DoNotInvoiceFlag      = 0              
          INNER JOIN 
                     Products.dbo.Product P WITH (nolock)
              ON     OI.ProductCode  = P.code 
              AND    OI.PriceVersion = P.PriceVersion
              AND    P.PrePaidFlag   = @LI_PrePaidFlag
          INNER JOIN
                     Products.dbo.Family FAM with (nolock)
          on         OI.FamilyCode  = FAM.Code
          and        P.FamilyCode   = FAM.Code
          and        OI.OrderIDSeq  = @LBI_OrderID 
          and        OI.IDSeq       = @LVBI_OrderItemIDSeq
          and        FAM.EpicorPostingCode  = @LVC_EpicorPostingCode
          and        FAM.TaxwareCompanyCode = @LVC_TaxwareCompanyCode             
          INNER JOIN 
                     Products.dbo.Charge C WITH (nolock)
              ON     OI.ProductCode    = C.ProductCode
              AND    OI.PriceVersion   = C.PriceVersion
              AND    P.code            = C.ProductCode
              AND    P.PriceVersion    = C.PriceVersion
              AND    OI.ChargeTypeCode = C.ChargeTypeCode 
              AND    OI.FrequencyCode  = C.FrequencyCode 
              AND    OI.MeasureCode    = C.MeasureCode
              AND    OI.MeasureCode    = 'TRAN'            
              AND    C.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
          INNER JOIN Orders.dbo.OrderItemTransaction OIT WITH (nolock)
              ON     OI.idseq              = OIT.orderItemidseq
              AND    OI.IDSeq              = @LVBI_OrderItemIDSeq 
              AND    OIT.orderItemidseq    = @LVBI_OrderItemIDSeq
              AND    OIT.OrderIDSeq        = OI.OrderIDSeq
              AND    OIT.Ordergroupidseq   = OI.Ordergroupidseq
              AND    OIT.OrderIDSeq        = @LBI_OrderID
              and    OIT.TransactionalFlag = 1
              and    OIT.InvoicedFlag      = 0 
          Inner Join
                     INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
             on      C.LeadDays           = BTM.LeadDays
             and     BTM.BillingCycleDate = @LDT_BillingCycleDate    
             and     OIT.ServiceDate      <= BTM.TargetDate     
              ---and    OIT.ServiceDate       <= @LDT_TargetDate
          WHERE      OI.OrderIDSeq         = @LBI_OrderID 
              AND    OI.IDSeq              = @LVBI_OrderItemIDSeq
              AND    OI.BillToAddressTypeCode     = @LVC_BillToAddressTypeCode
              AND    OI.BillToDeliveryOptionCode  = @LVC_BillToDeliveryOptionCode
              AND    OI.FamilyCode                = coalesce(@LVC_SeparateInvoiceProductFamilyCode,OI.FamilyCode)
              AND    C.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
              and    FAM.EpicorPostingCode  = @LVC_EpicorPostingCode
              and    FAM.TaxwareCompanyCode = @LVC_TaxwareCompanyCode 
              and    P.PrePaidFlag          = @LI_PrePaidFlag
              AND    OI.MeasureCode    = 'TRAN'
              AND    OI.DoNotInvoiceFlag   = 0    
              and    OIT.TransactionalFlag = 1
              and    OIT.InvoicedFlag      = 0               
           ORDER BY OIT.ServiceDate ASC ---> This is important for Epicor Push.                    
  end 
  -------------------------------------------------------------------------------------------------
  ---Step 1 : Create Invoice if there are items to process, else quit.
  ---         Get Latest InvoiceID with Printflag=0 if one exist for the @IPVC_AccountID
  ---         Else Generate New InvoiceID for the @IPVC_AccountID
  -------------------------------------------------------------------------------------------------
  if (@LI_TransactionLineItemCount = 0) 
    begin 
      SELECT 0 as SQLErrorcode, 'ABCDEFGHIJK' as InvoiceID --> Dummy Returned to UI 
      return --nothing to process, please quit stored procedure.
    end
  else 
    BEGIN -- Create InvoiceIDSeq - Start 
	  IF Exists (SELECT top 1 1 
                          from   Invoices.dbo.Invoice I WITH (nolock)
                          Inner Join
                                 Invoices.dbo.InvoiceItem II with (nolock)
                          on     II.InvoiceIDSeq              = I.InvoiceIDSeq
                          and    II.BillToAddressTypeCode     = I.BillToAddressTypeCode
                          and    II.BillToDeliveryOptionCode  = I.BillToDeliveryOptionCode 
                          and    I.BillingCycleDate           = @LDT_BillingCycleDate
                          and    I.PrintFlag                  = 0 
                          and    I.XMLProcessingStatus        = 0
		          and    I.accountIDSeq               = @IPVC_AccountID
                          and    I.BillToAddressTypeCode      = @LVC_BillToAddressTypeCode
                          and    I.BillToDeliveryOptionCode   = @LVC_BillToDeliveryOptionCode
                          and    I.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
                          and    I.MarkAsPrintedFlag          = @LVB_MarkAsPrintedFlag
                          and    I.EpicorPostingCode          = @LVC_EpicorPostingCode
                          and    I.TaxwareCompanyCode         = @LVC_TaxwareCompanyCode
                          and    I.PrePaidFlag                = @LI_PrePaidFlag
                          and    I.ValidFlag                  = 1 
                          Inner Join
                                 Products.dbo.Product P with (nolock)
                          on     II.ProductCode = P.Code
                          and    II.PriceVersion= P.PriceVersion
                          and    ((P.FamilyCode   = coalesce(@LVC_SeparateInvoiceProductFamilyCode,P.FamilyCode))
                                     OR
                                  (II.OrderGroupIDSeq = @LBI_GroupID and @LI_CBEnabledFlag = 1)
                                 )                         
                          and    (
                                  (@LI_PrePaidFlag = 1 and II.OrderIDSeq = @LBI_OrderID and I.PrePaidFlag = P.PrePaidFlag  and  P.PrePaidFlag = 1 and I.PrePaidFlag=1)
                                         OR
                                  (@LI_PrePaidFlag = 0 and I.PrePaidFlag = 0)
                                 )
		          WHERE  I.BillingCycleDate           = @LDT_BillingCycleDate
                          and    I.PrintFlag                  = 0 
                          and    I.XMLProcessingStatus        = 0
		          and    I.accountIDSeq               = @IPVC_AccountID
                          and    I.BillToAddressTypeCode      = @LVC_BillToAddressTypeCode
                          and    I.BillToDeliveryOptionCode   = @LVC_BillToDeliveryOptionCode
                          and    I.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
                          and    I.MarkAsPrintedFlag          = @LVB_MarkAsPrintedFlag
                          and    I.EpicorPostingCode          = @LVC_EpicorPostingCode
                          and    I.TaxwareCompanyCode         = @LVC_TaxwareCompanyCode
                          and    I.PrePaidFlag                = @LI_PrePaidFlag
                          and    I.ValidFlag                  = 1 
                          and    ((P.FamilyCode   = coalesce(@LVC_SeparateInvoiceProductFamilyCode,P.FamilyCode))
                                     OR
                                  (II.OrderGroupIDSeq = @LBI_GroupID and @LI_CBEnabledFlag = 1)
                                 )                         
                          and    (
                                  (@LI_PrePaidFlag = 1 and II.OrderIDSeq = @LBI_OrderID and I.PrePaidFlag = P.PrePaidFlag  and  P.PrePaidFlag = 1 and I.PrePaidFlag=1)
                                         OR
                                  (@LI_PrePaidFlag = 0 and I.PrePaidFlag = 0)
                                 )
                       )
	          BEGIN
	             SELECT @LVC_InvoiceID   = Min(I.InvoiceIDSeq)
	             from   Invoices.dbo.Invoice I WITH (nolock)
                     Inner Join
                            Invoices.dbo.InvoiceItem II with (nolock)
                     on     II.InvoiceIDSeq              = I.InvoiceIDSeq
                     and    II.BillToAddressTypeCode     = I.BillToAddressTypeCode
                     and    II.BillToDeliveryOptionCode  = I.BillToDeliveryOptionCode 
                     and    I.BillingCycleDate           = @LDT_BillingCycleDate
                     and    I.PrintFlag                  = 0 
                     and    I.XMLProcessingStatus        = 0
		     and    I.accountIDSeq               = @IPVC_AccountID
                     and    I.BillToAddressTypeCode      = @LVC_BillToAddressTypeCode
                     and    I.BillToDeliveryOptionCode   = @LVC_BillToDeliveryOptionCode
                     and    I.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
                     and    I.MarkAsPrintedFlag          = @LVB_MarkAsPrintedFlag
                     and    I.EpicorPostingCode          = @LVC_EpicorPostingCode
                     and    I.TaxwareCompanyCode         = @LVC_TaxwareCompanyCode
                     and    I.PrePaidFlag                = @LI_PrePaidFlag
                     and    I.ValidFlag                  = 1 
                     Inner Join
                            Products.dbo.Product P with (nolock)
                     on     II.ProductCode = P.Code
                     and    II.PriceVersion= P.PriceVersion
                     and    ((P.FamilyCode   = coalesce(@LVC_SeparateInvoiceProductFamilyCode,P.FamilyCode))
                                   OR
                             (II.OrderGroupIDSeq = @LBI_GroupID and @LI_CBEnabledFlag = 1)
                            )                         
                     and    (
                             (@LI_PrePaidFlag = 1 and II.OrderIDSeq = @LBI_OrderID and I.PrePaidFlag = P.PrePaidFlag  and  P.PrePaidFlag = 1 and I.PrePaidFlag=1)
                                      OR
                             (@LI_PrePaidFlag = 0 and I.PrePaidFlag = 0)
                            )
		     WHERE  I.BillingCycleDate           = @LDT_BillingCycleDate
                     and    I.PrintFlag                  = 0 
                     and    I.XMLProcessingStatus        = 0
		     and    I.accountIDSeq               = @IPVC_AccountID
                     and    I.BillToAddressTypeCode      = @LVC_BillToAddressTypeCode
                     and    I.BillToDeliveryOptionCode   = @LVC_BillToDeliveryOptionCode
                     and    I.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
                     and    I.MarkAsPrintedFlag          = @LVB_MarkAsPrintedFlag
                     and    I.EpicorPostingCode          = @LVC_EpicorPostingCode
                     and    I.TaxwareCompanyCode         = @LVC_TaxwareCompanyCode
                     and    I.PrePaidFlag                = @LI_PrePaidFlag
                     and    I.ValidFlag                  = 1 
                     and    ((P.FamilyCode   = coalesce(@LVC_SeparateInvoiceProductFamilyCode,P.FamilyCode))
                                  OR
                             (II.OrderGroupIDSeq = @LBI_GroupID and @LI_CBEnabledFlag = 1)
                            )                         
                     and    (
                             (@LI_PrePaidFlag = 1 and II.OrderIDSeq = @LBI_OrderID and I.PrePaidFlag = P.PrePaidFlag  and  P.PrePaidFlag = 1 and I.PrePaidFlag=1)
                                      OR
                             (@LI_PrePaidFlag = 0 and I.PrePaidFlag = 0)
                            )
	    end
	    else
	    begin
	      ----------------------------------------
	      --- Create a new Invoice id
	      ----------------------------------------
              begin TRY
                BEGIN TRANSACTION CTI; 
      	          UPDATE Invoices.DBO.IDGenerator WITH (TABLOCKX,XLOCK,HOLDLOCK)
	          SET    IDSeq = IDSeq+1,
	                 GeneratedDate =CURRENT_TIMESTAMP
                  WHERE  TypeIndicator = 'I'      
	
	          SELECT @LVC_InvoiceID = IDGeneratorSeq
	          FROM   Invoices.DBO.IDGenerator WITH (NOLOCK)
                  WHERE  TypeIndicator  = 'I'
                COMMIT TRANSACTION CTI;
              end TRY
              begin CATCH    
                if (XACT_STATE()) = -1
                begin
                  IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION CTI;
                end
                else 
                if (XACT_STATE()) = 1
                begin
                  IF @@TRANCOUNT > 0 COMMIT TRANSACTION CTI;
                end  
                IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION CTI;

                SELECT 0 as SQLErrorcode, 'ABCDEFGHIJK' as InvoiceID --> Dummy Returned to UI
                Return; -- There IS nothing to process.
              end CATCH;
	    end
            -------------------------------------------------
            INSERT INTO #temp_InvoiceIDHoldingTable (SQLErrorcode,InvoiceID)
            select @SQLErrorCode as SQLErrorcode,@LVC_InvoiceID as InvoiceID
            -------------------------------------------------
          -- error handling -- when Select/InvoiceID generation fails-- 
          select @SQLErrorCode = @@error	
          if @SQLErrorCode <> 0 
            begin 
               select @SQLErrorCode as SQLErrorCode, @LVC_InvoiceID as InvoiceIDSeq
               exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'New InvoiceID Gen: New InvoiceID Generation failed for uspINVOICES_CreateInvoice'  
            return
          end
    END -- Create InvoiceIDSeq - end  
 -------------------------------------------------------------------------------------------------
 ---Step 2 : Load all temp tables - 
 -------------------------------------------------------------------------------------------------
if (@LI_TransactionLineItemCount <> 0) 
  BEGIN -- process ILF, ACS, TRX 
	 --------------------------------------------------------
	 ---Company  (Insert data into #TEMPCompany) - Start
	 --------------------------------------------------------
	      INSERT INTO #TEMPCompany 
                    ( IDSeq,
	              [Name],
	              PMCFlag,
	              PriceTerm,
                      SendInvoiceToClientFlag
	            )
	      SELECT    C.IDSeq  as CompanyID,
	                C.[Name] as Name,
	                C.PMCFlag,
	                C.PriceTerm,
                        Convert(int,C.SendInvoiceToClientFlag) as SendInvoiceToClientFlag 
	      FROM      CUSTOMERS.dbo.COMPANY  C WITH (nolock)
	      WHERE     C.IDSeq   = @IPVC_CompanyID
	     

	  select @SQLErrorCode = @@error, @SQLRowCount = @@rowcount
	   if @SQLErrorCode <> 0
	     begin 
            select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	        exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while inserting data into #TEMPCompany table' 
	        return -- quit procedure! 
	     end 
	
	   -- error handling --
	   if @SQLRowCount = 0 
	     begin
            select  0 as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
 	        exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Company was not found in customers.dbo.company table for AccountIDSeq.' 
	        return -- quit procedure! 
	     end 
	 --------------------------------------------------------
	 ---Company  (Insert data into #TEMPCompany) - End
	 --------------------------------------------------------
	 --------------------------------------------------------
	 -- Account (Insert data into #TEMPAccount table) -Start
	 --------------------------------------------------------
	  if (select top 1 AccountTypeCode from CUSTOMERS.DBO.Account A with (nolock) where  A.IDseq = @IPVC_AccountID) = 'AHOFF'
		  begin
			select Top 1 @LI_PriceTerms= priceterm from #TEMPCompany with (nolock)
		  end
	          else
		  begin
			select Top 1 @LI_PriceTerms= priceterm from #TEMPProperty with (nolock)
		  end
	
	   -- Insertion into #TEMPAccount Begins
	      INSERT 
          INTO #TEMPAccount
                           (
                            IDSeq,
                            AccountTypeCode,
                            CompanyIDSeq,
                            PropertyIDSeq,
                            EpicorCustomerCode,
                            PriceTerm
                           )
	      SELECT  A.IDSeq,
                  A.AccountTypeCode,
                  A.CompanyIDSeq,
                  A.PropertyIDSeq,
                  ISNULL(A.EpicorCustomerCode,0),
                  @LI_PriceTerms
	      FROM    CUSTOMERS.DBO.Account A WITH (nolock)
	      WHERE   A.IDSeq = @IPVC_AccountID 
           -- Insertion into #TEMPAccount Ends

	  select @SQLErrorCode = @@error, @SQLRowCount = @@rowcount

	  if @SQLErrorCode <> 0 
	    begin 
           select @SQLErrorCode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
 	       exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while trying to insert account data into #TEMPAccount table.' 
	       return -- quit procedure! 
	    end 
	
	  -- error handling -- 
	  if @SQLRowCount = 0 
	    begin 
           select 0 as SQLErrorcode
                ,@LVC_InvoiceID as InvoiceID  
 	       exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Account was not found in customers.dbo.account table for AccountIDSeq.' 
	       return -- quit procedure! 
	    end  
	 
	  select @LVC_EpicorCustomerCode = EpicorCustomerCode
	         ,@LVC_AccountTypeCode = AccountTypeCode 
	  from #TEMPAccount (nolock)

	  select @SQLErrorCode = @@error

	  if @SQLErrorCode <> 0 
	    begin 
           select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	       exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while trying to set @LVC_EpicorCustomerCode and @LVC_AccountTypeCode variables from #TEMPAccount table.' 
	       return -- quit procedure! 
	    end 
	
	  -- error handling -- 
	  if @LVC_AccountTypeCode is null 
	    begin 
           select 0 as SQLErrorcode, @LVC_InvoiceID as InvoiceID
 	       exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'AccountTypeCode is not found for accountidseq' 
	       return -- quit procedure! 
	    end 
	 --------------------------------------------------------
	 -- Account (Insert data into #TEMPAccount table) - End
	 --------------------------------------------------------
	 --------------------------------------------------------
	 ---Property  (Insert data into #TEMPProperty) - Start
	 --------------------------------------------------------
	  INSERT 
          INTO #TEMPProperty
                   (
                    IDSeq,
                    Name,
	            PMCIDSeq,
                    OwnerIDSeq,
                    Units,
                    Beds,
                    PPUPercentage,
                    PriceTerm,
                    SendInvoiceToClientFlag
                    )
	      SELECT  
                    P.IDSeq,
                    P.Name,
	            P.PMCIDSeq,
                    P.OwnerIDSeq,
                    P.Units,
                    P.Beds,
                    P.PPUPercentage,
                    P.PriceTerm,
                    convert(int,P.SendInvoiceToClientFlag) as SendInvoiceToClientFlag
	      FROM      CUSTOMERS.dbo.PROPERTY  P WITH (nolock)
	      INNER JOIN 
                    #TEMPAccount A            WITH (nolock)
		    ON  P.IDSeq = A.propertyIDSeq
          WHERE A.IDSeq = @IPVC_AccountID

	  select @SQLErrorCode = @@error

	  if @SQLErrorCode <> 0 
	    begin 
           select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	       exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while trying to locate a property for AccountIDSeq' 
	       return -- quit procedure! 
	    end 
	 --------------------------------------------------------
	 ---Property  (Insert data into #TEMPProperty) - End
	 --------------------------------------------------------
	 --------------------------------------------------------
	 ---Accounts Billing Address - Start 
	 -- Insert into #TEMPAddress table
	 --(account could be a company or a property)
	 --------------------------------------------------------
	 -- if account type is a property then load property's billing address. 
	 INSERT 
         INTO #TEMPAddress 
                               (
                                IDSeq,
	                            CompanyIDSeq,
	                            PropertyIDSeq,
	                            AccountName,
	                            AddressTypeCode,
	                            AddressLine1,
	                            AddressLine2,
	                            City,
	                            County,
	                            State,
	                            Zip,
	                            Country,
	                            SameAsPMCAddressFlag,
		                    CountryCode,
                                    Email
                               )
               SELECT   Top 1
                            AD.IDSeq,
	                    AD.CompanyIDSeq,
	                    AD.PropertyIDSeq,
	                    CASE WHEN AD.SameAsPMCAddressFlag = 1 
                                   THEN @LVC_CompanyName
                                 ELSE coalesce(@LVC_PropertyName,@LVC_CompanyName)
                            END     AS AccountName, 
	                    AD.AddressTypeCode,
	                    AD.AddressLine1,
	                    AD.AddressLine2,
	                    AD.City,
	                    AD.County,
	                    AD.State,
	                    AD.Zip,
	                    AD.Country,
	                    AD.SameAsPMCAddressFlag,
			    AD.CountryCode,
                            AD.Email
	       FROM     CUSTOMERS.DBO.ADDRESS AD WITH (nolock)
               WHERE    AD.CompanyIDSeq    = @IPVC_CompanyID
               AND      AD.AddressTypeCode = @LVC_BillToAddressTypeCode 
               and     (
                        (AD.AddressTypeCode = @LVC_BillToAddressTypeCode and 
                         AD.AddressTypeCode like 'PB%'                   and 
                         coalesce(AD.PropertyIDSeq,'') = @IPVC_PropertyID
                        )
                          OR
                       (AD.AddressTypeCode = @LVC_BillToAddressTypeCode and 
                        AD.AddressTypeCode NOT like 'PB%'  
                       )
                      )

	  select @SQLErrorCode = @@error, @SQLRowCount = @@rowcount

	  if @SQLErrorCode <> 0 
	    begin 
           select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
	       exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while trying to locate a billing address for AccountIDSeq' 
	       return -- quit procedure! 
	    end 
	
--	  if @SQLRowCount = 0 
--	    begin 
--           select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
-- 	       exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Billing addresses were not found for AccountIDSeq' 
--	       return -- quit procedure! 
--	    end 	
	 --------------------------------------------------------
	 ---Accounts Billing Address - End 
	 -- Insert into #TEMPAddress table
	 --(account could be a company or a property)
	 --------------------------------------------------------
	 --------------------------------------------------------
	 ---Accounts SHIPPING Address - Start 
	 -- Insert into #TEMPAddress table
	 --(account could be a company or a property)
	 --------------------------------------------------------
	 --- if account type is a property then load property's billing address. 
	 IF (@LVC_AccountTypeCode = 'APROP')
	        BEGIN 
	 	       INSERT 
               INTO #TEMPAddress 
                                ( 
                                 IDSeq,
	                             CompanyIDSeq,
	                             PropertyIDSeq,
	                             AccountName,
	                             AddressTypeCode,
	                             AddressLine1,
	                             AddressLine2,
	                             City,
	                             County,
	                             State,
	                             Zip,
	                             Country,
	                             SameAsPMCAddressFlag,
		                     CountryCode,
                                     Email
                                )
               SELECT  top 1 AD.IDSeq,
	                    AD.CompanyIDSeq,
	                    AD.PropertyIDSeq,
	                    CASE WHEN AD.SameAsPMCAddressFlag = 1 
                                THEN @LVC_CompanyName
                              ELSE coalesce(@LVC_PropertyName,@LVC_CompanyName)
                        END     AS AccountName, 
	                    AddressTypeCode,
	                    AD.AddressLine1,
	                    AD.AddressLine2,
	                    AD.City,
	                    AD.County,
	                    AD.State,
	                    AD.Zip,
	                    AD.Country,
	                    AD.SameAsPMCAddressFlag,
			    AD.CountryCode,
                            AD.Email
	           FROM     CUSTOMERS.DBO.ADDRESS AD WITH (nolock)
               WHERE    AD.PropertyIDSeq IS NOT NULL
                 AND    AD.CompanyIDSeq    = @IPVC_CompanyID
                 AND    AD.PropertyIDSeq   = @IPVC_PropertyID                 
                 AND    AD.AddressTypeCode = 'PST' 
	        END
	      ELSE --ELSE account type is company
	        BEGIN 
	           INSERT 
               INTO #TEMPAddress 
                               ( 
                                IDSeq,
	                            CompanyIDSeq,
	                            PropertyIDSeq,
	                            AccountName,
	                            AddressTypeCode,
	                            AddressLine1,
	                            AddressLine2,
	                            City,
	                            County,
	                            State,
	                            Zip,
	                            Country,
	                            SameAsPMCAddressFlag,
		                    CountryCode,
                                    Email
                               )
               SELECT  top 1 AD.IDSeq,
	                    AD.CompanyIDSeq,
	                    @IPVC_PropertyID as  PropertyIDSeq,
	                    @LVC_CompanyName as  AccountName,
	                    AddressTypeCode,
	                    AD.AddressLine1,
	                    AD.AddressLine2,
	                    AD.City,
	                    AD.County,
	                    AD.State,
	                    AD.Zip,
	                    AD.Country,
	                    AD.SameAsPMCAddressFlag,
			    AD.CountryCode,
                            AD.Email
	           FROM     CUSTOMERS.DBO.ADDRESS AD WITH (nolock)
               WHERE    AD.PropertyIDSeq IS NULL  
                 AND    AD.CompanyIDSeq    = @IPVC_CompanyID                 
                 AND    AD.AddressTypeCode = 'CST'    
	        END 

		  -- error handling -- 
		  select @SQLErrorCode = @@error, @SQLRowCount = @@rowcount
		  if @SQLErrorCode <> 0 
		    begin 
			  select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
		      exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while trying to locate a Shipping address for AccountIDSeq' 
		      return -- quit procedure! 
	        end 
	
--	  -- error handling -- 
--	  if @SQLRowCount = 0 
--	    begin 
--           select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
--	       exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Shipping Address not found.' 
--	       return -- quit procedure! 
--	    end
	 --------------------------------------------------------
	 ---Accounts SHIPPING Address - End 
	 -- Insert into #TEMPAddress table
	 --(account could be a company or a property)
	 --------------------------------------------------------
	 --------------------------------------------------------
	 -- Now insert data into Invoices.dbo.Invoices table 
	 --------------------------------------------------------
	 if not exists (select 1 from INVOICES.dbo.INVOICE with (nolock) where InvoiceIDSeq = @LVC_InvoiceID)
	   begin
	      INSERT 
              INTO  Invoices.dbo.Invoice 
                                        ( 
                                         InvoiceIDSeq,
	                                     CompanyName,
	                                     PropertyName,
	                                     AccountIDSeq,
	                                     CompanyIDSeq,
	                                     PropertyIDSeq,
	                                     ILFChargeAmount,
	                                     AccessChargeAmount,
	                                     TransactionChargeAmount,
	                                     TaxAmount,
	                                     CreditAmount,
	                                     ShippingAndHandlingAmount,
	                                     StatusCode,
	                                     InvoiceTerms,
	                                     InvoiceDate,
	                                     InvoiceDueDate,
	                                     OriginalPrintDate,
	                                     PrintFlag,
	                                     CreatedBy,
	                                     ModifiedBy,
	                                     CreatedDate,
	                                     ModifiedDate,
	                                     ApplyDate,
	                                     RePrintDate,
	                                     PrintCount,
	                                     EpicorBatchCode,
	                                     SentToEpicorFlag,
	                                     SentToEpicorStatus,
	                                     EpicorCustomerCode,
	                                     AccountTypeCode,
	                                     BillToAccountName,
	                                     ShipToAccountName,
	                                     Units,
	                                     Beds,
	                                     PPUPercentage,
	      	                             BillToAttentionName,
	                                     BillToAddressLine1,
	                                     BillToAddressLine2,
	                                     BillToCity,
	                                     BillToCounty,
	                                     BillToState,
	                                     BillToZip,
	                                     BillToCountry,
	                                     BillToPhoneVoice,
	                                     BillToPhoneVoiceExt,
	                                     BillToPhoneFax,
	                                     ShipToAddressLine1,
	                                     ShipToAddressLine2,
	                                     ShipToCity,
	                                     ShipToCounty,
	                                     ShipToState,
	                                     ShipToZip,
	                                     ShipToCountry,
		                             BillToCountryCode,
		                             ShipToCountryCode,
                                         BillToAddressTypeCode,
                                         SeparateInvoiceGroupNumber,
                                         MarkAsPrintedFlag,
                                         EpicorPostingCode,
                                         TaxwareCompanyCode,
                                         BillToEmailAddress,
                                         BillToDeliveryOptionCode,
                                         SendInvoiceToClientFlag,
                                         BillingCycleDate,
                                         PrePaidFlag
                                        )
	 select    
				@LVC_InvoiceID
				,S.Name
				,(SELECT top 1 Name FROM #TEMPProperty with (nolock)) as PropertyName
				,@IPVC_AccountID
				,@IPVC_CompanyID
				,@IPVC_PropertyID
				,0,0
				,0
				,0,0,0
				,@LVC_InvoiceStatusCode
				,@LI_InvoiceTerms
				,@LDT_InvoiceDate
				,(@LDT_InvoiceDate+@LI_InvoiceTerms)
				,NULL,0,'MIS Admin','MIS Admin',getdate(),getdate(),NULL,NULL
				,0,NULL,0,NULL
				,@LVC_EpicorCustomerCode,@LVC_AccountTypeCode
				,BA.AccountName
				,SA.AccountName
				,(case when @IPVC_PropertyID is not null 
                                          then (SELECT top 1 Units FROM #TEMPProperty with (nolock))
                                        else NULL
                                   end)              as Units
	                        ,(case when @IPVC_PropertyID is not null 
                                          then (SELECT top 1 Beds FROM #TEMPProperty with (nolock))
                                        else NULL
                                   end)              as Beds
                                 ,(case when @IPVC_PropertyID is not null 
                                          then (SELECT top 1 PPUPercentage FROM #TEMPProperty with (nolock))
                                        else NULL
                                   end)              as PPUPercentage
				,''
				,BA.AddressLine1
				,BA.AddressLine2
				,BA.City
				,''
				,BA.State
				,BA.Zip
				,BA.Country,''
				,'',''
				,SA.AddressLine1
				,SA.AddressLine2,SA.City,''
				,SA.State,SA.Zip,SA.Country
				,BA.CountryCode,SA.CountryCode
				,@LVC_BillToAddressTypeCode
				,@LVBI_SeparateInvoiceGroupNumber
				,@LVB_MarkAsPrintedFlag
                                ,@LVC_EpicorPostingCode
                                ,@LVC_TaxwareCompanyCode
                                ,BA.Email
                                ,@LVC_BillToDeliveryOptionCode     as DeliveryOptionCode,
                                (case when @IPVC_PropertyID is not null 
                                                  then (SELECT top 1 SendInvoiceToClientFlag FROM #TEMPProperty with (nolock))
                                                else S.SendInvoiceToClientFlag
                                end)  as SendInvoiceToClientFlag
                               ,@LDT_BillingCycleDate as BillingCycleDate
                               ,@LI_PrePaidFlag       as PrePaidFlag
	       FROM        #TEMPCompany S  WITH (nolock) 
		      INNER JOIN 
                          #TEMPAddress SA WITH (nolock) 
		         ON   S.IDSeq = SA.CompanyIDSeq
                 AND (SA.AddressTypeCode = 'CST' or SA.AddressTypeCode = 'PST')
		      INNER JOIN 
                          #TEMPAddress BA WITH (nolock) 
		         ON   S.IDSeq = BA.CompanyIDSeq
                 AND (BA.AddressTypeCode = @LVC_BillToAddressTypeCode)
	          WHERE  (BA.AddressTypeCode = @LVC_BillToAddressTypeCode)
	 	         AND 
		         (SA.AddressTypeCode = 'CST' or SA.AddressTypeCode = 'PST')
            END


	  -- error handling -- 
	  select @SQLErrorCode = @@error --, @SQLRowCount = @@rowcount (i cannot use row count because invoice may already exist in invoice table)

	  if @SQLErrorCode <> 0 
	    begin 
          select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	      exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, Insert into invoices.dbo.invoice table failed.' 
	      return -- quit procedure! 
	    end 
	  --------------------------------------------------------------------------------------
	  --- Populate #TEMPInvoiceGroup and #TEMPInvoiceGroupFinal tables - Start
	  --------------------------------------------------------------------------------------
	  INSERT 
          INTO #TEMPInvoiceGroup 
                                (
                                 InvoiceIDSeq,
	                             OrderIDSeq,
	                             OrderGroupIDSeq,
	                             Name,
	                             CustomBundleNameEnabledFlag
	                            )
	      SELECT DISTINCT 
                               @LVC_InvoiceID                 as InvoiceIDSeq,
	                           OG.OrderIDSeq                  as OrderIDSeq,
	                           OG.IDSeq                       as OrderGroupIDSeq,
	                           OG.[Name]                      as Name,
	                           OG.CustomBundleNameEnabledFlag as CustomBundleNameEnabledFlag
	      FROM        Orders.DBO.[ordergroup] OG  WITH (nolock)
	      INNER JOIN 
                      #TEMPOrderItem OI           WITH (nolock) 
	         ON   OI.OrderGroupIDSeq = OG.IDSeq
	      INNER JOIN  Orders.dbo.[Order] O        WITH (nolock)
	         ON   O.OrderIDSeq   = OI.OrderIDSeq
	      WHERE   O.AccountIDSeq = @IPVC_AccountID 
	         AND  OI.OrderIDSeq  = @LBI_OrderID
		 
	  ------------------------------------------------------------------------------------
	  ---Get distinct List of InvoiceGroup records.

      INSERT 
      INTO #TEMPInvoiceGroupFinal
                                 (
                                  InvoiceIDSeq,
                                  OrderIDSeq,
                                  OrderGroupIDSeq,
                                  Name,
                                  CustomBundleNameEnabledFlag
                                 )
      SELECT DISTINCT InvoiceIDSeq,
                      OrderIDSeq,
                      OrderGroupIDSeq,
                      Name,
                      CustomBundleNameEnabledFlag
      FROM #TEMPInvoiceGroup WITH (nolock)

		select @SQLErrorCode = @@error, @SQLRowCount = @@rowcount

		-- error handling -- 
		if @SQLErrorCode <> 0
		  begin 
			select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
		    exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, Insert into #TEMPInvoiceGroupFinal table - failed' 
		    return -- quit procedure.
		  end 	 
	
	   --set variables - 
	    select @LI_OrderIDSeq=OrderIDSeq
	           ,@LI_OrderGroupIDSeq=OrderGroupIDSeq
	           ,@LVC_OrderGroupName=Name
	           ,@LVC_CustomBundleNameEnabledFlag = CustomBundleNameEnabledFlag
	    from   #TEMPInvoiceGroupFinal with (nolock)
	    select @SQLErrorCode = @@error, @SQLRowCount = @@rowcount

	    -- error handling -- 
	    if @SQLErrorCode <> 0
	      begin 
             select @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	         exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, unable to select data from #TEMPInvoiceGroupFinal table.' 
	         return -- quit procedure.
	      end 
	  --------------------------------------------------------------------------------------
	  --- Populate #TEMPInvoiceGroup and #TEMPInvoiceGroupFinal tables - End
	  --------------------------------------------------------------------------------------
	  --------------------------------------------------------------------------------------
	  --- Populate data into #TEMPInvoiceItem table - Start 
	  -------------------------------------------------------------------------------------- 
	  INSERT INTO #TEMPInvoiceItem
                                     (
                                       InvoiceIDSeq,
                                       OrderIDSeq,
                                       OrderGroupIDSeq,
                                       OrderItemIDSeq,
                                       ProductCode,
                                       ChargeTypeCode,
                                       FrequencyCode,
                                       MeasureCode,
	                               Quantity,
                                       ChargeAmount,
                                       EffectiveQuantity,
                                       ExtChargeAmount,
                                       DiscountAmount,
                                       NetChargeAmount,
	                               BillingPeriodFromDate,
                                       BillingPeriodToDate,
                                       [PriceVersion],
                                       [RevenueTierCode],
                                       [RevenueAccountCode],
                                       [DeferredRevenueAccountCode],
                                       [RevenueRecognitionCode],
                                       [TaxwareCode],
                                       [DefaultTaxwareCode],
                                       [ShippingAndHandlingAmount],
                                       UnitOfMeasure,
                                       ReportingTypeCode,
                                       PricingTiers,
                                       OrderItemTransactionIDseq,
                                       TransactionItemName,
                                       ServiceCode,
                                       TransactionDate,
                                       Billtoaddresstypecode,
                                       BillToDeliveryOptionCode, 
                                       Units,Beds,PPUPercentage
                                     )
	      SELECT @LVC_InvoiceID     as InvoiceIDSeq,
                 OI.OrderIDSeq          as OrderIDSeq,
                 OI.OrderGroupIDSeq     as OrderGroupIDSeq,
	         OI.OrderItemIDSeq      as OrderItemIDSeq,
                 OI.ProductCode,
                 OI.ChargeTypeCode,
                 OI.FrequencyCode,
                 OI.MeasureCode,
	         OI.Quantity,
                 OI.ChargeAmount,
                 OI.EffectiveQuantity,
                 OI.ExtChargeAmount,
                 Convert(numeric(30,2),OI.DiscountAmount)  as DiscountAmount,
	         Convert(numeric(30,2),OI.NetChargeAmount) as NetChargeAmount,
	         OI.NewILFStartDate              as BillingPeriodFromDate, 
	         OI.NewILFEndDate                as BillingPeriodToDate,
	         OI.[PriceVersion],
                 OI.[RevenueTierCode]            as [RevenueTierCode],
                 OI.[RevenueAccountCode]         as [RevenueAccountCode],
                 OI.[DeferredRevenueAccountCode] as [DeferredRevenueAccountCode],
                 OI.[RevenueRecognitionCode]     as [RevenueRecognitionCode],
                 OI.[TaxwareCode]                as [TaxwareCode],
                 OI.DefaultTaxwareCode           as [DefaultTaxwareCode],
                 OI.[ShippingAndHandlingAmount]  as [ShippingAndHandlingAmount],
                 OI.UnitOfMeasure,
                 OI.ReportingTypeCode,
                 OI.PricingTiers,
                 OI.OrderItemTransactionIDseq,
                 substring(OI.TransactionItemName,1,300) as TransactionItemName,
                 OI.ServiceCode,OI.TransactionDate,
                 OI.Billtoaddresstypecode,
                 OI.BillToDeliveryOptionCode,
                 OI.Units,OI.Beds,OI.PPUPercentage
	      FROM   #TempOrderItem OI WITH (nolock) 
	      WHERE  exists (SELECT top 1 1 FROM #TEMPInvoiceGroupFinal TIGF WITH (nolock)
	                     WHERE TIGF.InvoiceIDSeq  = @LVC_InvoiceID
	                       AND OI.OrderIDSeq      = TIGF.OrderIDSeq
	                       AND OI.OrderGroupIDSeq = TIGF.OrderGroupIDSeq)	
              ORDER BY OI.TransactionDate ASC ---> This is important for Epicor Push 
	  --------------------------------------------------------------------------------------
	  --- Now Loop through the #TEMPInvoiceGroupFinal to populate Real Invoicing tables - 
	  -- Insert New InvoiceGroup Records from #TEMPInvoiceGroupFinal 
	  -- InvoiceItem Records from #TEMPInvoiceItem in a LOOP.
	  --------------------------------------------------------------------------------------
	  select @LI_MIN = 1
	  select @LI_MAX = count(SEQ) from #TEMPInvoiceGroupFinal with (nolock)
	  while  @LI_MIN <= @LI_MAX
	    begin --> begin for while loop - invoice group
	       SELECT @LI_OrderIDSeq                   = OrderIDSeq,
	                 @LI_OrderGroupIDSeq              = OrderGroupIDSeq,
	                 @LVC_OrderGroupName              = Name,
	                 @LVC_CustomBundleNameEnabledFlag = CustomBundleNameEnabledFlag
	       FROM   #TEMPInvoiceGroupFinal WITH (nolock)
	       WHERE  SEQ = @LI_MIN
	    -------------------------Begin Insert INVOICES.dbo.InvoiceGroup---------------------------
	       IF exists (SELECT top 1 1 FROM Invoices.dbo.InvoiceGroup WITH (nolock)
	                     WHERE InvoiceIDSeq    = @LVC_InvoiceID
	                       AND OrderIDSeq      = @LI_OrderIDSeq
	                       AND OrderGroupIDSeq = @LI_OrderGroupIDSeq)
	            BEGIN
	              SELECT top 1 @LI_InvoiceGroupIDSeq=IDSeq
	              FROM   Invoices.dbo.InvoiceGroup WITH (nolock)
	              WHERE  InvoiceIDSeq    = @LVC_InvoiceID
	                AND  OrderIDSeq      = @LI_OrderIDSeq
	                AND  OrderGroupIDSeq = @LI_OrderGroupIDSeq
	            END
	         ELSE
	            BEGIN
                  INSERT INTO Invoices.dbo.InvoiceGroup 
                                                      (
                                                       InvoiceIDSeq,
                                                       OrderIDSeq,
                                                       OrderGroupIDSeq,
                                                       Name,
                                                       CustomBundleNameEnabledFlag
                                                      )
	               SELECT @LVC_InvoiceID                   as InvoiceIDSeq,
                          @LI_OrderIDSeq                   as OrderIDSeq,
                          @LI_OrderGroupIDSeq              as OrderGroupIDSeq,
                          @LVC_OrderGroupName              as Name,
                          @LVC_CustomBundleNameEnabledFlag as CustomBundleNameEnabledFlag

	               SELECT @LI_InvoiceGroupIDSeq =  SCOPE_IDENTITY() 
		        END -- ELSE block

         select @SQLErrorCode = @@error 

		if @SQLErrorCode<> 0 
		  begin 
		     select @SQLErrorCode as SQLErrorCode, @LVC_InvoiceID as InvoiceID
		     exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Select/Generation of @LI_InvoiceGroupIDSeq Failed.' 
		  end
		-------------------------End Insert INVOICES.dbo.InvoiceGroup---------------------------
	    -------------------------Insert data into Invoices.dbo.Invoices table -------------------
	    if (@LI_InvoiceGroupIDSeq <> -1)
	      begin
	        INSERT INTO Invoices.dbo.InvoiceItem
                                                      (
                                                       InvoiceIDSeq, 
                                                       InvoiceGroupIDSeq,
                                                       OrderIDSeq,
                                                       OrderGroupIDSeq,
                                                       OrderItemIDSeq,
                                                       ProductCode,
	                                               ChargeTypeCode,
                                                       FrequencyCode,
                                                       MeasureCode,
                                                       Quantity,
                                                       ChargeAmount,
                                                       EffectiveQuantity,
                                                       ExtChargeAmount,
                                                       DiscountAmount,
                                                       NetChargeAmount,
                                                       BillingPeriodFromDate,
                                                       BillingPeriodToDate,
                                                       PriceVersion,
                                                       RevenueTierCode,
                                                       RevenueAccountCode,
                                                       DeferredRevenueAccountCode,
                                                       RevenueRecognitionCode,
                                                       TaxwareCode,
                                                       DefaultTaxwareCode,
                                                       ShippingAndHandlingAmount,
                                                       UnitOfMeasure,
                                                       ReportingTypeCode,
                                                       PricingTiers,
                                                       OrderItemTransactionIDseq,
                                                       TransactionItemName,
                                                       ServiceCode,
                                                       TransactionDate,
                                                       Billtoaddresstypecode,
                                                       BillToDeliveryOptionCode,
                                                       Units,Beds,PPUPercentage
                                                      )
	              SELECT @LVC_InvoiceID, 
                         @LI_InvoiceGroupIDSeq as InvoiceGroupIDSeq,
	                 S.OrderIDSeq,
                         S.OrderGroupIDSeq,
                         S.OrderItemIDSeq,
                         S.ProductCode,
	                 S.ChargeTypeCode,
                         S.FrequencyCode,
                         S.MeasureCode,
                         S.Quantity,
                         S.ChargeAmount,
	                 S.EffectiveQuantity,
                         S.ExtChargeAmount,
                         S.DiscountAmount,
                         S.NetChargeAmount,
	                 S.BillingPeriodFromDate,
		         S.BillingPeriodToDate,
			 S.PriceVersion,
                         RevenueTierCode,
                         RevenueAccountCode,
                         DeferredRevenueAccountCode,
                         RevenueRecognitionCode,
                         TaxwareCode,
                         DefaultTaxwareCode,
                         S.ShippingAndHandlingAmount,
                         UnitOfMeasure,
                         ReportingTypeCode,
                         PricingTiers,
                         S.OrderItemTransactionIDseq,
                         substring(S.TransactionItemName,1,300) as TransactionItemName,
                         null,
                         S.TransactionDate,
                         S.Billtoaddresstypecode,
                         S.BillToDeliveryOptionCode,
                         S.Units,S.Beds,S.PPUPercentage
	              FROM   #TEMPInvoiceItem S WITH (nolock)      
	              WHERE  S.OrderIDSeq        = @LI_OrderIDSeq
	                AND  S.OrderGroupIDSeq   = @LI_OrderGroupIDSeq
                        AND  NOT exists (SELECT top 1 1 FROM Invoices.dbo.InvoiceItem DII WITH (nolock)
                                         WHERE  DII.OrderIDSeq        = @LI_OrderIDSeq
	                                 AND    DII.OrderGroupIDSeq   = @LI_OrderGroupIDSeq      
	                                 AND    DII.OrderIDSeq        = S.OrderIDSeq
	                                 AND    DII.OrderGroupIDSeq   = S.OrderGroupIDSeq
	                                 AND    DII.OrderItemIDSeq    = S.OrderItemIDSeq
                                         AND    DII.OrderitemTransactionIDSeq = S.OrderItemTransactionIDseq                                         
	                                 AND    DII.ProductCode       = S.ProductCode
	                                 AND    DII.ChargeTypeCode    = S.ChargeTypeCode
	                                 AND    DII.FrequencyCode     = S.FrequencyCode
	                                 AND    DII.MeasureCode       = S.MeasureCode
	                                 AND    DII.BillingPeriodFromDate = S.BillingPeriodFromDate
	                                 AND    DII.BillingPeriodToDate   = S.BillingPeriodToDate
                                        )
                     ORDER BY S.TransactionDate ASC ---> This is important for Epicor Push 
	      end	    
            -----------------------------------------------------------------------------
            -- code to update the InvoicedFlag in the orderItemTransaction after Invoicing
            Update OIT
            set    OIT.InvoicedFlag = 1
            from   Orders.dbo.orderItemTransaction OIT with (nolock)
            inner join
                   #TEMPOrderItem S with (nolock)
            on     OIT.IDSeq          = S.OrderItemTransactionIDseq
            and    OIT.OrderItemIDSeq = S.OrderItemIDSeq
            and    OIT.OrderIDSeq     = S.OrderIDSeq
            and    OIT.OrderGroupIDSeq= S.OrderGroupIDSeq
            and    OIT.OrderIDSeq     = @LI_OrderIDSeq 
            and    S.OrderIDSeq       = @LI_OrderIDSeq 
            and    OIT.OrderGroupIDSeq= @LI_OrderGroupIDSeq
            and    S.OrderGroupIDSeq  = @LI_OrderGroupIDSeq
            and    OIT.TransactionalFlag = 1
            and    OIT.InvoicedFlag      = 0             
            where  OIT.IDSeq          = S.OrderItemTransactionIDseq
            and    OIT.OrderItemIDSeq = S.OrderItemIDSeq
            and    OIT.OrderIDSeq     = S.OrderIDSeq
            and    OIT.OrderGroupIDSeq= S.OrderGroupIDSeq
            and    OIT.OrderIDSeq     = @LI_OrderIDSeq 
            and    S.OrderIDSeq       = @LI_OrderIDSeq 
            and    OIT.OrderGroupIDSeq= @LI_OrderGroupIDSeq
            and    S.OrderGroupIDSeq  = @LI_OrderGroupIDSeq
            and    OIT.TransactionalFlag = 1
            and    OIT.InvoicedFlag      = 0             
            -----------------------------------------------------------------------------
            select @LI_MIN = @LI_MIN+1 
	  end --: end for while Loop
        END -- Processing completed for ILF,ACS,TRX	  
	   ------------------------------------------------------------------------------------
        --Truncating the temp tables other than #TEMPAddrType_InvGroupNumber
        ------------------------------------------------------------------------------------    
        TRUNCATE TABLE #TEMPCompany
        TRUNCATE TABLE #TEMPProperty
        TRUNCATE TABLE #TEMPAccount
        TRUNCATE TABLE #TEMPAddress
        TRUNCATE TABLE #TEMPInvoiceGroup
        TRUNCATE TABLE #TEMPInvoiceGroupFinal
        TRUNCATE TABLE #TEMPInvoiceItem
        TRUNCATE TABLE #TEMPOrderItem      

        SELECT @LI_MinValue = @LI_MinValue+1
    END --: END for parent while Loop	
      
       ------------------------------------------------------------------------------------
        --Update for Taxable Address related columns
        ------------------------------------------------------------------------------------
        declare @imin int,@imax int,@LVC_INVOICE varchar(50)
        select @imin = 1,@imax=count(*) from  #TEMP_InvoiceIDHoldingTable with (nolock)
        while @imin <= @imax
        begin
          select @LVC_INVOICE = InvoiceID 
          from   #TEMP_InvoiceIDHoldingTable with (nolock)
          where  IDSeq = @imin
          exec Invoices.dbo.uspINVOICES_TaxableAddressUpdate @IPVC_InvoiceID =@LVC_INVOICE
          select @imin = @imin+1
        end
        ------------------------------------------------------------------------------------
       --Sync $$$ amount totals and Notes now.
       ------------------------------------------------------------------------------------    
       Exec Invoices.dbo.[uspInvoices_SyncInvoiceTablesAndNotes] @IPVC_OrderIDSeq = @LBI_OrderID

       select @SQLErrorcode as SQLErrorcode,@LVC_InvoiceID as InvoiceID	
  -------------------------------------------------------------------------------------------------
  ---Final Cleanup
  drop table #TEMPCompany
  drop table #TEMPProperty
  drop table #TEMPAccount
  drop table #TEMPAddress
  drop table #TEMPInvoiceGroup
  drop table #TEMPInvoiceGroupFinal
  drop table #TEMPInvoiceItem
  drop table #TEMPOrderItem
  drop table #TEMPAddrType_InvGroupNumber
  DROP TABLE #TEMP_InvoiceIDHoldingTable;

END --: --: Main Procedure END
GO
