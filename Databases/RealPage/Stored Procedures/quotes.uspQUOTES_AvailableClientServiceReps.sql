SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_AvailableClientServiceReps]
-- Description     : This procedure gets the list of available Sales Representatives for a quote
--
-- OUTPUT          : RecordSet of Sales Representatives
--
-- Code Example    : Exec DOCUMENTS.dbo.[uspQUOTES_AvailableClientServiceReps]
--
-- Revision History:
-- Author          : Naval Kishore SIngh
-- 8/31/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_AvailableClientServiceReps] @IPVC_QuoteID varchar(20)
AS
BEGIN 
  ----------------------------------------------------------------------
  SELECT DISTINCT u.IDSeq                         AS IDSeq,
                  u.FirstName + ' ' + u.LastName  AS [RepName]
  FROM            Security..[User] U

  INNER JOIN      Security..UserRoles UR
    ON            U.IDSeq = UR.UserIDSeq 

  INNER JOIN      Security..RoleRights RR 
    ON            RR.RoleIDSeq = UR.RoleIDSeq 

  INNER JOIN      Security..Rights R 
    ON            R.IDSeq = RR.RightIDSeq 
    AND           R.Code = 'CSRep'
  
--WHERE u.IDSEQ NOT IN (SELECT SalesAgentIDSeq FROM Quotes.dbo.QuoteSaleAgent
  --                     WHERE Quoteidseq=@IPVC_QuoteID)
  ORDER BY [RepName]
---------------------------------------------------------------------------------
SELECT CSRIDSeq FROM Quotes.dbo.Quote WHERE QuoteIDSEQ = @IPVC_QuoteID

END 

GO
