SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_AddressDelete
-- Description     : This procedure gets called for Creation of Brand New Addresses
--                    This procedure takes care of Inserting Only Address Records.
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressDelete  Passing Input Parameters
-- Revision History:
-- Author          : SRS
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_AddressDelete] (@IPBI_AddressIDSeq           bigint,                --> Unique AddressIDSeq identifier returned by Proc Call uspCUSTOMERS_AddressSelect.
                                                                                                          -- UI to pass back as such for Update.
                                                     @IPVC_CompanyIDSeq           varchar(50),           --> CompanyID (Mandatory) : For Both Company and Property Addresses
                                                     @IPVC_PropertyIDSeq          varchar(50)='',        --> For Company Addresses, PropertyID is NULL or Blank. 
                                                                                                          -- For Property Addresses, PropertyID is Mandatory
                                                     @IPVC_AddressType            varchar(30),           --> AddressType (Mandatory) 
                                                                                                             -- This denotes the addressType as 'LOCATION' for Primary Location/Street
                                                                                                             -- This denotes the addressType as 'BILLING'  for Billing Address Type
                                                                                                             -- This denotes the addressType as 'SHIPPING' for Shipping Address Type 
                                                                                                             -- UI knows for what AddressType it is initiating address insert request.
                                                     @IPVC_AddressTypeApplyTo     varchar(30),           --- This denotes Address Type Apply to
                                                                                                             --   Company, Property,RegionalOffice
                                                     @IPVC_AddressTypeCode        varchar(20),           --> AddressTypeCode (Mandatory)
                                                                                                          -- For Company Location/Street Address, UI should Pass COM
                                                                                                          -- For Company Billing Address, UI should pass CBT (Expandable to CB0,CB1,CB2,CB3.. for future Release)
                                                                                                          -- For Company Shipping Address, UI should pass CST (Expandable to CS0,CS1,CS2,CS3.. for future Release)
                                                                                                          -- For Property Location/Street Address, UI should Pass PRO
                                                                                                          -- For Property Billing Address, UI should pass PBT (Expandable to PB0,PB1,PB2,PB3.. for multiple Billing Address;
                                                                                                          -- For Property Shipping Address, UI should pass PST (Expandable to PS0,PS1,PS2,PS3.. for future Release)
                                                     @IPBI_UserIDSeq              bigint                  --> This is UserID of person logged on and creating this Address in OMS.(Mandatory)
                                                  )
as 
BEGIN
  set nocount on; 
  -----------------------------------------------------------
  --Initialization of Variables.
  declare  @LDT_SystemDate      datetime,
           @LVC_CodeSection     varchar(1000)
  select  @LDT_SystemDate      = Getdate(),
          @IPVC_PropertyIDSeq  = LTRIM(RTRIM(NULLIF(@IPVC_PropertyIDSeq,'')))
  -----------------------------------------------------------
  -----------------------------------------------------------
  ---Address cannot be deleted for Primary default addresses
  -----------------------------------------------------------
  if (@IPVC_AddressTypeCode in ('COM','CBT','CST','PRO','PBT','PST'))
  begin
    --Do nothing as these AddressTypecode records are mandatory and cannot be deleted. Only Update is allowed.
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressDelete - Delete of Address for ' + @IPVC_AddressTypeApplyTo + ' for Type ' + @IPVC_AddressType + ' is not allowed.Use Update Instead'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  -----------------------------------------------------------  
  ---Prequalification Criteria will be filled in later cross checking Relationship Matrix
  -----------------------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION AH;
      Insert into Customers.dbo.AddressHistory(AddressIDSeq,CompanyIDSeq,PropertyIDSeq,AddressTypeCode,
                                               AddressLine1,AddressLine2,City,County,State,Zip,
                                               PhoneVoice1,PhoneVoiceExt1,PhoneVoice2,PhoneVoiceExt2,PhoneFax,Email,URL,
                                               SameAsPMCAddressFlag,CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate,
                                               AttentionName,GeoCodeFlag,GeoCodeMatch,Latitude,Longitude,MSANumber,
                                               Country,CountryCode,
                                               PhoneVoice3,PhoneVoiceExt3,PhoneVoice4,PhoneVoiceExt4)
      select Addr.IDSeq as AddressIDSeq,Addr.CompanyIDSeq,Addr.PropertyIDSeq,Addr.AddressTypeCode,
             Addr.AddressLine1,Addr.AddressLine2,Addr.City,Addr.County,Addr.State,Addr.Zip,
             Addr.PhoneVoice1,Addr.PhoneVoiceExt1,Addr.PhoneVoice2,Addr.PhoneVoiceExt2,Addr.PhoneFax,Addr.Email,Addr.URL,
             Addr.SameAsPMCAddressFlag,Addr.CreatedByIDSeq,@IPBI_UserIDSeq as ModifiedByIDSeq,Addr.CreatedDate,@LDT_SystemDate as ModifiedDate,
             Addr.AttentionName,Addr.GeoCodeFlag,Addr.GeoCodeMatch,Addr.Latitude,Addr.Longitude,Addr.MSANumber,
             Addr.Country,Addr.CountryCode,
             Addr.PhoneVoice3,Addr.PhoneVoiceExt3,Addr.PhoneVoice4,Addr.PhoneVoiceExt4
      from  Customers.dbo.Address Addr with (nolock)
      where Addr.IDSeq = @IPBI_AddressIDSeq
      and   Addr.AddressTypeCode = @IPVC_AddressTypeCode
      and   Addr.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and   Coalesce(Addr.PropertyIDSeq,'') = Coalesce(@IPVC_PropertyIDSeq,Coalesce(Addr.PropertyIDSeq,''))

      Delete from CUSTOMERS.dbo.Address
      where IDSeq = @IPBI_AddressIDSeq
      and   AddressTypeCode = @IPVC_AddressTypeCode
      and   CompanyIDSeq    = @IPVC_CompanyIDSeq
      and   Coalesce(PropertyIDSeq,'') = Coalesce(@IPVC_PropertyIDSeq,Coalesce(PropertyIDSeq,''))

   COMMIT TRANSACTION AH; 
  END TRY
  BEGIN CATCH
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION AH;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION AH;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION AH;   
    ------------------------      
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressDelete - Unexpected Internal Error Occurred during Delete of Address for ' + @IPVC_AddressTypeApplyTo + ' for Type ' + @IPVC_AddressType
    ------------------------    
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;                  
  END CATCH; 
  -----------------------------------------------------------
END
GO
