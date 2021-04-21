SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_GetInvoiceDetailASXML
-- Description     : This procedure gets Invoice Details pertaining to passed InvoiceID
-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(15)
--      
-- Code Example    : 
/*
--OLD 
Exec INVOICES.dbo.uspINVOICES_Rep_GetInvoiceDetail @IPVC_InvoiceID ='I1106012295' 
Exec INVOICES.dbo.uspINVOICES_Rep_GetInvoiceDetail @IPVC_InvoiceID ='I1106012289'
--NEW
declare @LXML_Detail1 xml
EXEC	 INVOICES.dbo.[uspINVOICES_GetInvoiceDetailAsXML]
		@LXML_Detail1  OUTPUT,
		@IPVC_InvoiceID = N'I1106012295'
select @LXML_Detail1

-- Syntax for call :
                   
declare @LXML_Detail1 xml
EXEC	 INVOICES.dbo.[uspINVOICES_GetInvoiceDetailAsXML]
		@LXML_Detail1  OUTPUT,
		@IPVC_InvoiceID = N'I1106012289'
select @LXML_Detail1
*/
-- 
-- Revision History:
-- Author          : 
-- 03/18/2007      : Stored Procedure Created. This is used only in SRS report Invoice From
-- 07/02/2008      : Defect #5298 (Aligned code and commented insertion/grouping of FamilyCode for custom Bundle in #TEMP_BillingRecords table)
-- 07/05/2011      : TFS 821 for GSTTaxAmt and PSTTaxAmt enhancement                 
------------------------------------------------------------------------------------------------------
create PROCEDURE [invoices].[uspINVOICES_GetInvoiceDetailAsXML](@Detail xml output,@IPVC_InvoiceID    VARCHAR(50)                                                        
							  )
AS
BEGIN 
  SET NOCOUNT ON; 
  SET CONCAT_NULL_YIELDS_NULL OFF;
--------------------------------------------------------------------------------------
-- Declaring Local Variables
--------------------------------------------------------------------------------------

	DECLARE  @TEMP_InvGroupRecords TABLE
	(
		IGSeq			INT NOT NULL IDENTITY(1,1) Primary Key,
		GroupID			BIGINT,
		GroupName		VARCHAR(70),
		CBEnabledFlag	        VARCHAR(4),
		EXPFLAG			BIT
	)
	DECLARE  @TEMP_ProductRecords TABLE
	(
		PSeq			INT NOT NULL IDENTITY(1,1) Primary Key,
		RecType			CHAR(1),
		FeeType			VARCHAR(4),
		Description		VARCHAR(255),
		SortSeq			Int --SRS 01/30/2010
	)
	DECLARE @TEMP_BillingRecords	TABLE 
	(
		IDSeq                   INT NOT NULL IDENTITY(1,1) Primary Key,
		OrderItemSeq	        VARCHAR(12),
		InvoiceSeq		VARCHAR(12),	  
		RecType			CHAR(2),
		FeeType			VARCHAR(4),
		Product			VARCHAR(255),
		Description		VARCHAR(1000),
		Qty			DECIMAL(18,2),
		ItemAmt			NUMERIC(18,4),
		NetAmt			NUMERIC(18,5),
		SnHAmt			NUMERIC(18,5),
		TaxAmt			NUMERIC(18,5),
		ExtAmt			NUMERIC(18,5),
		PricingTiers            INT,
		FamilyCode              CHAR(3),
                GSTTaxAmt               NUMERIC(18,5),
                PSTTaxAmt               NUMERIC(18,5), 
                BillingPeriodFromDate   datetime, 
                BillingPeriodToDate     datetime
	)
	DECLARE  @TEMP_NotesRecords TABLE
	(
		NSeq			INT NOT NULL IDENTITY(1,1) Primary Key,
		PSeq			INT NOT NULL,
		BSeq			INT NOT NULL,
		RecType			CHAR(1),
		FeeType			VARCHAR(4),
		Description		VARCHAR(8000)
	)
	CREATE Table  #TEMP_ListRecords 
	(
		IDSeq				INT NOT NULL IDENTITY (1,1),
		RecType				CHAR(1),
		FeeType				VARCHAR(4),		
		PSeq				INT NOT NULL default 0,
		BSeq				INT NOT NULL default 0,
		NSeq				INT NOT NULL default 0,
		TSeq				INT NOT NULL default 0,
		Description			VARCHAR(8000),
		Qty				DECIMAL(18,2),
		ItemAmt				NUMERIC(18,4),
		NetAmt				NUMERIC(18,5),
		SnHAmt				NUMERIC(18,5),
		TaxAmt				NUMERIC(18,5),
		ExtAmt				NUMERIC(18,5),
		PricingTiers                    INT,
		FamilyCode                      CHAR(3),
		SortOrder			INT,
		PageNo				INT,
		TotalRecords                    INT,
                GSTTaxAmt                       NUMERIC(18,5),
                PSTTaxAmt                       NUMERIC(18,5),
		TranIDSeq                       INT NULL, -- dummy column for transactions
                LineItemCount                   INT NOT NULL default(0),
                ProductRecordCount              INT NOT NULL default 0
	)
	DECLARE  @TEMP_TranProductRecords TABLE
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
	DECLARE  @TEMP_FinalInvoiceTranItems TABLE 
	(
		sortseq      BIGINT not null IDENTITY(20000,1),
		Description  VARCHAR(4000),
		Qty	     DECIMAL(18,2),
		ItemAmt	     NUMERIC(18,6),
		NetAmt	     NUMERIC(18,5),
		SnHAmt	     NUMERIC(18,5),
		TaxAmt	     NUMERIC(18,5),
                GSTTaxAmt    NUMERIC(18,5),
                PSTTaxAmt    NUMERIC(18,5),
		ExtAmt	     NUMERIC(18,5),
		RecType      CHAR(1),
		FeeType	     VARCHAR(4),
		PSeq	     INT,
		BSeq	     INT,
		NSeq         INT,
		TSeq         INT,
		PricingTiers INT,
		FamilyCode   CHAR(3),
		SortOrder    INT,
		PageNo       INT,
		TotalRecords INT,
		DisplayTransactionalProductPriceOnInvoiceFlag INT
	)

