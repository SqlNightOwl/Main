SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_AddCountry
-- Description     : This proc is called by Product Administration Country Management to Add New Country(s)
-- Input Parameters: @IPVC_CountryCode,@IPVC_CountryName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_AddCountry 
                       @IPVC_CountryCode = 'ABC'               --> This is the new Countrycode 
                      ,@IPVC_CountryName = 'Abc Test'          --> This is the new CountryName 
                      ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Country Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_AddCountry]  (@IPVC_CountryCode          varchar(10),     ---->MANDATORY : This is the upto 3 character Unique Country Code for adding new Country
                                                  @IPVC_CountryName          varchar(100),    ---->MANDATORY : This is Country Name for the new Country 
                                                  @IPBI_UserIDSeq            bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                 )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500);
         
 
  select  @IPVC_CountryCode        = UPPER(NullIf(ltrim(rtrim(@IPVC_CountryCode)),'')),
          @IPVC_CountryName        = NullIf(ltrim(rtrim(@IPVC_CountryName)),''),
          @LDT_SystemDate                 = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_CountryCode or @IPVC_CountryName cannot be blank or null
  If (@IPVC_CountryCode is null)
  begin
    select @LVC_CodeSection = 'Error: Country Code cannot be blank. 3-Letter Standard UN CountryCode(s) are accepted. Refer: http://countrycode.org/ OR http://www.worldatlas.com/aatlas/ctycodes.htm';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  if len(@IPVC_CountryCode) <> 3
  begin
    select @LVC_CodeSection = 'Error: Valid Country Code should be 3 characters. 3-Letter Standard UN CountryCode(s) are accepted. Refer: http://countrycode.org/ OR http://www.worldatlas.com/aatlas/ctycodes.htm';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  If (@IPVC_CountryName is null)
  begin
    select @LVC_CodeSection = 'Error: Country Name cannot be blank. For valid countries on planet earth Refer: http://countrycode.org/ OR http://www.worldatlas.com/aatlas/ctycodes.htm';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  --Validation 2: @IPVC_CountryCode or @IPVC_CountryName should be unique and should not already exists
  if exists (select  Top 1 1
             from    CUSTOMERS.dbo.Country CNTRY with (nolock)
             where   (CNTRY.Code = @IPVC_CountryCode)
            )
  begin
    select @LVC_CodeSection = 'Error: Country Code already exists in the system. Country Code should be unique for new Country additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if exists (select  Top 1 1
             from    CUSTOMERS.dbo.Country CNTRY with (nolock)
             where   (CNTRY.Name = @IPVC_CountryName)
            )
  begin
    select @LVC_CodeSection = 'Error: Country Name already exists in the system. Country Name should be unique for new Country additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if (not exists (select  Top 1 1
                  from    CUSTOMERS.dbo.Country CNTRY with (nolock)
                  where   (CNTRY.Code = @IPVC_CountryCode)                  
                 )
         AND
      not exists (select  Top 1 1
                  from    CUSTOMERS.dbo.Country CNTRY with (nolock)
                  where   (CNTRY.Name = @IPVC_CountryName)
                 )
     )
  begin
    Insert into CUSTOMERS.dbo.Country(Code,Name,CreatedByIDSeq,CreatedDate,SystemLogDate)
    select @IPVC_CountryCode as Code,@IPVC_CountryName as Name,          
           @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate;
  end
  ------------------------------------------
END--> Main End
GO
