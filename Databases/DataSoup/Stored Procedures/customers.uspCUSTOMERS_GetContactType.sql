SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetContactType] (@IPVC_RETURNTYPE   varchar(100) = 'XML')
AS
BEGIN
  set nocount on 
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,ltrim(rtrim(Name)) as name 
    from CUSTOMERS.dbo.ContactType (nolock)
    where Code <> 'BIL' 
    order by Name asc
    FOR XML raw ,ROOT('contacttype'), TYPE
  end
  else
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,ltrim(rtrim(Name)) as name 
    from CUSTOMERS.dbo.ContactType (nolock)
    where Code <> 'BIL' 
    order by Name asc
  end
END

GO
