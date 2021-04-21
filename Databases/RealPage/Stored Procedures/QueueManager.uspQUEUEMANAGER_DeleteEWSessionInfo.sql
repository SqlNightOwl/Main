SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_DeleteEWSessionInfo
-- Description     : This proc deletes corresponding EWSGUID,EWSessionXML row for the passed in @IPVC_EWSGUID
--                   This proc also takes care of wiping out 24 hours older orphans GUID records as well.
-- Input Parameters: @IPVC_EWSGUID  varchar(50)
-- Returns         : Nothing
--                   If Operation fails, SP returns a nasty error for UI to trap.

-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_DeleteEWSessionInfo 
                                   @IPVC_EWSGUID                = '19BD35D1-D8F8-E011-A94D-0019B94B86AD'
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1315 (Shopping Cart Online)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_DeleteEWSessionInfo] (@IPVC_EWSGUID        varchar(50)  ---> MANDATORY : @IPVC_EWSGUID is the unqiue GUID passed in by UI to delete corresponding record.
                                                             )
as
BEGIN --> Main Begin
  set nocount on;    
  ------------------------------------------
  Begin Try
    -------------------
    --Step 1 : Delete This GUID
    Delete QUEUEMANAGER.dbo.ExternalWebSessionInfo    
    where  EWSGUID = @IPVC_EWSGUID;
    -------------------
    --Step 2: Delete Any GUID that are 24 hours older orphans
    Delete QUEUEMANAGER.dbo.ExternalWebSessionInfo    
    where  CreatedDate <= DATEADD(hh,-24,Getdate());  
    -------------------
  End  Try
  Begin Catch
    Exec QUEUEMANAGER.DBO.uspQUEUEMANAGER_RaiseError  @IPVC_CodeSection = 'Proc:uspQUEUEMANAGER_DeleteEWSessionInfo.Delete Failed.'    
    return
  end   Catch;
END--> Main End
GO
