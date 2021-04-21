SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec uspQUOTES_ReportGetQuoteItemNotes @IPVC_CompanyID=N'C0000001146',@IPVC_QuoteID=N'|Q0710000205|'    

----------------------------------------------------------------------
*/
CREATE PROCEDURE [reports].[uspQUOTES_ReportGetQuoteItemNotes] 
                                                      (@IPVC_CompanyID     varchar(50),
                                                       @IPVC_QuoteID       varchar(8000), 
                                                       @IPVC_Delimiter     varchar(1)= '|'
                                                      )
AS
BEGIN   
  set nocount on 
  -----------------------------------------------------------------------------------
  --Declaring Local Variables 
  -----------------------------------------------------------------------------------
  declare @LT_Quotes  TABLE (QuoteID varchar(50)) 
  declare @LT_QuoteItemNoteTable table 
                                  (SortSeq       bigint        not null,  
                                   Title         varchar(1000) null,                                 
                                   Description   varchar(4000) NULL
                                  )  
  -----------------------------------------------------------------------------------
  --Parse the string to get all the Quotes.
  insert into @LT_Quotes(QuoteID)
  select Items as QuoteID from QUOTES.dbo.fnSplitDelimitedString(@IPVC_QuoteID,@IPVC_Delimiter)
  ----------------------------------------------------------------------------------- 
  ---Default QuoteItemNote #1 to appear First
  Insert into @LT_QuoteItemNoteTable(SortSeq,Title,Description)
  Select distinct 0 as SortSeq,D.Title as Title,D.Description as QuoteItemNote
  From   Quotes.DBO.QuoteItemNote D with (nolock)
  inner join
         @LT_Quotes S 
  on     D.QuoteIDSeq   = S.QuoteID 
  and    D.PrintOnOrderFormFlag = 1
  and    (D.Title       = 'Default QuoteItemNote #1')
  ----------------------------------------------------------------------------------- 
   ---Default QuoteItemNote #2 to appear Last but one
  Insert into @LT_QuoteItemNoteTable(SortSeq,Title,Description)
  Select distinct 99999999999999 as SortSeq,D.Title as Title,D.Description as QuoteItemNote
  From   Quotes.DBO.QuoteItemNote D with (nolock)
  inner join
         @LT_Quotes S 
  on     D.QuoteIDSeq   = S.QuoteID 
  and    D.PrintOnOrderFormFlag = 1
  and    (D.Title       = 'Default QuoteItemNote #2')
  ----------------------------------------------------------------------------------- 
   ---Default QuoteItemNote #3 to appear at the very last
  Insert into @LT_QuoteItemNoteTable(SortSeq,Title,Description)
  Select distinct 9999999999999999 as SortSeq,D.Title as Title,D.Description as QuoteItemNote
  From   Quotes.DBO.QuoteItemNote D with (nolock)
  inner join
         @LT_Quotes S 
  on     D.QuoteIDSeq   = S.QuoteID 
  and    D.PrintOnOrderFormFlag = 1
  and    (D.Title       = 'Default QuoteItemNote #3')
  ----------------------------------------------------------------------------------- 
  Insert into @LT_QuoteItemNoteTable(SortSeq,Title,Description)
  Select distinct D.IDSeq as SortSeq,D.Title as Title,D.Description as QuoteItemNote
  From   Quotes.DBO.QuoteItemNote D with (nolock)
  inner join
         @LT_Quotes S 
  on     D.QuoteIDSeq   = S.QuoteID 
  and    D.PrintOnOrderFormFlag = 1
  and    not exists (select top 1 1 from @LT_QuoteItemNoteTable X
                     where  D.Title = X.Title)
  order by D.IDSeq
  -----------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------- 
  select Description as QuoteItemNote
  from @LT_QuoteItemNoteTable
  order by sortseq asc
  -----------------------------------------------------------------------
END

GO
