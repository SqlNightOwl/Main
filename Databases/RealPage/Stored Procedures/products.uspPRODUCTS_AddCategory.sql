SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_AddCategory
-- Description     : This proc is called by Product Administration Category Management to Add New Categorys
-- Input Parameters: @IPVC_CategoryCode,@IPVC_CategoryName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_AddCategory 
                       @IPVC_CategoryCode = 'RACK'  --> This is the new Categorycode 
                      ,@IPVC_CategoryName = 'Rack'  --> This is the new CategoryName 
                      ,@IPVC_CategoryDescription ='Rack' --> This is new CategoryDescription 
                      ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Category Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_AddCategory]  (@IPVC_CategoryCode          varchar(10),     ---->MANDATORY : This is the upto 3 character Unique Category Code for adding new Category
                                                   @IPVC_CategoryName          varchar(70),     ---->MANDATORY : This is Category Name for the new Category 
                                                   @IPVC_CategoryDescription   varchar(255)='', ---->OPTIONAL  : This is Category Description. Default is same as Category Name
                                                   @IPBI_UserIDSeq             bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                  )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500),
          @LI_SortSeq      int; 
 
  select  @IPVC_CategoryCode        = UPPER(NullIf(ltrim(rtrim(@IPVC_CategoryCode)),'')),
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
  If ( (isnumeric(@IPVC_CategoryCode) = 1) 
            OR 
       (PATINDEX('%[^A-Z]%',@IPVC_CategoryCode) > 0)
     )
  begin
    select @LVC_CodeSection = 'Error: Category Code cannot be numeric or alpha numeric.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if len(@IPVC_CategoryCode) > 3
  begin
    select @LVC_CodeSection = 'Error: Category Code cannot be more than 3 characters';
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
  --Validation 2: @IPVC_CategoryCode or @IPVC_CategoryName should be unique and should not already exists
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Category CAT with (nolock)
             where   (CAT.Code = @IPVC_CategoryCode)
            )
  begin
    select @LVC_CodeSection = 'Error: Category Code already exists in the system. Category Code should be unique for new Category additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Category CAT with (nolock)
             where   (CAT.Name = @IPVC_CategoryName)
            )
  begin
    select @LVC_CodeSection = 'Error: Category Name already exists in the system. Category Name should be unique for new Category additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if (not exists (select  Top 1 1
                  from    PRODUCTS.dbo.Category CAT with (nolock)
                  where   (CAT.Code = @IPVC_CategoryCode)                  
                 )
         AND
      not exists (select  Top 1 1
                  from    PRODUCTS.dbo.Category CAT with (nolock)
                  where   (CAT.Name = @IPVC_CategoryName)
                 )
     )
  begin
    select @LI_SortSeq = Max(CAT.SortSeq)+ 10 from PRODUCTS.dbo.Category CAT with (nolock)

    Insert into Products.dbo.Category(Code,Name,Description,SortSeq,CreatedByIDSeq,CreatedDate,SystemLogDate)
    select @IPVC_CategoryCode as Code,@IPVC_CategoryName as Name,coalesce(@IPVC_CategoryDescription,@IPVC_CategoryName) as Description,
           @LI_SortSeq as SortSeq,
           @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate;
  end
  ------------------------------------------
END--> Main End
GO
