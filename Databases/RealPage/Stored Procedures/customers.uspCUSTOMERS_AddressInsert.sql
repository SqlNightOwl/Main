SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_AddressInsert
-- Description     : This procedure gets called for Creation of Brand New Addresses
--                    This procedure takes care of Inserting Only Address Records.
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressInsert  Passing Input Parameters
-- Revision History:
-- Author          : SRS
-- 06/02/2011  Mahaboob Commented Validation checking for Duplicate Addresses. Defect #533
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_AddressInsert] (@IPVC_CompanyIDSeq           varchar(50),           --> CompanyID (Mandatory) : For Both Company and Property Addresses
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
                                                                                                          -- For Property Billing Address, UI should pass PBT (Expandable to PB0,PB1,PB2,PB3.. for multiple Billing Address; column NextAvailableAddressTypeCode from Call of uspCUSTOMERS_AddressSelect)
                                                                                                          -- For Property Shipping Address, UI should pass PST (Expandable to PS0,PS1,PS2,PS3.. for future Release)
                                                     @IPVC_AttentionName          varchar(255)='',        --> Corresponding to Contact Name Text field in UI      
                                                     @IPVC_AddressLine1           varchar(255),           --> AddressLine1
                                                     @IPVC_AddressLine2           varchar(255)='',        --> AddressLine2 (Optional)
                                                     @IPVC_City                   varchar(100),           --> City
                                                     @IPVC_State                  varchar(2)  ='',        --> State (Mandatory) for US. 
                                                     @IPVC_Zip                    varchar(100),           --> Zipcode
                                                     @IPVC_County                 varchar(100)='',        --> County (ie.like Collin County, Denton County etc)
                                                     @IPVC_Country                varchar(100),           --> Value of Country Drop down user selection (Mandatory) like USA,Canada etc
                                                     @IPVC_CountryCode            varchar(100),           --> Code corresponding to Country Drop down user selection (Mandatory)

                                                     @IPVC_PhoneVoice1            varchar(50) ='',        --> Corresponding to Phone Text field in UI
                                                     @IPVC_PhoneVoiceExt1         varchar(50) ='',        --> Corresponding to Phone Ext Text field in UI
                                                     @IPVC_PhoneVoice2            varchar(50) ='',        --> Not in Use currently (For Future) UI Pass Blank
                                                     @IPVC_PhoneVoiceExt2         varchar(50) ='',        --> Not in Use currently (For Future) UI Pass Blank
                                                     @IPVC_PhoneVoice3            varchar(50) ='',        --> Not in Use currently (For Future) UI Pass Blank
                                                     @IPVC_PhoneVoiceExt3         varchar(50) ='',        --> Not in Use currently (For Future) UI Pass Blank
                                                     @IPVC_PhoneVoice4            varchar(50) ='',        --> Corresponding to Cell Phone Text field in UI
                                                     @IPVC_PhoneVoiceExt4         varchar(50) ='',        --> Not in Use currently (For Future) UI Pass Blank. Cell Phones dont have Extension
                                                     @IPVC_PhoneFax               varchar(50) ='',        --> Corresponding to Fax Text field in UI
                                                     @IPVC_Email                  varchar(4000)='',       --> Email ID (Optional) Corresponding to Email Text field in UI
                                                     @IPVC_URL                    varchar(255)='',        --> URL For Company. Applicable only to Company. For Property, pass blank.
                                                     @IPI_SameAsPMCAddressFlag    int         =0,         --> For Company Default is 0. Applicable only to Property Billing And Shipping address.
                                                                                                            -- When User checks Check Box, Pass 1, Else 0.
                                                     @IPVC_Latitude               varchar(50)='',         --> UI is not capturing (Future). Default is blank.
                                                     @IPVC_Longitude              varchar(50)='',         --> UI is not capturing (Future). Default is blank.
                                                     @IPVC_MSANumber              varchar(50)='',         --> UI is not capturing (Future). Default is blank.
                                                     @IPBI_UserIDSeq              bigint                  --> This is UserID of person logged on and creating this Address in OMS.(Mandatory)
                                                    )
