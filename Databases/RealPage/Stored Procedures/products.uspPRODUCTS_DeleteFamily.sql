SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_DeleteFamily
-- Description     : This proc is called by Product Administration Family Management to an Existing Family
-- Input Parameters: @IPVC_FamilyCode
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_DeleteFamily 
                          @IPVC_FamilyCode = 'NFM'  ---> This is the existing Family that is to be deleted
                         ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Family Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_DeleteFamily]  (@IPVC_FamilyCode          varchar(3),     ---->MANDATORY : This is the upto 3 character Unique Family Code of existing Family                                                                                                                                           
                                                    @IPBI_UserIDSeq           bigint= -1      ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                   )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_FamilyCode   = UPPER(NullIf(ltrim(rtrim(@IPVC_FamilyCode)),'')),
          @LDT_SystemDate    = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_FamilyCode cannot be blank or null
  If (@IPVC_FamilyCode is null)
  begin
    select @LVC_CodeSection = 'Error: Family Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  --Validation 2: @IPVC_FamilyCode should not be referenced by any Product Charge irrespective of Version
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Product P with (nolock)
             where   P.FamilyCode = @IPVC_FamilyCode
            )
  begin
    select @LVC_CodeSection = 'Error: Family is actively referenced by atleast one product record. Family cannot be deleted.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 3: @IPVC_FamilyCode should not be referenced by any Diverse Family for Account
  --              BL to be filled in when that piece is done down the road. 
  ------------------------------------------
  Delete FM
  from   PRODUCTS.dbo.Family FM with (nolock)
  where  (FM.Code =  @IPVC_FamilyCode);  
  ------------------------------------------
END--> Main End
GO
