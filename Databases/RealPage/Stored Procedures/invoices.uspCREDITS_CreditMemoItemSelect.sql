SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : [uspCREDITS_CreditMemoItemSelect]
-- Description     : This procedure gets the list of Credit Memo Items for the credit memo id passed.
-- Input Parameters: @CreditMemoIDSeq bigint
-- OUTPUT          : RecordSet of IDSEq is generated
-- Code Example    : 
-- Exec Invoices.dbo.[uspCREDITS_CreditMemoItemSelect] 'R1110000029' 
-- Revision History:
-- Author          : Shashi Bhushan
-- 10/11/2007      : Stored Procedure Created.
-- Revised		   : Kiran Kusumba
-- 31/10/2007	   : Added the code for Custom Bundle Enabled Flag 1
-- 26/12/2007      : Naval Kishore Singh Modified Stored Procedure
-- 11/06/2008      : Naval Kishore Modified stored procedure to get IDSEQ for custombundle
-- 17/10/2008      : Naval Kishore Modified stored procedure to get requested date.
-- 14/07/2009      : Shashi Bhushan for defect #6745 
-- 11/05/2011      : SRS TFS 901 Notes : One Day this Proc needs to Rewritten. Poor implmentation.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspCREDITS_CreditMemoItemSelect] (@CreditMemoIDSeq varchar(50)) 
AS
BEGIN
  set nocount on;
  ------------------------------------------------------------------------------------------
  --                  Decalration of Temporary tables.
  ------------------------------------------------------------------------------------------
  Declare @LT_InvoiceCreditSummary TABLE
  (
        IDSeq                       varchar(22),
        ProductCode                 varchar(30),
        ProductName                 varchar(255),
        ChargeType                  char(4),
	CreditReasonCode	    varchar(6),
	CreditMemoItemIDSeq         bigint,
	RevisedDate                 datetime,
	RequestedBy                 varchar(70),
	Comments		    varchar(4000),
        CreditAmount                numeric(30,2),
	ChargeAmount                numeric(30,2),
	TaxAmount                   numeric(30,2),
        TaxPercent                  numeric(30,3),
        Total                       numeric(30,2),
        NetPrice                    numeric(30,2),
        TotalCreditAmount           numeric(30,2),
        TotalTaxAmount              numeric(30,2),
        AvailableCredit             numeric(30,2),
	InvoiceItemIDSeq	    bigint,
        InvoiceGroupIDSeq           bigint,
        BillingPeriod               varchar(255),
        CustomBundleNameEnabledFlag bit,
	DoNotPrintCreditReasonFlag      bit,
	DoNotPrintCreditCommentsFlag    bit,
        ReportingTypeCode		    varchar(6),
        ActualTaxAmount             numeric(30,2),
        InvoiceTaxAmount            numeric(30,2),
        RenewalCount                bigint,
        InvoiceIDseq                varchar(22),
        OrderIDSeq                  varchar(22),
        OrderGroupIDSeq             bigint,
        BillingPeriodFromDate       datetime,
        BillingPeriodToDate         datetime,
        ShippingAndHandlingAmount   numeric(30,2), 
        AvailShippingAndHandlingAmount   numeric(30,2)    
  )

  Declare @LT_InvoiceCreditTotals TABLE
  (
      TotalCredit Numeric(30,2),
      TotalTax    Numeric(30,2),
      SnHTotal    Numeric(30,2),
      NetTotal    Numeric(30,2)
  )
  Declare @LT_InvoiceGroupSummary TABLE
  (
      RowNumber                   int identity(1,1),
	  CreditMemoItemIDSeq         bigint,
	  InvoiceIDSeq				  Varchar(22),
	  InvoiceItemIDSeq			  bigint,	
      InvoiceGroupIDSeq           bigint,
      GroupName                   varchar(255),
      CustomBundleNameEnabledFlag bit,
      ChargeTypeCode              char(3),
      ReportingTypeCode           char(4),
      RenewalCount                bigint,
      OrderIDSeq                  varchar(22),
      OrderGroupIDSeq             bigint,
      BillingPeriodFromDate       datetime,
      BillingPeriodToDate         datetime		
  )
  DECLARE @LT_BundleGroupSummary TABLE
  (
      RowNumber                   int identity(1,1),
      InvoiceGroupIDSeq           bigint,
      GroupName                   varchar(255),
      CustomBundleNameEnabledFlag bit,
      ChargeTypeCode              char(3),
      ReportingTypeCode           char(4),
      RenewalCount                bigint,
      InvoiceIDseq                varchar(22),
      OrderIDSeq                  varchar(22),
      OrderGroupIDSeq             bigint,
      BillingPeriodFromDate       datetime,
      BillingPeriodToDate         datetime
  )
	Declare @LT_CustomBundleEnabled TABLE
  (
      RowNumber                   int identity(1,1),
	  CustomBundleNameEnabledFlag bit      
  )
------------------------------------------------------------------------------------------
--                  Declaration of Temporary Variables.
	Declare @InvoiceIDSeq          varchar(200) 
	Declare @Mode                  varchar(20)
	Declare @LVC_CreditReasonCode  Varchar(6)
	Declare @LVD_RevisedDate	   Datetime
	Declare @LVC_RequestedBy       Varchar(70)
	Declare @LVC_Comments		   Varchar(4000)
	Declare @LV_Counter            int
	Declare @LV_RowCount           int 
    Declare @LVC_BillingPeriod     varchar(255)
	DECLARE @LN_InvoiceTaxAmount    numeric(30,2)  
    DECLARE @LN_CreditTaxAmount     numeric(30,2)	
    DECLARE @LN_ActualTaxAmount     numeric(30,2)
	DECLARE @LN_IDSEQCustomBundle          bigint
    ------------------------------------------------
    DECLARE @LBI_CB_MinInvoiceItemIDSeq bigint
    DECLARE @LN_SnHAmount               numeric(30,2)
    DECLARE @LN_AvailSnHAmount          numeric(30,2)
    DECLARE @LN_InvoiceSnHAmount        numeric(30,2)  
    DECLARE @LN_CreditSnHAmount         numeric(30,2)
    DECLARE @LVC_EpicorPostingCode      varchar(10)
    DECLARE @LVC_TaxwareCompanyCode     varchar(10)
------------------------------------------------------------------------------------------------------
	Set @Mode=(select Case when CreditTypeCode='PARC' then 'PartialCredit'
						   when CreditTypeCode='FULC' then 'FullCredit'
						   when CreditTypeCode='TAXC' then 'TaxCredit'
					  end 
			   from Invoices.dbo.CreditMemo with (nolock)
               where CreditMemoIDSeq = @CreditMemoIDSeq )

	Select @LVC_CreditReasonCode = CreditReasonCode,
           @LVD_RevisedDate      = RevisedDate,
           @LVC_RequestedBy      = RequestedBy,
           @LVC_Comments         = Comments,
           @InvoiceIDSeq         = InvoiceIDSeq
	From Invoices.dbo.CreditMemo  with (nolock)
    where CreditMemoIDSeq=@CreditMemoIDSeq   
  ------------------------------------------------------------------------------------
  -- Assigning values of EpicorPostingCode,TaxwareCompanyCode to local variables  
  SELECT @LVC_EpicorPostingCode  = EpicorPostingCode,
         @LVC_TaxwareCompanyCode = TaxwareCompanyCode 
  FROM   Invoices.dbo.[Invoice] with (nolock)
  WHERE  InvoiceIDSeq = @InvoiceIDSeq
--------------------------------------------------------------------------------------------------------
	INSERT INTO @LT_CustomBundleEnabled (CustomBundleNameEnabledFlag)
	SELECT DISTINCT CustomBundleNameEnabledFlag 
    FROM  Invoices.dbo.InvoiceGroup with (nolock)
	WHERE InvoiceIDSeq = @InvoiceIDSeq

--select * from @LT_CustomBundleEnabled
----------------------------------------------------------------------------------------------------------
Declare @LV_BundleCounter int
Declare @LV_BundleRowCount int
Declare @BundleFlag	int
---------------------------------------------------------------------------------------------------------
SELECT @LV_BundleRowCount = count(*) FROM @LT_CustomBundleEnabled
SET    @LV_BundleCounter = 1
---------------------------------------------------------------------------------------------------------
WHILE @LV_BundleCounter < = @LV_BundleRowCount
BEGIN
    SELECT @BundleFlag = CustomBundleNameEnabledFlag           
    FROM @LT_CustomBundleEnabled 
    WHERE RowNumber = @LV_BundleCounter 
---------------------------------------------------------------------------------------
-----If CustomBundleEnabledFlag is 1
-----------------------------------------------------------------------------------------  
	IF (@BundleFlag = 1)
	BEGIN
		IF(@Mode = 'PartialCredit')
			BEGIN
				INSERT INTO @LT_BundleGroupSummary
				(     
					InvoiceGroupIDSeq,
					GroupName,
					CustomBundleNameEnabledFlag,
					ChargeTypeCode,
                    ReportingTypeCode,
                    RenewalCount,
                    InvoiceIDseq,
                    OrderIDSeq,
                    OrderGroupIDSeq,
                    BillingPeriodFromDate,
                    BillingPeriodToDate
				)
				 SELECT DISTINCT InvGrIDSEq,IGName,IGFlag,
                                 ChType,RTCode,RCount,
                                 InvIDSeq,OrderID,OrderGrpID,
                                 BillingFrom,BillingTo
				 FROM  Invoices.dbo.CreditMemoItem CMI 
                 RIGHT JOIN 
					(SELECT  IG.IDSeq                       AS InvGrIDSeq,
                             IG.[Name]                      AS IGName,
                             IG.CustomBundleNameEnabledFlag AS IGFlag, 
                             II.ChargeTypeCode              AS ChType,
	                         II.ReportingTypeCode           AS RTCode,
	                         II.OrderItemRenewalCount       AS RCount,
                             II.InvoiceIDSeq                AS InvIDSeq,
                             II.OrderIDSeq                  AS OrderID,
                             II.OrderGroupIDSeq             AS OrderGrpID,
	                         II.BillingPeriodFromDate       AS BillingFrom,
                             II.BillingPeriodToDate         AS BillingTo                    
					 FROM    Invoices.dbo.InvoiceGroup IG
					 INNER JOIN 
                             Invoices.dbo.InvoiceItem II 
                          ON IG.InvoiceIDSeq     = II.InvoiceIDSeq
                          and IG.IDSeq           = II.InvoiceGroupIDSeq
                          and IG.OrderIDSeq      = II.OrderIDSeq
                          and IG.OrderGroupIDSeq = II.OrderGroupIDSeq
					 WHERE    IG.InvoiceIDSeq = @InvoiceIDSeq ) AS  temp 
                  ON  CMI.InvoiceGroupIDSeq = temp.InvGrIDSeq 
                  AND CMI.InvoiceIDSeq      = @InvoiceIDSeq
			END
		ELSE
			BEGIN
				INSERT INTO @LT_BundleGroupSummary
				(     
					InvoiceGroupIDSeq,
					GroupName,
					CustomBundleNameEnabledFlag,
					ChargeTypeCode,
                    ReportingTypeCode,
                    RenewalCount,
                    InvoiceIDseq,
                    OrderIDSeq,
                    OrderGroupIDSeq,
                    BillingPeriodFromDate,
                    BillingPeriodToDate
				)
				 SELECT DISTINCT InvGrIDSEq,IGName,IGFlag,
                                 ChType,RTCode,RCount,
                                 InvIDSeq,OrderID,OrderGrpID,
                                 BillingFrom,BillingTo
				 FROM  Invoices.dbo.CreditMemoItem CMI 
                 INNER JOIN 
					(SELECT  IG.IDSeq                       AS InvGrIDSeq,
                             IG.[Name]                      AS IGName,
                             IG.CustomBundleNameEnabledFlag AS IGFlag, 
                             II.ChargeTypeCode              AS ChType,
	                         II.ReportingTypeCode           AS RTCode,
	                         II.OrderItemRenewalCount       AS RCount,
                             II.InvoiceIDSeq                AS InvIDSeq,
                             II.OrderIDSeq                  AS OrderID,
                             II.OrderGroupIDSeq             AS OrderGrpID,
	                         II.BillingPeriodFromDate       AS BillingFrom,
                             II.BillingPeriodToDate         AS BillingTo                    
					 FROM    Invoices.dbo.InvoiceGroup IG
					 INNER JOIN 
                             Invoices.dbo.InvoiceItem II 
                          ON IG.InvoiceIDSeq     = II.InvoiceIDSeq
                          and IG.IDSeq           = II.InvoiceGroupIDSeq
                          and IG.OrderIDSeq      = II.OrderIDSeq
                          and IG.OrderGroupIDSeq = II.OrderGroupIDSeq
					 WHERE    IG.InvoiceIDSeq = @InvoiceIDSeq ) AS  temp 
                  ON  CMI.InvoiceGroupIDSeq = temp.InvGrIDSeq 
                  AND CMI.InvoiceIDSeq      = @InvoiceIDSeq
			END

		SELECT @LV_RowCount = count(*) FROM @LT_BundleGroupSummary
  	SET @LV_Counter = 1
		
		DECLARE @LVC_CustomBundleNameEnabledFlag bit
		DECLARE @LVC_InvoiceGroupIDSeq           bigint
		DECLARE @LVC_GroupName                   varchar(255)
		DECLARE @LC_ChargeTypeCode               char(3)
		DECLARE @LN_TotalChargeAmount			 numeric(30,2)
--		select * from @LT_BundleGroupSummary
        DECLARE @LC_ReportingTypeCode            char(4)
        DECLARE @LBI_RenewalCount                bigint
        DECLARE @LVC_InvoiceIDseq                varchar(22)
        DECLARE @LVC_OrderIDSeq                  varchar(22)
        DECLARE @LBI_OrderGroupIDSeq             bigint
        DECLARE @LDT_BillingPeriodFromDate       datetime
        DECLARE @LDT_BillingPeriodToDate         datetime

  	WHILE @LV_Counter < = @LV_RowCount
		BEGIN
			SELECT @LVC_CustomBundleNameEnabledFlag = CustomBundleNameEnabledFlag,
                   @LVC_InvoiceGroupIDSeq           = InvoiceGroupIDSeq,
                   @LVC_GroupName                   = GroupName,
                   @LC_ChargeTypeCode               = ChargeTypeCode,
                   @LC_ReportingTypeCode            = ReportingTypeCode,    
                   @LBI_RenewalCount                = RenewalCount,         
                   @LVC_InvoiceIDseq                = InvoiceIDseq,         
                   @LVC_OrderIDSeq                  = OrderIDSeq,
                   @LBI_OrderGroupIDSeq             = OrderGroupIDSeq,
                   @LDT_BillingPeriodFromDate       = BillingPeriodFromDate,
                   @LDT_BillingPeriodToDate         = BillingPeriodToDate
			FROM @LT_BundleGroupSummary 
            WHERE RowNumber = @LV_Counter 		 

            SELECT @LVC_BillingPeriod = convert(varchar(11),BillingPeriodFromDate,101) + ' - ' + convert(varchar(11),BillingPeriodToDate,101)
            FROM  Invoices.dbo.InvoiceItem with (nolock)
            WHERE InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
			AND   ChargeTypeCode        = @LC_ChargeTypeCode
            AND   Orderitemrenewalcount = @LBI_RenewalCount	
            AND   BillingPeriodFromDate = @LDT_BillingPeriodFromDate
            AND   BillingPeriodToDate   = @LDT_BillingPeriodToDate
            AND   OrderIDSeq            = @LVC_OrderIDSeq
            AND   OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
            AND   InvoiceIDSeq          = @InvoiceIDSeq
