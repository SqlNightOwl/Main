SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_DeleteCountry
-- Description     : This proc is called by Product Administration Country Management to an Existing Country
-- Input Parameters: @IPVC_CountryCode
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_DeleteCountry 
                          @IPVC_CountryCode = 'ABC'  ---> This is the existing Country that is to be deleted
                         ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Country Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_DeleteCountry]  (@IPVC_CountryCode    varchar(3),     ---->MANDATORY : This is the upto 3 character Unique Country Code of existing Country                                                                                                                                           
                                                     @IPBI_UserIDSeq      bigint= -1      ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                    )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_CountryCode = UPPER(NullIf(ltrim(rtrim(@IPVC_CountryCode)),'')),
          @LDT_SystemDate          = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_CountryCode cannot be blank or null
  If (@IPVC_CountryCode is null)
  begin
    select @LVC_CodeSection = 'Error: Country Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  --Validation 2: @IPVC_CountryCode should not be referenced by any Customer Address
  if exists (select  Top 1 1
             from    CUSTOMERS.dbo.Address ADDR with (nolock)
             where   ADDR.CountryCode = @IPVC_CountryCode
            )
  begin
    select @LVC_CodeSection = 'Error: Country Code is actively referenced by atleast one Customer/Property Address. Country cannot be deleted.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  --Validation 3: @IPVC_CountryCode should not be referenced by any TaxableCountry
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.TaxableCountry TC with (nolock)
             where   TC.TaxableCountryCode = @IPVC_CountryCode
            )
  begin
    select @LVC_CodeSection = 'Error: Country Code is actively referenced by atleast one Taxable Country Record in Product Master. Country cannot be deleted.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  Delete CNTRY
  from   CUSTOMERS.dbo.Country CNTRY with (nolock)
  where  (CNTRY.Code =  @IPVC_CountryCode);  
  ------------------------------------------
END--> Main End
GO
