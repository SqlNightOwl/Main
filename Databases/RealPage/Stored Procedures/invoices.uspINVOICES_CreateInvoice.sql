SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : Invoices
-- Procedure Name  : [uspInvoices_CreateInvoice]
-- Description     : This procedure creates Invoice for a given Account AND Order
-- Input Parameters: @IPVC_QuoteID      as  VARCHAR(50)
--                   @IPVC_AccountID    as  VARCHAR(50) 
--                   @IPVC_CompanyID    as  VARCHAR(50)
--                   @IPVC_PropertyID   as  VARCHAR(50)
--                   @LBI_OrderID       as  VARCHAR(50)
-- Code Example    : 
--                  Exec Invoices.DBO.uspInvoices_CreateInvoice
-- 	                @IPVC_AccountID  = 'A0000000010',  
-- 	                @IPVC_CompanyID  = 'C0000003017',  
-- 	                @IPVC_PropertyID = 'P0000000026',
--                      @LBI_OrderID     = 70865  

-- 11/07/2011      : TFS 1514 : Transaction is moved to SP code from UI
----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_CreateInvoice] ( @IPVC_AccountID   VARCHAR(50)
                                                    ,@IPVC_CompanyID   VARCHAR(50)
                                                    ,@IPVC_PropertyID  VARCHAR(50)=NULL                                                                                                
                                                    ,@LBI_OrderID      VARCHAR(50)
                                                   )  
