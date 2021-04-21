SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_GeneratedInvoiceSelect
-- Description     : This procedure gets the invoices that have been printed
-- Revision History:
-- Author          : Shashi Bhushan
-- 12/28/2007        : Stored Procedure Created.
-- Author          : Bhavesh Shah
-- 08/12/2008      : Updated code to get DocumentPath from CompanyDocumentPath table.
-- 01/11/2008      : Altered to include ShippingAndHandlingAmount value in the total column
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GeneratedInvoiceSelect] (@IPI_PageNumber     int, 
                                                             @IPI_RowsPerPage    int,
                                                             @IPVC_CustomerIDSeq varchar(20),
                                                             @IPVC_AccountIDSeq  varchar(20),
                                                             @IPVC_StartDate     varchar(20),
                                                             @IPVC_EndDate       varchar(20),
							                                               @IPVC_PullListIDSeq varchar(20),
                                                             @IPVC_SinglePageOnly bit = 0
                                                             )
AS
BEGIN
  set nocount on;
  set @IPVC_CustomerIDSeq = nullif(@IPVC_CustomerIDSeq,'');
  set @IPVC_AccountIDSeq  = nullif(@IPVC_AccountIDSeq,'');
	SET @IPVC_SinglePageOnly = nullif(@IPVC_SinglePageOnly, 0);

  ---------------------------------------------------------
  create table #TEMP_GeneratedInvoiceForPrinting(Seq                     int not null identity(1,1),
                                                 DocumentIDSeq           varchar(50),
                                                 DocumentPath            varchar(500),
                                                 InvoiceIDSeq            varchar(50),
                                                 CompanyIDSeq            varchar(50),
                                                 AccountName             varchar(500),
                                                 CompanyName             varchar(500),
                                                 AccountIDSeq            varchar(50),
                                                 ILFChargeAmount         numeric(30,2),
                                                 AccessChargeAmount      numeric(30,2),
                                                 TransactionChargeAmount numeric(30,2),
                                                 TaxAmount               numeric(30,2),
                                                 TotalAmount             numeric(30,2),
                                                 OriginalPrintDate       varchar(20),
                                                 BillToAccountName             varchar(500),
                                                 BillToAddressLine1      varchar(500),
                                                 BillToAddressLine2      varchar(500),
                                                 BillToCity              varchar(500),
                                                 BillToState             varchar(2),
                                                 BillToZip               varchar(20),
                                                 BillToCountry           varchar(100),
                                                 InternalPrintBatchID    bigint not null default(0),
                                                 TotalPageCount          int
                                                )
  ---------------------------------------------------------
  if (@IPVC_PullListIDSeq ='' and isdate(@IPVC_StartDate) = 0)
  begin
    Insert into #TEMP_GeneratedInvoiceForPrinting(DocumentIDSeq,DocumentPath,
                                                  InvoiceIDSeq,CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,
                                                  ILFChargeAmount,AccessChargeAmount,TransactionChargeAmount,TaxAmount,TotalAmount,
                                                  OriginalPrintDate,
                                                  BillToAccountName,BillToAddressLine1,BillToAddressLine2,
                                                  BillToCity,BillToState,BillToZip,BillToCountry,
                                                  InternalPrintBatchID, TotalPageCount                                            
                                                  )
    select distinct Min(doc.DocumentIDSeq)                            as DocumentIDSeq,
                    Min(ISNULL(cdp.CompanyIDDocumentPath, '')) 
                    + '\' + Min(doc.DocumentPath)                     as DocumentPath,
                    I.InvoiceIDSeq                                    as InvoiceIDSeq,
                    Max(I.CompanyIDSeq)                               as CompanyIDSeq,
                    isnull(Max(I.PropertyName),Max(I.CompanyName))    as AccountName,
                    Max(I.CompanyName)                                as CompanyName,
                    I.AccountIDSeq                                    as AccountIDSeq, 
                    Max(I.ILFChargeAmount)                            as ILFChargeAmount,
                    Max(I.AccessChargeAmount)                         as AccessChargeAmount,
                    Max(I.TransactionChargeAmount)                    as TransactionChargeAmount,
                    Max(I.TaxAmount)                                  as TaxAmount, 
                    (Max(I.ILFChargeAmount)         + 
                     Max(I.AccessChargeAmount)      + 
                     Max(I.TransactionChargeAmount) + 
                     Max(I.TaxAmount)               +
                     Max(I.ShippingAndHandlingAmount)
                    )                                                 as TotalAmount,
                    Convert(varchar(20),Min(I.OriginalPrintDate),101) as OriginalPrintDate,
                    Max(I.BillToAccountName)                          as BillToAccountName,
                    Max(I.BillToAddressLine1)                         as BillToAddressLine1,
                    Max(I.BillToAddressLine2)                         as BillToAddressLine2,
                    Max(I.BillToCity)                                 as BillToCity,
                    Max(I.BillToState)                                as BillToState,
                    Max(I.BillToZip)                                  as BillToZip,
                    Max(I.BillToCountry)                              as BillToCountry,
                    RANK() OVER (ORDER BY Max(I.BillToState)        ASC,
                                          Max(I.BillToZip)          ASC,
                                          Max(I.BillToCity)         ASC,
                                          Max(I.BillToCountry)      ASC,
                                          Max(I.BillToAddressLine1) ASC,
                                          Max(I.BillToAddressLine2) ASC,
                                          Max(I.BillToAccountName)  ASC
                                 )                                    as InternalPrintBatchID,
                    MAX(I.TotalPageCount) AS TotalPageCount
    from INVOICES.dbo.Invoice     I   with (nolock)
    inner join 
         DOCUMENTS.dbo.[document] doc with (nolock) 
    on  doc.InvoiceIDSeq=I.InvoiceIDSeq              
    and doc.InvoiceIDSeq is not null
    and doc.ActiveFlag = 1
    and I.PrintBatchID is null and I.printflag = 1 
    and I.MarkAsPrintedFlag <> 1 
    ---> Note: MarkAsPrintedFlag=1 (ie Payment transaction) Invoices should not appear in Batch printing.
    ---> But they can be printed individually from within Invoice tab.
    and I.CompanyIDSeq   = coalesce(@IPVC_CustomerIDSeq,I.CompanyIDSeq)
    and I.AccountIDSeq   = coalesce(@IPVC_AccountIDSeq,I.AccountIDSeq)
    left join 
        DOCUMENTS.dbo.CompanyDocumentPath cdp with (nolock)
    on doc.CompanyIDSeq = cdp.CompanyIDSeq
    where I.CompanyIDSeq = coalesce(@IPVC_CustomerIDSeq,I.CompanyIDSeq)
    and   I.AccountIDSeq = coalesce(@IPVC_AccountIDSeq,I.AccountIDSeq)
    and   I.printflag = 1    
    and   I.PrintBatchID is null 
    ---> Note: MarkAsPrintedFlag=1 (ie Payment transaction) Invoices should not appear in Batch printing.
    ---> But they can be printed individually from within Invoice tab.         
    and   I.MarkAsPrintedFlag <> 1 
    and   doc.InvoiceIDSeq is not null
    and   doc.ActiveFlag = 1           
    group by I.Invoiceidseq,I.AccountIDSeq
    order by BillToState ASC,BillToZip ASC,BillToCity ASC,BillToCountry ASC,
             BillToAddressLine1 ASC,BillToAccountName ASC,I.Invoiceidseq ASC
    --->Note: above Order by clause is very important for printing.
  end
  else if (@IPVC_PullListIDSeq ='' and isdate(@IPVC_StartDate) = 1)
  begin
    select @IPVC_StartDate = convert(datetime,@IPVC_StartDate),
           @IPVC_EndDate   = convert(datetime,@IPVC_EndDate)

    Insert into #TEMP_GeneratedInvoiceForPrinting(DocumentIDSeq,DocumentPath,
                                                  InvoiceIDSeq,CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,
                                                  ILFChargeAmount,AccessChargeAmount,TransactionChargeAmount,TaxAmount,TotalAmount,
                                                  OriginalPrintDate,
                                                  BillToAccountName,BillToAddressLine1,BillToAddressLine2,
                                                  BillToCity,BillToState,BillToZip,BillToCountry,
                                                  InternalPrintBatchID, TotalPageCount
                                                  )  
    select distinct Min(doc.DocumentIDSeq)                            as DocumentIDSeq,
                    Min(ISNULL(cdp.CompanyIDDocumentPath, '')) 
                    + '\' + Min(doc.DocumentPath)                     as DocumentPath,
                    I.InvoiceIDSeq                                    as InvoiceIDSeq,
                    Max(I.CompanyIDSeq)                               as CompanyIDSeq,
                    isnull(Max(I.PropertyName),Max(I.CompanyName))    as AccountName,
                    Max(I.CompanyName)                                as CompanyName,
                    I.AccountIDSeq                                    as AccountIDSeq, 
                    Max(I.ILFChargeAmount)                            as ILFChargeAmount,
                    Max(I.AccessChargeAmount)                         as AccessChargeAmount,
                    Max(I.TransactionChargeAmount)                    as TransactionChargeAmount,
                    Max(I.TaxAmount)                                  as TaxAmount, 
                    (Max(I.ILFChargeAmount)         + 
                     Max(I.AccessChargeAmount)      + 
                     Max(I.TransactionChargeAmount) + 
                     Max(I.TaxAmount)               +
                     Max(I.ShippingAndHandlingAmount)
                    )                                                 as TotalAmount,
                    Convert(varchar(20),Min(I.OriginalPrintDate),101) as OriginalPrintDate,
                    Max(I.BillToAccountName)                          as BillToAccountName,
                    Max(I.BillToAddressLine1)                         as BillToAddressLine1,
                    Max(I.BillToAddressLine2)                         as BillToAddressLine2,
                    Max(I.BillToCity)                                 as BillToCity,
                    Max(I.BillToState)                                as BillToState,
                    Max(I.BillToZip)                                  as BillToZip,
                    Max(I.BillToCountry)                              as BillToCountry,
                    RANK() OVER (ORDER BY Max(I.BillToState)        ASC,
                                          Max(I.BillToZip)          ASC,
                                          Max(I.BillToCity)         ASC,
                                          Max(I.BillToCountry)      ASC,
                                          Max(I.BillToAddressLine1) ASC,
                                          Max(I.BillToAddressLine2) ASC,
                                          Max(I.BillToAccountName)  ASC
                                 )                                    as InternalPrintBatchID,
                    MAX(I.TotalPageCount) AS TotalPageCount   
    from INVOICES.dbo.Invoice     I with (nolock)
    inner join 
         DOCUMENTS.dbo.[document] doc with (nolock) 
    on  doc.InvoiceIDSeq=I.InvoiceIDSeq              
    and doc.InvoiceIDSeq is not null
    and doc.ActiveFlag = 1
    and I.PrintBatchID is null and I.printflag = 1 
    and I.MarkAsPrintedFlag <> 1 
    ---> Note: MarkAsPrintedFlag=1 (ie Payment transaction) Invoices should not appear in Batch printing.
    ---> But they can be printed individually from within Invoice tab.
    and I.CompanyIDSeq = coalesce(@IPVC_CustomerIDSeq,I.CompanyIDSeq)
    and I.AccountIDSeq = coalesce(@IPVC_AccountIDSeq,I.AccountIDSeq)
    and (I.invoicedate    between @IPVC_StartDate and @IPVC_EndDate)
    left join 
        DOCUMENTS.dbo.CompanyDocumentPath cdp with (nolock)
    on doc.CompanyIDSeq = cdp.CompanyIDSeq
    where (I.invoicedate  between @IPVC_StartDate and @IPVC_EndDate)
    and   I.CompanyIDSeq = coalesce(@IPVC_CustomerIDSeq,I.CompanyIDSeq)
    and I.AccountIDSeq   = coalesce(@IPVC_AccountIDSeq,I.AccountIDSeq)
    and I.printflag      = 1 
    and I.PrintBatchID is null 
    and I.MarkAsPrintedFlag <> 1 
    ---> Note: MarkAsPrintedFlag=1 (ie Payment transaction) Invoices should not appear in Batch printing.
    ---> But they can be printed individually from within Invoice tab.
    and doc.InvoiceIDSeq is not null
    and doc.ActiveFlag = 1   
   group by I.Invoiceidseq,I.AccountIDSeq
   order by BillToState ASC,BillToZip ASC,BillToCity ASC,BillToCountry ASC,
            BillToAddressLine1 ASC,BillToAccountName ASC,I.Invoiceidseq ASC
    --->Note: above Order by clause is very important for printing.
  end
  else if (@IPVC_PullListIDSeq is not null and @IPVC_PullListIDSeq <> '' and isdate(@IPVC_StartDate) = 0)
  begin
    Insert into #TEMP_GeneratedInvoiceForPrinting(DocumentIDSeq,DocumentPath,InvoiceIDSeq,CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,
                                                  ILFChargeAmount,AccessChargeAmount,TransactionChargeAmount,TaxAmount,TotalAmount,
                                                  OriginalPrintDate,
                                                  BillToAccountName,BillToAddressLine1,BillToAddressLine2,
                                                  BillToCity,BillToState,BillToZip,BillToCountry,
                                                  InternalPrintBatchID, TotalPageCount
                                                  )  
    select distinct Min(doc.DocumentIDSeq)                            as DocumentIDSeq,
                    Min(ISNULL(cdp.CompanyIDDocumentPath, '')) 
                    + '\' + Min(doc.DocumentPath)                     as DocumentPath,
                    I.InvoiceIDSeq                                    as InvoiceIDSeq,
                    Max(I.CompanyIDSeq)                               as CompanyIDSeq,
                    isnull(Max(I.PropertyName),Max(I.CompanyName))    as AccountName,
                    Max(I.CompanyName)                                as CompanyName,
                    I.AccountIDSeq                                    as AccountIDSeq, 
                    Max(I.ILFChargeAmount)                            as ILFChargeAmount,
                    Max(I.AccessChargeAmount)                         as AccessChargeAmount,
                    Max(I.TransactionChargeAmount)                    as TransactionChargeAmount,
                    Max(I.TaxAmount)                                  as TaxAmount, 
                    (Max(I.ILFChargeAmount)         + 
                     Max(I.AccessChargeAmount)      + 
                     Max(I.TransactionChargeAmount) + 
                     Max(I.TaxAmount)               +
                     Max(I.ShippingAndHandlingAmount)
                    )                                                 as TotalAmount,
                    Convert(varchar(20),Min(I.OriginalPrintDate),101) as OriginalPrintDate,
                    Max(I.BillToAccountName)                          as BillToAccountName,
                    Max(I.BillToAddressLine1)                         as BillToAddressLine1,
                    Max(I.BillToAddressLine2)                         as BillToAddressLine2,
                    Max(I.BillToCity)                                 as BillToCity,
                    Max(I.BillToState)                                as BillToState,
                    Max(I.BillToZip)                                  as BillToZip,
                    Max(I.BillToCountry)                              as BillToCountry,
                    RANK() OVER (ORDER BY Max(I.BillToState)        ASC,
                                          Max(I.BillToZip)          ASC,
                                          Max(I.BillToCity)         ASC,
                                          Max(I.BillToCountry)      ASC,
                                          Max(I.BillToAddressLine1) ASC,
                                          Max(I.BillToAddressLine2) ASC,
                                          Max(I.BillToAccountName)  ASC
                                 )                                    as InternalPrintBatchID,
                    MAX(I.TotalPageCount) AS TotalPageCount   
   from INVOICES.dbo.Invoice          I  with (nolock)
   inner join
        INVOICES.dbo.PullListAccounts pa with (nolock) 
   on pa.AccountIDSeq = I.AccountIDSeq and pa.PullListIDSeq=@IPVC_PullListIDSeq
   and I.PrintBatchID is null and I.printflag = 1 
   and I.MarkAsPrintedFlag <> 1 
   ---> Note: MarkAsPrintedFlag=1 (ie Payment transaction) Invoices should not appear in Batch printing.
   ---> But they can be printed individually from within Invoice tab.
   and I.CompanyIDSeq = coalesce(@IPVC_CustomerIDSeq,I.CompanyIDSeq)
   and I.AccountIDSeq = coalesce(@IPVC_AccountIDSeq,I.AccountIDSeq)
   inner join 
        DOCUMENTS.dbo.[document] doc with (nolock) 
   on  doc.InvoiceIDSeq=I.InvoiceIDSeq              
   and doc.InvoiceIDSeq is not null
   and doc.ActiveFlag = 1   
    left join 
        DOCUMENTS.dbo.CompanyDocumentPath cdp with (nolock)
    on doc.CompanyIDSeq = cdp.CompanyIDSeq
   where I.CompanyIDSeq = coalesce(@IPVC_CustomerIDSeq,I.CompanyIDSeq)
               and I.AccountIDSeq = coalesce(@IPVC_AccountIDSeq,I.AccountIDSeq)
               and I.printflag = 1 
               and doc.InvoiceIDSeq is not null
               and doc.ActiveFlag = 1
               and I.PrintBatchID is null  
   and I.MarkAsPrintedFlag <> 1 
   ---> Note: MarkAsPrintedFlag=1 (ie Payment transaction) Invoices should not appear in Batch printing.
   ---> But they can be printed individually from within Invoice tab.              
   group by I.Invoiceidseq,I.AccountIDSeq
   order by BillToState ASC,BillToZip ASC,BillToCity ASC,BillToCountry ASC,
            BillToAddressLine1 ASC,BillToAccountName ASC,I.Invoiceidseq ASC
    --->Note: above Order by clause is very important for printing.
  end
  else if (@IPVC_PullListIDSeq is not null and @IPVC_PullListIDSeq <> '' and isdate(@IPVC_StartDate) = 1)
  begin
    select @IPVC_StartDate = convert(datetime,@IPVC_StartDate),
           @IPVC_EndDate   = convert(datetime,@IPVC_EndDate)

    Insert into #TEMP_GeneratedInvoiceForPrinting(DocumentIDSeq,DocumentPath,InvoiceIDSeq,CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,
                                                  ILFChargeAmount,AccessChargeAmount,TransactionChargeAmount,TaxAmount,TotalAmount,
                                                  OriginalPrintDate,
                                                  BillToAccountName,BillToAddressLine1,BillToAddressLine2,
                                                  BillToCity,BillToState,BillToZip,BillToCountry,
                                                  InternalPrintBatchID, TotalPageCount
                                                  )  
    select distinct Min(doc.DocumentIDSeq)                            as DocumentIDSeq,
                    Min(ISNULL(cdp.CompanyIDDocumentPath, '')) 
                    + '\' + Min(doc.DocumentPath)                     as DocumentPath,
                    I.InvoiceIDSeq                                    as InvoiceIDSeq,
                    Max(I.CompanyIDSeq)                               as CompanyIDSeq,
                    isnull(Max(I.PropertyName),Max(I.CompanyName))    as AccountName,
                    Max(I.CompanyName)                                as CompanyName,
                    I.AccountIDSeq                                    as AccountIDSeq, 
                    Max(I.ILFChargeAmount)                            as ILFChargeAmount,
                    Max(I.AccessChargeAmount)                         as AccessChargeAmount,
                    Max(I.TransactionChargeAmount)                    as TransactionChargeAmount,
                    Max(I.TaxAmount)                                  as TaxAmount, 
                    (Max(I.ILFChargeAmount)         + 
                     Max(I.AccessChargeAmount)      + 
                     Max(I.TransactionChargeAmount) + 
                     Max(I.TaxAmount)               +
                     Max(I.ShippingAndHandlingAmount)
                    )                                                 as TotalAmount,
                    Convert(varchar(20),Min(I.OriginalPrintDate),101) as OriginalPrintDate,
                    Max(I.BillToAccountName)                          as BillToAccountName,
                    Max(I.BillToAddressLine1)                         as BillToAddressLine1,
                    Max(I.BillToAddressLine2)                         as BillToAddressLine2,
                    Max(I.BillToCity)                                 as BillToCity,
                    Max(I.BillToState)                                as BillToState,
                    Max(I.BillToZip)                                  as BillToZip,
                    Max(I.BillToCountry)                              as BillToCountry,
                    RANK() OVER (ORDER BY Max(I.BillToState)        ASC,
                                          Max(I.BillToZip)          ASC,
                                          Max(I.BillToCity)         ASC,
                                          Max(I.BillToCountry)      ASC,
                                          Max(I.BillToAddressLine1) ASC,
                                          Max(I.BillToAddressLine2) ASC,
                                          Max(I.BillToAccountName)  ASC
                                 )                                    as InternalPrintBatchID,
                    MAX(I.TotalPageCount) AS TotalPageCount    
    from INVOICES.dbo.Invoice          I  with (nolock)
    inner join
         INVOICES.dbo.PullListAccounts pa with (nolock) 
    on pa.AccountIDSeq = I.AccountIDSeq and pa.PullListIDSeq=@IPVC_PullListIDSeq
    and I.PrintBatchID is null and I.printflag = 1 
    and I.MarkAsPrintedFlag <> 1 
    ---> Note: MarkAsPrintedFlag=1 (ie Payment transaction) Invoices should not appear in Batch printing.
    ---> But they can be printed individually from within Invoice tab.
    and I.CompanyIDSeq = coalesce(@IPVC_CustomerIDSeq,I.CompanyIDSeq)
    and I.AccountIDSeq = coalesce(@IPVC_AccountIDSeq,I.AccountIDSeq)
    and (I.invoicedate  between @IPVC_StartDate and @IPVC_EndDate)   
    inner join 
         DOCUMENTS.dbo.[document] doc with (nolock) 
    on  doc.InvoiceIDSeq=I.InvoiceIDSeq              
    and doc.InvoiceIDSeq is not null
    and doc.ActiveFlag = 1   
    left join 
        DOCUMENTS.dbo.CompanyDocumentPath cdp with (nolock)
    on doc.CompanyIDSeq = cdp.CompanyIDSeq
    where (I.invoicedate  between @IPVC_StartDate and @IPVC_EndDate)
    and   I.CompanyIDSeq = coalesce(@IPVC_CustomerIDSeq,I.CompanyIDSeq)
    and   I.AccountIDSeq = coalesce(@IPVC_AccountIDSeq,I.AccountIDSeq)
    and   I.printflag    = 1    
    and I.PrintBatchID is null
    and I.MarkAsPrintedFlag <> 1 
    ---> Note: MarkAsPrintedFlag=1 (ie Payment transaction) Invoices should not appear in Batch printing.
    ---> But they can be printed individually from within Invoice tab.
    and   doc.InvoiceIDSeq is not null
    and   doc.ActiveFlag = 1
   group by I.Invoiceidseq,I.AccountIDSeq
   order by BillToState ASC,BillToZip ASC,BillToCity ASC,BillToCountry ASC,
            BillToAddressLine1 ASC,BillToAccountName ASC,I.Invoiceidseq ASC
    --->Note: above Order by clause is very important for printing.
  end
  
  --------------------------------------------------------------------------
  select InvoiceIDSeq,CompanyIDSeq,AccountName,CompanyName,AccountIDSeq,
         ILFChargeAmount,AccessChargeAmount,TransactionChargeAmount,TaxAmount,TotalAmount,
         DocumentIDSeq,DocumentPath,OriginalPrintDate,
         BillToAccountName,BillToAddressLine1,BillToAddressLine2,
         BillToCity,BillToState,BillToZip,BillToCountry,
         InternalPrintBatchID
         , COUNT(1) OVER(PARTITION BY InternalPrintBatchID) AS InternalPrintBatchCount
         , TotalPageCount
  from   #TEMP_GeneratedInvoiceForPrinting with (nolock)
  where  SEQ > (@IPI_PageNumber-1) * @IPI_RowsPerPage    
  AND    SEQ <= (@IPI_PageNumber)  * @IPI_RowsPerPage    
	AND    TotalPageCount = coalesce(@IPVC_SinglePageOnly, TotalPageCount)

  select Count(DocumentIDSeq)                as TotalCount,
         Coalesce(Sum(TotalAmount),0.00)     as TotalAmount,
         SUM(CASE TotalPageCount WHEN 1 THEN 1 ELSE 0 END) AS SingleTotalCount,
				 Coalesce(Sum(CASE TotalPageCount WHEN 1 THEN TotalAmount ELSE 0 END),0.00)     as SingleTotalAmount
  from #TEMP_GeneratedInvoiceForPrinting with (nolock)
	WHERE TotalPageCount = coalesce(@IPVC_SinglePageOnly, TotalPageCount)
  ---------------------------------------------------------------------------
  --Final Cleanup
  drop table #TEMP_GeneratedInvoiceForPrinting
  --------------------------------------------------------------------------
END

GO
