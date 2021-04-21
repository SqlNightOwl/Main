SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_UpdateDealDeskQuoteDocument
-- Description     : This procedure gets Called to Update ONLY  DocumentName,DocumentNote for an existing document
--                   Deal Desk Document tab, More-->Edit-->UI will detect any change to DocumentName,DocumentNote 
--                   and upon SAVE call Proc Exec QUOTES.dbo.uspQUOTES_UpdateDealDeskQuoteDocument
-- Input Parameters: As Below (all mandatory)
-- 
-- OUTPUT          : None

--syntax           : 
/*
Exec QUOTES.dbo.uspQUOTES_UpdateDealDeskQuoteDocument   @IPBI_QDocIDSeq   = 1
                                                       ,@IPVC_QuoteIDSeq  ='Q1104000100' 
                                                       ,@IPVC_DocumentType='DealDesk'                                                      
                                                       ,@IPVC_DocumentName='Sample document name Change'
                                                       ,@IPVC_DocumentNote='Special deal Note Change etc'
                                                       ,@IPBI_UserIDSeq   = 137
*/
-- Revision History:
-- Author          : SRS
-- 05/15/2011      : Stored Procedure Created.TFS : 267 : Deal Desk Project
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_UpdateDealDeskQuoteDocument]  (@IPBI_QDocIDSeq                  bigint,                  ---> Mandatory: This is the UNIQUE QDocIDSeq that is available in UI as hidden value. 
                                                                                                                            --  Returned by call of EXEC QUOTES.dbo.uspQUOTES_GetDealDeskQuoteDocumentList
                                                                 @IPVC_QuoteIDSeq                 varchar(50),             ---> Mandatory: This is the QuoteIDSeq that UI is Operating under. UI knows this Q number
                                                                 @IPVC_DocumentType               varchar(50)  ='DealDesk',---> Mandatory: This is Document Type that UI is looking for. For Deal Desk, it is going to be 'DealDesk'
                                                                 @IPVC_DocumentName               varchar(100) ='',        ---> This is document Short Name
                                                                 @IPVC_DocumentNote               varchar(8000)='',        ---> This is document Description or Note associated with document.
                                                                 @IPBI_UserIDSeq                  bigint                   ---> MANDATORY : User ID of the User Logged on and operating on the Quote and Modifying attributes related to Deal Desk document.         
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
         @IPVC_DocumentType = nullif(ltrim(rtrim(@IPVC_DocumentType)),''),
         @IPVC_DocumentName = nullif(ltrim(rtrim(@IPVC_DocumentName)),''),
         @IPVC_DocumentNote = nullif(ltrim(rtrim(@IPVC_DocumentNote)),'')
  -----------------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION QDU;
      Update QUOTES.dbo.QuoteDocument
      set    DocumentName       = coalesce(@IPVC_DocumentName,DocumentName),
             DocumentNote       = coalesce(@IPVC_DocumentNote,DocumentNote),
             ModifiedByIDSeq    = @IPBI_UserIDSeq,
             ModifiedDate       = @LDT_SystemDate,
             SystemLogDate      = @LDT_SystemDate
      where  QDocIDSeq          = @IPBI_QDocIDSeq
      and    QuoteIDSeq         = @IPVC_QuoteIDSeq
      and    DocumentType       = @IPVC_DocumentType;
    COMMIT TRANSACTION QDU;
  END TRY
  BEGIN CATCH;    
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION QDU;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION QDU;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION QDU;
    select @LVC_ErrorCodeSection= 'Proc: uspQUOTES_UpdateDealDeskQuoteDocument. Update Deal Desk Document Failed. Quote : ' + @IPVC_QuoteIDSeq + '. Aboting Update to Document(s)...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    return;                  
  END CATCH;
 -----------------------------------------------------
END -- :Main End
GO
