SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_GetProductOptions] (@IPVC_RETURNTYPE   varchar(100) = 'XML')
AS
BEGIN
  set nocount on 
  ------------------------------------------------------------------------------------------------------
  ---Declaring local variables
  declare @LT_ProductOptions table (seq                       int identity(1,1) not null,
                                    productcode               varchar(100)      not null default '',
                                    productoptioncode         varchar(100)      not null default '',
                                    requiredflag              bit               not null default 0
                                   )
  ------------------------------------------------------------------------------------------------------
  /*if exists (select top 1 1 from PRODUCTS.dbo.ProductOption A (nolock)
             where exists (select Top 1 B.ProductCode from PRODUCTS.dbo.charge B (nolock)
                           where  ltrim(rtrim(A.ProductCode))   = ltrim(rtrim(B.ProductCode))                              
                          )
             and   exists (select Top 1 B.ProductCode from PRODUCTS.dbo.charge B (nolock)
                           where  ltrim(rtrim(A.ProductOptionCode)) = ltrim(rtrim(B.ProductCode))                              
                          ) 
            )
  begin
    insert into @LT_ProductOptions (productcode,productoptioncode,requiredflag)
    select DISTINCT ltrim(rtrim(A.ProductCode))       as productcode,
                    ltrim(rtrim(A.ProductOptionCode)) as productoptioncode,
                    A.RequiredFlag                    as requiredflag
    from PRODUCTS.dbo.ProductOption A (nolock)
    where exists (select Top 1 B.ProductCode from PRODUCTS.dbo.charge B (nolock)
                  where  ltrim(rtrim(A.ProductCode))   = ltrim(rtrim(B.ProductCode))                    
                 )
    and   exists (select Top 1 B.ProductCode from PRODUCTS.dbo.charge B (nolock)
                  where  ltrim(rtrim(A.ProductOptionCode)) = ltrim(rtrim(B.ProductCode))                    
                 )
    order by ltrim(rtrim(A.ProductCode)) asc      
  end
  else if exists(select top 1 1 from PRODUCTS.dbo.ProductOption A (nolock))
  begin
    insert into @LT_ProductOptions (productcode,productoptioncode,requiredflag)
    select DISTINCT ltrim(rtrim(A.ProductCode))       as productcode,
                    ltrim(rtrim(A.ProductOptionCode)) as productoptioncode,
                    A.RequiredFlag                    as requiredflag
    from PRODUCTS.dbo.ProductOption A (nolock)
    order by ltrim(rtrim(A.ProductCode)) asc 
  end  
  else 
*/
  begin
    insert into @LT_ProductOptions (productcode,productoptioncode,requiredflag)
    select '' as productcode,'' as productoptioncode,'0' as requiredflag   
  end  
  -------------------------------------------------------------------------------
  --Final Select 
  -------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select productcode,productoptioncode,requiredflag
    from   @LT_ProductOptions FOR XML raw ,ROOT('productoptions'),TYPE
  end
  else
  begin
    select productcode,productoptioncode,requiredflag
    from   @LT_ProductOptions
  end
END

GO
