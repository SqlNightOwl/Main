SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_Rep_GetInvoiceDetail
-- Description     : This procedure gets Invoice Details pertaining to passed InvoiceID
-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(15)
--      
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_Rep_GetInvoiceDetail @IPVC_InvoiceID ='I0804000326'    
-- 
-- 
-- Revision History:
-- Author          : 
-- 03/18/2007      : Stored Procedure Created. This is used only in SRS report Invoice From
-- 07/02/2008      : Defect #5298 (Aligned code and commented insertion/grouping of FamilyCode for custom Bundle in #TEMP_BillingRecords table)
--                   
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspINVOICES_Rep_GetInvoiceDetail](@IPVC_InvoiceID    VARCHAR(50)                                                        
							 )
AS
BEGIN 
  SET NOCOUNT ON; 
  SET CONCAT_NULL_YIELDS_NULL OFF;
   --------------------------------------------------------------------------------------
  -- Declaring Local Variables
  --------------------------------------------------------------------------------------
		DECLARE @Curr_InvGrpIDSeq					BIGINT
		DECLARE @Max_InvGrpIDSeq					BIGINT
		DECLARE @CurrIDSeq							BIGINT
		DECLARE @MaxIDSeq							BIGINT
		DECLARE @PIDSeq								BIGINT
		DECLARE @BIDSeq								BIGINT
		DECLARE @TIDSeq								BIGINT
		DECLARE @OrderItemSeq						BIGINT
		DECLARE @LI_InnerOrderItemSeq               BIGINT
		DECLARE @FeeType							VARCHAR(4)
		Declare @InvGrpID							BIGINT
		DEclare @IsCustomBun						BIT
		DEclare @GroupName							VARCHAR(70)
		DECLARE @LVB_CMPBUNDLEFLAG					BIT
		DECLARE @LVB_CMPBUNDLEEXPFLAG				BIT
		DECLARE @LVB_PRPBUNDLEEXPFLAG				BIT
		DECLARE @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG   BIT 
		DECLARE @LVC_FeeType                        VARCHAR(3)
		DECLARE @LI_MainInvoicePageCount            INT
       --------------------------------------------------------------------------------------
        -- temp storage for Invoice Group
        --------------------------------------------------------------------------------------
	CREATE TABLE #TEMP_InvGroupRecords 
									(
									IGSeq			INT NOT NULL IDENTITY(1,1) primary key,
									GroupID			BIGINT,
									GroupName		VARCHAR(70),
									CBEnabledFlag	VARCHAR(4),
									EXPFLAG			BIT
								   ) 
	--------------------------------------------------------------------------------------
	-- temp storage for products
	--------------------------------------------------------------------------------------
	CREATE TABLE #TEMP_ProductRecords 
									(
									PSeq			INT NOT NULL IDENTITY(1,1) primary key,
									RecType			CHAR(1),
									FeeType			VARCHAR(4),
									Description		VARCHAR(255),
                                    SortSeq         INT --SRS 01/30/2010
								   )  

	--------------------------------------------------------------------------------------
	-- temp storage for billing records
	--------------------------------------------------------------------------------------
	CREATE TABLE #TEMP_BillingRecords	
									(
									IDSeq           INT NOT NULL IDENTITY(1,1) primary key,
									OrderItemSeq	VARCHAR(12),
									InvoiceSeq		VARCHAR(12),	  
									RecType			CHAR(2),
									FeeType			VARCHAR(4),
									Product			VARCHAR(255),
									Description		VARCHAR(1000),
									Qty			    DECIMAL(18,2),
									ItemAmt			NUMERIC(18,4),
									NetAmt			NUMERIC(18,5),
									SnHAmt			NUMERIC(18,5),
									TaxAmt			NUMERIC(18,5),
									ExtAmt			NUMERIC(18,5),
                                    PricingTiers    INT,
                                    FamilyCode      CHAR(3),
									GSTTaxAmt       NUMERIC(18,5),
								    PSTTaxAmt       NUMERIC(18,5)
									
									)  

	--------------------------------------------------------------------------------------
	-- temp storage for item notes
	--------------------------------------------------------------------------------------
	CREATE TABLE #TEMP_NotesRecords 
								   (
									NSeq			INT NOT NULL IDENTITY(1,1) primary key,
									PSeq			INT NOT NULL,
									BSeq			INT NOT NULL,
									RecType			CHAR(1),
									FeeType			VARCHAR(4),
									Description		VARCHAR(8000)
								   ) 
	--------------------------------------------------------------------------------------------
	-- Declaring the Final temp table to populate the data in the required format for the Invoice
	--------------------------------------------------------------------------------------------
	CREATE TABLE #TEMP_ListRecords  
								   (
									IDSeq				INT NOT NULL IDENTITY (1,1),
									RecType				CHAR(1),
									FeeType				VARCHAR(4),		
									PSeq				INT NULL,
									BSeq				INT NULL,
									NSeq				INT NULL,
									TSeq				INT default 0,
									Description			VARCHAR(8000),
									Qty					DECIMAL(18,2),
									ItemAmt				NUMERIC(18,4),
									NetAmt				NUMERIC(18,5),
									SnHAmt				NUMERIC(18,5),
									TaxAmt				NUMERIC(18,5),
									ExtAmt				NUMERIC(18,5),
                                    PricingTiers        INT,
                                    FamilyCode          CHAR(3),
									SortOrder			INT,
									PageNo				INT,
                                    TotalRecords        INT,
									GSTTaxAmt			NUMERIC(18,5),
								    PSTTaxAmt			NUMERIC(18,5),
                                    TranIDSeq			INT NULL -- dummy column for transactions
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
        and     INV.InvoiceIDSeq = @IPVC_InvoiceID 
	LEFT JOIN
		CUSTOMERS.DBO.PROPERTY PRP with (nolock)
	ON      INV.PropertyIdSeq = PRP.IDSeq
        and     INV.InvoiceIDSeq = @IPVC_InvoiceID 
	WHERE   INV.InvoiceIDSeq = @IPVC_InvoiceID   
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
	SELECT	DISTINCT IDSeq,[Name],CustomBundleNameEnabledFlag,@LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG
	FROM	Invoices.dbo.InvoiceGroup WITH (nolock)
	WHERE	InvoiceIDSeq = @IPVC_InvoiceID
        ORDER BY IDSeq ASC --SRS 01/30/2010
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
    -------------------------------------------------------------------------------------------------
    IF (@IsCustomBun=1)  -- For Custom Bundle inserting #TEMP_BillingRecords
    BEGIN
      INSERT INTO  #TEMP_BillingRecords(OrderItemSeq,InvoiceSeq,RecType,FeeType,Product,
                                        Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,
								        PricingTiers--,FamilyCode
                                       )
      SELECT DISTINCT				0   						AS [ORDERITEMSEQ],
									II.InvoiceIDSeq				AS [INVOICESEQ],
									'B'							AS [RECTYPE],
									SUBSTRING(II.ReportingTypeCode,1,3)			AS [FEETYPE],
									@GroupName						AS [PRODUCT],
									CASE 
										WHEN (II.ReportingTypeCode IN ('ACSF', 'ILFF')) THEN
											CASE II.FrequencyCode
												WHEN 'YR' THEN 'Annual Fees;'
												WHEN 'SG' THEN 'Initial Fees;'
												WHEN 'MN' THEN 'Monthly Fees;'
												ELSE '' 
											END +                                                                                
											CASE II.MeasureCode
												WHEN 'SITE' THEN ' Site'
												WHEN 'UNIT' THEN ' Unit'
												WHEN 'BED'  THEN ' Bed'
                                                                                                WHEN 'PMC'  THEN ' PMC'
												ELSE ''
											end +
                                                                              (case when II.MeasureCode in ('SITE','UNIT','BED','PMC')
                                                                                      then
											' Pricing; ' +
											CONVERT	(
													VARCHAR(10), 
													CONVERT(INT,(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                                             then II.EffectiveQuantity
                                                                                                                           else  II.UnitOfMeasure
                                                                                                                     end)
                                                                                                               )
													) +
											CASE II.MeasureCode
												WHEN 'SITE' THEN ' Site'
												WHEN 'UNIT' THEN ' Unit'
												WHEN 'BED'  THEN ' Bed'
                                                                                                WHEN 'PMC'  THEN ' PMC'
												ELSE ''
											END + 
											CASE 
												WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                             then II.EffectiveQuantity
                                                                                                           else  II.UnitOfMeasure
                                                                                                      end) > 1 THEN 's;'
												ELSE '; '
											END 
                                                                                   else ''
                                                                                 end) +
                                                                                        (CASE WHEN (II.Frequencycode = 'OT' and II.ReportingTypeCode NOT IN ('ILFF'))
                                                                                                 THEN ' Period ' + 
											              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101)
                                                                                               WHEN   (II.ReportingTypeCode NOT IN ('ILFF'))  
											         THEN ' Period ' + 
											              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101) +
                                                                                                      ' to ' +
											              CONVERT(VARCHAR(10), II.BillingPeriodToDate, 101)
                                                                                               ELSE ''
                                                                                         END)	
								ELSE
									CASE WHEN (II.ReportingTypeCode IN ('ANCF')) THEN
										CASE II.FrequencyCode
											WHEN 'DY' THEN 'Day;'
											WHEN 'HR' THEN 'Hourly;'
											WHEN 'MI' THEN 'Minutes;'
											WHEN 'OC' THEN 'Usage;'
											WHEN 'OT' THEN 'One-time;'
											ELSE '' 
										END +
										CASE II.MeasureCode
											WHEN 'BOOK'    THEN ' Book'
											WHEN 'DAY'     THEN ' Day'
											WHEN 'ITEM'    THEN ' Item'
											WHEN 'MODULE'  THEN ' Module'
											WHEN 'PERSON'  THEN ' Person'
											WHEN 'PMC'     THEN ' PMC'
											WHEN 'REPORT'  THEN ' Report'
											WHEN 'SOURCE'  THEN ' Source'
                                                                                        WHEN 'FPLAN'   THEN ' Floor Plan'
                                                                                        WHEN 'SITE'    THEN ' Site'
											WHEN 'UNIT'    THEN ' Unit'
											WHEN 'BED'     THEN ' Bed' 
											ELSE ''
										end +
										' Pricing; ' +
										CONVERT	(
												VARCHAR(10), 
												CONVERT(INT,(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                                    then II.EffectiveQuantity
                                                                                                                  else  II.UnitOfMeasure
                                                                                                             end)
                                                                                                        )
												) +
										CASE II.MeasureCode
											WHEN 'BOOK'    THEN ' Book'
											WHEN 'DAY'     THEN ' Day'
											WHEN 'ITEM'    THEN ' Item'
											WHEN 'MODULE'  THEN ' Module'
											WHEN 'PERSON'  THEN ' Person'
											WHEN 'PMC'     THEN ' PMC'
											WHEN 'REPORT'  THEN ' Report'
											WHEN 'SOURCE'  THEN ' Source'
                                                                                        WHEN 'FPLAN'   THEN ' Floor Plan'
                                                                                        WHEN 'SITE'    THEN ' Site'
											WHEN 'UNIT'    THEN ' Unit'
											WHEN 'BED'     THEN ' Bed' 
											ELSE ''
										END + 
										CASE 
											WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                     then II.EffectiveQuantity
                                                                                                   else  II.UnitOfMeasure
                                                                                              end) > 1 THEN 's;'
											ELSE '; '
										END +
										(CASE WHEN (II.Frequencycode = 'OT' and II.ReportingTypeCode NOT IN ('ILFF'))
                                                                                                 THEN ' Period ' + 
											              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101)
                                                                                               WHEN   (II.ReportingTypeCode NOT IN ('ILFF'))  
											         THEN ' Period ' + 
											              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101) +
                                                                                                      ' to ' +
											              CONVERT(VARCHAR(10), II.BillingPeriodToDate, 101)
                                                                                               ELSE ''
                                                                                END)
									END			
								END								       AS [DESCRIPTION],
								(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                        then II.EffectiveQuantity
                                                                      else  II.UnitOfMeasure
                                                                 end)                                                                   AS [QTY],
								CAST(
									 (
										SUM(II.NetChargeAmount) / 
										(CASE WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                   then II.EffectiveQuantity
                                                                                                 else  II.UnitOfMeasure
                                                                                            end) > 0 
                                                                                       THEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                   then II.EffectiveQuantity
                                                                                                  else  II.UnitOfMeasure
                                                                                             end)
                                                                                        ELSE 1 
                                                                                 END)
									 ) 
									 AS NUMERIC(18,4)
									)				     AS [ITEMAMT],
								SUM(II.NetChargeAmount)			     AS [NETAMT], 
								SUM(II.ShippingAndHandlingAmount)         AS [SNHAMT],
								SUM(II.TaxAmount)                         AS [TAXAMT],
								SUM(II.TaxwareGSTCountryTaxAmount)        AS [GSTTaxAmt],
								SUM(II.TaxwarePSTStateTaxAmount)          AS [PSTTaxAmt],
								SUM(II.NetChargeAmount) + 
								SUM(II.ShippingAndHandlingAmount) + 
								SUM(II.TaxAmount)                            AS [EXTAMT],
                                1                                            AS PricingTiers--,
