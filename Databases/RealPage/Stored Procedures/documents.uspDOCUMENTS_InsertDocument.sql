SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_InsertDocument
-- Description     : This procedure insert Document 
--
-- Input Parameters:   as Below
-- 
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_InsertDocument 
--                     @IPVC_DocumentTypeCode  = 'NOTE' 
--                     @IPVC_DocumentLevelCode = 'INV'
--                     @IPVC_Name              = 'Ixxxxxxxxxx'
--                     @IPVC_Description       = 'Ixxxxxxxxxx_FirstPrint'
--                     @IPVC_CompanyIDSeq      = 'Cxxxxxxxxxx'
--                     @IPVC_InvoiceIDSeq      = 'Ixxxxxxxxxx'
--                     @IPVC_DocumentPath      = 'Invoices\'
--                     @IPVC_CreatedBy         = 'Sample user'
--                     @IPBI_UserIDSeq         = '123'
-- Revision History:
-- Author          : 
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [documents].[uspDOCUMENTS_InsertDocument] (
                                                      @IPVC_DocumentTypeCode     varchar(5),             ---> MANDATORY
                                                      @IPVC_DocumentLevelCode    varchar(5),             ---> MANDATORY
                                                      @IPVC_Name                 varchar(255)    = NULL, ---> MANDATORY
                                                      @IPVC_Description          varchar(8000)   = NULL, ---> Optional
                                                      @IPVC_CompanyIDSeq         varchar(50),            ---> MANDATORY 
                                                      @IPVC_PropertyIDSeq        varchar(50)     = NULL,
                                                      @IPVC_AccountIDSeq         varchar(50)     = NULL,
                                                      @IPVC_QuoteIDSeq           varchar(50)     = NULL,
                                                      @IPVC_OrderIDSeq           varchar(50)     = NULL,
                                                      @IPVC_OrderItemIDSeq       varchar(50)     = NULL,
                                                      @IPVC_InvoiceIDSeq         varchar(50)     = NULL,
                                                      @IPVC_InvoiceItemIDSeq     varchar(50)     = NULL,
                                                      @IPVC_FamilyCode           varchar(3)      = NULL,
                                                      @IPVC_AgreementAddendum    varchar(800)    = NULL,
                                                      @IPB_AgreementExecutedFlag bit             = 0,
                                                      @IPVC_DocumentPath         varchar(255)    = NULL, ---> MANDATORY 
                                                      @IPB_AttachmentFlag        bit             = 0,  
                                                      @IPVC_AgreementSignedDate  datetime        = NULL, 
                                                      @IPVC_AgreementSentDate    datetime        = NULL,
                                                      @IPVC_CreatedBy            varchar(70)     = '', ---> MANDATORY : User Name of the User Logged on and doing the operation.    
                                                      @IPB_PrintOnInvoiceFlag    bit             = 0,
                                                      @IPVC_CreditIDSeq          varchar(50)     = NULL,
                                                      @IPN_AgreementIDSeq        numeric(18,0)   = NULL,
                                                      @IPBI_UserIDSeq            bigint          = -1  ---> MANDATORY : User ID of the User Logged on and doing the operation. 
                                                     )
