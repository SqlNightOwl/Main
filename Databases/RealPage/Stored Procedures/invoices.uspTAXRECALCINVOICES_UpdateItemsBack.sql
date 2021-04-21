SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- Database  Name  : INVOICES
-- Procedure Name  : uspTAXRECALCINVOICES_UpdateItemsBack
-- Description     : Push all updated tax info back to regular data columns
-- Remarks: 
	Here the updated information from the RECALC columns, is pushed back into the regular columns.
	Data is only pushed back for rows where new values have been posted during this session. 
	Data is pushed back within the InvoiceItem table, and also in the CreditMemoItem table. 

	This update was originally a sql file in the prjTaxReCalc\Queries folder, for use with the TaxRecalc app. 
	It was placed into this stored proc, and modified, under PCR 6250. 

-- Revision History:
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-11-13   Larry Wilson          eliminate separate database, now using alternate columns in normal tables (PCR 6151)
-- 2009-09-21   Larry Wilson          initial implementation
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
*/
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_UpdateItemsBack]
AS
BEGIN
	UPDATE [dbo].[InvoiceItem]
		SET [TaxPercent]=[RECALCTaxPercent]
			,[TaxAmount]=[RECALCTaxAmount]
			,[TaxwarePrimaryStateTaxPercent]=[RECALCTaxwarePrimaryStateTaxPercent]
			,[TaxwarePrimaryStateTaxAmount]=[RECALCTaxwarePrimaryStateTaxAmount]
			,[TaxwareSecondaryStateTaxPercent]=[RECALCTaxwareSecondaryStateTaxPercent]
			,[TaxwareSecondaryStateTaxAmount]=[RECALCTaxwareSecondaryStateTaxAmount]
			,[TaxwarePrimaryCityTaxPercent]=[RECALCTaxwarePrimaryCityTaxPercent]
			,[TaxwarePrimaryCityTaxAmount]=[RECALCTaxwarePrimaryCityTaxAmount]
			,[TaxwareSecondaryCityTaxPercent]=[RECALCTaxwareSecondaryCityTaxPercent]
			,[TaxwareSecondaryCityTaxAmount]=[RECALCTaxwareSecondaryCityTaxAmount]
			,[TaxwarePrimaryCountyTaxPercent]=[RECALCTaxwarePrimaryCountyTaxPercent]
			,[TaxwarePrimaryCountyTaxAmount]=[RECALCTaxwarePrimaryCountyTaxAmount]
			,[TaxwareSecondaryCountyTaxPercent]=[RECALCTaxwareSecondaryCountyTaxPercent]
			,[TaxwareSecondaryCountyTaxAmount]=[RECALCTaxwareSecondaryCountyTaxAmount]
			,[TaxwarePrimaryStateTaxBasisAmount]=[RECALCTaxwarePrimaryStateTaxBasisAmount]
			,[TaxwareSecondaryStateTaxBasisAmount]=[RECALCTaxwareSecondaryStateTaxBasisAmount]
			,[TaxwarePrimaryCityTaxBasisAmount]=[RECALCTaxwarePrimaryCityTaxBasisAmount]
			,[TaxwareSecondaryCityTaxBasisAmount]=[RECALCTaxwareSecondaryCityTaxBasisAmount]
			,[TaxwarePrimaryCountyTaxBasisAmount]=[RECALCTaxwarePrimaryCountyTaxBasisAmount]
			,[TaxwareSecondaryCountyTaxBasisAmount]=[RECALCTaxwareSecondaryCountyTaxBasisAmount]
			,[TaxwarePrimaryStateJurisdictionZipCode]=[RECALCTaxwarePrimaryStateJurisdictionZipCode]
			,[TaxwareSecondaryStateJurisdictionZipCode]=[RECALCTaxwareSecondaryStateJurisdictionZipCode]
			,[TaxwarePrimaryCityJurisdiction]=[RECALCTaxwarePrimaryCityJurisdiction]
			,[TaxwareSecondaryCityJurisdiction]=[RECALCTaxwareSecondaryCityJurisdiction]
			,[TaxwarePrimaryCountyJurisdiction]=[RECALCTaxwarePrimaryCountyJurisdiction]
			,[TaxwareSecondaryCountyJurisdiction]=[RECALCTaxwareSecondaryCountyJurisdiction]
			,[TaxwareCallOverrideFlag]=[RECALCTaxwareCallOverrideFlag]
			,[TaxwarePrimaryStateSalesUseTaxIndicator]=[RECALCTaxwarePrimaryStateSalesUseTaxIndicator]
			,[TaxwarePrimaryCountySalesUseTaxIndicator]=[RECALCTaxwarePrimaryCountySalesUseTaxIndicator]
			,[TaxwarePrimaryCitySalesUseTaxIndicator]=[RECALCTaxwarePrimaryCitySalesUseTaxIndicator]
			,[TaxwareSecondaryStateSalesUseTaxIndicator]=[RECALCTaxwareSecondaryStateSalesUseTaxIndicator]
			,[TaxwareSecondaryCountySalesUseTaxIndicator]=[RECALCTaxwareSecondaryCountySalesUseTaxIndicator]
			,[TaxwareSecondaryCitySalesUseTaxIndicator]=[RECALCTaxwareSecondaryCitySalesUseTaxIndicator]
                        ,[TaxwareGSTCountryTaxAmount]              = [RECALCTaxwareGSTCountryTaxAmount]
                        ,[TaxwareGSTCountryTaxPercent]             = [RECALCTaxwareGSTCountryTaxPercent]
                        ,[TaxwarePSTStateTaxAmount]                = [RECALCTaxwarePSTStateTaxAmount]
                        ,[TaxwarePSTStateTaxPercent]               = [RECALCTaxwarePSTStateTaxPercent]
		WHERE [RECALCComplete]=1	-- ONLY for those rows that were updated
	/*
		And then, the same treatment for CreditMemoItem rows that have been updated
	*/
	UPDATE [dbo].[CreditMemoItem]
		SET [TaxPercent]=[RECALCTaxPercent]
			,[TaxAmount]=[RECALCTaxAmount]
			,[TaxwarePrimaryStateTaxPercent]=[RECALCTaxwarePrimaryStateTaxPercent]
			,[TaxwarePrimaryStateTaxAmount]=[RECALCTaxwarePrimaryStateTaxAmount]
			,[TaxwareSecondaryStateTaxPercent]=[RECALCTaxwareSecondaryStateTaxPercent]
			,[TaxwareSecondaryStateTaxAmount]=[RECALCTaxwareSecondaryStateTaxAmount]
			,[TaxwarePrimaryCityTaxPercent]=[RECALCTaxwarePrimaryCityTaxPercent]
			,[TaxwarePrimaryCityTaxAmount]=[RECALCTaxwarePrimaryCityTaxAmount]
			,[TaxwareSecondaryCityTaxPercent]=[RECALCTaxwareSecondaryCityTaxPercent]
			,[TaxwareSecondaryCityTaxAmount]=[RECALCTaxwareSecondaryCityTaxAmount]
			,[TaxwarePrimaryCountyTaxPercent]=[RECALCTaxwarePrimaryCountyTaxPercent]
			,[TaxwarePrimaryCountyTaxAmount]=[RECALCTaxwarePrimaryCountyTaxAmount]
			,[TaxwareSecondaryCountyTaxPercent]=[RECALCTaxwareSecondaryCountyTaxPercent]
			,[TaxwareSecondaryCountyTaxAmount]=[RECALCTaxwareSecondaryCountyTaxAmount]
			,[TaxwarePrimaryStateTaxBasisAmount]=[RECALCTaxwarePrimaryStateTaxBasisAmount]
			,[TaxwareSecondaryStateTaxBasisAmount]=[RECALCTaxwareSecondaryStateTaxBasisAmount]
			,[TaxwarePrimaryCityTaxBasisAmount]=[RECALCTaxwarePrimaryCityTaxBasisAmount]
			,[TaxwareSecondaryCityTaxBasisAmount]=[RECALCTaxwareSecondaryCityTaxBasisAmount]
			,[TaxwarePrimaryCountyTaxBasisAmount]=[RECALCTaxwarePrimaryCountyTaxBasisAmount]
			,[TaxwareSecondaryCountyTaxBasisAmount]=[RECALCTaxwareSecondaryCountyTaxBasisAmount]
			,[TaxwarePrimaryStateJurisdictionZipCode]=[RECALCTaxwarePrimaryStateJurisdictionZipCode]
			,[TaxwareSecondaryStateJurisdictionZipCode]=[RECALCTaxwareSecondaryStateJurisdictionZipCode]
			,[TaxwarePrimaryCityJurisdiction]=[RECALCTaxwarePrimaryCityJurisdiction]
			,[TaxwareSecondaryCityJurisdiction]=[RECALCTaxwareSecondaryCityJurisdiction]
			,[TaxwarePrimaryCountyJurisdiction]=[RECALCTaxwarePrimaryCountyJurisdiction]
			,[TaxwareSecondaryCountyJurisdiction]=[RECALCTaxwareSecondaryCountyJurisdiction]
			,[TaxwareCallOverrideFlag]=[RECALCTaxwareCallOverrideFlag]
			,[TaxwarePrimaryStateSalesUseTaxIndicator]=[RECALCTaxwarePrimaryStateSalesUseTaxIndicator]
			,[TaxwarePrimaryCountySalesUseTaxIndicator]=[RECALCTaxwarePrimaryCountySalesUseTaxIndicator]
			,[TaxwarePrimaryCitySalesUseTaxIndicator]=[RECALCTaxwarePrimaryCitySalesUseTaxIndicator]
			,[TaxwareSecondaryStateSalesUseTaxIndicator]=[RECALCTaxwareSecondaryStateSalesUseTaxIndicator]
			,[TaxwareSecondaryCountySalesUseTaxIndicator]=[RECALCTaxwareSecondaryCountySalesUseTaxIndicator]
			,[TaxwareSecondaryCitySalesUseTaxIndicator]=[RECALCTaxwareSecondaryCitySalesUseTaxIndicator]
                        ,[TaxwareGSTCountryTaxAmount]              = [RECALCTaxwareGSTCountryTaxAmount]
                        ,[TaxwareGSTCountryTaxPercent]             = [RECALCTaxwareGSTCountryTaxPercent]
                        ,[TaxwarePSTStateTaxAmount]                = [RECALCTaxwarePSTStateTaxAmount]
                        ,[TaxwarePSTStateTaxPercent]               = [RECALCTaxwarePSTStateTaxPercent]       
		WHERE [RECALCComplete]=1	-- ONLY for those rows that were updated

	SELECT '1' AS confirmAction,
		'Tax data has been pushed back to INVOICES' AS responseMsg
	RETURN(0)
END
GO
