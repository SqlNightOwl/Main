SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- Database  Name  : INVOICES
-- Procedure Name  : uspTAXRECALCINVOICES_FindWork
-- Description     : fetch list of invoice items in need of tax recalculation
-- Remarks: 
	Here it is necessary to collect all Invoice Items which need recalculation for themselves, 
	along with all Invoices owning one or more Credit Memo items that still need recalculation. 
	It is probable that many Credit Memo items need processing, although they are tied to Invoices from prior
	months -- which are NOT being recalculated any more.  Nonetheless, those Invoices must be included in 
	today's batch, in order to drive the recalculation of the associated Credit Memo items. 

	This query was originally in-line dynamic sql, in the source code of TaxRecalc app. 
	It runs when the user clicks on "Connect To Server" button, and it fetches the complete 
	list of Invoice Items that need tax recalculation, at this time. 
	This sql was lifted out of source code to this stored proc, (and modified) under PCR 6250. 

-- Revision History:
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-09-21   Larry Wilson          initial implementation
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
*/
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_FindWork]
(
	@CountOnly bit = 0
)
AS
BEGIN
	IF @CountOnly=1
	BEGIN -- count all the line items in the open invoices and credits
		SELECT COUNT(1) as [ItemCount]
		FROM (
			SELECT DISTINCT i.[IDSeq]
			FROM ( -- first the currently open invoices
				SELECT ii.[IDSeq]
					FROM [dbo].[InvoiceItem] ii WITH (NOLOCK)
					WHERE ii.[RECALCNeeded]=1 AND ii.[RECALCComplete]=0
				UNION -- and then also the invoices owning one or more open credits
				SELECT ii.[IDSeq]
					FROM [dbo].[CreditMemoItem] ci
					INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=ci.[InvoiceItemIDSeq]
					WHERE ci.[RECALCNeeded]=1 AND ci.[RECALCComplete] = 0
				) AS i
		) AS lines
	END
	ELSE
	BEGIN -- make a list of "open" invoices, i.e. Invoices that need work (for whichever reason)
		SELECT DISTINCT i.[InvoiceIDSeq]
		FROM ( -- first the currently open invoices
			SELECT ii.[InvoiceIDSeq]
				FROM [dbo].[InvoiceItem] ii WITH (NOLOCK)
				WHERE ii.[RECALCNeeded]=1 AND ii.[RECALCComplete]=0
			UNION -- and then also the invoices owning one or more open credits
			SELECT ii.[InvoiceIDSeq]
				FROM [dbo].[CreditMemoItem] ci
				INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[IDSeq]=ci.[InvoiceItemIDSeq]
				WHERE ci.[RECALCNeeded]=1 AND ci.[RECALCComplete] = 0
			) AS i
		ORDER BY i.[InvoiceIDSeq]
	END
	RETURN(0)
END
GO