--                                PP.FamilyCode                                AS FamilyCode

      FROM		Invoices.dbo.InvoiceItem	II (nolock) 
      INNER JOIN                                             
                        Products.dbo.Product		PP (nolock)
      ON		II.Productcode		 = PP.Code
      AND               II.PriceVersion		 = PP.PriceVersion
      AND               II.InvoiceIDSeq		 = @IPVC_InvoiceID
      AND		II.InvoiceGroupIDSeq     = @InvGrpID
      WHERE		II.InvoiceIDSeq		 = @IPVC_InvoiceID					
      AND		II.InvoiceGroupIDSeq     = @InvGrpID
      AND       II.MeasureCode <> 'TRAN'
      GROUP BY    II.InvoiceIDSeq,II.ReportingTypeCode,II.FrequencyCode,II.MeasureCode,
                  (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                         then II.EffectiveQuantity
                        else  II.UnitOfMeasure
                   end) ,II.BillingPeriodFromDate,II.BillingPeriodToDate--,FamilyCode
      ORDER BY    FEETYPE ASC, PRODUCT ASC --SRS 01/30/2010 
    END
    ELSE
    BEGIN
      INSERT INTO #TEMP_BillingRecords (OrderItemSeq,InvoiceSeq,RecType,FeeType,Product,
                                        Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTAXAmt,PSTTAXAmt,ExtAmt,
                                        PricingTiers,FamilyCode
                                       )
      SELECT DISTINCT		II.OrderItemIDSeq 	AS [ORDERITEMSEQ],
			 						II.InvoiceIDSeq										AS [INVOICESEQ],
									'B'											AS [RECTYPE],
									SUBSTRING(II.ReportingTypeCode,1,3)					                AS [FEETYPE],
									PP.DisplayName										AS [PRODUCT],
									CASE 
										WHEN (II.ReportingTypeCode IN ('ACSF', 'ILFF')) THEN
											CASE II.FrequencyCode
												WHEN 'YR' THEN 'Annual Fees;'
												WHEN 'SG' THEN 'Initial Fees;'
												WHEN 'MN' THEN 'Monthly Fees;'
												ELSE '' 
											END +
											CASE II.MeasureCode
												WHEN 'SITE' THEN ' Site'
												WHEN 'UNIT' THEN ' Unit'
												WHEN 'BED'  THEN ' Bed'
                                                                                                WHEN 'PMC'  THEN ' PMC'
												ELSE ''
											end +
										(case when II.MeasureCode in ('SITE','UNIT','BED','PMC')
                                                                                      then
											' Pricing; ' +
											CONVERT	(
													VARCHAR(10), 
													CONVERT(INT,(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                                             then II.EffectiveQuantity
                                                                                                                           else  II.UnitOfMeasure
                                                                                                                     end)
                                                                                                               )
													) +
											CASE II.MeasureCode
												WHEN 'SITE' THEN ' Site'
												WHEN 'UNIT' THEN ' Unit'
												WHEN 'BED'  THEN ' Bed'
                                                                                                WHEN 'PMC'  THEN ' PMC' 
												ELSE ''
											END + 
											CASE 
												WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                             then II.EffectiveQuantity
                                                                                                           else  II.UnitOfMeasure
                                                                                                      end) > 1 THEN 's;'
												ELSE '; '
											END 
                                                                                      else ''
                                                                                     end)+
											(CASE WHEN (II.Frequencycode = 'OT' and II.ReportingTypeCode NOT IN ('ILFF'))
                                                                                                 THEN ' Period ' + 
											              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101)
                                                                                               WHEN   (II.ReportingTypeCode NOT IN ('ILFF'))  
											         THEN ' Period ' + 
											              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101) +
                                                                                                      ' to ' +
											              CONVERT(VARCHAR(10), II.BillingPeriodToDate, 101)
                                                                                               ELSE ''
                                                                                         END)
									ELSE
										CASE WHEN (II.ReportingTypeCode IN ('ANCF')) THEN
											CASE II.FrequencyCode
												WHEN 'DY' THEN 'Day;'
												WHEN 'HR' THEN 'Hourly;'
												WHEN 'MI' THEN 'Minutes;'
												WHEN 'OC' THEN 'Usage;'
												WHEN 'OT' THEN 'One-time;'
												ELSE '' 
											END +
											CASE II.MeasureCode
												WHEN 'BOOK'    THEN ' Book'
												WHEN 'DAY'     THEN ' Day'
												WHEN 'ITEM'    THEN ' Item'
												WHEN 'MODULE'  THEN ' Module'
												WHEN 'PERSON'  THEN ' Person'
												WHEN 'PMC'     THEN ' PMC'
												WHEN 'REPORT'  THEN ' Report'
												WHEN 'SOURCE'  THEN ' Source'
                                                                                                WHEN 'FPLAN'   THEN ' Floor Plan'
                                                                                                WHEN 'SITE'    THEN ' Site'
											        WHEN 'UNIT'    THEN ' Unit'
											        WHEN 'BED'     THEN ' Bed' 
												ELSE ''
											end +
											' Pricing; ' +
											CONVERT	(
													VARCHAR(10), 
													CONVERT(INT,(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                                            then II.EffectiveQuantity
                                                                                                                          else  II.UnitOfMeasure
                                                                                                                     end)
                                                                                                                )
													) +
											CASE II.MeasureCode
												WHEN 'BOOK'   THEN ' Book'
												WHEN 'DAY'    THEN ' Day'
												WHEN 'ITEM'   THEN ' Item'
												WHEN 'MODULE' THEN ' Module'
												WHEN 'PERSON' THEN ' Person'
												WHEN 'PMC'    THEN ' PMC'
												WHEN 'REPORT' THEN ' Report'
												WHEN 'SOURCE' THEN ' Source'
                                                                                                WHEN 'FPLAN'   THEN ' Floor Plan'
                                                                                                WHEN 'SITE'    THEN ' Site'
											        WHEN 'UNIT'    THEN ' Unit'
											        WHEN 'BED'     THEN ' Bed' 
												ELSE ''
											END + 
											CASE 
												WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                             then II.EffectiveQuantity
                                                                                                           else  II.UnitOfMeasure
                                                                                                      end)  > 1 THEN 's;'
												ELSE '; '
											END +
											(CASE WHEN (II.Frequencycode = 'OT' and II.ReportingTypeCode NOT IN ('ILFF'))
                                                                                                 THEN ' Period ' + 
											              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101)
                                                                                               WHEN   (II.ReportingTypeCode NOT IN ('ILFF'))  
											         THEN ' Period ' + 
											              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101) +
                                                                                                      ' to ' +
											              CONVERT(VARCHAR(10), II.BillingPeriodToDate, 101)
                                                                                               ELSE ''
                                                                                         END)
									END			
										END									      AS [DESCRIPTION],
									(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                then II.EffectiveQuantity
                                                                               else  II.UnitOfMeasure
                                                                         end)                                                                                  AS [QTY],
									CAST(
										 (
											II.NetChargeAmount / 
											(CASE WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                           then II.EffectiveQuantity
                                                                                                         else  II.UnitOfMeasure
                                                                                                    end)  > 0 
                                                                                                THEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') 
                                                                                                             then II.EffectiveQuantity
                                                                                                           else  II.UnitOfMeasure
                                                                                                      end) 
                                                                                              ELSE 1 
                                                                                         END)
										 ) 
										 AS NUMERIC(18,4)
										)																AS [ITEMAMT],
									II.NetChargeAmount			AS [NETAMT], 
									II.ShippingAndHandlingAmount            AS [SNHAMT],
									II.TaxAmount				AS [TAXAMT],
									II.TaxwareGSTCountryTaxAmount        AS [GSTTaxAmt],
								    II.TaxwarePSTStateTaxAmount          AS [PSTTaxAmt],
									II.NetChargeAmount + 
									II.ShippingAndHandlingAmount + 
									II.TaxAmount				AS [EXTAMT],
                                    II.PricingTiers                         as [PricingTiers],
                                    PP.FamilyCode               AS FamilyCode

      FROM	Invoices.dbo.InvoiceItem	II (nolock) 
      INNER JOIN                                            
                Products.dbo.Product		PP (nolock)
      ON	II.Productcode       = PP.Code
      AND       II.PriceVersion      = PP.PriceVersion
      AND       II.InvoiceIDSeq      = @IPVC_InvoiceID 
      AND	II.InvoiceGroupIDSeq = @InvGrpID
      AND       II.MeasureCode <> 'TRAN' 
      WHERE	II.InvoiceIDSeq      = @IPVC_InvoiceID 
      AND	II.InvoiceGroupIDSeq = @InvGrpID
      ORDER BY	FEETYPE ASC, PRODUCT ASC --SRS 01/30/2010 
    END

    --------------------------------------------------------------------------------------
    -- Find distinct products for each fee type
    --------------------------------------------------------------------------------------
    INSERT INTO   #TEMP_ProductRecords(RecType,FeeType,Description,SortSeq)
    SELECT RecType,FeeType,Description,SortSeq
    from (SELECT DISTINCT	'P'	AS RecType,
			FeeType AS FeeType,
			Product AS Description,
                        CASE WHEN FeeType='ILF' THEN 1
                             WHEN FeeType='ACS' THEN 2
                             WHEN FeeType='ANC' THEN 3
                             WHEN FeeType='TRX' THEN 4
                             ELSE ''
                        END  as SortSeq
          FROM #TEMP_BillingRecords with (nolock)
         ) S
    ORDER BY SortSeq ASC,Description ASC --SRS 01/30/2010
     
    --------------------------------------------------------------------------------------
    -- insert the 'P' records
    --------------------------------------------------------------------------------------
    INSERT INTO #TEMP_ListRecords
                                 (
                                 PSeq,
                                 BSeq,
                                 NSeq,
                                 RecType, 
                                 FeeType,
                                 Description,
                                 SortOrder
                                 )
    SELECT                      PSeq,
                                0,
                                0,
                                RecType,
                                FeeType,
                                Description,
                                CASE WHEN FeeType='ILF' THEN 1
                                     WHEN FeeType='ACS' THEN 2
                                     WHEN FeeType='ANC' THEN 3
                                     WHEN FeeType='TRX' THEN 4
                                     ELSE ''
                                END  as SortSeq				
    FROM #TEMP_ProductRecords with (nolock)
    ORDER BY PSeq ASC -- SRS 01/30/2010
    --------------------------------------------------------------------------------------
    -- insert the 'B' records
    --------------------------------------------------------------------------------------
    INSERT INTO #TEMP_ListRecords
                                (
                                PSeq,
                                BSeq,
                                NSeq,
                                RecType,
                                FeeType,		
                                Description,
                                Qty,
                                ItemAmt,
                                NetAmt,
                                SnHAmt,
                                TaxAmt,
								GSTTAXAmt,
								PSTTAXAmt,
                                ExtAmt,
                                PricingTiers,
                                FamilyCode,
                                SortOrder
                                )
    SELECT                      PRD.PSeq,
                                TID.IDSeq,
                                0,
                                'B',
                                TID.FeeType,
                                TID.Description,
                                TID.Qty,
                                TID.ItemAmt,
                                TID.NetAmt,
                                TID.SnHAmt,
                                TID.TaxAmt,
								TID.GSTTaxAmt,
								TID.PSTTaxAmt,
                                TID.ExtAmt,
                                TID.PricingTiers,
                                FamilyCode,
                                CASE WHEN TID.FeeType='ILF' THEN 1
                                     WHEN TID.FeeType='ACS' THEN 2
                                     WHEN TID.FeeType='ANC' THEN 3
                                     WHEN TID.FeeType='TRX' THEN 4
                                     ELSE ''
                                END
    FROM #TEMP_BillingRecords   TID with (nolock)
    INNER JOIN
         #TEMP_ProductRecords	PRD with (nolock)
    ON   PRD.Description = TID.Product
    AND  PRD.FeeType     = TID.FeeType
    --------------------------------------------------------------------------------------
    --  set loop iterators for inner look
    --------------------------------------------------------------------------------------
    SET	 @CurrIDSeq		= (SELECT max(IDSeq) FROM #TEMP_BillingRecords with (nolock))
    SET	 @MaxIDSeq		= 1
    --------------------------------------------------------------------------------------
    --  loop to evaluate all billing records
    --------------------------------------------------------------------------------------
    BEGIN				
      SET       @LVC_FeeType  = ''	
      SEt       @LI_InnerOrderItemSeq = ''		
      WHILE	@CurrIDSeq >= @MaxIDSeq
      BEGIN ---> Inner Loop BEGIN
        -------------------------------------------------------------------------------
        -- select the product id seq for this current billing record
        -- also get the invoice item id seq to fetch the line items notes
        -- also pick the fee type indicator
        -------------------------------------------------------------------------------
        SELECT	@PIDSeq       = PRD.PSeq,
                @OrderItemSeq = TID.OrderItemSeq,
                @FeeType      = TID.FeeType
        FROM	#TEMP_BillingRecords  TID with (nolock)
        INNER JOIN
                #TEMP_ProductRecords  PRD with (nolock)
        ON	PRD.Description = TID.Product
        AND	PRD.FeeType     = TID.FeeType
        WHERE	TID.IDSeq       = @CurrIDSeq
				
        -- the current id seq is the billing record seq number
        SELECT	@BIDSeq = @CurrIDSeq
        -------------------------------------------------------------------------------
        -- get the notes records FOR @IPVC_InvoiceID  in the loop
        -- When Custom Bundle we get the product names as Notes
        -------------------------------------------------------------------------------
        IF (@IsCustomBun =1 and @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG = 1 and @LVC_FeeType <> @FeeType )
        BEGIN
          SELECT @CurrIDSeq = max(IDSeq) FROM #TEMP_BillingRecords WHERE FeeType=@FeeType
          ---select @CurrIDSeq = 1
          SELECT @BIDSeq    = @CurrIDSeq

          INSERT INTO #TEMP_NotesRecords(PSeq,BSeq,RecType,FeeType,Description)
          SELECT distinct @PIDSeq, 
                          @BIDSeq,
		  	  'N', 
                          @FeeType,
                          PRD.DisplayName				
          FROM Invoices.dbo.InvoiceItem II WITH (nolock)
          INNER JOIN
               Products.dbo.product PRD WITH (nolock)
          ON     II.ProductCode       = PRD.Code
	  AND    II.PriceVersion      = PRD.PriceVersion
          WHERE	 II.InvoiceIDSeq      = @IPVC_InvoiceID
          AND    II.InvoiceGroupIDSeq = @InvGrpID
          AND    II.ChargeTypeCode    = @FeeType

          INSERT INTO	#TEMP_ListRecords 
								(
								PSeq,
								BSeq,
								NSeq,
								RecType,
								FeeType,		
								Description,
								SortOrder
								)
          SELECT	DISTINCT
								PSeq,
								BSeq,
								NSeq,
								RecType,
								FeeType,
								Description,
								CASE WHEN FeeType='ILF' THEN 1
								     WHEN FeeType='ACS' THEN 2
								     WHEN FeeType='ANC' THEN 3
								     WHEN FeeType='TRX' THEN 4
								   ELSE ''
								END
          FROM	#TEMP_NotesRecords
          WHERE	BSeq = @BIDSeq

          SET @LVC_FeeType = @FeeType
        END
        -------------------------------------------------------------------------------
        -- get the notes records FOR @IPVC_InvoiceID and @OrderItemSeq in the loop
        -- with PrintOnInvoiceFlag = 1 ordered by SortSeq
        -------------------------------------------------------------------------------
        IF (@IsCustomBun =0) and (@LI_InnerOrderItemSeq <> @OrderItemSeq)
        BEGIN          
          INSERT INTO #TEMP_NotesRecords(PSeq,BSeq,RecType,FeeType,Description)
          SELECT	@PIDSeq, 
                        @BIDSeq,
                        'N', 
                        @FeeType,
                        IIN.Description
          FROM	   Invoices.dbo.InvoiceItemNote IIN WITH (nolock)
          WHERE	   IIN.InvoiceIDSeq   = @IPVC_InvoiceID 
          AND      IIN.OrderItemIDSeq = @OrderItemSeq
          AND      IIN.PrintOnInvoiceFlag = 1
          ORDER BY IIN.SortSeq ASC

          INSERT INTO #TEMP_ListRecords 
                                       (
                                        PSeq,
                                        BSeq,
                                        NSeq,
                                        RecType,
                                        FeeType,		
                                        Description,
                                        SortOrder
                                       )
          SELECT	PSeq,
                        BSeq,
                        NSeq,
                        RecType,
                        FeeType,
                        Description,
                        CASE WHEN FeeType='ILF' THEN 1
                             WHEN FeeType='ACS' THEN 2
                             WHEN FeeType='ANC' THEN 3
                             WHEN FeeType='TRX' THEN 4
                             ELSE ''
                        END
          FROM	#TEMP_NotesRecords with (nolock)
          WHERE	BSeq = @BIDSeq                              
        END        
        select @LI_InnerOrderItemSeq = @OrderItemSeq
        SELECT @CurrIDSeq = @CurrIDSeq - 1
      END---> Inner Loop END
    END
    TRUNCATE TABLE  #TEMP_BillingRecords
    DELETE FROM     #TEMP_ProductRecords	
    TRUNCATE TABLE  #TEMP_NotesRecords
    SELECT @Curr_InvGrpIDSeq = @Curr_InvGrpIDSeq + 1
  END --End Of Parent WHILE LOOP
  ----------------------------------------------------------------------------------
  ---Total Record for Fee Type 
  INSERT INTO #TEMP_ListRecords (Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,PricingTiers,FamilyCode,SortOrder)
  select NULL          as Description,
         NULL          as Qty,
         NULL          as ItemAmt,
         sum(T.NetAmt) as NetAmt,
         sum(T.SnHAmt) as SnHAmt,
         sum(T.TaxAmt) as TaxAmt,
         sum(T.GSTTaxAmt) as GSTTaxAmt,
         sum(T.PSTTaxAmt) as PSTTaxAmt,
         sum(T.ExtAmt) as ExtAmt,
         'T'           as RecType,
         T.FeeType     as FeeType,
         max(T.PSeq)   as PSeq,
         max(T.BSeq)+20000   as BSeq,
         max(T.NSeq)+20000   as NSeq,
         max(T.TSeq)+20000   as TSeq,
         NULL as PricingTiers,
         NULL as FamilyCode,
         T.SortOrder   as SortOrder
   from #TEMP_ListRecords T with (nolock)
   where T.[RECTYPE] = 'B'
   and   T.FeeType   <> 'TRX'
   group by T.FeeType,T.SortOrder
   ORDER BY T.SortOrder ASC,T.FeeType ASC
 --------------------------------------------------------------------------
  ---Update for TotalRecords
  Update D set D.TotalRecords = Source.TotalRecords
  from   #TEMP_ListRecords D with (nolock)
  inner join
         (select S.PSeq,count(1) as TotalRecords
          from   #TEMP_ListRecords S with (nolock) 
          group by S.PSeq
         ) Source
  on  D.PSeq = Source.PSeq
  and D.[RECTYPE] = 'P'  
  ----------------------------------------------------------------------------------
  ---Call to get TRANSACTIONS
  ----------------------------------------------------------------------------------
  --set identity_insert #TEMP_ListRecords on;
  --Insert into #TEMP_ListRecords(TranIDSeq,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,Description,Qty,ItemAmt,
  --                              NetAmt,SnHAmt,TaxAmt,ExtAmt,PricingTiers,FamilyCode,SortOrder,PageNo,TotalRecords)
  --exec INVOICES.dbo.uspINVOICES_Rep_GetInvoiceDetailTransaction @IPVC_InvoiceID = @IPVC_InvoiceID
  --set identity_insert #TEMP_ListRecords off;  
  --------------------------------------------------------------------------------------
  -- Declaring Local Variables
  --------------------------------------------------------------------------------------
  DECLARE @LV_MinProdCnt INT
  DECLARE @LV_MaxProdCnt INT
  --DECLARE @LV_TranCount  INT   --Commented based on Gwen's Defect ID : 5360
  --DECLARE @LV_TranAmount MONEY --Commented based on Gwen's Defect ID : 5360

  DECLARE @LVC_ProductCode           varchar(50)
  DECLARE @LVC_ProductName           varchar(255)
  DECLARE @LVC_Familycode            varchar(50)
  DECLARE @LDT_BillingPeriodFromDate datetime
  DECLARE @LDT_BillingPeriodToDate   datetime
  ---DECLARE @LI_MaxTransactionItemNameLength int

  DECLARE @LV_PSeq  INT
  DECLARE @LV_BSeq  INT
  DECLARE @LV_NSeq  INT
  DECLARE @LV_TSeq  INT  
  --------------------------------------------------------------------------------------
  -- Creating Temp Tables
  --------------------------------------------------------------------------------------
  CREATE TABLE #Temp_FinalInvoiceTranItems 
				    (
				      sortseq      BIGINT not null IDENTITY(20000,1),
				      Description  VARCHAR(4000),
                                      Qty	   DECIMAL(18,2),
				      ItemAmt	   NUMERIC(18,6),
				      NetAmt	   NUMERIC(18,5),
				      SnHAmt	   NUMERIC(18,5),
				      TaxAmt	   NUMERIC(18,5),
				      GSTTaxAmt	   NUMERIC(18,5),
				      PSTTaxAmt	   NUMERIC(18,5),
				      ExtAmt	   NUMERIC(18,5),
                      RecType      CHAR(1),
                      FeeType	   VARCHAR(4),
                      PSeq			INT,
				      BSeq			INT,
				      NSeq         INT,
				      TSeq         INT,
                      PricingTiers INT,
                      FamilyCode   CHAR(3),
                      SortOrder    INT,
                      PageNo       INT,
                      TotalRecords INT,
                      DisplayTransactionalProductPriceOnInvoiceFlag INT
			            )

  CREATE TABLE #TEMP_TranProductRecords 
        			     (
		  		      PSeq       INT NOT NULL IDENTITY(1,1),
				      ProdCode   VARCHAR(255),
				      ProdName   VARCHAR(255),
					  Familycode varchar(50),
					  FeeType    VARCHAR(4),
					  SortOrder  INT,
					  BillingPeriodFromDate  datetime,
					  BillingPeriodToDate    datetime,
					  MaxTransactionItemNameLength  int
				      )  
  --------------------------------------------------------------------------------------
  -- Populating #TEMP_TranProductRecords table with the ProductCode and ProductName 
  -- for the InvoiceID passed.
  --------------------------------------------------------------------------------------
  INSERT INTO #TEMP_TranProductRecords(ProdCode,ProdName,Familycode,FeeType,SortOrder,BillingPeriodFromDate,BillingPeriodToDate,MaxTransactionItemNameLength)
  SELECT distinct II.ProductCode  as ProdCode,
         Max(P.DisplayName)       as ProdName,
         Max(P.Familycode)        as Familycode,
         'TRX'                    as FeeType,
         4                        as SortOrder,
         II.BillingPeriodFromDate as BillingPeriodFromDate,
         II.BillingPeriodToDate   as BillingPeriodToDate,
         Max(Len(II.TransactionItemName)) as MaxTransactionItemNameLength
  FROM   Invoices.dbo.InvoiceItem II WITH (NOLOCK)
  INNER JOIN
         Products.dbo.Product P WITH (NOLOCK) 
  ON     II.ProductCode     = P.Code 
  and    II.PriceVersion    = P.PriceVersion
  and    II.MeasureCode     = 'TRAN'
  and    II.InvoiceIDSeq     = @IPVC_InvoiceID
  WHERE  II.InvoiceIDSeq     = @IPVC_InvoiceID
  Group by II.ProductCode,II.BillingPeriodFromDate,II.BillingPeriodToDate
  Order by II.ProductCode ASC,II.BillingPeriodFromDate ASC,II.BillingPeriodToDate ASC,SortOrder ASC

  --------------------------------------------------------------------------------------
  -- Assigining values to the Local Variables / Loop Iterators
  --------------------------------------------------------------------------------------
   SET @LV_MinProdCnt = 1
   Select  @LV_MaxProdCnt    = max(PSeq)
           ---,@LI_MaxTransactionItemNameLength = Max(MaxTransactionItemNameLength)
   FROM #TEMP_TranProductRecords WITH (NOLOCK)
    
   SET @LV_PSeq = 1
   SET @LV_BSeq = 1
   SET @LV_NSeq = 1
   SET @LV_TSeq = 1
  ------------------------------------------------------------------------------------------------
  -- "WHILE" loop to Insert the data into #Temp_FinalInvoiceTranItems table
  ------------------------------------------------------------------------------------------------
  WHILE @LV_MinProdCnt<=@LV_MaxProdCnt
  BEGIN
    Select @LVC_ProductCode           = S.ProdCode,
           @LVC_ProductName           = S.ProdName,
           @LVC_Familycode            = S.Familycode,
           @LDT_BillingPeriodFromDate = S.BillingPeriodFromDate,
           @LDT_BillingPeriodToDate   = S.BillingPeriodToDate
    from   #TEMP_TranProductRecords S WITH (NOLOCK)
    where  PSeq = @LV_MinProdCnt 
    --------------------------------------------------------------------------------------------------
    -- Inserting Transaction Description,Date,ServiceCode and Amount into #Temp_FinalInvoiceTranItems
    --------------------------------------------------------------------------------------------------
    INSERT INTO #Temp_FinalInvoiceTranItems (Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt, PSTTaxAmt,ExtAmt,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,PricingTiers,FamilyCode,SortOrder,DisplayTransactionalProductPriceOnInvoiceFlag)
    SELECT distinct 
           @LVC_ProductName                                                         AS Description,
           SUM(II.EffectiveQuantity)                                                AS [QTY],
           convert(NUMERIC(18,6),SUM(II.NetChargeAmount))
                    /
                  (case when SUM(II.EffectiveQuantity) >0 then SUM(II.EffectiveQuantity)
                         else 1
                   end )                                                            AS [ITEMAMT],
            Convert(money,SUM(II.NetChargeAmount))			            AS NETAMT, 
			Convert(money,SUM(II.ShippingAndHandlingAmount))            AS SNHAMT,
			Convert(money,SUM(II.TaxAmount))                            AS TAXAMT,
			Convert(money,SUM(II.TaxwareGSTCountryTaxAmount))           AS GSTTAXAMT,
			Convert(money,SUM(II.TaxwarePSTStateTaxAmount))             AS PSTTAXAMT,
			Convert(money,SUM(II.NetChargeAmount)) + 
			Convert(money,SUM(II.ShippingAndHandlingAmount)) + 
			Convert(money,SUM(II.TaxAmount))                            AS EXTAMT,            
            'P'                                          AS [RECTYPE],
            'TRX'           							 AS [FEETYPE],
            @LV_PSeq                                     AS [PSEQ],
            @LV_BSeq                                     AS [BSEQ],
            0                                            AS [NSEQ],
            0                                            AS [TSEQ],
            1                                            AS [PRICINGTIERS],
            @LVC_Familycode                              AS [FAMILYCODE],
            4                                            AS [SORTORDER],
            MAX(convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag))      as [DisplayTransactionalProductPriceOnInvoiceFlag]
    FROM  Invoices.dbo.InvoiceItem II WITH (NOLOCK)
    INNER JOIN
          Products.dbo.Charge      C WITH (NOLOCK)
    ON    II.ProductCode   =  C.ProductCode
    and   II.PriceVersion  =  C.PriceVersion
    and   II.ChargeTypeCode=  C.Chargetypecode
    and   II.Measurecode   =  C.Measurecode
    and   II.Frequencycode =  C.FrequencyCode
    and   II.MeasureCode   = 'TRAN'
    and   C.MeasureCode    = 'TRAN'
    and   II.InvoiceIDSeq  =  @IPVC_InvoiceID
    and   II.ProductCode   =  @LVC_ProductCode
    and   C.ProductCode    =  @LVC_ProductCode
    and   II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
    and   II.BillingPeriodToDate   = @LDT_BillingPeriodToDate 
    WHERE II.InvoiceIDSeq  =  @IPVC_InvoiceID
    AND   II.ProductCode   =  @LVC_ProductCode
    AND   II.MeasureCode   = 'TRAN'				  
    AND   II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
    AND   II.BillingPeriodToDate   = @LDT_BillingPeriodToDate  
    GROUP BY II.InvoiceIDSeq,II.ReportingTypeCode,II.ProductCode,II.FrequencyCode,II.Measurecode,
             II.BillingPeriodFromDate,II.BillingPeriodToDate
    ---------------------------------------------------------------------
    -- Inserting Transaction Description into #Temp_FinalInvoiceTranItems
    ---------------------------------------------------------------------
    INSERT INTO #Temp_FinalInvoiceTranItems (Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,SortOrder,DisplayTransactionalProductPriceOnInvoiceFlag)
    SELECT /*Substring(
                     II.TransactionItemName + REPLICATE(' ',(@LI_MaxTransactionItemNameLength-Len(II.TransactionItemName))) +
                     (case when isdate(II.TransactionDate) = 1
                              then  convert(varchar(20),II.TransactionDate,101) + ' - ' 
                            else ''
                      end)                      
                     ,1,1000)                                AS [Description],*/
              Substring(
                         (case when isdate(II.TransactionDate) = 1
                                 then  convert(varchar(20),II.TransactionDate,101) + ' - ' 
                               else ''
                          end) + 
                          II.TransactionItemName                                           
                     ,1,1000)                                AS [Description],
               (case when convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag)=0 
                       then NULL 
                     else II.EffectiveQuantity 
               end)                                         AS [QTY],
               (case when convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag)=0 
                       then NULL
                     else
                           convert(NUMERIC(18,6),(II.NetChargeAmount))
                            /
                           (case when (II.EffectiveQuantity) >0 then (II.EffectiveQuantity)  else 1  end )
               end)                                                         AS [ITEMAMT],
               (case when convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag)=0 
                       then NULL 
                     else Convert(money,(II.NetChargeAmount))	
               end)                                                         AS NETAMT, 
               (case when convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag)=0 
                       then NULL 
                     else Convert(money,(II.ShippingAndHandlingAmount))	
               end)                                                         AS SNHAMT,  
               (case when convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag)=0 
                       then NULL 
                     else Convert(money,(II.TaxAmount))	
               end)                                                         AS TAXAMT, 
				(case when convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag)=0 
                       then NULL 
                     else Convert(money,(II.TaxwareGSTCountryTaxAmount))	
               end)                                                         AS GSTTAXAMT, 
				(case when convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag)=0 
                       then NULL 
                     else Convert(money,(II.TaxwarePSTStateTaxAmount))	
               end)                                                         AS PSTTAXAMT,  
               (case when convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag)=0 
                       then NULL 
                     else Convert(money,(II.NetChargeAmount)) + 
			  Convert(money,(II.ShippingAndHandlingAmount)) + 
			  Convert(money,(II.TaxAmount))	
               end)                                                         AS EXTAMT,        
               'N'                                           AS [RECTYPE],
               'TRX'       	                             AS [FEETYPE],
                @LV_PSeq,
                @LV_BSeq,
                @LV_NSeq,
                0,
                4                                            AS [SORTORDER],
                convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag)      AS DisplayTransactionalProductPriceOnInvoiceFlag
    FROM Invoices.dbo.InvoiceItem II WITH (NOLOCK)
    INNER JOIN
          Products.dbo.Charge      C WITH (NOLOCK)
    ON    II.ProductCode   =  C.ProductCode
    and   II.PriceVersion  =  C.PriceVersion
    and   II.ChargeTypeCode=  C.Chargetypecode
    and   II.Measurecode   =  C.Measurecode
    and   II.Frequencycode =  C.FrequencyCode
    and   II.MeasureCode   = 'TRAN'
    and   C.MeasureCode    = 'TRAN'
    and   II.InvoiceIDSeq  =  @IPVC_InvoiceID
    and   II.ProductCode   =  @LVC_ProductCode
    and   C.ProductCode    =  @LVC_ProductCode
    and   II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
    and   II.BillingPeriodToDate   = @LDT_BillingPeriodToDate
    WHERE II.InvoiceIDSeq  = @IPVC_InvoiceID
    AND   II.MeasureCode   = 'TRAN'
    AND   II.ProductCode   =  @LVC_ProductCode
    AND   II.BillingPeriodFromDate = @LDT_BillingPeriodFromDate
    AND   II.BillingPeriodToDate   = @LDT_BillingPeriodToDate 
    ORDER BY  II.TransactionDate ASC,II.TransactionItemName ASC

    SELECT @LV_PSeq = @LV_PSeq + 1,
           @LV_BSeq = @LV_BSeq + 1,
           @LV_NSeq = @LV_NSeq + 1,
           @LV_TSeq = @LV_TSeq + 1

    SELECT @LV_MinProdCnt = @LV_MinProdCnt + 1   -- Incrementing the Loop Iterator

  END  -- End of "WHILE" loop
  --------------------------------------------------------------------------
  ---Total Record for Fee Type TRX'
  if exists (select top 1 1 from #Temp_FinalInvoiceTranItems with (nolock))
  begin
    INSERT INTO #Temp_FinalInvoiceTranItems (Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,PricingTiers,FamilyCode,SortOrder)
    select NULL          as Description,
           NULL          as Qty,
           NULL          as ItemAmt,
           sum(T.NetAmt) as NetAmt,
           sum(T.SnHAmt) as SnHAmt,
           sum(T.TaxAmt) as TaxAmt,
           sum(T.GSTTaxAmt) as GSTTaxAmt,
           sum(T.PSTTaxAmt) as PSTTaxAmt,
           sum(T.ExtAmt) as ExtAmt,
           'T'           as RecType,
           'TRX'         as FeeType,
           max(T.PSeq)   as PSeq,
           max(T.BSeq)+20000   as BSeq,
           max(T.NSeq)+20000   as NSeq,
           max(T.TSeq)+20000   as TSeq,
           NULL as PricingTiers,
           NULL as FamilyCode,
           4    as SortOrder
     from #Temp_FinalInvoiceTranItems T with (nolock)
     where T.[FEETYPE] = 'TRX'
     and   T.[RECTYPE] = 'P'   
    --------------------------------------------------------------------------
    ---Update for TotalRecords
    Update D set D.TotalRecords = Source.TotalRecords
    from   #Temp_FinalInvoiceTranItems D with (nolock)
    inner join
           (select S.PSeq,count(1) as TotalRecords
            from   #Temp_FinalInvoiceTranItems S with (nolock) 
            group by S.PSeq
           ) Source
    on  D.PSeq = Source.PSeq
    and D.[RECTYPE] = 'P'
    --------------------------------------------------------------------------
    ---Update to null out Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,ExtAmt for P  RECTYPE 
    ---  records where DisplayTransactionalProductPriceOnInvoiceFlag is set to 0
    Update #Temp_FinalInvoiceTranItems
    set   Qty=NULL,ItemAmt=NULL,NetAmt=NULL,SnHAmt=NULL,TaxAmt=NULL,ExtAmt=NULL
    where [RECTYPE] = 'P'
    and   DisplayTransactionalProductPriceOnInvoiceFlag = 1
    --------------------------------------------------------------------------
    -- Final Select to retrieve the data for the Transactions
    --------------------------------------------------------------------------
    Insert into #TEMP_ListRecords(TranIDSeq,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,Description,Qty,ItemAmt,
                                  NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,PricingTiers,FamilyCode,SortOrder,PageNo,TotalRecords)
    SELECT sortseq as IDSeq,
           RecType,
           FeeType,
           PSeq,
           BSeq,
           NSeq,
           TSeq,           
           Description,
           Qty,
           ItemAmt,
           NetAmt,
           SnHAmt,
           TaxAmt,
           GSTTaxAmt,
           PSTTaxAmt,
           ExtAmt,
           PricingTiers,
           FamilyCode,
           SortOrder,
           PageNo,
           TotalRecords
    FROM   #Temp_FinalInvoiceTranItems WITH (NOLOCK)
    ORDER  by sortseq ASC
  end
  -----------------------------------------------------------------
  -- Dropping the temporary table
  -----------------------------------------------------------------
  DROP TABLE #TEMP_TranProductRecords
  DROP TABLE #Temp_FinalInvoiceTranItems
  ----------------------------------------------------------------------------------  
  -----------------------------------------------------------------------------------
  --  Updating Page No Column
  --------------------------------------------------------------------------------------
  -- Looping var
  DECLARE @IDX_IDSeq    INT,
          @MAX_IDSeq    INT,
          @IDX_FEETYPE  VARCHAR(5),
          @LST_FEETYPE  VARCHAR(5),
          @PAGE_NUMBER  INT,
          @REC_TYPE     VARCHAR(1),
          @TotalRecords INT
         
  -- Line Width var
  DECLARE @PROD_WIDTH   NUMERIC(18, 6),
          @NOTE_WIDTH   NUMERIC(18, 6),
          @SPACE_WIDTH  NUMERIC(18, 6),
          @SPACE_USED   NUMERIC(18, 6),
          @TOTAL_WIDTH  NUMERIC(18, 6),
          @LINE_WIDTH   NUMERIC(18, 6),
          @SPACE_AVAIL  NUMERIC(18, 6);

  SELECT  @IDX_IDSeq = 1,
          @MAX_IDSeq = MAX(IDSeq) FROM #TEMP_ListRecords;

