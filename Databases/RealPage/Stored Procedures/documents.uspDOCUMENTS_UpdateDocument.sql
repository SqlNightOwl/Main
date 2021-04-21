SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_UpdateDocument
-- Description     : This procedure gets Document Details pertaining to passed 
--                        DocumentType,Description,CreatedBy and ModifiedDate

-- Input Parameters:   @IPVC_DocumentID         varchar(22)
--                     @IPVC_DocumentTypeCode   varchar
--                     @IPVC_DocumentLevelCode  varchar
--                     @IPVC_Name               varchar
--                     @IPVC_Description        varchar
--                     @IPVC_CreatedDate        varchar
--                     @IPVC_CreatedBy          varchar
--                     @IPVC_DocumentPath       varchar
--                     @IPVC_AgreementSentDate  datetime  
-- 
-- OUTPUT          : RecordSet of ID,Type,Attachment,
--                                Name,Description,CreatedBy,Last Modified
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_UpdateDocument 
--                     @IPVC_DocumentID         = 24
--                     @IPVC_DocumentTypeCode   = 'AGGR'
--                     @IPVC_DocumentLevelCode  = 'PMC'
--                     @IPVC_Name               = 'Master'
--                     @IPVC_Description        = 'Old'
--                     @IPVC_CreatedDate        = '02/02/2007'
--                     @IPVC_CreatedBy          = 'Kishore'
--                     @IPVC_DocumentPath       = 'C:\\OMSDocs'
--                     @IPVC_AgreementSentDate  = '06/13/2007'
-- Revision History:
-- Author          : KISHORE KUMAR A S 
-- 07/02/2007      : Stored Procedure Created.
-- 08/02/2007      : Changed by KISHORE KUMAR A S. Changed Database Name from Customers to Documents.
-- 09/02/2007      : Changed by KISHORE KUMAR A S. Standardized with comments.Implemented the document log
--                   functionality
-- 06/13/2007      : Changed by Kiran Kusumba. Added an input parameter @IPVC_DateSent.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [documents].[uspDOCUMENTS_UpdateDocument] (
                                                              @IPVC_DocumentID        varchar(22),
                                                              @IPVC_DocumentTypeCode  varchar(5),
                                                              @IPVC_DocumentLevelCode varchar(5), 
                                                              @IPVC_Name              varchar(255),
                                                              @IPVC_Description       varchar(8000),
                                                              @IPVC_FamilyCode        varchar(3)  = NULL,
                                                              @IPVC_AgreementAddendum varchar(800)= NULL,
                                                              @IPB_AgreementExecutedFlag bit      = 0,
                                                              @IPB_ActiveFlag            bit      = 1, 
                                                              @IPVC_DocumentPath        varchar(255),
                                                              @IPB_AttachmentFlag       bit,  
                                                              @IPVC_AgreementSignedDate datetime, 
                                                              @IPVC_AgreementSentDate   datetime,
                                                              @IPVC_ModifiedBy          varchar(70),      
                                                              @IPB_PrintOnInvoiceFlag   bit = 0,
                                                              @IPVC_CreditIDSeq         varchar(50) 
                                                     )
AS
BEGIN

  /********************************************************************************************/
  /*                          INSERTING TO DOCUMENT LOG                                       */  
  /********************************************************************************************/
  INSERT INTO Documents.dbo.DocumentLog 
              (DocumentIDSeq,DocumentTypeCode,DocumentLevelCode,Name,Description,
               CompanyIDSeq,PropertyIDSeq,AccountIDSeq,QuoteIDSeq,QuoteItemIdSeq,OrderIDSeq,OrderItemIDSeq,
               InvoiceIDSeq,InvoiceItemIDSeq,FamilyCode,AgreementAddendum,AgreementExecutedFlag,
               ActiveFlag,DocumentPath,AttachmentFlag,AgreementSignedDate,AgreementSentDate,
               CreatedBy,ModifiedBy,CreatedDate,ModifiedDate,LogDate,CreditMemoIDSeq)

  SELECT TOP  1
              DocumentIDSeq,DocumentTypeCode,DocumentLevelCode,Name,Description,
              CompanyIDSeq,PropertyIDSeq,AccountIDSeq,QuoteIDSeq,QuoteItemIdSeq,OrderIDSeq,OrderItemIDSeq,
              InvoiceIDSeq,InvoiceItemIDSeq,FamilyCode,AgreementAddendum,AgreementExecutedFlag,
              ActiveFlag,DocumentPath,AttachmentFlag,AgreementSignedDate,AgreementSentDate,
              CreatedBy,ModifiedBy,CreatedDate,ModifiedDate,getdate() as LogDate,CreditMemoIDSeq
  FROM    
              Documents.Dbo.[Document] D with (nolock)
  WHERE   
              DocumentIDSeq = @IPVC_DocumentID
          
  /******************************************************************************************/



  /*******************************************************************************************/
  /*                                UPDATE STATEMENT                                         */  
  /*******************************************************************************************/   
	IF (@IPVC_AgreementSignedDate='')
	BEGIN
		SET @IPVC_AgreementSignedDate=null
	END

	IF (@IPVC_AgreementSentDate='')
	BEGIN
		SET @IPVC_AgreementSentDate=null
	END
 
  UPDATE  
          Documents.dbo.[Document]
  SET         
          DocumentTypeCode  = @IPVC_DocumentTypeCode,
          DocumentLevelCode = @IPVC_DocumentLevelCode,
          Name              = @IPVC_Name,
          Description       = @IPVC_Description,
          FamilyCode        = @IPVC_FamilyCode,
          AgreementAddendum = @IPVC_AgreementAddendum,
          AgreementExecutedFlag = @IPB_AgreementExecutedFlag,
          ActiveFlag            = @IPB_ActiveFlag,
          DocumentPath          = @IPVC_DocumentPath,
          AttachmentFlag        = @IPB_AttachmentFlag,
          AgreementSignedDate   = @IPVC_AgreementSignedDate,
          AgreementSentDate     = @IPVC_AgreementSentDate,          
          ModifiedBy            = @IPVC_ModifiedBy,          
          ModifiedDate          = getdate(),
          PrintOnInvoiceFlag    = @IPB_PrintOnInvoiceFlag,
          CreditMemoIDSeq       = @IPVC_CreditIDSeq
  WHERE   
          DocumentIDSeq       =   @IPVC_DocumentID
  /********************************************************************************************/    

END
GO