DECLARE @Curr_InvGrpIDSeq					BIGINT
DECLARE @Max_InvGrpIDSeq					BIGINT
DECLARE @CurrIDSeq						BIGINT
DECLARE @MaxIDSeq						BIGINT
DECLARE @PIDSeq							BIGINT
DECLARE @BIDSeq							BIGINT
DECLARE @TIDSeq							BIGINT
DECLARE @OrderItemSeq						BIGINT
DECLARE @LI_InnerOrderItemSeq				        BIGINT
DECLARE @FeeType						VARCHAR(4)
Declare @InvGrpID						BIGINT
DEclare @IsCustomBun						BIT
DEclare @GroupName						VARCHAR(70)
DECLARE @LVB_CMPBUNDLEFLAG					BIT
DECLARE @LVB_CMPBUNDLEEXPFLAG				        BIT
DECLARE @LVB_PRPBUNDLEEXPFLAG				        BIT
DECLARE @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG	                BIT 
DECLARE @LVC_FeeType						VARCHAR(3)
DECLARE @LI_MainInvoicePageCount			        INT
DECLARE @ErrorMessage						varchar(1000)
DECLARE @ErrorSeverity						Int
DECLARE @ErrorState						Int
DECLARE @LV_MinProdCnt INT
DECLARE @LV_MaxProdCnt INT
DECLARE @LVC_ProductCode           varchar(50)
DECLARE @LVC_ProductName           varchar(255)
DECLARE @LVC_Familycode            varchar(50)
DECLARE @LDT_BillingPeriodFromDate datetime
DECLARE @LDT_BillingPeriodToDate   datetime
DECLARE @LV_PSeq  INT
DECLARE @LV_BSeq  INT
DECLARE @LV_NSeq  INT
DECLARE @LV_TSeq  INT  

BEGIN TRY

SET @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG = 0;
-------------------------------------------------------------------
SELECT	@LVB_CMPBUNDLEFLAG = CASE INV.AccountTypeCode WHEN 'AHOFF' THEN 1 ELSE 0 END,
		@LVB_CMPBUNDLEEXPFLAG = CASE CMP.CustomBundlesProductBreakDownTypeCode WHEN 'YEBR' THEN 1 ELSE 0 END,
		@LVB_PRPBUNDLEEXPFLAG = CASE PRP.CustomBundlesProductBreakDownTypeCode WHEN 'NOBR' THEN 0 ELSE 1 END
FROM	INVOICES.DBO.INVOICE INV with (nolock)
INNER JOIN CUSTOMERS.DBO.COMPANY  CMP with (nolock)	ON	CMP.IDSeq = INV.CompanyIDSeq and INV.InvoiceIDSeq = @IPVC_InvoiceID 
LEFT JOIN CUSTOMERS.DBO.PROPERTY PRP with (nolock) ON INV.PropertyIdSeq = PRP.IDSeq and INV.InvoiceIDSeq = @IPVC_InvoiceID 
WHERE   INV.InvoiceIDSeq = @IPVC_InvoiceID   

