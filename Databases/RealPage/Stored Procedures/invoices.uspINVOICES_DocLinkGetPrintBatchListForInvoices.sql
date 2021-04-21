SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
------------------------------------------------------------------------
Procedure  : uspINVOICES_DocLinkGetPrintBatchListForInvoices

Purpose    : Gets data from Invoices PrintBatch table and also
             Checking to see if PrintBatchIDSeq has atleast 1
             qualifying Invoice already printed,senttoepicor
             and ready to be pushed to DOCLink
             
Parameters : @IPI_PageNumber,@IPI_RowsPerPage

Returns    : All Qualifying Batches
Date         Author                  Comments
-------------------------------------------------------
01/19/2008   SRS              Initial Creation

Example: EXEC uspINVOICES_DocLinkGetPrintBatchListForInvoices

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
------------------------------------------------------------------------
*/     
CREATE Procedure [invoices].[uspINVOICES_DocLinkGetPrintBatchListForInvoices](@IPI_PageNumber      int=1,  
                                                                         @IPI_RowsPerPage     int=21  
                                                                        ) WITH RECOMPILE    
AS
BEGIN
  set nocount on;
  declare @rowstoprocess bigint
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  ----------------------------------------------------------------
  ;WITH tablefinalDocLinkInvoiceCount 
  AS (
      Select  I.BillingCycleDate                                   as InvoiceDate,
              count(distinct I.InvoiceIDSeq)                       as InvoiceCount,
              row_number() OVER(ORDER BY I.BillingCycleDate asc)   as  [RowNumber],
              Count(1) OVER()                                      as _TotalRows_ -- Adding this for Paging.  This will avoid multiple hits to table to get total count.  
      from    INVOICES.DBO.Invoice I with (nolock)
      inner join              
              DOCUMENTS.dbo.[document] doc with (nolock) 
      on      doc.InvoiceIDSeq   =I.InvoiceIDSeq              
      and     doc.InvoiceIDSeq   is not null
      and     doc.DocumentPath   is not null
      and     doc.ActiveFlag     = 1   
      and     I.PrintFlag        = 1
      and     I.SentToEpicorFlag = 1
      and     I.SentToDocLinkFlag= 0
      where   doc.InvoiceIDSeq   is not null
      and     doc.DocumentPath   is not null
      and     doc.ActiveFlag     = 1   
      and     I.PrintFlag        = 1
      and     I.SentToEpicorFlag = 1
      and     I.SentToDocLinkFlag= 0
      group by I.BillingCycleDate
    )
  select tablefinalDocLinkInvoiceCount._TotalRows_,
         tablefinalDocLinkInvoiceCount.RowNumber,
         Convert(varchar(50),tablefinalDocLinkInvoiceCount.InvoiceDate,101) as InvoiceDate,
         tablefinalDocLinkInvoiceCount.InvoiceCount
  from   tablefinalDocLinkInvoiceCount
  where  tablefinalDocLinkInvoiceCount.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage
  and    tablefinalDocLinkInvoiceCount.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage;
  -----------------------------------------------
END
GO
