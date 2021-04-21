SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_GetOrderDetails
-- Description     : This procedure gets Order Details pertaining to passed AccountID
-- Input Parameters: 1. @IPI_AccountID   as integer
--                   2. @IPI_PageNumber  as integer
--                   3. @IPI_RowsPerPage as integer
-- 
-- OUTPUT          : RecordSet of OrderID,Status,CustomerID,CustomerName,AccountID,
--                                AccountName,OrderDate,OrderPeriod,LastInvoice,RowNumber
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_GetOrderDetails @IPI_AccountID  ='A0810000047',
--                                                                   @IPI_PageNumber =3,
--                                                                   @IPI_RowsPerPage=20    
-- 
-- 
-- Revision History:
-- Author          : STA
-- 12/07/2006      : Stored Procedure Created.
-- 29/11/2007      : Naval Kishore Modified the Sp to get invoiceitem.level.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetInvoiceDetailsByProduct] (@IPI_AccountID     varchar(20), 
                                                         @IPI_PageNumber    int, 
                                                         @IPI_RowsPerPage   int
                                                         ) 
AS
BEGIN 
----------------------------------------------------------------------------
SELECT TOP (@IPI_RowsPerPage) * FROM
  (
  select top (@IPI_PageNumber * @IPI_RowsPerPage) * from
    (
    select  *, row_number() over(order by InvoiceDate desc) as RowNumber from
      (
        select          i.InvoiceIDSeq                            as InvoiceIDSeq,
                        prod.[DisplayName]                        as ProductName,
                        prod.[Code]                               as ProductCode,
                        c.Name                                    as CustomerName,
--                       case when isnull(convert(numeric(10,2),
--                  isnull(I.ILFChargeAmount,0)
--                    + isnull(I.AccessChargeAmount,0)
--                      + isnull(I.TransactionChargeAmount,0)
--                        + isnull(I.TaxAmount,0) 
--                          - isnull(I.CreditAmount,0)),0) < 0 then 0 else
--                      isnull(convert(numeric(10,2),
--                  isnull(I.ILFChargeAmount,0)
--                    + isnull(I.AccessChargeAmount,0)
--                      + isnull(I.TransactionChargeAmount,0)
--                        + isnull(I.TaxAmount,0) 
--                          - isnull(I.CreditAmount,0)),0) end          as Amount,

						
		  (convert(varchar(50),ii.BillingPeriodFromDate,101) 		
			+ ' - ' + convert(varchar(50),ii.BillingPeriodToDate,101))  as BillingPeriod,
		ii.ChargeTypeCode					AS ChargeTypeCode,	

--						 ISNULL( Quotes.DBO.fn_FormatCurrency(case when isnull(convert(numeric(10,2),
--                  isnull(I.ILFChargeAmount,0)
--                    + isnull(I.AccessChargeAmount,0)
--                      + isnull(I.TransactionChargeAmount,0)
--                        + isnull(I.TaxAmount,0) 
--                          - isnull(I.CreditAmount,0)),0) < 0 then 0 else
--                      isnull(convert(numeric(10,2),
--                  isnull(I.ILFChargeAmount,0)
--                    + isnull(I.AccessChargeAmount,0)
--                      + isnull(I.TransactionChargeAmount,0)
--                        + isnull(I.TaxAmount,0) 
--                          - isnull(I.CreditAmount,0)),0) end,2,2),'0')		as Amount,

				ISNULL( Quotes.DBO.fn_FormatCurrency(isnull(ii.NetChargeAmount,0)
                    + isnull(ii.TaxAmount,0) + isnull(ii.ShippingAndHandlingAmount,0) ,2,2),'0')		as Amount,

                        IST.[Name]                                as Status,
                        Convert(varchar(10),i.InvoiceDueDate,101) as InvoiceDueDate,
                        Convert(varchar(10),i.InvoiceDate,101)    as InvoiceDate
        from            Invoices.dbO.[Invoice] i with (nolock)

        left outer join Customers.dbO.Company c with (nolock)
          on            i.CompanyIDSeq = c.IDSeq

        left outer join Invoices.dbo.InvoiceStatusType IST with (nolock)
          ON            i.StatusCode = IST.Code

         left outer join Invoices.dbo.InvoiceItem ii with (nolock)
          on           ii.InvoiceIDSeq = i.InvoiceIDSeq
    
        left outer join Products.dbo.product prod with (nolock)
          on    prod.Code = ii.productCode
          and   prod.PriceVersion = ii.PriceVersion
        
        where           i.AccountIDSeq = @IPI_AccountID
--        order by ProductName

      )                 LT_InvoiceList

    )                   LT_ListOfInvoices
    
  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage 
    and RowNumber <= (@IPI_PageNumber) * @IPI_RowsPerPage
  )
