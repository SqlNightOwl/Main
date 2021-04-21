SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspInvoices_GeneratedInvoiceSelect1
-- Description     : This procedure gets the invoices that have been printed
-- Revision History:
-- Author          : DC
-- 12/28/2007        : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspInvoices_GeneratedInvoiceSelect1] (@IPI_PageNumber     int, 
                                                             @IPI_RowsPerPage    int,
                                                             @IPVC_CustomerIDSeq varchar(20),
                                                             @IPVC_AccountIDSeq  varchar(20),
                                                             @IPVC_StartDate     varchar(20),
                                                             @IPVC_EndDate       varchar(20),
												             @IPVC_PullListIDSeq varchar(20)
                                                             )
AS
BEGIN	
if (@IPVC_PullListIDSeq ='')
   Begin 
     WITH tablefinal AS 
     ----------------------------------------------------------  
      (SELECT tableinner.*
       FROM
          ---------------------------------------------------------- 
         (select  row_number() over(order by source.InvoiceIDSeq  
                                ) as RowNumber,
                  source.*
          from
         ---------------------------------------------------------- 
            (select distinct ivc.InvoiceIDSeq, ivc.CompanyIDSeq, isnull(PropertyName, CompanyName) as AccountName,
               CompanyName, ivc.AccountIDSeq, ILFChargeAmount,  AccessChargeAmount, TransactionChargeAmount,
               ivc.TaxAmount as TaxAmount, ILFChargeAmount + AccessChargeAmount + TransactionChargeAmount + ivc.TaxAmount as TotalAmount,
               doc.DocumentIDSeq,doc.DocumentPath
             from Invoices..Invoice ivc with (nolock)
              join Invoices..InvoiceItem ivcIt with (nolock) on ivc.InvoiceIDSeq=ivcIt.InvoiceIDSeq
              Join DOCUMENTS..[document] doc with (nolock) on doc.InvoiceIDSeq=ivc.InvoiceIDSeq 
              and doc.[Name] = 'Invoice' and doc.InvoiceIDSeq is not null and doc.PrintOnInvoiceFlag=1
             where ((@IPVC_CustomerIDSeq = '') or (ivc.CompanyIDSeq = @IPVC_CustomerIDSeq))
               and ((@IPVC_AccountIDSeq = '') or (ivc.AccountIDSeq = @IPVC_AccountIDSeq))
               AND
                 ((@IPVC_StartDate is not null and 
                    convert(varchar(12),ivcIt.BillingPeriodFromDate,101) >= @IPVC_StartDate)
                      or @IPVC_StartDate     = '')
                 AND
                 ((@IPVC_EndDate is not null and 
                    convert(varchar(12),ivcIt.BillingPeriodToDate,101) <= @IPVC_EndDate)
                      or @IPVC_EndDate = '')
         ---------------------------------------------------------------
            ) source
       --------------------------------------------------------------------
        )tableinner
          ------------------------------------------------------------------------
             WHERE tableinner.RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage    
             AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage    
        ----------------------------------------------------------------------------
      )
		 select InvoiceIDSeq, CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,ILFChargeAmount,AccessChargeAmount,
                TransactionChargeAmount,TaxAmount,TotalAmount,DocumentIDSeq,DocumentPath
         from   tablefinal
   END
