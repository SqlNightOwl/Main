SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetAddressType] (@IPVC_RETURNTYPE   varchar(100) = 'XML')
AS
BEGIN
  set nocount on 
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,
                    ltrim(rtrim(Name)) as name
    from   CUSTOMERS.dbo.AddressType (nolock)
    FOR XML raw ,ROOT('addresstype'), TYPE
  end
  else
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,
                    ltrim(rtrim(Name)) as name
    from   CUSTOMERS.dbo.AddressType (nolock)
  end
END

GO
