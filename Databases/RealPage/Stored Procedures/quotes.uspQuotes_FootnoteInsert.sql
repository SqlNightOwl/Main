SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQuotes_FootnoteInsert]
-- Description     : This procedure returns the list of contacts based on the parameters
-- Input Parameters:  1. @IPVC_QuoteIDSeq        varchar(20)
--                    2. @IPVC_Title             varchar(255)
--                    3. @IPVC_Description       varchar(4000)
-- 
-- OUTPUT          : RecordSet of ID, SalesAgentName, CommissionPercent, CommissionAmount
--
-- Code Example    : Exec [uspQuotes_FootnoteInsert]   @IPVC_QuoteIDSeq = 'Q0802000020', 
--                                                        @IPVC_Title = 'aaa',
--                                                        @IPVC_Description = 'description'
-- 
-- 
-- Revision History:
-- Author          : RealPage 
-- 04/01/2008      : Created by Naval Kishore
--
------------------------------------------------------------------------------------------------------


CREATE PROCEDURE [quotes].[uspQuotes_FootnoteInsert] (
                                                    @IPVC_QuoteIDSeq        varchar(20), 
                                                    @IPVC_Title             varchar(255),
                                                    @IPVC_Description       varchar(4000),
                                                    @IPB_MandatoryFlag      bit,
                                                    @IPBI_SortSeq           bigint
                                                   )     
AS
BEGIN 
  
  
  INSERT INTO dbo.QuoteItemNote(QuoteIDSeq, 
                      Title,
                      [Description],
                      CreatedDate,
                      MandatoryFlag,
                      SortSeq
                      )

  VALUES              (@IPVC_QuoteIDSeq,
                       @IPVC_Title,
                       @IPVC_Description, 
                       GETDATE(),
                       @IPB_MandatoryFlag,
                       @IPBI_SortSeq
					)

END


GO
