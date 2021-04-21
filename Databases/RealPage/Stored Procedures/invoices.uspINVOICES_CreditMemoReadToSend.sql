SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_CreditMemoReadToSend]
-- Description     : This procedure returns the number of credit memos ready to send to epicor
-- 
-- Revision History:
-- Author          : DCANNON
-- 5/1/2006      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [invoices].[uspINVOICES_CreditMemoReadToSend] 
AS
BEGIN
  SELECT count(*) FROM Invoices..CreditMemo  
  where SentToEpicorFlag = 0
  and SentToEpicorStatus is null
    
END



GO
