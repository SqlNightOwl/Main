SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_DeleteDealDeskQuoteDocument
-- Description     : This procedure gets Called to Delete an existing Quote Deal Desk document
--                   Deal Desk Document tab, More-->Delete-->UI will prompt for User Confirmation.
--                   and upon OK
--                   Step 1 : call Proc Exec QUOTES.dbo.uspQUOTES_DeleteDealDeskQuoteDocument
--                   Step 2 : Remove the orphan document from OMSFileRepository.
--                            \\servername\omsfilerepository\CompanyIDseq\DealDesk\DealDesk\QuoteIDseq+uniqueRowGUID.doc
-- Input Parameters: As Below (all mandatory)
-- 
-- OUTPUT          : None

--syntax           : 
/*
Exec QUOTES.dbo.uspQUOTES_DeleteDealDeskQuoteDocument   @IPBI_QDocIDSeq   = 1
                                                       ,@IPVC_QuoteIDSeq  ='Q1104000100' 
                                                       ,@IPVC_DocumentType='DealDesk'                                                       
                                                       ,@IPBI_UserIDSeq   = 137
*/
-- Revision History:
-- Author          : SRS
-- 05/15/2011      : Stored Procedure Created.TFS : 267 : Deal Desk Project
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_DeleteDealDeskQuoteDocument]  (@IPBI_QDocIDSeq                  bigint,                  ---> Mandatory: This is the UNIQUE QDocIDSeq that is available in UI as hidden value. 
                                                                                                                            --  Returned by call of EXEC QUOTES.dbo.uspQUOTES_GetDealDeskQuoteDocumentList
                                                                 @IPVC_QuoteIDSeq                 varchar(50),             ---> Mandatory: This is the QuoteIDSeq that UI is Operating under. UI knows this Q number
                                                                 @IPVC_DocumentType               varchar(50)  ='DealDesk',---> Mandatory: This is Document Type that UI is looking for. For Deal Desk, it is going to be 'DealDesk'
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
         @IPVC_DocumentType = nullif(ltrim(rtrim(@IPVC_DocumentType)),'')        
  -----------------------------------------------------
  ---Step 1 : Mark The Document as Inactive (soft Delete)
  --- This will make the document not to appear in UI at all.
      Update QUOTES.dbo.QuoteDocument
      set    ActiveFlag         = 0,
             ModifiedByIDSeq    = @IPBI_UserIDSeq,
             ModifiedDate       = @LDT_SystemDate,
             SystemLogDate      = @LDT_SystemDate
      where  QDocIDSeq          = @IPBI_QDocIDSeq
      and    QuoteIDSeq         = @IPVC_QuoteIDSeq
      and    DocumentType       = @IPVC_DocumentType;
  -----------------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION QDD;
      -----------------------------------------------------
      --Step 2: Delete this inactive document permanently.
      Delete from QUOTES.dbo.QuoteDocument
      where  QDocIDSeq          = @IPBI_QDocIDSeq
      and    QuoteIDSeq         = @IPVC_QuoteIDSeq
      and    DocumentType       = @IPVC_DocumentType
      and    ActiveFlag         = 0;
      ----------------------------------------------------
    COMMIT TRANSACTION QDD;
  END TRY
  BEGIN CATCH;    
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION QDD;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION QDD;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION QDD;
    select @LVC_ErrorCodeSection= 'Proc: uspQUOTES_DeleteDealDeskQuoteDocument. Delete Deal Desk Document Failed. Quote : ' + @IPVC_QuoteIDSeq + '. Aboting Deleting Document(s)...'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    return;                  
  END CATCH;
END -- :Main End
GO
