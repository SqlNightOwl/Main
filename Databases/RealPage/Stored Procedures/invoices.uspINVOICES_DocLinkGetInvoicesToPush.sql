SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_DocLinkGetInvoicesToPush
-- Description     : This procedure gets the invoices that have been printed
-- Revision History:
-- Author          : SRS
-- 01/19/2009      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_DocLinkGetInvoicesToPush] (@IPVC_InvoiceDate varchar(50)
                                                              )
AS
BEGIN
  set nocount on;
  DECLARE @LDT_InvoiceDate datetime;
  SELECT  @LDT_InvoiceDate = convert(datetime,@IPVC_InvoiceDate)
  -----------------------------
  select            Min(doc.DocumentIDSeq)                            as DocumentIDSeq
                  , Min(ISNULL(cdp.CompanyIDDocumentPath, '')) 
                     + '\' +
                    Min(doc.DocumentPath)                             as DocumentPath
                  , I.InvoiceIDSeq                                    as InvoiceIDSeq
                  , Max(I.CompanyIDSeq)                               as CompanyIDSeq                                       
                  , MAX(I.AccountIDSeq)                               as AccountNumber
                  , MAX(I.BillToAccountName)                          as AccountName
                  , MAX(I.EpicorCustomerCode)                         as RefNumber
                  , MAX(CONVERT(varchar(50), I.InvoiceDueDate, 101))  as DueDate
                  , MAX(I.CompanyName)                                as PMCName
                  , MAX(A.EpicorCustomerCode)                         as PMCEpicorID
				  , MAX(AD.CountryCode)								  as CountryCode

    from INVOICES.dbo.Invoice     I   with (nolock)    
    inner join 
         DOCUMENTS.dbo.[document] doc with (nolock) 
    on   doc.InvoiceIDSeq=I.InvoiceIDSeq              
    and  doc.InvoiceIDSeq   is not null
    and  doc.DocumentPath   is not null
    and  doc.ActiveFlag = 1
    and  I.BillingCycleDate = @LDT_InvoiceDate
    and  I.PrintFlag        = 1
    and  I.SentToEpicorFlag = 1
    and  I.SentToDocLinkFlag= 0
    Left outer Join 
         Customers.dbo.Account A WITH (NOLOCK)
    on   I.CompanyIDSeq     = A.CompanyIDSeq 
    and  A.AccountTypeCode  = 'AHOFF' 
    and  I.BillingCycleDate = @LDT_InvoiceDate
    Left outer Join
        DOCUMENTS.dbo.CompanyDocumentPath cdp with (nolock)
    on  doc.CompanyIDSeq = cdp.CompanyIDSeq
    and I.CompanyIDSeq   = cdp.CompanyIDSeq
	inner join customers.dbo.[Address] AD with (nolock) 
    on AD.CompanyIDSeq=I.CompanyIDSeq 
    and AD.AddressTypeCode='COM'
    where   doc.InvoiceIDSeq   is not null
    and     doc.DocumentPath   is not null
    and     doc.ActiveFlag     = 1   
    and     I.PrintFlag        = 1
    and     I.SentToEpicorFlag = 1
    and     I.SentToDocLinkFlag= 0
    group by I.Invoiceidseq
END
GO
