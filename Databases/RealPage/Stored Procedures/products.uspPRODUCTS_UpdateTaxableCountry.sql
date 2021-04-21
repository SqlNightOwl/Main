SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_UpdateTaxableCountry
-- Description     : This proc is called by Product Administration TaxableCountry Management to Update Existing TaxableCountrys
-- Input Parameters: @IPVC_TaxableCountryCode,@IPVC_TaxableCountryName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_UpdateTaxableCountry 
                       @IPVC_TaxableCountryCode = '12'                --> This is the existing TaxwareCompanyCode 
                      ,@IPVC_TaxableCountryCode = 'USA'               --> This is the existing TaxableCountrycode 
                      ,@IPI_CalculateTaxFlag    =  1                  --> This is the new @IPI_CalculateTaxFlag setting                 
                      ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxableCountry Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_UpdateTaxableCountry]  (@IPVC_TaxwareCompanyCode          varchar(10),    ---> MANDATORY : This is existing TaxwareCompanyCode. This is upto 10 characters.
                                                            @IPVC_TaxableCountryCode          varchar(3),    ---> MANDATORY : This is the upto 3 character existing Unique TaxableCountry Code.
                                                            @IPI_CalculateTaxFlag             int       =1,   ---> MANDATORY : This is the indicator to system whether to call Taxware for Calculating Taxes or Not.(Important)                                                       
                                                                                                              ---  Default is 1.
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
  --Validation 1 : @IPVC_TaxableCountryCode 
  If (@IPVC_TaxwareCompanyCode is null)
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  if len(@IPVC_TaxwareCompanyCode) > 10
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Code cannot be more than 10 characters';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  If (@IPVC_TaxableCountryCode is null)
  begin
    select @LVC_CodeSection = 'Error: TaxableCountry Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  if len(@IPVC_TaxableCountryCode) > 3
  begin
    select @LVC_CodeSection = 'Error: TaxableCountry Code cannot be more than 3 characters';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if (@IPI_CalculateTaxFlag not in (0,1))
  begin
    select @LVC_CodeSection = 'Error: Calculate Tax Flag as an identifier where TAXWARE call for corresponding product orders should be made or not can only be 1 for YES or 0 for No.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------ 
  if Not exists (select Top 1 1
                 from   Products.dbo.TaxwareCompany TC with (nolock)
                 where  TC.TaxwareCompanyCode = @IPVC_TaxwareCompanyCode
                )
  begin
    select @LVC_CodeSection = 'Error: Taxware Company is not found or set up yet. Please Set up Taxware Company first for this code before using this new TaxwareCompanyCode.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  if Not exists (select Top 1 1
                 from   CUSTOMERS.dbo.Country CTRY with (nolock)
                 where  CTRY.Code = @IPVC_TaxableCountryCode
                )
  begin
    select @LVC_CodeSection = 'Error: Country Code is not found or set up yet. Please Set up a valid Country with ISO Standardized 3 character CountryCode in Customers.dbo.Country. Refer: http://countrycode.org/ OR http://www.worldatlas.com/aatlas/ctycodes.htm';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.TaxableCountry TAXC with (nolock)
             where   TAXC.TaxwareCompanyCode = @IPVC_TaxwareCompanyCode
             and     TAXC.TaxableCountryCode = @IPVC_TaxableCountryCode
             and     (convert(int,TAXC.CalculateTaxFlag) <> @IPI_CalculateTaxFlag)
            )
  begin
    Update TAXC
    set    TAXC.CalculateTaxFlag  = (Case when (convert(int,TAXC.CalculateTaxFlag) <> @IPI_CalculateTaxFlag)
                                            then @IPI_CalculateTaxFlag
                                          else TAXC.CalculateTaxFlag
                                     end)
          ,TAXC.ModifiedByIdSeq = @IPBI_UserIDSeq
          ,TAXC.ModifiedDate    = @LDT_SystemDate 
          ,TAXC.SystemLogDate   = @LDT_SystemDate
    from  PRODUCTS.dbo.TaxableCountry TAXC with (nolock)
    where (TAXC.TaxwareCompanyCode =  @IPVC_TaxwareCompanyCode) 
    and   (TAXC.TaxableCountryCode =  @IPVC_TaxableCountryCode)
    and   (convert(int,TAXC.CalculateTaxFlag) <> @IPI_CalculateTaxFlag)        
  end
  ------------------------------------------
END--> Main End
GO
