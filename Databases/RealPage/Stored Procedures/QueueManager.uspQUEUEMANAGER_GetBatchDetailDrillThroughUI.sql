SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUEUEMANAGER
-- Procedure Name  : uspQUEUEMANAGER_GetBatchDetailDrillThroughUI
-- Description     : This is the Main UI Search Proc for Monitor Screen
-- Input Parameters: As below
-- Returns         : RecordSet



-- Code Example    : 
/*
Exec QUEUEMANAGER.dbo.uspQUEUEMANAGER_GetBatchDetailDrillThroughUI 
                                   @IPI_PageNumber          = 1,
                                   @IPI_RowsPerPage         = 20,
                                   @IPBI_QBatchHeaderIDSeq  = 1,
                                   @IPI_QueueTypeIDSeq      = 1
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 1037
------------------------------------------------------------------------------------------------------
Create PROCEDURE [QueueManager].[uspQUEUEMANAGER_GetBatchDetailDrillThroughUI] (@IPI_PageNumber                  int        =1,          ---> This is Page Number. Default is 1 and based on user click on page number.
                                                                       @IPI_RowsPerPage                 int        =999999999,  ---> This is number of records that a single page can accomodate. UI will pass 24. For Excel Export 999999999.
                                                                       @IPBI_QBatchHeaderIDSeq          bigint,                 ---> MANDATORY : UI will pass corresponding Queue Batch HeaderID of the record From the main page -->More for drill through 
                                                                       @IPI_QueueTypeIDSeq              int                     ---> MANDATORY : UI will pass corresponding QueueTypeIDSeq of the record From the main page -->More for drill through 
                                                                      )
as
BEGIN --> Main Begin
  set nocount on;  
  -----------------------------------------------------
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)* @IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  -----------------------------------------------------  
  ;with CTE_BDDrillThro(QBDIDSeq,QBDDescription,
                        QBDCreatedDate,
                        QBDStatus,QBDProcessStartDate,QBDProcessEndDate,
                        [RowNumber],TotalBatchCountForPaging
                     )
   as (select QBD.QBDIDSeq                       as QBDIDSeq
             ,QBD.QBDDescription                 as QBDDescription             
             ,QBD.CreatedDate                    as QBDCreatedDate
             ,QS.[Name]                          as QBDStatus
             ,QBD.ProcessStartDate               as QBDProcessStartDate
             ,QBD.ProcessEndDate                 as QBDProcessEndDate
              ,row_number() OVER(ORDER BY QBD.[QBDIDSeq] asc)
                                                 as  [RowNumber]
              ,Count(1) OVER()                   as  TotalBatchCountForPaging 
       from   QUEUEMANAGER.dbo.QueueBatchDetail QBD with (nolock)
       inner join
              QUEUEMANAGER.dbo.QueueStatus      QS  with (nolock)
       on     QBD.ProcessStatus        = QS.Status
       and    QBD.QBHIDSeq             = @IPBI_QBatchHeaderIDSeq    
       and    QBD.QTypeIDSeq           = @IPI_QueueTypeIDSeq       
       where  QBD.QBHIDSeq             = @IPBI_QBatchHeaderIDSeq    
       and    QBD.QTypeIDSeq           = @IPI_QueueTypeIDSeq 
      )
  select tablefinal.QBDIDSeq                   as  RequestDetailID            ---> UI will show this as Request ID
        ,tablefinal.QBDDescription             as  RequestDetailDescription   ---> UI will show this as User Request Description
        ,tablefinal.QBDCreatedDate             as  RequestDetailSubmittedDate ---> UI will display this as Submitted Date
        ,tablefinal.QBDStatus                  as  RequestProcessStatus       ---> UI will display this as Status
        ,tablefinal.QBDProcessStartDate        as  RequestProcessStartDate    ---> UI will display this as Process Start Date
        ,tablefinal.QBDProcessEndDate          as  RequestProcessEndDate      ---> UI will display this as Process End Date
        ,tablefinal.TotalBatchCountForPaging   as  TotalBatchCountForPaging   ---> This is used by UI for Pagination
  from  CTE_BDDrillThro tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage
  order by tablefinal.RowNumber asc;
END--> Main End
GO
