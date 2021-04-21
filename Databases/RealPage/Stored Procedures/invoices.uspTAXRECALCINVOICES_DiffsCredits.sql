SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- procedure  : dbo.uspTAXRECALCINVOICES_DiffsCredits
-- purpose    : present differences in Invoice Items resulting from tax recalc
-- parameters : (none)
-- returns    : None.
-- remarks:
	For Credit Memo Items, only perceive differences when the actual tax amounts or percents have changed. 
	Based on consultation with Sriram, I have removed a large number of comparison columns, on the remainder
	of the 32 Taxware result fields.  For example, the SalesUseTaxIndicator fields are intermittently NULL or
	they are present, in the INVOICES database.  After TaxRecalc, those flags are always present.  That for 
	example was determined to be a matter of no importance, which should not be called out as any kind of 
	difference, for this purpose. 
	After due consideration, we decided that all of those Taxware result columns should be ignored here, 
	except for tax data itself. 
--
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-09-23   Larry Wilson             initial implementation  (PCR-6250)
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
*/
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_DiffsCredits]
AS
BEGIN
	SELECT  h.CreditTypeCode,d.creditmemoidseq,d.idseq [CreditMemoItemIDSeq]
		,d.netcreditamount,d.shippingandhandlingCreditamount
		,d.taxwarecode,ii.taxwarecode [II Taxware Code]
		,ii.taxableaddressline1,ii.taxablecity,ii.taxablestate,ii.taxablezip
		,d.TaxPercent,d.RECALCTaxPercent
		,d.TaxAmount,d.RECALCTaxAmount
	-- SELECT COUNT(1)
	FROM [dbo].[CreditMemoItem] d WITH (NOLOCK)
	INNER JOIN [dbo].[CreditMemo] h WITH (NOLOCK) ON h.[CreditMemoIDSeq]=d.[CreditMemoIDSeq]
	INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=d.[InvoiceItemIDSeq]
										AND ii.[InvoiceGroupIDSeq]=d.[InvoiceGroupIDSeq]
										AND ii.[InvoiceIDSeq]=d.[InvoiceIDSeq]
	WHERE d.[RECALCComplete]=1		-- only pay attention to rows that were updated by Tax Recalc
	AND ISNULL(ii.[netchargeamount],0) + ISNULL(ii.[shippingandhandlingamount],0) <> 0
	AND NOT
	(   ISNULL(d.TaxPercent,0)=ISNULL(d.RECALCTaxPercent,0) AND
		ISNULL(d.TaxAmount,0)=ISNULL(d.RECALCTaxAmount,0)
	)
	RETURN(0)
END
GO
