SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_AddProductType
-- Description     : This proc is called by Product Administration ProductType Management to Add New ProductTypes
-- Input Parameters: @IPVC_ProductTypeCode,@IPVC_ProductTypeName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_AddProductType 
                       @IPVC_ProductTypeCode = 'RACK'  --> This is the new ProductTypecode 
                      ,@IPVC_ProductTypeName = 'Rack'  --> This is the new ProductTypeName  
                      ,@IPVC_PPCReportPrimaryProductFlag = 0 --> This is used for PPC Report Primary Product listing. (important)
                      ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration ProductType Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_AddProductType]  (@IPVC_ProductTypeCode             varchar(10),     ---->MANDATORY : This is the upto 3 character Unique ProductType Code for adding new ProductType
                                                      @IPVC_ProductTypeName             varchar(70),     ---->MANDATORY : This is ProductType Name for the new ProductType 
                                                      @IPVC_ProductTypeDescription      varchar(255)='', ---->OPTIONAL  : This is Product Type Description. Default is same as Product Type Name 
                                                      @IPI_PPCReportPrimaryProductFlag  int = 0,         ---->MANDATORY : This is used for PPC Report Primary Product listing. (important) 0 or 1 from checkbox
                                                      @IPBI_UserIDSeq                   bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                     )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500),
          @LI_SortSeq      int; 
 
  select  @IPVC_ProductTypeCode        = UPPER(NullIf(ltrim(rtrim(@IPVC_ProductTypeCode)),'')),
          @IPVC_ProductTypeName        = NullIf(ltrim(rtrim(@IPVC_ProductTypeName)),''),
          @IPVC_ProductTypeDescription = NullIf(NullIf(ltrim(rtrim(@IPVC_ProductTypeDescription)),'0'),''),
          @LDT_SystemDate              = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_ProductTypeCode or @IPVC_ProductTypeName cannot be blank or null
  If (@IPVC_ProductTypeCode is null)
  begin
    select @LVC_CodeSection = 'Error: ProductType Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  If ( (isnumeric(@IPVC_ProductTypeCode) = 1) 
            OR 
       (PATINDEX('%[^A-Z]%',@IPVC_ProductTypeCode) > 0)
     )
  begin
    select @LVC_CodeSection = 'Error: ProductType Code cannot be numeric or alpha numeric.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if len(@IPVC_ProductTypeCode) > 3
  begin
    select @LVC_CodeSection = 'Error: ProductType Code cannot be more than 3 characters';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  If (@IPVC_ProductTypeName is null)
  begin
    select @LVC_CodeSection = 'Error: ProductType Name cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if (@IPI_PPCReportPrimaryProductFlag not in (0,1))
  begin
    select @LVC_CodeSection = 'Error: PPC Report Primary Product Flag  can only be 1 for YES or 0 for No.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 2: @IPVC_ProductTypeCode or @IPVC_ProductTypeName should be unique and should not already exists
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.ProductType PT with (nolock)
             where   (PT.Code = @IPVC_ProductTypeCode)
            )
  begin
    select @LVC_CodeSection = 'Error: ProductType Code already exists in the system. ProductType Code should be unique for new ProductType additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.ProductType PT with (nolock)
             where   (PT.Name = @IPVC_ProductTypeName)
            )
  begin
    select @LVC_CodeSection = 'Error: ProductType Name already exists in the system. ProductType Name should be unique for new ProductType additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if (not exists (select  Top 1 1
                  from    PRODUCTS.dbo.ProductType PT with (nolock)
                  where   (PT.Code = @IPVC_ProductTypeCode)                  
                 )
         AND
      not exists (select  Top 1 1
                  from    PRODUCTS.dbo.ProductType PT with (nolock)
                  where   (PT.Name = @IPVC_ProductTypeName)
                 )
     )
  begin
    select @LI_SortSeq = Max(CAT.SortSeq)+ 10 from PRODUCTS.dbo.ProductType CAT with (nolock)

    Insert into Products.dbo.ProductType(Code,Name,Description,ReportPrimaryProductFlag,SortSeq,CreatedByIDSeq,CreatedDate,SystemLogDate)
    select @IPVC_ProductTypeCode as Code,@IPVC_ProductTypeName as Name,coalesce(@IPVC_ProductTypeDescription,@IPVC_ProductTypeName) as Description,
           @IPI_PPCReportPrimaryProductFlag as ReportPrimaryProductFlag,@LI_SortSeq as SortSeq,
           @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate;
  end
  ------------------------------------------
END--> Main End
GO
