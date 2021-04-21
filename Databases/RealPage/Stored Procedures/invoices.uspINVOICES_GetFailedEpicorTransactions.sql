SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_GetFailedEpicorTransactions
-- Description     : This procedure returns the failed epicor transactions
-- 
-- OUTPUT          : RecordSet of Type,Invoice Or Credit Number, Failed Batch Number , Failed Sent Date,
--								  Error Message, Resolved Batch Number, Resolved Sent Date
-- Code Example    : INVOICES.dbo.uspINVOICES_GetFailedEpicorTransactions @IPI_PageNumber=1,@IPI_RowsPerPage=22
-- Revision History:
-- Author          : SKONDAPALLI
-- 01/12/2010      : Stored Procedure Created.
-- 08/05/2011	   : Surya Kondapalli - Task # 912	Epicor batch sent date is incorrect in Failed Transactions History 
--													modal of Send to Epicor
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetFailedEpicorTransactions] 
													(  
													   @IPI_PageNumber			INT,    
                                                       @IPI_RowsPerPage			INT,
													   @IPVC_EpicorBatchCode    VARCHAR(50) = '',
                                                       @IPVC_StartDate          DATETIME = '01/01/1900',     
                                                       @IPVC_EndDate            DATETIME = '01/01/1900',   
                                                       @IPVC_Type               VARCHAR(50)='' --> Possible Values are '' for all, 'INVOICE', 'CREDIT','REVERSE CREDIT'
                                                    )  WITH RECOMPILE
