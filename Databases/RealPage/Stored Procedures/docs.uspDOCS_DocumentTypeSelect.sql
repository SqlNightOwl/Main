SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE Procedure [docs].[uspDOCS_DocumentTypeSelect]

AS
BEGIN
SELECT DISTINCT Code,Name from [Item] Where Active = 1 and CODE NOT IN('SOW')
END




GO
