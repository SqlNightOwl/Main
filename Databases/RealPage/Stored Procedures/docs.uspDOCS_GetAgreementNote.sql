SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [docs].[uspDOCS_GetAgreementNote]
AS
BEGIN   
  set nocount on  
  select 
    IDSeq,
    [Name],
    [Description] + ' dated:___________' as [Description]
  from 
    DOCS.dbo.Template with (nolock)
  where
    PrintOnOrderFlag = 1
  order by 
    [IDSeq]
END

GO
