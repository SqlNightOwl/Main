SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_GetPriceType] (@IPVC_TYPE varchar(20) = 'BOTH', @IPVC_RETURNTYPE varchar(100) = 'XML')
AS
BEGIN
  set nocount on 
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,
                    ltrim(rtrim(Name)) as name
    from PRODUCTS.dbo.PriceType (nolock)
    where @IPVC_TYPE = 'BOTH'
      or (@IPVC_TYPE = 'NORMAL ONLY' and ltrim(rtrim(Code)) = 'Normal')
    order by Name asc
    FOR XML raw ,ROOT('measure'),TYPE
  end
  else
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,
                    ltrim(rtrim(Name)) as name
    from PRODUCTS.dbo.PriceType (nolock)
    where @IPVC_TYPE = 'BOTH'
      or (@IPVC_TYPE = 'NORMAL ONLY' and ltrim(rtrim(Code)) = 'Normal')
    order by Name asc
  end
END


GO
