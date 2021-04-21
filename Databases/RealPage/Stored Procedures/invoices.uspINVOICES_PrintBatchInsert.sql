SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES
--
-- Procedure Name  : uspINVOICES_PrintBatchInsert   
--
-- Description     : Inserts new record into PrintBatch table.
--
-- Input Parameters: @IPVC_InvoiceString varchar(8000)
--
-- Returns         : IDSeq for New record.
--                     
-- Code Example    : Exec Invoices.dbo.uspINVOICES_PrintBatchInsert 'Some User', 'SUB'
--   
-- Revision History:  
-- Author          : Bhavesh Shah
-- 08/07/2008      : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [invoices].[uspINVOICES_PrintBatchInsert] 
(
  @IPVC_PrintedBy varchar(255)
  , @IPC_Status varchar(20) = 'Submitted'
  , @IPD_PrintDate datetime = NULL
  , @IPI_TotalCount bigint = NULL
  , @IPI_ProcessCount bigint = NULL
  , @IPI_ErrorCount bigint = NULL
  , @IPI_PrintedCount bigint = NULL
  , @IPD_EndDate datetime = NULL
)
AS
BEGIN
  INSERT INTO INVOICES.DBO.PrintBatch
    (PrintedBy, PrintDate, [Status], TotalCount, ProcessCount, ErrorCount, PrintedCount, EndDate)
  OUTPUT
    INSERTED.IDSeq as IDSeq
  VALUES
    ( @IPVC_PrintedBy, COALESCE(@IPD_PrintDate, getDate()), @IPC_Status, @IPI_TotalCount, @IPI_ProcessCount
      , @IPI_ErrorCount, @IPI_PrintedCount, COALESCE(@IPD_EndDate, getDate()))
End
GO
