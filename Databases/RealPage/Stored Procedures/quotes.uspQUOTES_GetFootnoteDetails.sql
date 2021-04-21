SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_GetFootnoteDetails]
-- Description     : This procedure returns the list of contacts based on the parameters
-- Input Parameters:  1. @IPI_IDSeq bigint
--                   
-- 
-- OUTPUT          : RecordSet of ID, SalesAgentName, CommissionPercent, CommissionAmount
--
-- Code Example    : Exec [uspQUOTES_GetFootnoteDetails]  @IPI_IDSeq = 10
-- 
-- 
-- Revision History:
-- Author          : RealPage 
-- 04/02/2008      : Created by Naval Kishore
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_GetFootnoteDetails]
														( 
														@IPI_IDSeq bigint	
														) 
AS
BEGIN
  
	SELECT  Title,
			[Description]
	FROM    QUOTES.dbo.QuoteItemNote
	WHERE   IDSEQ = @IPI_IDSeq
END

-- Exec [uspQUOTES_GetFootnoteDetails]  @IPVC_IDSeq = 2




GO
