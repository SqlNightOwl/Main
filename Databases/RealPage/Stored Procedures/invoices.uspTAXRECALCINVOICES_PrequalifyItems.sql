SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- Database  Name  : INVOICES
-- Procedure Name  : uspTAXRECALCINVOICES_PrequalifyItems
-- Description     : Pre-set the control bits on Invoices and Credit Memo items, to schedule Tax Recalc
-- Remarks:  MAKES a sort of TODO list, for today's run of tax recalc. 
	This update was originally a chunk of ad hoc sql, in the procedural instructions for TaxRecalc app. 
	It was placed into this stored proc, and modified, under PCR 6250. 
	In this version, all invoice and credit memo items that have not yet been 
	EITHER "Printed" OR "sent to Epicor" -- are scheduled for recalculation. 

	In future, it may be necessary to specify some other criterion for determinating which items are 
	to be recalculated.  But for now, this is it. 

-- Revision History:
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-09-21   Larry Wilson          initial implementation
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
*/
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_PrequalifyItems]
AS
BEGIN
/*
	NOTE how, in both cases we omit from our TODO list all items for which matching Product 
	and Charge info is not present in the PRODUCTS database...
	Such items would never get selected for recalculation anyway, because indeed they cannot be. 
	Therefore do not even set them up for recalculation initially. 
*/
	-- 1) for InvoiceItem table, ensure all OPEN items are set up to process, and all others are NOT
	UPDATE [dbo].[InvoiceItem] SET [RECALCNeeded]=0,[RECALCComplete] = 0  -- preset entire table
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
		WHERE ISNULL(i.[SentToEpicorStatus],'') NOT LIKE 'COMP%'
			AND i.[PrintFlag]=0

	-- 2) for CreditMemoItem table, same deal...
	UPDATE [dbo].[CreditMemoItem] SET [RECALCNeeded]=0,[RECALCComplete] = 0
	UPDATE ci SET [RECALCNeeded]=1
		FROM [dbo].[CreditMemoItem] ci
		INNER JOIN [dbo].[CreditMemo] cm WITH (NOLOCK) on cm.[CreditMemoIDSeq]=ci.[CreditMemoIDSeq]
		INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=ci.[InvoiceItemIDSeq]
		INNER JOIN [PRODUCTS].[dbo].[Charge] c WITH (NOLOCK) ON ii.[ProductCode]=c.[ProductCode]
			AND  ii.[PriceVersion]=c.[PriceVersion]
			AND  ii.[ChargeTypeCode]=c.[ChargeTypeCode]
			AND  ii.[FrequencyCode]=c.[FrequencyCode]
			AND  ii.[MeasureCode]=c.[MeasureCode]
			AND  c.[TaxwareCode] IS NOT NULL
		INNER JOIN [PRODUCTS].[dbo].[Product] p WITH (NOLOCK) ON ii.[ProductCode]=p.[Code]
			AND   ii.[PriceVersion] = p.[PriceVersion]     
		WHERE ISNULL(cm.[SentToEpicorStatus],'') NOT LIKE 'COMP%'
		 AND cm.[PrintFlag]=0
		 AND cm.[CreditStatusCode]='APPR'

	SELECT '1' AS confirmAction,
		'Items scheduled for TaxRecalc' AS responseMsg
	RETURN(0)
END
GO
