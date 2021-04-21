SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_GetDiscountAllocation] (@IPVC_RETURNTYPE   varchar(100) = 'XML')
AS
BEGIN
  set nocount on 
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,
                    ltrim(rtrim(Name)) as name
    from PRODUCTS.dbo.DiscountAllocation (nolock)
    FOR XML raw ,ROOT('discountallocation'),TYPE
  end
  else
  begin
    select DISTINCT ltrim(rtrim(Code)) as code,
                    ltrim(rtrim(Name)) as name
    from PRODUCTS.dbo.DiscountAllocation (nolock)
  end
END
GO
