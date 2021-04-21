SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [quotes].[uspQUOTES_GetQuotesForProperties] (@IPVC_PropertyIDSeq varchar(11))
AS
BEGIN
  select 
         q_quote.QuoteIDSeq as QuoteIDSeq,
         QS.Name as Status,
         convert(numeric(10,2),q_quote.ILFNetExtYearChargeAmount) as ILF,
         convert(numeric(10,2),q_quote.AccessNetExtYear1ChargeAmount) as Access
  from QUOTES.dbo.GroupProperties               q_group  with (nolock)
  inner join Quotes.dbo.Quote                   q_quote  with (nolock)
  on    q_quote.QuoteIDSeq = q_group.QuoteIDSeq
  and   q_group.PropertyIDSeq = @IPVC_PropertyIDSeq
  AND   q_quote.QuoteStatusCode <> 'APR'
  inner join Quotes.dbo.QuoteStatus             QS       with (nolock)
  on    q_quote.QuoteStatusCode = QS.Code
  where q_group.PropertyIDSeq = @IPVC_PropertyIDSeq
  AND   q_quote.QuoteStatusCode <> 'APR'
END

-- exec [uspQUOTES_GetQuotesForProperties] 'P0000023012'
GO
