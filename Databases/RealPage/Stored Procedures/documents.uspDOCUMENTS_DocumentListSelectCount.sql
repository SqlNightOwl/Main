SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_DocumentListSelectCount
-- Description     : This procedure gets Document Details pertaining to passed 
--                        DocumentType,Description,CreatedBy and ModifiedDate

-- Input Parameters: @IPVC_CompanyIDSeq varchar
--                   @IPVC_DocumentType varchar
--                   @IPVC_Description  varchar
--                   @IPVC_CreatedBy    varchar
--                   @IPVC_ModifiedDate varchar
-- 
-- OUTPUT          : RecordSet of ID,Type,Attachment,
--                                Name,Description,CreatedBy,Last Modified
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_DocumentListSelectCount 
--                   @IPI_PageNumber    = 1
--                   @IPI_RowsPerPage   = 5
--                   @IPVC_CompanyIDSeq = 'A0000003273' 
--                   @IPVC_DocumentType = 'AGGR' 
--                   @IPVC_Description  = 'Old Agreement' 
--                   @IPVC_CreatedBy    = 'Kishore'  
--                   @IPVC_ModifiedDate = '02/02/2007' 
-- Revision History:
-- Author          : KRK, SRA Systems Limited.
-- 02/07/2007      : Stored Procedure Created.
-- 02/08/2007      : Changed by KRK. Changed Database Name from Customers to Documents.
-- 02/21/2007      : Changed by STA. Revised for accomodating Documents for Quotes.
--
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [documents].[uspDOCUMENTS_DocumentListSelectCount] (                                                              
                                                               @IPVC_CompanyIDSeq   varchar(22),
                                                               @IPVC_QuoteIDSeq     varchar(22),
                                                               @IPVC_InvoiceIDSeq   varchar(22),
                                                               @IPVC_OrderIDSeq     varchar(22),
                                                               @IPVC_DocumentType   varchar(5), 
                                                               @IPVC_Description    varchar(4000),
                                                               @IPVC_CreatedBy      varchar(70),
                                                               @IPVC_ModifiedDate   varchar(20),
                                                               @IPVC_CreditIDSeq    varchar(22) 
                                                              ) --WITH RECOMPILE  
AS
BEGIN
  set nocount on;  
  SET ROWCOUNT 0;  
  ----------------------------------------------
  select @IPVC_CompanyIDSeq = nullif(@IPVC_CompanyIDSeq,''),
         @IPVC_QuoteIDSeq   = nullif(@IPVC_QuoteIDSeq,''),
         @IPVC_InvoiceIDSeq = nullif(@IPVC_InvoiceIDSeq,''),
         @IPVC_OrderIDSeq   = nullif(@IPVC_OrderIDSeq,''),
         @IPVC_DocumentType = nullif(@IPVC_DocumentType,''),
         @IPVC_CreditIDSeq  = nullif(@IPVC_CreditIDSeq,''),
         @IPVC_ModifiedDate = nullif(@IPVC_ModifiedDate,'')

  ----------------------------------------------------------------------------  
  select  count(1)  as [Count]        
  from    Documents.dbo.[Document]   doc     with (nolock) 
  inner join 
          Documents.dbo.DocumentType docType with (nolock)  
  ON   doc.DocumentTypeCode = docType.Code
  and  doc.ActiveFlag = 1 
  and  docType.Code <> 'FNOT'
  and  docType.Code = coalesce(@IPVC_DocumentType,docType.Code)
  and  coalesce(nullif(doc.CompanyIDSeq,''),'0')    = coalesce(@IPVC_CompanyIDSeq,coalesce(nullif(doc.CompanyIDSeq,''),'0'))
  and  coalesce(nullif(doc.QuoteIDSeq,''),'0')      = coalesce(@IPVC_QuoteIDSeq,coalesce(nullif(doc.QuoteIDSeq,''),'0'))
  and  coalesce(nullif(doc.InvoiceIDSeq,''),'0')    = coalesce(@IPVC_InvoiceIDSeq,coalesce(nullif(doc.InvoiceIDSeq,''),'0'))
  and  coalesce(nullif(doc.OrderIDSeq,''),'0')      = coalesce(@IPVC_OrderIDSeq,coalesce(nullif(doc.OrderIDSeq,''),'0'))
  and  coalesce(nullif(doc.CreditMemoIDSeq,''),'0') = coalesce(@IPVC_CreditIDSeq,coalesce(nullif(doc.CreditMemoIDSeq,''),'0'))
  --and  convert(varchar(20),coalesce(doc.ModifiedDate,getdate()),101) = coalesce(@IPVC_ModifiedDate,convert(varchar(20),coalesce(doc.ModifiedDate,getdate()),101))
  and ((isdate(@IPVC_ModifiedDate)= 0)
                   OR
       (isdate(@IPVC_ModifiedDate)= 1 
               and
        convert(varchar(20),coalesce(doc.ModifiedDate,getdate()),101) = coalesce(@IPVC_ModifiedDate,convert(varchar(20),coalesce(doc.ModifiedDate,getdate()),101))
       )
      )
  and (                
        (
         ((@IPVC_Description <> '') and (doc.Description like  '%' + @IPVC_Description + '%')) 
                OR
          (@IPVC_Description =  '')
         )
         and
        (
          ((@IPVC_CreatedBy  <> '') and (doc.CreatedBy like  '%' + @IPVC_CreatedBy + '%')) 
               OR 
           (@IPVC_CreatedBy =  '')
          )              
       )        


END
GO