as 
BEGIN
  set nocount on;  
  SET CONCAT_NULL_YIELDS_NULL off;
  ----------------------------------------------------------------------------
  -- Local Variable Declaration
  ----------------------------------------------------------------------------   
  declare @LDT_SystemDate      datetime,
          @LVC_CodeSection     varchar(1000) 
  ----------------------------------------------------------------------------
  --Initialization of Variables.
  select @LDT_SystemDate      = Getdate(),                
         @IPVC_PropertyIDSeq  = LTRIM(RTRIM(NULLIF(@IPVC_PropertyIDSeq,''))),
         @IPVC_AddressTypeCode= LTRIM(RTRIM(NULLIF(@IPVC_AddressTypeCode,''))),
         @IPVC_AttentionName  = LTRIM(RTRIM(NULLIF(@IPVC_AttentionName,''))),
         @IPVC_AddressLine1   = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_AddressLine1,'')))),
         @IPVC_AddressLine2   = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_AddressLine2,'')))),
         @IPVC_City           = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_City,'')))),
         @IPVC_State          = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_State,'')))),
         @IPVC_Zip            = LTRIM(RTRIM(NULLIF(@IPVC_Zip,''))),
         @IPVC_County         = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_County,'')))),
         @IPVC_Country        = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_Country,'')))), 
         @IPVC_CountryCode    = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_CountryCode,'')))),
         @IPVC_PhoneVoice1    = LTRIM(RTRIM(NULLIF(@IPVC_PhoneVoice1,''))),
         @IPVC_PhoneVoiceExt1 = LTRIM(RTRIM(NULLIF(@IPVC_PhoneVoiceExt1,''))),
         @IPVC_PhoneVoice2    = LTRIM(RTRIM(NULLIF(@IPVC_PhoneVoice2,''))),
         @IPVC_PhoneVoiceExt2 = LTRIM(RTRIM(NULLIF(@IPVC_PhoneVoiceExt2,''))),
         @IPVC_PhoneVoice3    = LTRIM(RTRIM(NULLIF(@IPVC_PhoneVoice3,''))),
         @IPVC_PhoneVoiceExt3 = LTRIM(RTRIM(NULLIF(@IPVC_PhoneVoiceExt3,''))),
         @IPVC_PhoneVoiceExt4 = LTRIM(RTRIM(NULLIF(@IPVC_PhoneVoiceExt4,''))),
         @IPVC_PhoneFax       = LTRIM(RTRIM(NULLIF(@IPVC_PhoneFax,''))),
         @IPVC_Email          = LTRIM(RTRIM(NULLIF(@IPVC_Email,''))),
         @IPVC_URL            = LTRIM(RTRIM(NULLIF(@IPVC_URL,''))),
         @IPVC_Latitude       = LTRIM(RTRIM(NULLIF(@IPVC_Latitude,''))),
         @IPVC_Longitude      = LTRIM(RTRIM(NULLIF(@IPVC_Longitude,''))),
         @IPVC_MSANumber      = LTRIM(RTRIM(NULLIF(@IPVC_MSANumber,'')))
         
  ----------------------------------------------------------------------------
  ---Inital validation 1 : Address Type Code  cannot be null
  if (@IPVC_AddressTypeCode is null)
   begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - AddressTypeCode Cannot be Null'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end 
  ---Inital validation 2 : If CompanyID and PropertyID are passed, then it is Property based Address.
  ---                      If CompanyID is passed and PropertyID is NULL, then it is Company based Address.
  ---Validation if the Passed in @IPVC_AddressTypeCode matches the right Apply to
  if not exists (select top 1 1
                 from   CUSTOMERS.dbo.AddressType Adt with (nolock) 
                 where  Adt.ApplyTo     = @IPVC_AddressTypeApplyTo
                 and    Adt.Type        = @IPVC_AddressType
                 and    Adt.Code        = @IPVC_AddressTypeCode
                )
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - AddressTypeCode : ' + @IPVC_AddressTypeCode + ' is not valid for '+@IPVC_AddressTypeApplyTo+' : ' + @IPVC_PropertyIDSeq + '. Aborting Address creation.'   
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end    
  ---Inital validation 3 : Check if Company ID is valid.
  if not exists (select top 1 1 
                 from   Customers.dbo.Company With (nolock)
                 where  IDSeq = @IPVC_CompanyIDSeq
                )
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - CompanyID : ' + @IPVC_CompanyIDSeq + ' does not exist in OMS. Aborting Address creation.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end 
  ---Inital validation 4 : Check if Company ID is valid and PropertyId is valid, when both are passed.
  if not exists (select top 1 1 
                 from   Customers.dbo.Property With (nolock)
                 where  IDSeq    = @IPVC_PropertyIDSeq
                 and    PMCIDSeq = @IPVC_CompanyIDSeq
                )
      and 
      (@IPVC_PropertyIDSeq is not null)
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - PropertyID : ' + @IPVC_PropertyIDSeq + ' does not belong to PMCID : '+@IPVC_CompanyIDSeq + '. Aborting Address creation.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end 
  ---Inital validation 5 : Check if @IPVC_Country is null
  if (@IPVC_Country is  null)
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - Country is Mandatory and is blank. Aborting Address creation.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end  
  ---Inital validation 6 : Check if @IPVC_CountryCode is null
  if (@IPVC_CountryCode is  null)
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - Country CODE is Mandatory and is blank. Aborting Address creation.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end 
  ---Intial validation 7 : Check if the Address for passed parameters. If yes, This is wrong proc call. Only Update Proc needs to be called.
  If exists (select top 1 1 
             from   Customers.dbo.Address ADDR with (nolock)
             where  ADDR.CompanyIDSeq = @IPVC_CompanyIDSeq
             and    Coalesce(ADDR.PropertyIDSeq,'') = Coalesce(@IPVC_PropertyIDSeq,Coalesce(ADDR.PropertyIDSeq,''))
             and    ADDR.AddressTypeCode= @IPVC_AddressTypeCode
            )
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - Address already exists in the system. Wrong Proc call uspCUSTOMERS_AddressInsert from UI. Only uspCUSTOMERS_AddressUpdate should be initiated.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  ---Intial validation 9 : Check if any of the important address parameters in the list are blank: AddressLine1,City,Country,CountryCode,Zip
  If (len(@IPVC_AddressLine1)=0 OR len(@IPVC_City)=0 OR len(@IPVC_Country)=0 OR len(@IPVC_CountryCode)=0 OR Len(@IPVC_Zip)=0
     )
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - All Or One of Critical input Address attributes Missing : AddressLine1,City,Country,CountryCode,Zip'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  ---------------------------------------------------------------------------- 
--Defect #533 
--  if exists (select top 1 1
--             from   Customers.dbo.Address ADDR with (nolock)
--             inner join
--                    Customers.dbo.AddressType Adt with (nolock)
--             on     ADDR.AddressTypeCode = Adt.Code
--             and    Adt.Type             = @IPVC_AddressType             
--             and    ADDR.CompanyIDSeq    = @IPVC_CompanyIDSeq
--             and    Coalesce(ADDR.PropertyIDSeq,'') = Coalesce(@IPVC_PropertyIDSeq,Coalesce(ADDR.PropertyIDSeq,''))
--             and    ADDR.AddressTypeCode <> @IPVC_AddressTypeCode
--             and    @IPVC_AddressTypeCode not in ('COM','CBT','CST','PRO','PBT','PST')
--             and    ADDR.AddressLine1  = @IPVC_AddressLine1
--             and    ADDR.City          = @IPVC_City
--             and    ADDR.State         = @IPVC_State
--             and    substring(ADDR.Zip,1,5) = substring(@IPVC_Zip,1,5)
--             and    ADDR.Country       = @IPVC_Country
--            )
--  begin
--    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - Another Address with exact same attributes already exists for ' + @IPVC_AddressTypeApplyTo + ' for Type ' + @IPVC_AddressType + '. Duplicate entry not allowed.'
--    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
--    return
--  end
--Defect #533
  ----------------------------------------------------------------------------  
  --Step 1 : Insert Address
  begin TRY
    Insert into Customers.dbo.Address(CompanyIDSeq,PropertyIDSeq,AddressTypeCode,
                                      AddressLine1,AddressLine2,City,County,State,Zip,
                                      PhoneVoice1,PhoneVoiceExt1,
                                      PhoneVoice2,PhoneVoiceExt2,
                                      PhoneVoice3,PhoneVoiceExt3,
                                      PhoneVoice4,PhoneVoiceExt4,
                                      PhoneFax,Email,URL,
                                      SameAsPMCAddressFlag,
                                      AttentionName, 
                                      Latitude,Longitude,MSANumber,
                                      Country,CountryCode,
                                      CreatedByIDSeq,CreatedDate,SystemLogDate)
    select @IPVC_CompanyIDSeq as CompanyIDSeq,@IPVC_PropertyIDSeq as PropertyIDSeq,@IPVC_AddressTypeCode as AddressTypeCode,
           @IPVC_AddressLine1 as AddressLine1,@IPVC_AddressLine2  as AddressLine2,@IPVC_City as City,@IPVC_County as County,@IPVC_State as State,@IPVC_Zip as Zip,
           @IPVC_PhoneVoice1  as PhoneVoice1,@IPVC_PhoneVoiceExt1 as PhoneVoiceExt1,
           @IPVC_PhoneVoice2  as PhoneVoice2,@IPVC_PhoneVoiceExt2 as PhoneVoiceExt2,
           @IPVC_PhoneVoice3  as PhoneVoice3,@IPVC_PhoneVoiceExt3 as PhoneVoiceExt3,
           @IPVC_PhoneVoice4  as PhoneVoice4,@IPVC_PhoneVoiceExt4 as PhoneVoiceExt4,
           @IPVC_PhoneFax     as PhoneFax,@IPVC_Email as Email,@IPVC_URL as URL,
           @IPI_SameAsPMCAddressFlag as SameAsPMCAddressFlag,
           @IPVC_AttentionName as AttentionName, 
           @IPVC_Latitude as Latitude,@IPVC_Longitude  as Longitude,@IPVC_MSANumber as MSANumber,
           @IPVC_Country  as Country,@IPVC_CountryCode as CountryCode,
           @IPBI_UserIDSeq as  CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
  end TRY
  begin CATCH
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressInsert - Unexpected Internal Error Occurred during Insert of Address for ' + @IPVC_AddressTypeApplyTo + ' for Type ' + @IPVC_AddressType
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end CATCH
  ---------------------------------------------------------------------------- 
END
GO
