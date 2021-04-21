SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_GetBatchHeaderSummaryUI
-- Description     : This is the Main UI Search Proc for Monitor Screen
-- Input Parameters: As below
-- Returns         : RecordSet



-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_GetBatchHeaderSummaryUI 
                                   @IPI_PageNumber          = 1,
                                   @IPI_RowsPerPage         = 20,
                                   @IPBI_QBatchHeaderIDSeq  = 0,
                                   @IPI_QueueTypeIDSeq      = 0,
                                   @IPI_UserIDSeq           = 0
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_GetBatchHeaderSummaryUI] (@IPI_PageNumber                  int        =1,          ---> This is Page Number. Default is 1 and based on user click on page number.
                                                                  @IPI_RowsPerPage                 int        =999999999,  ---> This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                                  @IPBI_QBatchHeaderIDSeq          bigint     =0,          ---> UI will pass valid Queue Batch HeaderID if user happens to Key in a specific Batch Header ID in the Textbox search. Default is 0 for Nothing.
                                                                  @IPI_QueueTypeIDSeq              int        =0,          ---> UI will pass valid QueueTypeIDSeq if User selected from Drop down. Else for all QueueTypes, default is 0 for Nothing.
                                                                  @IPI_UserIDSeq                   bigint     =0           ---> UI will pass 0 as default for all Users, else valid Userid based on userID selection.
                                                                 )
as
BEGIN --> Main Begin
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  -----------------------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)* @IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  -----------------------------------------------------
  select @IPBI_QBatchHeaderIDSeq = (case when (@IPBI_QBatchHeaderIDSeq = 0 or isnumeric(@IPBI_QBatchHeaderIDSeq) = 0) then NULL
                                         else  @IPBI_QBatchHeaderIDSeq
                                    end),
         @IPI_QueueTypeIDSeq     = (case when (@IPI_QueueTypeIDSeq = 0 or isnumeric(@IPI_QueueTypeIDSeq) = 0) then NULL
                                         else  @IPI_QueueTypeIDSeq
                                    end),
         @IPI_UserIDSeq          = (case when (@IPI_UserIDSeq = 0 or isnumeric(@IPI_UserIDSeq) = 0) then NULL
                                         else  @IPI_UserIDSeq
                                    end);
  -----------------------------------------------------
  ;with CTE_BHSummary(QBHIDSeq,QTypeIDSeq,QTypeName,
                      QBHCreatedBy,QBHCreatedDate,
                      TotalSubmittedCount,TotalWaitingCount,TotalInProcessCount,TotalCompletedCount,TotalFailedCount,
                      QBHModifiedDate,[RowNumber],TotalBatchCountForPaging
                     )
   as (select QBH.QBHIDSeq                       as QBHIDSeq
             ,QBH.QTypeIDSeq                     as QTypeIDSeq
             ,QT.QTypeName                       as QTypeName
             ,UC.FirstName + ' ' + UC.LastName   as QBHCreatedBy  
             ,QBH.CreatedDate                    as QBHCreatedDate
             ,QBH.TotalSubmittedCount            as TotalSubmittedCount
             ,QBH.TotalWaitingCount              as TotalWaitingCount
             ,QBH.TotalInProcessCount            as TotalInProcessCount
             ,QBH.TotalCompletedCount            as TotalCompletedCount
             ,QBH.TotalFailedCount               as TotalFailedCount
             ,QBH.ModifiedDate                   as QBHModifiedDate
             ,row_number() OVER(ORDER BY QBH.[QBHIDSeq] desc)
                                                 as  [RowNumber]
              ,Count(1) OVER()                   as  TotalBatchCountForPaging 
       from   QUEUEMANAGER.dbo.QueueBatchHeader QBH with (nolock)
       inner join
              QUEUEMANAGER.dbo.QueueType        QT  with (nolock)
       on     QBH.QTypeIDSeq           = QT.QTypeIDSeq
       and    QBH.QBHIDSeq             = coalesce(@IPBI_QBatchHeaderIDSeq,QBH.QBHIDSeq)
       and    QT.QTypeIDSeq            = coalesce(@IPI_QueueTypeIDSeq,QT.QTypeIDSeq)
       and    QBH.QTypeIDSeq           = coalesce(@IPI_QueueTypeIDSeq,QBH.QTypeIDSeq) 
       left outer join
              SECURITY.dbo.[User] UC with (nolock)
       on     QBH.CreatedByIDSeq = UC.IDSeq
       and    UC.IDSeq           = coalesce(@IPI_UserIDSeq,UC.IDSeq)
       and    QBH.CreatedByIDSeq = coalesce(@IPI_UserIDSeq,QBH.CreatedByIDSeq)
       where  QBH.QBHIDSeq             = coalesce(@IPBI_QBatchHeaderIDSeq,QBH.QBHIDSeq)
       and    QT.QTypeIDSeq            = coalesce(@IPI_QueueTypeIDSeq,QT.QTypeIDSeq)
       and    QBH.QTypeIDSeq           = coalesce(@IPI_QueueTypeIDSeq,QBH.QTypeIDSeq) 
       and    (
                (@IPI_UserIDSeq is null)
                  OR
                (UC.IDSeq           = coalesce(@IPI_UserIDSeq,UC.IDSeq))
                     and 
                (QBH.CreatedByIDSeq = coalesce(@IPI_UserIDSeq,QBH.CreatedByIDSeq))
              )
      )
  select tablefinal.QBHIDSeq                   as  QueueBatchID             ---> UI will show this as Queue ID. Also retain it to send it as input parameter to Drill thro detail proc.
        ,tablefinal.QTypeIDSeq                 as  QTypeIDSeq               ---> UI will not display this. Will retain as hidden value to send it as input parameter to Drill thro detail proc.
        ,tablefinal.QTypeName                  as  QueueTypeName            ---> UI will display this as Queue Type 
        ,tablefinal.QBHCreatedBy               as  QueueSubmittedBy         ---> UI will display this as Submitted By
        ,tablefinal.QBHCreatedDate             as  QueueSubmittedDate       ---> UI will display this as Submitted Date
        ,tablefinal.TotalSubmittedCount        as  TotalSubmittedCount      ---> UI will display this as Submitted count  or Submitted
        ,tablefinal.TotalInProcessCount        as  TotalInProcessCount      ---> UI will display this as In Process count or In Process
        ,tablefinal.TotalCompletedCount        as  TotalCompletedCount      ---> UI will display this as Completed count  or Completed
        ,tablefinal.TotalFailedCount           as  TotalFailedCount         ---> UI will display this as Failed count     or Failed
        ,tablefinal.QBHModifiedDate            as  QueueLastProcessedDate   ---> UI will display this as Last Processed
        ,tablefinal.TotalBatchCountForPaging   as  TotalBatchCountForPaging --->This is used by UI for Pagination
  from  CTE_BHSummary tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
