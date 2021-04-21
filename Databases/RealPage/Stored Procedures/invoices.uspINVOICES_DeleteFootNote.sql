SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [invoices].[uspINVOICES_DeleteFootNote] (
                                                               @IPVC_DocumentID bigint
                                                      )
as
begin  

DELETE FROM Invoices.dbo.FamilyFootNote Where IDSEQ=@IPVC_DocumentID

END

GO
