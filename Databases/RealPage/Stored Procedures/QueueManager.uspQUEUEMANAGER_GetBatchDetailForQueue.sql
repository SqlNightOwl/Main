SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_GetBatchDetailForQueue
-- Description     : This proc gets called by the Client ONLY after it completes the following
--                   Call 1 : For unique Batch Header Insert uspQUEUEMANAGER_SetBatchHeader
--                   Call 2 : One or more calls against the Batch Header to create all Batch detail records

--            
-- Input Parameters: @IPBI_QBatchHeaderIDSeq,@IPBI_UserIDSeq
-- Returns         : RecordSet of Unique Header and Batch Detail ID back to Client to submit it through the Queue along with 
--                   identifying Unique Header and Batch Detail ID(s)

---                  Only Unprocessed and freshly submitted Batch Detail Rows that have status = 0 will be returned for submit to queue.



-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_GetBatchDetailForQueue                                  
                                         @IPBI_QBatchHeaderIDSeq      = 1
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_GetBatchDetailForQueue] (@IPBI_QBatchHeaderIDSeq         bigint,             ---> MANDATROY: This is not null positive whole number value of QBatchHeaderIDSeq For the batch Header Request previously returned through call of uspQUEUEMANAGER_SetBatchHeader.
                                                                 @IPBI_UserIDSeq                 bigint       =-1    ---> MANDATORY : User ID of the User Logged on and doing the operation or the person submitting the Batch.
                                                                                                                     ---    UI or application will know the userid who queries to submits this Batch to queue.
                                                                 )
as
BEGIN --> Main Begin
  set nocount on;
  ------------------------------------------
  select QBD.QBHIDSeq                   as QBatchHeaderIDSeq,
         QBD.QBDIDSeq                   as QBatchDetailIDSeq
  from   QUEUEMANAGER.dbo.QueueBatchDetail QBD with (nolock)
  where  QBD.QBHIDSeq         = @IPBI_QBatchHeaderIDSeq
  and    QBD.ProcessStatus    = 0
  order by QBD.QBHIDSeq ASC,QBD.QBDIDSeq ASC;
  ------------------------------------------
END--> Main End
GO
