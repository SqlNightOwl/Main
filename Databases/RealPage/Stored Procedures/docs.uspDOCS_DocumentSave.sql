SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Procedure  : uspDOCS_DocumentSave

Purpose    :  Saves Data into Document table.  Also adds data into DocumentHistory table.
             
Parameters : 

Returns    : code indicating if the Insert were successful

Date         Author                  Comments
-------------------------------------------------------
05/02/2008   Bhavesh Shah              Initial Creation


Example: EXEC uspDOCS_DocumentSave

Copyright  : copyright (c) 2000.  RealPage Inc.
This module is the confidential & proprietary property of
RealPage Inc.
*/
CREATE Procedure [docs].[uspDOCS_DocumentSave]
(
  @IP_DocumentIDSeq varchar (22),
  @IP_IterationCount bigint,
  @IP_StatusCode varchar (3),
  @IP_DocumentClassIDSeq bigint,
  @IP_ScopeCode varchar (3),
  @IP_Name varchar (255),
  @IP_Description varchar (4000),
  @IP_CompanyIDSeq varchar (11),
  @IP_PropertyIDSeq varchar (11),
  @IP_AccountIDSeq varchar (11),
  @IP_ContractIDSeq varchar(22),
  @IP_QuoteIDSeq varchar (22),
  @IP_OrderIDSeq varchar (22),
  @IP_InvoiceIDSeq varchar (22),
  @IP_CreditMemoIDSeq varchar (22),
  @IP_ActiveFlag bit,
  @IP_DocumentPath varchar (255),
  @IP_AttachmentFlag bit,
  @IP_CreatedBy varchar (70),
  @IP_ModifiedBy varchar (70),
  @IP_CreatedDate datetime,
  @IP_ModifiedDate datetime,
  @IP_InsertHistory bit = 1 
)
AS
  Declare @LVC_DocumentIDSeq VARCHAR(22)
  DECLARE @LI_IterationCount int;
 
  IF ( @IP_DocumentIDSeq is not null )
  BEGIN
    BEGIN TRY
      BEGIN TRANSACTION;

        -- No Need to update the IterationCount if not inserting into History.
        IF ( @IP_InsertHistory = 1 )
        BEGIN
          -- Get Next Iteration Count and lock the table to no one else can update the iteration count.
          SELECT @LI_IterationCount=ISNULL(MAX(IterationCount), 0) FROM DocumentHistory WITH (TABLOCKX,XLOCK,HOLDLOCK) WHERE DocumentIDSeq = @IP_DocumentIDSeq
          SET @LI_IterationCount = @LI_IterationCount + 1;
        END

        -- Update Document table with next iteration count.
        UPDATE Document SET
          IterationCount=ISNULL(@LI_IterationCount,IterationCount)
          , StatusCode=@IP_StatusCode, DocumentClassIDSeq=@IP_DocumentClassIDSeq, ScopeCode=@IP_ScopeCode
          , Name=@IP_Name, Description=@IP_Description, CompanyIDSeq=@IP_CompanyIDSeq
          , PropertyIDSeq=@IP_PropertyIDSeq, AccountIDSeq=@IP_AccountIDSeq, ContractIDSeq=@IP_ContractIDSeq
          , QuoteIDSeq=@IP_QuoteIDSeq, OrderIDSeq=@IP_OrderIDSeq, InvoiceIDSeq=@IP_InvoiceIDSeq, CreditMemoIDSeq=@IP_CreditMemoIDSeq
          , ActiveFlag=@IP_ActiveFlag, DocumentPath=@IP_DocumentPath, AttachmentFlag=@IP_AttachmentFlag
          , CreatedBy=@IP_CreatedBy, ModifiedBy=@IP_ModifiedBy, CreatedDate=@IP_CreatedDate
          , ModifiedDate=@IP_ModifiedDate
        OUTPUT 
          INSERTED.DocumentIDSeq as DocumentIDSeq, INSERTED.IterationCount as IterationCount
        Where 
          DocumentIDSeq = @IP_DocumentIDSeq
        
        IF ( @IP_InsertHistory = 1 )
        BEGIN
          -- Add New Record to History table.
          EXEC uspDOCS_DocumentHistoryInsert null, @IP_DocumentIDSeq, @LI_IterationCount, @IP_StatusCode, @IP_DocumentClassIDSeq, @IP_ScopeCode,
                                             @IP_Name, @IP_Description, @IP_CompanyIDSeq, @IP_PropertyIDSeq, @IP_AccountIDSeq,
                                             @IP_ContractIDSeq, @IP_QuoteIDSeq,@IP_OrderIDSeq, @IP_InvoiceIDSeq, @IP_CreditMemoIDSeq, @IP_ActiveFlag,
                                             @IP_DocumentPath, @IP_AttachmentFlag, @IP_CreatedBy, @IP_ModifiedBy, @IP_CreatedDate, @IP_ModifiedDate
        END
          
      COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
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
      EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Docs Update Section'
    END CATCH
  END
  ELSE
  BEGIN
    BEGIN TRY
      BEGIN TRANSACTION; 
        update IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
        set    IDSeq = IDSeq+1,
               GeneratedDate =CURRENT_TIMESTAMP
        where  TypeIndicator = 'D'
        select @LVC_DocumentIDSeq = IDGeneratorSeq
        from   IDGenerator with (NOLOCK)
        where  TypeIndicator = 'D'
       
        -- This is a new Document to Iteration will be 0;    
        SET @LI_IterationCount = 0;
        
        -- Insert document.
        INSERT INTO Document
          (DocumentIDSeq, IterationCount
           , StatusCode, DocumentClassIDSeq, ScopeCode
           , Name, Description, CompanyIDSeq
           , PropertyIDSeq, AccountIDSeq, ContractIDSeq
           , QuoteIDSeq,OrderIDSeq,InvoiceIDSeq, CreditMemoIDSeq
           , ActiveFlag, DocumentPath, AttachmentFlag
           , CreatedBy, ModifiedBy, CreatedDate
           , ModifiedDate)
        OUTPUT 
           INSERTED.DocumentIDSeq as DocumentIDSeq, INSERTED.IterationCount as IterationCount
        VALUES
          (@LVC_DocumentIDSeq, @LI_IterationCount
           , @IP_StatusCode, @IP_DocumentClassIDSeq, @IP_ScopeCode
           , @IP_Name, @IP_Description, @IP_CompanyIDSeq
           , @IP_PropertyIDSeq, @IP_AccountIDSeq, @IP_ContractIDSeq
           , @IP_QuoteIDSeq,@IP_OrderIDSeq,@IP_InvoiceIDSeq, @IP_CreditMemoIDSeq
           , @IP_ActiveFlag, @IP_DocumentPath, @IP_AttachmentFlag
           , @IP_CreatedBy, @IP_ModifiedBy, @IP_CreatedDate
           , @IP_ModifiedDate)

        IF ( @IP_InsertHistory = 1 )
        BEGIN
          -- Insert Document History.
          EXEC uspDOCS_DocumentHistoryInsert null, @LVC_DocumentIDSeq, @LI_IterationCount, @IP_StatusCode, @IP_DocumentClassIDSeq, @IP_ScopeCode,
                                             @IP_Name, @IP_Description, @IP_CompanyIDSeq, @IP_PropertyIDSeq, @IP_AccountIDSeq,
                                             @IP_ContractIDSeq, @IP_QuoteIDSeq,@IP_OrderIDSeq, @IP_InvoiceIDSeq, @IP_CreditMemoIDSeq, @IP_ActiveFlag,
                                             @IP_DocumentPath, @IP_AttachmentFlag, @IP_CreatedBy, @IP_ModifiedBy, @IP_CreatedDate, @IP_ModifiedDate
        END
           
      COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
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
      EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Docs Insert Section'
    END CATCH
  END

GO
