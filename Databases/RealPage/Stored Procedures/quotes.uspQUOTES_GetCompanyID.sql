SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_GetCompanyID]
-- Description     : This procedure retrieves CompanyID and created date based on the quote Ids passed with dilimiter '|'
-- Input Parameters: @QuoteID  VARCHAR(8000)
--                   
-- OUTPUT          : 
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_GetCompanyID]   @QuoteID  = '|Q0000002589|Q0000002581|Q0000002580|Q0000002579|'
--                                                             
-- Revision History:
-- Author          : Shashi Bhushan
-- 09/04/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetCompanyID] @QuoteID  VARCHAR(8000)
AS
BEGIN
	select top 1 customeridseq,convert(varchar(12),createdate,101) as createdate
	from quotes..quote
	where quoteidseq in (select * from Customers.dbo.[fnSplitProductCodes] (@QuoteID))
END


GO
