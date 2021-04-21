SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- Database  Name  : INVOICES
-- Procedure Name  : uspTAXRECALCINVOICES_PrequalifyReset
-- Description     : Pre-set the control bits on Invoices and Credit Memo items, to All Off
-- Remarks:  
-- Revision History:
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2010-11-15   Larry Wilson          initial implementation
--
-- Copyright  : copyright (c) 2010.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
*/
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_PrequalifyReset]
AS
BEGIN
	UPDATE [dbo].[InvoiceItem] SET [RECALCNeeded]=0,[RECALCComplete] = 0  -- preset entire table
	UPDATE [dbo].[CreditMemoItem] SET [RECALCNeeded]=0,[RECALCComplete] = 0
	SELECT '1' AS confirmAction,
		'TaxRecalc flags ALL OFF' AS responseMsg
	RETURN(0)
END
GO
