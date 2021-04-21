SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [quotes].[uspQUOTES_GetMPFPublicationYears] (@IPVC_RETURNTYPE varchar(100) = 'RECORDSET')
AS
BEGIN
  set nocount on 
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select DISTINCT ltrim(rtrim(PublicationYear)) as PublicationYear
    from QUOTES.dbo.MPFPublicationYear (nolock)
    order by ltrim(rtrim(PublicationYear)) asc    
    FOR XML raw ,ROOT('MPFPublicationYear'),TYPE
  end
  else
  begin
    select DISTINCT ltrim(rtrim(PublicationYear)) as PublicationYear
    from QUOTES.dbo.MPFPublicationYear (nolock)        
    order by ltrim(rtrim(PublicationYear)) asc
  end
END

GO
