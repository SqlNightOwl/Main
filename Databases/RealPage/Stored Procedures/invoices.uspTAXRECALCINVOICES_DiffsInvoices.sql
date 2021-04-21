SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------
-- procedure  : dbo.uspTAXRECALCINVOICES_DiffsInvoices
-- purpose    : present differences in Invoice Items resulting from tax recalc
-- parameters : (none)
-- returns    : None.
--
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-09-21   Larry Wilson             initial implementation  (PCR-6250)
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
-----------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_DiffsInvoices]
AS
BEGIN
	SELECT  i.InvoiceIDSeq,i.accountidseq, d.netchargeamount,d.shippingandhandlingamount
		,d.productcode,d.priceversion, d.taxwarecode [II Taxware Code],d.taxwarecode [Recalc TaxWare Code]
		,d.taxableaddressline1,d.taxablecity,d.taxablestate,d.taxablezip
		,d.TaxPercent,d.RECALCTaxPercent
		,d.TaxAmount,d.RECALCTaxAmount
		,d.TaxwarePrimaryStateTaxPercent,d.RECALCTaxwarePrimaryStateTaxPercent
		,d.TaxwarePrimaryStateTaxAmount,d.RECALCTaxwarePrimaryStateTaxAmount
		,d.TaxwareSecondaryStateTaxPercent,d.RECALCTaxwareSecondaryStateTaxPercent
		,d.TaxwareSecondaryStateTaxAmount,d.RECALCTaxwareSecondaryStateTaxAmount
		,d.TaxwarePrimaryCityTaxPercent,d.RECALCTaxwarePrimaryCityTaxPercent
		,d.TaxwarePrimaryCityTaxAmount,d.RECALCTaxwarePrimaryCityTaxAmount
		,d.TaxwareSecondaryCityTaxPercent,d.RECALCTaxwareSecondaryCityTaxPercent
		,d.TaxwareSecondaryCityTaxAmount,d.RECALCTaxwareSecondaryCityTaxAmount
		,d.TaxwarePrimaryCountyTaxPercent,d.RECALCTaxwarePrimaryCountyTaxPercent
		,d.TaxwarePrimaryCountyTaxAmount,d.RECALCTaxwarePrimaryCountyTaxAmount
		,d.TaxwareSecondaryCountyTaxPercent,d.RECALCTaxwareSecondaryCountyTaxPercent
		,d.TaxwareSecondaryCountyTaxAmount,d.RECALCTaxwareSecondaryCountyTaxAmount
		,isnull(d.[TaxwareGSTCountryTaxAmount],0) as [TaxwareGSTCountryTaxAmount]
		,isnull(d.[RECALCTaxwareGSTCountryTaxAmount],0) as [RECALCTaxwareGSTCountryTaxAmount]
		,isnull(d.[TaxwareGSTCountryTaxPercent],0) as [TaxwareGSTCountryTaxPercent]
		,isnull(d.[RECALCTaxwareGSTCountryTaxPercent],0) as [RECALCTaxwareGSTCountryTaxPercent]
		,isnull(d.[TaxwarePSTStateTaxAmount],0) as [TaxwarePSTStateTaxAmount]
		,isnull(d.[RECALCTaxwarePSTStateTaxAmount],0) as [RECALCTaxwarePSTStateTaxAmount]
		,isnull(d.[TaxwarePSTStateTaxPercent],0) as [TaxwarePSTStateTaxPercent]
		,isnull(d.[RECALCTaxwarePSTStateTaxPercent],0) as [RECALCTaxwarePSTStateTaxPercent]
		,d.TaxwarePrimaryStateTaxBasisAmount,d.RECALCTaxwarePrimaryStateTaxBasisAmount
		,d.TaxwareSecondaryStateTaxBasisAmount,d.RECALCTaxwareSecondaryStateTaxBasisAmount
		,d.TaxwarePrimaryCityTaxBasisAmount,d.RECALCTaxwarePrimaryCityTaxBasisAmount
		,d.TaxwareSecondaryCityTaxBasisAmount,d.RECALCTaxwareSecondaryCityTaxBasisAmount
		,d.TaxwarePrimaryCountyTaxBasisAmount,d.RECALCTaxwarePrimaryCountyTaxBasisAmount
		,d.TaxwareSecondaryCountyTaxBasisAmount,d.RECALCTaxwareSecondaryCountyTaxBasisAmount
		,d.TaxwarePrimaryStateJurisdictionZipCode,d.RECALCTaxwarePrimaryStateJurisdictionZipCode
		,d.TaxwareSecondaryStateJurisdictionZipCode,d.RECALCTaxwareSecondaryStateJurisdictionZipCode
		,d.TaxwarePrimaryCityJurisdiction,d.RECALCTaxwarePrimaryCityJurisdiction
		,d.TaxwareSecondaryCityJurisdiction,d.RECALCTaxwareSecondaryCityJurisdiction
		,d.TaxwarePrimaryCountyJurisdiction,d.RECALCTaxwarePrimaryCountyJurisdiction
		,d.TaxwareSecondaryCountyJurisdiction,d.RECALCTaxwareSecondaryCountyJurisdiction
		,d.TaxwareCallOverrideFlag,d.RECALCTaxwareCallOverrideFlag
		,d.TaxwarePrimaryStateSalesUseTaxIndicator,d.[RECALCTaxwarePrimaryStateSalesUseTaxIndicator]
		,d.TaxwarePrimaryCountySalesUseTaxIndicator,d.[RECALCTaxwarePrimaryCountySalesUseTaxIndicator]
		,d.TaxwarePrimaryCitySalesUseTaxIndicator,d.[RECALCTaxwarePrimaryCitySalesUseTaxIndicator]
		,d.TaxwareSecondaryStateSalesUseTaxIndicator,d.[RECALCTaxwareSecondaryStateSalesUseTaxIndicator]
		,d.TaxwareSecondaryCountySalesUseTaxIndicator,d.[RECALCTaxwareSecondaryCountySalesUseTaxIndicator]
		,d.TaxwareSecondaryCitySalesUseTaxIndicator,d.[RECALCTaxwareSecondaryCitySalesUseTaxIndicator]


	-- SELECT COUNT(1)
	FROM [dbo].[InvoiceItem] d 
	INNER JOIN [dbo].[Invoice] i ON d.[InvoiceIDSeq]=i.[InvoiceIDSeq]
	WHERE ISNULL(d.[netchargeamount],0) + ISNULL(d.[shippingandhandlingamount],0) <> 0
	AND d.[RECALCComplete]=1		-- only pay attention to rows that were updated by Tax Recalc
	AND NOT
	(   ISNULL(d.TaxPercent,0)=ISNULL(d.RECALCTaxPercent,0) AND
		ISNULL(d.TaxAmount,0)=ISNULL(d.RECALCTaxAmount,0) AND
		ISNULL(d.TaxwarePrimaryStateTaxPercent,0)=ISNULL(d.RECALCTaxwarePrimaryStateTaxPercent,0) AND
		ISNULL(d.TaxwarePrimaryStateTaxAmount,0)=ISNULL(d.RECALCTaxwarePrimaryStateTaxAmount,0) AND
		d.TaxwareSecondaryStateTaxPercent=d.RECALCTaxwareSecondaryStateTaxPercent AND
		d.TaxwareSecondaryStateTaxAmount=d.RECALCTaxwareSecondaryStateTaxAmount  AND
		d.TaxwarePrimaryCityTaxPercent=d.RECALCTaxwarePrimaryCityTaxPercent AND
		d.TaxwarePrimaryCityTaxAmount=d.RECALCTaxwarePrimaryCityTaxAmount AND
		d.TaxwareSecondaryCityTaxPercent=d.RECALCTaxwareSecondaryCityTaxPercent AND
		d.TaxwareSecondaryCityTaxAmount=d.RECALCTaxwareSecondaryCityTaxAmount AND
		d.TaxwarePrimaryCountyTaxPercent=d.RECALCTaxwarePrimaryCountyTaxPercent AND
		d.TaxwarePrimaryCountyTaxAmount=d.RECALCTaxwarePrimaryCountyTaxAmount AND
		d.TaxwareSecondaryCountyTaxPercent=d.RECALCTaxwareSecondaryCountyTaxPercent AND
		d.TaxwareSecondaryCountyTaxAmount=d.RECALCTaxwareSecondaryCountyTaxAmount AND
		d.TaxwarePrimaryStateTaxBasisAmount=d.RECALCTaxwarePrimaryStateTaxBasisAmount AND
		d.TaxwareSecondaryStateTaxBasisAmount=d.RECALCTaxwareSecondaryStateTaxBasisAmount AND
		d.TaxwarePrimaryCityTaxBasisAmount=d.RECALCTaxwarePrimaryCityTaxBasisAmount AND
		d.TaxwareSecondaryCityTaxBasisAmount=d.RECALCTaxwareSecondaryCityTaxBasisAmount AND
		d.TaxwarePrimaryCountyTaxBasisAmount=d.RECALCTaxwarePrimaryCountyTaxBasisAmount AND
		d.TaxwareSecondaryCountyTaxBasisAmount=d.RECALCTaxwareSecondaryCountyTaxBasisAmount AND
		ISNULL(d.TaxwarePrimaryStateJurisdictionZipCode,'')=ISNULL(d.RECALCTaxwarePrimaryStateJurisdictionZipCode,'') AND
		ISNULL(d.TaxwareSecondaryStateJurisdictionZipCode,'')=ISNULL(d.RECALCTaxwareSecondaryStateJurisdictionZipCode,'') AND
		ISNULL(d.TaxwarePrimaryCityJurisdiction,'')=ISNULL(d.RECALCTaxwarePrimaryCityJurisdiction,'') AND
		ISNULL(d.TaxwareSecondaryCityJurisdiction,'')=ISNULL(d.RECALCTaxwareSecondaryCityJurisdiction,'') AND
		ISNULL(d.TaxwarePrimaryCountyJurisdiction,'')=ISNULL(d.RECALCTaxwarePrimaryCountyJurisdiction,'') AND
		ISNULL(d.TaxwareSecondaryCountyJurisdiction,'')=ISNULL(d.RECALCTaxwareSecondaryCountyJurisdiction,'') AND
		ISNULL(d.TaxwareCallOverrideFlag,'')=ISNULL(d.RECALCTaxwareCallOverrideFlag,'') AND
		ISNULL(d.TaxwarePrimaryStateSalesUseTaxIndicator,'')=ISNULL(d.[RECALCTaxwarePrimaryStateSalesUseTaxIndicator],'') AND
   		ISNULL(d.TaxwarePrimaryCountySalesUseTaxIndicator,'')=ISNULL(d.[RECALCTaxwarePrimaryCountySalesUseTaxIndicator],'') AND
		ISNULL(d.TaxwarePrimaryCitySalesUseTaxIndicator,'')=ISNULL(d.[RECALCTaxwarePrimaryCitySalesUseTaxIndicator],'') AND
		ISNULL(d.TaxwareSecondaryStateSalesUseTaxIndicator,'')=ISNULL(d.[RECALCTaxwareSecondaryStateSalesUseTaxIndicator],'') AND
		ISNULL(d.TaxwareSecondaryCountySalesUseTaxIndicator,'')=ISNULL(d.[RECALCTaxwareSecondaryCountySalesUseTaxIndicator],'') AND
		ISNULL(d.TaxwareSecondaryCitySalesUseTaxIndicator,'')=ISNULL(d.[RECALCTaxwareSecondaryCitySalesUseTaxIndicator],'') AND
		isnull(d.TaxwareGSTCountryTaxAmount,'0') = isnull(d.RECALCTaxwareGSTCountryTaxAmount,'0') and 
		isnull(d.[TaxwareGSTCountryTaxPercent],'0') = Isnull(d.RECALCTaxwareGSTCountryTaxPercent,'0') and 
		isnull(d.TaxwarePSTStateTaxAmount,'0') = isnull(d.RECALCTaxwarePSTStateTaxAmount,'0') and 
		isnull(d.TaxwarePSTStateTaxPercent,'0') = isnull(d.RECALCTaxwarePSTStateTaxPercent,'0')  
	)
	RETURN(0)
END
GO
