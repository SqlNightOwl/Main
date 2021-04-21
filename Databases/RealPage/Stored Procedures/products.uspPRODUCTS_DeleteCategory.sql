SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_DeleteCategory
-- Description     : This proc is called by Product Administration Category Management to an Existing Category
-- Input Parameters: @IPVC_CategoryCode
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_DeleteCategory 
                          @IPVC_CategoryCode = 'ABC'  ---> This is the existing category that is to be deleted
                         ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Category Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_DeleteCategory]  (@IPVC_CategoryCode          varchar(3),     ---->MANDATORY : This is the upto 6 character Unique Category Code of existing Category                                                                                                                                           
                                                      @IPBI_UserIDSeq             bigint= -1      ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                     )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_CategoryCode = UPPER(NullIf(ltrim(rtrim(@IPVC_CategoryCode)),'')),
          @LDT_SystemDate    = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_CategoryCode cannot be blank or null
  If (@IPVC_CategoryCode is null)
  begin
    select @LVC_CodeSection = 'Error: Category Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  --Validation 2: @IPVC_CategoryCode should not be referenced by any Product Charge irrespective of Version
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Product P with (nolock)
             where   P.CategoryCode = @IPVC_CategoryCode
            )
  begin
    select @LVC_CodeSection = 'Error: Category is actively referenced by atleast one product record. Category cannot be deleted.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 3: @IPVC_CategoryCode should not be referenced by any Diverse Category for Account
  --              BL to be filled in when that piece is done down the road. 
  ------------------------------------------
  Delete CAT
  from   PRODUCTS.dbo.Category CAT with (nolock)
  where  (CAT.Code =  @IPVC_CategoryCode);  
  ------------------------------------------
END--> Main End
GO
