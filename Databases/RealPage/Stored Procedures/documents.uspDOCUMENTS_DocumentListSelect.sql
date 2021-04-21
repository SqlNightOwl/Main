SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_DocumentListSelectVer1
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
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_DocumentListSelectVer1 
--                   @IPI_PageNumber    = 1
--                   @IPI_RowsPerPage   = 5
--                   @IPVC_CompanyIDSeq = 'A0000003273' 
--                   @IPVC_DocumentType = 'AGGR' 
--                   @IPVC_Description  = 'Old Agreement' 
--                   @IPVC_CreatedBy    = 'Kishore'  
--                   @IPVC_ModifiedDate = '02/02/2007' 
-- Revision History:
-- Author          : KRK, SRA Systems Limited.
-- 2010-09-28      : LWW. Add option to query by DocumentLevelCode (pcr 8015)
-- 2007-02-21      : Changed by STA. Revised for accomodating Documents for Quotes.
-- 2007-02-08      : Changed by KRK. Changed Database Name from Customers to Documents.
-- 2007-02-07      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [documents].[uspDOCUMENTS_DocumentListSelect] (
                                                               @IPI_PageNumber      int,
                                                               @IPI_RowsPerPage     int,
                                                               @IPVC_CompanyIDSeq   varchar(22),
                                                               @IPVC_QuoteIDSeq     varchar(22),
                                                               @IPVC_InvoiceIDSeq   varchar(22),
                                                               @IPVC_OrderIDSeq     varchar(22),
                                                               @IPVC_DocumentType   varchar(5), 
                                                               @IPVC_Description    varchar(4000),
                                                               @IPVC_CreatedBy      varchar(70),
                                                               @IPVC_ModifiedDate   varchar(20),
                                                               @IPVC_CreditIDSeq    varchar(22), 
                                                               @IPVC_DocumentLevel  varchar(5)=NULL
                                                              ) --WITH RECOMPILE  
AS
BEGIN
  set nocount on;
  ----------------------------------------------
  select @IPVC_CompanyIDSeq = nullif(@IPVC_CompanyIDSeq,''),
         @IPVC_QuoteIDSeq   = nullif(@IPVC_QuoteIDSeq,''),
         @IPVC_InvoiceIDSeq = nullif(@IPVC_InvoiceIDSeq,''),
         @IPVC_OrderIDSeq   = nullif(@IPVC_OrderIDSeq,''),
         @IPVC_DocumentType = nullif(@IPVC_DocumentType,''),
         @IPVC_CreditIDSeq  = nullif(@IPVC_CreditIDSeq,''),
         @IPVC_DocumentLevel  = nullif(@IPVC_DocumentLevel,''),
         @IPVC_ModifiedDate = nullif(@IPVC_ModifiedDate,'')

  declare @rowstoprocess bigint;
  select  @rowstoprocess = (@IPI_PageNumber)*@IPI_RowsPerPage
  SET ROWCOUNT @rowstoprocess;
  ----------------------------------------------------------------
  ---Get Records based on search criteria
  ----------------------------------------------------------------
  WITH tablefinal AS 
  ----------------------------------------------------------------------------  
       (SELECT tableinner.*
        FROM
         ----------------------------------------------------------------------------
         (select  row_number() over(order by source.[Name] asc)  as RowNumber,
                  source.*
          from
          (select  doc.DocumentIDSeq                              as ID,
                   coalesce((case when @IPVC_QuoteIDSeq is not null
                                   then 
                                    (select top 1 Q.QuoteStatusCode
                                     from Quotes.dbo.Quote Q with (nolock)
                                     where Q.QuoteIDSeq = @IPVC_QuoteIDSeq
                                    ) 
                             end),'N/A')                          as quotestatus,
                   coalesce((case when @IPVC_CreditIDSeq is not null
                                   then 
                                    (select top 1 CM.creditstatuscode
                                     from INVOICES.dbo.CreditMemo CM with (nolock)
                                     where CM.CreditMemoIDSeq = CreditMemoIDSeq
                                    ) 
                             end),'N/A')                          as creditstatus, 
                   docType.Name                                   as [Type],
                   docType.Code                                   as DType,   
                   doc.AttachmentFlag                             as Attachment,  
                   doc.Name                                       as [Name],
                   doc.Description                                as Description,
                   isnull(dbo.fn_getDateSigned(DocumentIDSeq),'') as DateSigned,
                   doc.CreatedBy                                  as CreatedBy,
                   convert(varchar(10),doc.ModifiedDate,101)      as LastModified,
                   convert(varchar(10),doc.AgreementSentDate,101) as AgreementSentDate                   
           from Documents.dbo.[Document]   doc     with (nolock) 
           inner join 
                Documents.dbo.DocumentType docType with (nolock)  
           ON   doc.DocumentTypeCode = docType.Code
           and  doc.ActiveFlag = 1 
           and  docType.Code <> 'FNOT'
           and  docType.Code = coalesce(@IPVC_DocumentType,docType.Code)
           and  coalesce(nullif(doc.CompanyIDSeq,''),'0')    = coalesce(@IPVC_CompanyIDSeq,coalesce(nullif(doc.CompanyIDSeq,''),'0'))
           and  coalesce(nullif(doc.QuoteIDSeq,''),'0')      = coalesce(@IPVC_QuoteIDSeq,coalesce(nullif(doc.QuoteIDSeq,''),'0'))
           and  coalesce(nullif(doc.[DocumentLevelCode],''),'') = coalesce(@IPVC_DocumentLevel,coalesce(nullif(doc.[DocumentLevelCode],''),''))
           and  coalesce(nullif(doc.InvoiceIDSeq,''),'0')    = coalesce(@IPVC_InvoiceIDSeq,coalesce(nullif(doc.InvoiceIDSeq,''),'0'))
           and  coalesce(nullif(doc.OrderIDSeq,''),'0')      = coalesce(@IPVC_OrderIDSeq,coalesce(nullif(doc.OrderIDSeq,''),'0'))
           and  coalesce(nullif(doc.CreditMemoIDSeq,''),'0') = coalesce(@IPVC_CreditIDSeq,coalesce(nullif(doc.CreditMemoIDSeq,''),'0'))
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
          ) source          
          -----------------------------------------------------------------------------------
         )tableinner  
        WHERE tableinner.RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage
        and   tableinner.RowNumber <= (@IPI_PageNumber)  * @IPI_RowsPerPage
    )
    SELECT  tablefinal.RowNumber,            
            tablefinal.ID, 
            tablefinal.quotestatus,
            tablefinal.creditstatus,
            tablefinal.[Type],
            tablefinal.DType ,
            tablefinal.Attachment,
            tablefinal.[Name],
            tablefinal.Description,
            tablefinal.DateSigned,
            tablefinal.CreatedBy,
            tablefinal.LastModified,
            tablefinal.AgreementSentDate
    from    tablefinal


  ----------------------------------------------------------------
  ---Get Counts based on search criteria
  --- The below portion needs to be put in a separate proc 
  ----  uspDOCUMENTS_DocumentListSelectCount
  ----------------------------------------------------------------
  SET ROWCOUNT 0;  
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
