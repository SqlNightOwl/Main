SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [documents].[uspDOCUMENTS_GetAgreementNote]
AS
BEGIN   
  set nocount on  
  select Code,Name,Description
  from DOCUMENTS.dbo.AgreementNote with (nolock)
  order by Name desc
END

GO
