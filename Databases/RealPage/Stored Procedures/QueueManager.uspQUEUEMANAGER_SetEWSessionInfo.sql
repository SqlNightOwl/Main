SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_SetEWSessionInfo
-- Description     : Creates a new GUID Session Info Record and stores passed in SessionXML, if Input Parameter GUID is blank or Null
--                   If Input Parameter GUID is a valid value, then it updates the passed in SessionXML.
-- Input Parameters: 
-- Returns         : On Row RecordSet of Unique GUID
--                   If Operation fails, SP returns a nasty error for UI to trap.

-- Code Example    : 
/*
--Scenario 1 : For Creating Brand New (if XML is not known)
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SetEWSessionInfo 
                                   @IPVC_EWSGUID                = '',
                                   @IPXML_EWSessionXML          = '',
                                   @IPBI_UserIDSeq              = 123
OR 
--Scenario 1.1 : For Creating Brand New (if XML is known)
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SetEWSessionInfo 
                                   @IPVC_EWSGUID                = '',
                                   @IPXML_EWSessionXML          = '<root><row>...</row></root>',
                                   @IPBI_UserIDSeq              = 123

--Scenario 2 : For Updating Existing GUID row for updated XML
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SetEWSessionInfo 
                                   @IPVC_EWSGUID                = 'C1DE6141-DBF8-E011-A94D-0019B94B86AD',
                                   @IPXML_EWSessionXML          = '<root><row>TEST</row></root>',
                                   @IPBI_UserIDSeq              = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1315 (Shopping Cart Online)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_SetEWSessionInfo] (@IPVC_EWSGUID              varchar(50)  = '',  ---> Optional: For New Session storage,@IPVC_EWSGUID will be passed as blank. Else Valid existing @IPVC_EWSGUID                                                                                                              
                                                           @IPXML_EWSessionXML        XML          = '',  ---> Optional: This is the External Web Session XML for storage. UI will pass blank if not available
                                                           @IPBI_UserIDSeq            bigint       =-1    ---> MANDATORY : User ID of the User Logged on and doing the operation or the person submitting the Batch.
                                                                                                          ---    UI or application will know the userid
                                                          )
as
BEGIN --> Main Begin
  set nocount on;
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500);  
  select  @IPVC_EWSGUID                = nullif(ltrim(rtrim(@IPVC_EWSGUID)),''),
          @IPXML_EWSessionXML          = nullif(ltrim(rtrim(convert(varchar(max),@IPXML_EWSessionXML))),''),
          @LDT_SystemDate              = Getdate();
  ------------------------------------------
  Begin Try
    -------------------
    --Step 1: Delete Any GUID that are 24 hours older orphans
    Delete QUEUEMANAGER.dbo.ExternalWebSessionInfo    
    where  CreatedDate <= DATEADD(hh,-24,Getdate());  
    -------------------
    if not exists (select Top 1 1
                   from   QUEUEMANAGER.dbo.ExternalWebSessionInfo EWS with (nolock)
                   where  EWS.EWSGUID = @IPVC_EWSGUID
                  )
    begin
      Insert into QUEUEMANAGER.dbo.ExternalWebSessionInfo(EWSessionXML,
                                                          CreatedByIDSeq,
                                                          CreatedDate,
                                                          SystemLogDate
                                                         )
      ---------------------------------------------------
      OUTPUT INSERTED.EWSGUID                    as EWSGUID
      ---------------------------------------------------
      select  @IPXML_EWSessionXML                as EWSessionXML           
             ,@IPBI_UserIDSeq                    as CreatedByIDSeq
             ,@LDT_SystemDate                    as CreatedDate
             ,@LDT_SystemDate                    as SystemLogDate;
    end
    else
    begin
      Update QUEUEMANAGER.dbo.ExternalWebSessionInfo
      Set    EWSessionXML    =  @IPXML_EWSessionXML
            ,ModifiedByIDSeq =  @IPBI_UserIDSeq
            ,ModifiedDate    =  @LDT_SystemDate
            ,SystemLogDate   =  @LDT_SystemDate
      OUTPUT INSERTED.EWSGUID                   as EWSGUID
      where  EWSGUID      =  @IPVC_EWSGUID   
    end
  End  Try
  Begin Catch
    Exec QUEUEMANAGER.DBO.uspQUEUEMANAGER_RaiseError  @IPVC_CodeSection = 'Proc:uspQUEUEMANAGER_SetEWSessionInfo. Insert/Update Failed.'
    select null as QBatchHeaderIDSeq
    return
  end   Catch;
END--> Main End
GO
