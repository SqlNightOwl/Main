SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_UpdateCategory
-- Description     : This proc is called by Product Administration Category Management to Update Existing Categorys
-- Input Parameters: @IPVC_CategoryCode,@IPVC_CategoryName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_UpdateCategory 
                       @IPVC_CategoryCode = 'RACK'  --> This is the existing Categorycode 
                      ,@IPVC_CategoryName = 'Rack1' --> This is the new updated CategoryName
                      ,@IPVC_CategroyDescription = 'Rack1' --> This is the new updated Description
                      ,@IPBI_UserIDSeq    = 76
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Category Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_UpdateCategory]  (@IPVC_CategoryCode           varchar(3),      ---->MANDATORY : This is the upto 3 character Unique Category Code of existing Category
                                                      @IPVC_CategoryName           varchar(70),     ---->MANDATORY : This is new Category Name for the existing Category                                                      
                                                      @IPVC_CategoryDescription    varchar(255)='', ---->OPTIONAL  : This is Category Description. Default is same as Category Name
                                                      @IPBI_UserIDSeq              bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                     )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_CategoryCode        = NullIf(ltrim(rtrim(@IPVC_CategoryCode)),''),
          @IPVC_CategoryName        = NullIf(ltrim(rtrim(@IPVC_CategoryName)),''),
          @IPVC_CategoryDescription = NullIf(NullIf(ltrim(rtrim(@IPVC_CategoryDescription)),'0'),''),
          @LDT_SystemDate           = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_CategoryCode or @IPVC_CategoryName cannot be blank or null
  If (@IPVC_CategoryCode is null)
  begin
    select @LVC_CodeSection = 'Error: Category Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  If (@IPVC_CategoryName is null)
  begin
    select @LVC_CodeSection = 'Error: Category Name cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 2: @IPVC_CategoryName should be unique and should not already exists
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Category CAT with (nolock)
             where   (CAT.Name =  @IPVC_CategoryName)
             and     (CAT.Code <> @IPVC_CategoryCode)   
            )
  begin
    select @LVC_CodeSection = 'Error: Category Name already exists for a different Category Code in the system. Category Name should be unique.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Category CAT with (nolock)
             where   (CAT.Code =  @IPVC_CategoryCode) 
             and     (
                      (CAT.Name        <> @IPVC_CategoryName)
                          OR
                      (CAT.Description <> coalesce(@IPVC_CategoryDescription,@IPVC_CategoryName))
                     )
            )
  begin
    Update CAT
    set    CAT.Name            = @IPVC_CategoryName
          ,CAT.Description     = coalesce(@IPVC_CategoryDescription,@IPVC_CategoryName)
          ,CAT.ModifiedByIdSeq = @IPBI_UserIDSeq
          ,CAT.ModifiedDate    = @LDT_SystemDate 
          ,CAT.SystemLogDate   = @LDT_SystemDate
    from  PRODUCTS.dbo.Category CAT with (nolock)
    where (CAT.Code =  @IPVC_CategoryCode) 
    and   (
            (CAT.Name        <> @IPVC_CategoryName)
                OR
            (CAT.Description <> coalesce(@IPVC_CategoryDescription,@IPVC_CategoryName))
          )
  end
  ------------------------------------------
END--> Main End
GO