-----------------------------------------------------------------------------------------
			Declare @LN_NetCreditAmount            numeric(30,2)
			Declare @LN_TaxAmount                  numeric(30,2)
			Declare @LN_TaxPercent                 numeric(30,3)
			Declare @LN_SumNetPrice                numeric(30,2)
			Declare @LN_SumTotalCreditAmount       numeric(30,2)
			Declare @LN_SumTotalTaxAmount          numeric(30,2) 
			Declare @LN_AvailableCredit	           numeric(30,2)
			Declare @LN_AvailNetCreditAmount       numeric(30,2)
			Declare @LN_AvailTaxAmount             numeric(30,2)
            Declare @LN_SumTaxPrice                numeric(30,2)
            Declare @LV_NetPriceSum                money
			Declare @LV_TaxAmount                  money
			Declare @LV_CreditAmount               money
---------------------------------------------------------------------------------------------
--			SELECT @LN_TotalChargeAmount       = SUM(NetChargeAmount)
--			FROM  Invoices.dbo.InvoiceItem with (nolock)
--            WHERE InvoiceGroupIDSeq       = @LVC_InvoiceGroupIDSeq
--			  AND   ChargeTypeCode        = @LC_ChargeTypeCode
--              AND   Orderitemrenewalcount = @LBI_RenewalCount	
--              AND   BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--              AND   BillingPeriodToDate   = @LDT_BillingPeriodToDate
--              AND   OrderIDSeq            = @LVC_OrderIDSeq
--              AND   OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--              AND   InvoiceIDSeq          = @InvoiceIDSeq

			SELECT @LN_TotalChargeAmount = SUM(NetChargeAmount),
                   @LN_TaxPercent        = Avg(II.TaxPercent),
                   @LN_SumNetPrice       = convert(numeric(30,2),SUM(II.NetChargeAmount) + SUM(II.TaxAmount)),
                   @LN_SumTaxPrice       = convert(numeric(30,2),SUM(II.TaxAmount)),
                   @LV_NetPriceSum       = sum(ISNULL(NetChargeAmount,0.00)),
--                   @LV_TaxAmount         = sum(ISNULL(TaxAmount,0.00))
                   @LV_TaxAmount         = convert(numeric(30,2),SUM(isnull(TaxAmount,0.00)))
			FROM  Invoices.dbo.InvoiceItem II with (nolock)
            WHERE InvoiceGroupIDSeq       = @LVC_InvoiceGroupIDSeq
			  AND   ChargeTypeCode        = @LC_ChargeTypeCode
              AND   Orderitemrenewalcount = @LBI_RenewalCount	
              AND   BillingPeriodFromDate = @LDT_BillingPeriodFromDate
              AND   BillingPeriodToDate   = @LDT_BillingPeriodToDate
              AND   OrderIDSeq            = @LVC_OrderIDSeq
              AND   OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
              AND   InvoiceIDSeq          = @InvoiceIDSeq

            SELECT @LBI_CB_MinInvoiceItemIDSeq = (IDSeq) 
			FROM  Invoices.dbo.InvoiceItem with (nolock)
            WHERE InvoiceGroupIDSeq       = @LVC_InvoiceGroupIDSeq
			  AND   ChargeTypeCode        = @LC_ChargeTypeCode
              AND   Orderitemrenewalcount = @LBI_RenewalCount	
              AND   BillingPeriodFromDate = @LDT_BillingPeriodFromDate
              AND   BillingPeriodToDate   = @LDT_BillingPeriodToDate
              AND   OrderIDSeq            = @LVC_OrderIDSeq
              AND   OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
              AND   InvoiceIDSeq          = @InvoiceIDSeq
              AND   ShippingAndHandlingAmount >1

            SELECT @LN_NetCreditAmount = 
				(CASE 
                   WHEN isnull((select sum(CI.ExtCreditAmount) 
                                from  Invoices.dbo.CreditMemoItem CI with (nolock)
								inner join 
                                      Invoices.dbo.CreditMemo C with (nolock)
								   on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								inner join 
                                      Invoices.dbo.InvoiceItem II with (nolock)
								   on II.IDSeq = CI.InvoiceItemIDSeq
								where CI.InvoiceGroupIDSeq    = @LVC_InvoiceGroupIDSeq 
                                  and II.ChargeTypeCode       = @LC_ChargeTypeCode
                                  AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                  AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                  AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                  AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                  AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                  AND II.InvoiceIDSeq          = @InvoiceIDSeq
								  and CI.CustomBundleNameEnabledFlag = 1
								  and C.CreditStatusCode in ('PAPR')),0)< 0 
								THEN 0 
                   ELSE isnull((select sum(CI.ExtCreditAmount) 
                                from Invoices.dbo.CreditMemoItem CI with (nolock)
								inner join 
                                     Invoices.dbo.CreditMemo C with (nolock)
								   on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								inner join 
                                     Invoices.dbo.InvoiceItem II with (nolock)
								   on  II.IDSeq = CI.InvoiceItemIDSeq
								where CI.InvoiceGroupIDSeq    = @LVC_InvoiceGroupIDSeq 
                                  and II.ChargeTypeCode       = @LC_ChargeTypeCode
                                  AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                  AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                  AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                  AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                  AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                  AND II.InvoiceIDSeq          = @InvoiceIDSeq
								  and CI.CustomBundleNameEnabledFlag = 1
								  and C.CreditStatusCode in ('PAPR')),0)
				END)
----------------------------------------------------------------------------------------------
			select Top 1 @LN_IDSEQCustomBundle = IDSEQ --AVG(II.TaxPercent) 
            from  Invoices.dbo.InvoiceItem with (nolock)
            where InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq                 
			  and ChargeTypeCode     = @LC_ChargeTypeCode
              and Orderitemrenewalcount = @LBI_RenewalCount	
              and BillingPeriodFromDate = @LDT_BillingPeriodFromDate
              and BillingPeriodToDate   = @LDT_BillingPeriodToDate
              and OrderIDSeq            = @LVC_OrderIDSeq
              and OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
              and InvoiceIDSeq          = @InvoiceIDSeq
			order by taxpercent desc
--------------------------------------------------------------------------------------------------

        SELECT @LN_AvailNetCreditAmount =Round(
             (CASE 
                WHEN isnull((select sum(CI.ExtCreditAmount) 
                             from Invoices.dbo.CreditMemoItem CI with (nolock)
						     inner join 
                                  Invoices.dbo.CreditMemo C with (nolock)
							   on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
							 inner join 
                                  Invoices.dbo.InvoiceItem II with (nolock)
							   on  II.IDSeq = CI.InvoiceItemIDSeq
							 where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
                               and II.ChargeTypeCode        = @LC_ChargeTypeCode
                               and II.Orderitemrenewalcount = @LBI_RenewalCount	
                               and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                               and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                               and II.OrderIDSeq            = @LVC_OrderIDSeq
                               and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                               and II.InvoiceIDSeq          = @InvoiceIDSeq
							   and CI.CustomBundleNameEnabledFlag = 1
							   and C.CreditStatusCode in ('APPR')),0)< 0 
							THEN 0 
                ELSE isnull((select sum(CI.ExtCreditAmount) 
                             from Invoices.dbo.CreditMemoItem CI with (nolock)
						     inner join 
                                  Invoices.dbo.CreditMemo C with (nolock)
							   on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
							 inner join 
                                  Invoices.dbo.InvoiceItem II with (nolock)
							   on  II.IDSeq = CI.InvoiceItemIDSeq
							 where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
                               and II.ChargeTypeCode        = @LC_ChargeTypeCode
                               and II.Orderitemrenewalcount = @LBI_RenewalCount	
                               and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                               and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                               and II.OrderIDSeq            = @LVC_OrderIDSeq
                               and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                               and II.InvoiceIDSeq          = @InvoiceIDSeq
							   and CI.CustomBundleNameEnabledFlag = 1
								and  C.CreditStatusCode in ('APPR')),0)
              END),0)

        SELECT @LN_TaxAmount = 
                       ( CASE 
							WHEN isnull((select convert(numeric(30,2),sum(CI.TaxAmount))  
										 from Invoices.dbo.CreditMemoItem CI with (nolock) 
										 inner join 
                                              Invoices.dbo.CreditMemo C with (nolock)
										   on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                                         inner join 
                                              Invoices.dbo.InvoiceItem II with (nolock)
                                           on II.IDSeq = CI.InvoiceItemIDSeq
										  and C.CreditStatusCode in ('PAPR')
										 where CI.InvoiceGroupIDSeq    = @LVC_InvoiceGroupIDSeq
                                          and II.InvoiceGroupIdSeq     = @LVC_InvoiceGroupIDSeq
                                          and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                          and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                          and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                          and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                          and II.OrderIDSeq            = @LVC_OrderIDSeq
                                          and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                          and II.InvoiceIDSeq          = @InvoiceIDSeq
										  and CI.CustomBundleNameEnabledFlag = 1 ), 0) < 0 
							THEN 0 
							ELSE isnull((select convert(numeric(30,2),sum(CI.TaxAmount))  
										 from Invoices.dbo.CreditMemoItem CI with (nolock) 
										 inner join 
                                              Invoices.dbo.CreditMemo C with (nolock)
										   on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                                         inner join 
                                              Invoices.dbo.InvoiceItem II with (nolock)
                                           on II.IDSeq = CI.InvoiceItemIDSeq
										  and C.CreditStatusCode in ('PAPR')
										 where CI.InvoiceGroupIDSeq    = @LVC_InvoiceGroupIDSeq
                                          and II.InvoiceGroupIdSeq     = @LVC_InvoiceGroupIDSeq
                                          and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                          and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                          and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                          and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                          and II.OrderIDSeq            = @LVC_OrderIDSeq
                                          and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                          and II.InvoiceIDSeq          = @InvoiceIDSeq
										  and CI.CustomBundleNameEnabledFlag = 1 ), 0)
							END)  

        SELECT @LN_AvailTaxAmount = 
                (CASE 
                   WHEN isnull((select sum(CI.TaxAmount) 
                                from Invoices.dbo.CreditMemoItem CI with (nolock)
								inner join 
                                     Invoices.dbo.CreditMemo C with (nolock)
								  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								inner join 
                                     Invoices.dbo.InvoiceItem II with (nolock)
								  on  II.IDSeq = CI.InvoiceItemIDSeq
								where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
                                  and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                  and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                  and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                  and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                  and II.OrderIDSeq            = @LVC_OrderIDSeq
                                  and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                  and II.InvoiceIDSeq          = @InvoiceIDSeq
								  and CI.CustomBundleNameEnabledFlag = 1
								  and C.CreditStatusCode in ('APPR')),0)< 0 
								THEN 0 
                   ELSE isnull((select sum(CI.TaxAmount) 
                                from Invoices.dbo.CreditMemoItem CI with (nolock)
								inner join 
                                     Invoices.dbo.CreditMemo C with (nolock)
								  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								inner join 
                                     Invoices.dbo.InvoiceItem II with (nolock)
								  on  II.IDSeq = CI.InvoiceItemIDSeq
								where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
                                  and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                  and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                  and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                  and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                  and II.OrderIDSeq            = @LVC_OrderIDSeq
                                  and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                  and II.InvoiceIDSeq          = @InvoiceIDSeq
								  and CI.CustomBundleNameEnabledFlag = 1
								  and  C.CreditStatusCode in ('APPR')),0)
							 END)

--        SELECT @LN_TaxPercent = Avg(II.TaxPercent) 
--        from  Invoices.dbo.InvoiceItem II with (nolock)
--        where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--          and II.ChargeTypeCode        = @LC_ChargeTypeCode
--          and II.Orderitemrenewalcount = @LBI_RenewalCount	
--          and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--          and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--          and II.OrderIDSeq            = @LVC_OrderIDSeq
--          and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--          and II.InvoiceIDSeq          = @InvoiceIDSeq
--
--        SELECT @LN_SumNetPrice = convert(numeric(30,2),SUM(II.NetChargeAmount) + SUM(II.TaxAmount)) 
--        from  Invoices.dbo.InvoiceItem II with (nolock)
--        where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--          and II.ChargeTypeCode        = @LC_ChargeTypeCode
--          and II.Orderitemrenewalcount = @LBI_RenewalCount	
--          and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--          and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--          and II.OrderIDSeq            = @LVC_OrderIDSeq
--          and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--          and II.InvoiceIDSeq          = @InvoiceIDSeq
--
--        SELECT @LN_SumTaxPrice = convert(numeric(30,2),SUM(II.TaxAmount)) 
--        from  Invoices.dbo.InvoiceItem II with (nolock)
--        where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--          and II.ChargeTypeCode        = @LC_ChargeTypeCode
--          and II.Orderitemrenewalcount = @LBI_RenewalCount	
--          and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--          and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--          and II.OrderIDSeq            = @LVC_OrderIDSeq
--          and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--          and II.InvoiceIDSeq          = @InvoiceIDSeq

	    SELECT @LN_SumTotalCreditAmount = Round(
			  (CASE 
                  WHEN isnull((select sum(CI.ExtCreditAmount) 
                               from Invoices.dbo.CreditMemoItem CI with (nolock)
							   inner join 
                                    Invoices.dbo.CreditMemo C with (nolock)
								 on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
							   inner join 
                                    Invoices.dbo.InvoiceItem II with (nolock)
							     on  II.IDSeq                 = CI.InvoiceItemIDSeq
							   where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
                                 and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                 and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                 and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                 and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                 and II.OrderIDSeq            = @LVC_OrderIDSeq
                                 and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                 and II.InvoiceIDSeq          = @InvoiceIDSeq
								 and CI.CustomBundleNameEnabledFlag = 1
								 and C.CreditStatusCode in ('APPR')),0)< 0 
				   THEN 0 
                 ELSE isnull(( select sum(CI.ExtCreditAmount) 
                               from Invoices.dbo.CreditMemoItem CI with (nolock)
							   inner join 
                                    Invoices.dbo.CreditMemo C with (nolock)
								 on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
							   inner join 
                                    Invoices.dbo.InvoiceItem II with (nolock)
							     on  II.IDSeq                 = CI.InvoiceItemIDSeq
							   where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
                                 and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                 and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                 and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                 and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                 and II.OrderIDSeq            = @LVC_OrderIDSeq
                                 and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                 and II.InvoiceIDSeq          = @InvoiceIDSeq
								 and CI.CustomBundleNameEnabledFlag = 1	
								and  C.CreditStatusCode in ('APPR')),0)
							 END),0)

        SELECT  @LN_SumTotalTaxAmount = 
		     (CASE 
                 WHEN isnull((select  convert(numeric(30,2),sum(CI.TaxAmount))  
                              from Invoices.dbo.CreditMemoItem CI with (nolock) 
							  inner join 
                                   Invoices.dbo.CreditMemo C with (nolock)
								on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								and  C.CreditStatusCode in ('APPR')
							  where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq  
                                and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                and II.OrderIDSeq            = @LVC_OrderIDSeq
                                and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                and II.InvoiceIDSeq          = @InvoiceIDSeq
							    and CI.CustomBundleNameEnabledFlag = 1), 0) < 0
                THEN 0 
            ELSE
                      isnull((select  convert(numeric(30,2),sum(CI.TaxAmount))  
                              from Invoices.dbo.CreditMemoItem CI with (nolock) 
							  inner join 
                                   Invoices.dbo.CreditMemo C with (nolock)
								on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								and  C.CreditStatusCode in ('APPR')
							  where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq  
                                and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                and II.OrderIDSeq            = @LVC_OrderIDSeq
                                and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                and II.InvoiceIDSeq          = @InvoiceIDSeq
							    and   CI.CustomBundleNameEnabledFlag = 1), 0) 
            END)    from Invoices.dbo.InvoiceItem II with (nolock) where InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq   