AS
BEGIN
SET NOCOUNT ON;          
  
  DECLARE @rowstoprocess BIGINT  
  SELECT  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage  
  SET ROWCOUNT @rowstoprocess;
  
   IF (@IPVC_EpicorBatchCode = '')
	SET @IPVC_EpicorBatchCode = NULL
	
  IF (@IPVC_EndDate = '01/01/1900')
	SET @IPVC_EndDate = GETDATE()
  
  IF (@IPVC_Type = '')
	SET @IPVC_Type = NULL
  
  ;WITH tablefinal AS  
         (
  
		  SELECT	BPD.BatchType											AS [Type]
				  , CASE WHEN BPD.BatchType = 'Invoice' 
							 THEN BPD.InvoiceIDSeq 
						 ELSE BPD.CreditMemoIDSeq END						AS [Invoice/Credit ID #]
				  ,	BPD.EpicorBatchCode										AS [Failed Batch Number]
				  ,	CONVERT(VARCHAR(20),BP.EndDate,101)						AS [Failed Sent Date] 
				  ,	BPD.SentToEpicorFailureMessage							AS [Error Message]
				  ,	CASE WHEN T.SentToEpicorFlag = 1 
							 THEN T.EpicorBatchCode
						 ELSE '' END										AS [Resolved Batch Number]
				  ,	CASE WHEN T.SentToEpicorFlag = 1 
							THEN CONVERT(VARCHAR(20),T.EndDate,101)
						 ELSE '' END										AS [Resolved Sent Date]
				  ,	ROW_NUMBER() OVER(ORDER BY	BPD.EpicorBatchCode, 
										CASE WHEN BPD.BatchType = 'Invoice' 
												THEN BPD.InvoiceIDSeq 
											 ELSE BPD.CreditMemoIDSeq END	
									 )										AS RowNumber  
                  , COUNT(1) OVER()                                         AS TotalCountForPaging -- UI to use the value of this column in the very first row for paging.No need for separate extra costly count(*)  
		  FROM		Invoices.dbo.BatchProcess 				BP WITH (NOLOCK)			
		  JOIN		Invoices.dbo.BatchProcessDetail		   BPD WITH (NOLOCK) 
					ON   BP.EpicorBatchCode = BPD.EpicorBatchCode
		  LEFT JOIN (  SELECT I.SentToEpicorFlag
							, I.SentToEpicorStatus
							, I.InvoiceIDSeq
							, I.EpicorBatchCode
							, BP1.EndDate
						FROM   Invoices.dbo.Invoice			I WITH (NOLOCK)
						JOIN   Invoices.dbo.BatchProcess  BP1 WITH (NOLOCK) 
							   ON BP1.EpicorBatchCode = I.EpicorBatchCode
					) T 
					ON T.InvoiceIDSeq = BPD.InvoiceIDSeq
		  WHERE BPD.CreditMemoIDSeq IS NULL 
		   AND  (BPD.EpicorBatchCode = COALESCE(@IPVC_EpicorBatchCode,BPD.EpicorBatchCode))
		   AND  (BPD.BatchType = COALESCE(@IPVC_Type, BPD.BatchType))
		   AND  (CONVERT(INT, CONVERT(VARCHAR(10), T.EndDate, 112)) BETWEEN CONVERT(INT, CONVERT(VARCHAR(10), @IPVC_StartDate, 112)) AND CONVERT(INT, CONVERT(VARCHAR(10), @IPVC_EndDate, 112)))
				      
		  UNION ALL
		  SELECT	BPD.BatchType											AS [Type]
				  , CASE WHEN BPD.BatchType = 'Invoice' 
							THEN BPD.InvoiceIDSeq 
						 ELSE BPD.CreditMemoIDSeq END						AS [Invoice/Credit ID #]
				  ,	BPD.EpicorBatchCode										AS [Failed Batch Number]
				  ,	CONVERT(VARCHAR(20),BP.EndDate,101)						AS [Failed Sent Date] 
				  ,	BPD.SentToEpicorFailureMessage							AS [Error Message]
				  ,	CASE WHEN T.SentToEpicorFlag = 1 
							THEN T.EpicorBatchCode
						 ELSE '' END										AS [Resolved Batch Number]
				  ,	CASE WHEN T.SentToEpicorFlag = 1 
							THEN CONVERT(VARCHAR(20),T.EndDate,101)
						 ELSE '' END										AS [Resolved Sent Date]
				  ,	ROW_NUMBER() OVER(ORDER BY	BPD.EpicorBatchCode, 
										CASE WHEN BPD.BatchType = 'Invoice' 
												THEN BPD.InvoiceIDSeq 
											 ELSE BPD.CreditMemoIDSeq END	
									 )										AS RowNumber  
                  , COUNT(1) OVER()                                         AS TotalCountForPaging -- UI to use the value of this column in the very first row for paging.No need for separate extra costly count(*)  
		  FROM		Invoices.dbo.BatchProcess				BP WITH (NOLOCK)			
		  JOIN		Invoices.dbo.BatchProcessDetail		   BPD WITH (NOLOCK) 
					ON   BP.EpicorBatchCode = BPD.EpicorBatchCode
		  LEFT JOIN (  SELECT C.SentToEpicorFlag
							, C.SentToEpicorStatus
							, C.CreditMemoIDSeq
							, C.EpicorBatchCode
							, BP1.EndDate
						FROM   Invoices.dbo.CreditMemo		C WITH (NOLOCK)
						JOIN   Invoices.dbo.BatchProcess  BP1 WITH (NOLOCK) 
						ON BP1.EpicorBatchCode = C.EpicorBatchCode
					) T 
					ON T.CreditMemoIDSeq = BPD.CreditMemoIDSeq
		  WHERE BPD.CreditMemoIDSeq IS NOT NULL 
		  AND  (BPD.BatchType = COALESCE(@IPVC_Type, BPD.BatchType))
		  AND  (BPD.EpicorBatchCode = COALESCE(@IPVC_EpicorBatchCode,BPD.EpicorBatchCode))
		  AND  (CONVERT(INT, CONVERT(VARCHAR(10), T.EndDate, 112)) BETWEEN CONVERT(INT, CONVERT(VARCHAR(10), @IPVC_StartDate, 112)) AND CONVERT(INT, CONVERT(VARCHAR(10), @IPVC_EndDate, 112)))
			         
		)
		
		SELECT *  
		FROM   tablefinal  
		WHERE  tablefinal.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage  
		AND    tablefinal.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage  
		ORDER BY [Failed Batch Number], [Invoice/Credit ID #]
  
  
END
GO
