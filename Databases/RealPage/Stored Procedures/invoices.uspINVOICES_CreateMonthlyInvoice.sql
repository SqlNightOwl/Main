SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------
-- Database Name   : Invoices
-- Procedure Name  : [uspINVOICES_CreateMonthlyInvoice]
-- Description     : This procedure creates a new monthly Invoice for a given Account and Order
-- Input Parameters: @IPVC_QuoteID      as  VARCHAR(50)
--                   @IPVC_AccountID    as  VARCHAR(50) 
--                   @IPVC_CompanyID    as  VARCHAR(50)
--                   @IPVC_PropertyID   as  VARCHAR(50)
--                   @LBI_OrderID       as  VARCHAR(50)
-- Code Example    : 
--                  Exec Invoices.DBO.[uspINVOICES_CreateMonthlyInvoice]
-- 	                @IPVC_AccountID  = 'A0000000010',  
-- 	                @IPVC_CompanyID  = 'C0000003017',  
-- 	                @IPVC_PropertyID = 'P0000000026',
--                      @LBI_OrderID     = 70865   

-- 11/07/2011      : TFS 1514 : Transaction is moved to SP code from UI
----------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_CreateMonthlyInvoice] 
                                                   (
                                                     @IPVC_AccountID   VARCHAR(50),
                                                     @IPVC_CompanyID   VARCHAR(50),
                                                     @IPVC_PropertyID  VARCHAR(50)=NULL,
                                                     @LBI_OrderID      VARCHAR(50)
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
  DECLARE @LDT_TargetDate                  DATETIME
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
  DECLARE @LDT_ActivationStartDate         DATETIME
  DECLARE @LDT_NewActivationEndDate        DATETIME --Based on Gwen's Email
  DECLARE @LDT_MonthlyRecurringToDate      DATETIME --Based on Gwen's Email
  DECLARE @MonthlyInvoiceMinCount          BIGINT
  DECLARE @MontlyInvoiceMaxCount           BIGINT
  DECLARE @LDT_BillingPeriodFromDate       DATETIME
  DECLARE @LDT_BillingPeriodToDate         DATETIME
  DECLARE @LC_ChargeTypeCode               CHAR(3)
  DECLARE @LC_FrequencyCode                CHAR(6)
  DECLARE @LDT_BillingCycleDate            DATETIME
  -------------------------------------------------------------------------------------------------
  -- Declaring Variables for Error Handling 
  -------------------------------------------------------------------------------------------------
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
  --Declaring Local Temporary Tables 
  -------------------------------------------------------------------------------------------------  
  Create table #TEMPMonthlyInvoiceHoldingTable (IDSeq          int not null identity(1,1),
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
	                     [PropertyIDSeq]          [VARCHAR](22)           COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
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
                             OrderItemRenewalCount        INT              NOT NULL,                              
	                     [ProductCode]                [VARCHAR](30)    COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [ChargeTypeCode]             [CHAR](3)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [FrequencyCode]              [CHAR](6)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [MeasureCode]                [CHAR](6)        COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
	                     [Quantity]                   [decimal](18, 3) NOT NULL,	                      
	                     [ChargeAmount]               [MONEY]          NOT NULL,
	                     [EffectiveQuantity]          [decimal](18, 5),
	                     [ExtChargeAmount]            [MONEY]          NOT NULL,
	                     [DiscountAmount]             [MONEY]          NOT NULL,	                      
	                     [NetChargeAmount]            [MONEY]          NOT NULL,
	                     [BillingPeriodFromDate]      [DATETIME]       NOT NULL,
	                     [BillingPeriodToDate]        [DATETIME]           NULL,
                             [PriceVersion]               [numeric](18, 0)     NULL,
			     [RevenueTierCode]            [VARCHAR](50),
			     [RevenueAccountCode]         [VARCHAR](50),
			     [DeferredRevenueAccountCode] [VARCHAR](50),
			     [RevenueRecognitionCode]     [VARCHAR](50),
			     [TaxwareCode]                [VARCHAR](50),
                             [DefaultTaxwareCode]         [VARCHAR](50),
			     [ShippingAndHandlingAmount]  [MONEY]          NOT NULL,  
                             [UnitOfMeasure]              [decimal](18, 5),
                             [ReportingTypeCode]          [VARCHAR](4),
                             [PricingTiers]               [INT],
                             [BillToAddressTypeCode]      [VARCHAR](20),
                             [BillToDeliveryOptionCode]   [VARCHAR](20),
                             [Units]                      [INT],
                             [Beds]                       [INT],
                             [PPUPercentage]              [INT]
                          ) 
  -- *** used to identify order line items for invoicing *** -- 
  CREATE TABLE #TEMPOrderItem  
                         (	
                             [InvoiceIDSeq]               [VARCHAR](22),
                             [OrderItemIDSeq]             [BIGINT]      NOT NULL,
                             [OrderIDSeq]                 [VARCHAR](50) NOT NULL,
                             [OrderGroupIDSeq]            [BIGINT]      NOT NULL,
                             OrderItemRenewalCount        INT           NOT NULL,
                             [ProductCode]                [CHAR](30), 
                             [ChargeTypeCode]             [CHAR](3),
                             [FrequencyCode]              [CHAR](6), 
                             [MeasureCode]                [CHAR](6),
                             [PlatFormCode]               varchar(5), 
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
                             [ShippingAndHandlingAmount]  [MONEY]         NOT NULL,
                             [UnitOfMeasure]              [decimal](18, 5),           -- Newly added for the upcoming enhancement
                             [SeparateInvoiceGroupNumber] [BIGINT],                   -- Newly added for the upcoming enhancement
			     [ReportingTypeCode]          [VARCHAR](4),               -- Newly added for the upcoming enhancement
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
         ,@LC_ChargeTypeCode            = 'ACS'
         ,@LC_FrequencyCode             = 'MN'
  -----------------------------------------------------------------------------------------------------------     
  ---Initialization of Input Parameters if not passed
  ----------------------------------------------------------------------------------------------------------- 
  IF (@IPVC_PropertyID IS NULL or @IPVC_PropertyID = '')  --When PropertyIDSeq is not supplied as parameter.
  BEGIN
    SELECT @IPVC_PropertyID = (SELECT PropertyIDSeq FROM Orders.dbo.[Order] WITH (NOLOCK) WHERE OrderIDSeq=@LBI_OrderID)
  END

  SELECT TOP 1 @LDT_BillingCycleDate = BillingCycleDate
  FROM   INVOICES.dbo.InvoiceEOMServiceControl with (nolock)
  WHERE  BillingCycleClosedFlag = 0
  ------------------------------------------------------------------------------------------------------------------- 
  -- Retrieving the count of line items (get line items WITH dates) that will be Inserted INTO #TEMPOrderItem table - 
  -- IF 0 order items were found, then quit the procedure (Nothing to process).
  -------------------------------------------------------------------------------------------------------------------
  SELECT  @LI_OrderLineItemCount = Count(DISTINCT OI.IDSeq)
  FROM    Orders.dbo.OrderItem OI WITH (nolock)
  inner Join
          Products.dbo.Charge C with (nolock)
  on      OI.ProductCode       = C.ProductCode
  and     OI.PriceVersion      = C.PriceVersion
  and     OI.ChargeTypeCode    = C.ChargeTypeCode
  and     OI.MeasureCode       = C.MeasureCode
  and     OI.FrequencyCode     = C.FrequencyCode
  and     OI.OrderIDSeq        = @LBI_OrderID    
  AND     OI.ChargeTypeCode    = @LC_ChargeTypeCode   -- always 'ACS'
  AND     OI.FrequencyCode     = @LC_FrequencyCode    -- always 'MN'
  AND     OI.StatusCode        <> 'EXPD'
  AND     OI.MeasureCode       <> 'TRAN'
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
             and OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  = 'MN'
           ) 
           OR
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NOT NULL
             and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.EndDate)
             and  OI.LastBillingPeriodToDate < BTM.TargetDate
             and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  = 'MN'
            )            
       )       
  ----------------------------------- 
    
  ------------------------------------------------------
  -- Error Handling - 
  SELECT @SQLErrorCode = @@Error

  IF (@SQLErrorCode <> 0) -- sql Error occured. 
    BEGIN 
      SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured, @LI_OrderLineItemCount variable could not be populated' 
      Return
    END  
  -------------------------------------------------------------------------------------------------
  -- IF 0 order items were found, then quit the procedure.
  -------------------------------------------------------------------------------------------------