--	 SELECT @LN_AvailableCredit = @LN_TotalChargeAmount - (@LN_AvailNetCreditAmount + @LN_AvailTaxAmount)

--        SELECT 
--		   @LV_NetPriceSum = sum(ISNULL(i_item.NetChargeAmount,0.00)) ,
--		   @LV_TaxAmount   = sum(ISNULL(i_item.TaxAmount,0.00))
--		from invoices.dbo.[invoiceitem] i_item with (nolock)
--		where i_item.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
--		  and i_item.ReportingTypeCode     = @LC_ChargeTypeCode+'F'
--          and i_item.Orderitemrenewalcount = @LBI_RenewalCount	
--          and i_item.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--          and i_item.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--          and i_item.OrderIDSeq            = @LVC_OrderIDSeq
--          and i_item.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--          and i_item.InvoiceIDSeq          = @InvoiceIDSeq
--		group by i_item.InvoiceIDSeq 

       select --@LN_SnHAmount    = isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00),
              @LV_CreditAmount = isnull(convert(numeric(30,2),sum(CI.ExtCreditAmount)),0.00)
       from Invoices.dbo.CreditMemoItem CI with (nolock)  
	   inner join 
            Invoices.dbo.CreditMemo C with (nolock)  
		on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq  
		and C.CreditStatusCode in ('APPR')  
	   inner join 
            Invoices.dbo.InvoiceItem II with (nolock)  
		on II.InvoiceGroupIDSeq = CI.InvoiceGroupIDSeq 
        and II.IDSeq = CI.InvoiceItemIDSeq  
	   where CI.InvoiceIDSeq           = @InvoiceIDSeq 
		and CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
		and II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
        and II.ChargeTypeCode        = @LC_ChargeTypeCode
        and II.Orderitemrenewalcount = @LBI_RenewalCount	
        and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
        and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
        and II.OrderIDSeq            = @LVC_OrderIDSeq
        and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
        and II.InvoiceIDSeq          = @InvoiceIDSeq

       select @LN_SnHAmount = (select isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00)  
		 from Invoices.dbo.CreditMemoItem CI with (nolock)  
		  inner join 
              Invoices.dbo.CreditMemo C with (nolock)  
			on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq  
			and C.CreditStatusCode in ('APPR','PAPR')  
		  inner join 
              Invoices.dbo.InvoiceItem II with (nolock)  
			 on II.InvoiceGroupIDSeq = CI.InvoiceGroupIDSeq 
            and II.IDSeq = CI.InvoiceItemIDSeq  
		 where CI.InvoiceIDSeq           = @InvoiceIDSeq 
		    and CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
		    and II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
            and II.ChargeTypeCode        = @LC_ChargeTypeCode
            and II.Orderitemrenewalcount = @LBI_RenewalCount	
            and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
            and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
            and II.OrderIDSeq            = @LVC_OrderIDSeq
            and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
            and II.InvoiceIDSeq          = @InvoiceIDSeq)
-------------------------------------------------------------------------------------------
       -- S n H Calc
                 if not exists (select top 1 1 from Invoices.dbo.CreditMemo with (nolock) where invoiceidseq = @InvoiceIDSeq and CreditStatusCode='APPR' and creditmemoIDseq=@CreditMemoIDSeq)
					 begin
						Select @LN_AvailSnHAmount = (select isnull(convert(numeric(30,2),SUM(ShippingAndHandlingAmount)),0.00) 
												from invoices.dbo.invoiceitem II with (nolock) 
												where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
                                                  and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                  and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                  and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                  and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                  and II.OrderIDSeq            = @LVC_OrderIDSeq
                                                  and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                  and II.InvoiceIDSeq          = @InvoiceIDSeq
                                                  and II.IDSeq                 = @LBI_CB_MinInvoiceItemIDSeq)
					 end
				 else
					 begin			  
					   select @LN_InvoiceSnHAmount = (select isnull(convert(numeric(30,2),SUM(ShippingAndHandlingAmount)),0.00) 
                                                      from invoices.dbo.invoiceitem  II with (nolock)
                                                      where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
                                                        and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                        and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                        and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                        and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                        and II.OrderIDSeq            = @LVC_OrderIDSeq
                                                        and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                        and II.InvoiceIDSeq          = @InvoiceIDSeq
                                                        and II.IDSeq                 = @LBI_CB_MinInvoiceItemIDSeq)

					   set @LN_CreditSnHAmount = @LN_SnHAmount

					   select @LN_AvailSnHAmount = isnull(@LN_InvoiceSnHAmount,0) - isnull(@LN_CreditSnHAmount,0)
					 end

--                       select @LN_SnHAmount = (select isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00)  
--													 from Invoices.dbo.CreditMemoItem CI with (nolock)  
--													  inner join 
--                                                          Invoices.dbo.CreditMemo C with (nolock)  
--														on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq  
--														and C.CreditStatusCode in ('APPR')  
--													  inner join 
--                                                          Invoices.dbo.InvoiceItem II with (nolock)  
--														 on II.InvoiceGroupIDSeq = CI.InvoiceGroupIDSeq 
--                                                        and II.IDSeq = CI.InvoiceItemIDSeq  
--													 where CI.InvoiceIDSeq           = @InvoiceIDSeq 
--													    and CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
--													    and II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                                                        and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                                                        and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                                                        and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                                                        and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                                                        and II.OrderIDSeq            = @LVC_OrderIDSeq
--                                                        and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                                                        and II.InvoiceIDSeq          = @InvoiceIDSeq
----                                                        and II.IDSeq                 = @LBI_CB_MinInvoiceItemIDSeq
--                                                )

--         SELECT	@LV_CreditAmount= (SELECT  ISNULL(sum(cmi.ExtCreditAmount),0.00)            AS Amount
--				                   From Invoices.dbo.CreditMemoItem CMI with (nolock) 
--				                   INNER JOIN Invoices.dbo.CreditMemo CM with (nolock) 
--				                     ON CM.CreditMemoIDSeq = CMI.CreditMemoIDSeq 
--				                   INNER JOIN Invoices.dbo.InvoiceItem II with (nolock) 
--				                     on II.IDSeq = CMI.InvoiceItemIDSeq 
--				                   WHERE cm.InvoiceIDSeq          = @InvoiceIDSeq
--				                     and cmi.CreditMemoIDSeq      = cm.CreditMemoIDSeq
--				                     and CreditStatusCode         = 'APPR' 
--				                     and cmi.InvoiceGroupIDSeq    = @LVC_InvoiceGroupIDSeq
--				                     and II.ReportingTypeCode     = @LC_ChargeTypeCode+'F' 
--                                     and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                                     and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                                     and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                                     and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                                     and II.OrderIDSeq            = @LVC_OrderIDSeq
--                                     and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                                     and II.InvoiceIDSeq          = @InvoiceIDSeq)

--				SELECT @LN_AvailableCredit =(@LV_NetPriceSum  + @LV_ShipAmount +  @LV_TaxAmount - @LV_CreditAmount)

				SELECT @LN_AvailableCredit =(@LV_NetPriceSum  - @LV_CreditAmount)

                Select @LN_ActualTaxAmount = @LV_TaxAmount
---------------------------------------------------------------------------------------------	
			IF(@Mode = 'FullCredit')
			BEGIN
			   if not exists (select top 1 1 from Invoices.dbo.CreditMemo with (nolock) where invoiceidseq = @InvoiceIDSeq and CreditStatusCode='APPR')
					 begin
--						Select @LN_TaxAmount = (select convert(numeric(30,2),SUM(TaxAmount)) 
--												from invoices.dbo.invoiceitem II with (nolock) 
--												where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                                                  and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                                                  and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                                                  and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                                                  and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                                                  and II.OrderIDSeq            = @LVC_OrderIDSeq
--                                                  and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                                                  and II.InvoiceIDSeq          = @InvoiceIDSeq)

						Select @LN_TaxAmount = @LV_TaxAmount
					 end
				 else
					 begin			  
--					   select @LN_InvoiceTaxAmount = (select convert(numeric(30,2),SUM(TaxAmount)) 
--                                                      from invoices.dbo.invoiceitem  II with (nolock)
--                                                      where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                                                        and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                                                        and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                                                        and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                                                        and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                                                        and II.OrderIDSeq            = @LVC_OrderIDSeq
--                                                        and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                                                        and II.InvoiceIDSeq          = @InvoiceIDSeq)

					   select @LN_InvoiceTaxAmount = @LV_TaxAmount

					   select @LN_CreditTaxAmount = (select convert(numeric(30,2),sum(CI.TaxAmount))  
													 from Invoices.dbo.CreditMemoItem CI with (nolock)  
													  inner join 
                                                          Invoices.dbo.CreditMemo C with (nolock)  
														on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq  
														and C.CreditStatusCode in ('APPR')  
													  inner join 
                                                          Invoices.dbo.InvoiceItem II with (nolock)  
														 on II.InvoiceGroupIDSeq = CI.InvoiceGroupIDSeq 
                                                        and II.IDSeq = CI.InvoiceItemIDSeq  
													 where CI.InvoiceIDSeq           = @InvoiceIDSeq 
													    and CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
													    and II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
                                                        and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                        and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                        and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                        and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                        and II.OrderIDSeq            = @LVC_OrderIDSeq
                                                        and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                        and II.InvoiceIDSeq          = @InvoiceIDSeq)

					   SELECT @LN_TaxAmount = isnull(@LN_InvoiceTaxAmount,0) - isnull(@LN_CreditTaxAmount,0)
					 end

                       Select @LN_ActualTaxAmount = @LN_TaxAmount
					----------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
--       -- S n H Calc
--                 if not exists (select top 1 1 from Invoices.dbo.CreditMemo with (nolock) where invoiceidseq = @InvoiceIDSeq and CreditStatusCode='APPR' and creditmemoIDseq=@CreditMemoIDSeq)
--					 begin
--						Select @LN_AvailSnHAmount = (select isnull(convert(numeric(30,2),SUM(II.ShippingAndHandlingAmount)),0.00) 
--												from invoices.dbo.invoiceitem II with (nolock) 
--												where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                                                  and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                                                  and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                                                  and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                                                  and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                                                  and II.OrderIDSeq            = @LVC_OrderIDSeq
--                                                  and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                                                  and II.InvoiceIDSeq          = @InvoiceIDSeq
--                                                  and II.IDSeq                 = @LBI_CB_MinInvoiceItemIDSeq)
--					 end
--				 else
--					 begin			  
--					   select @LN_InvoiceSnHAmount = (select isnull(convert(numeric(30,2),SUM(II.ShippingAndHandlingAmount)),0.00)
--                                                      from invoices.dbo.invoiceitem  II with (nolock)
--                                                      where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                                                        and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                                                        and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                                                        and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                                                        and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                                                        and II.OrderIDSeq            = @LVC_OrderIDSeq
--                                                        and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                                                        and II.InvoiceIDSeq          = @InvoiceIDSeq
--                                                        and II.IDSeq                 = @LBI_CB_MinInvoiceItemIDSeq)
--
--					   select @LN_CreditSnHAmount = (select isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00)  
--													 from Invoices.dbo.CreditMemoItem CI with (nolock)  
--													  inner join 
--                                                          Invoices.dbo.CreditMemo C with (nolock)  
--														on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq  
--														and C.CreditStatusCode in ('APPR')  
--													  inner join 
--                                                          Invoices.dbo.InvoiceItem II with (nolock)  
--														 on II.InvoiceGroupIDSeq = CI.InvoiceGroupIDSeq 
--                                                        and II.IDSeq = CI.InvoiceItemIDSeq  
--													 where CI.InvoiceIDSeq           = @InvoiceIDSeq 
--													    and CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
--													    and II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                                                        and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                                                        and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                                                        and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                                                        and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                                                        and II.OrderIDSeq            = @LVC_OrderIDSeq
--                                                        and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                                                        and II.InvoiceIDSeq          = @InvoiceIDSeq
----                                                        and II.IDSeq                 = @LBI_CB_MinInvoiceItemIDSeq
--                                                       )
--
--					   select @LN_AvailSnHAmount = isnull(@LN_InvoiceSnHAmount,0) - isnull(@LN_CreditSnHAmount,0)
--					 end

                       select @LN_SnHAmount = (select isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00)  
													 from Invoices.dbo.CreditMemoItem CI with (nolock)  
													  inner join 
                                                          Invoices.dbo.CreditMemo C with (nolock)  
														on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq  
														and C.CreditStatusCode in ('APPR','PAPR')  
													  inner join 
                                                          Invoices.dbo.InvoiceItem II with (nolock)  
														 on II.InvoiceGroupIDSeq = CI.InvoiceGroupIDSeq 
                                                        and II.IDSeq = CI.InvoiceItemIDSeq  
													 where CI.InvoiceIDSeq           = @InvoiceIDSeq 
													    and CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq 
													    and II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
                                                        and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                        and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                        and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                        and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                        and II.OrderIDSeq            = @LVC_OrderIDSeq
                                                        and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                        and II.InvoiceIDSeq          = @InvoiceIDSeq)
					----------------------------------------------------------------------------------------------
--			           SELECT Top 1 @LN_IDSEQCustomBundle =  II.IDSEQ --AVG(II.TaxPercent) 
--                       from Invoices.dbo.InvoiceItem II with (nolock) 
--                       where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                         and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                         and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                         and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                         and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                         and II.OrderIDSeq            = @LVC_OrderIDSeq
--                         and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                         and II.InvoiceIDSeq          = @InvoiceIDSeq
--					   order by II.taxpercent desc
--------------------------------------------------------------------------------------------------

				INSERT INTO @LT_InvoiceCreditSummary
				(
					IDSeq,
					ProductCode,
					ProductName,
					ChargeType,
					CreditReasonCode,
					CreditMemoItemIDSeq,
					RevisedDate,
					RequestedBy,
					Comments,
					CreditAmount,
					ChargeAmount,
					TaxAmount,
					TaxPercent,
					Total,
					NetPrice,
					TotalCreditAmount,
					TotalTaxAmount,
					AvailableCredit,
					InvoiceItemIDSeq,
					InvoiceGroupIDSeq,
					BillingPeriod,
					CustomBundleNameEnabledFlag,
					DoNotPrintCreditReasonFlag ,
					DoNotPrintCreditCommentsFlag,
                    ReportingTypeCode,
                    ActualTaxAmount,
                    InvoiceTaxAmount,
                    RenewalCount, 
                    InvoiceIDseq,
                    OrderIDSeq,
                    OrderGroupIDSeq,
                    BillingPeriodFromDate,
                    BillingPeriodToDate,
                    ShippingAndHandlingAmount,
                    AvailShippingAndHandlingAmount 
				)
				SELECT  Distinct
				@LN_IDSEQCustomBundle								            as IDSeq,
				NULL					                                        as ProductCode,
				@LVC_GroupName                                                  as ProductName,
				II.chargeTypeCode                                               as ChargeType,
				CM.CreditReasonCode  										    as CreditReasonCode,
				NULL									  						as CreditMemoItemIDSeq,
				CM.RequestedDate                            					as RevisedDate,
				@LVC_RequestedBy												as RequestedBy,
				CM.Comments									       				as Comments,
			 ---------------------------------------------------------------------------
--			 @LN_TotalChargeAmount												as CreditAmount,
--             (@LN_NetCreditAmount-@LN_TaxAmount)								as CreditAmount,
             (@LN_NetCreditAmount)								                as CreditAmount,
			 -----------------------------------------------------------------
			 @LN_TotalChargeAmount												as ChargeAmount,			
             @LN_TaxAmount												    as TaxAmount,
			 ---------------------------------------------------------------
