SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_uspDOCUMENTS_CopyQuoteDocumentsToOrder
-- Description     : This procedure copies the documents of the Quote 
--                    to the generated order.
-- Input Parameters:   @IPVC_QuoteIDSeq        varchar
--                    
-- 
-- Code Example    :  Exec DOCUMENTS.dbo.uspDOCUMENTS_InsertDocument 
--                     @IPVC_QuoteIDSeq   = 'Q0000002503' 
--                     
-- Revision History:
-- Author          : Kiran Kusumba.
-- 07/12/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [documents].[uspDOCUMENTS_CopyQuoteDocumentsToOrder] (@IPVC_QuoteIDSeq  varchar(22)
                                                                )
AS
BEGIN
  --------------Declaration of Temporary table-----------------------------------------------
  DECLARE @LT_OrdersSummary           Table(RowNumber     int Identity(1,1),
                                            OrderIDSeq    varchar(22)
                                           )

  declare @LT_ExistingQuoteFootNotes  table (RowNumber              int  not null identity(1,1),
                                             ExistingDocumentIDSeq  varchar(50) NULL
                                             )
  ------------------------------------------------------------------------------------------- 
  declare @LI_OuterMin         int
  declare @LI_OuterMax         int
  declare @LI_InnerMin         int
  declare @LI_InnerMax         int
  declare @LVC_OrderIDSeq      varchar(22)
  declare @LVC_ExistingDocumentIDSeq varchar(22)
  declare @LVC_NewDocumentIDSeq varchar(22)
  -----------------------------------------------------------------------------------------
  Select @LI_OuterMin=1,@LI_OuterMax=0,@LI_InnerMin=1,@LI_InnerMax=0
  -----------------------------------------------------------------------------------------
  ----Get All existing Orders For Input QuoteIDSeq
  INSERT INTO @LT_OrdersSummary(OrderIDSeq)
  SELECT OrderIDSeq 
  FROM   ORDERS.dbo.[Order] with (nolock) 
  WHERE QuoteIDSeq = @IPVC_QuoteIDSeq 
  -----------------------------------------------------------------------------------------
  --Get Active FootNote DocumentIDs of Input QuoteIDSeq
  Insert into @LT_ExistingQuoteFootNotes(ExistingDocumentIDSeq)
  select DocumentIDSeq 
  from   DOCUMENTS.dbo.Document with (nolock)
  where QuoteIDSeq = @IPVC_QuoteIDSeq and DocumentTypeCode = 'FNOT' and ActiveFlag = 1
  -----------------------------------------------------------------------------------------
  SELECT @LI_OuterMax = Count(*) FROM @LT_OrdersSummary
  select @LI_InnerMax = Count(*) from @LT_ExistingQuoteFootNotes

  WHILE @LI_OuterMin <= @LI_OuterMax
  BEGIN --->Outer Loop Begin
    -------------------Get the OrderIDseq of the particular row----------------------------
    SELECT @LVC_OrderIDSeq = OrderIDSeq 
    FROM   @LT_OrdersSummary 
    WHERE  RowNumber = @LI_OuterMin 
    ------------------Loop Through @LT_ExistingQuoteFootNotes to insert Docs for this OrderId-------------  
    select @LI_InnerMin = 1    
    while @LI_InnerMin <= @LI_InnerMax
    begin --> Inner Loop Begin
      select @LVC_ExistingDocumentIDSeq = ExistingDocumentIDSeq 
      from @LT_ExistingQuoteFootNotes where RowNumber = @LI_InnerMin
      ----------------------------------------------------------------------------------------------------
      begin TRY
        BEGIN TRANSACTION; 
          update DOCUMENTS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
          set    IDSeq = IDSeq+1,
                 GeneratedDate =CURRENT_TIMESTAMP

          select @LVC_NewDocumentIDSeq = DocumentIDSeq
          from   DOCUMENTS.DBO.IDGenerator with (NOLOCK)

          Insert into DOCUMENTS.dbo.Document(DocumentIDSeq,DocumentTypeCode,DocumentLevelCode,
                                             Name,Description,CompanyIDSeq,PropertyIDSeq,AccountIDSeq,
                                             QuoteIDSeq,OrderIDSeq,OrderItemIDSeq,InvoiceIDSeq,InvoiceItemIDSeq,
                                             FamilyCode,AgreementAddendum,AgreementExecutedFlag,ActiveFlag,
                                             DocumentPath,AttachmentFlag,AgreementSignedDate,AgreementSentDate,
                                             CreatedBy,ModifiedBy,CreatedDate,ModifiedDate,PrintOnInvoiceFlag)
          select @LVC_NewDocumentIDSeq as DocumentIDSeq,
                 DocumentTypeCode,DocumentLevelCode,
                 Name,Description,CompanyIDSeq,PropertyIDSeq,AccountIDSeq,
                 @IPVC_QuoteIDSeq as QuoteIDSeq,
                 @LVC_OrderIDSeq  as OrderIDSeq,OrderItemIDSeq,InvoiceIDSeq,InvoiceItemIDSeq,
                 FamilyCode,AgreementAddendum,AgreementExecutedFlag,ActiveFlag,
                 DocumentPath,AttachmentFlag,AgreementSignedDate,AgreementSentDate,
                 CreatedBy,ModifiedBy,
                 getdate() as CreatedDate,getdate() as ModifiedDate,PrintOnInvoiceFlag
          from   DOCUMENTS.dbo.Document with (nolock)
          where  DocumentIDSeq    = @LVC_ExistingDocumentIDSeq 
          and    QuoteIDSeq       = @IPVC_QuoteIDSeq 
          and    DocumentTypeCode = 'FNOT'
          and    ActiveFlag = 1
        COMMIT TRANSACTION;
      end TRY
      begin CATCH    
        -- XACT_STATE:
        -- If 1, the transaction is committable.
        -- If -1, the transaction is uncommittable and should be rolled back.
        -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
        if (XACT_STATE()) = -1
        begin
          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        end
        else if (XACT_STATE()) = 1
        begin
          IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
        end   
        EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'uspDOCUMENTS_CopyQuoteDocumentsToOrder Insert Section'
        RETURN
      end CATCH      
      ------------------------------------------------------------------------------------------------------
      select @LI_InnerMin = @LI_InnerMin + 1
    end   --> Inner Loop End
    ------------------------------------------------------------------------------------------------------ 
    select @LI_InnerMin = 1 --- Reinitialize @LI_InnerMin again for inner loop for next OrderID
    SET @LI_OuterMin = @LI_OuterMin + 1
  -------------------------------------------------------------------------------  
  END --> Outer Loop End
  ------------------------------------------------------------------------------- 
  --Final Cleanup
  IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
  -------------------------------------------------------------------------------  
END

GO
