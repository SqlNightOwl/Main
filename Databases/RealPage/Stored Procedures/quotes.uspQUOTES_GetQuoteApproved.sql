SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_GetQuoteApproved
-- Description     : This procedure gets the list of Quotes available.
--
-- Input Parameters: @IPVC_QuoteID            varchar(20),

-- OUTPUT          : A recordSet of QuoteID, CustomerID, CustomerName, 
--                   Status, ILF, Access, ExpiresOn, RowNumber
--
-- Code Example    : Exec ORDERS.[dbo].[uspQUOTES_GetQuoteApproved] @IPVC_QuoteID = 'Q0000000046',
-- Revision History:
-- Author          : sra
--                 : Stored Procedure Created.
-- 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetQuoteApproved]
                 (
                   @IPVC_QuoteIDSeq         varchar(20)                         
                 )
AS
BEGIN
      select QuoteStatusCode from Quotes.dbo.Quote with (nolock) where QuoteIDSeq = @IPVC_QuoteIDSeq
end

-- exec dbo.uspQUOTES_GetQuoteApproved 'Q0000000046'

GO