--			(SELECT AVG(II.TaxPercent) 
--			 from Invoices.dbo.InvoiceItem II with (nolock) 
--             where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--               and II.ChargeTypeCode        = @LC_ChargeTypeCode
--               and II.Orderitemrenewalcount = @LBI_RenewalCount	
--               and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--               and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--               and II.OrderIDSeq            = @LVC_OrderIDSeq
--               and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--               and II.InvoiceIDSeq          = @InvoiceIDSeq)                as TaxPercent,

             @LN_TaxPercent                                                 as TaxPercent,
			 ---------------------------------------------------------------
              @LN_NetCreditAmount + @LN_TaxAmount + @LN_SnHAmount          			as Total,
			 ---------------------------------------------------------------
            -- replace with @LN_SumNetPrice for below calc of net price
--			(SELECT SUM(II.NetChargeAmount) + SUM(II.TaxAmount)
--			 from Invoices.dbo.InvoiceItem II with (nolock) 
--             where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--               and II.ChargeTypeCode        = @LC_ChargeTypeCode
--               and II.Orderitemrenewalcount = @LBI_RenewalCount	
--               and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--               and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--               and II.OrderIDSeq            = @LVC_OrderIDSeq
--               and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--               and II.InvoiceIDSeq          = @InvoiceIDSeq)                       as NetPrice,

             @LN_SumNetPrice                                                      as NetPrice,
			 ----------------------------------------------------------------
			 @LN_TotalChargeAmount												  as TotalCreditAmount,
			 ----------------------------------------------------------------
				0																																			as TotalTaxAmount,
			 ----------------------------------------------------------------
  		     @LN_AvailableCredit													     as AvailableCredit,
				NULL																																	as InvoiceItemIDSeq,
				IG.IDSeq                                                      as InvocieGroupIDSeq,
             @LVC_BillingPeriod                                               as BillingPeriod,
				@LVC_CustomBundleNameEnabledFlag                              as CustombundleNameEnabledFlag,
				CM.DoNotPrintCreditReasonFlag								  as DoNotPrintCreditReasonFlag,
			 CM.DoNotPrintCreditCommentsFlag								  as DoNotPrintCreditCommentsFlag,
             II.ReportingTypeCode                                             as ReportingTypeCode,
			 @LN_ActualTaxAmount                                              as ActualTaxAmount,
--             @LN_SumTaxPrice                                                  as InvoiceTaxAmount,
             @LN_TaxAmount                                                 as InvoiceTaxAmount,
             @LBI_RenewalCount                                                as RenewalCount,
             @LVC_InvoiceIDseq                                                as InvoiceIDseq,
             @LVC_OrderIDSeq                                                  as OrderIDSeq,
             @LBI_OrderGroupIDSeq                                             as OrderGroupIDSeq,
             @LDT_BillingPeriodFromDate                                       as BillingPeriodFromDate,
             @LDT_BillingPeriodToDate                                         as BillingPeriodToDate,
             @LN_SnHAmount                                                    as ShippingAndHandlingAmount,
	         @LN_AvailSnHAmount                                               as AvailShippingAndHandlingAmount
		FROM        
             Invoices.dbo.[InvoiceItem] II with (nolock)
		INNER JOIN
             Invoices.dbo.[InvoiceGroup] IG with (nolock)
		  ON  II.InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq
		  AND II.OrderIDSeq = IG.OrderIDSeq 
		  AND IG.OrderGroupIDSeq=II.OrderGroupIDSeq					
		INNER JOIN 
             Invoices.dbo.creditmemo CM with (nolock) 
		  ON  IG.InvoiceIDSeq = CM.InvoiceIDSeq	
          AND CM.CreditMemoIDSeq = @CreditMemoIDSeq
		INNER JOIN 
             Invoices.dbo.[Invoice] I with (nolock)
		  ON I.InvoiceIDSeq = IG.InvoiceIDSeq
		WHERE IG.InvoiceIDSeq          = @InvoiceIDSeq 
		  AND II.ChargeTypeCode        = @LC_ChargeTypeCode
--          AND II.Orderitemrenewalcount = @LBI_RenewalCount	
--          AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--          AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--          AND II.OrderIDSeq            = @LVC_OrderIDSeq
--          AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
          AND II.InvoiceIDSeq                  = @InvoiceIDSeq
          AND CM.CreditMemoIDSeq               = @CreditMemoIDSeq
		  AND @LVC_CustomBundleNameEnabledFlag = 1 
		GROUP BY  II.InvoiceIDSeq,II.ChargeTypeCode, CM.CreditReasonCode, CM.RevisedDate, CM.RequestedDate,
                  CM.RevisedBy, CM.Comments, II.IDSeq, IG.IDSeq, II.InvoiceGroupIDSeq,
                  CM.DoNotPrintCreditReasonFlag,CM.DoNotPrintCreditCommentsFlag,II.ReportingTypeCode
	  END		
--END OF FULL CREDIT
--------------------------------------------------------------------------------------------------------------
	ELSE IF(@Mode = 'PartialCredit')
	  BEGIN
		INSERT INTO @LT_InvoiceCreditSummary
           (
            IDSeq,
            ProductCode,
            ProductName,
            ChargeType,
		    CreditReasonCode,
	        CreditMemoItemIDSeq,
	        RevisedDate,
		    RequestedBy,
		    Comments,
            CreditAmount,
		    ChargeAmount,
            TaxAmount,
            TaxPercent,
            Total,
            NetPrice,
            TotalCreditAmount,
            TotalTaxAmount,
            AvailableCredit,
			InvoiceItemIDSeq,
            InvoiceGroupIDSeq,
            BillingPeriod,
            CustomBundleNameEnabledFlag,
			DoNotPrintCreditReasonFlag,
			DoNotPrintCreditCommentsFlag,
            ReportingTypeCode,
            ActualTaxAmount,
            InvoiceTaxAmount,
            RenewalCount, 
            InvoiceIDseq,
            OrderIDSeq,
            OrderGroupIDSeq,
            BillingPeriodFromDate,
            BillingPeriodToDate,
            ShippingAndHandlingAmount,
            AvailShippingAndHandlingAmount
           )
-------------------------------------------------------------------------------------------------
----------                  Retrives InvocieItem data for Partial Credit Mode
    SELECT DISTINCT 
			@LN_IDSEQCustomBundle          					                as IDSeq,
            NULL							    					        as ProductCode,
            @LVC_GroupName                                                  as ProductName,
            II.chargeTypeCode                                               as ChargeType,
			CM.CreditReasonCode									            as CreditReasonCode,
			NULL									  						as CreditMemoItemIDSeq,
			CM.RequestedDate                            					as RevisedDate,
			@LVC_RequestedBy												as RequestedBy,
			CM.Comments									       				as Comments,
			---------------------------------------------------------------         
            @LN_NetCreditAmount												as CreditAmount,
      --------------------------------------------------------------- 
			@LN_TotalChargeAmount								            as ChargeAmount,
			---------------------------------------------------------------         
            @LN_TaxAmount													as TaxAmount,
      --------------------------------------------------------------- 
            @LN_TaxPercent													as TaxPercent,
			---------------------------------------------------------------
			@LN_NetCreditAmount + @LN_TaxAmount + @LN_SnHAmount             as Total,
			---------------------------------------------------------------
            @LN_SumNetPrice													as NetPrice,
      ---------------------------------------------------------------         
            @LN_SumTotalCreditAmount                                        as TotalCreditAmount,
      ---------------------------------------------------------------   
            @LN_SumTotalTaxAmount                                           as TotalTaxAmount,
      --------------------------------------------------------------
			@LN_AvailableCredit                                             as AvailableCredit,

			NULL                                                            as InvoiceItemIDSeq,
            IG.IDSeq                                                        as InvocieGroupIDSeq,
            @LVC_BillingPeriod                                              as BillingPeriod,
            @LVC_CustomBundleNameEnabledFlag                                as CustombundleNameEnabledFlag,
			CM.DoNotPrintCreditReasonFlag									as DoNotPrintCreditReasonFlag,
			CM.DoNotPrintCreditCommentsFlag									as DoNotPrintCreditCommentsFlag,
            II.ReportingTypeCode                                            as ReportingTypeCode,
            @LN_ActualTaxAmount                                             as ActualTaxAmount,
--            @LN_SumTaxPrice                                                 as InvoiceTaxAmount,
            (@LN_SumTaxPrice - @LN_AvailTaxAmount)                          as InvoiceTaxAmount,
            @LBI_RenewalCount                                               as RenewalCount,
            @LVC_InvoiceIDseq                                               as InvoiceIDseq,
            @LVC_OrderIDSeq                                                 as OrderIDSeq,
            @LBI_OrderGroupIDSeq                                            as OrderGroupIDSeq,
            @LDT_BillingPeriodFromDate                                      as BillingPeriodFromDate,
            @LDT_BillingPeriodToDate                                        as BillingPeriodToDate,
            @LN_SnHAmount                                                    as ShippingAndHandlingAmount,
	        @LN_AvailSnHAmount                                               as AvailShippingAndHandlingAmount
          FROM  Invoices.dbo.[InvoiceItem] II with (nolock)
		  INNER JOIN      
                Invoices.dbo.[InvoiceGroup] IG with (nolock)
			ON  II.InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq
			AND	II.OrderIDSeq = IG.OrderIDSeq 
			AND	IG.OrderGroupIDSeq=II.OrderGroupIDSeq	
			INNER JOIN 
                Invoices.dbo.creditmemo CM with (nolock) 
			ON  IG.InvoiceIDSeq = CM.InvoiceIDSeq	
			INNER JOIN 
                Invoices.dbo.[Invoice] I with (nolock)
			ON  I.InvoiceIDSeq = IG.InvoiceIDSeq
		  WHERE IG.InvoiceIDSeq          = @InvoiceIDSeq 
			AND	II.ChargeTypeCode        = @LC_ChargeTypeCode 
            AND II.Orderitemrenewalcount = @LBI_RenewalCount	
            AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
            AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
            AND II.OrderIDSeq            = @LVC_OrderIDSeq
            AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
            AND II.InvoiceIDSeq          = @InvoiceIDSeq
			AND	CM.CreditMemoIDSeq       = @CreditMemoIDSeq
			AND @LVC_CustomBundleNameEnabledFlag = 1
		  GROUP BY  II.InvoiceIDSeq,II.ChargeTypeCode, CM.CreditReasonCode, CM.RequestedDate,
                    CM.Comments, IG.IDSeq,
                    CM.DoNotPrintCreditReasonFlag,CM.DoNotPrintCreditCommentsFlag,II.ReportingTypeCode
	  END
--END OF PARTIAL CREDIT
--------------------------------------------------------------------------------------------------------------------------

    ELSE IF(@Mode = 'TaxCredit')
	  BEGIN
	    INSERT INTO @LT_InvoiceCreditSummary
           (
            IDSeq,
            ProductCode,
            ProductName,
            ChargeType,
            CreditReasonCode,
		    CreditMemoItemIDSeq,
		    RevisedDate,
		    RequestedBy,
		    Comments,
            CreditAmount,
			ChargeAmount,
            TaxAmount,
            TaxPercent,
            Total,
            NetPrice,
            TotalCreditAmount,
            TotalTaxAmount,
            AvailableCredit,
			InvoiceItemIDSeq,
            InvoiceGroupIDSeq,
            BillingPeriod,
            CustomBundleNameEnabledFlag,
			DoNotPrintCreditReasonFlag ,
			DoNotPrintCreditCommentsFlag,
            ReportingTypeCode,
            ActualTaxAmount,
            InvoiceTaxAmount,
            RenewalCount, 
            InvoiceIDseq,
            OrderIDSeq,
            OrderGroupIDSeq,
            BillingPeriodFromDate,
            BillingPeriodToDate,
            ShippingAndHandlingAmount,
            AvailShippingAndHandlingAmount
           )
					 SELECT  Distinct
						@LN_IDSEQCustomBundle   										as IDSeq,
						NULL					                                        as ProductCode,
						@LVC_GroupName                                                  as ProductName,
						II.chargeTypeCode                                               as ChargeType,
						CM.CreditReasonCode  											as CreditReasonCode,
						NULL									  						as CreditMemoItemIDSeq,
						CM.RequestedDate                            					as RevisedDate,
						@LVC_RequestedBy												as RequestedBy,
						CM.Comments									       				as Comments,
					 ---------------------------------------------------------------------------
					 0																	as CreditAmount,
					 -----------------------------------------------------------------
					 @LN_TotalChargeAmount												as ChargeAmount,
					 @LN_TaxAmount                                                      as TaxAmount,
					 ---------------------------------------------------------------
--					(SELECT AVG(II.TaxPercent) 
--					from Invoices.dbo.InvoiceItem II with (nolock) 
--                    where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                      and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                      and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                      and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                      and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                      and II.OrderIDSeq            = @LVC_OrderIDSeq
--                      and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                      and II.InvoiceIDSeq          = @InvoiceIDSeq)  	 as TaxPercent,

                     @LN_TaxPercent                                                    as TaxPercent,
					 ---------------------------------------------------------------
                     @LN_TaxAmount                                                     as Total,
--					 @LN_TotalChargeAmount																					 as Total,
					 ---------------------------------------------------------------
            -- replace with @LN_SumNetPrice for below calc of net price
--					(SELECT SUM(II.NetChargeAmount) + SUM(II.TaxAmount)
--					from Invoices.dbo.InvoiceItem II with (nolock) 
--                    where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                      and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                      and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                      and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                      and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                      and II.OrderIDSeq            = @LVC_OrderIDSeq
--                      and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                      and II.InvoiceIDSeq          = @InvoiceIDSeq)		               as NetPrice,

                     @LN_SumNetPrice                                                  as NetPrice,
					 ----------------------------------------------------------------
            -- replace with @LN_SumTaxPrice for below calc of net price
--					(SELECT SUM(II.TaxAmount) 
--					from Invoices.dbo.InvoiceItem II with (nolock) 
--                    where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                      and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                      and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                      and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                      and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                      and II.OrderIDSeq            = @LVC_OrderIDSeq
--                      and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                      and II.InvoiceIDSeq          = @InvoiceIDSeq)		               as TotalCreditAmount,

                     @LN_SumTaxPrice                                                  as TotalCreditAmount,
					 ----------------------------------------------------------------
            -- replace with @LN_SumTaxPrice for below calc of net price
--					(SELECT SUM(II.TaxAmount) 
--					from Invoices.dbo.InvoiceItem II with (nolock) 
--                    where II.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
--                      and II.ChargeTypeCode        = @LC_ChargeTypeCode
--                      and II.Orderitemrenewalcount = @LBI_RenewalCount	
--                      and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
--                      and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
--                      and II.OrderIDSeq            = @LVC_OrderIDSeq
--                      and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
--                      and II.InvoiceIDSeq          = @InvoiceIDSeq)                   as TotalTaxAmount,

                     @LN_SumTaxPrice                                                  as TotalTaxAmount,
					 ----------------------------------------------------------------

						@LN_AvailableCredit										      as AvailableCredit,
						NULL														  as InvoiceItemIDSeq,
						IG.IDSeq                                                      as InvocieGroupIDSeq,
                        @LVC_BillingPeriod                                            as BillingPeriod,
						@LVC_CustomBundleNameEnabledFlag                              as CustombundleNameEnabledFlag,
						CM.DoNotPrintCreditReasonFlag							      as DoNotPrintCreditReasonFlag,
						CM.DoNotPrintCreditCommentsFlag								  as DoNotPrintCreditCommentsFlag,
                        II.ReportingTypeCode                                          as ReportingTypeCode,
                        @LN_ActualTaxAmount                                           as ActualTaxAmount,
