SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_GetQuotesType
-- Description     : This procedure gets the list of Quotes available.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetQuotesType]
as
BEGIN
  Select Code,Name from Quotes.dbo.QuoteType with (nolock)
END
GO