--@SPACE_WIDTH = 0.22500 + 0.03125 + 0.22500 + 0.10000,
--@SPACE_WIDTH = 0.22500 + 0.05208 + 0.16667 + 0.25 + 0.07302,
  SELECT  @PROD_WIDTH = 0.16250,
          @NOTE_WIDTH = 0.09490,
          @SPACE_WIDTH = 0.25 + 0.07302,
          @SPACE_USED = 0.0,
          @SPACE_AVAIL = 3.1,
          @TOTAL_WIDTH = 0.1667 + 0.05208,
          @LINE_WIDTH = 0.03125,
          @PAGE_NUMBER = 1;

  DECLARE @PAGE_LIST TABLE (
    IDSeq       INT NOT NULL IDENTITY(1,1), 
    ListIDSeq   INT NOT NULL
  )

  DECLARE @PAGE_IDX TABLE (
    LastFeeType   VARCHAR(5),
    CurrFeeType   VARCHAR(5),
    SpaceUsed     NUMERIC(18,6),
    SpaceAvail    NUMERIC(18,6),
    PageNumber    int
  )
  
  INSERT INTO @PAGE_LIST
    ( ListIDSeq )
  SELECT IDSeq FROM #TEMP_ListRecords ORDER BY SortOrder ASC,FeeType ASC,PSeq ASC,BSeq ASC,NSeq ASC;
  
  SELECT @LST_FEETYPE=FeeType FROM #TEMP_ListRecords WHERE IDSeq = (SELECT ListIDSeq FROM @PAGE_LIST WHERE IDSeq = @IDX_IDSeq );
	
  WHILE		@IDX_IDSeq <= @MAX_IDSeq
	BEGIN
    SELECT @IDX_FEETYPE=FeeType, @REC_TYPE=RecType,@TotalRecords=TotalRecords
    FROM #TEMP_ListRecords WHERE IDSeq = (SELECT ListIDSeq FROM @PAGE_LIST WHERE IDSeq = @IDX_IDSeq );

    INSERT INTO @PAGE_IDX
      SELECT @LST_FEETYPE, @IDX_FEETYPE, @SPACE_USED, @SPACE_AVAIL, @PAGE_NUMBER

    -- Check for New Group
    IF @IDX_FEETYPE <> @LST_FEETYPE 
    BEGIN
      -- New Group.  Account for Space between group list in report.
      SET @SPACE_USED = @SPACE_USED + @SPACE_WIDTH;
      SET @LST_FEETYPE = @IDX_FEETYPE;
    END

    -- Check for Record Type
    IF @REC_TYPE = 'P'
    BEGIN
      SET @SPACE_USED = @SPACE_USED + @PROD_WIDTH
    END
    ELSE IF @REC_TYPE = 'T'
    BEGIN
      SET @SPACE_USED = @SPACE_USED + @TOTAL_WIDTH
    END
    ELSE IF @REC_TYPE = 'Z'
    BEGIN
      SET @SPACE_USED = @SPACE_USED + @LINE_WIDTH
    END
    ELSE
    BEGIN
      SET @SPACE_USED = @SPACE_USED + @NOTE_WIDTH
    END
    
    -- Check for Space Available
    IF ( (@SPACE_USED >= @SPACE_AVAIL)
           OR 
        (@REC_TYPE = 'P' and @LST_FEETYPE <> 'TRX' and 
          ((@TotalRecords * @NOTE_WIDTH)+@SPACE_USED) >= @SPACE_AVAIL )
       )
    BEGIN
      -- Start New page and reset Space Available.
      SET @PAGE_NUMBER = @PAGE_NUMBER + 1;
      SET @SPACE_AVAIL = 7.3;
      SET @SPACE_USED = @SPACE_WIDTH;
    END

    UPDATE #TEMP_ListRecords SET PageNo = @PAGE_NUMBER WHERE IDSeq = (SELECT ListIDSeq FROM @PAGE_LIST WHERE IDSeq = @IDX_IDSeq );
    SET @IDX_IDSeq = @IDX_IDSeq + 1

  END

  --SELECT * FROM @PAGE_IDX
  --------------------------------------------------------------------------------------
  --Get the Max Page Number of Main Invoice PDF Report and Update Invoice Header.
  -- The Total Page Count is used by Printing Engine.
  select @LI_MainInvoicePageCount = Max(PageNo) from #TEMP_ListRecords with (nolock)
  Update Invoices.dbo.Invoice 
  set    MainInvoicePageCount = coalesce(@LI_MainInvoicePageCount,0)
  where  InvoiceIDSeq = @IPVC_InvoiceID  
  --------------------------------------------------------------------------------------
  ---Insert to Dummy Record RecType='Z' for Blank line for SRS
  set identity_insert #TEMP_ListRecords on;
  INSERT INTO #TEMP_ListRecords (IDSeq,Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,PricingTiers,FamilyCode,SortOrder,PageNo)
  select Max(T.IDSeq)   as IDSeq,
         NULL           as Description,
         NULL           as Qty,
         NULL           as ItemAmt,
         0              as NetAmt,
         0              as SnHAmt,
         0              as TaxAmt,
         0              as GSTTaxAmt,
         0              as PSTTaxAmt,
         0              as ExtAmt,
         'Z'            as RecType,
         Max(T.FeeType) as FeeType,
         max(T.PSeq)    as PSeq,
         max(T.BSeq)+50000   as BSeq,
         max(T.NSeq)+50000   as NSeq,
         max(T.TSeq)+50000   as TSeq,
         NULL as PricingTiers,
         NULL as FamilyCode,
         Max(T.SortOrder)   as SortOrder,
         T.PageNo           as PageNo
   from #TEMP_ListRecords T with (nolock)
   group by T.PageNo
   set identity_insert #TEMP_ListRecords on;
  --  Final SELECT to retrieve the data for the Invoice
  --------------------------------------------------------------------------------------
  SELECT IDSeq,
         RecType,
         FeeType,
         PSeq,
         BSeq,
         NSeq,
         TSeq,           
         Description,
         Qty,
         ItemAmt,
         NetAmt,
         SnHAmt,
         TaxAmt,
		 GSTTaxAmt,
		 PSTTaxAmt,
         ExtAmt,
         PricingTiers,
         FamilyCode,
         SortOrder,
         PageNo         
  FROM #TEMP_ListRecords 
  ORDER BY PageNo ASC,SortOrder ASC,PSeq ASC,BSeq ASC,NSeq ASC 
  --------------------------------------------------------------------------------------
   --  Dropping the temporary tables
  --------------------------------------------------------------------------------------
  DROP TABLE #TEMP_BillingRecords
  DROP TABLE #TEMP_ProductRecords	
  DROP TABLE #TEMP_NotesRecords
  DROP TABLE #TEMP_ListRecords
  DROP TABLE #TEMP_InvGroupRecords
  --------------------------------------------------------------------------------------
END
GO