--                        @LN_SumTaxPrice                                               as InvoiceTaxAmount,
                        @LN_TaxAmount                                                 as InvoiceTaxAmount,
                        @LBI_RenewalCount                                             as RenewalCount,
                        @LVC_InvoiceIDseq                                             as InvoiceIDseq,
                        @LVC_OrderIDSeq                                               as OrderIDSeq,
                        @LBI_OrderGroupIDSeq                                          as OrderGroupIDSeq,
                        @LDT_BillingPeriodFromDate                                    as BillingPeriodFromDate,
                        @LDT_BillingPeriodToDate                                      as BillingPeriodToDate,
                        0                                                             as ShippingAndHandlingAmount,
                        @LN_AvailSnHAmount                                            as AvailShippingAndHandlingAmount
					FROM  Invoices.dbo.[InvoiceItem] II (nolock)
					INNER JOIN 
                          Invoices.dbo.[InvoiceGroup] IG (nolock)
					   ON  II.InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq
					   AND II.OrderIDSeq = IG.OrderIDSeq 
					   AND IG.OrderGroupIDSeq=II.OrderGroupIDSeq	
					INNER JOIN 
                          Invoices.dbo.creditmemo CM (nolock) 
					   ON IG.InvoiceIDSeq = CM.InvoiceIDSeq	
					INNER JOIN 
                          Invoices.dbo.[Invoice] I (nolock)
					   ON I.InvoiceIDSeq = IG.InvoiceIDSeq
					WHERE IG.InvoiceIDSeq           = @InvoiceIDSeq 
					   AND II.ChargeTypeCode        = @LC_ChargeTypeCode
                       AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                       AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                       AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                       AND II.OrderIDSeq            = @LVC_OrderIDSeq
                       AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                       AND II.InvoiceIDSeq          = @InvoiceIDSeq 
					   AND CM.CreditMemoIDSeq       = @CreditMemoIDSeq
					   AND @LVC_CustomBundleNameEnabledFlag = 1
					GROUP BY II.InvoiceIDSeq,II.ChargeTypeCode, CM.CreditReasonCode, CM.RevisedDate, CM.RequestedDate,
                             CM.RevisedBy, CM.Comments, II.IDSeq, IG.IDSeq, II.InvoiceGroupIDSeq,
                             CM.DoNotPrintCreditReasonFlag,CM.DoNotPrintCreditCommentsFlag,II.ReportingTypeCode		
			END
-----END OF TAX CREDIT
------------------------------------------------------------------------------------------------------------------
			SET @LV_Counter = @LV_Counter + 1
		END
	END
---------------------------------------------------------------------------------------
-----If CustomBundleEnabledFlag is 0
----------------------------------------------------------------------------------------- 
	ELSE 
		BEGIN
		IF(@Mode = 'PartialCredit')
			BEGIN
				INSERT INTO @LT_InvoiceGroupSummary
				(   CreditMemoItemIDSeq,
					InvoiceIDSeq,
					InvoiceItemIDSeq,
					InvoiceGroupIDSeq,
					GroupName,
					CustomBundleNameEnabledFlag,
					ChargeTypeCode,
                    ReportingTypeCode,
                    RenewalCount,
                    OrderIDSeq,
                    OrderGroupIDSeq,
                    BillingPeriodFromDate,
                    BillingPeriodToDate
				)
				 select CMI.IDSEq,InvoiceID,InvIIDSeq,
                        InvGrIDSEq,IGName,IGFlag,ChType,RTCode,
                        RCount,OrderID,OrderGrpID,BillingFrom,BillingTo 
				 from Invoices.dbo.CreditMemoItem CMI with (nolock)
                 right Join 
					(SELECT  II.Invoiceidseq                as InvoiceID,
                             II.IDSeq                       as InvIIDSeq,
                             IG.IDSeq                       as InvGrIDSEq ,
                             IG.[Name]                      as IGName,
                             IG.CustomBundleNameEnabledFlag as IGFlag, 
                             II.ChargeTypeCode              as ChType,
	                         II.ReportingTypeCode           as RTCode,
	                         II.OrderItemRenewalCount       as RCount,
                             II.OrderIDSeq                  as OrderID,
                             II.OrderGroupIDSeq             as OrderGrpID,
	                         II.BillingPeriodFromDate       as BillingFrom,
                             II.BillingPeriodToDate         as BillingTo 
					 FROM  Invoices.dbo.InvoiceGroup IG with (nolock)
					 INNER JOIN 
                           Invoices.dbo.InvoiceItem II  with (nolock)
                        ON IG.InvoiceIDSeq    = II.InvoiceIDSeq
                       and IG.IDSeq           = II.InvoiceGroupIDSeq
                       and IG.OrderIDSeq      = II.OrderIDSeq
                       and IG.OrderGroupIDSeq = II.OrderGroupIDSeq
					 WHERE IG.InvoiceIDSeq = @InvoiceIDSeq ) as  temp 
                 On  CMI.InvoiceGroupIDSeq = temp.InvGrIDSeq 
                 and CMI.creditmemoidseq   = @CreditMemoIDSeq 
                 and temp.InvIIDSeq        = CMI.invoiceitemidseq
			END
		Else
			BEGIN
				INSERT INTO @LT_InvoiceGroupSummary
				(   CreditMemoItemIDSeq,
					InvoiceIDSeq,
					InvoiceItemIDSeq,
					InvoiceGroupIDSeq,
					GroupName,
					CustomBundleNameEnabledFlag,
					ChargeTypeCode,
                    ReportingTypeCode,
                    RenewalCount,
                    OrderIDSeq,
                    OrderGroupIDSeq,
                    BillingPeriodFromDate,
                    BillingPeriodToDate
				)
                 select CMI.IDSEq,InvoiceID,InvIIDSeq,
                        InvGrIDSEq,IGName,IGFlag,ChType,RTCode,
                        RCount,OrderID,OrderGrpID,BillingFrom,BillingTo 
				 from Invoices.dbo.CreditMemoItem CMI with (nolock)
                 Join 
					(SELECT  II.Invoiceidseq                as InvoiceID,
                             II.IDSeq                       as InvIIDSeq,
                             IG.IDSeq                       as InvGrIDSEq ,
                             IG.[Name]                      as IGName,
                             IG.CustomBundleNameEnabledFlag as IGFlag, 
                             II.ChargeTypeCode              as ChType,
	                         II.ReportingTypeCode           as RTCode,
	                         II.OrderItemRenewalCount       as RCount,
                             II.OrderIDSeq                  as OrderID,
                             II.OrderGroupIDSeq             as OrderGrpID,
	                         II.BillingPeriodFromDate       as BillingFrom,
                             II.BillingPeriodToDate         as BillingTo 
					 FROM  Invoices.dbo.InvoiceGroup IG with (nolock)
					 INNER JOIN 
                           Invoices.dbo.InvoiceItem II  with (nolock)
                        ON IG.InvoiceIDSeq    = II.InvoiceIDSeq
                       and IG.IDSeq           = II.InvoiceGroupIDSeq
                       and IG.OrderIDSeq      = II.OrderIDSeq
                       and IG.OrderGroupIDSeq = II.OrderGroupIDSeq
					 WHERE IG.InvoiceIDSeq = @InvoiceIDSeq ) as  temp 
                 On  CMI.InvoiceGroupIDSeq = temp.InvGrIDSeq 
                 and CMI.creditmemoidseq   = @CreditMemoIDSeq 
                 and temp.InvIIDSeq        = CMI.invoiceitemidseq
		END
		
		SELECT @LV_RowCount = count(*) FROM @LT_InvoiceGroupSummary
  
		SET @LV_Counter = 1
	  
		Declare @LN_ChargeAmount                 numeric(30,2)
		Declare @LVC_InvoiceItemIDSeq            bigint
		Declare @LVC_CreditMemoItemIDSeq         bigint
  
		WHILE @LV_Counter < = @LV_RowCount
		BEGIN
			SELECT @LVC_CustomBundleNameEnabledFlag = CustomBundleNameEnabledFlag,
				   @LVC_InvoiceGroupIDSeq     = InvoiceGroupIDSeq,
                   @LVC_GroupName             = GroupName,
				   @LC_ChargeTypeCode         = ChargeTypeCode,
                   @LVC_InvoiceItemIDSeq      = InvoiceItemIDSeq,
				   @LVC_CreditMemoItemIDSeq   = CreditMemoItemIDSeq,
                   @InvoiceIDSeq              = InvoiceIDSeq,
                   @LC_ReportingTypeCode      = ReportingTypeCode,    
                   @LBI_RenewalCount          = RenewalCount,         
                   @LVC_OrderIDSeq            = OrderIDSeq,
                   @LBI_OrderGroupIDSeq       = OrderGroupIDSeq,
                   @LDT_BillingPeriodFromDate = BillingPeriodFromDate,
                   @LDT_BillingPeriodToDate   = BillingPeriodToDate
			FROM  @LT_InvoiceGroupSummary 
            WHERE RowNumber = @LV_Counter 		 
-----------------------------------------------------------------------------------------
	    SELECT @LN_ChargeAmount = NetChargeAmount 
        from  Invoices.dbo.InvoiceItem with (nolock) 
        WHERE InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
		  AND ChargeTypeCode        = @LC_ChargeTypeCode
          AND Orderitemrenewalcount = @LBI_RenewalCount	
          AND BillingPeriodFromDate = @LDT_BillingPeriodFromDate
          AND BillingPeriodToDate   = @LDT_BillingPeriodToDate
          AND OrderIDSeq            = @LVC_OrderIDSeq
          AND OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
          AND InvoiceIDSeq          = @InvoiceIDSeq
          and IDSEq                 = @LVC_InvoiceItemIDSeq
	--------------------------------------------------------------------------------------------------
		IF(@Mode = 'FullCredit')
		BEGIN