AS
BEGIN
  set nocount on
  ------------------------------------------------------------- 
  Declare @LVC_DocumentIDSeq    varchar(50), 
          @LVC_DocumentPath     varchar(255),
          @LVC_docLevel         varchar(70),
          @LVC_CodeSection      varchar(1000),
          @LDT_SystemDate       datetime 
  ------------------------------------------------------------- 
  select  @LDT_SystemDate            = Getdate(),
          @IPVC_CreatedBy            = nullif(ltrim(rtrim(@IPVC_CreatedBy)),''),
          @LVC_DocumentPath          = nullif(ltrim(rtrim(@IPVC_DocumentPath)),''),
          @IPVC_Name                 = nullif(ltrim(rtrim(@IPVC_Name)),''),
          @IPVC_Description          = nullif(ltrim(rtrim(@IPVC_Description)),''),
          @IPVC_CompanyIDSeq         = nullif(ltrim(rtrim(@IPVC_CompanyIDSeq)),''),
          @IPVC_PropertyIDSeq        = nullif(ltrim(rtrim(@IPVC_PropertyIDSeq)),''),
          @IPVC_AccountIDSeq         = nullif(ltrim(rtrim(@IPVC_AccountIDSeq)),''),
          @IPVC_QuoteIDSeq           = nullif(ltrim(rtrim(@IPVC_QuoteIDSeq)),''),
          @IPVC_OrderIDSeq           = nullif(ltrim(rtrim(@IPVC_OrderIDSeq)),''),
          @IPVC_OrderItemIDSeq       = nullif(ltrim(rtrim(@IPVC_OrderItemIDSeq)),''),
          @IPVC_InvoiceIDSeq         = nullif(ltrim(rtrim(@IPVC_InvoiceIDSeq)),''),
          @IPVC_InvoiceItemIDSeq     = nullif(ltrim(rtrim(@IPVC_InvoiceItemIDSeq)),''),
          @IPVC_FamilyCode           = nullif(ltrim(rtrim(@IPVC_FamilyCode)),''),
          @IPVC_AgreementAddendum    = nullif(ltrim(rtrim(@IPVC_AgreementAddendum)),''),
          @IPVC_CreditIDSeq          = nullif(ltrim(rtrim(@IPVC_CreditIDSeq)),''),
          @IPN_AgreementIDSeq        = nullif(ltrim(rtrim(@IPN_AgreementIDSeq)),''),
          @IPVC_AgreementSignedDate  = (case when isdate(@IPVC_AgreementSignedDate)=0 then NULL else @IPVC_AgreementSignedDate end),
          @IPVC_AgreementSentDate    = (case when isdate(@IPVC_AgreementSentDate)=0 then NULL else @IPVC_AgreementSentDate end)
  -------------------------------------------------------------
  If (@LVC_DocumentPath IS NULL)
  begin
    select Top 1 @LVC_docLevel = [Name] 
    from   Documents.dbo.[DocumentLevel] with (nolock)
    where  Code = coalesce(@IPVC_DocumentLevelCode,'')

    if LEN(@LVC_docLevel) > 0
    begin
      select @LVC_DocumentPath = @LVC_docLevel + '\'
    end
  end;
  -------------------------------------------------------------
  --Validation for @LVC_DocumentPath (This should not be Null)
  If (@LVC_DocumentPath IS NULL) 
  begin
    select @LVC_CodeSection = 'Proc:uspDOCUMENTS_InsertDocument: Document path cannot be null NULL'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return
  end

  select @LVC_DocumentPath = (case when right(@LVC_DocumentPath,1)<> '\' then @LVC_DocumentPath+'\' else @LVC_DocumentPath end)  
  -------------------------------------------------------------
  --Validation before Inserting Documents
  select Top 1 @LVC_DocumentIDSeq = DocumentIDSeq
  from   Documents.dbo.[Document] With (nolock)
  where  CompanyIDSeq                                 =@IPVC_CompanyIDSeq 
  and    DocumentTypeCode                             =@IPVC_DocumentTypeCode
  and    DocumentLevelCode                            =@IPVC_DocumentLevelCode
  and    coalesce(PropertyIDSeq,'')                   =coalesce(@IPVC_PropertyIDSeq,'')
  and    coalesce(AccountIDSeq,'')                    =coalesce(@IPVC_AccountIDSeq,'') 
  and    coalesce(QuoteIDSeq,'')                      =coalesce(@IPVC_QuoteIDSeq,'')
  and    ActiveFlag                                   =1
  and    coalesce(Description,'')                     =coalesce(@IPVC_Description,'')
  and    coalesce(OrderIDSeq,'')                      =coalesce(@IPVC_OrderIDSeq,'')
  and    coalesce(OrderItemIDSeq,0)                   =coalesce(@IPVC_OrderItemIDSeq,0)
  and    coalesce(InvoiceIDSeq,'')                    =coalesce(@IPVC_InvoiceIDSeq,'')
  and    coalesce(InvoiceItemIDSeq,0)                 =coalesce(@IPVC_InvoiceItemIDSeq,0)
  and    coalesce(FamilyCode,'')                      =coalesce(@IPVC_FamilyCode,'')
  and    coalesce(AgreementAddendum,'')               =coalesce(@IPVC_AgreementAddendum,'')
  and    coalesce(DocumentPath,'')                    =coalesce(@IPVC_DocumentPath,'')
  and    coalesce(AttachmentFlag,0)                   =coalesce(@IPB_AttachmentFlag,0)
  and    coalesce(AgreementSignedDate,'')             =coalesce(@IPVC_AgreementSignedDate,'')
  and    coalesce(AgreementSentDate,'')               =coalesce(@IPVC_AgreementSentDate,'')
  and    coalesce(PrintOnInvoiceFlag,0)               =coalesce(@IPB_PrintOnInvoiceFlag,0)
  and    coalesce(CreditMemoIDSeq,'')                 =coalesce(@IPVC_CreditIDSeq,'')
  and    coalesce(AgreementIDSeq,0)                   =coalesce(@IPN_AgreementIDSeq,0)
  and    coalesce(Name,'')                            =coalesce(@IPVC_Name,'')
  -------------------------------------------------------------
  if (@LVC_DocumentIDSeq is not null and @LVC_DocumentIDSeq <> '')
  begin
    select @LVC_DocumentIDSeq as DocumentIDSeq
    return
  end
  else
  begin     
    begin TRY
      BEGIN TRANSACTION; 
        update DOCUMENTS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
        set    IDSeq = IDSeq+1,
               GeneratedDate =CURRENT_TIMESTAMP;

        select @LVC_DocumentIDSeq = DocumentIDSeq
        from   DOCUMENTS.DBO.IDGenerator with (NOLOCK);    

	SELECT @LVC_DocumentPath = @LVC_DocumentPath + @LVC_DocumentIDSeq + '.PDF';

        INSERT INTO Documents.dbo.[Document](DocumentIDSeq,DocumentTypeCode,DocumentLevelCode,
                                             Name,Description,
                                             CompanyIDSeq,PropertyIDSeq,AccountIDSeq,
                                             QuoteIDSeq,OrderIDSeq,OrderItemIDSeq,InvoiceIDSeq,InvoiceItemIDSeq,
                                             FamilyCode,AgreementAddendum,AgreementExecutedFlag,ActiveFlag,DocumentPath,
                                             AttachmentFlag,AgreementSignedDate,AgreementSentDate,
                                             PrintOnInvoiceFlag,CreditMemoIDSeq,
                                             AgreementIDSeq,
                                             CreatedBy,CreatedByIDSeq,CreatedDate
                                             )
        select @LVC_DocumentIDSeq,
               @IPVC_DocumentTypeCode,@IPVC_DocumentLevelCode,@IPVC_Name,@IPVC_Description,
               @IPVC_CompanyIDSeq,@IPVC_PropertyIDSeq,@IPVC_AccountIDSeq,
               @IPVC_QuoteIDSeq,@IPVC_OrderIDSeq,@IPVC_OrderItemIDSeq,@IPVC_InvoiceIDSeq,@IPVC_InvoiceItemIDSeq,
               @IPVC_FamilyCode,@IPVC_AgreementAddendum,
               (case when @IPVC_DocumentTypeCode = 'AGGR' then 1 else @IPB_AgreementExecutedFlag end)
               ,1   as ActiveFlag,
               @LVC_DocumentPath,
               @IPB_AttachmentFlag,@IPVC_AgreementSignedDate,@IPVC_AgreementSentDate,
               @IPB_PrintOnInvoiceFlag,@IPVC_CreditIDSeq,@IPN_AgreementIDSeq,
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
      select @LVC_DocumentIDSeq = NULL
      EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Document Insert Section'
      return  
    end CATCH  
  end
  --------------------------------------------------------------------------------------------
  --Final Return 
  select @LVC_DocumentIDSeq as [DocumentIDSeq], @LVC_DocumentPath as [DocumentPath]
  --------------------------------------------------------------------------------------------
END
GO
