SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_BatchInvoiceListCount]
-- Description     : This procedure returns the epicor batches
-- 
-- OUTPUT          : RecordSet of ID,CompanyName,CompanyIDSeq,
--                                StatusName,AccountIDSeq,CreatedDate,Period,LastInvoice
-- Revision History:
-- Author          : DCANNON
-- 5/1/2006      : Stored Procedure Created.
-- 4/6/2009		   : Naval Kishore Modified the SP to add paramater @IPB_EpicorFlag, defect#6259
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [invoices].[uspINVOICES_BatchInvoiceListCount] (@IPI_PageNumber       int, 
															@IPI_RowsPerPage      int,                        
						                                    @IPVC_EpicorBatchCode varchar(11),
															@IPB_EpicorFlag       bit) 
AS
BEGIN
  SELECT count(*) 
  FROM 
		(
		SELECT InvoiceIDSeq, SentToEpicorStatus, SentToEpicorFlag
		FROM Invoices.dbo.Invoice with (nolock)
		WHERE EpicorBatchCode = @IPVC_EpicorBatchCode
		AND  (
				(@IPB_EpicorFlag = 1 and SentToEpicorFlag = 0 and SentToEpicorStatus is not null)
				OR
				(@IPB_EpicorFlag = 0)
			 )   
 UNION
	    SELECT CreditMemoIDSeq, SentToEpicorStatus, SentToEpicorFlag
	    FROM  Invoices.dbo.CreditMemo with (nolock)
	    WHERE EpicorBatchCode = @IPVC_EpicorBatchCode
		AND  (
				(@IPB_EpicorFlag = 1 and SentToEpicorFlag = 0 and SentToEpicorStatus is not null)
				OR
				(@IPB_EpicorFlag = 0)
			 )
		)tbl
END


GO
