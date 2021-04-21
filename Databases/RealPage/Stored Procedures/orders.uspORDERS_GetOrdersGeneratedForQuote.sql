SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec [dbo].[uspORDERS_GetOrdersGeneratedForQuote] @IPVC_AccountID='A0000024458',@IPVC_QuoteID = 'Q0000002583'
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : uspORDERS_GetOrdersGeneratedForQuote
-- Description     : This procedure gets the all the Newly generated OrderID
--                   For a Given AccountID and QuoteID
--
-- Input Parameters: @IPVC_AccountID VARCHAR(50)
--                   @IPVC_QuoteID   VARCHAR(50)   
--
-- OUTPUT          : Approved OrderIDs for Given AccountID and QuoteID
--
-- Code Example    : Exec [dbo].[uspORDERS_GetOrdersGeneratedForQuote] 
--                              @IPVC_AccountID='A0000024458',@IPVC_QuoteID = 'Q0000002583'
-- 
-- Revision History:
-- Author          : SRS
-- 08/20/2007      : Stored Procedure Created.
-- 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_GetOrdersGeneratedForQuote] (@IPVC_AccountID VARCHAR(50),
                                                       @IPVC_QuoteID   VARCHAR(50))	
AS
BEGIN
  Set Nocount on
  ------------------------------------------
  Select O.OrderIDSeq as OrderID
  From   ORDERS.dbo.[Order] O with (nolock)
  Where  O.AccountIDSeq = @IPVC_AccountID
  and    O.QuoteIDSeq   = @IPVC_QuoteID
  and    O.StatusCode   = 'APPR'
END
GO