ELSE

   Begin 
     WITH tablefinal AS 
     ----------------------------------------------------------  
      (SELECT tableinner.*
       FROM
       ---------------------------------------------------------- 
         (select  row_number() over(order by source.InvoiceIDSeq  
                                   ) as RowNumber,
                  source.*
          from
         ---------------------------------------------------------- 
           (   select distinct ivc.InvoiceIDSeq, ivc.CompanyIDSeq, isnull(PropertyName, CompanyName) as AccountName,
                 CompanyName, ivc.AccountIDSeq, ILFChargeAmount,  AccessChargeAmount, TransactionChargeAmount,
                 ivc.TaxAmount as TaxAmount, ILFChargeAmount + AccessChargeAmount + TransactionChargeAmount + ivc.TaxAmount as TotalAmount,
                 doc.DocumentIDSeq,doc.DocumentPath
               from Invoices..Invoice ivc with (nolock)
                join Invoices..InvoiceItem ivcIt with (nolock) on ivc.InvoiceIDSeq=ivcIt.InvoiceIDSeq
                join INVOICES.dbo.PullListAccounts pa with (nolock) on pa.AccountIDSeq = ivc.AccountIDSeq and PullListIDSeq=@IPVC_PullListIDSeq
                Join DOCUMENTS..[document] doc with (nolock) on doc.InvoiceIDSeq=ivc.InvoiceIDSeq 
                and doc.[Name] = 'Invoice' and doc.InvoiceIDSeq is not null and doc.PrintOnInvoiceFlag=1
             where ((@IPVC_CustomerIDSeq = '') or (ivc.CompanyIDSeq = @IPVC_CustomerIDSeq))
                and ((@IPVC_AccountIDSeq = '') or (ivc.AccountIDSeq = @IPVC_AccountIDSeq))
				and ((@IPVC_StartDate is not null and convert(varchar(12),ivcIt.BillingPeriodFromDate,101) >= @IPVC_StartDate)
                      or @IPVC_StartDate = '')
                and ((@IPVC_EndDate is not null and convert(varchar(12),ivcIt.BillingPeriodToDate,101) <= @IPVC_EndDate)
                      or @IPVC_EndDate = '')
              ---------------------------------------------------------------
            ) source
            --------------------------------------------------------------------
          )tableinner
          ------------------------------------------------------------------------
             WHERE tableinner.RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage    
             AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage    
        ----------------------------------------------------------------------------
        )
          select InvoiceIDSeq,CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,ILFChargeAmount,AccessChargeAmount,
                 TransactionChargeAmount,TaxAmount,TotalAmount,DocumentIDSeq,DocumentPath
          from   tablefinal 
   END
 
----------------------------------------------------------------------------
-- Retrieving the Count (Number Of Output Records)
----------------------------------------------------------------------------
if (@IPVC_PullListIDSeq ='')
   Begin 
     select distinct count( distinct doc.DocumentIDSeq)--, sum(ILFChargeAmount + AccessChargeAmount + TransactionChargeAmount + ivc.TaxAmount)
     from Invoices..Invoice ivc with (nolock)
              join Invoices..InvoiceItem ivcIt with (nolock) on ivc.InvoiceIDSeq=ivcIt.InvoiceIDSeq
              Join DOCUMENTS..[document] doc with (nolock) on doc.InvoiceIDSeq=ivc.InvoiceIDSeq 
              and doc.[Name] = 'Invoice' and doc.InvoiceIDSeq is not null and doc.PrintOnInvoiceFlag=1
             where ((@IPVC_CustomerIDSeq = '') or (ivc.CompanyIDSeq = @IPVC_CustomerIDSeq))
               and ((@IPVC_AccountIDSeq = '') or (ivc.AccountIDSeq = @IPVC_AccountIDSeq))
               AND
                 ((@IPVC_StartDate is not null and 
                    convert(varchar(12),ivcIt.BillingPeriodFromDate,101) >= @IPVC_StartDate)
                      or @IPVC_StartDate     = '')
                 AND
                 ((@IPVC_EndDate is not null and 
                    convert(varchar(12),ivcIt.BillingPeriodToDate,101) <= @IPVC_EndDate)
                      or @IPVC_EndDate = '')
   End
else
   Begin
     select distinct count(distinct doc.DocumentIDSeq)--, sum(ILFChargeAmount + AccessChargeAmount + TransactionChargeAmount + ivc.TaxAmount)
     from Invoices..Invoice ivc with (nolock)
                join Invoices..InvoiceItem ivcIt with (nolock) on ivc.InvoiceIDSeq=ivcIt.InvoiceIDSeq
                join INVOICES.dbo.PullListAccounts pa with (nolock) on pa.AccountIDSeq = ivc.AccountIDSeq and PullListIDSeq=@IPVC_PullListIDSeq
                Join DOCUMENTS..[document] doc with (nolock) on doc.InvoiceIDSeq=ivc.InvoiceIDSeq 
                and doc.[Name] = 'Invoice' and doc.InvoiceIDSeq is not null and doc.PrintOnInvoiceFlag=1
             where ((@IPVC_CustomerIDSeq = '') or (ivc.CompanyIDSeq = @IPVC_CustomerIDSeq))
                and ((@IPVC_AccountIDSeq = '') or (ivc.AccountIDSeq = @IPVC_AccountIDSeq))
				and ((@IPVC_StartDate is not null and convert(varchar(12),ivcIt.BillingPeriodFromDate,101) >= @IPVC_StartDate)
                      or @IPVC_StartDate = '')
                and ((@IPVC_EndDate is not null and convert(varchar(12),ivcIt.BillingPeriodToDate,101) <= @IPVC_EndDate)
                      or @IPVC_EndDate = '')
   end
 

END

--Exec Invoices.dbo.uspInvoices_GeneratedInvoiceSelect1 1,400, '', '', '', '',''

GO
