SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_RepresentativeListSelect]
-- Description     : This procedure returns the list of contacts based on the parameters
-- Input Parameters:  1. @PageNumber  int
--                    2. @RowsPerPage int 
--                    3. @QuoteID   varchar(20)
-- 
-- OUTPUT          : RecordSet of ID, SalesAgentName, CommissionPercent, CommissionAmount
--
-- Code Example    : Exec uspCUSTOMERS_ContactListSelect  @PageNumber = 1, 
--                                                        @RowsPerPage = 14,
--                                                        @QuoteID = 'Q0000000001'
-- 
-- 
-- Revision History:
-- Author          : RealPage 
-- 02/02/2007      : Created by Eric Font
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_RepresentativeListSelect] @PageNumber int, 
                                                            @RowsPerPage int, 
                                                            @QuoteID varchar(20)
AS
BEGIN
---------------------------------------------------------------------
SELECT  * FROM (
  Select Top (@RowsPerPage * @PageNumber)
    qs.IDSeq                                       as ID, 
    qs.SalesAgentName                              as [Name],
    q.quotestatuscode                              as quotestatus,
    qs.CommissionPercent                           as CommissionPercent, 
    qs.CommissionAmount                            as CommissionAmount,
    row_number() over(order by qs.SalesAgentName)  as RowNumber
  From Quotes.dbo.QuoteSaleAgent qs
  inner join Quotes.dbo.Quote q on q.QuoteIDSeq = qs.QuoteIDSeq
  Where qs.QuoteIDSeq=@QuoteID
  ) as tbl
WHERE RowNumber > (@PageNumber-1) * @RowsPerPage
ORDER BY Name

---------------------------------------------------------------------
SELECT COUNT(*) From Quotes.dbo.QuoteSaleAgent Where QuoteIDSeq=@QuoteID
---------------------------------------------------------------------

END
-- exec dbo.uspQUOTES_RepresentativeListSelect 1,2,'Q0000000043' 
GO