--  IF @LI_OrderLineItemCount = 0 
--    BEGIN 
--       Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = '@LI_OrderLineItemCount is 0, No line Items to Process.'
--       Return -- There is nothing to process.
--    END 
  --------------------------------------------------------------------------------------------------------------------
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
    AND OI.ChargeTypeCode = @LC_ChargeTypeCode   -- always 'ACS'
    AND OI.FrequencyCode  = @LC_FrequencyCode    -- always 'MN'
    AND OI.StatusCode     <> 'EXPD'
    AND OI.MeasureCode    <> 'TRAN'
    AND OI.BillToAddressTypeCode IS NOT NULL
    -----------------------------------
    AND   OI.DoNotInvoiceFlag    = 0
    ----------------  
    Inner Join
          INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
    on    C.LeadDays           = BTM.LeadDays
    and   BTM.BillingCycleDate = @LDT_BillingCycleDate
    ----------------
    and  (
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NULL
             and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  = 'MN'
           ) 
           OR
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NOT NULL
             and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.EndDate)
             and  OI.LastBillingPeriodToDate < BTM.TargetDate
             and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  = 'MN'
            )            
        )   
  ----------------  
    -----------------------------------                                         --get Access that has dates.
    GROUP BY OI.IDSeq,OrderGroupIDSeq,OI.BillToAddressTypeCode,OI.BillToDeliveryOptionCode,C.SeparateInvoiceGroupNumber,CONVERT(INT,C.MarkAsPrintedFlag),FAM.EpicorPostingCode,FAM.TaxwareCompanyCode,PRD.PrePaidFlag
    ORDER BY OI.IDSeq,OrderGroupIDSeq,OI.BillToAddressTypeCode,OI.BillToDeliveryOptionCode,C.SeparateInvoiceGroupNumber,CONVERT(INT,C.MarkAsPrintedFlag),FAM.EpicorPostingCode,FAM.TaxwareCompanyCode,PRD.PrePaidFlag
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
                    CONVERT(INT,C.MarkAsPrintedFlag),
                    (Case when Max(Convert(int,OG.CustomBundleNameEnabledFlag)) = 1 then NULL
                          else Max(OI.FamilyCode)
                     end)       as SeparateInvoiceProductFamilyCode,
                    FAM.EpicorPostingCode,
                    FAM.TaxwareCompanyCode,
                    PRD.PrePaidFlag
    FROM            Orders.dbo.OrderItem OI     WITH (nolock)
    Inner Join
                    Orders.dbo.[OrderGroup] OG with (nolock)
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
    AND OI.ChargeTypeCode = @LC_ChargeTypeCode   -- always 'ACS'
    AND OI.FrequencyCode  = @LC_FrequencyCode    -- always 'MN'
    AND OI.StatusCode     <> 'EXPD'
    AND OI.MeasureCode    <> 'TRAN'
    AND OI.BillToAddressTypeCode IS NOT NULL
    -----------------------------------
    AND   OI.DoNotInvoiceFlag    = 0
    ----------------  
    Inner Join
          INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
    on    C.LeadDays           = BTM.LeadDays
    and   BTM.BillingCycleDate = @LDT_BillingCycleDate
    ----------------
    and  (
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NULL
             and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  = 'MN'
           ) 
           OR
           ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
             and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NOT NULL
             and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.EndDate)
             and  OI.LastBillingPeriodToDate < BTM.TargetDate
             and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  = 'MN'
            )            
        )   
   ----------------   
    GROUP BY OI.IDSeq,OI.OrderGroupIDSeq,OI.BillToAddressTypeCode,OI.BillToDeliveryOptionCode,C.SeparateInvoiceGroupNumber,CONVERT(INT,C.MarkAsPrintedFlag),
             OG.IDSeq,FAM.EpicorPostingCode,FAM.TaxwareCompanyCode,PRD.PrePaidFlag
    ORDER BY OI.IDSeq,OI.OrderGroupIDSeq,OI.BillToAddressTypeCode,OI.BillToDeliveryOptionCode,C.SeparateInvoiceGroupNumber,CONVERT(INT,C.MarkAsPrintedFlag),FAM.EpicorPostingCode,FAM.TaxwareCompanyCode,PRD.PrePaidFlag
  end  
  -------------------------------------------------------------------------------------------------
  -- Now Starting the loop to INSERT the data INTO all temp tables
  -------------------------------------------------------------------------------------------------
  SELECT @LI_MinValue = 1
  SELECT @LI_MaxValue = count(SEQ) FROM #TEMPAddrType_InvGroupNumber WITH (nolock)

  WHILE  @LI_MinValue <= @LI_MaxValue --Parent while loop Start
    BEGIN --> BEGIN for while loop - AddressType AND InvoiceGroupNumber
      ---------------------------------------------------------------------------------------------------------------------
      -- Retrieving 1st row OrderItemIDSeq,BillToAddressTypeCode,SeparateInvoiceGroupNumber and MarkAsPrintedFlag values 
      -- FROM #TEMPAddrType_InvGroupNumber table
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
      -- Populating table #TEMPOrderItem
      -- based on @LBI_OrderID,@LVBI_OrderItemIDSeq,@LVC_BillToAddressTypeCode,
      -- @LVBI_SeparateInvoiceGroupNumber AND @LVB_MarkAsPrintedFlag values 
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
                      [BillToAddressTypeCode],
                      [BillToDeliveryOptionCode],
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
                     coalesce(OI.CancelDate,OI.[ILFEndDate]),
                     OI.[ActivationStartDate],
                     coalesce(OI.CancelDate,OI.[ActivationEndDate]),
                     OI.[StatusCode], 
                     OI.[StartDate],
                     coalesce(OI.CancelDate,OI.[EndDate]),
                     OI.[LastBillingPeriodFromDate],
                     OI.[LastBillingPeriodToDate],
                     OI.BillToAddressTypeCode,
                     OI.BillToDeliveryOptionCode,
                     OI.[CancelDate],
                     OI.[CapMaxUnitsFlag],
                     NULL         as [NewActivationStartDate], 
                     NULL         as [NewActivationEndDate],
                     O.[AccountIDSeq],
                     O.[QuoteIDSeq],
                     NULL         as [NewILFStartDate],
                     NULL         as [NewILFEndDate],
                     O.[StatusCode]  as [OrderstatusCode],
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
                     BTM.Targetdate
          FROM       Orders.dbo.OrderItem OI WITH (nolock)
          INNER JOIN 
                     Orders.dbo.[Order] O    WITH (nolock)
              ON     OI.OrderIDSeq  = O.OrderIDSeq 
              AND    OI.BillToAddressTypeCode = @LVC_BillToAddressTypeCode
              AND    OI.BillToDeliveryOptionCode = @LVC_BillToDeliveryOptionCode
              AND    OI.FamilyCode            = coalesce(@LVC_SeparateInvoiceProductFamilyCode,OI.FamilyCode)
              AND    OI.StatusCode    <>  'EXPD'             
              AND    OI.MeasureCode   <> 'TRAN'      
              -----------------------------------
              AND   OI.DoNotInvoiceFlag    = 0              
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
              AND    OI.ChargeTypeCode = @LC_ChargeTypeCode   -- always 'ACS'
              AND    OI.FrequencyCode  = @LC_FrequencyCode    -- always 'MN'
              AND    OI.StatusCode    <> 'EXPD'
              AND    OI.MeasureCode   <> 'TRAN'            
              AND    C.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
          Inner Join
                 INVOICES.dbo.BillingTargetDateMapping BTM with (nolock)
          on      C.LeadDays           = BTM.LeadDays
          and     BTM.BillingCycleDate = @LDT_BillingCycleDate
          ----------------
         and  (
                ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
                  and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NULL
                  and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  = 'MN'
                ) 
                 OR
                ((OI.StartDate <> Coalesce(OI.canceldate,'')) and (coalesce(OI.Canceldate,OI.StartDate) >= OI.StartDate) 
                  and OI.EndDate is NOT NULL and (OI.StartDate  <= BTM.TargetDate) and OI.LastBillingPeriodToDate is NOT NULL
                  and  OI.LastBillingPeriodToDate < Coalesce(OI.canceldate,OI.EndDate)
                  and  OI.LastBillingPeriodToDate < BTM.TargetDate
                  and  OI.ChargeTypeCode = 'ACS' and OI.Frequencycode  = 'MN'
                )            
              ) 
          WHERE      OI.OrderIDSeq                = @LBI_OrderID 
              AND    OI.IDSeq                     = @LVBI_OrderItemIDSeq
              AND    OI.BillToAddressTypeCode     = @LVC_BillToAddressTypeCode
              AND    OI.BillToDeliveryOptionCode = @LVC_BillToDeliveryOptionCode
              AND    OI.FamilyCode                = coalesce(@LVC_SeparateInvoiceProductFamilyCode,OI.FamilyCode)
              and    FAM.EpicorPostingCode        = @LVC_EpicorPostingCode
              and    FAM.TaxwareCompanyCode       = @LVC_TaxwareCompanyCode 
              AND    C.SeparateInvoiceGroupNumber = @LVBI_SeparateInvoiceGroupNumber
              and    P.PrePaidFlag                = @LI_PrePaidFlag
              AND    OI.StatusCode    <> 'EXPD'
              AND    OI.MeasureCode   <> 'TRAN'   
              -----------------------------------
              AND   OI.DoNotInvoiceFlag    = 0              
              ----------------------------------- 
        END  -- END of Insertion of data INTO  #TEMPOrderItem

      -- Error Handling --
      SELECT @SQLErrorcode = @@Error, @SQLRowCount = @@rowcount
      IF @SQLErrorCode <> 0 
        BEGIN 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured, INSERT INTO #TempOrderItem table failed.' 
          Return  -- quit procedure! 
        END
      ---------------------------------------------------------------------------------------------------------------------------
      --ACCESS - Validation Query to check for following - 
          --a. IF both ActivationStartDate AND ActivationEndDate are populated on the order line item. 
          --b. IF dates are entered correctly  (for example - END date should not be less than the start date)
          -- This is precautionary (dates should NOT be missing since @LI_OrderLineItemCount is already checked WHEN populating) 
      ---------------------------------------------------------------------------------------------------------------------------
      -- IF Activation start date is missing - 
      IF Exists (SELECT ActivationStartDate 
                 FROM   #TEMPOrderItem WITH (nolock)
                 WHERE (ActivationStartDate IS NULL or ActivationStartDate = '') AND ChargeTypeCode = 'ACS')
        BEGIN
          SELECT 0 as SQLErrorCode, @LVC_InvoiceID as InvoiceID
          EXEC   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'ActivationStartDate IS NOT  populated for access OrderItemIDSeq' 
          RETURN -- quit procedure! 
        END 
      -- IF Activation end date is missing - 
      IF Exists (SELECT ActivationEndDate 
                 FROM   #TEMPOrderItem WITH (nolock)
                 WHERE (ActivationEndDate IS NULL or ActivationEndDate = '') AND ChargeTypeCode = 'ACS')
        BEGIN 
          SELECT 0 as SQLErrorCode, @LVC_InvoiceID as InvoiceID
          EXEC   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'ActivationEndDate IS NOT  populated for access OrderItemIDSeq' 
          RETURN -- quit procedure! 
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
      ---------------------------------------------------------------------------------------------------------------------------
      ---Step 2 for ACS : SET the appropriate Activation start and Activation end dates for billing purposes. 
      --user could have entered Activation start date = 01/15/2007 & Activation end date = 1/15/2008
      --For billing purposes, a new Activation start date (ACS) and end date would be 01/01/2007 thru 01/31/2008 for NON-LEGACY family. 
      --For billing purposes, a new Activation start date (ACS) and end dates would be 01/15/2007 thru 01/15/2008 for LEGACY family.
      --for non-legacy family, SET the Activation start date as the first day of the Month.
      ---------------------------------------------------------------------------------------------------------------------------      
      --to populate NewActivationStartDate column in #TEMPOrderItem table
      IF exists (SELECT top 1 * FROM #TempOrderItem WITH (nolock) WHERE ChargeTypeCode = 'ACS')
        BEGIN 
          UPDATE OI 
          SET  NewActivationStartDate = CASE WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG' AND datepart(dd,ActivationStartDate) <> '01')
                                              THEN Invoices.DBO.fn_SetFirstDayOfFollowingMonth(ActivationStartDate) 
                                             WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG' AND datepart(dd,ActivationStartDate) = '01')
                                              THEN ActivationStartDate 
	                                       ELSE 
                                            ActivationStartDate 
                                       END 
          FROM #TEMPOrderItem OI WITH (nolock)
          WHERE  OI.ChargeTypeCode = 'ACS'    

          DELETE FROM #TEMPOrderItem 
          where ChargeTypeCode = 'ACS' and FrequencyCode = 'MN' 
          and   NewActivationStartDate > TargetDate
          and   ProrateFirstMonthFlag  = 0      

          DELETE FROM #TEMPOrderItem 
          where ChargeTypeCode = 'ACS' and FrequencyCode = 'MN' 
          and   StartDate > TargetDate
          and   ProrateFirstMonthFlag  = 1  
        END
      -- Error Handling -- 
      SELECT @SQLErrorCode = @@Error
      IF @SQLErrorCode <> 0
        BEGIN 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured,UPDATE to populate NewActivationStartDate column in #TEMPOrderItem table failed.' 
          Return -- quit procedure! 
        END 
       --to populate NewActivationEndDate column in #TEMPOrderItem table
      IF exists (SELECT top 1 * FROM #TempOrderItem WITH (nolock) WHERE ChargeTypeCode = 'ACS')
        BEGIN 
          UPDATE OI 
          SET NewActivationEndDate = CASE WHEN (Platformcode <> 'PRM' and FamilyCode <> 'LEG')
                                THEN Invoices.DBO.fn_SetLastDayOfMonth(ActivationEndDate)
--                                  CASE WHEN datepart(dd, ActivationEndDate) = '01' 
--                                       THEN Invoices.DBO.fn_SetLastDayOfPreviousMonth(ActivationEndDate)
--                                       ELSE Invoices.DBO.fn_SetLastDayOfMonth(ActivationEndDate) END
	                            ELSE ActivationEndDate --for legacy family, we want to keep the dates as is.
                                  END     
          FROM #TEMPOrderItem OI WITH (nolock)
          WHERE  OI.ChargeTypeCode = 'ACS' 
          -----------------------------
          UPDATE OI
          SET    NewActivationEndDate = (CASE when NewActivationEndDate < NewActivationStartDate
                                                then Invoices.DBO.fn_SetLastDayOfMonth(NewActivationStartDate)
                                             else NewActivationEndDate
                                         end)
          FROM #TEMPOrderItem OI WITH (nolock)
          WHERE  OI.ChargeTypeCode = 'ACS'
        END
      -- Error Handling -- 
      SELECT @SQLErrorCode = @@Error
      IF @SQLErrorCode <> 0
        BEGIN 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured in updating NewActivationEndDate colum in #TEMPOrderItem table.' 
          Return -- quit procedure! 
        END 
      ---------------------------------------------------------------------------------------------------------------------------
      ---Validation query to see IF any of eligible OrderItems have been billed before. 
      -- IF these have been billed before, then flag an Error because this should be a new order AND there should NOT be any 
      -- order items that are billed so far. 
      -- ELSE proceed to creating Invoice for these order items. 
      ---------------------------------------------------------------------------------------------------------------------------
      IF exists (SELECT top 1 * 
                 FROM #TempOrderItem OI WITH (nolock) 
                 WHERE OI.LastBillingPeriodFromDate IS NOT NULL AND OI.LastBillingPeriodToDate IS NOT NULL)
      SELECT @SQLErrorCode = @@Error
      IF @SQLErrorCode <> 0 
        BEGIN 
          SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'Check LastBillingPeriodFromDate AND LastBillingPeriodToDate columns in Orders.dbo.OrderItem table' 
          Return -- quit procedure! 
        END
      -----------------  
      --ACCESS MONTHLY
      -----------------
      SELECT @LI_MonthlyLineItemCount =  ISNULL  (datedIFf(MM, CASE WHEN OI.LastBillingPeriodFromDate IS NULL 
                                                                     THEN (Case when OI.proratefirstmonthFlag = 1 
                                                                                   then OI.StartDate  
                                                                                 else OI.NewActivationStartDate
                                                                            end)  
              						            ELSE OI.LastBillingPeriodFromDate  END
                                                 ,Invoices.DBO.fn_SetFirstDayOfFollowingMonth(OI.TargetDate)),0) + 1
      FROM   #TEMPOrderItem OI WITH (nolock)
      WHERE  OI.ChargeTypeCode  = 'ACS' AND OI.FrequencyCode = 'MN'
        AND (     (OI.LastBillingPeriodFromDate IS NULL  AND LastBillingPeriodToDate IS NULL  ) -- a new order.
              AND (OI.NewActivationStartDate IS NOT NULL AND 
                   (Case when OI.proratefirstmonthFlag = 1 
                                then OI.StartDate  
                              else OI.NewActivationStartDate
                         end) <= OI.TargetDate)
            )
      -------------------------------------------------------------------------------------------------
      ---Step 1 : Create Invoice IF there are items to process, ELSE quit.
      ---         Get Latest InvoiceID WITH PrintFlag=0 IF ONe exist for the @IPVC_AccountID,@LVC_BillToAddressTypeCode 
      ---         AND @LVBI_SeparateInvoiceGroupNumber ELSE Generate New InvoiceID 
      -------------------------------------------------------------------------------------------------
      IF (@LI_MonthlyLineItemCount = 0) 
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
                       BEGIN TRANSACTION CMTHI; 
      	                 UPDATE Invoices.DBO.IDGenerator WITH (TABLOCKX,XLOCK,HOLDLOCK)
	                 SET    IDSeq = IDSeq+1,
	                        GeneratedDate =CURRENT_TIMESTAMP
                         WHERE  TypeIndicator = 'I'      
	
	                 SELECT @LVC_InvoiceID = IDGeneratorSeq
	                 FROM   Invoices.DBO.IDGenerator WITH (NOLOCK)
                         WHERE  TypeIndicator  = 'I'
                      COMMIT TRANSACTION CMTHI;
                     end TRY
                     begin CATCH    
                       if (XACT_STATE()) = -1
                       begin
                         IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION CMTHI;
                       end
                       else 
                       if (XACT_STATE()) = 1
                       begin
                         IF @@TRANCOUNT > 0 COMMIT TRANSACTION CMTHI;
                       end  
                       IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION CMTHI;

                       SELECT 0 as SQLErrorcode, 'ABCDEFGHIJK' as InvoiceID --> Dummy Returned to UI when Error Occurred
                       Return; -- There IS nothing to process.
                      end CATCH;
	          END
                  ----------------------------------------------
                  Insert into #TEMPMonthlyInvoiceHoldingTable(SQLErrorcode,InvoiceID)
                  select @SQLErrorCode as SQLErrorcode,@LVC_InvoiceID as InvoiceID 
                  ----------------------------------------------
        -- Error Handling -- WHEN SELECT/InvoiceID Generation fails-- 
        SELECT @SQLErrorCode = @@Error	
        IF @SQLErrorCode <> 0 
           BEGIN 
             SELECT @SQLErrorCode as SQLErrorCode, @LVC_InvoiceID as InvoiceIDSeq
             Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'New InvoiceID Gen: New InvoiceID Generation failed for uspInvoices_CreateInvoice'  
             Return
           END
         END -- Create InvoiceIDSeq - END
      -------------------------------------------------------------------------------------------------
      ---Step 2 : Load all temp tables - 
      -------------------------------------------------------------------------------------------------
      IF ( @LI_MonthlyLineItemCount <> 0 ) 
        BEGIN -- process monthly ACS 
	      --------------------------------------------------------
	      ---Company  (Insert data into #TEMPCompany) - Start
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
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured while Inserting data into #TEMPCompany table' 
	          Return -- quit procedure! 
	        END 	     
          IF @SQLRowCount = 0 
	        BEGIN
              SELECT  0 as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
 	          Exec    CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'Company was not found in customers.dbo.company table for AccountIDSeq.' 
	          Return -- quit procedure! 
	        END 
          --------------------------------------------------------
          ---Company  (Insert data into #TEMPCompany) - END
          --------------------------------------------------------
          --------------------------------------------------------
          -- Account (Insert data into #TEMPAccount table) -Start
          --------------------------------------------------------
          IF (@LVC_AccountTypeCode = 'AHOFF')
	         BEGIN
	           SELECT Top 1 @LI_PriceTerms= priceterm FROM #TEMPCompany WITH (nolock)
	         END
	      ELSE
	         BEGIN
	           SELECT Top 1 @LI_PriceTerms= priceterm FROM #TEMPProperty WITH (nolock)
	         END
	
          -- Insertion INTO #TEMPAccount Begins
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
           -- Insertion INTO #TEMPAccount ENDs

          -- Error Handling --
	      SELECT @SQLErrorCode = @@Error, @SQLRowCount = @@rowcount

	      IF @SQLErrorCode <> 0 
	        BEGIN 
              SELECT @SQLErrorCode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
 	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured while trying to INSERT account data INTO #TEMPAccount table.' 
	          Return -- quit procedure! 
	        END 	     
 
	      IF @SQLRowCount = 0 
	        BEGIN 
              SELECT 0 as SQLErrorcode,@LVC_InvoiceID as InvoiceID  
 	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'Account was NOT found in customers.dbo.account table for AccountIDSeq.' 
	          Return -- quit procedure! 
	        END  	   

          SELECT @LVC_EpicorCustomerCode = EpicorCustomerCode,
                 @LVC_AccountTypeCode    = AccountTypeCode	             
 	      FROM   #TEMPAccount WITH (nolock)	 
	       
	      IF @LVC_AccountTypeCode IS NULL   
	        BEGIN 
              SELECT 0 as SQLErrorcode, @LVC_InvoiceID as InvoiceID
 	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'AccountTypeCode IS NOT  found for accountIDSeq' 
	          Return -- quit procedure! 
	      END
	      --------------------------------------------------------
	      -- Account (Insert data into #TEMPAccount table) - END
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
                    #TEMPAccount A            WITH (nolock)
		    ON  P.IDSeq = A.propertyIDSeq
          WHERE A.IDSeq = @IPVC_AccountID

          -- Error Handling --
	      SELECT @SQLErrorCode = @@Error
	      IF @SQLErrorCode <> 0 
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured while trying to locate a property for AccountIDSeq' 
	          Return -- quit procedure! 
	        END 
	      --------------------------------------------------------
	      ---Property  (Insert data into #TEMPProperty) - END
	      --------------------------------------------------------
	      --------------------------------------------------------
	      ---Accounts Billing Address - Start 
	      -- Insert into #TEMPAddress table
	      --(Account could be a Company or a Property)
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
       

          -- Error Handling -- 
          SELECT @SQLErrorCode = @@Error, @SQLRowCount = @@rowcount
          IF @SQLErrorCode <> 0 
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured while trying to locate a billing address for AccountIDSeq' 
	          Return -- quit procedure! 
	        END 
	
          IF @SQLRowCount = 0 
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
 	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'Billing addresses were NOT found for AccountIDSeq' 
	          Return -- quit procedure! 
	        END 
	      --------------------------------------------------------
	      ---Accounts Billing Address - END 
	      -- Insert into #TEMPAddress table
	      --(Account could be a Company or a Property)
	      --------------------------------------------------------
	      --------------------------------------------------------
	      ---Accounts SHIPPING Address - Start 
	      -- Insert into #TEMPAddress table
	      --(Account could be a Company or a Property)
	      --------------------------------------------------------
	      --- IF account type is a property then load property's billing address. 
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
               SELECT Top 1 AD.IDSeq,
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
               SELECT  top 1  AD.IDSeq,
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
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured while trying to locate a Shipping address for AccountIDSeq' 
	          Return -- quit procedure! 
	        END 

          IF @SQLRowCount = 0 
	        BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID 
	          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'Shipping Address NOT found.' 
	          Return -- quit procedure! 
	        END 
	      --------------------------------------------------------
	      ---Accounts SHIPPING Address - END 
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
	                                     TransactiONChargeAmount,
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
	      	                             BillToAttentiONName,
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
	            Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured, INSERT INTO Invoices.dbo.Invoice table failed.' 
	            Return -- quit procedure! 
	          END 
          --------------------------------------------------------------------------------------
	      --- Populate #TEMPInvoiceGroup AND #TEMPInvoiceGroupFinal tables - Start
	      --------------------------------------------------------------------------------------
	      --------------------  
	      --New Monthly Access 
	      --------------------
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
	         AND (OI.NewActivationStartDate IS NOT NULL AND OI.LastBillingPeriodToDate IS NULL  ) --should always be a new access
          ------------------------------------------------------------------------------------
	      -- Get distinct List of InvoiceGroup records into #TEMPInvoiceGroupFinal.
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
	          --EXEC   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured, INSERT INTO #TEMPInvoiceGroupFinal table - failed' 
	          RETURN -- quit procedure.
	        END	

          IF @SQLRowCount = 0 
            BEGIN 
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
              --EXEC CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'No data was inserted into #TEMPInvoiceGroupFinal table.' 
              RETURN -- quit procedure.
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
	          --Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SQL Error occured, unable to SELECT data FROM #TEMPInvoiceGroupFinal table.' 
	          Return -- quit procedure.
	        END	   
	      --------------------------------------------------------------------------------------
	      --- Populate #TEMPInvoiceGroup AND #TEMPInvoiceGroupFinal tables - END
	      --------------------------------------------------------------------------------------

          --------------------------------------------------------------------------------------
	      --- Populate data INTO #TEMPInvoiceItem table - Start 
	      --------------------------------------------------------------------------------------
          --------------------------------------------------------------------------------------
          -- It creates first monthly invoice if that order item has not been billed yet 
          -- otherwise, it stores that last billing start and end dates for further checking and
          -- it will create following month's monthly bills if applicable.
          --------------------------------------------------------------------------------------
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
                       (CASE WHEN ChargeTypeCode = 'ACS' and FrequencyCode = 'YR' and DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
                               THEN  convert(numeric(30,2), 
                                               (convert(float,OI.NetChargeAmount) * DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate))
                                                 /
                                               (convert(float,INVOICES.dbo.fn_GetNumDaysInYear(OI.ActivationStartDate)))
                                             )
                             WHEN ChargeTypeCode = 'ACS' and FrequencyCode = 'MN' and DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
                               THEN  convert(numeric(30,2), 
                                               (convert(float,OI.NetChargeAmount) * DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate))
                                                 /
                                               (convert(float,INVOICES.dbo.fn_GetNumDaysInMonth(OI.ActivationStartDate)))
                                            )
                             else 0.00
                       end)
                 )                             as  DiscountAmount,
                (CASE WHEN ChargeTypeCode = 'ACS' and FrequencyCode = 'YR' and DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
                        THEN  convert(numeric(30,2), 
                                               (convert(float,OI.NetChargeAmount) * DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate))
                                                 /
                                               (convert(float,INVOICES.dbo.fn_GetNumDaysInYear(OI.ActivationStartDate)))
                                      )
                        WHEN ChargeTypeCode = 'ACS' and FrequencyCode = 'MN' and DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
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
              AND   OI.FrequencyCode   = 'MN'             
	      AND   (OI.ActivationStartDate IS NOT  NULL)
              AND   OI.ProrateFirstMonthFlag = 1
              AND   OI.[LastBillingPeriodFromDate] is NULL
              AND   OI.[LastBillingPeriodToDate]   is NULL
              AND   DATEDIFF(day,OI.ActivationStartDate,OI.NewActivationStartDate) > 0
              --------------------------------------
              DELETE FROM #TEMPOrderItem 
              where ChargeTypeCode = 'ACS' and FrequencyCode = 'MN' 
              and   NewActivationStartDate > TargetDate

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
	      SELECT @LVC_InvoiceID       as InvoiceIDSeq,
                 OI.OrderIDSeq            as OrderIDSeq,
                 OI.OrderGroupIDSeq       as OrderGroupIDSeq,
	         OI.OrderItemIDSeq        as OrderItemIDSeq,
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
                 case when OI.LastBillingPeriodFromDate is null then OI.NewActivationStartDate
                     else OI.LastBillingPeriodFromDate
                 end                                                  as BillingPeriodFromDate,  
                 case when OI.LastBillingPeriodToDate is null   then Invoices.dbo.fn_SetLastDayOfMonth(isnull(OI.LastBillingPeriodFromDate,NewActivationStartDate))
                     else OI.LastBillingPeriodToDate
                 end                                                  as BillingPeriodToDate,
	             OI.PriceVersion,
                 OI.RevenueTierCode            as RevenueTierCode,
                 OI.RevenueAccountCode         as RevenueAccountCode,
                 OI.DeferredRevenueAccountCode as DeferredRevenueAccountCode,
                 OI.RevenueRecognitionCode     as RevenueRecognitionCode,
                 OI.TaxwareCode                as TaxwareCode,
                 OI.DefaultTaxwareCode         as DefaultTaxwareCode,
                 OI.ShippingAndHandlingAmount  as ShippingAndHandlingAmount,
                 OI.UnitOfMeasure,
                 OI.ReportingTypeCode,
                 OI.PricingTiers,
                 OI.Billtoaddresstypecode,
                 OI.BillToDeliveryOptionCode,
                 Units,Beds,PPUPercentage
	      FROM   #TempOrderItem OI WITH (nolock) 
	      WHERE  exists (SELECT top 1 1 FROM #TEMPInvoiceGroupFinal TIGF WITH (nolock)
	                     WHERE TIGF.InvoiceIDSeq  = @LVC_InvoiceID
	                       AND OI.OrderIDSeq      = TIGF.OrderIDSeq
	                       AND OI.OrderGroupIDSeq = TIGF.OrderGroupIDSeq)

          --------------------------------------------------------------------------------------
	  --Now set the LastBillingPeriodFromDate on OrderItem table here
	  --------------------------------------------------------------------------------------           
          UPDATE OI 
	  SET    OI.LastBillingPeriodFromDate = (Case when OI.LastBillingPeriodFromDate is null 
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
	 WHERE OI.OrderIDSeq         = @LI_OrderIDSeq
	 AND   OI.OrderGroupIDSeq    = @LI_OrderGroupIDSeq

          -- Error Handling --
          SELECT @SQLErrorCode = @@error
          IF @SQLErrorCode <> 0
            BEGIN
              SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
              EXEC CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'LastBillingPeriodFromDate column update failed on #TEMPOrderItem.'
            END
          --------------------------------------------------------------------------------------
	      --- Now Loop through the #TEMPInvoiceGroupFinal to populate Real Invoicing tables - 
	      -- Insert New InvoiceGroup Records FROM #TEMPInvoiceGroupFinal 
	      -- InvoiceItem Records FROM #TEMPInvoiceItem in a LOOP.
	      --------------------------------------------------------------------------------------
	      SELECT @LI_MIN = 1
	      SELECT @LI_MAX = count(SEQ) FROM #TEMPInvoiceGroupFinal WITH (nolock)
              WHILE  @LI_MIN <= @LI_MAX
	        BEGIN --> BEGIN for while loop - Invoice group
	          SELECT @LI_OrderIDSeq=OrderIDSeq
	                ,@LI_OrderGroupIDSeq=OrderGroupIDSeq
	                ,@LVC_OrderGroupName=Name
	                ,@LVC_CustomBundleNameEnabledFlag = CustomBundleNameEnabledFlag
	          FROM   #TEMPInvoiceGroupFinal WITH (nolock)
	          WHERE  SEQ = @LI_MIN
	          -------------------------BEGIN INSERT Invoices.dbo.InvoiceGroup---------------------------
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
                  INSERT INTO Invoices.dbo.InvoiceGroup (InvoiceIDSeq,
                                                         OrderIDSeq,
                                                         OrderGroupIDSeq,
                                                         Name,
                                                         CustomBundleNameEnabledFlag)
	               SELECT @LVC_InvoiceID as InvoiceIDSeq
                         ,@LI_OrderIDSeq as OrderIDSeq
                         ,@LI_OrderGroupIDSeq as OrderGroupIDSeq
                         ,@LVC_OrderGroupName as Name
                         ,@LVC_CustomBundleNameEnabledFlag as CustomBundleNameEnabledFlag
	               SELECT @LI_InvoiceGroupIDSeq =  SCOPE_IDENTITY() 
		        END -- ELSE block

              -- Error Handling --
              SELECT @SQLErrorCode = @@Error 
	          IF @SQLErrorCode<> 0 
	            BEGIN 
		          SELECT @SQLErrorCode as SQLErrorCode, @LVC_InvoiceID as InvoiceID
		          Exec   CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSectiON = 'SELECT/Generation of @LI_InvoiceGroupIDSeq Failed.' 
	            END				
		     -------------------------END INSERT Invoices.dbo.InvoiceGroup---------------------------
             -------------------------------------------------------------------------------------------------------------------------
	         -------------------------Insert data into Invoices.dbo.Invoices table -------------------
	          IF (@LI_InvoiceGroupIDSeq <> -1)
	            BEGIN
                   --save the dates into variables 
                   SELECT  @LDT_BillingPeriodFromDate = S.BillingPeriodFromDate, 
                           @LDT_BillingPeriodToDate   = S.BillingPeriodToDate,
                           @LC_ChargeTypeCode         = S.chargetypecode,
                           @LC_FrequencyCode          = S.FrequencyCode,
                           @LDT_ActivationStartDate   = OI.ActivationStartDate,
                           @LDT_NewActivationEndDate  = OI.NewActivationEndDate,  --Based on Gwen's Email
                           @LDT_TargetDate            = OI.TargetDate
                   FROM       #TEMPInvoiceItem S       with (nolock)
                   INNER JOIN #TEMPOrderItem OI        with (nolock)
                      ON    OI.OrderIDSeq         = S.OrderIDSeq  
                      AND   OI.OrderGroupIDSeq    = S.OrderGroupIDSeq
                      AND   OI.orderitemidseq     = S.OrderItemIDSeq 
                      AND   OI.OrderItemRenewalCount = S.OrderItemRenewalCount
                      AND   OI.productcode        = S.productcode    collate SQL_Latin1_General_CP850_CI_AI
                      AND   OI.chargetypecode     = S.chargetypecode collate SQL_Latin1_General_CP850_CI_AI
                      AND   OI.FrequencyCode      = S.FrequencyCode  collate SQL_Latin1_General_CP850_CI_AI
                      AND   OI.MeasureCode        = S.MeasureCode    collate SQL_Latin1_General_CP850_CI_AI                   
                   WHERE  OI.OrderIDSeq      = @LI_OrderIDSeq 
                      AND OI.OrderGroupIDSeq = @LI_OrderGroupIDSeq 
                      AND (S.BillingPeriodFromDate is not null and S.BillingPeriodToDate is not null) --pick the starting value
                   
                   SELECT @SQLErrorCode = @@error 
                   -- error handling -- 
                   IF @SQLErrorCode <> 0 
                     BEGIN 
                        SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
                        EXEC CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, query to set variables @LDT_BillingPeriodFromDate,@LDT_BillingPeriodToDate failed. ' 
                        RETURN -- quit procedure.
                     END 

             -------------------------------------------------------------------------------
             --create a while loop to insert invoice item for following months if any. 
             --5/1/2007-5/31/2007, 6/1/2007-6/30/2007..etc.
             -------------------------------------------------------------------------------
             ---------Start  --Based on Gwen's Email -------------
             IF @LDT_NewActivationEndDate < @LDT_TargetDate 
                SET @LDT_MonthlyRecurringToDate = @LDT_NewActivationEndDate 
             ELSE 
                SET @LDT_MonthlyRecurringToDate = @LDT_TargetDate
             ---------End --Based on Gwen's Email --------------

             SELECT  @MonthlyInvoiceMinCount = 1
             SELECT  @MontlyInvoiceMaxCount = datediff(MM, @LDT_BillingPeriodFromDate,@LDT_MonthlyRecurringToDate) --Based on Gwen's Email

             DECLARE @newBillingPeriodFromDate DATETIME
             DECLARE @newBillingPeriodToDate   DATETIME

             WHILE  @MonthlyInvoiceMinCount <= @MontlyInvoiceMaxCount
                BEGIN --: monthly billing while loop begin
                  SELECT @newBillingPeriodFromDate = Invoices.dbo.fn_SetFirstDayOfFollowingMonth(@LDT_BillingPeriodFromDate)
                  SELECT @newBillingPeriodToDate   = Invoices.dbo.fn_SetLastDayOfFollowingMonth(@LDT_BillingPeriodFromDate)

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
	              SELECT @LVC_InvoiceID, 
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
                         Convert(numeric(30,2),S.DiscountAmount) as DiscountAmount,
                         Convert(numeric(30,2),S.NetChargeAmount) as NetChargeAmount,
	                 @newBillingPeriodFromDate,
                         @newBillingPeriodToDate,
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
	              FROM   #TEMPOrderItem S WITH (nolock)
                  WHERE NOT EXISTS (SELECT 1 FROM #TEMPInvoiceItem OI WITH (nolock)
                                    WHERE (BillingPeriodFromDate  = @newBillingPeriodFromDate
                                       AND BillingPeriodToDate    = @newBillingPeriodToDate))
                     AND  EXISTS (SELECT TOP 1 1 FROM #TEMPInvoiceGroupFinal TIGF WITH (nolock)
                                  WHERE    TIGF.InvoiceIDSeq  = @LVC_InvoiceID
                                     AND   S.OrderIDSeq      = TIGF.OrderIDSeq
                                     AND   S.OrderGroupIDSeq = TIGF.OrderGroupIDSeq)
                     AND  @newBillingPeriodFromDate <= S.TargetDate
                   -- error handling --
                   SELECT @SQLErrorCode = @@error 
                   IF @SQLErrorCode <> 0 
                     BEGIN 
                       SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
                       EXEC CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured, while trying to Insert data into #TEMPInvoiceItem table.' 
                       RETURN -- quit procedure.
                     END 

                   SELECT @LDT_BillingPeriodFromDate = @newBillingPeriodFromDate 
	         -------------------------------------------------------------------------------
             --end of order item table update to fill in the dates- : 
             -------------------------------------------------------------------------------
           UPDATE OI 
	   SET    OI.LastBillingPeriodFromDate = (Case when OI.LastBillingPeriodFromDate is null 
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
	 WHERE OI.OrderIDSeq         = @LI_OrderIDSeq
	 AND   OI.OrderGroupIDSeq    = @LI_OrderGroupIDSeq
     
         SELECT @MonthlyInvoiceMinCount = @MonthlyInvoiceMinCount+1

       END --: monthly billing while loop end 
     END   --: @LI_InvoiceGroupIDSeq  - end
     SELECT @LI_MIN = @LI_MIN+1
   END --: Invoice Group while Loop - end

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
	                                 WHERE  DII.OrderIDSeq        = @LI_OrderIDSeq
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
	        

       END -- Processing completed for ACS

        -- error handling --
         SELECT @SQLErrorCode = @@error, @SQLRowCount = @@rowcount
         IF @SQLErrorCode <> 0
           BEGIN      
             SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
             EXEC CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = 'SQL Error occured while inserting data into INVOICES.dbo.InvoiceItem table.'        
             RETURN -- quit procedure.
           END 

         /*
          IF @SQLRowCount = 0 
           BEGIN 
             SELECT @SQLErrorcode as SQLErrorcode, @LVC_InvoiceID as InvoiceID
             EXEC CUSTOMERS.DBO.uspCUSTOMERS_RaiseError @IPVC_CodeSection = '0 records were inserted into INVOICES.dbo.InvoiceItem table.' 
             RETURN -- quit procedure.
           END  
         */
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
        select @imin = 1,@imax=count(*) from  #TEMPMonthlyInvoiceHoldingTable with (nolock)
        while @imin <= @imax
        begin
          select @LVC_INVOICE = InvoiceID 
          from   #TEMPMonthlyInvoiceHoldingTable with (nolock)
          where  IDSeq = @imin
          exec Invoices.dbo.uspINVOICES_TaxableAddressUpdate @IPVC_InvoiceID =@LVC_INVOICE
          select @imin = @imin+1
        end
        ------------------------------------------------------------------------------------
        --Sync $$$ amount totals and Notes now.
        ------------------------------------------------------------------------------------    
        Exec Invoices.dbo.[uspInvoices_SyncInvoiceTablesAndNotes] @IPVC_OrderIDSeq = @LBI_OrderID

        select distinct SQLErrorcode,InvoiceID from #TEMPMonthlyInvoiceHoldingTable with (nolock)
        ----SELECT @SQLErrorcode as SQLErrorcode,@LVC_InvoiceID as InvoiceID
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
        DROP TABLE #TEMPMonthlyInvoiceHoldingTable
        ----------------------------------------------------------------------------

END --: --: Main Procedure END
GO
