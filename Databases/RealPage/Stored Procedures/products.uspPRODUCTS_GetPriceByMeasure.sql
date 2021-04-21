SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_GetPriceByMeasure] (@IPVC_RETURNTYPE          varchar(100) = 'XML')
AS
BEGIN
  set nocount on 
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,
                    ltrim(rtrim(Name)) as name
    from PRODUCTS.dbo.Measure (nolock)
    where DisplayFlag = 1 
    order by Name asc
    FOR XML raw ,ROOT('measure'),TYPE
  end
  else
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,
                    ltrim(rtrim(Name)) as name
    from PRODUCTS.dbo.Measure (nolock)
    where DisplayFlag = 1 order by Name asc
  end
END
GO
