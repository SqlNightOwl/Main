SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : uspINVOICES_GetPushBatchInProcess  
-- 
-- Description     : Selects in process batch record.
--
-- Input Parameters: 
--
-- Returns         : Inprocess Record.
--                     
-- Code Example    : Exec uspINVOICES_GetPushBatchInProcess
--   
-- Revision History:  
-- Author          : Bhavesh Shah
-- 08/12/2008      : Stored Procedure Created.  
-- 04/26/2011      : Surya Kondapalli - Task# 388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB  
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [invoices].[uspINVOICES_GetPushBatchInProcess] 
AS
BEGIN
  
Select	EpicorBatchCode
	,	BatchType
	,	[Status]
	,	InvoiceCount
	,	SuccessCount
	,	FailureCount
	,	CreatedDate
	,	CreatedByIDSeq
	,	CreatedBy
	,	StartDate
	,	EndDate
	,	ProcessCount
	,	ErrorMessage
	,	CanEpicorBatchCode
	,	CanBatchType
	,	CanStatus
	,	CanInvoiceCount
	,	CanSuccessCount
	,	CanFailureCount
	,	CanCreatedDate
	,	CanCreatedByIDSeq
	,	CanCreatedBy
	,	CanStartDate
	,	CanEndDate
	,	CanProcessCount
	,	CanErrorMessage
From	(
			Select Top 1
				  1					As	 RowNumber
				, EpicorBatchCode	As   EpicorBatchCode
				, BatchType			As   BatchType
				, [Status]			As   [Status]
				, InvoiceCount		As   InvoiceCount
				, SuccessCount		As   SuccessCount
				, FailureCount		As   FailureCount
				, CreatedDate		As   CreatedDate
				, CreatedByIDSeq	As   CreatedByIDSeq
				, CreatedBy			As   CreatedBy
				, StartDate			As   StartDate
				, EndDate			As   EndDate
				, ProcessCount		As   ProcessCount
				, ErrorMessage		As   ErrorMessage
			 From
				INVOICES.dbo.BatchProcess
			  Where [Status] IN ('EPICOR PUSH STARTED', 'EPICOR PUSH PENDING')
			  And  LTRIM(RTRIM(EpicorCompanyName)) = 'USD' ) AS USA
			Full Outer Join  
			(
			  Select Top 1
				  1					As   RowNumber
				, EpicorBatchCode	As   CanEpicorBatchCode
				, BatchType			As   CanBatchType
				, [Status]			As   CanStatus
				, InvoiceCount		As   CanInvoiceCount
				, SuccessCount		As   CanSuccessCount
				, FailureCount		As   CanFailureCount
				, CreatedDate		As   CanCreatedDate
				, CreatedByIDSeq	As   CanCreatedByIDSeq
				, CreatedBy			As   CanCreatedBy
				, StartDate			As   CanStartDate
				, EndDate			As   CanEndDate
				, ProcessCount		As   CanProcessCount
				, ErrorMessage		As   CanErrorMessage
			  From
				INVOICES.dbo.BatchProcess
			  Where [Status] IN ('EPICOR PUSH STARTED', 'EPICOR PUSH PENDING')
			  And  LTRIM(RTRIM(EpicorCompanyName))= 'CAD'
		) AS CAN On Can.RowNumber = USA.RowNumber
		
End
GO
