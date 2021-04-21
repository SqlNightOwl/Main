SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- Database  Name  : INVOICES
-- Procedure Name  : uspTAXRECALCINVOICES_GetCounts
-- Description     : obtain counts of invoice and credit items in need of tax recalculation
-- Remarks: 

-- Revision History:
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-11-30   Larry Wilson          initial implementation
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
*/
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_GetCounts]
AS
BEGIN
	DECLARE @InvoiceNeed int, @ItemNeed int, @InvoiceDone int, @ItemDone int
	SELECT @InvoiceNeed=0, @ItemNeed=0, @InvoiceDone=0, @ItemDone=0

	SELECT @InvoiceNeed=COUNT(1)
	FROM (
		SELECT DISTINCT i.[InvoiceIDSeq]
		FROM ( -- first the currently open invoices
			SELECT ii.[InvoiceIDSeq]
				FROM [dbo].[InvoiceItem] ii WITH (NOLOCK)
				WHERE ii.[RECALCNeeded]=1
			UNION -- and then also the invoices owning one or more open credits
			SELECT ii.[InvoiceIDSeq]
				FROM [dbo].[CreditMemoItem] ci
				INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=ci.[InvoiceItemIDSeq]
				WHERE ci.[RECALCNeeded]=1
			) AS i
		) as [Invoice_TODO]

	SELECT @InvoiceDone=COUNT(1)
	FROM (
		SELECT DISTINCT i.[InvoiceIDSeq]
		FROM ( -- first the currently open invoices
			SELECT ii.[InvoiceIDSeq]
				FROM [dbo].[InvoiceItem] ii WITH (NOLOCK)
				WHERE ii.[RECALCNeeded]=1 AND ii.[RECALCComplete]=1
			UNION -- and then also the invoices owning one or more open credits
			SELECT ii.[InvoiceIDSeq]
				FROM [dbo].[CreditMemoItem] ci
				INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=ci.[InvoiceItemIDSeq]
				WHERE ci.[RECALCNeeded]=1 AND ci.[RECALCComplete] = 1
			) AS i
		) as [Invoice_DONE]

	SELECT @ItemNeed = COUNT(1)
	FROM (
		SELECT DISTINCT i.[IDSeq]
		FROM ( -- first the currently open invoices
			SELECT ii.[IDSeq]
				FROM [dbo].[InvoiceItem] ii WITH (NOLOCK)
				WHERE ii.[RECALCNeeded]=1
			UNION -- and then also the invoices owning one or more open credits
			SELECT ii.[IDSeq]
				FROM [dbo].[CreditMemoItem] ci
				INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=ci.[InvoiceItemIDSeq]
				WHERE ci.[RECALCNeeded]=1
			) AS i
	) AS lines

	SELECT @ItemDone = COUNT(1)
	FROM (
		SELECT DISTINCT i.[IDSeq]
		FROM ( -- first the currently open invoices
			SELECT ii.[IDSeq]
				FROM [dbo].[InvoiceItem] ii WITH (NOLOCK)
				WHERE ii.[RECALCNeeded]=1 AND ii.[RECALCComplete]=1
			UNION -- and then also the invoices owning one or more open credits
			SELECT ii.[IDSeq]
				FROM [dbo].[CreditMemoItem] ci
				INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=ci.[InvoiceItemIDSeq]
				WHERE ci.[RECALCNeeded]=1 AND ci.[RECALCComplete] = 1
			) AS i
	) AS completed_lines

	SELECT @InvoiceNeed AS [InvoiceNeed], @ItemNeed AS [ItemNeed]
		, @InvoiceDone AS [InvoiceDone], @ItemDone AS [ItemDone]
	RETURN(0)
END
GO
