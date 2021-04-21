SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [quotes].[uspQUOTES_PMCBundleCountSelect] (@IPVC_QuoteID varchar(11))
AS
BEGIN

select count(*) 
from Quotes..[Group] 
where QuoteIDSeq = @IPVC_QuoteID
and GroupType = 'PMC'

END


GO
