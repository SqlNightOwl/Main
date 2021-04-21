SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_BatchDetailLookup
-- Description     : This proc gets called by the WCF for Lookup based on Key identifiers BatchHeaderIDSeq and BatchDetailIDSeq

--                   The Queue will have unique record identifiers BatchHeaderIDSeq and BatchDetailIDSeq, which gets passed to WCF.
--                   First step is to pass BatchHeaderIDSeq and BatchDetailIDSeq, UserIDSeq  to lookup to see if it is a valid unprocessed detail record.
--                   If YES, then this proc will mark the status of the detail record to 5  (inprocess) from previous 0 (Un Processed),
--                    marks the startdatetime and userid and then finally returns the Valid BatchHeaderIDSeq and BatchDetailIDSeq.

--                   If NO, then BatchHeaderIDSeq and BatchDetailIDSeq  will be returned as NULL, NULL so the WCF can ignore because it is not a valid record.
--              

--            
-- Input Parameters: @IPBI_QBatchHeaderIDSeq,@IPBI_QBatchDetailIDSeq,@IPBI_UserIDSeq
-- Returns         : RecordSet of Unique Header and Batch Detail ID back to Client to submit it through the Queue along with 
--                   identifying Unique Header and Batch Detail ID(s)

---                  Only Unprocessed and freshly submitted Batch Detail Rows that have status = 0 will be returned for submit to queue.



-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_BatchDetailLookup                                  
                                         @IPBI_QBatchHeaderIDSeq      = 1
                                        ,@IPBI_QBatchDetailIDSeq      = 1
                                        ,@IPBI_UserIDSeq              = 123

Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_BatchDetailLookup                                  
                                         @IPBI_QBatchHeaderIDSeq      = 1
                                        ,@IPBI_QBatchDetailIDSeq      = 2
                                        ,@IPBI_UserIDSeq              = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_BatchDetailLookup] (@IPBI_QBatchHeaderIDSeq         bigint,             ---> MANDATROY: This is not null positive whole number value of QBatchHeaderIDSeq For the batch Header Request. Queue will have this Unique HeaderID identifier.
                                                            @IPBI_QBatchDetailIDSeq         bigint,             ---> MANDATROY: This is not null positive whole number value of QBatchDetailIDSeq For the batch Detail Request. Queue will have this Unique DetailID identifier.
                                                            @IPBI_UserIDSeq                 bigint       =-1    ---> MANDATORY : User ID of the User Logged on and doing the operation or the person submitting the Batch.
                                                                                                                ---    UI or application will know the userid who queries to submits this Batch to queue.
                                                           )
as
BEGIN --> Main Begin
  set nocount on;
  ------------------------------------------
  declare @LDT_SystemDate  datetime;
  select  @LDT_SystemDate  = Getdate();
  ------------------------------------------
  Begin Try
    Update QBD
    Set    QBD.ProcessStatus     = 5,
           QBD.ProcessStartDate  = @LDT_SystemDate,
           QBD.ModifiedByIDSeq   = @IPBI_UserIDSeq,
           QBD.ModifiedDate      = @LDT_SystemDate,
           QBD.SystemLogDate     = @LDT_SystemDate
    -----------------------------
    OUTPUT INSERTED.QBHIDSeq     as QBatchHeaderIDSeq,
           INSERTED.QBDIDSeq     as QBatchDetailIDSeq
    ----------------------------- 
    from   QUEUEMANAGER.dbo.QueueBatchDetail QBD with (nolock)
    where  QBD.QBHIDSeq         = @IPBI_QBatchHeaderIDSeq
    and    QBD.QBDIDSeq         = @IPBI_QBatchDetailIDSeq
    and    QBD.ProcessStatus    = 0;
    --------------------------------------------
    --Sync Proc Call for Header Realtime Update
    --------------------------------------------    
    Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SyncStatsBatchHeader @IPBI_QBatchHeaderIDSeq = @IPBI_QBatchHeaderIDSeq;
    --------------------------------------------    
  End  Try
  Begin Catch
    Exec QUEUEMANAGER.DBO.uspQUEUEMANAGER_RaiseError  @IPVC_CodeSection = 'Proc:uspQUEUEMANAGER_BatchDetailLookup. Batch Detail Look Up Failed.'
    select null as QBatchHeaderIDSeq,null as QBatchDetailIDSeq
    return
  end   Catch;
END--> Main End
GO
