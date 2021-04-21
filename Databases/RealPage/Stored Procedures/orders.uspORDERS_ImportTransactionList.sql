SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspORDERS_ImportTransactionList]
-- Description     : This is the Main SP called for Listing Batch Headers
-- Input Parameters: @IPI_PageNumber,@IPI_RowsPerPage
--                   @IPI_ErroredBatchesOnly = 1 to filter and show only Errored Batches. 
--                                             0 will show all batches
-- Syntax          : Exec Orders.dbo.uspORDERS_ImportTransactionList @IPI_PageNumber = 1,@IPI_RowsPerPage=21,@IPI_ErroredBatchesOnly=0
--                   Exec Orders.dbo.uspORDERS_ImportTransactionList @IPI_PageNumber = 1,@IPI_RowsPerPage=21,@IPI_ErroredBatchesOnly=1
--                   Exec Orders.dbo.uspORDERS_ImportTransactionList @IPI_PageNumber = 1,@IPI_RowsPerPage=21,@IPVC_BatchName = 'niner'
--After DO Post    : Exec Orders.dbo.uspORDERS_ImportTransactionList @IPBI_BatchIDSeq=7
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 05/17/2010      : SRS (Defect 7491)
-- 08/24/2011      : Mahaboob ( Defect #717) Modified procedure to include batches with "BacthPostingStatusFlag" as 0 in RollBack Criteria.
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [orders].[uspORDERS_ImportTransactionList] (@IPI_PageNumber             int=1, 
                                                          @IPI_RowsPerPage            int=20,
                                                          @IPBI_BatchIDSeq            bigint      =0,
                                                          @IPVC_BatchName             varchar(255)='',
                                                          @IPVC_ImportedByUserIDSeq   bigint      =0,
                                                          @IPI_ErroredBatchesOnly     int = 0
                                                         )
AS
BEGIN 
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  -----------------------------------------------------
  declare @rowstoprocess bigint
  if (@IPI_RowsPerPage > 20)
  begin
    select  @IPI_RowsPerPage=20 --This is the maximum UI can show
  end
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  -----------------------------------------------------
  select @IPBI_BatchIDSeq = (case when (@IPBI_BatchIDSeq = 0 or isnumeric(@IPBI_BatchIDSeq) = 0) then NULL
                                  else  @IPBI_BatchIDSeq
                             end),
         @IPVC_ImportedByUserIDSeq = (case when  (@IPVC_ImportedByUserIDSeq = 0 or isnumeric(@IPVC_ImportedByUserIDSeq) = 0) then NULL
                                  else @IPVC_ImportedByUserIDSeq
                             end)



  -----------------------------------------------------
  ;WITH tablefinal AS
       (Select TIBH.[IDSeq]                                            as  TransactionImportIDSeq,
               TIBH.BatchName                                          as  BatchName,
               TIBH.EstimatedImportCount                               as  EstimatedImportCount,
               TIBH.EstimatedNetChargeAmount                           as  EstimatedNetChargeAmount,                                                 
               (Case when TIBH.BatchPostingStatusFlag in(1, 0)
                       then TIBH.ActualImportCount
                     else 0
                end)                                                   as  ActualImportCount,
               (Case when TIBH.BatchPostingStatusFlag in(1, 0)
                       then TIBH.TotalNetChargeAmount
                     else 0.00 
                end)                                                   as  TotalNetChargeAmount,
               

               TIBH.ErrorCount                                         as  ErrorCount,
               (case when TIBH.BatchPostingStatusFlag in (2,3)
                      then
                          TIBH.EstimatedNetChargeAmount     
                     else  0.00
                end)                                                  as  ErrorNetChargeAmount, 

               (case when TIBH.BatchPostingStatusFlag in(1, 0)
                      then  CONVERT(varchar(50),
                                        DATEADD(s,(datediff(ss,TIBH.CreatedDate,TIBH.ModifiedDate)),
                                               0),
                                    108) 
                     else '__:__:__'
               end)                                                    as  TotalTimeForImport,
               TIBH.ImportSource                                       as  ImportSource,
               TIBH.ImportedFileName                                   as  ImportedFileName,
               TIBH.BatchPostingStatusFlag                             as  BatchPostingStatusFlag, -- 1 means success,2 means failure,3 Means Rollback
               coalesce(TIBH.ErrorMessage,'')                          as  ErrorMessage,
               ltrim(rtrim(U.FirstName + ' ' + U.LastName))            as  ImportedByUserName,
               TIBH.CreatedDate                                        as  ImportDate,
               ltrim(rtrim(UR.FirstName + ' ' + UR.LastName))          as  RollBackByUserName,
               TIBH.RollbackDate                                       as  RollBackDate,            
               coalesce(R.ReasonName,'')                               as  RollBackReason, 
               row_number() OVER(ORDER BY TIBH.[IDSeq] desc)           as  [RowNumber],
               Count(1) OVER()                                         as  TotalBatchCountForPaging
        from   ORDERS.dbo.TransactionImportBatchHeader TIBH with (nolock)
        left outer join
               Security.dbo.[User] U with (nolock)
        on     TIBH.CreatedByIDSeq = U.IDSeq
        left outer join
               Security.dbo.[User] UR with (nolock)
        on     TIBH.RollBackByIDSeq = UR.IDSeq
        left outer Join
               ORDERS.dbo.Reason R with (nolock)
        on     TIBH.RollbackReasonCode = R.Code
        where  
		--TIBH.BatchPostingStatusFlag <> 0 and 
        ((@IPI_ErroredBatchesOnly=1 and TIBH.BatchPostingStatusFlag in(2,3))
                   OR
                (@IPI_ErroredBatchesOnly=0)
               )
        and   (TIBH.[IDSeq]        = coalesce(@IPBI_BatchIDSeq,TIBH.[IDSeq]))                  
        and   (TIBH.BatchName like '%' + @IPVC_BatchName + '%')              
        and   (TIBH.CreatedByIDSeq = coalesce(@IPVC_ImportedByUserIDSeq,TIBH.CreatedByIDSeq))
       )
  select tablefinal.TransactionImportIDSeq,
         tablefinal.BatchName,
         tablefinal.EstimatedImportCount,
         tablefinal.EstimatedNetChargeAmount,
         tablefinal.ActualImportCount,
         tablefinal.TotalNetChargeAmount,
         tablefinal.ErrorCount,
         tablefinal.ErrorNetChargeAmount,
         tablefinal.TotalTimeForImport,
         tablefinal.ImportSource,
         tablefinal.ImportedFileName,
         tablefinal.BatchPostingStatusFlag,
         tablefinal.ErrorMessage,
         tablefinal.ImportedByUserName,
         tablefinal.ImportDate,
         tablefinal.RollBackByUserName,
         tablefinal.RollBackDate,
         tablefinal.RollBackReason,
         tablefinal.TotalBatchCountForPaging
  from   tablefinal
  where  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
  -----------------------------------------------
END
GO
