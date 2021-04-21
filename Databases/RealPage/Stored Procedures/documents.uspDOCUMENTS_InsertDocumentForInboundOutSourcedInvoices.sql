SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_InsertDocumentForInboundOutSourcedInvoices
-- Description     : This procedure is for creating a Document record for Inbound Invoice OutSourced Invoices
--
-- Input Parameters:   @IPVC_DocumentTypeCode  varchar
--                     @IPVC_DocumentLevelCode varchar
--                     @IPVC_CompanyIDSeq      varchar
--                     @IPVC_InvoiceIDSeq      varchar
--                     @IPVC_CreatedBy         varchar

-- 
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_InsertDocumentForInboundOutSourcedInvoices 
--                     @IPVC_DocumentTypeCode  = 'NOTE' 
--                     @IPVC_DocumentLevelCode = 'INV'
--                     @IPVC_CompanyIDSeq      = 'Cxxxxxxxxxx'
--                     @IPVC_InvoiceIDSeq      = 'Ixxxxxxxxxx'
--                     @IPVC_DocumentPath      = 'Invoices\'
--                     @IPVC_CreatedBy         = 'Wendy Parks'
--                     @IPBI_UserIDSeq         = '123'
-- Revision History:
-- Author          : SRS
-- 02/10/2010      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [documents].[uspDOCUMENTS_InsertDocumentForInboundOutSourcedInvoices] (@IPVC_DocumentTypeCode  varchar(5)='NOTE',
                                                                                  @IPVC_DocumentLevelCode varchar(5)='INV',
                                                                                  @IPVC_CompanyIDSeq      varchar(50),
                                                                                  @IPVC_InvoiceIDSeq      varchar(50),
                                                                                  @IPVC_DocumentPath      varchar(500)='Invoices\',
                                                                                  @IPVC_CreatedBy         varchar(70) ='', ---> MANDATORY : User Name of the User Logged on and doing the operation.
                                                                                  @IPBI_UserIDSeq         bigint      =-1  ---> MANDATORY : User ID of the User Logged on and doing the operation.
                                                                                 )
AS
BEGIN -->:Main Begin
  set nocount on;
  -----------------------------------------------------
  declare @LVC_CodeSection   varchar(500),
          @LVC_AccountIDSeq  varchar(50),
          @LVC_PropertyIDSeq varchar(50),
          @LI_Count          bigint,
          @LVC_Name          varchar(100),
          @LVC_Description   varchar(100),
          @LVC_DocumentIDSeq varchar(22),
          @LDT_SystemDate    datetime
  -----------------------------------------------------
  select  @LDT_SystemDate = Getdate(),
          @IPVC_CreatedBy = nullif(ltrim(rtrim(@IPVC_CreatedBy)),'')
  -----------------------------------------------------
  --Preliminary validation and Select
  if not exists (select top 1 1 
                 from   Invoices.dbo.Invoice I with (nolock)
                 where  I.InvoiceIDSeq = @IPVC_InvoiceIDSeq
                 and    I.CompanyIDSeq = @IPVC_CompanyIDSeq
                 and    I.Printflag    = 1 
                )
  begin
    select @LVC_CodeSection = 'Proc:uspDOCUMENTS_InsertDocumentForInboundOutSourcedInvoices.Invoice: ' + @IPVC_InvoiceIDSeq + ' For Company: ' +  @IPVC_CompanyIDSeq + ' with printflag=1 is not found in OMS'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return
  end
  else
  begin
    select Top 1 
           @LVC_AccountIDSeq  =I.AccountIDSeq,
           @LVC_PropertyIDSeq =I.PropertyIDSeq
    from   Invoices.dbo.Invoice I with (nolock)
    where  I.InvoiceIDSeq = @IPVC_InvoiceIDSeq
    and    I.CompanyIDSeq = @IPVC_CompanyIDSeq
    and    I.Printflag    = 1
  end
  -----------------------------------------------------
  --Step1 : Find count of previous instance of same Invoice if any
  select @LI_Count = count(D.DocumentIDSeq)+1
  from   Documents.dbo.Document D with (nolock)
  where  D.InvoiceIDSeq = @IPVC_InvoiceIDSeq
  and    D.CompanyIDSeq = @IPVC_CompanyIDSeq
  -----------------------------------------------------
  --Step2 : set @LVC_Name,@LVC_Description,@IPVC_DocumentPath accordingly.
  select @LVC_Name          = (case when @LI_Count=1 then @IPVC_InvoiceIDSeq else @IPVC_InvoiceIDSeq + '_Reprint'+convert(varchar(50),@LI_Count) end),
         @LVC_Description   = (case when @LI_Count=1 then @IPVC_InvoiceIDSeq + '_FirstPrint' else @IPVC_InvoiceIDSeq + '_Reprint'+convert(varchar(50),@LI_Count) end),
         @IPVC_DocumentPath = (case when right(@IPVC_DocumentPath,1)<> '\' then @IPVC_DocumentPath+'\' else @IPVC_DocumentPath end)
  -----------------------------------------------------
  --Step3 : Generate New DocumentID and Insert into Document.
  begin TRY
    BEGIN TRANSACTION;
      update DOCUMENTS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
      set    IDSeq = IDSeq+1,
             GeneratedDate =CURRENT_TIMESTAMP

      select @LVC_DocumentIDSeq = DocumentIDSeq
      from   DOCUMENTS.DBO.IDGenerator with (NOLOCK)

      Insert into DOCUMENTS.DBO.Document(DocumentIDSeq,DocumentTypeCode,DocumentLevelCode,
                                         Name,Description,
                                         CompanyIDSeq,PropertyIDSeq,AccountIDSeq,InvoiceIDSeq,
                                         ActiveFlag,AttachmentFlag,PrintOnInvoiceFlag,
                                         DocumentPath,
                                         CreatedBy,CreatedByIDSeq,CreatedDate
                                        )
      select @LVC_DocumentIDSeq as DocumentIDSeq,coalesce(@IPVC_DocumentTypeCode,'NOTE') as DocumentTypeCode,coalesce(@IPVC_DocumentLevelCode,'INV') as DocumentLevelCode,
             @LVC_Name as Name,@LVC_Description as Description,
             @IPVC_CompanyIDSeq as CompanyIDSeq,@LVC_PropertyIDSeq as PropertyIDSeq,@LVC_AccountIDSeq as AccountIDSeq,
             @IPVC_InvoiceIDSeq as InvoiceIDSeq,1 as ActiveFlag,1 as AttachmentFlag,1 as PrintOnInvoiceFlag,
             @IPVC_DocumentPath+@LVC_DocumentIDSeq+'.pdf' as DocumentPath,
             @IPVC_CreatedBy    as CreatedBy,@IPBI_UserIDSeq as CreatedByIDSeq,
             @LDT_SystemDate    as CreatedDate
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
    select '<?:*:?>' as DocumentIDSeq
    select @LVC_CodeSection = 'Proc:uspDOCUMENTS_InsertDocumentForInboundOutSourcedInvoices.Document record Insert Failed'
    EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 
    return  
  end CATCH
  -----------------------------------------------------
  --Final Select 
  select @LVC_DocumentIDSeq as DocumentIDSeq
  -----------------------------------------------------
END
GO
