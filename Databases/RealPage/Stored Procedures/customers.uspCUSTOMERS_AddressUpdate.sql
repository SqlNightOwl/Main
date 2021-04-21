SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_AddressUpdate
-- Description     : This procedure gets called for Update of Existing Addresses
--                    This procedure takes care of Updating Only Address Records.
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_AddressUpdate  Passing Input Parameters
-- Revision History:
-- Author          : SRS
-- 06/02/2011  Mahaboob Commented Validation checking for Duplicate Addresses.  Defect #533
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_AddressUpdate] (@IPBI_AddressIDSeq           bigint,                --> Unique AddressIDSeq identifier returned by Proc Call uspCUSTOMERS_AddressSelect.
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
                                                     @IPI_SameAsPMCAddressFlag    int         =0,         --> For Company Default is 0. APPLICABLE ONLY to Property Billing And Shipping address.
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
         @IPVC_PropertyIDSeq  = NULLIF(LTRIM(RTRIM(@IPVC_PropertyIDSeq)),''),
         @IPVC_AddressTypeCode= LTRIM(RTRIM(NULLIF(@IPVC_AddressTypeCode,''))),
         @IPVC_AttentionName  = LTRIM(RTRIM(NULLIF(@IPVC_AttentionName,''))),
         @IPVC_AddressLine1   = NULLIF(UPPER(LTRIM(RTRIM(@IPVC_AddressLine1))),''),
         @IPVC_AddressLine2   = NULLIF(UPPER(LTRIM(RTRIM(@IPVC_AddressLine2))),''),
         @IPVC_City           = NULLIF(UPPER(LTRIM(RTRIM(@IPVC_City))),''),
         @IPVC_State          = NULLIF(UPPER(LTRIM(RTRIM(@IPVC_State))),''),
         @IPVC_Zip            = NULLIF(LTRIM(RTRIM(@IPVC_Zip)),''),
         @IPVC_County         = NULLIF(UPPER(LTRIM(RTRIM(@IPVC_County))),''),
         @IPVC_Country        = NULLIF(UPPER(LTRIM(RTRIM(@IPVC_Country))),''),
         @IPVC_CountryCode    = NULLIF(UPPER(LTRIM(RTRIM(@IPVC_CountryCode))),''),
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
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressUpdate - AddressTypeCode Cannot be Null'
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
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressUpdate - AddressTypeCode : ' + @IPVC_AddressTypeCode + ' is not valid for '+@IPVC_AddressTypeApplyTo+' : ' + @IPVC_PropertyIDSeq + '. Aborting Address Update.'   
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end   
  ---Inital validation 4 : Check if Company ID is valid.
  if not exists (select top 1 1 
                 from   Customers.dbo.Company With (nolock)
                 where  IDSeq = @IPVC_CompanyIDSeq
                )
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressUpdate - CompanyID : ' + @IPVC_CompanyIDSeq + ' does not exist in OMS. Aborting Address creation.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end 
  ---Inital validation 5 : Check if Company ID is valid and PropertyId is valid, when both are passed.
  if not exists (select top 1 1 
                 from   Customers.dbo.Property With (nolock)
                 where  IDSeq    = @IPVC_PropertyIDSeq
                 and    PMCIDSeq = @IPVC_CompanyIDSeq
                )
      and 
      (@IPVC_PropertyIDSeq is not null)
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressUpdate - PropertyID : ' + @IPVC_PropertyIDSeq + ' does not belong to PMCID : '+@IPVC_CompanyIDSeq + '. Aborting Address update.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end 
  ---Inital validation 6 : Check if @IPVC_Country is null
  if (@IPVC_Country is  null)
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressUpdate - Country is Mandatory and is blank. Aborting Address update.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end  
  ---Inital validation 7 : Check if @IPVC_CountryCode is null
  if (@IPVC_CountryCode is  null)
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressUpdate - Country CODE is Mandatory and is blank. Aborting Address update.'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  ---Intial validation 0 : Check if any of the important address parameters in the list are blank: AddressLine1,City,Country,CountryCode,Zip
  If (len(@IPVC_AddressLine1)=0 OR len(@IPVC_City)=0 OR len(@IPVC_Country)=0 OR len(@IPVC_CountryCode)=0 OR Len(@IPVC_Zip)=0
     )
  begin
    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressUpdate - All Or One of Critical input Address attributes Missing : AddressLine1,City,Country,CountryCode,Zip'    
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
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
--    select @LVC_CodeSection='Proc:uspCUSTOMERS_AddressUpdate - Another Address with exact same attributes already exists for ' + @IPVC_AddressTypeApplyTo + ' for Type ' + @IPVC_AddressType + '. Duplicate entry not allowed.'
--    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
--    return
--  end
--Defect #533
  ----------------------------------------------------------------------------
  ---@IPI_SameAsPMCAddressFlag applies only to AddressTypeCode 'PST' and 'PBT'
  if (@IPVC_AddressTypeCode not in ('PST','PBT'))
  begin
    select @IPI_SameAsPMCAddressFlag = 0
  end
  ----------------------------------------------------------------------------
  --Step 1: @IPI_SameAsPMCAddressFlag=0 
  --         Start Address Update For Company Address based on Addresstypecode as applicable
  --         OR Address Update For Property Address based on Addresstypecode as applicable
  --       For Company @IPI_SameAsPMCAddressFlag is always 0 for all Addresstype Codes COM,CBT,CST
  --       For Property Street address @IPI_SameAsPMCAddressFlag is always 0 for AddressTypeCode = PRO
  --       Property can have @IPI_SameAsPMCAddressFlag 0 or 1 for Billing and Shipping address PBT and PST.          
  ----------------------------------------------------------------------------
  If (@IPI_SameAsPMCAddressFlag=0)
  begin
    ---> This Piece of Code will fire only for Company Adress and 
    --       Property Street Address and Shipping and Billing Address of Property if @IPI_SameAsPMCAddressFlag = 0
    Update Customers.dbo.Address 
    set    AddressLine1         = @IPVC_AddressLine1,
           AddressLine2         = @IPVC_AddressLine2,
           City                 = @IPVC_City,
           County               = @IPVC_County,
           State                = @IPVC_State,
           Zip                  = @IPVC_Zip,
           PhoneVoice1          = @IPVC_PhoneVoice1,
           PhoneVoiceExt1       = @IPVC_PhoneVoiceExt1, 
           PhoneVoice2          = @IPVC_PhoneVoice2, 
           PhoneVoiceExt2       = @IPVC_PhoneVoiceExt2,
           PhoneVoice3          = @IPVC_PhoneVoice3,
           PhoneVoiceExt3       = @IPVC_PhoneVoiceExt3,
           PhoneVoice4          = @IPVC_PhoneVoice4,
           PhoneVoiceExt4       = @IPVC_PhoneVoiceExt4,
           PhoneFax             = @IPVC_PhoneFax,
           Email                = @IPVC_Email,
           URL                  = @IPVC_URL,
           SameAsPMCAddressFlag = @IPI_SameAsPMCAddressFlag,
           AttentionName        = @IPVC_AttentionName,
           Latitude             = @IPVC_Latitude,
           Longitude            = @IPVC_Longitude,
           MSANumber            = @IPVC_MSANumber,  
           Country              = @IPVC_Country,
           CountryCode          = @IPVC_CountryCode,
           ModifiedByIDSeq      = @IPBI_UserIDSeq,
           ModifiedDate         = @LDT_SystemDate,
           SystemLogDate        = @LDT_SystemDate          
    where  IDSeq          = @IPBI_AddressIDSeq
    and    CompanyIDSeq   = @IPVC_CompanyIDSeq
    and    coalesce(PropertyIDSeq,'') = coalesce(@IPVC_PropertyIDSeq,coalesce(PropertyIDSeq,''))
    and    AddressTypeCode= @IPVC_AddressTypeCode

    Update Customers.dbo.Address 
    set    AddressLine1         = @IPVC_AddressLine1,
           AddressLine2         = @IPVC_AddressLine2,
           City                 = @IPVC_City,
           County               = @IPVC_County,
           State                = @IPVC_State,
           Zip                  = @IPVC_Zip,
           PhoneVoice1          = @IPVC_PhoneVoice1,
           PhoneVoiceExt1       = @IPVC_PhoneVoiceExt1, 
           PhoneVoice2          = @IPVC_PhoneVoice2, 
           PhoneVoiceExt2       = @IPVC_PhoneVoiceExt2,
           PhoneVoice3          = @IPVC_PhoneVoice3,
           PhoneVoiceExt3       = @IPVC_PhoneVoiceExt3,
           PhoneVoice4          = @IPVC_PhoneVoice4,
           PhoneVoiceExt4       = @IPVC_PhoneVoiceExt4,
           PhoneFax             = @IPVC_PhoneFax,
           Email                = @IPVC_Email,
           URL                  = @IPVC_URL,           
           AttentionName        = @IPVC_AttentionName,
           Latitude             = @IPVC_Latitude,
           Longitude            = @IPVC_Longitude,
           MSANumber            = @IPVC_MSANumber,  
           Country              = @IPVC_Country,
           CountryCode          = @IPVC_CountryCode,
           ModifiedByIDSeq      = @IPBI_UserIDSeq,
           ModifiedDate         = @LDT_SystemDate,
           SystemLogDate        = @LDT_SystemDate          
    where  CompanyIDSeq         = @IPVC_CompanyIDSeq 
    and    PropertyIDSeq       is NOT NULL
    and    @IPVC_PropertyIDSeq is NULL
    and    (@IPVC_AddressTypeCode in ('CST','CBT'))
    and    AddressTypeCode = (Case when @IPVC_AddressTypeCode = 'CST'  Then 'PST'
                                   when @IPVC_AddressTypeCode = 'CBT'  Then 'PBT'
                                   else 'XYZ'
                              end)
    and    SameAsPMCAddressFlag = 1

  end
  ----------------------------------------------------------------------------
  --Step 2: Start Address Update For Property Address based on Addresstypecode and if @IPI_SameAsPMCAddressFlag=1
  --   if Propagate all attributes of Corresponding Company Billing And Or Shipping Address to Property Billing And / Or Shipping Address.
  ----------------------------------------------------------------------------
  else if (@IPI_SameAsPMCAddressFlag=1)
  begin
    ---> This Piece of Code will fire only for Property Shipping and Billing Address For Property if @IPI_SameAsPMCAddressFlag = 1
    Update PropAddr 
    set    PropAddr.AddressLine1         = CompAddr.AddressLine1,
           PropAddr.AddressLine2         = CompAddr.AddressLine2,
           PropAddr.City                 = CompAddr.City,
           PropAddr.County               = CompAddr.County,
           PropAddr.State                = CompAddr.State,
           PropAddr.Zip                  = CompAddr.Zip,
           PropAddr.PhoneVoice1          = CompAddr.PhoneVoice1,
           PropAddr.PhoneVoiceExt1       = CompAddr.PhoneVoiceExt1, 
           PropAddr.PhoneVoice2          = CompAddr.PhoneVoice2, 
           PropAddr.PhoneVoiceExt2       = CompAddr.PhoneVoiceExt2,
           PropAddr.PhoneVoice3          = CompAddr.PhoneVoice3,
           PropAddr.PhoneVoiceExt3       = CompAddr.PhoneVoiceExt3,
           PropAddr.PhoneVoice4          = CompAddr.PhoneVoice4,
           PropAddr.PhoneVoiceExt4       = CompAddr.PhoneVoiceExt4,
           PropAddr.PhoneFax             = CompAddr.PhoneFax,
           PropAddr.Email                = CompAddr.Email,
           PropAddr.URL                  = CompAddr.URL,
           PropAddr.SameAsPMCAddressFlag = @IPI_SameAsPMCAddressFlag,
           PropAddr.AttentionName        = CompAddr.AttentionName,
           PropAddr.Latitude             = CompAddr.Latitude,
           PropAddr.Longitude            = CompAddr.Longitude,
           PropAddr.MSANumber            = CompAddr.MSANumber,  
           PropAddr.Country              = CompAddr.Country,
           PropAddr.CountryCode          = CompAddr.CountryCode,
           PropAddr.ModifiedByIDSeq      = @IPBI_UserIDSeq,
           PropAddr.ModifiedDate         = @LDT_SystemDate,
           PropAddr.SystemLogDate        = @LDT_SystemDate
    from   Customers.dbo.Address PropAddr with (nolock)
    inner join
           Customers.dbo.Address CompAddr with (nolock)
    on     PropAddr.IDSeq          = @IPBI_AddressIDSeq
    and    PropAddr.CompanyIDSeq   = CompAddr.CompanyIDSeq
    and    PropAddr.CompanyIDSeq   = @IPVC_CompanyIDSeq
    and    CompAddr.CompanyIDSeq   = @IPVC_CompanyIDSeq
    and    CompAddr.PropertyIDSeq  is NULL
    and    PropAddr.PropertyIDSeq  = @IPVC_PropertyIDSeq
    and    PropAddr.PropertyIDSeq  is NOT NULL    
    and    PropAddr.AddressTypeCode= @IPVC_AddressTypeCode
    and    (@IPVC_AddressTypeCode in ('PST','PBT'))
    and    CompAddr.AddressTypeCode = (Case when @IPVC_AddressTypeCode = 'PST' Then 'CST'
                                            when @IPVC_AddressTypeCode = 'PBT' Then 'CBT'
                                            else 'XYZ'
                                       end)
    and    @IPI_SameAsPMCAddressFlag = 1;
  end
  ----------------------------------------------------------------------------
  ---> This Piece of Code will fire only for Company Adress Update for CST,CBT
  --   to propagate the address to corresponding Property Billing, Shipping Addresses
  --   that have SameAsPMCAddressFlag = 1
  ----------------------------------------------------------------------------
  if  ((@IPVC_PropertyIDSeq is Null) and (@IPVC_AddressTypeCode in ('CST','CBT')))
  begin
    ---Billing
    Update PropAddr 
    set    PropAddr.AddressLine1         = CompAddr.AddressLine1,
           PropAddr.AddressLine2         = CompAddr.AddressLine2,
           PropAddr.City                 = CompAddr.City,
           PropAddr.County               = CompAddr.County,
           PropAddr.State                = CompAddr.State,
           PropAddr.Zip                  = CompAddr.Zip,
           PropAddr.PhoneVoice1          = CompAddr.PhoneVoice1,
           PropAddr.PhoneVoiceExt1       = CompAddr.PhoneVoiceExt1, 
           PropAddr.PhoneVoice2          = CompAddr.PhoneVoice2, 
           PropAddr.PhoneVoiceExt2       = CompAddr.PhoneVoiceExt2,
           PropAddr.PhoneVoice3          = CompAddr.PhoneVoice3,
           PropAddr.PhoneVoiceExt3       = CompAddr.PhoneVoiceExt3,
           PropAddr.PhoneVoice4          = CompAddr.PhoneVoice4,
           PropAddr.PhoneVoiceExt4       = CompAddr.PhoneVoiceExt4,
           PropAddr.PhoneFax             = CompAddr.PhoneFax,
           PropAddr.Email                = CompAddr.Email,
           PropAddr.URL                  = CompAddr.URL,           
           PropAddr.AttentionName        = CompAddr.AttentionName,
           PropAddr.Latitude             = CompAddr.Latitude,
           PropAddr.Longitude            = CompAddr.Longitude,
           PropAddr.MSANumber            = CompAddr.MSANumber,  
           PropAddr.Country              = CompAddr.Country,
           PropAddr.CountryCode          = CompAddr.CountryCode,
           PropAddr.ModifiedByIDSeq      = @IPBI_UserIDSeq,
           PropAddr.ModifiedDate         = @LDT_SystemDate,
           PropAddr.SystemLogDate        = @LDT_SystemDate
    from   Customers.dbo.Address PropAddr with (nolock)
    inner join
           Customers.dbo.Address CompAddr with (nolock)
    on     PropAddr.CompanyIDSeq   = CompAddr.CompanyIDSeq
    and    PropAddr.CompanyIDSeq   = @IPVC_CompanyIDSeq
    and    CompAddr.CompanyIDSeq   = @IPVC_CompanyIDSeq 
    and    PropAddr.PropertyIDSeq  is NOT NULL     
    and    CompAddr.PropertyIDSeq  is NULL 
    and    PropAddr.AddressTypeCode      = 'PBT'
    and    CompAddr.AddressTypeCode      = 'CBT'
    and    PropAddr.SameAsPMCAddressFlag = 1
    and    ( 

             Binary_CheckSum(coalesce(ltrim(rtrim(PropAddr.AddressLine1)),'ABCDEF'),                             
                             coalesce(ltrim(rtrim(PropAddr.City)),'ABCDEF'),
                             coalesce(ltrim(rtrim(PropAddr.State)),'ABCDEF'), 
                             coalesce(ltrim(rtrim(PropAddr.Zip)),'ABCDEF')
                            ) <> 
             Binary_CheckSum(coalesce(ltrim(rtrim(CompAddr.AddressLine1)),'ABCDEF'),                             
                             coalesce(ltrim(rtrim(CompAddr.City)),'ABCDEF'),
                             coalesce(ltrim(rtrim(CompAddr.State)),'ABCDEF'), 
                             coalesce(ltrim(rtrim(CompAddr.Zip)),'ABCDEF')
                            )
           );
    ------------------------------
    ---Shipping
    Update PropAddr 
    set    PropAddr.AddressLine1         = CompAddr.AddressLine1,
           PropAddr.AddressLine2         = CompAddr.AddressLine2,
           PropAddr.City                 = CompAddr.City,
           PropAddr.County               = CompAddr.County,
           PropAddr.State                = CompAddr.State,
           PropAddr.Zip                  = CompAddr.Zip,
           PropAddr.PhoneVoice1          = CompAddr.PhoneVoice1,
           PropAddr.PhoneVoiceExt1       = CompAddr.PhoneVoiceExt1, 
           PropAddr.PhoneVoice2          = CompAddr.PhoneVoice2, 
           PropAddr.PhoneVoiceExt2       = CompAddr.PhoneVoiceExt2,
           PropAddr.PhoneVoice3          = CompAddr.PhoneVoice3,
           PropAddr.PhoneVoiceExt3       = CompAddr.PhoneVoiceExt3,
           PropAddr.PhoneVoice4          = CompAddr.PhoneVoice4,
           PropAddr.PhoneVoiceExt4       = CompAddr.PhoneVoiceExt4,
           PropAddr.PhoneFax             = CompAddr.PhoneFax,
           PropAddr.Email                = CompAddr.Email,
           PropAddr.URL                  = CompAddr.URL,           
           PropAddr.AttentionName        = CompAddr.AttentionName,
           PropAddr.Latitude             = CompAddr.Latitude,
           PropAddr.Longitude            = CompAddr.Longitude,
           PropAddr.MSANumber            = CompAddr.MSANumber,  
           PropAddr.Country              = CompAddr.Country,
           PropAddr.CountryCode          = CompAddr.CountryCode,
           PropAddr.ModifiedByIDSeq      = @IPBI_UserIDSeq,
           PropAddr.ModifiedDate         = @LDT_SystemDate,
           PropAddr.SystemLogDate        = @LDT_SystemDate
    from   Customers.dbo.Address PropAddr with (nolock)
    inner join
           Customers.dbo.Address CompAddr with (nolock)
    on     PropAddr.CompanyIDSeq   = CompAddr.CompanyIDSeq
    and    PropAddr.CompanyIDSeq   = @IPVC_CompanyIDSeq
    and    CompAddr.CompanyIDSeq   = @IPVC_CompanyIDSeq 
    and    PropAddr.PropertyIDSeq  is NOT NULL     
    and    CompAddr.PropertyIDSeq  is NULL 
    and    PropAddr.AddressTypeCode      = 'PST'
    and    CompAddr.AddressTypeCode      = 'CST'
    and    PropAddr.SameAsPMCAddressFlag = 1
    and    ( 

             Binary_CheckSum(coalesce(ltrim(rtrim(PropAddr.AddressLine1)),'ABCDEF'),                             
                             coalesce(ltrim(rtrim(PropAddr.City)),'ABCDEF'),
                             coalesce(ltrim(rtrim(PropAddr.State)),'ABCDEF'), 
                             coalesce(ltrim(rtrim(PropAddr.Zip)),'ABCDEF')
                            ) <> 
             Binary_CheckSum(coalesce(ltrim(rtrim(CompAddr.AddressLine1)),'ABCDEF'),                             
                             coalesce(ltrim(rtrim(CompAddr.City)),'ABCDEF'),
                             coalesce(ltrim(rtrim(CompAddr.State)),'ABCDEF'), 
                             coalesce(ltrim(rtrim(CompAddr.Zip)),'ABCDEF')
                            )
           );              
  ----------------------------------------------------------------------------
  end
END
GO
