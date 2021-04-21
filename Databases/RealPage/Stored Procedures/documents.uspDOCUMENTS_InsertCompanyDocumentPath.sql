SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_InsertCompanyDocumentPath
-- Description     : This procedure inserts Document path for company
--
-- Input Parameters:  @IPVC_CompanyIDSeq varchar
--                    @IPVC_DocumentPath varchar
-- 
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_InsertCompanyDocumentPath 
--                    @IPVC_CompanyIDSeq = 'A0000003273' 
--                    @IPVC_DocumentPath = 'c:\\OMSDOCS\'
-- Revision History:
-- Author          : KISHORE KUMAR A S 
-- 09/02/2007      : Stored Procedure Created.
-- 06/17/2011	   : Surya Kondapalli - Task# 417 - Companies are being created without a corresponding document path
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [documents].[uspDOCUMENTS_InsertCompanyDocumentPath](
                                                                 @IPVC_CompanyIDSeq    varchar(22),   ---> MANDATORY : This the CompanyIDSeq of the Company that is getting newly created.
                                                                                                         --- When new company is created Exec CUSTOMERS.dbo.uspCUSTOMERS_CompanyInsert is called by UI, which then returns CompanyID back to UI.
                                                                                                         --- UI will then have to pass the newly created CompanyID as parameter.
                                                                  @IPVC_ApplicationPath varchar(500),  ---> MANDATORY : This the main application path stored in web.config file. UI knows this value from web.config.
                                                                  @IPVC_DocumentPath    varchar(500),  ---> MANDATORY : This the CompanyIDSeq of the Company that is getting newly created.
                                                                                                         --- When new company is created Exec CUSTOMERS.dbo.uspCUSTOMERS_CompanyInsert is called by UI, which then returns CompanyID back to UI.
                                                                                                         --- UI will then have to pass the newly created CompanyID as parameter.
                                                                  @IPBI_UserIDSeq       bigint = -1    ---> MANDATORY : User ID of the User Logged on and Initiating this operation. UI knows this UserID to pass in.
                                                                 ) 
as
begin 
set nocount on;
  -----------------------------------------------------------------------------------
  declare @LDT_SystemDate datetime
  select @LDT_SystemDate = Getdate()
  -----------------------------------------------------------------------------------
  --Step 1 : Insert Documents.dbo.CompanyDocumentPath record when one does not exist.
  -----------------------------------------------------------------------------------
  Insert into Documents.dbo.CompanyDocumentPath(CompanyIDSeq,CompanyIDDocumentPath,
                                                CreatedByIDSeq,CreatedDate,SystemLogDate
                                               )
  select @IPVC_CompanyIDSeq as CompanyIDSeq,(@IPVC_ApplicationPath + '\' + @IPVC_DocumentPath) as CompanyIDDocumentPath,
         @IPBI_UserIDSeq    as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as  SystemLogDate
  where  not exists (select Top 1 1
                     from   DOCUMENTS.dbo.CompanyDocumentPath CDP with (nolock)
                     where  CDP.CompanyIDSeq = @IPVC_CompanyIDSeq
                    );
  -----------------------------------------------------------------------------------
  --Step 2 : Insert Docs.dbo.CompanyDocumentPath record when one does not exist.
  -----------------------------------------------------------------------------------   
  Insert into DOCS.dbo.CompanyDocumentPath(CompanyIDSeq,CompanyIDDocumentPath,
                                                CreatedByIDSeq,CreatedDate,SystemLogDate
                                               )
  select @IPVC_CompanyIDSeq as CompanyIDSeq,(@IPVC_ApplicationPath + '\' + @IPVC_DocumentPath) as CompanyIDDocumentPath,
         @IPBI_UserIDSeq    as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as  SystemLogDate
  where  not exists (select Top 1 1
                     from   DOCS.dbo.CompanyDocumentPath CDP with (nolock)
                     where  CDP.CompanyIDSeq = @IPVC_CompanyIDSeq
                    );
  -----------------------------------------------------------------------------------

END 

GO
