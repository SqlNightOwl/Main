SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_GetDocumentPath
-- Description     : This procedure gets the latest Document ID
-- Revision History:
-- Author          : DCANNON 
-- 5/02/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [docs].[uspDOCS_GetDocumentPath] @IPVC_CompanyIDSeq varchar(22), @IPVC_DefaultDocPath varchar(255)
as
begin
  if not exists (select 1 from DOCS.dbo.CompanyDocumentPath with (nolock)
                where CompanyIDSeq = @IPVC_CompanyIDSeq)
  begin
    insert into DOCS..CompanyDocumentPath (CompanyIDSeq, CompanyIDDocumentPath)
    values (@IPVC_CompanyIDSeq, @IPVC_DefaultDocPath + '\' + @IPVC_CompanyIDSeq)
  end

  select CompanyIDDocumentPath from DOCS.dbo.CompanyDocumentPath with (nolock)
  where CompanyIDSeq = @IPVC_CompanyIDSeq
END

GO