as
BEGIN --: Main Procedure BEGIN
  SET NOCOUNT ON; 
  ------------------------------------------------------------------------------------------------
  declare @LI_SeparateInvoiceByFamilyFlag     int,
          @LI_CMPFlag                         int,
          @LI_CMPSeparateInvoiceByFamilyFlag  int,
          @LI_PRPSeparateInvoiceByFamilyFlag  int

  select @LI_SeparateInvoiceByFamilyFlag = 0
  -------------------------------------------------------------------------------------------------
  --Declaring Local Variables
  -------------------------------------------------------------------------------------------------
  DECLARE @LVC_InvoiceID                   VARCHAR(50)
  DECLARE @LVC_InvoicestatusCode           VARCHAR(50)
  DECLARE @LVC_CompanyName                 VARCHAR(255)
  DECLARE @LVC_PropertyName                VARCHAR(255)
  DECLARE @LVC_AccountTypeCode             VARCHAR(50)
  DECLARE @LI_InvoiceTerms                 INT
  DECLARE @LI_PriceTerms                   INT
  DECLARE @LDT_InvoiceDate                 DATETIME  
  DECLARE @LDT_RunDateTime                 DATETIME
  DECLARE @LI_MIN                          BIGINT
  DECLARE @LI_MAX                          BIGINT  
  DECLARE @LI_OrderIDSeq                   VARCHAR(50)
  DECLARE @LI_OrderGroupIDSeq              BIGINT
  Declare @LBI_GroupID                     BIGINT
  Declare @LI_CBEnabledFlag                INT    
  DECLARE @LVC_OrderGroupName              VARCHAR(500)
  DECLARE @LI_InvoiceGroupIDSeq            BIGINT
  DECLARE @LVC_EpicorCustomerCode          VARCHAR(8)
  DECLARE @LVC_CustomBundleNameEnabledFlag SMALLINT
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
  DECLARE @LI_Months                       INT
  DECLARE @LDT_BillingCycleDate            DATETIME
  ----------------------------------------------------------------------------------------
  -- Declaring Variables for Error Handling 
  ----------------------------------------------------------------------------------------
  DECLARE @SQLErrorCode                    INT
  DECLARE @SQLRowCount                     INT 
  DECLARE @ErrorDescriptiON                VARCHAR(300)
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
  --Declaring Local Temporary Tables 
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
			     [CountryCode]            [VARCHAR](3)         NULL,
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
                             [OrderItemRenewalCount]      INT              NOT NULL,                             
	                     [ProductCode]                [VARCHAR](30)    COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [ChargeTypeCode]             [CHAR](3)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [FrequencyCode]              [CHAR](6)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [MeasureCode]                [CHAR](6)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [Quantity]                   [DECIMAL](18, 3) NOT NULL,	                      
	                     [ChargeAmount]               [MONEY]          NOT NULL,
	                     [EffectiveQuantity]          [decimal](18, 5),
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
                             [Units]                      [INT],
                             [Beds]                       [INT],
                             [PPUPercentage]              [INT],
                             [BillToAddressTypeCode]      [VARCHAR](20),
                             [BillToDeliveryOptionCode]   [VARCHAR](20)
                          ) 
  -- *** used to Identify order line items for invoicing *** -- 
  CREATE TABLE #TEMPOrderItem  
                         (	
                             [InvoiceIDSeq]               [VARCHAR](22),
                             [OrderItemIDSeq]             [BIGINT]      NOT NULL,
                             [OrderIDSeq]                 [VARCHAR](50) NOT NULL,
                             [OrderGroupIDSeq]            [BIGINT]      NOT NULL,
                             [OrderItemRenewalCount]      INT           NOT NULL, 
                             [ProductCode]                [CHAR](30), 
                             [ChargeTypeCode]             [CHAR](3),
                             [FrequencyCode]              [CHAR](6), 
                             [MeasureCode]                [CHAR](6),
                             [PlatFormCode]               [VARCHAR](5),
                             [FamilyCode]                 [CHAR](3), 
                             [PriceVersion]               [numeric](18, 0) NULL,
                             [Quantity]                   [decimal](18, 3) NOT NULL,
                             [ChargeAmount]               [MONEY]          NOT NULL, 
                             [EffectiveQuantity]          [decimal](18, 5), 
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
                             [Units]                      [INT],
                             [Beds]                       [INT],
                             [PPUPercentage]              [INT],
                             [ProrateFirstMonthFlag]      [INT] NOT NULL default(0),
                             [TargetDate]                 [DATETIME] NOT NULL
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
  SELECT  @LI_MIN                       = 1
         ,@LI_MAX                       = 0
         ,@LVC_InvoicestatusCode        = 'PENDG'
         ,@LI_InvoiceTerms              = 30
         ,@LDT_RunDateTime              = getdate()
         ,@LDT_InvoiceDate              = @LDT_RunDateTime 
         ,@LI_OrderLineItemCount        = 0  
         ,@LI_MonthlyLineItemCount      = 0 
         ,@LI_ILFLineItemCount          = 0
         ,@LI_AccessYearlyLineItemCount = 0 
  -------------------------------------------------------------------------------------------------      
  ---Initialization of Input Parameters IF NOT passed
  ------------------------------------------------------------------------------------------------- 
  IF (@IPVC_PropertyID IS NULL or @IPVC_PropertyID = '')  --When PropertyIDSeq is not supplied as parameter.
  BEGIN
    SELECT @IPVC_PropertyID = (SELECT PropertyIDSeq FROM Orders.dbo.[Order] WITH (NOLOCK) WHERE OrderIDSeq=@LBI_OrderID)
  END
  
  SELECT TOP 1 @LDT_BillingCycleDate = BillingCycleDate
  FROM   INVOICES.dbo.InvoiceEOMServiceControl with (nolock)
  WHERE  BillingCycleClosedFlag = 0
  ------------------------------------------------------------------------------------------------- 
  -- Retrieving the count of line items (get line items WITH dates) that will be Inserted INTO #TEMPOrderItem table - 
  -- IF 0 order items were found, THEN quit the procedure (Nothing to process).
  ------------------------------------------------------------------------------------------------- 
  SELECT  @LI_OrderLineItemCount = Count(OI.IDSeq)
  FROM    Orders.dbo.OrderItem OI WITH (nolock)     
  ----------------
  inner Join
          Products.dbo.Charge C with (nolock)
  on      OI.ProductCode       = C.ProductCode
  and     OI.PriceVersion      = C.PriceVersion
  and     OI.ChargeTypeCode    = C.ChargeTypeCode
  and     OI.MeasureCode       = C.MeasureCode
  and     OI.FrequencyCode     = C.FrequencyCode
  and     OI.OrderIDSeq        = @LBI_OrderID
  and     OI.StatusCode        <> 'EXPD'
  AND     OI.MeasureCode       <> 'TRAN'
  AND     OI.BillToAddressTypeCode IS NOT NULL
  -----------------------------------
  AND     OI.DoNotInvoiceFlag    = 0
  -----------------------------------
  Inner Join
          INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
  on      C.LeadDays           = BTM.LeadDays
  and     BTM.BillingCycleDate = @LDT_BillingCycleDate
  ----------------
  and  (
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NULL
           ) 
           OR
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NOT NULL
             and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.EndDate)
             and  OI.LastBillingPeriodToDate < BTM.TargetDate
             and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  <> 'OT'
            )            
       )  
  --------------------------------------   
  -- Error Handling - 
  SELECT @SQLErrorCode = @@Error

  IF (@SQLErrorCode <> 0) -- sql Error occured. 
    BEGIN 
      SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, @LI_OrderLineItemCount variable could NOT be populated' 
      Return
    END  
  -------------------------------------------------------------------------------------------------
  -- IF 0 order items were found, THEN quit the procedure.
  -------------------------------------------------------------------------------------------------
  IF @LI_OrderLineItemCount = 0 
    BEGIN 
       SELECT 0 as SQLErrorcode, 'ABCDEFGHIJK' as InvoiceID --> Dummy Returned to UI
       Return -- There IS nothing to process.
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
    SELECT          OI.IDSeq,
                    OI.OrderGroupIDSeq  as OrderGroupIDSeq,
                    Max(Convert(int,OG.CustomBundleNameEnabledFlag)) as CBEnabledFlag,
                    OI.BillToAddressTypeCode,
                    OI.BillToDeliveryOptionCode,
                    C.SeparateInvoiceGroupNumber,
                    CONVERT(INT,C.MarkAsPrintedFlag) AS MarkAsPrintedFlag,
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
    Inner Join
                    Products.dbo.Product PRD      WITH (nolock)
    on              OI.OrderIDSeq     = @LBI_OrderID
    AND             OI.ProductCode    = PRD.Code
    AND             OI.PriceVersion   = PRD.PriceVersion
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
    AND OI.StatusCode     <> 'EXPD'
    AND OI.MeasureCode    <> 'TRAN'
    AND OI.BillToAddressTypeCode IS NOT NULL
    -----------------------------------
    AND     OI.DoNotInvoiceFlag    = 0
    ----------------  
    Inner Join
          INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
    on    C.LeadDays           = BTM.LeadDays
    and   BTM.BillingCycleDate = @LDT_BillingCycleDate
    ----------------
    and  (
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NULL
           ) 
           OR
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NOT NULL
             and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.EndDate)
             and  OI.LastBillingPeriodToDate < BTM.TargetDate
             and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  <> 'OT'
            )            
        )  
    -----------------------------------
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
    SELECT          OI.IDSeq,
                    OI.OrderGroupIDSeq  as OrderGroupIDSeq,
                    Max(Convert(int,OG.CustomBundleNameEnabledFlag)) as CBEnabledFlag,
                    OI.BillToAddressTypeCode,
                    OI.BillToDeliveryOptionCode,
                    C.SeparateInvoiceGroupNumber,
                    CONVERT(INT,C.MarkAsPrintedFlag) AS MarkAsPrintedFlag,
                    (Case when Max(Convert(int,OG.CustomBundleNameEnabledFlag)) = 1 then NULL
                          else Max(OI.FamilyCode)
                     end)       as SeparateInvoiceProductFamilyCode,
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
    Inner Join
                    Products.dbo.Product PRD      WITH (nolock)
    on              OI.OrderIDSeq     = @LBI_OrderID
    AND             OI.ProductCode    = PRD.Code
    AND             OI.PriceVersion   = PRD.PriceVersion
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
    AND OI.StatusCode     <> 'EXPD'
    AND OI.MeasureCode    <> 'TRAN'
    AND OI.BillToAddressTypeCode IS NOT NULL
    -----------------------------------
    AND     OI.DoNotInvoiceFlag    = 0
    ----------------  
    Inner Join
          INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
    on    C.LeadDays             = BTM.LeadDays
    and   BTM.BillingCycleDate = @LDT_BillingCycleDate
    ----------------
    and  (
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NULL
           ) 
           OR
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NOT NULL
             and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.EndDate)
             and  OI.LastBillingPeriodToDate < BTM.TargetDate
             and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  <> 'OT'
            )            
        )     
    -----------------------------------
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
      SELECT @LVBI_OrderItemIDSeq                    = OrderItemIDSeq,
             @LBI_GroupID                            = OrderGroupIDSeq,
             @LI_CBEnabledFlag                       = CBEnabledFlag, 
             @LVC_BillToAddressTypeCode              = BillToAddressTypeCode,
             @LVC_BillToDeliveryOptionCode           = BillToDeliveryOptionCode,
             @LVBI_SeparateInvoiceGroupNumber        = SeparateInvoiceGroupNumber,
             @LVB_MarkAsPrintedFlag                  = MarkAsPrintedFlag,
             @LVC_SeparateInvoiceProductFamilyCode   = SeparateInvoiceProductFamilyCode,
             @LVC_EpicorPostingCode                  = EpicorPostingCode,
             @LVC_TaxwareCompanyCode                 = TaxwareCompanyCode,
             @LI_PrePaidFlag                         = PrePaidFlag
      FROM   #TEMPAddrType_InvGroupNumber WITH (nolock)
      WHERE  SEQ = @LI_MinValue        
      -------------------------------------------------------------------------------------------------
      -- Populating Table #TEMPOrderItem
      -- based on @LBI_OrderID,@LVBI_OrderItemIDSeq,@LVC_BillToAddressTypeCode,
      -- @LVBI_SeparateInvoiceGroupNumber and @LVB_MarkAsPrintedFlag values 
      -------------------------------------------------------------------------------------------------
      IF @LI_OrderLineItemCount <> 0 
        BEGIN -- BEGIN of Insertion of data into #TEMPOrderItem
          INSERT INTO #TEMPOrderItem 
                     (
                      [OrderItemIDSeq],
                      [OrderIDSeq],
                      [OrderGroupIDSeq],
                      OrderItemRenewalCount,
                      [ProductCode],
                      [ChargeTypeCode],
                      [FrequencyCode],
                      [MeasureCode],
                      [PlatFormCode],
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
                      Units,Beds,PPUPercentage,
                      ProrateFirstMonthFlag,
                      TargetDate
                     ) 
          SELECT 
                     OI.[IDSeq],
                     OI.[OrderIDSeq],
                     OI.[OrderGroupIDSeq],
                     OI.RenewalCount,
                     OI.[ProductCode],
                     OI.[ChargeTypeCode],
                     OI.[FrequencyCode],
                     OI.[MeasureCode],
                     P.[PlatFormCode],
                     OI.[FamilyCode],
                     OI.[PriceVersion],
                     OI.[Quantity],
                     OI.[ChargeAmount],
                     (convert(float,OI.ExtChargeAmount)
                               /
                      convert(float,(case when OI.ChargeAmount > 0 then convert(float,OI.ChargeAmount) else 1 end))
                     )  as EffectiveQuantity,
                     OI.[ExtChargeAmount],
                     OI.[TotalDiscountPercent],
                     OI.[TotalDiscountAmount],
                     OI.[NetChargeAmount],
                     OI.[ILFStartDate],
                     Coalesce(OI.canceldate,OI.[ILFEndDate]),
                     OI.[ActivationStartDate],
                     Coalesce(OI.canceldate,OI.[ActivationEndDate]),
                     OI.[StatusCode], 
                     OI.[StartDate],
                     Coalesce(OI.canceldate,OI.[EndDate]),
                     OI.[LastBillingPeriodFromDate],
                     OI.[LastBillingPeriodToDate],
                     OI.BillToAddressTypeCode,
                     OI.BillToDeliveryOptionCode,
                     OI.[CancelDate],
                     OI.[CapMaxUnitsFlag],
                     NULL        as [NewActivationStartDate], 
                     NULL        as [NewActivationEndDate],
                     O.[AccountIDSeq],
                     O.[QuoteIDSeq],
                     NULL        as [NewILFStartDate],
                     NULL        as [NewILFEndDate],
                     O.StatusCode   as [OrderstatusCode],
                     C.[RevenueTierCode],
                     C.[RevenueAccountCode],
                     C.[DeferredRevenueAccountCode],
                     C.[RevenueRecognitionCode],
                     C.[TaxwareCode],
                     C.[TaxwareCode] as DefaultTaxwareCode,
                     OI.[ShippingAndHandlingAmount],
                     C.[SeparateInvoiceGroupNumber],
                     OI.[UnitOfMeasure],
                     OI.[ReportingTypeCode],
                     OI.[PricingTiers],
                     OI.Units,OI.Beds,OI.PPUPercentage,
                     C.ProrateFirstMonthFlag,
                     BTM.TargetDate
          FROM       Orders.dbo.OrderItem OI WITH (nolock)
          INNER JOIN 
                     Orders.dbo.[Order] O WITH (nolock)
              ON     OI.OrderIDSeq            = O.OrderIDSeq 
              AND    OI.OrderIDSeq            = @LBI_OrderID 
              AND    OI.IDSeq                 = @LVBI_OrderItemIDSeq
              AND    OI.BillToAddressTypeCode = @LVC_BillToAddressTypeCode
              AND    OI.BillToDeliveryOptionCode = @LVC_BillToDeliveryOptionCode
              AND    OI.FamilyCode            = coalesce(@LVC_SeparateInvoiceProductFamilyCode,OI.FamilyCode)
              AND    OI.StatusCode     <>  'EXPD'
              AND    OI.MeasureCode    <>  'TRAN'
              -----------------------------------
              AND     OI.DoNotInvoiceFlag    = 0                            
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
          AND    OI.MeasureCode   <> 'TRAN'            
          AND    C.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
          ----------------  
          Inner Join
                 INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
          on      C.LeadDays           = BTM.LeadDays
          and     BTM.BillingCycleDate = @LDT_BillingCycleDate
          ----------------
         and  (
                ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
                  and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NULL
                ) 
                 OR
                ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
                  and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NOT NULL
                  and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.EndDate)
                  and  OI.LastBillingPeriodToDate < BTM.TargetDate
                  and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  <> 'OT'
                )            
              ) 
          WHERE      OI.OrderIDSeq                = @LBI_OrderID 
              AND    OI.IDSeq                     = @LVBI_OrderItemIDSeq
              AND    OI.BillToAddressTypeCode     = @LVC_BillToAddressTypeCode
              AND    OI.BillToDeliveryOptionCode  = @LVC_BillToDeliveryOptionCode
              AND    C.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
              AND    OI.FamilyCode                = coalesce(@LVC_SeparateInvoiceProductFamilyCode,OI.FamilyCode)
              and    FAM.EpicorPostingCode        = @LVC_EpicorPostingCode
              and    FAM.TaxwareCompanyCode       = @LVC_TaxwareCompanyCode 
              and    P.PrePaidFlag                = @LI_PrePaidFlag
              AND    OI.StatusCode                <>  'EXPD'
              AND    OI.MeasureCode               <>  'TRAN'

        END  -- END of Insertion of data into #TEMPOrderItem

      -- Error Handling --
      SELECT @SQLErrorcode = @@Error, @SQLRowCount = @@rowcount
      IF @SQLErrorCode <> 0 
        BEGIN 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, INSERT INTO #TempOrderItem table failed.' 
          Return  -- quit procedure! 
        END
      ---------------------------------------------------------------------------------------------------------------------------
      -- ILF - Validation Query to check if ILFStartDate is populated on the order line item.
      -- This is precautionary (dates should NOT be missing since @LI_OrderLineItemCountISalready checked when populating ) 
      ---------------------------------------------------------------------------------------------------------------------------
      IF Exists (SELECT ILFStartDate 
                 FROM   #TEMPOrderItem WITH (nolock)
                 WHERE (ILFStartDate IS NULL or ILFStartDate = '') AND ChargeTypeCode = 'ILF' )
        BEGIN 
          SELECT 0 as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'ILFStartDate IS NOT  populated for ILF OrderItemIDSeq. Check OrderItem dates' 
          Return -- quit procedure! 
        END 
      ---------------------------------------------------------------------------------------------------------------------------
      --ACCESS - Validation Query to check for following - 
          --a. If both ActivationStartDate AND ActivationEndDate are populated on the order line item. 
          --b. If dates are entered correctly  (for example - EndDate should NOT be less than the StartDate)
          -- This is precautionary (dates should NOT be missing since @LI_OrderLineItemCountISalready checked when populating) 
      ---------------------------------------------------------------------------------------------------------------------------
      -- If Activation start date is missing - 
      IF Exists (SELECT top 1 ActivationStartDate 
                 FROM   #TEMPOrderItem WITH (nolock)
                 WHERE (ActivationStartDate IS NULL or ActivationStartDate = '') AND ChargeTypeCode = 'ACS')
        BEGIN
          SELECT 0 as SQLErrorCode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'ActivationStartDate IS NOT  populated for access OrderItemIDSeq' 
          Return -- quit procedure! 
        END 
      -- If Activation END date is missing - 
      IF Exists (SELECT top 1 ActivationEndDate 
                 FROM   #TEMPOrderItem WITH (nolock)
                 WHERE (ActivationEndDate IS NULL or ActivationEndDate = '') AND ChargeTypeCode = 'ACS')
        BEGIN 
          SELECT 0 as SQLErrorCode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'ActivationEndDate IS NOT  populated for access OrderItemIDSeq' 
          Return -- quit procedure! 
        END 
      --To Verify Contract ActivationStartDate AND ActivationEndDate are either same or StartDate is less than the EndDate.
      IF Exists (SELECT top 1 ActivationEndDate 
                 FROM   #TEMPOrderItem WITH (nolock)
                 WHERE (ActivationEndDate < ActivationStartDate)
                        AND ChargeTypeCode = 'ACS' )
        BEGIN 
          SELECT 'ActivationEndDate or CancelDate is less than ActivationStartDate. Check OrderItem dates'  as ErrorMessage
                 ,0 as SQLErrorCode, @LVC_InvoiceID as InvoiceID
          Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'ActivationEndDate or CancelDate is less than ActivationStartDate. Check OrderItem dates' 
          Return -- quit procedure! 
        END 
      --To Verify Contract ILFStartdate AND ILFEndDate are either same or StartDate is less than the EndDate.
      IF Exists (SELECT top 1 ILFEndDate 
                 FROM   #TEMPOrderItem WITH (nolock)
                 WHERE (ILFEndDate < ILFStartdate)
                        AND ChargeTypeCode = 'ILF' )
        BEGIN 
          SELECT 'ILFEndDate or CancelDate is less than ILFEndDate. Check OrderItem dates'  as ErrorMessage
                 ,0 as SQLErrorCode, @LVC_InvoiceID as InvoiceID
          Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'ILFEndDate or CancelDate is less than ILFStartdate. Check OrderItem dates' 
          Return -- quit procedure! 
        END   
      ---------------------------------------------------------------------------------------------------------------------------
      ---Step 1 for ILF : SET the appropriate ILF Start and End dates for billing purposes. 
      --user could have entered ILF start date = 01/15/2007 & ILF END date = 1/15/2008
      --For billing purposes, a new ILF StartDate AND EndDate would be 01/01/2007 thru 01/31/2008 for NON-LEGACY family. 
      --For billing purposes, a new ILF StartDate AND EndDate would be 01/15/2007 thru 01/15/2008 for LEGACY family.
      ---------------------------------------------------------------------------------------------------------------------------
      --to populate NewILFStartDate column in #TEMPOrderItem table
      IF Exists (SELECT top 1 * FROM #TempOrderItem WITH (nolock) WHERE ChargeTypeCode = 'ILF')
        BEGIN 
          UPDATE OI 
          SET NewILFStartDate = CASE WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG' AND datepart(dd,ILFStartDate) <> '01')
                                         THEN Invoices.DBO.fn_SetFirstDayOfFollowingMonth(ILFStartDate) 
                                     WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG' AND datepart(dd,ILFStartDate) = '01')
                                         THEN ILFStartDate
	                             ELSE ILFStartDate 
                                END 
          FROM #TEMPOrderItem OI WITH (nolock)
          WHERE OI.ChargeTypeCode = 'ILF'

          DELETE FROM #TEMPOrderItem where ChargeTypeCode = 'ILF' and NewILFStartDate > TargetDate 
        END

      -- Error Handling -- 
      SELECT @SQLErrorCode = @@Error 
      IF @SQLErrorCode <> 0 
        BEGIN 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured in updating NewILFStartDate colum in #TEMPOrderItem table.' 
          Return -- quit procedure! 
        END

      IF Exists (SELECT top 1 * FROM #TempOrderItem WITH (nolock) WHERE NewILFStartDate IS NULL   AND ChargeTypeCode = 'ILF')
        BEGIN 
          SELECT 0 as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'NewILFStartDate is blank AND could NOT be calculated, Check ILF dates.' 
          Return -- quit procedure! 
        END 

      --to populate NewILFEndDate column in #TEMPOrderItem table
      IF Exists (SELECT top 1 * FROM #TempOrderItem WITH (nolock) WHERE ChargeTypeCode = 'ILF')
        BEGIN 
          UPDATE OI 
          SET    NewILFEndDate = CASE WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG' AND datepart(dd,ILFStartDate) <> '01') 
                                          THEN Invoices.DBO.fn_SetLastDayOfMonth(ILFEndDate)
                                      WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG' AND datepart(dd,ILFStartDate) = '01') 
                                          THEN ILFEndDate
                                   ELSE ILFEndDate 
                                 END     
          FROM   #TEMPOrderItem OI WITH (nolock)
          WHERE  OI.ChargeTypeCode = 'ILF'
          -----------------
          UPDATE OI
          SET    NewILFEndDate = (CASE when NewILFEndDate < NewILFStartDate
                                                then Invoices.DBO.fn_SetLastDayOfMonth(NewILFStartDate)
                                             else NewILFEndDate
                                         end)
          FROM #TEMPOrderItem OI WITH (nolock)
          WHERE  OI.ChargeTypeCode = 'ILF'  
        END
      -- Error Handling -- 
      SELECT @SQLErrorCode = @@Error
      IF @SQLErrorCode <> 0 
        BEGIN 
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, NewILFEndDate column UPDATE failed.Check ILF dates.' 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Return -- quit procedure! 
        END 
      ---------------------------------------------------------------------------------------------------------------------------
      ---Step 2 for ACS : SET the appropriate ActivationStart AND ActivationEnd dates for billing purposes. 
      --user could have entered ActivationStart date = 01/15/2007 & ActivationEnd date = 1/15/2008
      --For billing purposes, a new Activation start date (ACS) AND ActivationEnd date would be 01/01/2007 thru 01/31/2008 for NON-LEGACY family. 
      --For billing purposes, a new Activation start date (ACS) AND ActivationEnd date would be 01/15/2007 thru 01/15/2008 for LEGACY family.
      --for non-legacy family, set the Activation start date as the first day of the Month.
      --------------------------------------------------------------------------------------------------------------------------- 
      -------------------------------------------------------------------
      --to populate NewActivationStartDate column in #TEMPOrderItem table
      -------------------------------------------------------------------
      IF exists (SELECT top 1 * FROM #TempOrderItem WITH (nolock) WHERE ChargeTypeCode = 'ACS')
        BEGIN 
          UPDATE OI 
          SET  NewActivationStartDate = CASE 
                                             WHEN (ReportingTypeCode  = 'ANCF' and FrequencyCode = 'OT' and MeasureCode not in ('SITE','UNIT') 
                                                   and RevenueRecognitionCode = 'IRR')
                                              THEN ActivationStartDate
                                             WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG' AND datepart(dd,ActivationStartDate) <> '01')
                                              THEN Invoices.DBO.fn_SetFirstDayOfFollowingMonth(ActivationStartDate) 
                                             WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG' AND datepart(dd,ActivationStartDate) = '01')
                                              THEN ActivationStartDate 
	                                       ELSE 
                                            ActivationStartDate 
                                       END 
          FROM #TEMPOrderItem OI WITH (nolock)
          WHERE  OI.ChargeTypeCode = 'ACS' 

          DELETE FROM #TEMPOrderItem 
          where ChargeTypeCode = 'ACS' and FrequencyCode <> 'MN' 
          and   NewActivationStartDate > TargetDate 
          and   ProrateFirstMonthFlag  = 0

          DELETE FROM #TEMPOrderItem 
          where ChargeTypeCode = 'ACS' and FrequencyCode <> 'MN' 
          and   StartDate > TargetDate 
          and   ProrateFirstMonthFlag  = 1
        END
      -- Error Handling -- 
      SELECT @SQLErrorCode = @@Error
      IF @SQLErrorCode <> 0
        BEGIN 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured,UPDATE to populate NewActivationStartDate column in #TEMPOrderItem table failed.' 
          Return -- quit procedure! 
        END 
       -------------------------------------------------------------------
       --to populate NewActivationEndDate column in #TEMPOrderItem table
       -------------------------------------------------------------------
      IF exists (SELECT top 1 * FROM #TempOrderItem WITH (nolock) WHERE ChargeTypeCode = 'ACS')
        BEGIN 
          UPDATE OI 
          SET NewActivationEndDate = CASE                                           
                                          WHEN (Platformcode  = 'DMD' and FamilyCode = 'YLD' and 
                                                FrequencyCode = 'OT' and MeasureCode = 'SITE' and 
                                                ProductCode   = 'DMD-YLD-YTS-YTS-YLIT' and RevenueRecognitionCode = 'SRR')
                                            THEN Invoices.DBO.fn_SetLastDayOfMonth(DATEADD(month, 2, NewActivationStartDate))
                                          WHEN (ReportingTypeCode  = 'ANCF' and FrequencyCode = 'OT' and MeasureCode not in ('SITE','UNIT') 
                                                and RevenueRecognitionCode = 'IRR')
                                            THEN ActivationStartDate 
                                          WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG')
                                            THEN Invoices.DBO.fn_SetLastDayOfMonth(ActivationEndDate)
	                                   ELSE ActivationEndDate --for legacy family, we want to keep the dates as is.
                                     END     
          FROM #TEMPOrderItem OI WITH (nolock)
          WHERE  OI.ChargeTypeCode = 'ACS'
          ------------------------
          UPDATE OI
          SET    NewActivationEndDate = (CASE when NewActivationEndDate < NewActivationStartDate
                                                then Invoices.DBO.fn_SetLastDayOfMonth(NewActivationStartDate)
                                             else NewActivationEndDate
                                         end)
          FROM #TEMPOrderItem OI WITH (nolock)
          WHERE  OI.ChargeTypeCode = 'ACS'
        END
       -------------------------------------------------------------------
       --to calculate number of months for prorated calculation (ACS/YR)
       -------------------------------------------------------------------
      IF exists (SELECT top 1 * FROM #TempOrderItem WITH (nolock) WHERE ChargeTypeCode = 'ACS' and FrequencyCode='YR')
        BEGIN 
            Declare @LDT_ProStartDate Datetime
            Declare @LDT_ProEndDate Datetime
            Declare @LVC_PlatFormCode Varchar(5)
            Declare @LVC_FamilyCode Char(3)

            Select Top 1 @LVC_PlatFormCode = PlatFormCode,@LVC_FamilyCode = FamilyCode
            FROM #TempOrderItem WITH (nolock) 
            WHERE ChargeTypeCode = 'ACS' and FrequencyCode='YR'

            Select top 1 @LDT_ProStartDate=NewActivationStartDate,
                         @LDT_ProEndDate  =NewActivationEndDate
            From #TempOrderItem WITH (nolock)


           SELECT @LI_Months = CASE WHEN (@LVC_PlatFormCode <> 'PRM' and @LVC_FamilyCode <> 'LEG')
                                     THEN DATEDIFF(mm,@LDT_ProStartDate,@LDT_ProEndDate)+1
                                  ELSE DATEDIFF(mm,@LDT_ProStartDate,@LDT_ProEndDate+1)    -- Adding One day to the end date for legacy products
                              END

           IF @LI_Months=0 SELECT @LI_Months = 1
        END
      -- Error Handling -- 
      SELECT @SQLErrorCode = @@Error
      IF @SQLErrorCode <> 0
        BEGIN 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured in updating NewActivationEndDate colum in #TEMPOrderItem table.' 
          Return -- quit procedure! 
        END 
      ---------------------------------------------------------------------------------------------------------------------------
      ---Validation query to see If any of eligible OrderItems have been billed before. 
      -- IF these have been billed before, then flag an Error because this should be a new order and there should NOT be any 
      -- order items that are billed so far. 
      -- ELSE proceed to creating Invoice for these order items. 
      ---------------------------------------------------------------------------------------------------------------------------
      -- For Migration Orders the dates may not be null....so commented the code
--      IF exists (SELECT top 1 * 
--                 FROM #TempOrderItem OI WITH (nolock) 
--                 WHERE OI.LastBillingPeriodToDate IS NOT NULL AND OI.LastBillingPeriodToDate IS NOT NULL)
--      SELECT @SQLErrorCode = @@Error
--      IF @SQLErrorCode <> 0 
--        BEGIN 
--          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
--          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Check LastBillingPeriodFromDate AND LastBillingPeriodToDate columns in Orders.dbo.OrderItem table' 
--          Return -- quit procedure! 
--        END
      -------------------------------------------------------------------------------------------------
      ---Validation Check to see IF there are eligible items for invoicing based ON new calculated dates. 
      -- IF all variable valuesIS0 THEN quit stored procedure (no need to create Invoice).
      -- IF any variable valueIS1, proceed to creating Invoice.
      -------------------------------------------------------------------------------------------------
      -----------------  
      --ILF ONCE
      -----------------
      SELECT @LI_ILFLineItemCount = count(DISTINCT OI.OrderItemIDSeq)
      FROM   #TEMPOrderItem OI WITH (nolock)
      WHERE  (OI.ChargeTypeCode  = 'ILF'     AND OI.FrequencyCode in ('SG','OT'))
         AND (OI.NewILFStartDate IS NOT NULL)
      -----------------  
      --ACCESS YEARLY
      -----------------
      SELECT @LI_AccessYearlyLineItemCount = count(DISTINCT OI.OrderItemIDSeq)
      FROM   #TEMPOrderItem OI WITH (nolock)
      WHERE (OI.ChargeTypeCode  = 'ACS'            AND OI.FrequencyCode <>'MN') 
        AND (OI.NewActivationStartDate IS NOT NULL) --AND OI.LastBillingPeriodToDate IS NULL  ) --should always be a new access
      -----------------  
      --ACCESS MONTHLY
      -----------------
      SELECT @LI_MonthlyLineItemCount =  ISNULL  (datedIFf(MM, CASE WHEN OI.LastBillingPeriodFromDate IS NULL THEN OI.NewActivationStartDate  
              						                             ELSE OI.LastBillingPeriodFromDate  END
                                                 ,Invoices.DBO.fn_SetFirstDayOfFollowingMonth(OI.TargetDate)),0)
      FROM   #TEMPOrderItem OI WITH (nolock)
      WHERE  OI.ChargeTypeCode  = 'ACS' AND OI.FrequencyCode = 'MN'
      AND    OI.NewActivationStartDate IS NOT NULL AND OI.NewActivationStartDate <= OI.TargetDate
      ------------------------------------------------------------------------------------
      --Now Create Monthly Invoice Items for Monthly order items - 
      --Validation Query to check If there are any eligible Monthly order items to bill
      -- as per the new calculated dates.  
      --IF @LI_MonthlyLineItemCount = 1, call procedure uspInvoices_CreateMonthlyInvoice
      --IF @LI_MonthlyLineItemCount = 0, THEN don't call the stored procedure.
      ------------------------------------------------------------------------------------ 
      IF (@LI_MonthlyLineItemCount IS NOT NULL AND @LI_MonthlyLineItemCount <> 0 )
        BEGIN
           -- Inserting data into the temp table based on the MonthlyInvoice procedure output
           INSERT INTO #temp_InvoiceIDHoldingTable (SQLErrorcode,InvoiceID)
           EXEC Invoices.DBO.uspInvoices_CreateMonthlyInvoice		                                   
	                                           @IPVC_AccountID  = @IPVC_AccountID,  
	                                           @IPVC_CompanyID  = @IPVC_CompanyID,  
	                                           @IPVC_PropertyID = @IPVC_PropertyID,	                                           
		                                   @LBI_OrderID     = @LBI_OrderID           
        END
      -- Error Handling -- 
      SELECT @SQLErrorCode = @@Error
      IF @SQLErrorCode <>0 
        BEGIN 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, Procedure call to Invoices.DBO.uspInvoices_CreateMonthlyInvoice failed.' 
          Return -- quit procedure.
        END
      -------------------------------------------------------------------------------------------------
      ---Step 1 : Create Invoice If there are items to process, ELSE quit.
      ---         Get Latest InvoiceID WITH PrintFlag=0 IF One exists for the @IPVC_AccountID,@LVC_BillToAddressTypeCode 
      ---         AND @LVBI_SeparateInvoiceGroupNumber ELSE Generate New InvoiceID 
      -------------------------------------------------------------------------------------------------
      IF (    @LI_ILFLineItemCount          = 0 
          AND @LI_AccessYearlyLineItemCount = 0  
          AND @LI_MonthlyLineItemCount      = 0) 
         BEGIN
           SELECT 0 as SQLErrorcode, 'ABCDEFGHIJK' as InvoiceID --> Dummy Returned to UI  
           Return --Nothing to process, please quit stored procedure.
         END
      ELSE 
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
	          END
	          ELSE
	          BEGIN
	          ----------------------------------------
	          --- Create a new Invoice id
	          ----------------------------------------
                     begin TRY
                       BEGIN TRANSACTION CI; 
      	                 UPDATE Invoices.DBO.IDGenerator WITH (TABLOCKX,XLOCK,HOLDLOCK)
	                 SET    IDSeq = IDSeq+1,
	                        GeneratedDate =CURRENT_TIMESTAMP
                         WHERE  TypeIndicator = 'I'      
	
	                 SELECT @LVC_InvoiceID = IDGeneratorSeq
	                 FROM   Invoices.DBO.IDGenerator WITH (NOLOCK)
                         WHERE  TypeIndicator  = 'I'
                      COMMIT TRANSACTION CI;
                     end TRY
                     begin CATCH    
                       if (XACT_STATE()) = -1
                       begin
                         IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION CI;
                       end
                       else 
                       if (XACT_STATE()) = 1
                       begin
                         IF @@TRANCOUNT > 0 COMMIT TRANSACTION CI;
                       end  
                       IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION CI;

                       SELECT 0 as SQLErrorcode, 'ABCDEFGHIJK' as InvoiceID --> Dummy Returned to UI when Error Occurs
                       Return; -- There IS nothing to process.
                      end CATCH;
	          END
                  -------------------------------------------------
                  INSERT INTO #temp_InvoiceIDHoldingTable (SQLErrorcode,InvoiceID)
                  select @SQLErrorCode as SQLErrorcode,@LVC_InvoiceID as InvoiceID
                  -------------------------------------------------
        -- Error Handling -- WHEN SELECT/InvoiceID generatiON fails-- 
        SELECT @SQLErrorCode = @@Error	
        IF @SQLErrorCode <> 0 
           BEGIN 
             SELECT @SQLErrorCode as SQLErrorCode, @LVC_InvoiceID as InvoiceIDSeq
             Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'New InvoiceID Gen: New InvoiceID GeneratiON failed for uspInvoices_CreateInvoice'  
             Return
           END
         END -- Create InvoiceIDSeq - END
      -------------------------------------------------------------------------------------------------
      ---Step 2 : Load all temp tables - 
      -------------------------------------------------------------------------------------------------
      IF ( @LI_ILFLineItemCount <> 0 or @LI_AccessYearlyLineItemCount <> 0 ) 
        BEGIN -- process ILF, ACS 
	      --------------------------------------------------------
	      ---Company  (INSERT data INTO #TEMPCompany) - Start
	      --------------------------------------------------------
          INSERT 
          INTO #TEMPCompany 
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

           -- Error Handling --
	      SELECT @SQLErrorCode = @@Error, @SQLRowCount = @@rowcount
          IF @SQLErrorCode <> 0
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while INSERTing data INTO #TEMPCompany table' 
	          Return -- quit procedure! 
	        END 	     
          IF @SQLRowCount = 0 
	        BEGIN
              SELECT  0 as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
 	          Exec    CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Company was NOT found in customers.dbo.company table for AccountIDSeq.' 
	          Return -- quit procedure! 
	        END 
          --------------------------------------------------------
          ---Company  (INSERT data INTO #TEMPCompany) - END
          --------------------------------------------------------
          --------------------------------------------------------
          -- Account (INSERT data INTO #TEMPAccount table) -Start
          --------------------------------------------------------
          IF (@LVC_AccountTypeCode = 'AHOFF')
	         BEGIN
	           SELECT Top 1 @LI_PriceTerms= priceterm FROM #TEMPCompany WITH (nolock)
	         END
	      ELSE
	         BEGIN
	           SELECT Top 1 @LI_PriceTerms= priceterm FROM #TEMPProperty WITH (nolock)
	         END
	
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

          -- Error Handling --
	      SELECT @SQLErrorCode = @@Error, @SQLRowCount = @@rowcount

	      IF @SQLErrorCode <> 0 
	        BEGIN 
              SELECT @SQLErrorCode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
 	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while trying to INSERT account data into #TEMPAccount table.' 
	          Return -- quit procedure! 
	        END 	     
 
	      IF @SQLRowCount = 0 
	        BEGIN 
              SELECT 0 as SQLErrorcode,@LVC_InvoiceID as InvoiceID  
 	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Account was not found in customers.dbo.account table for AccountIDSeq.' 
	          Return -- quit procedure! 
	        END 
 
          SELECT @LVC_EpicorCustomerCode = EpicorCustomerCode,
                 @LVC_AccountTypeCode = AccountTypeCode	             
 	      FROM   #TEMPAccount WITH (nolock) 	 
	       
	      IF @LVC_AccountTypeCode IS NULL   
	        BEGIN 
              SELECT 0 as SQLErrorcode, @LVC_InvoiceID as InvoiceID
 	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'AccountTypeCode is not found for accountIDSeq' 
	          Return -- quit procedure! 
	      END	
	      --------------------------------------------------------
	      -- Account (INSERT data INTO #TEMPAccount table) - END
	      --------------------------------------------------------
             --------------------------------------------------------
	      ---Property  (INSERT data INTO #TEMPProperty) - Start
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
	      SELECT    P.IDSeq,
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
                    #TEMPAccount A             WITH (nolock)
		    ON  P.IDSeq = A.propertyIDSeq
          WHERE A.IDSeq = @IPVC_AccountID

          -- Error Handling --
	      SELECT @SQLErrorCode = @@Error
	      IF @SQLErrorCode <> 0 
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while trying to locate a property for AccountIDSeq' 
	          Return -- quit procedure! 
	        END 
	      --------------------------------------------------------
	      ---Property  (Insert data into #TEMPProperty) - END
	      --------------------------------------------------------
	      --------------------------------------------------------
	      ---Accounts Billing Address - Start 
	      -- Insert into #TEMPAddress table
	      --(account could be a company or a property)
	      --------------------------------------------------------
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
                                 ELSE   coalesce(@LVC_PropertyName,@LVC_CompanyName)
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

          -- Error Handling -- 
          SELECT @SQLErrorCode = @@Error, @SQLRowCount = @@rowcount
          IF @SQLErrorCode <> 0 
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while trying to locate a billing address for AccountIDSeq' 
	          Return -- quit procedure! 
	        END 
	
          IF @SQLRowCount = 0 
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
 	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Billing addresses were not found for AccountIDSeq' 
	          Return -- quit procedure! 
	        END 
	      --------------------------------------------------------
	      ---Accounts Billing Address - END 
	      -- Insert into #TEMPAddress table
	      --(Account could be a Company or a Property)
	      --------------------------------------------------------

	      --------------------------------------------------------
	      ---Accounts Shipping Address - Start 
	      -- Insert into #TEMPAddress table
	      --(Account could be a Company or a Property)
	      --------------------------------------------------------
	      --- If account type is a property then load property's billing address. 
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
               SELECT  Top 1
                            AD.IDSeq,
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
               SELECT   Top 1
                            AD.IDSeq,
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
	      -- Error Handling -- 
	      SELECT @SQLErrorCode = @@Error, @SQLRowCount = @@rowcount
	      IF @SQLErrorCode <> 0 
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while trying to locate a Shipping address for AccountIDSeq' 
	          Return -- quit procedure! 
	        END 

          IF @SQLRowCount = 0 
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'Shipping Address not found.' 
	          Return -- quit procedure! 
	        END 
	      --------------------------------------------------------
	      ---Accounts Shipping Address - END 
	      -- Insert into #TEMPAddress table
	      --(Account could be a Company or a Property)
	      --------------------------------------------------------

          --------------------------------------------------------
	      -- Now Inserting data into Invoices.dbo.Invoices table 
	      --------------------------------------------------------
          IF NOT EXISTS (SELECT 1 FROM Invoices.dbo.Invoice WITH (nolock) WHERE InvoiceIDSeq = @LVC_InvoiceID)
            BEGIN
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
              SELECT  DISTINCT
	                           @LVC_InvoiceID,
	                           S.Name
	                           ,(SELECT top 1 Name FROM #TEMPProperty with (nolock)) as PropertyName
	                           ,@IPVC_AccountID,
	                           @IPVC_CompanyID,
	                           @IPVC_PropertyID,
	                           0,0,0,0,0,0,
	                           @LVC_InvoicestatusCode,
	                           @LI_InvoiceTerms,
	                           @LDT_InvoiceDate,
	                          (@LDT_InvoiceDate+@LI_InvoiceTerms),
	                           NULL,0,'MIS Admin','MIS Admin',getdate(),getdate(),NULL,NULL,
	                           0,NULL,0,NULL,
	                           @LVC_EpicorCustomerCode,
                                   @LVC_AccountTypeCode,
	                           BA.AccountName,
	                           SA.AccountName
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
	                           ,'',
	                           BA.AddressLine1,
	                           BA.AddressLine2,
	                           BA.City,
	                           '',
	                           BA.State,
	                           BA.Zip,
	                           BA.Country,'',
	                           '','',
	                           SA.AddressLine1,
	                           SA.AddressLine2,SA.City,'',
	                           SA.State,SA.Zip,SA.Country,
		                   BA.CountryCode,SA.CountryCode,
                               @LVC_BillToAddressTypeCode,
                               @LVBI_SeparateInvoiceGroupNumber,
                               @LVB_MarkAsPrintedFlag,
                               @LVC_EpicorPostingCode,
                               @LVC_TaxwareCompanyCode,
                               BA.Email
                               ,@LVC_BillToDeliveryOptionCode     as DeliveryOptionCode,
                               (case when @IPVC_PropertyID is not null 
                                                  then (SELECT top 1 SendInvoiceToClientFlag FROM #TEMPProperty with (nolock))
                                                else S.SendInvoiceToClientFlag
                               end)  as SendInvoiceToClientFlag,
                              @LDT_BillingCycleDate as BillingCycleDate
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

            -- Error Handling -- 
            SELECT @SQLErrorCode = @@Error
	        IF @SQLErrorCode <> 0 
	          BEGIN 
                SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	            Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, Insert into Invoices.dbo.Invoice table failed.' 
	            Return -- quit procedure! 
	          END 

              --------------------------------------------------------------------------------------
	      --- Populate #TEMPInvoiceGroup AND #TEMPInvoiceGroupFinal tables - Start
	      --------------------------------------------------------------------------------------
	      --------------------------------------------------------------------------------------
	      --- Identify ILF thatISready to bill based on new calculated dates 
	      -- (ILF may or may not have a quote id, hence always use accountid)
	      --------------------------------------------------------------------------------------
	      -----------------  
	      --New ILF 
	      -----------------
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
	         AND (OI.ChargeTypeCode  = 'ILF'     AND OI.FrequencyCode in ('SG','OT'))
	         AND (OI.NewILFStartDate IS NOT NULL) --AND OI.LastBillingPeriodToDate IS NULL  ) --should always be a new ilf
	      -----------------  
	      --New Access 
	      -----------------
	      INSERT INTO #TEMPInvoiceGroup 
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
	                     OG.Name                        as Name,
	                     OG.CustomBundleNameEnabledFlag as CustomBundleNameEnabledFlag
	      FROM       Orders.DBO.[OrderGroup] OG  WITH (nolock)
	      INNER JOIN 
                     #TEMPOrderItem OI           WITH (nolock) 
	         ON  OI.OrderGroupIDSeq = OG.IDSeq
	      INNER JOIN Orders.dbo.[order] O WITH (nolock)
	         ON  O.OrderIDSeq   = OI.OrderIDSeq
	      WHERE  O.AccountIDSeq = @IPVC_AccountID 
	         AND OI.OrderIDSeq  = @LBI_OrderID
	         AND (OI.ChargeTypeCode  = 'ACS') 
	         AND (OI.NewActivationStartDate IS NOT NULL) -- AND OI.LastBillingPeriodToDate IS NULL  ) --should always be a new access
          ------------------------------------------------------------------------------------
	      ---Get DISTINCT List of InvoiceGroup records INTO #TEMPInvoiceGroupFinal.
          ------------------------------------------------------------------------------------
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

	      SELECT @SQLErrorCode = @@Error, @SQLRowCount = @@rowcount
	      -- Error Handling -- 
	      IF @SQLErrorCode <> 0
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	          --Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, Insert into #TEMPInvoiceGroupFinal table - failed' 
	          Return -- quit procedure.
	        END	

	      --SET variables - 
	      SELECT @LI_OrderIDSeq=OrderIDSeq
	            ,@LI_OrderGroupIDSeq=OrderGroupIDSeq
	            ,@LVC_OrderGroupName=Name
	            ,@LVC_CustomBundleNameEnabledFlag = CustomBundleNameEnabledFlag
	      FROM   #TEMPInvoiceGroupFinal WITH (nolock)

	      SELECT @SQLErrorCode = @@Error, @SQLRowCount = @@rowcount
	      -- Error Handling -- 
	      IF @SQLErrorCode <> 0
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	          --Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, unable to SELECT data FROM #TEMPInvoiceGroupFinal table.' 
	          Return -- quit procedure.
	        END	   
	      --------------------------------------------------------------------------------------
	      --- Populate #TEMPInvoiceGroup AND #TEMPInvoiceGroupFinal tables - END
	      --------------------------------------------------------------------------------------

          --------------------------------------------------------------------------------------
	      --- Populate data INTO #TEMPInvoiceItem table - Start 
	      --------------------------------------------------------------------------------------
	      -- ILF 
	      INSERT INTO #TEMPInvoiceItem
                                     (
                                       InvoiceIDSeq,
                                       OrderIDSeq,
                                       OrderGroupIDSeq,
                                       OrderItemIDSeq,
                                       OrderItemRenewalCount,
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
                                       Billtoaddresstypecode,
                                       BillToDeliveryOptionCode,
                                       Units,Beds,PPUPercentage
                                     )
	      SELECT   @LVC_InvoiceID     as InvoiceIDSeq,
                   OI.OrderIDSeq      as OrderIDSeq,
                   OI.OrderGroupIDSeq as OrderGroupIDSeq,
	           OI.OrderItemIDSeq  as OrderItemIDSeq,
                   OI.OrderItemRenewalCount as OrderItemRenewalCount,
                   OI.ProductCode, 
                   OI.ChargeTypeCode,
                   OI.FrequencyCode,
                   OI.MeasureCode,
	           OI.Quantity,
                   OI.ChargeAmount,
                   OI.EffectiveQuantity,
                   OI.ExtChargeAmount,
                   convert(numeric(30,2),OI.DiscountAmount)  as DiscountAmount,
	           convert(numeric(30,2),OI.NetChargeAmount) as NetChargeAmount,
	           OI.NewILFStartDate              as BillingPeriodFromDate, 
	           OI.NewILFEndDate                as BillingPeriodToDate,
	           OI.PriceVersion                 as PriceVersion,
                   OI.RevenueTierCode              as RevenueTierCode,
                   OI.RevenueAccountCode           as RevenueAccountCode,
                   OI.DeferredRevenueAccountCode   as DeferredRevenueAccountCode,
                   OI.RevenueRecognitionCode       as RevenueRecognitionCode,
                   OI.TaxwareCode                  as TaxwareCode,
                   OI.DefaultTaxwareCode           as DefaultTaxwareCode,
                   OI.ShippingAndHandlingAmount    as ShippingAndHandlingAmount,
                   OI.UnitOfMeasure,
                   OI.ReportingTypeCode,
                   OI.PricingTiers,
                   OI.Billtoaddresstypecode,
                   OI.BillToDeliveryOptionCode,
                   OI.Units,OI.Beds,OI.PPUPercentage
	      FROM   #TempOrderItem OI WITH (nolock) 
	      WHERE  exists (SELECT top 1 1 FROM #TEMPInvoiceGroupFinal TIGF WITH (nolock)
	                     WHERE   TIGF.InvoiceIDSeq = @LVC_InvoiceID
	                       AND   OI.OrderIDSeq     = TIGF.OrderIDSeq
	                       AND   OI.OrderGroupIDSeq= TIGF.OrderGroupIDSeq)
	        AND   OI.ChargeTypeCode  = 'ILF'
	        AND   OI.FrequencyCode in ('SG','OT')
	        AND  (OI.ILFStartDate IS NOT  NULL) -- AND OI.LastBillingPeriodToDate IS NULL  )
	     ------------------------
              -- Access with ProrateFirstMonthFlag = 1
             INSERT INTO #TEMPInvoiceItem
                                     (
                                       InvoiceIDSeq,
                                       OrderIDSeq,
                                       OrderGroupIDSeq,
                                       OrderItemIDSeq,
                                       OrderItemRenewalCount,
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
                                       Billtoaddresstypecode,
                                       BillToDeliveryOptionCode,
                                       Units,Beds,PPUPercentage
                                     )
	      SELECT @LVC_InvoiceID as InvoiceIDSeq,
                 OI.OrderIDSeq      as OrderIDSeq,
                 OI.OrderGroupIDSeq as OrderGroupIDSeq,
	         OI.OrderItemIDSeq  as OrderItemIDSeq,
                 OI.OrderItemRenewalCount as OrderItemRenewalCount,
                 OI.ProductCode,
                 OI.ChargeTypeCode,
                 OI.FrequencyCode,
                 OI.MeasureCode,
	         OI.Quantity,
                 OI.ChargeAmount               as ChargeAmount,
                 OI.EffectiveQuantity          as EffectiveQuantity,
                 OI.ExtChargeAmount            as ExtChargeAmount,                   
                 (OI.ExtChargeAmount -
                       (CASE WHEN OI.ChargeTypeCode = 'ACS' and OI.FrequencyCode = 'YR' and DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
                               THEN  convert(numeric(30,2), 
                                               (convert(float,OI.NetChargeAmount) * DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate))
                                                 /
                                               (convert(float,INVOICES.dbo.fn_GetNumDaysInYear(OI.ActivationStartDate)))
                                             )
                             WHEN OI.ChargeTypeCode = 'ACS' and OI.FrequencyCode = 'MN' and DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
                               THEN  convert(numeric(30,2), 
                                               (convert(float,OI.NetChargeAmount) * DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate))
                                                 /
                                               (convert(float,INVOICES.dbo.fn_GetNumDaysInMonth(OI.ActivationStartDate)))
                                            )
                             else 0.00
                       end)
                 )                             as  DiscountAmount,
                (CASE WHEN OI.ChargeTypeCode = 'ACS' and OI.FrequencyCode = 'YR' and DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
                        THEN  convert(numeric(30,2), 
                                               (convert(float,OI.NetChargeAmount) * DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate))
                                                 /
                                               (convert(float,INVOICES.dbo.fn_GetNumDaysInYear(OI.ActivationStartDate)))
                                      )
                        WHEN OI.ChargeTypeCode = 'ACS' and OI.FrequencyCode = 'MN' and DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
                          THEN  convert(numeric(30,2), 
                                               (convert(float,OI.NetChargeAmount) * DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate))
                                                 /
                                               (convert(float,INVOICES.dbo.fn_GetNumDaysInMonth(OI.ActivationStartDate)))
                                       )
                        else 0.00
                    end)                         as NetChargeAmount,   
	         OI.ActivationStartDate          as BillingPeriodFromDate, 
	         (OI.NewActivationStartDate-1)   as BillingPeriodToDate,
	         OI.[PriceVersion],
                 OI.[RevenueTierCode]            as [RevenueTierCode],
                 OI.[RevenueAccountCode]         as [RevenueAccountCode],
                 OI.[DeferredRevenueAccountCode] as [DeferredRevenueAccountCode],
                 OI.[RevenueRecognitionCode]     as [RevenueRecognitionCode],
                 OI.[TaxwareCode]                as [TaxwareCode],
                 OI.DefaultTaxwareCode           as [DefaultTaxwareCode],
                 0                               as [ShippingAndHandlingAmount],
                 OI.UnitOfMeasure,
                 OI.ReportingTypeCode,
                 OI.PricingTiers,
                 OI.Billtoaddresstypecode,
                 OI.BillToDeliveryOptionCode,
                 OI.Units,OI.Beds,OI.PPUPercentage
	      FROM   #TempOrderItem OI WITH (nolock) 
	      WHERE  exists (SELECT top 1 1 FROM #TEMPInvoiceGroupFinal TIGF WITH (nolock)
	                     WHERE TIGF.InvoiceIDSeq  = @LVC_InvoiceID
	                       AND OI.OrderIDSeq      = TIGF.OrderIDSeq
	                       AND OI.OrderGroupIDSeq = TIGF.OrderGroupIDSeq)
	      AND   OI.ChargeTypeCode  = 'ACS'   
              AND   OI.FrequencyCode   <> 'MN'             
	      AND   (OI.ActivationStartDate IS NOT  NULL)
              AND   OI.ProrateFirstMonthFlag = 1
              AND   OI.[LastBillingPeriodFromDate] is NULL
              AND   OI.[LastBillingPeriodToDate]   is NULL
              AND   DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
              ------------------------------
	      -- Access 
	      INSERT INTO #TEMPInvoiceItem
                                     (
                                       InvoiceIDSeq,
                                       OrderIDSeq,
                                       OrderGroupIDSeq,
                                       OrderItemIDSeq,
                                       OrderItemRenewalCount,
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
                                       Billtoaddresstypecode,
                                       BillToDeliveryOptionCode,
                                       Units,Beds,PPUPercentage
                                     )
	      SELECT @LVC_InvoiceID as InvoiceIDSeq,
                 OI.OrderIDSeq      as OrderIDSeq,
                 OI.OrderGroupIDSeq as OrderGroupIDSeq,
	         OI.OrderItemIDSeq  as OrderItemIDSeq,
                 OI.OrderItemRenewalCount as OrderItemRenewalCount,
                 OI.ProductCode,
                 OI.ChargeTypeCode,
                 OI.FrequencyCode,
                 OI.MeasureCode,
	         OI.Quantity,
                 OI.ChargeAmount               as ChargeAmount,
                 OI.EffectiveQuantity          as EffectiveQuantity,
                 OI.ExtChargeAmount            as ExtChargeAmount,
                 (OI.ExtChargeAmount 
                           -
                    (case when OI.ChargeTypeCode = 'ACS' and OI.FrequencyCode = 'YR' and @LI_Months <> 12                             
                           then  convert(numeric(30,2),(convert(float,(OI.NetChargeAmount*@LI_Months))/12))
                          else   convert(numeric(30,2),OI.NetChargeAmount)
                     end)
                 )                             as discountAmount, 
                 (case when OI.ChargeTypeCode = 'ACS' and OI.FrequencyCode = 'YR' and @LI_Months <> 12                             
                         then  convert(numeric(30,2),(convert(float,(OI.NetChargeAmount*@LI_Months))/12))
                       else   convert(numeric(30,2),OI.NetChargeAmount)
                  end)                           as NetChargeAmount,
	         OI.NewActivationStartDate       as BillingPeriodFromDate, 
	         OI.NewActivationEndDate         as BillingPeriodToDate,
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
                 OI.Billtoaddresstypecode,
                 OI.BillToDeliveryOptionCode,
                 OI.Units,OI.Beds,OI.PPUPercentage
	      FROM   #TempOrderItem OI WITH (nolock) 
	      WHERE  exists (SELECT top 1 1 FROM #TEMPInvoiceGroupFinal TIGF WITH (nolock)
	                     WHERE TIGF.InvoiceIDSeq  = @LVC_InvoiceID
	                       AND OI.OrderIDSeq      = TIGF.OrderIDSeq
	                       AND OI.OrderGroupIDSeq = TIGF.OrderGroupIDSeq
                             )
              AND   OI.ChargeTypeCode  = 'ACS'
              AND   OI.FrequencyCode   <> 'MN'  
	      AND  (OI.ActivationStartDate IS NOT  NULL) 
          --------------------------------------------------------------------------------------
	      -- Now Loop through the #TEMPInvoiceGroupFinal to populate Real Invoicing tables - 
	      -- Insert new InvoiceGroup Records FROM #TEMPInvoiceGroupFinal 
	      -- InvoiceItem Records FROM #TEMPInvoiceItem in a LOOP.
	      --------------------------------------------------------------------------------------
	      SELECT @LI_MIN = 1
	      SELECT @LI_MAX = count(SEQ) FROM #TEMPInvoiceGroupFinal WITH (nolock)
              WHILE  @LI_MIN <= @LI_MAX
	        BEGIN --> BEGIN for while loop - Invoice group
	          SELECT @LI_OrderIDSeq                   = OrderIDSeq,
	                 @LI_OrderGroupIDSeq              = OrderGroupIDSeq,
	                 @LVC_OrderGroupName              = Name,
	                 @LVC_CustomBundleNameEnabledFlag = CustomBundleNameEnabledFlag
	          FROM   #TEMPInvoiceGroupFinal WITH (nolock)
	          WHERE  SEQ = @LI_MIN
	          -------------------------BEGIN INSERT into Invoices.dbo.InvoiceGroup---------------------------
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

              -- Error Handling --
              SELECT @SQLErrorCode = @@Error 
	          IF @SQLErrorCode<> 0 
	            BEGIN 
		          SELECT @SQLErrorCode as SQLErrorCode, @LVC_InvoiceID as InvoiceID
		          EXEC   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SELECT/Generation of @LI_InvoiceGroupIDSeq Failed.' 
	            END				
		     -------------------------END INSERT Invoices.dbo.InvoiceGroup---------------------------
             -------------------------------------------------------------------------------------------------------------------------
	         -------------------------INSERT data INTO Invoices.dbo.Invoices table -------------------
	          IF (@LI_InvoiceGroupIDSeq <> -1)
	            BEGIN
	              INSERT INTO Invoices.dbo.InvoiceItem
                                                      (
                                                       InvoiceIDSeq, 
                                                       InvoiceGroupIDSeq,
                                                       OrderIDSeq,
                                                       OrderGroupIDSeq,
                                                       OrderItemIDSeq,
                                                       OrderItemRenewalCount,
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
                                                       Billtoaddresstypecode,
                                                       BillToDeliveryOptionCode, 
                                                       Units,Beds,PPUPercentage
                                                      )
	              SELECT InvoiceIDSeq, 
                         @LI_InvoiceGroupIDSeq as InvoiceGroupIDSeq,
	                 S.OrderIDSeq,
                         S.OrderGroupIDSeq,
                         S.OrderItemIDSeq,
                         S.OrderItemRenewalCount,
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
                         Billtoaddresstypecode,
                         BillToDeliveryOptionCode, 
                         Units,Beds,PPUPercentage
	              FROM   #TEMPInvoiceItem S WITH (nolock)      
	              WHERE  S.OrderIDSeq        = @LI_OrderIDSeq
	                AND  S.OrderGroupIDSeq   = @LI_OrderGroupIDSeq
	                AND  NOT exists (SELECT top 1 1 FROM Invoices.dbo.InvoiceItem DII WITH (nolock)
	                                 WHERE  DII.InvoiceGroupIDSeq = @LI_InvoiceGroupIDSeq
	                                 AND    DII.OrderIDSeq        = @LI_OrderIDSeq
	                                 AND    DII.OrderGroupIDSeq   = @LI_OrderGroupIDSeq      
	                                 AND    DII.OrderIDSeq        = S.OrderIDSeq
	                                 AND    DII.OrderGroupIDSeq   = S.OrderGroupIDSeq
	                                 AND    DII.OrderItemIDSeq    = S.OrderItemIDSeq
                                         AND    DII.OrderItemRenewalCount = S.OrderItemRenewalCount
	                                 AND    DII.ProductCode       = S.ProductCode
	                                 AND    DII.ChargeTypeCode    = S.ChargeTypeCode
	                                 AND    DII.FrequencyCode     = S.FrequencyCode
	                                 AND    DII.MeasureCode       = S.MeasureCode
	                                 AND    DII.BillingPeriodFromDate = S.BillingPeriodFromDate
	                                 AND    DII.BillingPeriodToDate   = S.BillingPeriodToDate) 
	            END
	        -------------------------------------------------------------------------------------
	        --- UPDATE Orders.DBO.OrderItem for LastBillingPeriodFromDate and LastBillingPeriodToDate	     
	        --  UPDATE the billing FROM and TO dates for ILF and ACCESS Annual for now.
            -------------------------------------------------------------------------------------
	        UPDATE OI 
	        SET   OI.LastBillingPeriodFromDate = (Case when OI.LastBillingPeriodFromDate is null 
                                                             then S.BillingPeriodFromDate
                                                           else OI.LastBillingPeriodFromDate
                                                      end),  
	              OI.LastBillingPeriodToDate   = S.BillingPeriodToDate
	        FROM  Orders.dbo.OrderItem OI WITH (nolock) 
	        INNER JOIN 
                      (Select X.OrderIDSeq,X.OrderGroupIDSeq,X.OrderItemIDSeq,X.OrderItemRenewalCount,
                              X.ChargeTypeCode,X.FrequencyCode,X.MeasureCode,X.ProductCode,
                              Min(X.BillingPeriodFromDate) as BillingPeriodFromDate,
                              Max(X.BillingPeriodToDate)   as BillingPeriodToDate
                       FROM  #TEMPInvoiceItem X WITH (nolock)
                       where X.OrderIDSeq         = @LI_OrderIDSeq
                       and   X.OrderGroupIDSeq    = @LI_OrderGroupIDSeq
                       group by X.OrderIDSeq,X.OrderGroupIDSeq,X.OrderItemIDSeq,X.OrderItemRenewalCount,
                                X.ChargeTypeCode,X.FrequencyCode,X.MeasureCode,X.ProductCode
                      ) S                        
	          ON    OI.OrderIDSeq         = @LI_OrderIDSeq
	          AND   OI.OrderGroupIDSeq    = @LI_OrderGroupIDSeq
                  AND   S.OrderIDSeq          = @LI_OrderIDSeq
	          AND   S.OrderGroupIDSeq     = @LI_OrderGroupIDSeq
	          AND   OI.OrderIDSeq         = S.OrderIDSeq
	          AND   OI.OrderGroupIDSeq    = S.OrderGroupIDSeq
	          AND   OI.IDSeq              = S.OrderItemIDSeq
	          AND   OI.ProductCode        = S.ProductCode
                  AND   OI.RenewalCount       = S.OrderItemRenewalCount
	          AND   OI.ChargeTypeCode     = S.ChargeTypeCode
	          AND   OI.FrequencyCode      = S.FrequencyCode
	          AND   OI.MeasureCode        = S.MeasureCode	        
	        WHERE   OI.OrderIDSeq         = @LI_OrderIDSeq
	        AND     OI.OrderGroupIDSeq    = @LI_OrderGroupIDSeq

	        SELECT @LI_MIN = @LI_MIN+1
          END --: END for while Loop

       END -- Processing completed for ILF,ACS
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
         
        select distinct SQLErrorcode,InvoiceID from #TEMP_InvoiceIDHoldingTable with (nolock)
        ---SELECT @SQLErrorcode as SQLErrorcode,@LVC_InvoiceID as InvoiceID
        -------------------------------------------------------------------------------------------------
        ---Final Cleanup
        -------------------------------------------------------------------------------------------------
        DROP TABLE #TEMPCompany
        DROP TABLE #TEMPProperty
        DROP TABLE #TEMPAccount
        DROP TABLE #TEMPAddress
        DROP TABLE #TEMPInvoiceGroup
        DROP TABLE #TEMPInvoiceGroupFinal
        DROP TABLE #TEMPInvoiceItem
        DROP TABLE #TEMPOrderItem
        DROP TABLE #TEMPAddrType_InvGroupNumber
        DROP TABLE #TEMP_InvoiceIDHoldingTable;
        -------------------------------------------------------------------------------------------------
END --: --: Main Procedure END
GO
