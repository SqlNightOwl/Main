SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQuotes_FootnoteUpdate]
-- Description     : This procedure returns the list of contacts based on the parameters
-- Input Parameters: 1. @IPI_IDSeq        varchar(20)
--                    2. @IPVC_Title             varchar(255)
--                    3. @IPVC_Description       varchar(4000)
-- 
-- OUTPUT          : RecordSet of ID, SalesAgentName, CommissionPercent, CommissionAmount
--
-- Code Example    : Exec [uspQuotes_FootnoteUpdate]  @IPI_IDSeq = 1, 
--                                                        @IPVC_Title = 'aaa',
--                                                        @IPVC_Description = 'description'
-- 
-- 
-- Revision History:
-- Author          : RealPage 
-- 04/02/2008      : Created by Naval Kishore
--
------------------------------------------------------------------------------------------------------


CREATE PROCEDURE [quotes].[uspQuotes_FootnoteUpdate] (
                                                    @IPI_IDSeq				bigint, 
                                                    @IPVC_Title             varchar(255),
                                                    @IPVC_Description       varchar(4000)
                                                   )     
AS
BEGIN 
  
  
  UPDATE Quotes.dbo.QuoteItemNote
  SET				  Title = @IPVC_Title,
                      [Description] = @IPVC_Description
                    
  WHERE IDSEQ = @IPI_IDSeq

 

END


GO
