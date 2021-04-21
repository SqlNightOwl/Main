SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------
-- procedure  : uspTAXRECALCINVOICES_SelectSingleItem
-- purpose    : acquire all tax data from one single Invoice Item
-- parameters : identify one Invoice Item
-- returns    : all Taxware result fields from specified item in database,
--				and NOT from taxware at all, at least not today...
--
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-09-22   Larry Wilson        initial implementation
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
-----------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_SelectSingleItem] (
	@IPVC_InvoiceItemID bigint
)
AS
BEGIN
	SELECT [IDSeq]
		  ,[TaxAmount]
		  ,[TaxPercent]
		  ,[TaxwarePrimaryStateTaxPercent]
		  ,[TaxwarePrimaryStateTaxAmount]
		  ,[TaxwareSecondaryStateTaxPercent]
		  ,[TaxwareSecondaryStateTaxAmount]
		  ,[TaxwarePrimaryCityTaxPercent]
		  ,[TaxwarePrimaryCityTaxAmount]
		  ,[TaxwareSecondaryCityTaxPercent]
		  ,[TaxwareSecondaryCityTaxAmount]
		  ,[TaxwarePrimaryCountyTaxPercent]
		  ,[TaxwarePrimaryCountyTaxAmount]
		  ,[TaxwareSecondaryCountyTaxPercent]
		  ,[TaxwareSecondaryCountyTaxAmount]
		  ,[TaxwarePrimaryStateTaxBasisAmount]
		  ,[TaxwareSecondaryStateTaxBasisAmount]
		  ,[TaxwarePrimaryCityTaxBasisAmount]
		  ,[TaxwareSecondaryCityTaxBasisAmount]
		  ,[TaxwarePrimaryCountyTaxBasisAmount]
		  ,[TaxwareSecondaryCountyTaxBasisAmount]
		  ,[TaxwarePrimaryStateJurisdictionZipCode]
		  ,[TaxwareSecondaryStateJurisdictionZipCode]
		  ,[TaxwarePrimaryCityJurisdiction]
		  ,[TaxwareSecondaryCityJurisdiction]
		  ,[TaxwarePrimaryCountyJurisdiction]
		  ,[TaxwareSecondaryCountyJurisdiction]
		  ,[TaxwareCallOverrideFlag]
		  ,[TaxwarePrimaryStateSalesUseTaxIndicator]
		  ,[TaxwarePrimaryCountySalesUseTaxIndicator]
		  ,[TaxwarePrimaryCitySalesUseTaxIndicator]
		  ,[TaxwareSecondaryStateSalesUseTaxIndicator]
		  ,[TaxwareSecondaryCountySalesUseTaxIndicator]
		  ,[TaxwareSecondaryCitySalesUseTaxIndicator]
	  FROM [dbo].[InvoiceItem] WITH (NOLOCK)
	WHERE [IDSeq]=@IPVC_InvoiceItemID
END
GO
