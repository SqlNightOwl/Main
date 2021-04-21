SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_GetProductInvalidCombo] (@IPVC_RETURNTYPE   varchar(100) = 'XML')
AS
BEGIN
  set nocount on 
  ------------------------------------------------------------------------------------------------------
  ---Declaring local variables
  declare @LT_ProductInvalidCombo table (seq                       int identity(1,1) not null,
                                         firstproductcode          varchar(100)      not null default '',
                                         secondproductcode         varchar(100)      not null default ''                                    
                                        )
  ------------------------------------------------------------------------------------------------------
  if exists (select top 1 1 from PRODUCTS.dbo.ProductInvalidCombo (nolock))
  begin
    insert into @LT_ProductInvalidCombo(firstproductcode,secondproductcode)
    select DISTINCT ltrim(rtrim(A.FirstProductCode))   as firstproductcode,
                    ltrim(rtrim(A.SecondProductCode))  as secondproductcode
    from PRODUCTS.dbo.ProductInvalidCombo A with (nolock)
    where exists (select top 1 1 
                  from  Products.dbo.Product X with (nolock)
                  where X.Code = A.FirstProductCode
                  and   X.DisabledFlag = 0
                 )
    and   exists (select top 1 1 
                  from  Products.dbo.Product X with (nolock)
                  where X.Code = A.SecondProductCode
                  and   X.DisabledFlag = 0
                 )
    order by ltrim(rtrim(A.FirstProductCode)) asc
  end
  else
  begin
    insert into @LT_ProductInvalidCombo(firstproductcode,secondproductcode)
    select '' as firstproductcode,'' as secondproductcode
  end
  -------------------------------------------------------------------------------
  --Final Select 
  -------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select firstproductcode as firstproductcode,secondproductcode as secondproductcode
    from   @LT_ProductInvalidCombo 
    FOR XML raw ,ROOT('productinvalidcombo'), TYPE
  end
  else
  begin
    select firstproductcode as firstproductcode,secondproductcode as secondproductcode
    from   @LT_ProductInvalidCombo 
  end
END

GO
