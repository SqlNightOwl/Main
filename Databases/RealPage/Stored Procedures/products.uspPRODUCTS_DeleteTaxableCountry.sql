SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_DeleteTaxableCountry
-- Description     : This proc is called by Product Administration TaxableCountry Management to an Existing TaxableCountry
-- Input Parameters: @IPVC_TaxableCountryCode
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_DeleteTaxableCountry 
                       @IPVC_TaxableCountryCode = '12'                --> This is the existing TaxwareCompanyCode 
                      ,@IPVC_TaxableCountryCode = 'USA'               --> This is the existing TaxableCountrycode 
                      ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxableCountry Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_DeleteTaxableCountry]  (@IPVC_TaxwareCompanyCode          varchar(20),    ---> MANDATORY : This is existing TaxwareCompanyCode. This is upto 10 characters.
                                                            @IPVC_TaxableCountryCode          varchar(20),    ---> MANDATORY : This is the upto 3 character existing Unique TaxableCountry Code.
                                                            @IPBI_UserIDSeq                   bigint= -1      ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                           )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_TaxwareCompanyCode        = UPPER(NullIf(ltrim(rtrim(@IPVC_TaxwareCompanyCode)),'')),
          @IPVC_TaxableCountryCode        = UPPER(NullIf(ltrim(rtrim(@IPVC_TaxableCountryCode)),'')),         
          @LDT_SystemDate                 = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_TaxableCountryCode and @IPVC_TaxwareCompanyCode cannot be blank or null
  If (@IPVC_TaxwareCompanyCode is null)
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  

  If (@IPVC_TaxableCountryCode is null)
  begin
    select @LVC_CodeSection = 'Error: TaxableCountry Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------  
  Delete TAXC
  from   PRODUCTS.dbo.TaxableCountry TAXC with (nolock)
  where (TAXC.TaxwareCompanyCode =  @IPVC_TaxwareCompanyCode) 
  and   (TAXC.TaxableCountryCode =  @IPVC_TaxableCountryCode);
  ------------------------------------------
END--> Main End
GO
