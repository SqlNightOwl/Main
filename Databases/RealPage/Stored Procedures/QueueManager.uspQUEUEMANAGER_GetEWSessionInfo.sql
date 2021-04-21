SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_GetEWSessionInfo
-- Description     : This proc Returns corresponding EWSessionXML for the passed in @IPVC_EWSGUID
-- Input Parameters: @IPVC_EWSGUID  varchar(50)
-- Returns         : On Row RecordSet of EWSessionXML
--                   if @IPVC_EWSGUID is not valid and not present in Database, the proc returns nothing

-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_GetEWSessionInfo 
                                   @IPVC_EWSGUID                = 'FB8C6553-CEF8-E011-A94D-0019B94B86AD'
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1315 (Shopping Cart Online)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_GetEWSessionInfo] (@IPVC_EWSGUID              varchar(50)  ---> MANDATORY : @IPVC_EWSGUID is the unqiue GUID passed in by UI to fetch corresponding @IPXML_EWSessionXML
                                                          )
as
BEGIN --> Main Begin
  set nocount on;    
  ------------------------------------------
  Begin Try
    select EWS.EWSessionXML
    from   QUEUEMANAGER.dbo.ExternalWebSessionInfo EWS with (nolock)
    where  EWS.EWSGUID = @IPVC_EWSGUID;
  End  Try
  Begin Catch    
    select null as EWSessionXML
    return
  end   Catch;
END--> Main End
GO
