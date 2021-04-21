SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_UpdateClientRepresentative]
-- Description     : This procedure gets the list of available Sales Representatives for a quote
--
-- OUTPUT          : RecordSet of Sales Representatives
--
-- Code Example    : Exec DOCUMENTS.dbo.[uspQUOTES_UpdateClientRepresentative]
--
-- Revision History:
-- Author          : Naval Kishore Singh
-- 8/31/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_UpdateClientRepresentative] @IPVC_QuoteID     varchar(50), 
                                                   @IPN_SalesAgentIDSeq   bigint
                                                   
As
BEGIN
  UPDATE Quotes.dbo.Quote 
  SET CSRIDSeq = @IPN_SalesAgentIDSeq
  WHERE QuoteIDSeq = @IPVC_QuoteID
END

GO
