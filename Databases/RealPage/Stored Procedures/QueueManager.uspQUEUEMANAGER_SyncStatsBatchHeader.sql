SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_SyncStatsBatchHeader
-- Description     : This is an Internal proc that will not be called from UI at all
--                   This proc call gets made to keep Batch Header Stats in Sync for 
--                    every Operation of corresponding Detail
-- Input Parameters: @IPBI_QBatchHeaderIDSeq 
-- Returns         : None

-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SyncStatsBatchHeader 
                                   @IPBI_QBatchHeaderIDSeq = 1
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_SyncStatsBatchHeader] (@IPBI_QBatchHeaderIDSeq         bigint   ---> MANDATROY: This is not null positive whole number value of QBatchHeaderIDSeq For the batch Header Request. Queue will have this Unique HeaderID identifier.
                                                              )
as
BEGIN --> Main Begin
  set nocount on;
  set ansi_warnings off;
  ------------------------------------------
  Begin Try
    ;With CTE_QBD (QBHIDSeq,QTypeIDSeq,
                   TotalSubmittedCount,TotalWaitingCount,TotalInProcessCount,TotalCompletedCount,TotalFailedCount,
                   ModifiedByIDSeq,ModifiedDate
                  )
     as (
         select QBD.QBHIDSeq                                              as QBHIDSeq,
                QBD.QTypeIDSeq                                            as QTypeIDSeq,
                Count(1)                                                  as TotalSubmittedCount,
                sum((case when QBD.ProcessStatus = 0 then 1 else 0 end))  as TotalWaitingCount,
                sum((case when QBD.ProcessStatus = 5 then 1 else 0 end))  as TotalInProcessCount,
                sum((case when QBD.ProcessStatus = 1 then 1 else 0 end))  as TotalCompletedCount,
                sum((case when QBD.ProcessStatus = 2 then 1 else 0 end))  as TotalFailedCount,
                Max((case when QBD.ProcessStatus not in (0,5) 
                            then QBD.ModifiedByIDSeq 
                          else null end)
                   )                                                      as ModifiedByIDSeq,              
               Max((case when QBD.ProcessStatus not in (0,5) 
                            then QBD.ModifiedDate 
                          else null end)
                   )                                                      as ModifiedDate
         from  QUEUEMANAGER.dbo.QueueBatchDetail QBD with (nolock) 
         where QBD.QBHIDSeq = @IPBI_QBatchHeaderIDSeq
         group by QBD.QBHIDSeq,QBD.QTypeIDSeq
        )
    -------------
    Update  QBH
    set     QBH.TotalSubmittedCount   = CTE_QBD.TotalSubmittedCount
           ,QBH.TotalWaitingCount     = CTE_QBD.TotalWaitingCount
           ,QBH.TotalInProcessCount   = CTE_QBD.TotalInProcessCount
           ,QBH.TotalCompletedCount   = CTE_QBD.TotalCompletedCount
           ,QBH.TotalFailedCount      = CTE_QBD.TotalFailedCount
           ,QBH.ModifiedByIDSeq       = CTE_QBD.ModifiedByIDSeq
           ,QBH.ModifiedDate          = CTE_QBD.ModifiedDate
           ,QBH.SystemLogDate         = Getdate()
    from   QUEUEMANAGER.dbo.QueueBatchHeader QBH with (nolock) 
    inner join
           CTE_QBD CTE_QBD
    on     QBH.QBHIDSeq   = CTE_QBD.QBHIDSeq
    and    QBH.QTypeIDSeq = CTE_QBD.QTypeIDSeq
    and    QBH.QBHIDSeq   = @IPBI_QBatchHeaderIDSeq;   
  End  Try
  Begin Catch    
    return
  end   Catch;
  ------------------------------------------
END--> Main End
GO
