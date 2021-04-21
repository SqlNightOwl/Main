SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_GetQueueType
-- Description     : Gets all QueueTypes
-- Input Parameters: 
-- Returns         : RecordSet of Unique QueueTypeID along with necessary information

-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_GetQueueType @IPVC_TypeStatus = 'ACTIVE';
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_GetQueueType @IPVC_TypeStatus = 'ALL';

Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_GetQueueType @IPVC_TypeStatus = 'INACTIVE';
*/

-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_GetQueueType] (@IPVC_TypeStatus     varchar(50) = 'ACTIVE' --->Scenario 1: If @IPVC_TypeStatus = 'ACTIVE', Only Active Queue Type Records are returned.
                                                                                                    ---> This is how the call will be made from WCF before submitting a new Create Batch for new request.
                                                                                                   --->Scenario 2:   If @IPVC_TypeStatus = 'ALL', All Queue Type Records irrespective of Queue Type Status are returned. 
                                                                                                    --> This is how the call will be made to list all queuetypes for Monitoring Screen Drop down list as needed.
                                                                                                   --->Scenario 3: If @IPVC_TypeStatus = 'INACTIVE', Only In Active or deactivated Queue Type Records are returned.
                                                      )
as
BEGIN
  set nocount on;
  ------------------------------------------
  select @IPVC_TypeStatus = coalesce(nullif(ltrim(rtrim(@IPVC_TypeStatus)),''),'ALL');


  Select  QT.QTypeIDSeq                                             as QueueTypeIDSeq
         ,QT.QTypeName                                              as QueueTypeName
         ,QT.QTypeDescription                                       as QueueTypeDescription
         ,QT.ActiveFlag                                             as ActiveFlag
         -------------------------
         ,ltrim(rtrim(UC.FirstName + ' ' + UC.LastName))            as CreatedByUserName
         ,QT.CreatedDate                                            as CreatedDate
         ,ltrim(rtrim(UM.FirstName + ' ' + UM.LastName))            as ModifiedByUserName
         ,QT.ModifiedDate                                           as ModifiedDate
         -------------------------
  from   QueueManager.dbo.QueueType QT with (nolock)
  left outer join
         Security.dbo.[User] UC with (nolock)
  on     QT.CreatedByIDSeq = UC.IDSeq
  left outer join
         Security.dbo.[User] UM with (nolock)
  on     QT.ModifiedByIDSeq = UM.IDSeq
  where ( 
          (@IPVC_TypeStatus='ACTIVE'   and QT.ActiveFlag = 1) 
             OR
          (@IPVC_TypeStatus='INACTIVE' and QT.ActiveFlag = 0) 
             OR
          (@IPVC_TypeStatus='ALL') 
        )
  order by QT.QTypeIDSeq ASC;
END
GO
