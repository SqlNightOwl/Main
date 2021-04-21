SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_SetBatchDetailStatus
-- Description     : This proc gets called by the WCF for based Key identifiers BatchHeaderIDSeq and BatchDetailIDSeq
--                   For Success, WCF will pass in @IPI_ProcessStatus as 0, @IPVC_ErrorMessage as blank
--                   For Failure, WCF will pass in @IPI_ProcessStatus as 2, @IPVC_ErrorMessage as valid error message

-- Input Parameters: @IPBI_QBatchHeaderIDSeq,@IPBI_QBatchDetailIDSeq,@IPI_ProcessStatus,@IPVC_ErrorMessage,@IPBI_UserIDSeq
-- Returns         : None



-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SetBatchDetailStatus                                  
                                         @IPBI_QBatchHeaderIDSeq      = 1
                                        ,@IPBI_QBatchDetailIDSeq      = 1
                                        ,@IPI_ProcessStatus           = 1
                                        ,@IPVC_ErrorMessage           = ''
                                        ,@IPBI_UserIDSeq              = 123

Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SetBatchDetailStatus                                  
                                         @IPBI_QBatchHeaderIDSeq      = 1
                                        ,@IPBI_QBatchDetailIDSeq      = 2
                                        ,@IPI_ProcessStatus           = 2
                                        ,@IPVC_ErrorMessage           = 'Failed due to Blah Blah'
                                        ,@IPBI_UserIDSeq              = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_SetBatchDetailStatus] (@IPBI_QBatchHeaderIDSeq         bigint,             ---> MANDATROY: This is not null positive whole number value of QBatchHeaderIDSeq For the batch Header Request. Queue will have this Unique HeaderID identifier.
                                                               @IPBI_QBatchDetailIDSeq         bigint,             ---> MANDATROY: This is not null positive whole number value of QBatchDetailIDSeq For the batch Detail Request. Queue will have this Unique DetailID identifier.
                                                               @IPI_ProcessStatus              int,                ---> MANDATORY: For Success, it will be 1. For Failure it will be 2.
                                                               @IPVC_ErrorMessage              varchar(4000)='',   ---> Optional: For Success, it will be blank ''. For Failure it will be some valid error message.
                                                               @IPBI_UserIDSeq                 bigint       =-1    ---> MANDATORY : User ID of the User Logged on and doing the operation or the person submitting the Batch.
                                                                                                                   ---    UI or application will know the userid who queries to submits this Batch to queue.
                                                               )
as
BEGIN --> Main Begin
  set nocount on;
  ------------------------------------------
  declare @LDT_SystemDate  datetime;
  select  @LDT_SystemDate    = Getdate(),
          @IPVC_ErrorMessage = nullif(ltrim(rtrim(@IPVC_ErrorMessage)),'');

  ------------------------------------------
  Begin Try
    Update QBD
    Set    QBD.ProcessStatus       = @IPI_ProcessStatus,
           QBD.ProcessErrorMessage = @IPVC_ErrorMessage,
           QBD.ProcessEndDate      = @LDT_SystemDate,
           QBD.ModifiedByIDSeq     = @IPBI_UserIDSeq,
           QBD.ModifiedDate        = @LDT_SystemDate,
           QBD.SystemLogDate       = @LDT_SystemDate    
    from   QUEUEMANAGER.dbo.QueueBatchDetail QBD with (nolock)
    where  QBD.QBHIDSeq         = @IPBI_QBatchHeaderIDSeq
    and    QBD.QBDIDSeq         = @IPBI_QBatchDetailIDSeq
    and    QBD.ProcessStatus    = 5;
    --------------------------------------------
    --Sync Proc Call for Header Realtime Update
    --------------------------------------------    
    Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SyncStatsBatchHeader @IPBI_QBatchHeaderIDSeq = @IPBI_QBatchHeaderIDSeq;
    --------------------------------------------
  End  Try
  Begin Catch
    Exec QUEUEMANAGER.DBO.uspQUEUEMANAGER_RaiseError  @IPVC_CodeSection = 'Proc:uspQUEUEMANAGER_SetBatchDetailStatus. Batch Detail Process Status set Failed.'  
    return
  end   Catch;
END--> Main End
GO
