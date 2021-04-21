SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [documents].[uspDOCUMENTS_GetDocumentNameByType] (
                                                               @IPVC_QuoteIDSeq     varchar(22)
                                                              )
AS
BEGIN

  
  select A.* 
  from  [Products].dbo.FootNote A with (nolock)
  where  A.MandatoryFlag      = 0
  and    A.ActiveFlag         = 1 
  order by Title
  
  select count(*)
  from  [Products].dbo.FootNote A with (nolock)
  where  A.MandatoryFlag      = 0
  and    A.ActiveFlag         = 1 
  /*********************************************************************************************/

END

-- exec [dbo].[uspDOCUMENTS_GetDocumentNameByType] 'C0000001696','Q0000000063'



GO
