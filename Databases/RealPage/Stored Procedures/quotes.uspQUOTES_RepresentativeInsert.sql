SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [quotes].[uspQUOTES_RepresentativeInsert] @IPVC_QuoteID     varchar(50), 
                                                   @IPN_SalesAgentIDSeq   bigint, 
                                                   @IPN_CommissionPercent varchar(50),
                                                   @IPN_CommissionAmount  varchar(50)
As
BEGIN
  Insert Into Quotes.dbo.QuoteSaleAgent (QuoteIDSeq, SalesAgentName, SalesAgentIDSeq, 
    CommissionPercent, CommissionAmount) 
  select @IPVC_QuoteID, FirstName + ' ' + LastName, @IPN_SalesAgentIDSeq, 
    @IPN_CommissionPercent, @IPN_CommissionAmount
  from Security.dbo.[User]
  where IDSeq = @IPN_SalesAgentIDSeq
END

GO
