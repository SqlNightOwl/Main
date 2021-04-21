SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : uspINVOICES_PrintBatchProcessList   
-- Description     : Selectes any Batch Print in process.
-- Input Parameters: @IPVC_InvoiceString varchar(8000)
--                     
-- Code Example    : Exec Invoices.dbo.uspINVOICES_PrintBatchProcessList null, 'SUB'
--   
-- Revision History:  
-- Author          : Bhavesh Shah
-- 08/07/2008      : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [invoices].[uspINVOICES_PrintBatchProcessList] 
(
  @IPI_IDSeq bigint = NULL
)
AS
BEGIN
  SET @IPI_IDSeq = NULLIF(@IPI_IDSeq, 0);
 
  SELECT 
    IDSeq
    , PrintDate
    , PrintedBy
    , Status
    , TotalCount
    , ProcessCount
    , ErrorCount
    , PrintedCount
  FROM
    Invoices.dbo.PrintBatch WITH (NOLOCK)
  Where
    IDSeq = COALESCE(@IPI_IDSeq, IDSeq)
    AND Status IN ('Submitted', 'Inprocess')
End
GO
