SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : [uspQUOTES_AvailableSalesAgents]
-- Description     : This procedure gets the list of available Sales Representatives for a quote
--
-- OUTPUT          : RecordSet of Sales Representatives
--
-- Code Example    : Exec QUOTES.dbo.[uspQUOTES_AvailableSalesAgents]
--
-- Revision History:
-- Author          : DCannon
-- 2/26/2007      : Stored Procedure Created.
-- 8/06/2007      : Changed for showing agentID not in list 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_AvailableSalesAgents] (@IPVC_QuoteID varchar(20))
AS
BEGIN 
  SET CONCAT_NULL_YIELDS_NULL OFF;
  set nocount on;
  ----------------------------------------------------------------------
  SELECT DISTINCT   u.IDSeq                         AS IDSeq,
                  u.FirstName + ' ' + u.LastName  AS [RepName]
  FROM            Security.dbo.[User]     U  with (nolock)
  INNER JOIN      Security.dbo.UserRoles  UR with (nolock)
    ON            U.IDSeq = UR.UserIDSeq 
    and           U.ActiveFlag = 1
  INNER JOIN      Security.dbo.RoleRights RR  with (nolock)
    ON            RR.RoleIDSeq = UR.RoleIDSeq
  INNER JOIN      Security.dbo.Rights     RGT with (nolock)
    ON            RR.RightIDSeq =RGT.IDSeq
    AND           RGT.Code = 'SalesRep'
  INNER JOIN      Security.dbo.Roles      RO  with (nolock)
    ON            RR.RoleIDSeq = RO.IDSeq
    and           RO.Code in ( 'SREP'-->Sales Representative
                              ,'SACT'-->Sales Administrator
                              ,'TREP'-->Tele-Sales Representative
                              ,'ACTR'-->Account Representative
                             )
  WHERE           U.ActiveFlag = 1
  and   U.IDSEQ NOT IN (SELECT SalesAgentIDSeq FROM Quotes.dbo.QuoteSaleAgent with (nolock)
                        WHERE Quoteidseq=@IPVC_QuoteID)
  ORDER BY [RepName] ASC;
END 

GO
