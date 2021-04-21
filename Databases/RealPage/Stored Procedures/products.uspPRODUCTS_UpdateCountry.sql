SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_UpdateCountry
-- Description     : This proc is called by Product Administration Country Management to Update Existing Countrys
-- Input Parameters: @IPVC_CountryCode,@IPVC_CountryName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_UpdateCountry 
                       @IPVC_CountryCode = 'ABC'   --> This is the existing Countrycode 
                      ,@IPVC_CountryName = 'Sample Country Name' --> This is the new updated CountryName
                      ,@IPBI_UserIDSeq    = 76
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Country Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_UpdateCountry]  (@IPVC_CountryCode          varchar(3),      ---->MANDATORY : This is the upto 3 character Unique Country Code of existing Country
                                                     @IPVC_CountryName          varchar(100),      ---->MANDATORY : This is new Country Name for the existing Country
                                                     @IPBI_UserIDSeq                   bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                    )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_CountryCode        = UPPER(NullIf(ltrim(rtrim(@IPVC_CountryCode)),'')),
          @IPVC_CountryName        = NullIf(ltrim(rtrim(@IPVC_CountryName)),''),
          @LDT_SystemDate          = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_CountryCode or @IPVC_CountryName cannot be blank or null
  If (@IPVC_CountryCode is null)
  begin
    select @LVC_CodeSection = 'Error: Country Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  If (@IPVC_CountryName is null)
  begin
    select @LVC_CodeSection = 'Error: Country Name cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  --Validation 2: @IPVC_CountryName should be unique and should not already exists
  if exists (select  Top 1 1
             from    CUSTOMERS.dbo.Country CNTRY with (nolock)
             where   (CNTRY.Name =  @IPVC_CountryName)
             and     (CNTRY.Code <> @IPVC_CountryCode)   
            )
  begin
    select @LVC_CodeSection = 'Error: Country Name already exists for a different Country Code in the system. Country Name should be unique.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  if exists (select  Top 1 1
             from    CUSTOMERS.dbo.Country CNTRY with (nolock)
             where   (CNTRY.Code =  @IPVC_CountryCode) 
             and     (CNTRY.Name <> @IPVC_CountryName)                                       
            )
  begin
    Update CNTRY
    set    CNTRY.Name            = @IPVC_CountryName
          ,CNTRY.ModifiedByIdSeq = @IPBI_UserIDSeq
          ,CNTRY.ModifiedDate    = @LDT_SystemDate 
          ,CNTRY.SystemLogDate   = @LDT_SystemDate
    from  CUSTOMERS.dbo.Country CNTRY with (nolock)
    where (CNTRY.Code =  @IPVC_CountryCode) 
    and   (CNTRY.Name <> @IPVC_CountryName)         
  end
  ------------------------------------------
END--> Main End
GO
