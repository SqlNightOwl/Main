SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : uspINVOICES_BatchProcessUpdate  
-- 
-- Description     : Updates BatchProcess table with specified parameters.  Pass Null for parameters
--                   that do not need update.
--
-- Input Parameters: 
--                    @IPVC_EpicorBatchCode varchar(50)
--                    @IPVC_BatchType varchar(50)
--                    @IPVC_Status varchar(50)
--                    @IPI_InvoiceCount int
--                    @IPI_SuccessCount int
--                    @IPI_FailureCount int
--                    @IPD_CreatedDate datetime
--                    @IPBI_CreatedByIDSeq bigint
--                    @IPVC_CreatedBy varchar(100)
--                    @IPD_StartDate datetime
--                    @IPD_EndDate datetime
--
-- Returns         : Updated Record.
--                     
-- Code Example    : Exec uspINVOICES_BatchProcessUpdate @IPVC_EpicorBatchCode='', @IPI_ProcessCount=0, @IPVC_ErrorMessage=''
--   
-- Revision History:  
-- Author          : Bhavesh Shah
-- 08/12/2008      : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [invoices].[uspINVOICES_BatchProcessUpdate] 
(
  @IPVC_EpicorBatchCode varchar(50)
  , @IPVC_BatchType varchar(50) = NULL
  , @IPVC_Status varchar(50) = NULL
  , @IPI_InvoiceCount int = NULL
  , @IPI_SuccessCount int = NULL
  , @IPI_ProcessCount int = NULL
  , @IPI_FailureCount int = NULL
  , @IPD_CreatedDate datetime = NULL
  , @IPBI_CreatedByIDSeq bigint = NULL
  , @IPVC_CreatedBy varchar(100) = NULL
  , @IPD_StartDate datetime = NULL
  , @IPD_EndDate datetime = NULL
  , @IPVC_ErrorMessage varchar(MAX) = NULL
)
AS
BEGIN
  UPDATE INVOICES.DBO.BatchProcess SET 
    BatchType = ISNULL(@IPVC_BatchType, BatchType)
    , [Status] = ISNULL(@IPVC_Status, [Status])
    , InvoiceCount = ISNULL(@IPI_InvoiceCount, InvoiceCount)
    , SuccessCount = ISNULL(@IPI_SuccessCount, SuccessCount)
    , ProcessCount = ISNULL(@IPI_ProcessCount, ProcessCount)
    , FailureCount = ISNULL(@IPI_FailureCount, FailureCount)
    , CreatedDate = ISNULL(@IPD_CreatedDate, CreatedDate)
    , CreatedByIDSeq = ISNULL(@IPBI_CreatedByIDSeq, CreatedByIDSeq)
    , CreatedBy = ISNULL(@IPVC_CreatedBy, CreatedBy)
    , StartDate = ISNULL(@IPD_StartDate, StartDate)
    , EndDate = ISNULL(@IPD_EndDate, EndDate)
    , ErrorMessage = ISNULL(@IPVC_ErrorMessage, ErrorMessage)
  OUTPUT 
    INSERTED.EpicorBatchCode
    , INSERTED.BatchType
    , INSERTED.Status
    , INSERTED.InvoiceCount
    , INSERTED.SuccessCount
    , INSERTED.ProcessCount
    , INSERTED.FailureCount
    , INSERTED.CreatedDate
    , INSERTED.CreatedByIDSeq
    , INSERTED.CreatedBy
    , INSERTED.StartDate
    , INSERTED.EndDate
    , INSERTED.ErrorMessage
  Where
    EpicorBatchCode = @IPVC_EpicorBatchCode
End
GO
