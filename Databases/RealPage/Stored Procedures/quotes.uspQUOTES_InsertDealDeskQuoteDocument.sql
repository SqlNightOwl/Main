SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_InsertDealDeskQuoteDocument
-- Description     : This procedure gets Called to INSERT any number Deal Desk documents for a given Quote and CompanyIDSeq
--                   Steps:
--Prerequisites :  UI already knows main path from web.config \\servername\omsfilerepository\{CompanyIDseq}\'
--                 IF Path folder does not exists, UI will take care of Creating a Folder in omsfilerepository  and also 
--                    inserting a record for company path by calling existing routines Exec DOCUMENTS.dbo.uspDOCUMENTS_InsertCompanyDocumentPath ...
--                 Now, UI will confirm folder "DealDesk" exists under \\servername\omsfilerepository\{CompanyIDseq}\DealDesk\ . If not it will create the folder.

/*
--Upon SAVE
--                 1)UI will make sure that the document.doc or document.eml that user is uploading is converted to unique QuoteIDSeq_uniqueRowGUID.doc or QuoteIDSeq_uniqueRowGUID.eml etc 
--                 2)UI will take care of placing the document named QuoteIDSeq+RowGUID under \\servername\omsfilerepository\{CompanyIDseq}\DealDesk\
--                 3)After confirming that a document exists, it then fires ONLY ONCE Exec QUOTES.dbo.uspQUOTES_InsertDealDeskQuoteDocument 
--                 4)It will then fire Exec QUOTES.dbo.uspQUOTES_GetDealDeskQuoteDocumentList @IPI_PageNumber=1,@IPI_RowsPerPage=5,
                                                       @IPVC_QuoteIDSeq='Q1104000100',
                                                       @IPVC_CompanyIDSeq='C0901002633',
                                                       @IPVC_DocumentType='DealDesk'
                    to refresh the DealDesk Documents tab 
*/ 

-- Input Parameters: As Below (all mandatory)
-- 
-- OUTPUT          : None

--syntax           : 
/*
Exec QUOTES.dbo.uspQUOTES_InsertDealDeskQuoteDocument  @IPVC_QuoteIDSeq  ='Q1104000100',
                                                       @IPVC_CompanyIDSeq='C0901002633',
                                                       @IPVC_DocumentType='DealDesk',
                                                       @IPVC_DocumentName='Sample document name',
                                                       @IPVC_DocumentNote='Special deal etc',
                                                       @IPVC_DocumentPath='DealDesk\Q1104000100_07000A0C-F0DE-4AFB-B3E7-D0B4DBDBBF49.doc', 
                                                       @IPBI_UserIDSeq   = 137

*/
-- Revision History:
-- Author          : SRS
-- 05/15/2011      : Stored Procedure Created.TFS : 267 : Deal Desk Project
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_InsertDealDeskQuoteDocument]  (@IPVC_QuoteIDSeq                 varchar(50),             ---> This is the QuoteIDSeq that UI is Operating under. UI knows this Q number
                                                                 @IPVC_CompanyIDSeq               varchar(50),             ---> This is the CompanyIDSeq that UI is Operating under. UI knows this C number associated with Q number in question.                                                                 
                                                                 @IPVC_DocumentType               varchar(50)  ='DealDesk',---> This is Document Type that UI is looking for. For Deal Desk, it is going to be 'DealDesk'
                                                                 @IPVC_DocumentName               varchar(100) ='',        ---> This is document Short Name
                                                                 @IPVC_DocumentNote               varchar(8000)='',        ---> This is document Description or Note associated with document.
                                                                 @IPVC_DocumentPath               varchar(500),            ---> This is document Path eg: 'DealDesk\QuoteIDseq+uniqueRowGUID.doc' 
                                                                 @IPBI_UserIDSeq                  bigint                   ---> MANDATORY : User ID of the User Logged on and operating on the Quote and uploading the document.         
                                                                )
AS
BEGIN-->Main Begin
  set nocount on;
  -----------------------------------------------------
  declare @LDT_SystemDate          datetime,
          @LVC_ErrorCodeSection    varchar(1000)
  select  @LDT_SystemDate = getdate()
  -----------------------------------------------------
  select @IPVC_QuoteIDSeq   = nullif(ltrim(rtrim(@IPVC_QuoteIDSeq)),''),
         @IPVC_CompanyIDSeq = nullif(ltrim(rtrim(@IPVC_CompanyIDSeq)),''),
         @IPVC_DocumentType = nullif(ltrim(rtrim(@IPVC_DocumentType)),''),
         @IPVC_DocumentName = nullif(ltrim(rtrim(@IPVC_DocumentName)),''),
         @IPVC_DocumentNote = nullif(ltrim(rtrim(@IPVC_DocumentNote)),''),
         @IPVC_DocumentPath = nullif(ltrim(rtrim(@IPVC_DocumentPath)),'')
  -----------------------------------------------------
  --Validation(s)
  -----------------------------------------------------
  --Step1: QuoteID and CustomerID should be valid and belong to each other.
  if not exists (select top 1 1
                 from   Quotes.dbo.Quote Q with (nolock)
                 where  Q.QuoteIDSeq    = @IPVC_QuoteIDSeq
                 and    Q.CustomerIDSeq = @IPVC_CompanyIDSeq
                 )
  begin
    select @LVC_ErrorCodeSection= 'Quote : ' + @IPVC_QuoteIDSeq + ' belonging to CompanyIDSeq : ' + @IPVC_CompanyIDSeq + ' does not exists in system. Aboting adding Document(s)...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    return;
  end
  -----------------------------------------------------
  --Step2: @IPVC_DocumentPath cannot be null
  if (@IPVC_DocumentPath is null or len(@IPVC_DocumentPath)=0)
  begin
    select @LVC_ErrorCodeSection= 'Document Path is invalid and cannot be null. Quote : ' + @IPVC_QuoteIDSeq + ';CompanyIDSeq : ' + @IPVC_CompanyIDSeq + '. Aboting adding Document(s)...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    return;
  end
  -----------------------------------------------------
  --Step 3: Insert document for deal desk.
  BEGIN TRY
    BEGIN TRANSACTION QDI;
      Insert into QUOTES.dbo.QuoteDocument(QuoteIDSeq,CompanyIDSeq,DocumentType,
                                           DocumentName,DocumentNote,DocumentPath,
                                           ActiveFlag,CreatedByIDSeq,CreatedDate,SystemLogDate
                                          )
      select @IPVC_QuoteIDSeq   as QuoteIDSeq,@IPVC_CompanyIDSeq as CompanyIDSeq,@IPVC_DocumentType as DocumentType,
             @IPVC_DocumentName as DocumentName,@IPVC_DocumentNote as DocumentNote,@IPVC_DocumentPath as DocumentPath,
             1 as ActiveFlag,@IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
    COMMIT TRANSACTION QDI;
  END TRY
  BEGIN CATCH;    
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION QDI;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION QDI;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION QDI;
    select @LVC_ErrorCodeSection= 'Proc: uspQUOTES_InsertDealDeskQuoteDocument. Insert Deal Desk Document Failed. Quote : ' + @IPVC_QuoteIDSeq + ';CompanyIDSeq : ' + @IPVC_CompanyIDSeq + '. Aboting adding Document(s)...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    return;                  
  END CATCH;
  -----------------------------------------------------
END -- :Main End
GO
