SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  :  CUSTOMERS
-- Procedure Name  :  [uspCUSTOMERS_PendingQuotes]
-- Input Parameters: 	1. @IPVC_PropertyIDSeq varchar(20)
-- 
-- OUTPUT          :  All the quotes that are prending for the property
--
-- 
-- Revision History:
-- Author          : DC
-- 06/26/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_PendingQuotes] 
                  @IPVC_PropertyIDSeq         varchar(20)
AS
BEGIN
  select distinct q.QuoteIDSeq
  from Quotes.dbo.Quote q with (nolock), Quotes.dbo.GroupProperties gp with (nolock)
  where gp.PropertyIDSeq = @IPVC_PropertyIDSeq
  and q.QuoteIDSeq = gp.QuoteIDSeq
  and q.QuoteStatusCode = 'NSU'
	
END

GO
