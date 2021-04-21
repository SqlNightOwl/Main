SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_GetFootnoteList]
-- Description     : This procedure returns the list of contacts based on the parameters
-- Input Parameters:  1. @PageNumber  int
--                    2. @RowsPerPage int 
--                    3. @QuoteID   varchar(20)
-- 
-- OUTPUT          : RecordSet of ID, SalesAgentName, CommissionPercent, CommissionAmount
--
-- Code Example    : Exec [uspQUOTES_GetFootnoteList]  @PageNumber = 1, 
--                                                        @RowsPerPage = 14,
--                                                        @QuoteID = 'Q0000000001'
-- 
-- 
-- Revision History:
-- Author          : RealPage 
-- 04/01/2008      : Created by Naval Kishore
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetFootnoteList] @PageNumber int, 
                                                            @RowsPerPage int, 
                                                            @QuoteID varchar(20)
AS
BEGIN
---------------------------------------------------------------------
SELECT  * FROM (
  Select Top (@RowsPerPage * @PageNumber)
    qs.IDSeq                                       as ID, 
    qs.Title                                       as Title,
	q.quotestatuscode                              as quotestatus,
    qs.Description								   as [Description],
   convert(varchar(12),qs.CreatedDate ,101)       as CreatedDate,
    
    row_number() over(order by qs.Title)		   as RowNumber
  From Quotes.dbo.QuoteItemNote qs
  inner join Quotes.dbo.Quote q on q.QuoteIDSeq = qs.QuoteIDSeq
  Where qs.QuoteIDSeq=@QuoteID
  ) as tbl
WHERE RowNumber > (@PageNumber-1) * @RowsPerPage


---------------------------------------------------------------------
SELECT COUNT(*) From Quotes.dbo.QuoteItemNote Where QuoteIDSeq=@QuoteID
---------------------------------------------------------------------

END
-- exec dbo.uspQUOTES_GetFootnoteList 1,2,'Q0000000043' 
GO