AS RecordTable
ORDER BY ProductName
------------------------------------------------------------------------------
SELECT COUNT(*) as linecount from (
  SELECT  * from
    (
    select  *, row_number() over(order by InvoiceDate desc) as RowNumber from
      (
        select         i.InvoiceIDSeq                            as InvoiceIDSeq,
                        prod.[DisplayName]                        as ProductName,
                        prod.[Code]                               as ProductCode,
                        c.Name                                    as CustomerName,
--                       case when isnull(convert(numeric(10,2),
--                  isnull(I.ILFChargeAmount,0)
--                    + isnull(I.AccessChargeAmount,0)
--                      + isnull(I.TransactionChargeAmount,0)
--                        + isnull(I.TaxAmount,0) 
--                          - isnull(I.CreditAmount,0)),0) < 0 then 0 else
--                      isnull(convert(numeric(10,2),
--                  isnull(I.ILFChargeAmount,0)
--                    + isnull(I.AccessChargeAmount,0)
--                      + isnull(I.TransactionChargeAmount,0)
--                        + isnull(I.TaxAmount,0) 
--                          - isnull(I.CreditAmount,0)),0) end          as Amount,

						
		  (convert(varchar(50),ii.BillingPeriodFromDate,101) 		
			+ ' - ' + convert(varchar(50),ii.BillingPeriodToDate,101))  as BillingPeriod,
		ii.ChargeTypeCode					AS ChargeTypeCode,	

--						 ISNULL( Quotes.DBO.fn_FormatCurrency(case when isnull(convert(numeric(10,2),
--                  isnull(I.ILFChargeAmount,0)
--                    + isnull(I.AccessChargeAmount,0)
--                      + isnull(I.TransactionChargeAmount,0)
--                        + isnull(I.TaxAmount,0) 
--                          - isnull(I.CreditAmount,0)),0) < 0 then 0 else
--                      isnull(convert(numeric(10,2),
--                  isnull(I.ILFChargeAmount,0)
--                    + isnull(I.AccessChargeAmount,0)
--                      + isnull(I.TransactionChargeAmount,0)
--                        + isnull(I.TaxAmount,0) 
--                          - isnull(I.CreditAmount,0)),0) end,2,2),'0')		as Amount,

				ISNULL( Quotes.DBO.fn_FormatCurrency(isnull(ii.NetChargeAmount,0)
                    + isnull(ii.TaxAmount,0) + isnull(ii.ShippingAndHandlingAmount,0) ,2,2),'0')		as Amount,

                        IST.[Name]                                as Status,
                        Convert(varchar(10),i.InvoiceDueDate,101) as InvoiceDueDate,
                        Convert(varchar(10),i.InvoiceDate,101)    as InvoiceDate
        from            Invoices.dbO.[Invoice] i with (nolock)

        left outer join Customers.dbO.Company c with (nolock)
          on            i.CompanyIDSeq = c.IDSeq

        left outer join Invoices.dbo.InvoiceStatusType IST with (nolock)
          ON            i.StatusCode = IST.Code

         left outer join Invoices.dbo.InvoiceItem ii with (nolock)
          on           ii.InvoiceIDSeq = i.InvoiceIDSeq
    
        left outer join Products.dbo.product prod with (nolock)
          on    prod.Code = ii.productCode
          and   prod.PriceVersion = ii.PriceVersion
        
        where           i.AccountIDSeq = @IPI_AccountID
      )                 LT_InvoiceList

    )                   LT_ListOfInvoices
  
  )
AS RecordTable

END

GO
