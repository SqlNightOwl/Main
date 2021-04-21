SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [quotes].[uspQUOTES_ValidateCancelQuote] (@IPVC_QuoteIDSeq varchar(50))
AS
BEGIN
  set nocount on
  ------------------------------------------------
  If exists (select top 1 1 from 
             CUSTOMERS.dbo.SiteTransferLog with (nolock)
             Where QuoteIDSeq = @IPVC_QuoteIDSeq  
             )
  begin
    select 1
  end
  else
  begin
    select 0
  end
END

GO
