SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec uspQUOTES_DeleteQuote @IPVC_CompanyID = 'A0000000000',@IPVC_QuoteID = 52
-- Revision History:
-- Author          : Satya B
-- 07/18/2011      : Added new column PrePaidFlag with refence to TFS #295 Instant Invoice Transactions through OMS

CREATE PROCEDURE [quotes].[uspQUOTES_DeleteQuote]  (@IPVC_CompanyID    varchar(50),
                                             @IPVC_QuoteID      varchar(50)                                    
                                            )
AS
BEGIN
  set nocount on
  begin TRY    
    delete from Quotes.dbo.QuoteSaleAgent  where quoteidseq = @IPVC_QuoteID
    delete from Quotes.dbo.QuoteItemNote   where quoteidseq = @IPVC_QuoteID
    delete from Quotes.dbo.QuoteItem       where quoteidseq = @IPVC_QuoteID
    delete from Quotes.dbo.GroupProperties where quoteidseq = @IPVC_QuoteID
    delete from Quotes.dbo.[Group]         where quoteidseq = @IPVC_QuoteID
    -----------------------------------------------------------------------   
    delete from Quotes.dbo.QuoteLog        where quoteidseq = @IPVC_QuoteID
    delete from Documents.dbo.Documentlog  where quoteidseq = @IPVC_QuoteID
    delete from Documents.dbo.Document     where quoteidseq = @IPVC_QuoteID
    delete from Quotes.dbo.Quote           where quoteidseq = @IPVC_QuoteID
    -----------------------------------------------------------------------    
  end TRY
  begin CATCH    
  end CATCH
END
GO
