SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_DeleteDocument
-- Description     : This procedure deletes Document Details pertaining to passed 
--                        DocumentID

-- Input Parameters: @IPVC_DocumentID bigint
-- 
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_DeleteDocument 
--                   @IPVC_DocumentID = 17
-- Revision History:
-- Author          : KISHORE KUMAR A S 
-- 07/02/2007      : Stored Procedure Created.
-- 08/02/2007      : Changed by KISHORE KUMAR A S. Changed Database Name from Customers to Documents.
-- 09/02/2007      : Changed by KISHORE KUMAR A S. Standardized with comments.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [documents].[uspDOCUMENTS_DeleteDocument] (
                                                       @IPVC_DocumentID   varchar(22)
                                                      )
as
begin   -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Local variable declaration                                                */  
        /*********************************************************************************************/
    
       declare    @LVC_DocumentTypeCode varchar(5)
       declare    @LVC_DocumentLevelCode varchar(5)
       declare    @LVC_Name varchar(255)
       declare    @LVC_Description varchar(1500)
       declare    @LVC_CompanyIDSeq varchar(22) 
       declare    @LVC_PropertyIDSeq varchar(22)
       declare    @LVC_AccountIDSeq varchar(22)
       declare    @LVC_QuoteIDSeq varchar(22)
       declare    @LBI_QuoteItemIDSeq bigint 
       declare    @LVC_OrderIDSeq varchar(22)
       declare    @LVC_OrderItemIDSeq varchar(22)
       declare    @LVC_InvoiceIDSeq varchar(22)
       declare    @LVC_DocumentPath varchar(255)
       declare    @LVC_CreatedBy varchar(70)
       declare    @LVC_ModifiedBy varchar(70)
       declare    @LVC_CreatedDate datetime
       declare    @LVC_ModifiedDate datetime

        /*********************************************************************************************/
        /*                 updating ActiveFlag status in Document Tabl e                             */  
        /*********************************************************************************************/        

       update Documents.dbo.[Document] set ActiveFlag = 0 where DocumentIDSeq =  @IPVC_DocumentID
 
        /*********************************************************************************************/
        /*                 Local variable initialization                                             */  
        /*********************************************************************************************/

       select 
              @LVC_DocumentTypeCode = DocumentTypeCode,
              @LVC_DocumentLevelCode = DocumentLevelCode,
              @LVC_Name = Name,
              @LVC_Description = Description,
              @LVC_CompanyIDSeq = CompanyIDSeq,
              @LVC_PropertyIDSeq = PropertyIDSeq,
              @LVC_AccountIDSeq = AccountIDSeq,
              @LVC_QuoteIDSeq = QuoteIDSeq,
              @LBI_QuoteItemIDSeq = QuoteItemIDSeq, 
              @LVC_OrderIDSeq = OrderIDSeq,
              @LVC_OrderItemIDSeq = OrderItemIDSeq,
              @LVC_InvoiceIDSeq = InvoiceIDSeq,
              @LVC_DocumentPath = DocumentPath,
              @LVC_CreatedBy = CreatedBy,
              @LVC_ModifiedBy = ModifiedBy,
              @LVC_CreatedDate = CreatedDate,
              @LVC_ModifiedDate  = ModifiedDate
       from   Documents.dbo.[Document]
       where  DocumentIDSeq =  @IPVC_DocumentID 
            
        /*********************************************************************************************/
        /*                 insert query for inserting Document Log                                   */  
        /*********************************************************************************************/


       insert into Documents.dbo.DocumentLog
      (
           DocumentIDSeq, 
           DocumentTypeCode,
           DocumentLevelCode,
           Name,
           Description,
           CompanyIDSeq,
           PropertyIDSeq,
           AccountIDSeq,
           QuoteIDSeq,
           QuoteItemIDSeq,
           OrderIDSeq,
           OrderItemIDSeq,
           InvoiceIDSeq,
           ActiveFlag,
           DocumentPath,
           CreatedBy,
           ModifiedBy,                    
           CreatedDate,
           ModifiedDate,
           LogDate    
      ) 
      values
      (
           @IPVC_DocumentID,
           @LVC_DocumentTypeCode,
           @LVC_DocumentLevelCode, 
           @LVC_Name,
           @LVC_Description,
           @LVC_CompanyIDSeq,
           @LVC_PropertyIDSeq,
           @LVC_AccountIDSeq,
           @LVC_QuoteIDSeq,
           @LBI_QuoteItemIDSeq,
           @LVC_OrderIDSeq,
           @LVC_OrderItemIDSeq,
           @LVC_InvoiceIDSeq,   
           0,
           @LVC_DocumentPath,
           @LVC_CreatedBy,
           @LVC_ModifiedBy,
           @LVC_CreatedDate,
           @LVC_ModifiedDate,
           GETDATE()
      )  

END -- Main BEGIN starts at Col 01

GO
