SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_GetDocumentDetails
-- Description     : This procedure gets Document Details pertaining to passed 
--                        DocumentID

-- Input Parameters: @IPVC_DocumentID bigint
-- 
-- OUTPUT          : RecordSet of ID,Type,Attachment,
--                                Name,Description,CreatedBy,Last Modified,DocumentPath
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_GetDocumentDetails 
--                   @IPVC_DocumentID = 17
-- Revision History:
-- Author          : KRK, SRA Systems Limited.
-- 02/07/2007      : Stored Procedure Created.
-- 02/08/2007      : Changed by KRK. Changed Database Name from Customers to Documents.
-- 02/21/2007      : Changed by STA. Revised for accomodating Documents for Quotes.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [documents].[uspDOCUMENTS_GetDocumentDetails] (
                                                               @IPVC_DocumentID varchar(22)
                                                          )
AS
BEGIN

  /******************************************************************************************/
  /*                      Main Select statement                                             */  
  /******************************************************************************************/    
  SELECT 
              D.DocumentIDSeq                              AS ID,
              DT.Name                                      AS [Type],
              DT.Code                                      AS DType,
              D.AttachmentFlag                             AS Attachment,  
              D.CompanyIDSeq                               AS CompanyIDSeq,
              ISNULL(D.QuoteIDSeq, '')                     AS QuoteIDSeq,
              ISNULL(D.InvoiceIDSeq, '')                   AS InvoiceIDSeq,
              ISNULl(D.OrderIDSeq,'')                      AS OrderIDSeq,
              CDP.CompanyIDDocumentPath                    AS CompanyDocumentPath, 
              D.Name                                       AS [Name],                  
              D.Description                                AS Description,
              CONVERT(VARCHAR(10),D.CreatedDate,101)       AS DateSigned,
              D.CreatedBy                                  AS CreatedBy,
              CONVERT(VARCHAR(10),D.ModifiedDate,101)      AS LastModified,
              D.DocumentPath                               AS DocumentPath,
              CONVERT(VARCHAR(10),D.AgreementSentDate,101) AS AgreementSentDate,
              CONVERT(VARCHAR(10),D.AgreementSignedDate,101) AS AgreementSignedDate,
              D.PrintOnInvoiceFlag                         AS PrintOnInvoiceFlag,
              D.FamilyCode                                 AS FamilyCode,
              D.CreditMemoIDSeq                            AS CreditIDSeq             
  FROM 
              Documents.dbo.[Document] D with (nolock)

  INNER JOIN  
              Documents.dbo.DocumentType DT with (nolock)
    ON        D.DocumentIDSeq =  @IPVC_DocumentID
   
    AND       D.DocumentTypeCode = DT.Code 
               
    
  INNER JOIN  
              Documents.dbo.CompanyDocumentPath CDP with (nolock)
    ON    
              D.CompanyIDSeq = CDP.CompanyIDSeq 
    AND       D.DocumentIDSeq =  @IPVC_DocumentID
  
              

  /******************************************************************************************/    

END

GO
