SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- Database  Name  : INVOICES
-- Procedure Name  : uspTAXRECALCINVOICES_PrequalifySingleItem
-- Description     : Pre-set Tax Recalc control bits on one single Invoice, and its Credit Memo items
-- Remarks:  Adds on especific invoice to the TODO list, for today's run of tax recalc. 

-- Revision History:
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2010-11-15   Larry Wilson          initial implementation
--
-- Copyright  : copyright (c) 2010.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
*/
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_PrequalifySingleItem]
(
		@InvoiceIDSeq varchar(22)
)
AS
BEGIN
	-- 1) for InvoiceItem table, flag at most this one single invoice's item(s)
	UPDATE ii SET [RECALCNeeded]=1
		FROM [dbo].[InvoiceItem] ii WITH (NOLOCK)
		INNER JOIN [dbo].[Invoice] i WITH (NOLOCK) ON i.[InvoiceIDSeq]=ii.[InvoiceIDSeq]
		INNER JOIN [PRODUCTS].[dbo].[Charge] c WITH (NOLOCK) ON ii.[ProductCode]=c.[ProductCode]
			AND  ii.[PriceVersion]=c.[PriceVersion]
			AND  ii.[ChargeTypeCode]=c.[ChargeTypeCode]
			AND  ii.[FrequencyCode]=c.[FrequencyCode]
			AND  ii.[MeasureCode]=c.[MeasureCode]
			AND  c.[TaxwareCode] IS NOT NULL
		INNER JOIN [PRODUCTS].[dbo].[Product] p WITH (NOLOCK) ON ii.[ProductCode]=p.[Code]
			AND   ii.[PriceVersion] = p.[PriceVersion]     
		WHERE ii.[InvoiceIDSeq] = @InvoiceIDSeq

	-- 2) for CreditMemoItem table, same deal...
	UPDATE ci SET [RECALCNeeded]=1
		FROM [dbo].[CreditMemoItem] ci
		INNER JOIN [dbo].[CreditMemo] cm WITH (NOLOCK) on cm.[CreditMemoIDSeq]=ci.[CreditMemoIDSeq]
		INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=ci.[InvoiceItemIDSeq]
		INNER JOIN [dbo].[Invoice] i WITH (NOLOCK) ON i.[InvoiceIDSeq]=ii.[InvoiceIDSeq]
		INNER JOIN [PRODUCTS].[dbo].[Charge] c WITH (NOLOCK) ON ii.[ProductCode]=c.[ProductCode]
			AND  ii.[PriceVersion]=c.[PriceVersion]
			AND  ii.[ChargeTypeCode]=c.[ChargeTypeCode]
			AND  ii.[FrequencyCode]=c.[FrequencyCode]
			AND  ii.[MeasureCode]=c.[MeasureCode]
			AND  c.[TaxwareCode] IS NOT NULL
		INNER JOIN [PRODUCTS].[dbo].[Product] p WITH (NOLOCK) ON ii.[ProductCode]=p.[Code]
			AND   ii.[PriceVersion] = p.[PriceVersion]     
		WHERE ii.[InvoiceIDSeq] = @InvoiceIDSeq
		 AND cm.[CreditStatusCode]='APPR'

	SELECT '1' AS confirmAction,
		'One invoice worth of items have been scheduled for TaxRecalc' AS responseMsg
	RETURN(0)
END
GO
