SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_GetFamilyInvalidComboList] (@IPVC_RETURNTYPE   varchar(100) = 'XML')
AS
BEGIN
  set nocount on 
  ------------------------------------------------------------------------------------------------------
  ---Declaring local variables
  declare @LT_FamilyInvalidComboList table (seq                      int identity(1,1) not null,
                                            firstfamilycode          varchar(100)      not null default '',
                                            secondfamilycode         varchar(100)      not null default ''                                    
                                            )
  ------------------------------------------------------------------------------------------------------
  if exists (select top 1 1 from PRODUCTS.dbo.FamilyInvalidCombo (nolock))
  begin
    insert into @LT_FamilyInvalidComboList(firstfamilycode,secondfamilycode)
    select DISTINCT ltrim(rtrim(A.firstfamilycode))   as firstfamilycode,
                    ltrim(rtrim(A.secondfamilycode))  as secondfamilycode
    from PRODUCTS.dbo.FamilyInvalidCombo A with (nolock)
    where exists (select top 1 1 
                  from  Products.dbo.Product X with (nolock)
                  where X.FamilyCode = A.firstfamilycode
                  and   X.DisabledFlag = 0
                 )
    and   exists (select top 1 1 
                  from  Products.dbo.Product X with (nolock)
                  where X.FamilyCode = A.secondfamilycode
                  and   X.DisabledFlag = 0
                 )
    order by ltrim(rtrim(A.firstfamilycode)) asc
  end
  else
  begin
    insert into @LT_FamilyInvalidComboList(firstfamilycode,secondfamilycode)
    select '' as firstfamilycode,'' as secondfamilycode
  end
  -------------------------------------------------------------------------------
  --Final Select 
  -------------------------------------------------------------------------------
  if @IPVC_RETURNTYPE = 'XML'
  begin
    select firstfamilycode as firstfamilycode,secondfamilycode as secondfamilycode
    from   @LT_FamilyInvalidComboList 
    FOR XML raw ,ROOT('FamilyInvalidComboList'), TYPE
  end
  else
  begin
    select firstfamilycode as firstfamilycode,secondfamilycode as secondfamilycode
    from   @LT_FamilyInvalidComboList 
  end
END
GO
