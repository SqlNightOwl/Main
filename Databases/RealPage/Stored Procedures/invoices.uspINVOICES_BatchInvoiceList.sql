SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_BatchInvoiceList]
-- Description     : This procedure returns the epicor batches
-- 
-- OUTPUT          : RecordSet of ID,CompanyName,CompanyIDSeq,
--                                StatusName,AccountIDSeq,CreatedDate,Period,LastInvoice
-- Revision History:
-- Author          : DCANNON
-- 5/1/2006      : Stored Procedure Created.
-- 4/6/2009		   : Naval Kishore Modified the SP to add paramater @IPB_EpicorFlag, defect#6259
-- 06/04/2009    : Altered for correct calculation of Gross Amount #6560
------------------------------------------------------------------------------------------------------
-- exec uspINVOICES_BatchInvoiceList 1, 8000, 'ARB0022737',1
CREATE PROCEDURE [invoices].[uspINVOICES_BatchInvoiceList] (@IPI_PageNumber       int, 
                                                       @IPI_RowsPerPage      int,                        
						                               @IPVC_EpicorBatchCode varchar(20),
													   @IPB_EpicorFlag bit
														) 
AS
BEGIN
  SELECT * FROM (
    ------------------------------------------------------------------------
   select top (@IPI_RowsPerPage * @IPI_PageNumber) 
                *, row_number()  over(order by EpicorBatchCode)   as RowNumber   
   from (select InvoiceIDSeq as LinkID, 'I' as Type, SentToEpicorStatus, SentToEpicorFlag,
                ILFChargeAmount + AccessChargeAmount + TransactionChargeAmount + ShippingAndHandlingAmount as GrossAmount, TaxAmount, 
                InvoiceDate  as ItemDate, EpicorBatchCode, SentToEpicorMessage
         from Invoices.dbo.Invoice with (nolock)
         where EpicorBatchCode = @IPVC_EpicorBatchCode
	 AND  (
				(@IPB_EpicorFlag = 1 and SentToEpicorFlag = 0 and SentToEpicorStatus is not null)
				OR
				(@IPB_EpicorFlag = 0)
				)
union
   select convert(varchar(20),CreditMemoIDSeq) as LinkID, 'C' as Type, SentToEpicorStatus, SentToEpicorFlag, 
          ILFCreditAmount + AccessCreditAmount + TransactionCreditAmount + ShippingAndHandlingCreditAmount as GrossAmount, TaxAmount, 
          RequestedDate as ItemDate, EpicorBatchCode, SentToEpicorMessage
   from Invoices.dbo.CreditMemo with (nolock)) as tbl
   where EpicorBatchCode = @IPVC_EpicorBatchCode
	 AND  (
			(@IPB_EpicorFlag = 1 and SentToEpicorFlag = 0 and SentToEpicorStatus is not null)
			OR
			(@IPB_EpicorFlag = 0)
		   )
) TBL_BP
    ------------------------------------------------------------------------
  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage    
  ----------------------------------------------------------------------------
END


GO
