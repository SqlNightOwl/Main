SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_UpdateProductType
-- Description     : This proc is called by Product Administration ProductType Management to Update Existing ProductTypes
-- Input Parameters: @IPVC_ProductTypeCode,@IPVC_ProductTypeName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_UpdateProductType 
                       @IPVC_ProductTypeCode = 'RACK'  --> This is the existing ProductTypecode 
                      ,@IPVC_ProductTypeName = 'Rack1' --> This is the new updated ProductTypeName This is used for PPC Report Primary Product listing. (important) 0 or 1 from checkbox
                      ,@IPI_PPCReportPrimaryProductFlag = 0
                      ,@IPBI_UserIDSeq    = 76
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration ProductType Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_UpdateProductType]  (@IPVC_ProductTypeCode             varchar(3),      ---->MANDATORY : This is the upto 3 character Unique ProductType Code of existing ProductType
                                                         @IPVC_ProductTypeName             varchar(70),     ---->MANDATORY : This is new ProductType Name for the existing ProductType
                                                         @IPVC_ProductTypeDescription      varchar(255)='', ---->OPTIONAL  : This is Product Type Description. Default is same as Product Type Name 
                                                         @IPI_PPCReportPrimaryProductFlag  int = 0,         ---->MANDATORY : This is used for PPC Report Primary Product listing. (important) 0 or 1 from checkbox
                                                         @IPBI_UserIDSeq                   bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                        )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
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
  --Validation 2: @IPVC_ProductTypeName should be unique and should not already exists
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.ProductType PT with (nolock)
             where   (PT.Name =  @IPVC_ProductTypeName)
             and     (PT.Code <> @IPVC_ProductTypeCode)   
            )
  begin
    select @LVC_CodeSection = 'Error: ProductType Name already exists for a different ProductType Code in the system. ProductType Name should be unique.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.ProductType PT with (nolock)
             where   (PT.Code =  @IPVC_ProductTypeCode) 
             and     (
                      (PT.Name        <> @IPVC_ProductTypeName)
                         OR
                      (PT.Description <> coalesce(@IPVC_ProductTypeDescription,@IPVC_ProductTypeName))
                         OR
                      (convert(int,PT.ReportPrimaryProductFlag) <> @IPI_PPCReportPrimaryProductFlag)
                     )
            )
  begin
    Update PT
    set    PT.Name            = @IPVC_ProductTypeName
          ,PT.Description     = coalesce(@IPVC_ProductTypeDescription,@IPVC_ProductTypeName)
          ,PT.ReportPrimaryProductFlag = (Case when (convert(int,PT.ReportPrimaryProductFlag) <> @IPI_PPCReportPrimaryProductFlag)
                                                then @IPI_PPCReportPrimaryProductFlag
                                               else PT.ReportPrimaryProductFlag
                                          end)
          ,PT.ModifiedByIdSeq = @IPBI_UserIDSeq
          ,PT.ModifiedDate    = @LDT_SystemDate 
          ,PT.SystemLogDate   = @LDT_SystemDate
    from  PRODUCTS.dbo.ProductType PT with (nolock)
    where (PT.Code =  @IPVC_ProductTypeCode) 
    and   (
            (PT.Name        <> @IPVC_ProductTypeName)
                 OR
            (PT.Description <> coalesce(@IPVC_ProductTypeDescription,@IPVC_ProductTypeName))
                 OR
            (convert(int,PT.ReportPrimaryProductFlag) <> @IPI_PPCReportPrimaryProductFlag)
         )
  end
  ------------------------------------------
END--> Main End
GO
