SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_SetBatchHeader
-- Description     : Creates a Batch Header Record (ie. the Main Batch Record).
--                   This call will be called by method must be called once to start. 
-- Input Parameters: 
-- Returns         : RecordSet of Unique Batch Header ID which will then be 
--                   used by multiple Calls of uspQUEUEMANAGER_SetBatchDetail to set one or more Batch Detail
--                   records pertaining the Batch Header ID.

--                   Upon Successful Creation of Batch Header Record, Returns a valid positive number QBatchHeaderIDSeq
--                   Upon error, SP will return Error Message and NULL as QBatchHeaderIDSeq, which has to be trapped by Calling program.



-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SetBatchHeader 
                                   @IPI_QueueTypeIDSeq          = 1,
                                   @IPVC_BatchHeaderDescription = 'Sample Batch Header',
                                   @IPBI_UserIDSeq              = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_SetBatchHeader] (@IPI_QueueTypeIDSeq             int,                ---> MANDATORY: This is the Queue TypeIDSeq For the batch Header Request submitted to be Submitted to Queue.
                                                                                                             ---  Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_GetQueueType @IPVC_TypeStatus = 'ACTIVE' will return all active Queue types with IDs
                                                         @IPVC_BatchHeaderDescription    varchar(255) = '',  ---> Optional : This is the Batch Header User identifiable description. Default is blank.
                                                         @IPBI_UserIDSeq                 bigint       =-1    ---> MANDATORY : User ID of the User Logged on and doing the operation or the person submitting the Batch.
                                                                                                             ---    UI or application will know the userid who submits this Batch.
                                                        )
as
BEGIN --> Main Begin
  set nocount on;
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500);  
  select  @IPVC_BatchHeaderDescription = nullif(ltrim(rtrim(@IPVC_BatchHeaderDescription)),''),
          @LDT_SystemDate              = Getdate();
  ------------------------------------------
  Begin Try
    Insert into QUEUEMANAGER.dbo.QueueBatchHeader(QTypeIDSeq,
                                                  QBHDescription,
                                                  TotalSubmittedCount,
                                                  TotalWaitingCount,
                                                  TotalInProcessCount,
                                                  TotalCompletedCount,
                                                  TotalFailedCount,
                                                  CreatedByIDSeq,
                                                  CreatedDate,
                                                  SystemLogDate
                                                 )
    ---------------------------------------------------
    OUTPUT INSERTED.QBHIDSeq                   as QBatchHeaderIDSeq
    ---------------------------------------------------
    select  @IPI_QueueTypeIDSeq                as QTypeIDSeq
           ,@IPVC_BatchHeaderDescription       as QBHDescription
           ,0                                  as TotalSubmittedCount
           ,0                                  as TotalWaitingCount
           ,0                                  as TotalInProcessCount
           ,0                                  as TotalCompletedCount
           ,0                                  as TotalFailedCount
           ,@IPBI_UserIDSeq                    as CreatedByIDSeq
           ,@LDT_SystemDate                    as CreatedDate
           ,@LDT_SystemDate                    as SystemLogDate;
  End  Try
  Begin Catch
    Exec QUEUEMANAGER.DBO.uspQUEUEMANAGER_RaiseError  @IPVC_CodeSection = 'Proc:uspQUEUEMANAGER_SetBatchHeader. Batch Header Creation Failed.'
    select null as QBatchHeaderIDSeq
    return
  end   Catch;

END--> Main End
GO
