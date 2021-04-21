SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : DOCUMENTS
-- Procedure Name  : uspDOCUMENTS_GetDocumentID
-- Description     : This procedure gets the latest Document ID
--
-- OUTPUT          : RecordSet of Latest ID
--
-- Code Example    : Exec DOCUMENTS.dbo.uspDOCUMENTS_GetDocumentID
--
-- Revision History:
-- Author          : KISHORE KUMAR A S 
-- 09/02/2007      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [documents].[uspDOCUMENTS_GetDocumentID] 
as
begin -- Main BEGIN starts at Col 01
    
        /*********************************************************************************************/
        /*                 Main Select statement                                                     */  
        /*********************************************************************************************/
       ---IDGenerator Scheme has changed. 
       --- The following is a temporary fix, until Davon and his team changes  UI with different approach
       ---  for Inserting a new document and correponding File    
/*
       SELECT max(IDSeq)+1 as DocumentID from [DOCUMENTS].dbo.[IDGenerator] with (nolock)
*/
       SELECT DocumentIDSeq as DocumentID from [DOCUMENTS].dbo.[IDGenerator] with (nolock)

END -- Main END starts at Col 01

GO
