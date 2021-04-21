SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_SelectQuoteDocumentList
-- Description     : This procedure gets Quote Document Details 

-- Input Parameters: @IPVC_QuoteID varchar
--                   
-- 
-- OUTPUT          : RecordSet of Name,Description
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_SelectQuoteDocumentList 
--                   @IPVC_QuoteID    = 'Q0000000006'
-- Revision History:
-- Author          : vvenkata RealPage, Inc.
-- 03/13/2007      : Stored Procedure Created.
-- 03/15/2007	   : Added "and ActiveFlag=1"
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [documents].[uspDOCUMENTS_SelectQuoteDocumentList] (                                                              
                                                               @IPVC_QuoteID     varchar(22)
                                                              )
AS
BEGIN
  declare @LT_DocumentTable table (SortSeq     bigInt Not null,
                                   Name        varchar(1000) NULL,
                                   Description varchar(4000) NULL
                                  )
  -----------------------------------------------------------------------
  Insert into @LT_DocumentTable(SortSeq,Name,Description)
  Select distinct 0 as SortSeq,D.Title as Name,D.Description as Description
  From   Quotes.DBO.QuoteItemNote D with (nolock)
  where  D.QuoteIDSeq   = @IPVC_QuoteID
  and    D.PrintOnOrderFormFlag = 1
  and    (D.Title       = 'Default Footnote #1')
  -----and   ltrim(rtrim(Description)) = 'Onetime Initial License Fees will be invoiced and due upon signing of this Order form.'
  -----------------------------------------------------------------------
  Insert into @LT_DocumentTable(SortSeq,Name,Description)
  Select distinct 99999999999999 as SortSeq,D.Title as Name,D.Description as Description
  From   Quotes.DBO.QuoteItemNote D with (nolock)
  where  D.QuoteIDSeq   = @IPVC_QuoteID
  and    D.PrintOnOrderFormFlag = 1
  and    (D.Title       = 'Default Footnote #2')
  ----and   ltrim(rtrim(Description)) = 'Use of certain Product Centers and Services may be subject to additional Dependencies and Uses.Please refer to http://www.specifications.controls.realpage.com, incorporated herein by this reference.'
  -----------------------------------------------------------------------
  Insert into @LT_DocumentTable(SortSeq,Name,Description)
  Select distinct 9999999999999999 as SortSeq,D.Title as Name,D.Description as Description
  From   Quotes.DBO.QuoteItemNote D with (nolock)
  where  D.QuoteIDSeq   = @IPVC_QuoteID
  and    D.PrintOnOrderFormFlag = 1
  and    (D.Title       = 'Default Footnote #3')
  ----and   ltrim(rtrim(Description)) = 'Use of certain Product Centers and Services may be subject to additional Dependencies and Uses.Please refer to http://www.specifications.controls.realpage.com, incorporated herein by this reference.'
  -----------------------------------------------------------------------
  Insert into @LT_DocumentTable(SortSeq,Name,Description)
  Select distinct D.IDSeq as SortSeq,D.Title as Name,D.Description as Description
  From   Quotes.DBO.QuoteItemNote D with (nolock)
  where  D.QuoteIDSeq   = @IPVC_QuoteID
  and    D.PrintOnOrderFormFlag = 1
  and    (D.Title<>'Default Footnote #1' and D.Title<>'Default Footnote #2' and D.Title<>'Default Footnote #3')
  order by D.IDSeq
  -----------------------------------------------------------------------
  --Final Select 
  ----------------------------------------------------------------------- 
  select Name,Description
  from @LT_DocumentTable
--  order by sortseq asc
  -----------------------------------------------------------------------
END
GO
