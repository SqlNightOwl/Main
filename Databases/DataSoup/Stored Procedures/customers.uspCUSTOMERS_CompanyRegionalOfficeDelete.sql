SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CompanyRegionalOfficeDelete
-- Description     : This procedure gets called for Deleting existing Regional Office of Company
--                   along with related Address.
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_CompanyRegionalOfficeDelete  Passing Input Parameters
-- Revision History:
-- Author          : SRS
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CompanyRegionalOfficeDelete] (@IPVC_CompanyIDSeq               varchar(50),       --> CompanyID (Mandatory) 
                                                                   @IPBI_RegionalOfficeID           bigint,            --> Mandatory. UI knows as part of resultset from EXEC CUSTOMERS.dbo.uspCUSTOMERS_AddressSelect call
                                                                   @IPBI_UserIDSeq                  bigint             --> This is UserID of person logged on and creating this Address in OMS.(Mandatory)
                                                                  )
as
BEGIN
  set nocount on;
  -----------------------------------------------
  declare  @LDT_SystemDate      datetime,
           @LVC_CodeSection     varchar(1000)
  select   @LDT_SystemDate      = Getdate()
  -----------------------------------------------
  ---Prequalification Criteria will be filled in later cross checking Relationship Matrix  
  -----------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION CRO;
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
      inner join
            Customers.dbo.AddressType Adt with (nolock)
      on     Addr.AddressTypecode = Adt.Code
      and    Addr.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    Addr.PropertyIDSeq   is null
      and    Addr.AddressTypecode not in ('COM','CST','CBT','PRO','PBT','PST')
      and    Adt.ApplyTo          = 'RegionalOffice'
      and    Adt.ApplyToRegionalOfficeIDSeq = @IPBI_RegionalOfficeID
      where  Addr.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    Addr.PropertyIDSeq   is null
      and    Addr.AddressTypecode not in ('COM','CST','CBT','PRO','PBT','PST')
      and    Adt.ApplyTo          = 'RegionalOffice'
      and    Adt.ApplyToRegionalOfficeIDSeq = @IPBI_RegionalOfficeID

      Delete Addr
      from  Customers.dbo.Address Addr with (nolock)
      inner join
            Customers.dbo.AddressType Adt with (nolock)
      on     Addr.AddressTypecode = Adt.Code
      and    Addr.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    Addr.PropertyIDSeq   is null
      and    Addr.AddressTypecode not in ('COM','CST','CBT','PRO','PBT','PST')
      and    Adt.ApplyTo          = 'RegionalOffice'
      and    Adt.ApplyToRegionalOfficeIDSeq = @IPBI_RegionalOfficeID
      where  Addr.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    Addr.PropertyIDSeq   is null
      and    Addr.AddressTypecode not in ('COM','CST','CBT','PRO','PBT','PST')
      and    Adt.ApplyTo          = 'RegionalOffice'
      and    Adt.ApplyToRegionalOfficeIDSeq = @IPBI_RegionalOfficeID 

      Delete from Customers.dbo.CompanyRegionalOffice
      where  CompanyIdSeq         = @IPVC_CompanyIDSeq
      and    RegionalOfficeIDSeq  = @IPBI_RegionalOfficeID
   COMMIT TRANSACTION CRO; 
  END TRY
  BEGIN CATCH
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION CRO;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION CRO;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION CRO;   
    ------------------------      
    select @LVC_CodeSection='Proc:uspCUSTOMERS_CompanyRegionalOfficeDelete - Unexpected Internal Error Occurred during Delete of Regional Office : ' + convert(varchar(50),@IPBI_RegionalOfficeID) + ' for Company : ' + @IPVC_CompanyIDSeq
    ------------------------    
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;                  
  END CATCH; 
  -----------------------------------------------------------  
END
GO
