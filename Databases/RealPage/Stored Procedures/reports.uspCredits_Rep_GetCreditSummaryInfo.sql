SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspCredits_Rep_GetCreditSummaryInfo
-- Description     : Retrieves CreditMemo Summary.
-- Input Parameters: @CreditMemoIDSeq varchar(50)
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.dbo.[uspCredits_Rep_GetCreditSummaryInfo]   @CreditMemoIDSeq  = 'R0805000289'
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 10/09/2007      : Stored Procedure Created.
-- 05/21/2008      : Naval Kishore Modified The StoredProcedure for new credit requirements.
-- 01/11/2008      : Shashi Bhushan [to include SnH amount in the report ref: #5864] 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspCredits_Rep_GetCreditSummaryInfo] (@CreditMemoIDSeq varchar(50))
AS
BEGIN
	--------------------------------------------------------------------------------------
  -- Declaring Local Variables
  --------------------------------------------------------------------------------------
  DECLARE @Curr_InvGrpIDSeq					BIGINT
  DECLARE @Max_InvGrpIDSeq					BIGINT
  DECLARE @CurrIDSeq						BIGINT
  DECLARE @MaxIDSeq						    BIGINT
  DECLARE @PIDSeq							BIGINT
  DECLARE @BIDSeq							BIGINT
  DECLARE @TIDSeq							BIGINT
  DECLARE @OrderItemSeq						BIGINT
  DECLARE @LI_InnerOrderItemSeq             BIGINT
  DECLARE @FeeType						    VARCHAR(4)
  DECLARE @InvGrpID						    BIGINT
  DECLARE @IsCustomBun						BIT
  DECLARE @GroupName						VARCHAR(70)
  DECLARE @LVB_CMPBUNDLEFLAG				BIT
  DECLARE @LVB_CMPBUNDLEEXPFLAG				BIT
  DECLARE @LVB_PRPBUNDLEEXPFLAG				BIT
  DECLARE @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG BIT 
  DECLARE @LVC_FeeType                      VARCHAR(3)
  --------------------------------------------------------------------------------------
  -- temp storage for Invoice Group
  --------------------------------------------------------------------------------------
	CREATE TABLE #TEMP_InvGroupRecords 
									(
									IGSeq			INT NOT NULL IDENTITY(1,1),
									GroupID			BIGINT,
									GroupName		VARCHAR(70),
									CBEnabledFlag   VARCHAR(4),
									EXPFLAG			BIT
								   ) 
  --------------------------------------------------------------------------------------
	-- temp storage for products
	--------------------------------------------------------------------------------------
   	CREATE TABLE #TEMP_BillingRecords
								   (
									IDSeq			INT NOT NULL IDENTITY(1,1),
                                    FeeType			VARCHAR(4),
                                    RecType         CHAR(1),									
									Description		VARCHAR(8000),
                                    CrAmt           MONEY,
                                    TaxAmt          MONEY,
                                    SnHAmt          MONEY,
                                    TotAmt          MONEY,
                                    SortOrder       INT,
								   )
--------------------------------------------------------------------------------------------
	-- CHECKING FOR WHETHER WE CAN SHOW PRODUCT LISTING 
	-- WITHIN A CUSTOM BUNDLE IN THE NOTES LINES
	--------------------------------------------------------------------------------------------
	SET         @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG   = 0
        -------------------------------------------------------------------
	SELECT      @LVB_CMPBUNDLEFLAG    = CASE INV.AccountTypeCode
						   WHEN 'AHOFF' THEN 1
						   ELSE 0
					    END,
  		   @LVB_CMPBUNDLEEXPFLAG = CASE CMP.CustomBundlesProductBreakDownTypeCode
			 			   WHEN 'YEBR' THEN 1
						   ELSE 0
					    END,
 		  @LVB_PRPBUNDLEEXPFLAG = CASE PRP.CustomBundlesProductBreakDownTypeCode
						   WHEN 'NOBR' THEN 0
						   ELSE 1
					    END
	FROM	INVOICES.DBO.INVOICE   INV with (nolock)
	INNER JOIN
		    CUSTOMERS.DBO.COMPANY  CMP with (nolock)
	ON	CMP.IDSeq        = INV.CompanyIDSeq
    INNER JOIN
            Invoices.dbo.CreditMemo CM with (nolock)
    On  CM.InvoiceIDSeq = INV.InvoiceIDSeq 
        and     CM.CreditMemoIDSeq = @CreditMemoIDSeq 
	LEFT JOIN
		CUSTOMERS.DBO.PROPERTY PRP with (nolock)
	ON      INV.PropertyIdSeq = PRP.IDSeq
        and     CM.CreditMemoIDSeq = @CreditMemoIDSeq 
	WHERE   CM.CreditMemoIDSeq = @CreditMemoIDSeq   
        --------------------------------------------------------------
        --Finalize Logic to @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG
	IF (
		 (@LVB_CMPBUNDLEEXPFLAG & @LVB_PRPBUNDLEEXPFLAG = 1)
		 OR
		 (@LVB_CMPBUNDLEFLAG & @LVB_CMPBUNDLEEXPFLAG = 1)
		 OR
		 (~@LVB_CMPBUNDLEFLAG & @LVB_PRPBUNDLEEXPFLAG = 1)
	   )
	  SET @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG = 1
--------------------------------------------------------------------------------------------
	-- Populating the #TEMP_InvGroupRecords table with the InvoiceGroup ID's,
	-- CustomBundleNameEnabledFlag and @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG
	-- for the passed InvoiceIDSEq as Input Parameter
	--------------------------------------------------------------------------------------------
	INSERT 
	INTO	#TEMP_InvGroupRecords(GroupID,GroupName,CBEnabledFlag,EXPFLAG)
	SELECT	DISTINCT IG.IDSeq,IG.[Name],IG.CustomBundleNameEnabledFlag,@LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG
	FROM	Invoices.dbo.InvoiceGroup IG WITH (nolock)
       join Invoices.dbo.CreditMemoItem CMI WITH (nolock)
     ON    Ig.InvoiceIDSeq = CMI.InvoiceIDSeq
	WHERE	CMI.CreditMemoIDSeq = @CreditMemoIDSeq
  --------------------------------------------------------------------------------------
  --  set loop iterators
  --------------------------------------------------------------------------------------
  SET   @Curr_InvGrpIDSeq		= 1
  SET	@Max_InvGrpIDSeq		= (SELECT max(IGSeq) FROM #TEMP_InvGroupRecords WITH (NOLOCK))
  --------------------------------------------------------------------------------------
  --  loop to evaluate all billing records
  --------------------------------------------------------------------------------------
  WHILE	@Curr_InvGrpIDSeq <= @Max_InvGrpIDSeq
  BEGIN
    SELECT  @InvGrpID	 =GroupID,
	    @IsCustomBun =CBEnabledFlag,
	    @GroupName	 =GroupName
    FROM    #TEMP_InvGroupRecords with (nolock)
    WHERE   IGSEq = @Curr_InvGrpIDSeq
	
    -------------------------------------------------------------------------------------------------
    -- Populating the #TEMP_BillingRecords table with list of Charges data along with Description column
    -------------------------------------------------------------------------------------------------.

	IF (@IsCustomBun=1)  -- For Custom Bundle inserting #TEMP_BillingRecords
		BEGIN
			INSERT INTO  #TEMP_BillingRecords(FeeType,RecType,[Description],CrAmt,TaxAmt,SnHAmt,TotAmt,SortOrder)
			SELECT DISTINCT		    
					SUBSTRING(II.ReportingTypeCode,1,3)			AS [FEETYPE],
                    'P'                                         AS [RECTYPE],
					@GroupName						            AS [DESCRIPTION],									
					SUM(CMI.Netcreditamount)                    AS [CrAMT],
					SUM(CMI.TaxAmount)                          AS [TAXAMT],
                    SUM(CMI.ShippingAndHandlingCreditAmount)    AS [SnHAmt],
					(
                     SUM(CMI.Netcreditamount) + 
					 SUM(CMI.TaxAmount) +
                     SUM(CMI.ShippingAndHandlingCreditAmount)
                    )                                           AS [TOTAMT],
                    CASE WHEN II.ReportingTypeCode ='ILFF' THEN 1
                         WHEN II.ReportingTypeCode ='ACSF' THEN 2
                         WHEN II.ReportingTypeCode ='ANCF' THEN 3
                         ELSE ''
                    END                                         AS [SORTORDER] 

			FROM	Invoices.dbo.InvoiceItem	II (nolock) 
			INNER JOIN                                             
					Invoices.dbo.CreditMemoItem	CMI (nolock)
			ON		II.InvoiceIDSeq      = CMI.InvoiceIDSeq
				and II.InvoiceGroupIDSeq = CMI.InvoiceGroupIDSeq
				and II.IDSeq             = CMI.InvoiceItemIDSeq 
                and II.InvoiceGroupIDSeq = @InvGrpID
                and CMI.CreditMemoIDSeq   = @CreditMemoIDSeq               
			WHERE	CMI.CreditMemoIDSeq   = @CreditMemoIDSeq
                and CMI.CustomBundleNameEnabledFlag = 1
            GROUP BY II.ReportingTypeCode

		IF(@LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG = 1)
          BEGIN
			INSERT INTO  #TEMP_BillingRecords(FeeType,RecType,[Description],CrAmt,TaxAmt,SnHAmt,TotAmt,SortOrder)
			SELECT DISTINCT		    
					SUBSTRING(II.ReportingTypeCode,1,3)             AS [FEETYPE],
                    'B'                                             AS [RECTYPE],
					PP.DisplayName									AS [DESCRIPTION],									
					NULL											AS [CrAMT],
					NULL											AS [TAXAMT],
					NULL											AS [SnHAmt],
					NULL											AS [TOTAMT],
                    CASE WHEN II.ReportingTypeCode ='ILFF' THEN 1
                         WHEN II.ReportingTypeCode ='ACSF' THEN 2
                         WHEN II.ReportingTypeCode ='ANCF' THEN 3
                         ELSE ''
                    END                                             AS [SORTORDER] 
			FROM	Invoices.dbo.InvoiceItem	II (nolock) 
			INNER JOIN                                             
					Invoices.dbo.CreditMemoItem	CMI (nolock)
			ON		II.InvoiceIDSeq      = CMI.InvoiceIDSeq
				and II.InvoiceGroupIDSeq = CMI.InvoiceGroupIDSeq
				and II.IDSeq             = CMI.InvoiceItemIDSeq
                and II.InvoiceGroupIDSeq = @InvGrpID
                and CMI.InvoiceGroupIDSeq = @InvGrpID
                and CMI.CreditMemoIDSeq   = @CreditMemoIDSeq
            INNER JOIN
                    Products.dbo.Product PP (nolock)
            ON      PP.Code = II.ProductCode
                and II.PriceVersion		 = PP.PriceVersion                  
			WHERE	CMI.CreditMemoIDSeq   = @CreditMemoIDSeq
                and CMI.InvoiceGroupIDSeq = @InvGrpID
                and CMI.CustomBundleNameEnabledFlag = 1
			END
		END
    ELSE
    BEGIN
      INSERT INTO  #TEMP_BillingRecords(FeeType,RecType,[Description],CrAmt,TaxAmt,SnHAmt,TotAmt,SortOrder)
			SELECT --DISTINCT		    
					SUBSTRING(II.ReportingTypeCode,1,3)             AS [FEETYPE],
                    'P'                                             AS [RECTYPE],
					PP.DisplayName									AS [DESCRIPTION],									
					CMI.Netcreditamount								AS [CrAMT],
					CMI.TaxAmount									AS [TAXAMT],
                    CMI.ShippingAndHandlingCreditAmount             AS [SnHAmt],
					(
                     CMI.Netcreditamount +
                     CMI.TaxAmount +
                     CMI.ShippingAndHandlingCreditAmount
                    ) 			                                    AS [TOTAMT],
                    CASE WHEN II.ReportingTypeCode ='ILFF' THEN 1
                         WHEN II.ReportingTypeCode ='ACSF' THEN 2
                         WHEN II.ReportingTypeCode ='ANCF' THEN 3
                         ELSE ''
                    END                                          AS [SORTORDER] 
			FROM	Invoices.dbo.InvoiceItem	II (nolock) 
			INNER JOIN                                             
					Invoices.dbo.CreditMemoItem	CMI (nolock)
			ON		II.InvoiceIDSeq      = CMI.InvoiceIDSeq
				and II.InvoiceGroupIDSeq = CMI.InvoiceGroupIDSeq
				and II.IDSeq             = CMI.InvoiceItemIDSeq
                and II.InvoiceGroupIDSeq = @InvGrpID
                and CMI.InvoiceGroupIDSeq = @InvGrpID
                and CMI.CreditMemoIDSeq   = @CreditMemoIDSeq
            INNER JOIN
                    Products.dbo.Product PP (nolock)
            ON      PP.Code = II.ProductCode
                and II.PriceVersion		 = PP.PriceVersion                  
			WHERE	CMI.CreditMemoIDSeq   = @CreditMemoIDSeq
                and CMI.InvoiceGroupIDSeq = @InvGrpID
                and CMI.CustomBundleNameEnabledFlag = 0 
    END 
SELECT @Curr_InvGrpIDSeq = @Curr_InvGrpIDSeq + 1
End

select FeeType,RecType,[Description],CrAmt,TaxAmt,SnHAmt,TotAmt from #TEMP_BillingRecords
order by SortOrder,IDSeq --feetype desc,IDSeq

 DROP TABLE #TEMP_BillingRecords  
 DROP TABLE #TEMP_InvGroupRecords
END



GO