IF ((@LVB_CMPBUNDLEEXPFLAG & @LVB_PRPBUNDLEEXPFLAG = 1) OR (@LVB_CMPBUNDLEFLAG & @LVB_CMPBUNDLEEXPFLAG = 1) OR (~@LVB_CMPBUNDLEFLAG & @LVB_PRPBUNDLEEXPFLAG = 1)) SET @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG = 1

INSERT INTO	@TEMP_InvGroupRecords(GroupID,GroupName,CBEnabledFlag,EXPFLAG)
	SELECT	DISTINCT IDSeq,[Name],CustomBundleNameEnabledFlag,@LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG
	FROM	Invoices.dbo.InvoiceGroup WITH (nolock) WHERE InvoiceIDSeq = @IPVC_InvoiceID
	ORDER BY IDSeq ASC --SRS 01/30/2010

SET @Curr_InvGrpIDSeq = 1;
SET	@Max_InvGrpIDSeq = (SELECT max(IGSeq) FROM @TEMP_InvGroupRecords);


WHILE @Curr_InvGrpIDSeq <= @Max_InvGrpIDSeq BEGIN
	SELECT @InvGrpID = GroupID, @IsCustomBun = CBEnabledFlag, @GroupName = GroupName FROM @TEMP_InvGroupRecords WHERE IGSEq = @Curr_InvGrpIDSeq
	
    IF (@IsCustomBun=1) BEGIN
      INSERT INTO  @TEMP_BillingRecords(OrderItemSeq,InvoiceSeq,RecType,FeeType,Product,Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,PricingTiers,BillingPeriodFromDate,BillingPeriodToDate)
      SELECT DISTINCT 
			0					AS [ORDERITEMSEQ],
			II.InvoiceIDSeq		AS [INVOICESEQ],
			'B'					AS [RECTYPE],
			SUBSTRING(II.ReportingTypeCode,1,3)			AS [FEETYPE],
			@GroupName			AS [PRODUCT],
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
					END +
					CASE 
						WHEN II.MeasureCode in ('SITE','UNIT','BED','PMC') THEN ' Pricing; ' + 
							CONVERT(VARCHAR(10),CONVERT(INT,(
								CASE WHEN (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') THEN II.EffectiveQuantity 
									ELSE  II.UnitOfMeasure 
								END))) +
							CASE II.MeasureCode
								WHEN 'SITE' THEN ' Site'
								WHEN 'UNIT' THEN ' Unit'
								WHEN 'BED'  THEN ' Bed'
                                                                WHEN 'PMC'  THEN ' PMC'
								ELSE ''
							END + 
							CASE 
								WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') THEN II.EffectiveQuantity ELSE  II.UnitOfMeasure END) > 1 THEN 's;'
								ELSE '; '
							END 
						ELSE ''
                     END +
					CASE 
						WHEN (II.Frequencycode = 'OT' and II.ReportingTypeCode NOT IN ('ILFF')) THEN ' Period ' + 
							CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101) 
						WHEN   (II.ReportingTypeCode NOT IN ('ILFF')) THEN ' Period ' + 
							CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101) + ' to ' + CONVERT(VARCHAR(10), II.BillingPeriodToDate, 101)
						ELSE ''
					END	
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
						END + ' Pricing; ' + 
						CONVERT(VARCHAR(10),CONVERT(INT,(CASE WHEN (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') THEN II.EffectiveQuantity ELSE  II.UnitOfMeasure END))+
						CASE II.MeasureCode
							WHEN 'BOOK'    THEN  ' Book'
							WHEN 'DAY'     THEN  ' Day'
							WHEN 'ITEM'    THEN  ' Item'
							WHEN 'MODULE'  THEN  ' Module'
							WHEN 'PERSON'  THEN  ' Person'
							WHEN 'PMC'     THEN  ' PMC'
							WHEN 'REPORT'  THEN  ' Report'
							WHEN 'SOURCE'  THEN  ' Source'
                                                        WHEN 'FPLAN'   THEN  ' Floor Plan'
                                                        WHEN 'SITE'    THEN  ' Site'
							WHEN 'UNIT'    THEN  ' Unit'
							WHEN 'BED'     THEN  ' Bed' 
							ELSE ''
						END + 
						CASE 
							WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') THEN II.EffectiveQuantity ELSE  II.UnitOfMeasure END) > 1 THEN 's;'
							ELSE '; '
						END +
						CASE 
								WHEN (II.Frequencycode = 'OT' and II.ReportingTypeCode NOT IN ('ILFF')) THEN ' Period ' + 
									CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101)
								WHEN (II.ReportingTypeCode NOT IN ('ILFF')) THEN ' Period ' + 
									CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101) + ' to ' + CONVERT(VARCHAR(10), II.BillingPeriodToDate, 101)
								ELSE ''
                        END)
					END
				END AS [DESCRIPTION],
				CASE 
					WHEN (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') then II.EffectiveQuantity
					ELSE  II.UnitOfMeasure
                END AS [QTY],
				CAST((SUM(II.NetChargeAmount) / 
					(CASE WHEN 
						(CASE 
							WHEN (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') THEN II.EffectiveQuantity 
							ELSE  II.UnitOfMeasure 
						END) > 0 THEN 
						(CASE WHEN (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') then II.EffectiveQuantity 
							ELSE  II.UnitOfMeasure 
						END)
					ELSE 1 
					END)) AS NUMERIC(18,4))		  AS [ITEMAMT],
				SUM(II.NetChargeAmount)			  AS [NETAMT], 
				SUM(II.ShippingAndHandlingAmount)         AS [SNHAMT],
				SUM(II.TaxAmount)                         AS [TAXAMT],
                                SUM(II.TaxwareGSTCountryTaxAmount)        AS [GSTTaxAmt],
                                SUM(II.TaxwarePSTStateTaxAmount)          AS [PSTTaxAmt],
				SUM(II.NetChargeAmount) + SUM(II.ShippingAndHandlingAmount) + SUM(II.TaxAmount)                 AS [EXTAMT],
                1                                             AS PricingTiers
                ,II.BillingPeriodFromDate                     as BillingPeriodFromDate
                ,II.BillingPeriodToDate                       as BillingPeriodToDate
		  FROM		Invoices.dbo.InvoiceItem	II with(nolock) 
		  INNER JOIN Products.dbo.Product		PP with(nolock)
		  ON		II.Productcode		 = PP.Code
		  AND       II.PriceVersion		 = PP.PriceVersion
		  AND       II.InvoiceIDSeq		 = @IPVC_InvoiceID
		  AND		II.InvoiceGroupIDSeq     = @InvGrpID
		  WHERE		II.InvoiceIDSeq		 = @IPVC_InvoiceID					
		  AND		II.InvoiceGroupIDSeq     = @InvGrpID
		  AND       II.MeasureCode <> 'TRAN'
		  GROUP BY    II.InvoiceIDSeq,II.ReportingTypeCode,II.FrequencyCode,II.MeasureCode,
                  (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') then II.EffectiveQuantity
                        else  II.UnitOfMeasure
                   end) ,II.BillingPeriodFromDate,II.BillingPeriodToDate
		  ORDER BY    FEETYPE ASC, PRODUCT ASC --SRS 01/30/2010
                              ,II.BillingPeriodFromDate,II.BillingPeriodToDate --SRS 04/03/2010
		END
		ELSE
		BEGIN
			INSERT INTO @TEMP_BillingRecords (OrderItemSeq,InvoiceSeq,RecType,FeeType,Product,Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTAXAmt,PSTTAXAmt,
                                                          ExtAmt,PricingTiers,FamilyCode,BillingPeriodFromDate,BillingPeriodToDate)
				SELECT DISTINCT
					II.OrderItemIDSeq 	AS [ORDERITEMSEQ],
					II.InvoiceIDSeq		AS [INVOICESEQ],
					'B'					AS [RECTYPE],
					SUBSTRING(II.ReportingTypeCode,1,3) AS [FEETYPE],
					PP.DisplayName		AS [PRODUCT],
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
							END +
							(CASE WHEN II.MeasureCode in ('SITE','UNIT','BED','PMC') then ' Pricing; ' +
								CONVERT	(VARCHAR(10), CONVERT(INT,
									(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') then II.EffectiveQuantity
										else  II.UnitOfMeasure
                                     end))) +
									CASE II.MeasureCode
										WHEN 'SITE' THEN ' Site'
										WHEN 'UNIT' THEN ' Unit'
										WHEN 'BED'  THEN ' Bed'
										WHEN 'PMC'  THEN ' PMC' 
										ELSE ''
									END + 
									CASE 
										WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT')then II.EffectiveQuantity else  II.UnitOfMeasure end) > 1 THEN 's;'
										ELSE '; '
									END 
                              ELSE ''
                             END)+
							(CASE WHEN (II.Frequencycode = 'OT' and II.ReportingTypeCode NOT IN ('ILFF')) THEN ' Period ' + 
									CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101)
		                          WHEN (II.ReportingTypeCode NOT IN ('ILFF')) THEN ' Period ' +
									CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101) + ' to ' + CONVERT(VARCHAR(10), II.BillingPeriodToDate, 101)
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
								END +
								' Pricing; ' +
								CONVERT	(VARCHAR(10),CONVERT(INT,(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') then II.EffectiveQuantity else  II.UnitOfMeasure end))) +
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
									WHEN (Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') then II.EffectiveQuantity else  II.UnitOfMeasure end)  > 1 THEN 's;'
										ELSE '; '
									END +
									(CASE WHEN (II.Frequencycode = 'OT' and II.ReportingTypeCode NOT IN ('ILFF')) THEN ' Period ' + 
							              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101)
                                           WHEN   (II.ReportingTypeCode NOT IN ('ILFF')) THEN ' Period ' + 
									              CONVERT(VARCHAR(10), II.BillingPeriodFromDate, 101) + ' to ' + CONVERT(VARCHAR(10), II.BillingPeriodToDate, 101)
                                           ELSE ''
                                     END)
								END			
							END	AS [DESCRIPTION],
							(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') then II.EffectiveQuantity else  II.UnitOfMeasure end)                                                                                  AS [QTY],
									CAST((II.NetChargeAmount / 
											(CASE WHEN 
												(Case 
													when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') then II.EffectiveQuantity
                                                     else  II.UnitOfMeasure
                                                end)  > 0 THEN 
													(Case when (PP.FamilyCode='LSD' and II.MeasureCode='UNIT') then II.EffectiveQuantity
                                                           else  II.UnitOfMeasure
                                                      end) 
                                              ELSE 1 
                                             END)) AS NUMERIC(18,4))     AS [ITEMAMT],
				II.NetChargeAmount			 AS [NETAMT], 
				II.ShippingAndHandlingAmount             AS [SNHAMT],
				II.TaxAmount				 AS [TAXAMT],
                                II.TaxwareGSTCountryTaxAmount            AS [GSTTaxAmt], 
                                II.TaxwarePSTStateTaxAmount              AS [PSTTaxAmt],
				II.NetChargeAmount + II.ShippingAndHandlingAmount + II.TaxAmount				AS [EXTAMT],
                II.PricingTiers              as [PricingTiers],
                PP.FamilyCode               AS FamilyCode
                ,II.BillingPeriodFromDate                as BillingPeriodFromDate
               ,II.BillingPeriodToDate                  as BillingPeriodToDate
      FROM	Invoices.dbo.InvoiceItem	II with (nolock) 
      INNER JOIN Products.dbo.Product		PP with (nolock)
      ON	II.Productcode       = PP.Code
      AND       II.PriceVersion      = PP.PriceVersion
      AND       II.InvoiceIDSeq      = @IPVC_InvoiceID 
      AND	II.InvoiceGroupIDSeq = @InvGrpID
      AND       II.MeasureCode <> 'TRAN' 
      WHERE	II.InvoiceIDSeq      = @IPVC_InvoiceID 
      AND	II.InvoiceGroupIDSeq = @InvGrpID
      ORDER BY	FEETYPE ASC, PRODUCT ASC --SRS 01/30/2010    
                ,II.BillingPeriodFromDate ASC,II.BillingPeriodToDate ASC
	END



    INSERT INTO   @TEMP_ProductRecords(RecType,FeeType,Description,SortSeq)
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
          FROM @TEMP_BillingRecords 
         ) S
    ORDER BY SortSeq ASC,Description ASC --SRS 01/30/2010




    INSERT INTO #TEMP_ListRecords (PSeq,BSeq,NSeq,RecType,FeeType,Description,SortOrder)
		SELECT PSeq,0,0,RecType,FeeType,Description,
            CASE WHEN FeeType='ILF' THEN 1
                 WHEN FeeType='ACS' THEN 2
                 WHEN FeeType='ANC' THEN 3
                 WHEN FeeType='TRX' THEN 4
                 ELSE ''
            END	as SortSeq				
    FROM @TEMP_ProductRecords
	ORDER BY PSeq ASC -- SRS 01/30/2010

    INSERT INTO #TEMP_ListRecords(PSeq,BSeq,NSeq,RecType,FeeType,Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTAXAmt,PSTTAXAmt,ExtAmt,PricingTiers,FamilyCode,SortOrder)
    SELECT  PRD.PSeq,TID.IDSeq,0,'B',TID.FeeType,TID.Description,TID.Qty,TID.ItemAmt,TID.NetAmt,TID.SnHAmt,TID.TaxAmt,TID.GSTTAXAmt,TID.PSTTAXAmt,TID.ExtAmt,TID.PricingTiers,FamilyCode,
            CASE WHEN TID.FeeType='ILF' THEN 1
                 WHEN TID.FeeType='ACS' THEN 2
                 WHEN TID.FeeType='ANC' THEN 3
                 WHEN TID.FeeType='TRX' THEN 4
                 ELSE ''
            END 
    FROM @TEMP_BillingRecords   TID 
    INNER JOIN @TEMP_ProductRecords	PRD
    ON   PRD.Description = TID.Product AND  PRD.FeeType     = TID.FeeType

    SET	 @CurrIDSeq		= (SELECT max(IDSeq) FROM @TEMP_BillingRecords)
    SET	 @MaxIDSeq		= 1

    BEGIN				
      SET       @LVC_FeeType  = ''	
      SEt       @LI_InnerOrderItemSeq = ''		
      WHILE	@CurrIDSeq >= @MaxIDSeq
      BEGIN ---> Inner Loop BEGIN
        SELECT	@PIDSeq = PRD.PSeq,@OrderItemSeq = TID.OrderItemSeq,@FeeType = TID.FeeType
        FROM	@TEMP_BillingRecords  TID 
        INNER JOIN @TEMP_ProductRecords  PRD
        ON	PRD.Description = TID.Product AND	PRD.FeeType     = TID.FeeType
        WHERE	TID.IDSeq = @CurrIDSeq
				
        SELECT	@BIDSeq = @CurrIDSeq

        IF (@IsCustomBun =1 and @LVB_SHOWCUSTOMBUNDLEPRODUCTSFLAG = 1 and @LVC_FeeType <> @FeeType )
        BEGIN
          SELECT @CurrIDSeq = max(IDSeq) FROM @TEMP_BillingRecords WHERE FeeType=@FeeType
          SELECT @BIDSeq    = @CurrIDSeq

          INSERT INTO @TEMP_NotesRecords(PSeq,BSeq,RecType,FeeType,Description)
          SELECT distinct @PIDSeq,@BIDSeq,'N', @FeeType,PRD.DisplayName				
          FROM Invoices.dbo.InvoiceItem II WITH (nolock)
          INNER JOIN Products.dbo.product PRD WITH (nolock) ON  II.ProductCode = PRD.Code AND II.PriceVersion = PRD.PriceVersion
          WHERE	 II.InvoiceIDSeq  = @IPVC_InvoiceID AND II.InvoiceGroupIDSeq = @InvGrpID AND II.ChargeTypeCode = @FeeType

          INSERT INTO	#TEMP_ListRecords(PSeq,BSeq,NSeq,RecType,FeeType,Description,SortOrder)
			  SELECT DISTINCT PSeq,BSeq,NSeq,RecType,FeeType,Description,
				CASE WHEN FeeType='ILF' THEN 1
				     WHEN FeeType='ACS' THEN 2
				     WHEN FeeType='ANC' THEN 3
				     WHEN FeeType='TRX' THEN 4
				   ELSE ''
				END
			FROM	@TEMP_NotesRecords WHERE	BSeq = @BIDSeq

          SET @LVC_FeeType = @FeeType
        END

        IF (@IsCustomBun =0) and (@LI_InnerOrderItemSeq <> @OrderItemSeq)
        BEGIN          
          INSERT INTO @TEMP_NotesRecords(PSeq,BSeq,RecType,FeeType,Description)
			  SELECT @PIDSeq,@BIDSeq,'N',@FeeType,IIN.Description
			  FROM	   Invoices.dbo.InvoiceItemNote IIN WITH (nolock)
			  WHERE	   IIN.InvoiceIDSeq   = @IPVC_InvoiceID AND IIN.OrderItemIDSeq = @OrderItemSeq AND IIN.PrintOnInvoiceFlag = 1
			  ORDER BY IIN.SortSeq ASC

          INSERT INTO #TEMP_ListRecords(PSeq,BSeq,NSeq,RecType,FeeType,Description,SortOrder)
			  SELECT PSeq,BSeq,NSeq,RecType,FeeType,Description,
                    CASE WHEN FeeType='ILF' THEN 1
                         WHEN FeeType='ACS' THEN 2
                         WHEN FeeType='ANC' THEN 3
                         WHEN FeeType='TRX' THEN 4
                         ELSE ''
                    END
          FROM	@TEMP_NotesRecords 
          WHERE	BSeq = @BIDSeq                              
        END        
        select @LI_InnerOrderItemSeq = @OrderItemSeq
        SELECT @CurrIDSeq = @CurrIDSeq - 1
      END---> Inner Loop END
    END
    Delete from  @TEMP_BillingRecords
    Delete from  @TEMP_ProductRecords	
    Delete from  @TEMP_NotesRecords
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
   from #TEMP_ListRecords  T  with (nolock)
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
          from   #TEMP_ListRecords S  with (nolock) 
          group by S.PSeq
         ) Source
  on  D.PSeq = Source.PSeq
  and D.[RECTYPE] = 'P'  

  INSERT INTO @TEMP_TranProductRecords(ProdCode,ProdName,Familycode,FeeType,SortOrder,BillingPeriodFromDate,BillingPeriodToDate,MaxTransactionItemNameLength)
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

   SET @LV_MinProdCnt = 1
   SET @LV_PSeq = 1
   SET @LV_BSeq = 1
   SET @LV_NSeq = 1
   SET @LV_TSeq = 1
   Select  @LV_MaxProdCnt = max(PSeq) FROM @TEMP_TranProductRecords 
    
  ------------------------------------------------------------------------------------------------
  -- "WHILE" loop to Insert the data into #Temp_FinalInvoiceTranItems table
  ------------------------------------------------------------------------------------------------
  WHILE @LV_MinProdCnt<=@LV_MaxProdCnt
  BEGIN
    Select @LVC_ProductCode = S.ProdCode,@LVC_ProductName = S.ProdName,@LVC_Familycode = S.Familycode,@LDT_BillingPeriodFromDate = S.BillingPeriodFromDate,@LDT_BillingPeriodToDate   = S.BillingPeriodToDate
    from   @TEMP_TranProductRecords S where  PSeq = @LV_MinProdCnt 

    INSERT INTO @TEMP_FinalInvoiceTranItems (Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,PricingTiers,FamilyCode,SortOrder,DisplayTransactionalProductPriceOnInvoiceFlag)
		SELECT distinct 
           @LVC_ProductName                                                         AS Description,
           SUM(II.EffectiveQuantity)                                                AS [QTY],
           convert(NUMERIC(18,6),SUM(II.NetChargeAmount))
                    /
                  (case when SUM(II.EffectiveQuantity) >0 then SUM(II.EffectiveQuantity)
                         else 1
                   end )                                                            AS [ITEMAMT],
            Convert(money,SUM(II.NetChargeAmount))			            AS NETAMT, 
            Convert(money,SUM(II.ShippingAndHandlingAmount))                        AS SNHAMT,
            Convert(money,SUM(II.TaxAmount))                                        AS TAXAMT,
            Convert(money,SUM(II.TaxwareGSTCountryTaxAmount))                       AS GSTTAXAMT,
            Convert(money,SUM(II.TaxwarePSTStateTaxAmount))                         AS PSTTAXAMT,
            Convert(money,SUM(II.NetChargeAmount)) + 
            Convert(money,SUM(II.ShippingAndHandlingAmount)) + 
            Convert(money,SUM(II.TaxAmount))                                        AS EXTAMT,            
            'P'                                          AS [RECTYPE],
            'TRX'           		                 AS [FEETYPE],
            @LV_PSeq                                     AS [PSEQ],
            @LV_BSeq                                     AS [BSEQ],
            0                                            AS [NSEQ],
            0                                            AS [TSEQ],
            1                                            AS [PRICINGTIERS],
            @LVC_Familycode                              AS [FAMILYCODE],
            4                                            AS [SORTORDER],
            MAX(convert(int,C.DisplayTransactionalProductPriceOnInvoiceFlag))      as [DisplayTransactionalProductPriceOnInvoiceFlag]
    FROM  Invoices.dbo.InvoiceItem II WITH (NOLOCK)
    INNER JOIN Products.dbo.Charge      C WITH (NOLOCK)
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
    INSERT INTO @TEMP_FinalInvoiceTranItems (Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,
                                             SortOrder,DisplayTransactionalProductPriceOnInvoiceFlag)
    SELECT Substring(
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
  if exists (select top 1 1 from @TEMP_FinalInvoiceTranItems )
  begin
    INSERT INTO @TEMP_FinalInvoiceTranItems (Description,Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,GSTTaxAmt,PSTTaxAmt,ExtAmt,RecType,FeeType,PSeq,BSeq,NSeq,TSeq,PricingTiers,FamilyCode,SortOrder)
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
     from @TEMP_FinalInvoiceTranItems T 
     where T.[FEETYPE] = 'TRX'
     and   T.[RECTYPE] = 'P'   
    --------------------------------------------------------------------------
    ---Update for TotalRecords
    Update D set D.TotalRecords = Source.TotalRecords
    from   @TEMP_FinalInvoiceTranItems D 
    inner join
           (select S.PSeq,count(1) as TotalRecords
            from   @TEMP_FinalInvoiceTranItems S  
            group by S.PSeq
           ) Source
    on  D.PSeq = Source.PSeq
    and D.[RECTYPE] = 'P'
    --------------------------------------------------------------------------
    ---Update to null out Qty,ItemAmt,NetAmt,SnHAmt,TaxAmt,ExtAmt for P  RECTYPE 
    ---  records where DisplayTransactionalProductPriceOnInvoiceFlag is set to 0
    Update @TEMP_FinalInvoiceTranItems
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
    FROM   @TEMP_FinalInvoiceTranItems 
    ORDER  by sortseq ASC
  end
  -----------------------------------------------------------------
  -- Dropping the temporary table
  -----------------------------------------------------------------
  Delete from  @TEMP_TranProductRecords
  Delete from  @TEMP_FinalInvoiceTranItems
  ----------------------------------------------------------------------------------  
  

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
   from #TEMP_ListRecords T  with (nolock)
   group by T.PageNo
  set identity_insert #TEMP_ListRecords off;

  --  Final SELECT to retrieve the data for the Invoice
  --------------------------------------------------------------------------------------
  --Update for ProductRecordCount
  Update #TEMP_ListRecords
  set    ProductRecordCount = (select count(*) 
                               from #TEMP_ListRecords T with (nolock)
                               where  T.RecType = 'P'
                               ),
         LineItemCount      = (select count(*) 
                               from #TEMP_ListRecords T with (nolock)
                               where  T.RecType <> 'Z'
                               )
  --------------------------------------------------------------------------------------
  Set @Detail = (SELECT 
		RecType as '@RecType',
		FeeType as '@FeeType',
		PSeq as '@PSeq',
		BSeq as '@BSeq',
		NSeq as '@NSeq',
		TSeq as '@TSeq',           
		PricingTiers as '@PricingTiers',
		FamilyCode as '@FamilyCode',
		SortOrder as '@SortOrder',
		PageNo as '@PageNo',       
		--'' as '@LineNumber',
		--'' as '@UnitNumber',
		IDSeq as 'SKU',
		Qty as 'Quantity',
		ItemAmt as 'UnitPrice',
		Qty as 'OrderQuantity',
		Convert(Numeric(30,2),ItemAmt)   as 'OrderPrice',
		Convert(Numeric(30,2),SnHAmt)    as 'FreightTotal',
		Convert(Numeric(30,2),TaxAmt)    as 'TaxTotal',
                Convert(Numeric(30,2),GSTTaxAmt) as 'GSTTaxAmt', 
                Convert(Numeric(30,2),PSTTaxAmt) as 'PSTTaxAmt',
		Convert(Numeric(30,2),NetAmt)    as 'NetTotal',
		Convert(Numeric(30,2),ExtAmt)    as 'LineTotal',
		'' as 'UnitofMeasure',
                Description as 'Description',
		'' as 'Manufacturer',
		'' as 'BuyerNotes',
		'0' as 'IsTaxableFlag',
		'0' as 'IsServiceFlag',
		'' as 'ServiceDate',
		'' as 'ShipmentType',
		'' as 'LedgerCode',
		'' as 'LedgerType/LedgerTypeName',
		'' as 'LedgerType/LedgerTypeDescription',
		'' as 'SupplierNotes',
		'' as 'PropertyName',
		'' as 'PropertyCode',
		'' as 'FiscalPeriod/FiscalMonth',
		'' as 'FiscalPeriod/FiscalYear',
		'' as 'ChartOfAccount',
		'' as 'ProjectCode',
		'' as 'SerialNumberList/SerialNumber/@Serial',
		'' as 'SerialNumberList/SerialNumber/WarrantyList/Warranty/@StartDate',
		'' as 'SerialNumberList/SerialNumber/WarrantyList/Warranty/@EndDateDate',
		'' as 'SerialNumberList/SerialNumber/WarrantyList/Warranty/@LifeTimeFlag',
		'' as 'SerialNumberList/SerialNumber/WarrantyList/Warranty/WarrantyName',
                coalesce(ProductRecordCount,0) as ProductRecordCount,
                coalesce(LineItemCount,0)      as LineItemCount
  FROM #TEMP_ListRecords with (nolock) 
  ORDER BY PageNo ASC,SortOrder ASC,PSeq ASC,BSeq ASC,NSeq ASC
  For XML Path  ('LineItem'))
END TRY
BEGIN CATCH
        Set @ErrorMessage = 'GetInvoiceDetailAsXML '+ ERROR_MESSAGE();
        Set @ErrorSeverity = ERROR_SEVERITY();
        Set @ErrorState = ERROR_STATE();
		RAISERROR (@ErrorMessage,@ErrorSeverity,@ErrorState);
	    return;
end CATCH; 
END
GO
