SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_SetBatchDetail
-- Description     : Creates a Batch Detail Record pertaining to Main Batch Record.
--                   This call will be called for every input Request to the batch
--                   It could be 1 or 2 or as many as there are detailed request(s) for the Main Batch
-- Input Parameters: 
-- Returns         : RecordSet of Unique Batch Detail ID. The calling program may not catch this and use it immediately though
--                   But will by the call of uspQUEUEMANAGER_ValidateBatchDetail down the line by calling WCF. 

--                   Upon Successful Creation of Batch Detail Record, Returns a valid positive number QBatchDetailIDSeq
--                   Upon error, SP will return Error Message and NULL as QBatchDetailIDSeq, which has to be trapped by Calling program.



-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SetBatchDetail 
                                   @IPI_QueueTypeIDSeq          = 1,
                                   @IPBI_QBatchHeaderIDSeq      = 1,
                                   @IPVC_BatchDetailDescription = 'Sample Batch Detail',
                                   @IPXML_CommandXML            = '<param>...</param>',
                                   @IPBI_UserIDSeq              = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_SetBatchDetail] (@IPI_QueueTypeIDSeq             int,                ---> MANDATORY: This is the Queue TypeIDSeq For the batch Header Request previously submitted through call of uspQUEUEMANAGER_SetBatchHeader.
                                                         @IPBI_QBatchHeaderIDSeq         bigint,             ---> MANDATROY: This is not null positive whole number value of QBatchHeaderIDSeq For the batch Header Request previously returned through call of uspQUEUEMANAGER_SetBatchHeader.
                                                         @IPVC_BatchDetailDescription    varchar(255) = '',  ---> Optional : This is the Batch Detail User identifiable description. Default is blank.
                                                         @IPXML_CommandXML               XML          =NULL, ---> Optional: This is the Command XML or Parameter XML with Identifiable information for the MSMQ
                                                         @IPBI_UserIDSeq                 bigint       =-1    ---> MANDATORY : User ID of the User Logged on and doing the operation or the person submitting the Batch.
                                                                                                             ---    UI or application will know the userid who submits this Batch.
                                                        )
as
BEGIN --> Main Begin
  set nocount on;
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500);  
  select  @IPVC_BatchDetailDescription = nullif(ltrim(rtrim(@IPVC_BatchDetailDescription)),''),
          @IPXML_CommandXML            = nullif(ltrim(rtrim(convert(varchar(max),@IPXML_CommandXML))),''),
          @LDT_SystemDate              = Getdate();
  ------------------------------------------
  Begin Try
    Insert into QUEUEMANAGER.dbo.QueueBatchDetail(QBHIDSeq,
                                                  QTypeIDSeq,
                                                  QBDDescription,
                                                  CommandXML,
                                                  ProcessStatus,
                                                  CreatedByIDSeq,
                                                  CreatedDate,
                                                  SystemLogDate
                                                 )
    ---------------------------------------------------
    OUTPUT INSERTED.QBHIDSeq                   as QBatchHeaderIDSeq,
           INSERTED.QBDIDSeq                   as QBatchDetailIDSeq
    ---------------------------------------------------
    select  @IPBI_QBatchHeaderIDSeq            as QBHIDSeq 
           ,@IPI_QueueTypeIDSeq                as QTypeIDSeq
           ,@IPVC_BatchDetailDescription       as QBDDescription
           ,@IPXML_CommandXML                  as CommandXML
           ,0                                  as ProcessStatus
           ,@IPBI_UserIDSeq                    as CreatedByIDSeq
           ,@LDT_SystemDate                    as CreatedDate
           ,@LDT_SystemDate                    as SystemLogDate;

   --------------------------------------------
   --Sync Proc Call for Header Realtime Update
   --------------------------------------------    
   Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_SyncStatsBatchHeader @IPBI_QBatchHeaderIDSeq = @IPBI_QBatchHeaderIDSeq;
   --------------------------------------------   
  End  Try
  Begin Catch
    Exec QUEUEMANAGER.DBO.uspQUEUEMANAGER_RaiseError  @IPVC_CodeSection = 'Proc:uspQUEUEMANAGER_SetBatchDetail. Batch Detail Creation Failed.'
    select null as QBatchHeaderIDSeq,null as QBatchDetailIDSeq
    return
  end   Catch;

END--> Main End
GO
