SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_GetFootNotes
-- Description     : This procedure gets Fotnotes pertaining to passed 
--                        InvoiceID

-- Input Parameters: @IPVC_InvoiceIDSeq varchar
--
-- OUTPUT          : RecordSet of Description
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_GetFootNotes
--                   @IPVC_InvoiceIDSeq = 'I0711000071' 
-- Revision History:
-- Author          : Kiran Kusumba.
-- 11/29/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [documents].[uspDOCUMENTS_GetFootNotes] (@IPVC_InvoiceIDSeq   varchar(50)
                                                    )
AS
BEGIN 
  set nocount on 
  declare @LVC_CompanyIDSeq    varchar(50)
  declare @LVC_PropertyIDSeq   varchar(50)
  declare @LVC_AccountIDSeq    varchar(50)
  -----------------------------------------------------------
  create table #temp_documenttoprintonInvoice (IDSeq           bigint identity(1,1),
                                               Description     varchar(4000) NULL
                                              )
  -----------------------------------------------------------
  select @LVC_CompanyIDSeq   = I.CompanyIDSeq,
         @LVC_PropertyIDSeq  = I.PropertyIDSeq,
         @LVC_AccountIDSeq   = I.AccountIDSeq
  from   INVOICES.DBO.INVOICE I with (nolock)
  where  I.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
  -----------------------------------------------------------   
  --Get documents NOTES pertaining to @LVC_CompanyIDSeq and @LVC_PropertyIDSeq 
  -- with Orderid is null
  -- for this @IPVC_InvoiceIDSeq
  Insert into #temp_documenttoprintonInvoice(Description)
  select distinct D.[Description] 
  from   Documents.dbo.Document D with (nolock)  
  where  D.CompanyIDSeq       = @LVC_CompanyIDSeq
  and    coalesce(D.PropertyIDSeq,'') = coalesce(@LVC_PropertyIDSeq,'')
  and    D.DocumentTypeCode   = 'NOTE'
  and    D.Activeflag         = 1
  and    D.PrintOnInvoiceFlag = 1  
  and    D.OrderIDSeq is null 
  and    (D.[Description] is not null and D.[Description] <> '')
  and    not exists (select top 1 1 from #temp_documenttoprintonInvoice S with (nolock)
                     where  D.[Description] = S.[Description]
                    )
  
  -----------------------------------------------------------
  --Get documents NOTES pertaining to @LVC_AccountIDSeq
  -- with Orderid is null
  -- for this @IPVC_InvoiceIDSeq
  Insert into #temp_documenttoprintonInvoice(Description)
  select distinct D.[Description] 
  from   Documents.dbo.Document D with (nolock)  
  where  D.AccountIDSeq       = @LVC_AccountIDSeq
  and    D.DocumentTypeCode   = 'NOTE'
  and    D.Activeflag         = 1
  and    D.PrintOnInvoiceFlag = 1  
  and    D.OrderIDSeq is null
  and    (D.[Description] is not null and D.[Description] <> '')
  and    not exists (select top 1 1 from #temp_documenttoprintonInvoice S with (nolock)
                     where  D.[Description] = S.[Description]
                    )
  -----------------------------------------------------------
  --Get documents pertaining to QuoteIDSeq for this @IPVC_InvoiceIDSeq
  --with Orderid is null
  Insert into #temp_documenttoprintonInvoice(Description)
  select distinct D.[Description] 
  from   Documents.dbo.Document D with (nolock)
  where  D.DocumentTypeCode    = 'NOTE'
  and    D.Activeflag          = 1
  and    D.PrintOnInvoiceFlag  = 1
  and    D.OrderIDSeq is null
  and    (D.[Description] is not null and D.[Description] <> '')
  and    Exists (select top 1 1 
                 From  Invoices.dbo.InvoiceItem II with (nolock)
                 inner join
                       Orders.dbo.[Order] O   with (nolock)
                 on    II.OrderIDSeq   = O.OrderIdSeq
                 and   O.QuoteidSeq    = D.Quoteidseq 
                 and   II.InvoiceIDSeq = @IPVC_InvoiceIDSeq
                )    
  and    not exists (select top 1 1 from #temp_documenttoprintonInvoice S with (nolock)
                     where  D.[Description] = S.[Description]
                    ) 
  -----------------------------------------------------------
  --Get documents pertaining to OrderID for this @IPVC_InvoiceIDSeq
  Insert into #temp_documenttoprintonInvoice(Description)
  select distinct D.[Description] 
  from   Documents.dbo.Document D with (nolock)
  Inner Join
         Invoices.dbo.InvoiceItem II with (nolock)
  on     D.OrderIdSeq         = II.OrderIDSeq 
  and    II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
  and    D.OrderItemIDSeq is null
  and    D.DocumentTypeCode   = 'NOTE'
  and    D.Activeflag         = 1
  and    D.PrintOnInvoiceFlag = 1 
  and    (D.[Description] is not null and D.[Description] <> '')
  and    not exists (select top 1 1 from #temp_documenttoprintonInvoice S with (nolock)
                     where  D.[Description] = S.[Description]
                    )          
  -----------------------------------------------------------
  --Get documents pertaining to OrderID and OrderItemID for this @IPVC_InvoiceIDSeq
  Insert into #temp_documenttoprintonInvoice(Description)
  select distinct D.[Description] 
  FROM   Documents.dbo.Document D with (nolock)
  Inner Join
         Invoices.dbo.InvoiceItem II with (nolock)
  on     D.OrderIdSeq         = II.OrderIDSeq
  and    D.OrderItemIDSeq     = II.OrderItemIDSeq  
  and    II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq 
  and    D.DocumentTypeCode   = 'NOTE'
  and    D.Activeflag         = 1
  and    D.PrintOnInvoiceFlag = 1
  and    (D.[Description] is not null and D.[Description] <> '')
  and    not exists (select top 1 1 from #temp_documenttoprintonInvoice S with (nolock)
                     where  D.[Description] = S.[Description]
                    )              
  -----------------------------------------------------------
  --Get FamilyFootNotes Pertaining to FamilyCode for InvoiceItems
  Insert into #temp_documenttoprintonInvoice(Description)
  select distinct FFN.[Description] 
  from   Invoices.dbo.FamilyFootNote FFN   with (nolock)
  where  exists (select top 1 1
                 from   Invoices.dbo.InvoiceItem II with (nolock)
                 inner join
                        Products.dbo.Product P      with (nolock)
                 on     II.ProductCode  = P.Code 
                 and    II.InvoiceIDSeq = @IPVC_InvoiceIDSeq
                 and    P.FamilyCode    =  FFN.Familycode
                )
  and    not exists (select top 1 1 from #temp_documenttoprintonInvoice S with (nolock)
                     where  S.[Description] = FFN.[Description]
                    )  
  and    (FFN.[Description] is not null and FFN.[Description] <> '')
  -----------------------------------------------------------
  --Final Select 
  select [Description] as [Description] 
  from   #temp_documenttoprintonInvoice with (nolock)
  order by IDSeq asc
  -----------------------------------------------------------
  --Final Cleanup
  drop table #temp_documenttoprintonInvoice
  -----------------------------------------------------------  
END   
  
-- exec uspDOCUMENTS_GetFootNotes 'I0801000461' 
GO