-------------------------------------------------------------------------------------------------
----------                 Retrives InvocieItem data for Full Credit Mode
    INSERT INTO @LT_InvoiceCreditSummary
               (
				IDSeq,
				ProductCode,
				ProductName,
				ChargeType,
				CreditReasonCode,
				CreditMemoItemIDSeq,
				RevisedDate,
				RequestedBy,
				Comments,
				CreditAmount,
				ChargeAmount,
				TaxAmount,
				TaxPercent,
				Total,
				NetPrice,
				TotalCreditAmount,
				TotalTaxAmount,
				AvailableCredit,
				InvoiceItemIDSeq,
				InvoiceGroupIDSeq,
				BillingPeriod,
				CustomBundleNameEnabledFlag,
				DoNotPrintCreditReasonFlag ,
				DoNotPrintCreditCommentsFlag,
                ReportingTypeCode,
                ActualTaxAmount,
                InvoiceTaxAmount,
                RenewalCount, 
                InvoiceIDseq,
                OrderIDSeq,
                OrderGroupIDSeq,
                BillingPeriodFromDate,
                BillingPeriodToDate,
                ShippingAndHandlingAmount,
                AvailShippingAndHandlingAmount
              )
    SELECT  
			II.IDSeq											    as IDSeq,
            II.ProductCode                                                  as ProductCode,
            (Case when II.Measurecode = 'TRAN' then II.TransactionItemName 
               else P.DisplayName  
             end)                                                           as ProductName,
            II.chargeTypeCode                                               as ChargeType,
			CM.CreditReasonCode  										    as CreditReasonCode,
			@LVC_CreditMemoItemIDSeq									    as CreditMemoItemIDSeq,
			convert(varchar(15),CM.RequestedDate,101)                       as RevisedDate,
			@LVC_RequestedBy												as RequestedBy,
			CM.Comments									       				as Comments,
       ---------------------------------------------------------------------------
		CASE 
            WHEN isnull((
                    select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
                    from  Invoices.dbo.CreditMemoItem CI with (nolock)
					inner join 
                          Invoices.dbo.CreditMemo C  with (nolock)
					  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					  and C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq  ) - (select  convert(numeric(30,2),sum(CI.DiscountCreditAmount))  
                                                               from  Invoices.dbo.CreditMemoItem CI with (nolock) 
					                                           inner join 
                                                                     Invoices.dbo.CreditMemo C with (nolock)
					                                             on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					                                             and C.CreditStatusCode in ('PAPR')
                                                                where CI.InvoiceItemIDSeq = II.IDSeq ), 0) <0 
            THEN 0 
          ELSE isnull((
                    select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
					inner join 
                          Invoices.dbo.CreditMemo C with (nolock)
					  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					  and  C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq ) - (select  convert(numeric(30,2),sum(CI.DiscountCreditAmount))  
                                                              from   Invoices.dbo.CreditMemoItem CI with (nolock) 
					                                          inner join 
                                                                     Invoices.dbo.CreditMemo C with (nolock)
					                                             on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					                                             and C.CreditStatusCode in ('PAPR')
                                                              where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 

            END                                                             as CreditAmount,
       -----------------------------------------------------------------
		@LN_ChargeAmount													  as ChargeAmount,
       -----------------------------------------------------------------
           CASE 
            WHEN isnull((
                    select  convert(numeric(30,2),sum(CI.TaxAmount))  
                    from  Invoices.dbo.CreditMemoItem CI with (nolock) 
					inner join 
                          Invoices.dbo.CreditMemo C with (nolock)
					  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					  and C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq  ), 0) <0 
            THEN 0 
            ELSE isnull((
                    select  convert(numeric(30,2),sum(CI.TaxAmount))  
                    from  Invoices.dbo.CreditMemoItem CI with (nolock) 
					inner join 
                          Invoices.dbo.CreditMemo C with (nolock)
					  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					  and C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
            END                                                               as TaxAmount,
         ---------------------------------------------------------------

        II.TaxPercent                                                         as TaxPercent,
         ---------------------------------------------------------------

        CASE 
          WHEN isnull(convert(numeric(30,2),(II.NetChargeAmount + II.TaxAmount  + II.ShippingAndHandlingAmount - 
                                                                                 (select  isnull(convert(numeric(30,2),sum(CI.NetCreditAmount)),0.00) + 
                                                                                          isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00) 
                                                                                  from   Invoices.dbo.CreditMemoItem CI with (nolock)
			                                                                      inner join 
                                                                                         Invoices.dbo.CreditMemo C with (nolock)
					                                                                 on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					                                                                 and C.CreditStatusCode in ('APPR')
                                                                                  where CI.InvoiceItemIDSeq = II.IDSeq))),II.NetChargeAmount) < 0 
          THEN 0 
          ELSE isnull(convert(numeric(30,2),(II.NetChargeAmount + II.TaxAmount  + II.ShippingAndHandlingAmount - 
                                                                                 (select  isnull(convert(numeric(30,2),sum(CI.NetCreditAmount)),0.00) + 
                                                                                          isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00)  
                                                                                  from   Invoices.dbo.CreditMemoItem CI with (nolock)
		                                                                          inner join 
                                                                                          Invoices.dbo.CreditMemo C with (nolock)
		                                                                              on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					                                                                  and C.CreditStatusCode in ('APPR')
		                                                                          where CI.InvoiceItemIDSeq = II.IDSeq))),II.NetChargeAmount + II.TaxAmount) 
          
        END                                                                 as Total,
        ---------------------------------------------------------------
        convert(numeric(10,3),convert(numeric(30,2),II.NetChargeAmount + II.TaxAmount),101)  as NetPrice,
         ----------------------------------------------------------------
        (CASE 
          WHEN isnull(
                      (select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
                       from   Invoices.dbo.CreditMemoItem CI with (nolock) 
					   inner join 
                              Invoices.dbo.CreditMemo C with (nolock)
					      on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					      and C.CreditStatusCode in ('APPR')
                       where CI.InvoiceItemIDSeq = II.IDSeq ), 0)<0 
          THEN 0 
          ELSE isnull(
                      (select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
                       from   Invoices.dbo.CreditMemoItem CI with (nolock) 
					   inner join 
                              Invoices.dbo.CreditMemo C with (nolock)
					      on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					      and C.CreditStatusCode in ('APPR')
                       where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
          END)                                                             as TotalCreditAmount,
         ----------------------------------------------------------------
        (CASE 
          WHEN isnull(
                      (select  convert(numeric(30,2),sum(CI.TaxAmount))  
                       from  Invoices.dbo.CreditMemoItem CI with (nolock)
			           inner join 
                             Invoices.dbo.CreditMemo C with (nolock)
			             on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					     and C.CreditStatusCode in ('APPR') 
                       where CI.InvoiceItemIDSeq = II.IDSeq ), 0) <0  
            THEN 0 
          ELSE isnull(
                      (select  convert(numeric(30,2),sum(CI.TaxAmount))  
                       from  Invoices.dbo.CreditMemoItem CI with (nolock)
			           inner join 
                             Invoices.dbo.CreditMemo C with (nolock)
			             on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					     and C.CreditStatusCode in ('APPR')
                       where CI.InvoiceItemIDSeq = II.IDSeq ), 0)   
          END )                                                                as TotalTaxAmount,      
         ----------------------------------------------------------------
        ((II.NetChargeAmount)  - ((CASE 
									  WHEN isnull(
										          (select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
												   from  Invoices.dbo.CreditMemoItem CI with (nolock) 
												   inner join 
                                                         Invoices.dbo.CreditMemo C with (nolock)
												     on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
													 and C.CreditStatusCode in ('APPR')
												   where CI.InvoiceItemIDSeq = II.IDSeq ), 0)<0 
									    THEN 0 
									  ELSE isnull(
										          (select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
												   from   Invoices.dbo.CreditMemoItem CI with (nolock) 
												   inner join 
                                                          Invoices.dbo.CreditMemo C with (nolock)
												      on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
													  and C.CreditStatusCode in ('APPR')
												    where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
									  END)  
                                   ))                                                                      as AvailableCredit,
         ----------------------------------------------------------------
		II.IDSeq											               as InvoiceItemIDSeq,
        IG.IDSeq                                                           as InvocieGroupIDSeq,
        convert(varchar(11),II.BillingPeriodFromDate,101) +
               ' - ' + convert(varchar(11),II.BillingPeriodToDate,101)     as BillingPeriod,
        @LVC_CustomBundleNameEnabledFlag                                   as CustombundleNameEnabledFlag,
		CM.DoNotPrintCreditReasonFlag									   as DoNotPrintCreditReasonFlag,
		CM.DoNotPrintCreditCommentsFlag								       as DoNotPrintCreditCommentsFlag,
        II.ReportingTypeCode                                               as ReportingTypeCode,
         ----------------------------------------------------------------
        (CASE 
            WHEN isnull(
                        (select  convert(numeric(30,2),sum(CI.TaxAmount))  
                         from  Invoices.dbo.CreditMemoItem CI with (nolock) 
					     inner join 
                               Invoices.dbo.CreditMemo C with (nolock)
					       on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					       and C.CreditStatusCode in ('PAPR')
                         where CI.InvoiceItemIDSeq = II.IDSeq  ), 0) <0 
               THEN 0 
            ELSE isnull(
                        (select  convert(numeric(30,2),sum(CI.TaxAmount))  
                         from Invoices.dbo.CreditMemoItem CI with (nolock) 
					     inner join 
                              Invoices.dbo.CreditMemo C with (nolock)
					       on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					      and C.CreditStatusCode in ('PAPR')
                         where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
            END)                                                           as ActualTaxAmount,
         ----------------------------------------------------------------
          ( CASE 
                    WHEN  isnull(convert(numeric(30,2),(II.TaxAmount - 
                                                                  (select  convert(numeric(30,2),sum(CI.TaxAmount))  
								                                   from Invoices.dbo.CreditMemoItem CI with (nolock)
								                                    inner join 
                                                                           Invoices.dbo.CreditMemo C with (nolock)
								                                       on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								                                       and C.CreditStatusCode in ('APPR')
								                                       and II.IDSeq                 = CI.InvoiceItemIDSeq
								                                   where CI.InvoiceIDSeq            = @InvoiceIDSeq	
								                                       and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                                       AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                                       AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                                       AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                                       AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                                                       AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                                       AND II.InvoiceIDSeq          = @InvoiceIDSeq))), II.TaxAmount) < 0 
                  THEN 0 
              ELSE  isnull(convert(numeric(30,2),(II.TaxAmount - 
                                                                  (select  convert(numeric(30,2),sum(CI.TaxAmount))  
								                                   from Invoices.dbo.CreditMemoItem CI with (nolock)
								                                    inner join 
                                                                           Invoices.dbo.CreditMemo C with (nolock)
								                                       on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								                                       and C.CreditStatusCode in ('APPR')
								                                       and II.IDSeq                 = CI.InvoiceItemIDSeq
								                                   where CI.InvoiceIDSeq            = @InvoiceIDSeq	
								                                       and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                                       AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                                       AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                                       AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                                       AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                                                       AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                                       AND II.InvoiceIDSeq          = @InvoiceIDSeq))), II.TaxAmount) 
             END )                                                                          as InvoiceTaxAmount,
          ----------------------------------------------------------------
         II.OrderItemRenewalCount                                          as RenewalCount,
          ----------------------------------------------------------------
         II.InvoiceIDseq                                                   as InvoiceIDseq,
          ----------------------------------------------------------------
         II.OrderIDSeq                                                     as OrderIDSeq,
          ----------------------------------------------------------------
         II.OrderGroupIDSeq                                                as OrderGroupIDSeq,
          ----------------------------------------------------------------
         II.BillingPeriodFromDate                                          as BillingPeriodFromDate,
          ----------------------------------------------------------------
         II.BillingPeriodToDate                                            as BillingPeriodToDate,
          -----------------------------------------------------------------
         ((II.ShippingAndHandlingAmount)  - ((CASE 
												  WHEN isnull(
													  (select  isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00)  
													   from  Invoices.dbo.CreditMemoItem CI with (nolock) 
													   inner join 
															 Invoices.dbo.CreditMemo C with (nolock)
														 on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
														 and C.CreditStatusCode in ('APPR')
													   where CI.InvoiceItemIDSeq = II.IDSeq ), 0)<0 
													THEN 0 
												  ELSE isnull(
													  (select  isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00)  
													   from   Invoices.dbo.CreditMemoItem CI with (nolock) 
													   inner join 
															  Invoices.dbo.CreditMemo C with (nolock)
														  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
														  and C.CreditStatusCode in ('APPR')
														where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
												  END)
											   ))                                      as ShippingAndHandlingAmount,
          --------------------------------------------------------------------------------------------------------------------------
         ((II.ShippingAndHandlingAmount)  - ((CASE 
												  WHEN isnull(
													  (select  isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00)  
													   from  Invoices.dbo.CreditMemoItem CI with (nolock) 
													   inner join 
															 Invoices.dbo.CreditMemo C with (nolock)
														 on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
														 and C.CreditStatusCode in ('APPR')
													   where CI.InvoiceItemIDSeq = II.IDSeq ), 0)<0 
													THEN 0 
												  ELSE isnull(
													  (select  isnull(convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount)),0.00)  
													   from   Invoices.dbo.CreditMemoItem CI with (nolock) 
													   inner join 
															  Invoices.dbo.CreditMemo C with (nolock)
														  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
														  and C.CreditStatusCode in ('APPR')
														where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
												  END)
											   ))                          as AvailShippingAndHandlingAmount
          --------------------------------------------------------------------------------------------------------------------------
        FROM   Invoices.dbo.[InvoiceItem] II with (nolock)        
         INNER JOIN      
               Invoices.dbo.[InvoiceGroup] IG with (nolock)
			ON  II.InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq
			AND II.OrderIDSeq        = IG.OrderIDSeq 
			AND IG.OrderGroupIDSeq   = II.OrderGroupIDSeq
            AND II.ChargeTypeCode        = @LC_ChargeTypeCode
            AND II.Orderitemrenewalcount = @LBI_RenewalCount	
            AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
            AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
            AND II.OrderIDSeq            = @LVC_OrderIDSeq
            AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
            AND II.InvoiceIDSeq          = @InvoiceIDSeq 
            AND II.IDSeq                 = @LVC_InvoiceItemIDSeq	
		 LEFT OUTER JOIN      
               Invoices.dbo.creditmemo CM  with (nolock) 
			ON  IG.InvoiceIDSeq    = CM.InvoiceIDSeq	
            AND CM.creditmemoIDSeq = @CreditMemoIDSeq
         LEFT OUTER JOIN 
               Invoices.dbo.[Invoice] I with (nolock)
            ON  I.InvoiceIDSeq  = IG.InvoiceIDSeq
         LEFT OUTER JOIN 
               Products.dbo.Product P   with (nolock)
            ON  II.ProductCode  = P.Code
            AND II.PriceVersion = P.PriceVersion
        WHERE   IG.InvoiceIDSeq = @InvoiceIDSeq 
--            AND II.ExtChargeAmount  > II.CreditAmount
            AND II.ChargeTypeCode = @LC_ChargeTypeCode
            AND II.Orderitemrenewalcount = @LBI_RenewalCount	
            AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
            AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
            AND II.OrderIDSeq            = @LVC_OrderIDSeq
            AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
            AND II.InvoiceIDSeq          = @InvoiceIDSeq 
            AND II.IDSeq                 = @LVC_InvoiceItemIDSeq 
			AND @LVC_CustomBundleNameEnabledFlag = 0
        ORDER BY P.DisplayName,II.TransactionItemName,II.TransactionDate
	END  

	ELSE	IF(@Mode = 'TaxCredit')
  BEGIN
      INSERT INTO @LT_InvoiceCreditSummary
       (
        IDSeq,
				ProductCode,
				ProductName,
				ChargeType,
				CreditReasonCode,
				CreditMemoItemIDSeq,
				RevisedDate,
				RequestedBy,
				Comments,
				CreditAmount,
				ChargeAmount,
				TaxAmount,
				TaxPercent,
				Total,
				NetPrice,
				TotalCreditAmount,
				TotalTaxAmount,
				AvailableCredit,
				InvoiceItemIDSeq,
				InvoiceGroupIDSeq,
				BillingPeriod,
				CustomBundleNameEnabledFlag,
				DoNotPrintCreditReasonFlag,
				DoNotPrintCreditCommentsFlag,
                ReportingTypeCode,
                ActualTaxAmount,
                InvoiceTaxAmount,
                RenewalCount, 
                InvoiceIDseq,
                OrderIDSeq,
                OrderGroupIDSeq,
                BillingPeriodFromDate,
                BillingPeriodToDate,
                ShippingAndHandlingAmount,
                AvailShippingAndHandlingAmount        
       )
-------------------------------------------------------------------------------------------------
----------                  Retrives InvocieItem data for Full Tax Mode
-------------------------------------------------------------------------------------------------
      SELECT  
			II.IDSeq                                               as IDSeq,
            II.ProductCode                                                  as ProductCode,
            (Case when II.Measurecode = 'TRAN' then II.TransactionItemName 
                else P.DisplayName  
             end)                                                           as ProductName,
            II.chargeTypeCode                                               as ChargeType,
			CM.CreditReasonCode  				                            as CreditReasonCode,
			@LVC_CreditMemoItemIDSeq										as CreditMemoItemIDSeq,
			convert(varchar(15),CM.RequestedDate,101)                       as RevisedDate,
			CM.RevisedBy							                        as RequestedBy,
			CM.Comments									       			    as Comments,							
            0                                                               as CreditAmount,
			@LN_ChargeAmount												as ChargeAmount,
            ---------------------------------------------------------------
            (CASE 
				  WHEN isnull((select convert(numeric(30,2),sum(CI.TaxAmount))  
							   from Invoices.dbo.CreditMemoItem CI with (nolock) 
							   inner join 
                                    Invoices.dbo.CreditMemo C with (nolock)
							      on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                                  and II.IDSeq = CI.InvoiceItemIDSeq
								  and C.CreditStatusCode in ('PAPR')
								where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
                                  and II.InvoiceGroupIdSeq     = @LVC_InvoiceGroupIDSeq
                                  and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                  and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                  and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                  and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                  and II.OrderIDSeq            = @LVC_OrderIDSeq
                                  and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                  and II.InvoiceIDSeq          = @InvoiceIDSeq), 0) < 0 
			  THEN 0 
			ELSE isnull((select convert(numeric(30,2),sum(CI.TaxAmount))  
			             from  Invoices.dbo.CreditMemoItem CI with (nolock) 
						 inner join 
                                Invoices.dbo.CreditMemo C with (nolock)
							on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                            and II.IDSeq = CI.InvoiceItemIDSeq
							and  C.CreditStatusCode in ('PAPR')
						 where CI.InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq
                            and II.InvoiceGroupIdSeq = @LVC_InvoiceGroupIDSeq
                            and II.ChargeTypeCode = @LC_ChargeTypeCode
                            and II.Orderitemrenewalcount = @LBI_RenewalCount	
                            and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                            and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                            and II.OrderIDSeq            = @LVC_OrderIDSeq
                            and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                            and II.InvoiceIDSeq          = @InvoiceIDSeq), 0)
			END)                                                                   as TaxAmount,  
             ----------------------------------------------------------------
             II.TaxPercent                                                         as TaxPercent,
             ----------------------------------------------------------------                
            (CASE 
				  WHEN isnull((select convert(numeric(30,2),sum(CI.TaxAmount))  
							   from  Invoices.dbo.CreditMemoItem CI with (nolock) 
						       inner join 
                                      Invoices.dbo.CreditMemo C with (nolock)
							      on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                                  and II.IDSeq = CI.InvoiceItemIDSeq
								  and  C.CreditStatusCode in ('PAPR')
							   where CI.InvoiceGroupIDSeq      = @LVC_InvoiceGroupIDSeq
                                  and II.InvoiceGroupIdSeq     = @LVC_InvoiceGroupIDSeq
                                  and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                  and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                  and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                  and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                  and II.OrderIDSeq            = @LVC_OrderIDSeq
                                  and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                  and II.InvoiceIDSeq          = @InvoiceIDSeq), 0) < 0 
				THEN 0 
			ELSE      isnull((select convert(numeric(30,2),sum(CI.TaxAmount))  
							   from  Invoices.dbo.CreditMemoItem CI with (nolock) 
						       inner join 
                                      Invoices.dbo.CreditMemo C with (nolock)
							      on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                                  and II.IDSeq = CI.InvoiceItemIDSeq
								  and  C.CreditStatusCode in ('PAPR')
							   where CI.InvoiceGroupIDSeq      = @LVC_InvoiceGroupIDSeq
                                  and II.InvoiceGroupIdSeq     = @LVC_InvoiceGroupIDSeq
                                  and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                  and II.Orderitemrenewalcount = @LBI_RenewalCount	
                                  and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                  and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                  and II.OrderIDSeq            = @LVC_OrderIDSeq
                                  and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                  and II.InvoiceIDSeq          = @InvoiceIDSeq), 0)
			END)                                                                          as Total,
              ---------------------------------------------------------------
              convert(numeric(30,2),II.NetChargeAmount)                                   as NetPrice,
              ---------------------------------------------------------------
              isnull((select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
                      from   Invoices.dbo.CreditMemoItem CI with (nolock) 
					  inner join 
                             Invoices.dbo.CreditMemo C with (nolock)
					     on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					     and C.CreditStatusCode in ('APPR')
                      where CI.InvoiceItemIDSeq = II.IDSeq), 0)                           as TotalCreditAmount,
              ----------------------------------------------------------------
              isnull((select  convert(numeric(30,2),sum(CI.TaxAmount))  
                      from  Invoices.dbo.CreditMemoItem CI with (nolock)
					  inner join 
                            Invoices.dbo.CreditMemo C with (nolock)
					    on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					    and C.CreditStatusCode in ('APPR') 
                      where CI.InvoiceItemIDSeq = II.IDSeq ), 0)                          as TotalTaxAmount,
              ----------------------------------------------------------------
             ((II.NetChargeAmount)  - ((CASE 
											WHEN isnull(
											            (select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
														 from  Invoices.dbo.CreditMemoItem CI with (nolock) 
														 inner join 
                                                                Invoices.dbo.CreditMemo C with (nolock)
														    on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
														    and C.CreditStatusCode in ('APPR')
														  where CI.InvoiceItemIDSeq = II.IDSeq ), 0)<0 
											THEN 0 
										ELSE    isnull(
											           (select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
														from  Invoices.dbo.CreditMemoItem CI with (nolock) 
														inner join 
                                                               Invoices.dbo.CreditMemo C with (nolock)
														   on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
														   and C.CreditStatusCode in ('APPR')
														where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
										END) 
                                        ))                                                  as AvailableCredit,
          ------------------------------------------------------------------------------
		  II.IDSeq											              as InvoiceItemIDSeq,
          IG.IDSeq                                                        as InvocieGroupIDSeq,
          convert(varchar(11),II.BillingPeriodFromDate,101) +
               ' - ' + convert(varchar(11),II.BillingPeriodToDate,101)    as BillingPeriod,    
          @LVC_CustomBundleNameEnabledFlag								  as CustombundleNameEnabledFlag,
		  CM.DoNotPrintCreditReasonFlag									  as DoNotPrintCreditReasonFlag,
		  CM.DoNotPrintCreditCommentsFlag								  as DoNotPrintCreditCommentsFlag,             
          II.ReportingTypeCode                                            as ReportingTypeCode,
          ------------------------------------------------------------------------------
           ( CASE 
				WHEN isnull((select convert(numeric(30,2),sum(CI.TaxAmount))  
							 from  Invoices.dbo.CreditMemoItem CI with (nolock) 
							 inner join 
                                   Invoices.dbo.CreditMemo C with (nolock)
							   on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                               and II.IDSeq = CI.InvoiceItemIDSeq
							   and C.CreditStatusCode in ('PAPR')
							 where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
                               and II.InvoiceGroupIdSeq     = @LVC_InvoiceGroupIDSeq
                               and II.ChargeTypeCode        = @LC_ChargeTypeCode
                               and II.Orderitemrenewalcount = @LBI_RenewalCount	
                               and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                               and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                               and II.OrderIDSeq            = @LVC_OrderIDSeq
                               and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                               and II.InvoiceIDSeq          = @InvoiceIDSeq ), 0) < 0 
				THEN 0 
			 ELSE isnull((select convert(numeric(30,2),sum(CI.TaxAmount))  
							 from  Invoices.dbo.CreditMemoItem CI with (nolock) 
							 inner join 
                                   Invoices.dbo.CreditMemo C with (nolock)
							   on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                               and II.IDSeq = CI.InvoiceItemIDSeq
							   and C.CreditStatusCode in ('PAPR')
							 where CI.InvoiceGroupIDSeq     = @LVC_InvoiceGroupIDSeq
                               and II.InvoiceGroupIdSeq     = @LVC_InvoiceGroupIDSeq
                               and II.ChargeTypeCode        = @LC_ChargeTypeCode
                               and II.Orderitemrenewalcount = @LBI_RenewalCount	
                               and II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                               and II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                               and II.OrderIDSeq            = @LVC_OrderIDSeq
                               and II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                               and II.InvoiceIDSeq          = @InvoiceIDSeq), 0)
				END)                                                      as ActualTaxAmount,
          ------------------------------------------------------------------------------
           ( CASE 
                    WHEN  isnull(convert(numeric(30,2),(II.TaxAmount - 
                                                                  (select  convert(numeric(30,2),sum(CI.TaxAmount))  
								                                   from Invoices.dbo.CreditMemoItem CI with (nolock)
								                                    inner join 
                                                                           Invoices.dbo.CreditMemo C with (nolock)
								                                       on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								                                       and C.CreditStatusCode in ('APPR')
								                                       and II.IDSeq                 = CI.InvoiceItemIDSeq
								                                   where CI.InvoiceIDSeq            = @InvoiceIDSeq	
								                                       and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                                       AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                                       AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                                       AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                                       AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                                                       AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                                       AND II.InvoiceIDSeq          = @InvoiceIDSeq))), II.TaxAmount) < 0 
                  THEN 0 
              ELSE  isnull(convert(numeric(30,2),(II.TaxAmount - 
                                                                  (select  convert(numeric(30,2),sum(CI.TaxAmount))  
								                                   from Invoices.dbo.CreditMemoItem CI with (nolock)
								                                    inner join 
                                                                           Invoices.dbo.CreditMemo C with (nolock)
								                                       on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								                                       and C.CreditStatusCode in ('APPR')
								                                       and II.IDSeq                 = CI.InvoiceItemIDSeq
								                                   where CI.InvoiceIDSeq            = @InvoiceIDSeq	
								                                       and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                                       AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                                       AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                                       AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                                       AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                                                       AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                                       AND II.InvoiceIDSeq          = @InvoiceIDSeq))), II.TaxAmount) 
             END )                                                                          as InvoiceTaxAmount,
          ----------------------------------------------------------------
         II.OrderItemRenewalCount                                          as RenewalCount,
          ----------------------------------------------------------------
         II.InvoiceIDseq                                                   as InvoiceIDseq,
          ----------------------------------------------------------------
         II.OrderIDSeq                                                     as OrderIDSeq,
          ----------------------------------------------------------------
         II.OrderGroupIDSeq                                                as OrderGroupIDSeq,
          ----------------------------------------------------------------
         II.BillingPeriodFromDate                                          as BillingPeriodFromDate,
          ----------------------------------------------------------------
         II.BillingPeriodToDate                                            as BillingPeriodToDate,
          ---------------------------------------------------------------- 
         II.ShippingAndHandlingAmount                                      as ShippingAndHandlingAmount,
          ----------------------------------------------------------------
         ((II.ShippingAndHandlingAmount)  - ((CASE 
												  WHEN isnull(
															  (select  convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount))  
															   from  Invoices.dbo.CreditMemoItem CI with (nolock) 
															   inner join 
																	 Invoices.dbo.CreditMemo C with (nolock)
																 on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
																 and C.CreditStatusCode in ('APPR')
															   where CI.InvoiceItemIDSeq = II.IDSeq ), 0)<0 
													THEN 0 
												  ELSE isnull(
															  (select  convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount))  
															   from   Invoices.dbo.CreditMemoItem CI with (nolock) 
															   inner join 
																	  Invoices.dbo.CreditMemo C with (nolock)
																  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
																  and C.CreditStatusCode in ('APPR')
																where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
												  END)
											   ))                           as AvailShippingAndHandlingAmount
           --------------------------------------------------------------------
          FROM  Invoices.dbo.[InvoiceItem] II with (nolock)          
          INNER JOIN    
                Invoices.dbo.[InvoiceGroup] IG (nolock)
			ON  II.InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq
			AND II.OrderIDSeq        = IG.OrderIDSeq 
			AND IG.OrderGroupIDSeq   = II.OrderGroupIDSeq
            AND II.ChargeTypeCode        = @LC_ChargeTypeCode
            AND II.Orderitemrenewalcount = @LBI_RenewalCount	
            AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
            AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
            AND II.OrderIDSeq            = @LVC_OrderIDSeq
            AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
            AND II.InvoiceIDSeq          = @InvoiceIDSeq 
            AND II.IDSeq                 = @LVC_InvoiceItemIDSeq	          
		  INNER JOIN      
                Invoices.dbo.creditmemo CM with (nolock) 
			ON  IG.InvoiceIDSeq = CM.InvoiceIDSeq
          LEFT OUTER JOIN 
                Invoices.dbo.[Invoice] I with (nolock)
            ON  I.InvoiceIDSeq  = IG.InvoiceIDSeq
          LEFT OUTER JOIN 
                Products.dbo.Product P with (nolock)
            ON  II.ProductCode  = P.Code
            AND II.PriceVersion = P.PriceVersion
          WHERE IG.InvoiceIDSeq = @InvoiceIDSeq  
--            AND II.ExtChargeAmount  > II.CreditAmount
			AND II.ChargeTypeCode        = @LC_ChargeTypeCode
            AND II.Orderitemrenewalcount = @LBI_RenewalCount	
            AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
            AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
            AND II.OrderIDSeq            = @LVC_OrderIDSeq
            AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
            AND II.InvoiceIDSeq          = @InvoiceIDSeq 
            AND II.IDSeq                 = @LVC_InvoiceItemIDSeq 
            AND CM.CreditMemoIDSeq       = @CreditMemoIDSeq
			AND @LVC_CustomBundleNameEnabledFlag = 0
          ORDER BY P.DisplayName,II.TransactionItemName,II.TransactionDate
    END

    ELSE IF(@Mode = 'PartialCredit')
    BEGIN
    INSERT INTO @LT_InvoiceCreditSummary
           (
            IDSeq,
            ProductCode,
            ProductName,
            ChargeType,
		    CreditReasonCode,
		    CreditMemoItemIDSeq,
		    RevisedDate,
		    RequestedBy,
		    Comments,
            CreditAmount,
		    ChargeAmount,
            TaxAmount,
            TaxPercent,
            Total,
            NetPrice,
            TotalCreditAmount,
            TotalTaxAmount,
            AvailableCredit,
		    InvoiceItemIDSeq,
            InvoiceGroupIDSeq,
            BillingPeriod,
            CustomBundleNameEnabledFlag,
			DoNotPrintCreditReasonFlag,
			DoNotPrintCreditCommentsFlag,
            ReportingTypeCode,
            ActualTaxAmount,
            InvoiceTaxAmount,
            RenewalCount, 
            InvoiceIDseq,
            OrderIDSeq,
            OrderGroupIDSeq,
            BillingPeriodFromDate,
            BillingPeriodToDate,
            ShippingAndHandlingAmount,
            AvailShippingAndHandlingAmount 
           )
-------------------------------------------------------------------------------------------------
----------                  Retrives InvocieItem data for Partial Credit Mode
    SELECT   II.IDSeq                                               as IDSeq,
            II.ProductCode                                                  as ProductCode,
            (Case when II.Measurecode = 'TRAN' then II.TransactionItemName 
                else P.DisplayName  
            end)                                                            as ProductName,
            II.chargeTypeCode                                               as ChargeType,
			CM.CreditReasonCode  				                            as CreditReasonCode,
			@LVC_CreditMemoItemIDSeq										as CreditMemoItemIDSeq,
			convert(varchar(15),CM.RequestedDate,101)                       as RevisedDate,
			@LVC_RequestedBy							                    as RequestedBy,
			CM.Comments									       			    as Comments,
			---------------------------------------------------------------         
            CASE 
            WHEN isnull((
            select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
					  inner join Invoices.dbo.CreditMemo C with (nolock)
					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					          and  C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq  ), 0) <0 
            THEN 0 
            ELSE isnull((
            select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
					  inner join Invoices.dbo.CreditMemo C with (nolock)
					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					          and  C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
            END                                                             as CreditAmount,
            --------------------------------------------------------------- 
		    @LN_ChargeAmount												as ChargeAmount,
			---------------------------------------------------------------         
            CASE 
            WHEN isnull((
            select  convert(numeric(30,2),sum(CI.TaxAmount))  
                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
					  inner join Invoices.dbo.CreditMemo C with (nolock)
					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					          and  C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq  ), 0) <0 
            THEN 0 
            ELSE isnull((
            select  convert(numeric(30,2),sum(CI.TaxAmount))  
                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
					  inner join Invoices.dbo.CreditMemo C with (nolock)
					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					          and  C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
            END                                                             as TaxAmount,
            --------------------------------------------------------------- 
            II.TaxPercent                                                   as TaxPercent,
			---------------------------------------------------------------
--			(CASE 
--            WHEN isnull((
--            select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
--                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
--					  inner join Invoices.dbo.CreditMemo C with (nolock)
--					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
--                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
--					          and  C.CreditStatusCode in ('PAPR')
--                    where CI.InvoiceItemIDSeq = II.IDSeq  ), 0) <0 
--            THEN 0 
--            ELSE isnull((
--            select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
--                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
--					  inner join Invoices.dbo.CreditMemo C with (nolock)
--					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
--                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
--					          and  C.CreditStatusCode in ('PAPR')
--                    where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
--            END) + 
--			  (CASE 
--            WHEN isnull((
--            select  convert(numeric(30,2),sum(CI.TaxAmount))  
--                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
--					  inner join Invoices.dbo.CreditMemo C with (nolock)
--					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
--                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
--					          and  C.CreditStatusCode in ('PAPR')
--                    where CI.InvoiceItemIDSeq = II.IDSeq  ), 0) <0 
--            THEN 0 
--            ELSE isnull((
--            select  convert(numeric(30,2),sum(CI.TaxAmount))  
--                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
--					  inner join Invoices.dbo.CreditMemo C with (nolock)
--					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
--                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
--					          and  C.CreditStatusCode in ('PAPR')
--                    where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
--            END) +
--              CASE 
--            WHEN isnull((select  convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount))  
--                         from   Invoices.dbo.CreditMemoItem CI with (nolock)
--						 inner join 
--                                Invoices.dbo.CreditMemo C with (nolock)
--						    on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
--                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
--					        and  C.CreditStatusCode in ('PAPR')
--                         where CI.InvoiceItemIDSeq = II.IDSeq ), 0) <0 
--            THEN 0 
--            ELSE
--              isnull((select  convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount))  
--                         from   Invoices.dbo.CreditMemoItem CI with (nolock)
--						 inner join 
--                                Invoices.dbo.CreditMemo C with (nolock)
--						    on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
--                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
--					        and  C.CreditStatusCode in ('PAPR')
--                         where CI.InvoiceItemIDSeq = II.IDSeq), 0) 
--            END                                                            as Total,
			(CASE 
            WHEN isnull((
            select  convert(numeric(30,2), (isnull(sum(CI.ExtCreditAmount), 0) + isnull(sum(CI.TaxAmount), 0) + isnull(sum(CI.ShippingAndHandlingCreditAmount), 0)))  
                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
					  inner join Invoices.dbo.CreditMemo C with (nolock)
					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
					          and  C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq  ), 0) <0 
            THEN 0 
            ELSE isnull((
            select  convert(numeric(30,2), (isnull(sum(CI.ExtCreditAmount), 0) + isnull(sum(CI.TaxAmount), 0) + isnull(sum(CI.ShippingAndHandlingCreditAmount), 0)))    
                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
					  inner join Invoices.dbo.CreditMemo C with (nolock)
					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
					          and  C.CreditStatusCode in ('PAPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
            END)                                                            as Total,
			---------------------------------------------------------------
            convert(numeric(30,2),II.NetChargeAmount + II.TaxAmount)         as NetPrice,
            ---------------------------------------------------------------         
            CASE 
            WHEN isnull((
            select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
					  inner join Invoices.dbo.CreditMemo C with (nolock)
					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					          and  C.CreditStatusCode in ('APPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq  ), 0) <0 
            THEN 0 
            ELSE isnull((
            select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
                    from Invoices.dbo.CreditMemoItem CI with (nolock) 
					  inner join Invoices.dbo.CreditMemo C with (nolock)
					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					          and  C.CreditStatusCode in ('APPR')
                    where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
            END                                                             as TotalCreditAmount,
            ---------------------------------------------------------------   
            CASE 
            WHEN isnull((select  convert(numeric(30,2),sum(CI.TaxAmount))  
                         from Invoices.dbo.CreditMemoItem CI with (nolock)
						inner join Invoices.dbo.CreditMemo C with (nolock)
						on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					          and  C.CreditStatusCode in ('APPR')
                         where CI.InvoiceItemIDSeq = II.IDSeq ), 0) <0 
            THEN 0 
            ELSE
              isnull((select  convert(numeric(30,2),sum(CI.TaxAmount))  
                      from Invoices.dbo.CreditMemoItem CI with (nolock)
					  inner join Invoices.dbo.CreditMemo C with (nolock)
					  on C.CreditMemoIDSeq = CI.CreditMemoIDSeq
					          and  C.CreditStatusCode in ('APPR')
                      where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
            END                                                             as TotalTaxAmount,
            --------------------------------------------------------------
            ((II.NetChargeAmount)  - ((CASE 
											WHEN isnull(
											            (select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
														 from  Invoices.dbo.CreditMemoItem CI with (nolock) 
														 inner join 
                                                               Invoices.dbo.CreditMemo C with (nolock)
														   on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
														   and C.CreditStatusCode in ('APPR')
														 where CI.InvoiceItemIDSeq = II.IDSeq ), 0)<0 
											THEN 0 
									   ELSE   isnull(
									  		          ( select  convert(numeric(30,2),sum(CI.ExtCreditAmount))  
														 from  Invoices.dbo.CreditMemoItem CI with (nolock) 
														 inner join 
                                                               Invoices.dbo.CreditMemo C with (nolock)
														   on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
														   and C.CreditStatusCode in ('APPR')
														 where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
									   END)  
                                     ))															as AvailableCredit,
            ------------------------------------------------------------------------------------------------------------------------
			II.IDSeq														as InvoiceItemIDSeq,
            IG.IDSeq                                                        as InvocieGroupIDSeq,
            convert(varchar(11),II.BillingPeriodFromDate,101) +
               ' - ' + convert(varchar(11),II.BillingPeriodToDate,101)      as BillingPeriod,
            @LVC_CustomBundleNameEnabledFlag                                as CustombundleNameEnabledFlag,
			CM.DoNotPrintCreditReasonFlag									as DoNotPrintCreditReasonFlag,
			CM.DoNotPrintCreditCommentsFlag									as DoNotPrintCreditCommentsFlag,
            II.ReportingTypeCode                                            as ReportingTypeCode,
              ( CASE 
                    WHEN  isnull(convert(numeric(30,2),(II.TaxAmount - 
                                                                  (select  convert(numeric(30,2),sum(CI.TaxAmount))  
								                                   from Invoices.dbo.CreditMemoItem CI with (nolock)
								                                    inner join 
                                                                           Invoices.dbo.CreditMemo C with (nolock)
								                                       on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								                                       and C.CreditStatusCode in ('APPR')
								                                       and II.IDSeq                 = CI.InvoiceItemIDSeq
								                                   where CI.InvoiceIDSeq            = @InvoiceIDSeq	
								                                       and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                                       AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                                       AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                                       AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                                       AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                                                       AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                                       AND II.InvoiceIDSeq          = @InvoiceIDSeq))), II.TaxAmount) < 0 
                  THEN 0 
              ELSE  isnull(convert(numeric(30,2),(II.TaxAmount - 
                                                                  (select  convert(numeric(30,2),sum(CI.TaxAmount))  
								                                   from Invoices.dbo.CreditMemoItem CI with (nolock)
								                                    inner join 
                                                                           Invoices.dbo.CreditMemo C with (nolock)
								                                       on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								                                       and C.CreditStatusCode in ('APPR')
								                                       and II.IDSeq                 = CI.InvoiceItemIDSeq
								                                   where CI.InvoiceIDSeq            = @InvoiceIDSeq	
								                                       and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                                       AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                                       AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                                       AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                                       AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                                                       AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                                       AND II.InvoiceIDSeq          = @InvoiceIDSeq))), II.TaxAmount) 
             END )                                                                                                                        as ActualTaxAmount,
            ------------------------------------------------------------------------------------------------------------------------
            ( CASE 
                    WHEN  isnull(convert(numeric(30,2),(II.TaxAmount - 
                                                                  (select  convert(numeric(30,2),sum(CI.TaxAmount))  
								                                   from Invoices.dbo.CreditMemoItem CI with (nolock)
								                                    inner join 
                                                                           Invoices.dbo.CreditMemo C with (nolock)
								                                       on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								                                       and C.CreditStatusCode in ('APPR')
								                                       and II.IDSeq                 = CI.InvoiceItemIDSeq
								                                   where CI.InvoiceIDSeq            = @InvoiceIDSeq	
								                                       and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                                       AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                                       AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                                       AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                                       AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                                                       AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                                       AND II.InvoiceIDSeq          = @InvoiceIDSeq))), II.TaxAmount) < 0 
                  THEN 0 
              ELSE  isnull(convert(numeric(30,2),(II.TaxAmount - 
                                                                  (select  convert(numeric(30,2),sum(CI.TaxAmount))  
								                                   from Invoices.dbo.CreditMemoItem CI with (nolock)
								                                    inner join 
                                                                           Invoices.dbo.CreditMemo C with (nolock)
								                                       on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
								                                       and C.CreditStatusCode in ('APPR')
								                                       and II.IDSeq                 = CI.InvoiceItemIDSeq
								                                   where CI.InvoiceIDSeq            = @InvoiceIDSeq	
								                                       and II.ChargeTypeCode        = @LC_ChargeTypeCode
                                                                       AND II.Orderitemrenewalcount = @LBI_RenewalCount	
                                                                       AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
                                                                       AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
                                                                       AND II.OrderIDSeq            = @LVC_OrderIDSeq
                                                                       AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
                                                                       AND II.InvoiceIDSeq          = @InvoiceIDSeq))), II.TaxAmount) 
             END )                                                                          as InvoiceTaxAmount,
          ----------------------------------------------------------------
            II.OrderItemRenewalCount                                          as RenewalCount,
          ----------------------------------------------------------------
            II.InvoiceIDseq                                                   as InvoiceIDseq,
          ----------------------------------------------------------------
            II.OrderIDSeq                                                     as OrderIDSeq,
          ----------------------------------------------------------------
            II.OrderGroupIDSeq                                                as OrderGroupIDSeq,
           ----------------------------------------------------------------
            II.BillingPeriodFromDate                                          as BillingPeriodFromDate,
          ----------------------------------------------------------------
            II.BillingPeriodToDate                                            as BillingPeriodToDate,
            ----------------------------------------------------------------------------------------
            CASE 
            WHEN isnull((select  convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount))  
                         from   Invoices.dbo.CreditMemoItem CI with (nolock)
						 inner join 
                                Invoices.dbo.CreditMemo C with (nolock)
						    on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
					        and  C.CreditStatusCode in ('PAPR')
                         where CI.InvoiceItemIDSeq = II.IDSeq ), 0) <0 
            THEN 0 
            ELSE
              isnull((select  convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount))  
                         from   Invoices.dbo.CreditMemoItem CI with (nolock)
						 inner join 
                                Invoices.dbo.CreditMemo C with (nolock)
						    on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
                            and C.CreditMemoIDSeq = @CreditMemoIDSeq
					        and  C.CreditStatusCode in ('PAPR')
                         where CI.InvoiceItemIDSeq = II.IDSeq), 0) 
            END                                                               as ShippingAndHandlingAmount,
          ------------------------------------------------------------------------------------------
         ((II.ShippingAndHandlingAmount)  - ((CASE 
												  WHEN isnull(
															  (select  convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount))  
															   from  Invoices.dbo.CreditMemoItem CI with (nolock) 
															   inner join 
																	 Invoices.dbo.CreditMemo C with (nolock)
																 on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
																 and C.CreditStatusCode in ('APPR')
															   where CI.InvoiceItemIDSeq = II.IDSeq ), 0)<0 
													THEN 0 
												  ELSE isnull(
															  (select  convert(numeric(30,2),sum(CI.ShippingAndHandlingCreditAmount))  
															   from   Invoices.dbo.CreditMemoItem CI with (nolock) 
															   inner join 
																	  Invoices.dbo.CreditMemo C with (nolock)
																  on  C.CreditMemoIDSeq = CI.CreditMemoIDSeq
																  and C.CreditStatusCode in ('APPR')
																where CI.InvoiceItemIDSeq = II.IDSeq ), 0) 
												  END)
											   ))                          as AvailShippingAndHandlingAmount
            ------------------------------------------------------------------------- 
          FROM  Invoices.dbo.[InvoiceItem] II    with (nolock)        
          INNER JOIN
                Invoices.dbo.[InvoiceGroup] IG   with (nolock)
			ON  II.InvoiceGroupIDSeq = @LVC_InvoiceGroupIDSeq
            AND II.OrderIDSeq        = IG.OrderIDSeq 
            AND IG.OrderGroupIDSeq   = II.OrderGroupIDSeq
            AND II.ChargeTypeCode        = @LC_ChargeTypeCode 
            AND II.Orderitemrenewalcount = @LBI_RenewalCount	
            AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
            AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
            AND II.OrderIDSeq            = @LVC_OrderIDSeq
            AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
            AND II.InvoiceIDSeq          = @InvoiceIDSeq
			AND	II.IDSeq                 = @LVC_InvoiceItemIDSeq
          INNER JOIN      
                Invoices.dbo.creditmemo CM       with (nolock) 
            ON  IG.InvoiceIDSeq = CM.InvoiceIDSeq          
          LEFT OUTER JOIN 
                Invoices.dbo.[Invoice] I         with (nolock)
            ON  I.InvoiceIDSeq  = IG.InvoiceIDSeq
          LEFT OUTER JOIN Products.dbo.Product P with (nolock)
            ON  II.ProductCode  = P.Code
            AND II.PriceVersion = P.PriceVersion
          WHERE IG.InvoiceIDSeq = @InvoiceIDSeq  
--            AND II.ExtChargeAmount  > II.CreditAmount
            AND II.ChargeTypeCode        = @LC_ChargeTypeCode 
            AND II.Orderitemrenewalcount = @LBI_RenewalCount	
            AND II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
            AND II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
            AND II.OrderIDSeq            = @LVC_OrderIDSeq
            AND II.OrderGroupIDSeq       = @LBI_OrderGroupIDSeq
            AND II.InvoiceIDSeq          = @InvoiceIDSeq
			AND	II.IDSeq                 = @LVC_InvoiceItemIDSeq 
			AND	CM.CreditMemoIDSeq       = @CreditMemoIDSeq
			AND	@LVC_CustomBundleNameEnabledFlag = 0
          ORDER BY P.DisplayName,II.TransactionItemName,II.TransactionDate
    END	
-------------------------------------------------------------------------------------------------
   
-------------------------------------------------------------------------------------------------
  SET @LV_Counter = @LV_Counter + 1
	END
	END
  SET @LV_BundleCounter = @LV_BundleCounter + 1
END
	--SELECT * FROM  @LT_BundleGroupSummary   
-----------------------------------------------------------------------------------------
        INSERT INTO @LT_InvoiceCreditTotals
        (
            TotalCredit,
            TotalTax,
            SnHTotal,
            NetTotal
        )
        SELECT 
            SUM(CreditAmount),
            SUM(TaxAmount),
            SUM((case when (@Mode='TaxCredit' or @Mode = 'FullTax')
                       then 0.00
                 else ShippingAndHandlingAmount
                 end)
               )     as ShippingAndHandlingAmount,
            SUM(Total)
        FROM @LT_InvoiceCreditSummary S
        where (
                ------------------------------------------
               (
                 ((S.AvailableCredit > 0) OR (S.ActualTaxAmount > 0) OR (S.AvailShippingAndHandlingAmount > 0))
                    AND
                 ((@Mode='FullCredit') OR (@Mode='PartialCredit'))  
               )
               ------------------------------------------
                    OR
              ( 
                 ((S.ActualTaxAmount > 0))
                   AND
                 ((@Mode='TaxCredit') OR (@Mode='FullTax')) 
               )
               ------------------------------------------
              )

        --Where (AvailableCredit + ActualTaxAmount + AvailShippingAndHandlingAmount) <> 0.00

---------------------------------------------------------------------------------------------------
---------------------------------------------------------Final Select
SELECT  distinct IDSeq,
         ProductCode,
         ProductName,
         ChargeType,
	 CreditReasonCode,
	 CreditMemoItemIDSeq as CreditMemoItemIDSeq,
	 Convert(varchar(15),RevisedDate,101) as RequestedDate,
	 RequestedBy,
	 Comments,
	 ChargeAmount,
         TaxPercent,
         NetPrice,
         TotalCreditAmount,
         TotalTaxAmount,
         AvailableCredit,
         AvailShippingAndHandlingAmount,
         InvoiceTaxAmount,
         CreditAmount
         ,(case when (@Mode='TaxCredit' or @Mode = 'FullTax')
                 then 0.00
               else ShippingAndHandlingAmount
           end)          as ShippingAndHandlingAmount ,
         TaxAmount,
         Total,
	 InvoiceItemIDSeq,
         InvoiceGroupIDSeq,
         BillingPeriod,
         CustomBundleNameEnabledFlag,
	 DoNotPrintCreditReasonFlag , 
	 DoNotPrintCreditCommentsFlag,
         Substring(ReportingTypeCode,1,3) as ReportingTypeCode,
         ActualTaxAmount,
         RenewalCount, 
         InvoiceIDseq,
         OrderIDSeq,
         OrderGroupIDSeq,
         SubString(BillingPeriod,1,10)  as BillingPeriodFromDate,
         SubString(BillingPeriod,13,23) as BillingPeriodToDate,
         case ReportingTypeCode when 'ILFF' then 1
                                when 'ACSF' then 2
                                when 'ANCF' then 3
                                else 4
         end                              as SortOrder
  FROM @LT_InvoiceCreditSummary S
  --WHERE (AvailableCredit + ActualTaxAmount + AvailShippingAndHandlingAmount) <> 0.00
  where (
                ------------------------------------------
               (
                 ((S.AvailableCredit > 0) OR (S.ActualTaxAmount > 0) OR (S.AvailShippingAndHandlingAmount > 0))
                    AND
                 ((@Mode='FullCredit') OR (@Mode='PartialCredit'))  
               )
               ------------------------------------------
                    OR
              ( 
                 ((S.ActualTaxAmount > 0))
                   AND
                 ((@Mode='TaxCredit') OR (@Mode='FullTax')) 
               )
               ------------------------------------------
              )
  Order By ProductName ASC,SortOrder ASC,BillingPeriodFromDate ASC
  
  SELECT TotalCredit,
         TotalTax,
         SnHTotal,
         NetTotal 
  FROM @LT_InvoiceCreditTotals

  SELECT convert(varchar(11),InvoiceDate,101) as InvoiceDate,
         @LVC_EpicorPostingCode  as EpicorPostingCode,
         @LVC_TaxwareCompanyCode as TaxwareCompanyCode 
  FROM Invoices.dbo.[Invoice] I with (nolock)
       Inner Join Invoices.dbo.CreditMemo C with (nolock)
	   on I.InvoiceIDSeq = C.InvoiceIDSeq
	   and C.CreditMemoIDSeq=  @CreditMemoIDSeq
END
--Exec Invoices..[uspCREDITS_CreditMemoItemSelect] 'R0810000017'
GO
