SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_DeleteProductType
-- Description     : This proc is called by Product Administration ProductType Management to an Existing ProductType
-- Input Parameters: @IPVC_ProductTypeCode
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_DeleteProductType 
                          @IPVC_ProductTypeCode = 'ABC'  ---> This is the existing ProductType that is to be deleted
                         ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration ProductType Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_DeleteProductType]  (@IPVC_ProductTypeCode       varchar(3),     ---->MANDATORY : This is the upto 6 character Unique ProductType Code of existing ProductType                                                                                                                                           
                                                         @IPBI_UserIDSeq             bigint= -1      ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                        )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_ProductTypeCode = UPPER(NullIf(ltrim(rtrim(@IPVC_ProductTypeCode)),'')),
          @LDT_SystemDate   = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_ProductTypeCode cannot be blank or null
  If (@IPVC_ProductTypeCode is null)
  begin
    select @LVC_CodeSection = 'Error: ProductType Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  --Validation 2: @IPVC_ProductTypeCode should not be referenced by any Product Charge irrespective of Version
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Product P with (nolock)
             where   P.ProductTypeCode = @IPVC_ProductTypeCode
            )
  begin
    select @LVC_CodeSection = 'Error: ProductType is actively referenced by atleast one product record. ProductType cannot be deleted.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 3: @IPVC_ProductTypeCode should not be referenced by any Diverse ProductType for Account
  --              BL to be filled in when that piece is done down the road. 
  ------------------------------------------
  Delete PT
  from   PRODUCTS.dbo.ProductType PT with (nolock)
  where  (PT.Code =  @IPVC_ProductTypeCode);  
  ------------------------------------------
END--> Main End
GO
