SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetSiteInvoiceDetails]
-- Description     : This procedure gets Order Details pertaining to passed AccountID
-- Input Parameters: 1. @IPI_AccountID   as integer
--                   2. @IPI_PageNumber  as integer
--                   3. @IPI_RowsPerPage as integer
-- 
-- OUTPUT          : RecordSet of OrderID,Status,CustomerID,CustomerName,AccountID,
--                                AccountName,OrderDate,OrderPeriod,LastInvoice,RowNumber
-- Code Example    : Exec CUSTOMERS.DBO.[uspCUSTOMERS_GetSiteInvoiceDetails] @IPI_AccountID  =1,
--                                                                   @IPI_PageNumber =3,
--                                                                   @IPI_RowsPerPage=20    
-- 
-- 
-- Revision History:
-- Author          : STA
-- 12/07/2006      : Stored Procedure Created.
-- 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetSiteInvoiceDetails] (
                                                         @IPI_PageNumber    int, 
                                                         @IPI_RowsPerPage   int,
                                                         @IPI_AccountID     varchar(20) 
                                                         ) 
AS
BEGIN 
--------------------------------------------------------------------------------------------
SELECT * FROM
  (
    SELECT TOP        (@IPI_PageNumber * @IPI_RowsPerPage)       
                        I.InvoiceIDSeq                                  as InvoiceIDSeq,
                        C.Name                                          as CustomerName,
                        case when isnull(convert(numeric(10,2),
                          isnull(I.ILFChargeAmount,0)
                            + isnull(I.AccessChargeAmount,0)
                              + isnull(I.TransactionChargeAmount,0)
                                + isnull(I.TaxAmount,0) 
                                  - isnull(I.CreditAmount,0)),0) < 0 
                          then 0 
                        else
                          isnull(convert(numeric(10,2),
                            isnull(I.ILFChargeAmount,0)
                              + isnull(I.AccessChargeAmount,0)
                                + isnull(I.TransactionChargeAmount,0)
                                  + isnull(I.TaxAmount,0) 
                                    - isnull(I.CreditAmount,0)),0) 
                        end                                             as Amount,
                        IST.[Name]                                      as Status,
                        Convert(varchar(10), I.InvoiceDueDate,101)      as InvoiceDueDate,
                        Convert(varchar(10), I.InvoiceDate,101)         as InvoiceDate,
                        row_number() over(order by I.InvoiceIDSeq)      as RowNumber

      FROM            Invoices.dbO.[Invoice] I (nolock)

      LEFT OUTER JOIN Customers.dbO.Company c (nolock) 
        ON            I.CompanyIDSeq = c.IDSeq

      LEFT OUTER JOIN Invoices.dbo.InvoiceStatusType IST
        ON            I.StatusCode = IST.Code

      WHERE           I.AccountIDSeq = @IPI_AccountID
 
      AND             I.StatusCode = 'PENDG'

  )                   LT_ListOfInvoices
    
WHERE                 RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage 
  AND                 RowNumber <= (@IPI_PageNumber) * @IPI_RowsPerPage  
--------------------------------------------------------------------------------------------
SELECT 
                  COUNT(*) 
FROM
                  Invoices.dbO.[Invoice] I (NOLOCK)

LEFT OUTER JOIN   Customers.dbO.Company c (NOLOCK) 
  ON              I.CompanyIDSeq = c.IDSeq

LEFT OUTER JOIN   Invoices.dbo.InvoiceStatusType IST
  ON              I.StatusCode = IST.Code

WHERE             I.AccountIDSeq = @IPI_AccountID 
  AND             I.StatusCode = 'PENDG'
--------------------------------------------------------------------------------------------
END

GO
