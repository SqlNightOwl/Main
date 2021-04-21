SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [reports].[uspQUOTES_Rep_GetSalesAgents] (@IPVC_QUOTEID varchar(20))
AS
BEGIN
  declare @SalesAgents varchar(500)
  declare @QuoteDate varchar(12)

  set @SalesAgents = ''

  select @SalesAgents = @SalesAgents + ', ' + SalesAgentName
  from Quotes..QuoteSaleAgent (nolock)
  where QuoteIDSeq in ( select Items as QuoteID from QUOTES.dbo.fnSplitDelimitedString(@IPVC_QuoteID,'|'))

  if @SalesAgents = ''
  begin
    set @SalesAgents = '<Unknown>'
  end
  else
  begin
    set @SalesAgents = right(@SalesAgents, len(@SalesAgents)-1)
  end

  select @QuoteDate = Convert(varchar(12), CreateDate, 101)
  from Quotes..Quote (nolock)
  where QuoteIDSeq = @IPVC_QUOTEID

  select @SalesAgents as SalesAgents,
         @QuoteDate as QuoteDate
END

GO
