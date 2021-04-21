SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : uspINVOICES_PrintBatchUpdate  
-- 
-- Description     : Updates PrintBatch table with specified parameters.  Pass Null for parameters
--                   that do not need update.
--
-- Input Parameters: @IPVC_InvoiceString varchar(8000)
--
-- Returns         : IDSeq for all updated records.  If not record is updated then it will return null.
--                     
-- Code Example    : Exec Invoices.dbo.uspINVOICES_PrintBatchUpdate @IPI_IDSeq=80, @IPI_ProcessCount=1, @IPC_StatusCode='INP'
--   
-- Revision History:  
-- Author          : Bhavesh Shah
-- 08/07/2008      : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [invoices].[uspINVOICES_PrintBatchUpdate] 
(
  @IPI_IDSeq bigint
  , @IPVC_PrintedBy varchar(255) = NULL
  , @IPC_Status varchar(20) = NULL
  , @IPI_TotalCount bigint = NULL
  , @IPI_ProcessCount bigint = NULL
  , @IPI_ErrorCount bigint = NULL
  , @IPI_PrintedCount bigint = NULL
  , @IPD_PrintDate datetime = NULL
  , @IPD_EndDate datetime = NULL
)
AS
BEGIN
  UPDATE INVOICES.DBO.PrintBatch SET 
    PrintedBy = COALESCE( @IPVC_PrintedBy, PrintedBy), 
    PrintDate = COALESCE( @IPD_PrintDate, PrintDate), 
    [Status] = COALESCE( @IPC_Status, [Status]), 
    TotalCount = COALESCE( @IPI_TotalCount, TotalCount), 
    ProcessCount = COALESCE( @IPI_ProcessCount, ProcessCount), 
    ErrorCount = COALESCE( @IPI_ErrorCount, ErrorCount), 
    PrintedCount = COALESCE( @IPI_PrintedCount, PrintedCount),
    EndDate = CASE 
                WHEN @IPD_EndDate IS NULL THEN  CASE COALESCE( @IPC_Status, [Status]) 
                                                  WHEN 'Completed' THEN getDate()
                                                  WHEN 'Failed' THEN getDate()
                                                  ELSE NULL
                                                END
                ELSE @IPD_EndDate 
              END
  OUTPUT 
    INSERTED.IDSeq
    , INSERTED.PrintedBy 
    , INSERTED.PrintDate
    , INSERTED.[Status]
    , INSERTED.TotalCount
    , INSERTED.ProcessCount
    , INSERTED.ErrorCount
    , INSERTED.PrintedCount
  Where
    IDSeq = @IPI_IDSeq
End
GO
