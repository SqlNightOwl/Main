SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_DOCLinkUpdateSentToFlagForCreditMemos]
-- Description     : Updates the SentToDocLinkFlag
-- 
-- Revision History:
-- Author          : SRS
-- 01/19/2009        : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_DOCLinkUpdateSentToFlagForCreditMemos] (@IPVC_CreditMemoIDString   varchar(8000))
AS
BEGIN
  update Invoices.dbo.CreditMemo  
  set    SentToDocLinkFlag   = 1
  Where
         CreditMemoIDSeq in (select SplitString from INVOICES.dbo.[fnGenericSplitString] (@IPVC_CreditMemoIDString))

END
GO
