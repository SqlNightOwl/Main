SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
exec CUSTOMERS.dbo.uspCUSTOMERS_PushAccountInfoToEpicor @IPVC_CompanyID='C0901000406'
exec CUSTOMERS.dbo.uspCUSTOMERS_PushAccountInfoToEpicor @IPVC_CompanyID='C0901000406',@IPVC_PropertyID='P0901004723'
*/

----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_PushAccountInfoToEpicor
-- Description     : This procedure Selects Account Info for Epicor Push for the passed parameters.
-- Input Parameters: 1. @IPVC_CompanyID   as varchar(50)
--                   2. @IPVC_PropertyID  as varchar(50)
-- OUTPUT          : None
--  
--                   
-- Code Example    : exec CUSTOMERS.dbo.uspCUSTOMERS_PushAccountInfoToEpicor @IPVC_CompanyID='C0901000406'
--                   exec CUSTOMERS.dbo.uspCUSTOMERS_PushAccountInfoToEpicor @IPVC_CompanyID='C0901000406',
--                                                                           @IPVC_PropertyID='P0901004723'
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 03/28/2007      : Stored Procedure Created.
-- 05/25/2010      : Shashi Bhushan  Defect #7656 Altered procedure to send attn name and phone from address table instead of Contact table to Epicor.
-- 05/25/2010      : Shashi Bhushan  Defect #7656 Altered to handle the scenario when SameAsPMCAddressFlag = 1
-- 04/27/2011	   : Surya Kondapalli Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
-- 10/03/2011	   : Surya Kondapalli Task# 1244 - Send vendor flag as parameter when inserting or updating an epicor customer
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_PushAccountInfoToEpicor] (@IPVC_CompanyID  varchar(50),
                                                           @IPVC_PropertyID varchar(50)=NULL                                      
                                                           )
AS
BEGIN
  set nocount on 
  ----------------------------------------------------------------------------
  --Declaring Local Temporary Tables 
  declare @LT_FinalResultsToEpicor table (CompanyIDSeq             varchar(50),
                                          PropertyIDSeq            varchar(50),
                                          AccountIDSeq             varchar(50),
                                          AccountTypeCode          varchar(50),
                                          AccountName              varchar(255),
                                          ActiveFlag               smallint not null default 0,
                                          SiteMasterID             varchar(50),
                                          EpicorCustomerCode       varchar(50),                                                                                   
                                          BillToAccountName        varchar(255),
                                          BillToAddressLine1       varchar(255),
                                          BillToAddressLine2       varchar(255),
                                          BillToCity               varchar(100),
                                          BillToState              varchar(50),
                                          BillToZipcode            varchar(50),      
                                          BillToCountry            varchar(50), 
                                          BillToCountryCode        varchar(20),     
                                          BillToAttnName           varchar(255),    
                                          BillToAttnPhoneVoice1    varchar(50),
                                          BillToAttnPhoneVoiceExt1 varchar(50),
                                          BillToPhoneFax           varchar(50),          
                                          BillToPhoneVoice1        varchar(50),       
                                          BillToPhoneVoiceExt1     varchar(50),
                                          BillToPhoneVoice2        varchar(50),
                                          BillToPhoneVoiceExt2     varchar(50),
                                          AddressURL               varchar(255),
										  CurrencyCode			   varchar(3),
										  VendorFlag               bit 	
                                         )  
  -------------------------------------------------------------------------------------------
  IF (@IPVC_CompanyID is not null) and (@IPVC_PropertyID = '' or @IPVC_PropertyID IS NULL)
  BEGIN
    ---Gather Records into @LT_FinalResultsToEpicor For Company Based Account
    insert into @LT_FinalResultsToEpicor (CompanyIDSeq,PropertyIDSeq,AccountIDSeq,AccountTypeCode,AccountName,ActiveFlag,SiteMasterID,EpicorCustomerCode,BillToAccountName,
                BillToAddressLine1,BillToAddressLine2,BillToCity,BillToState,BillToZipcode,BillToCountry,BillToCountryCode,
                BillToAttnName,BillToAttnPhoneVoice1,BillToAttnPhoneVoiceExt1,BillToPhoneFax,BillToPhoneVoice1,BillToPhoneVoiceExt1,BillToPhoneVoice2,BillToPhoneVoiceExt2,AddressURL,
				CurrencyCode,VendorFlag)
    Select distinct 
             A.companyIDSeq              as companyIDSeq,
             A.PropertyIDSeq             as propertyIDSeq,
             A.IDSeq                     as AccountIDSeq,
             A.AccountTypeCode           as AccountTypeCode,
             C.Name                      as AccountName,
             A.ActiveFlag                as ActiveFlag,
             C.SiteMasterID              as SiteMasterID,
             A.EpicorCustomerCode        as EpicorCustomerCode,
             C.Name                      as BillToAccountName,
             ADR.AddressLine1            as BillToAddressLine1,
             ADR.AddressLine2            as BillToAddressLine2,
             ADR.City                    as BillToCity,
             ADR.State                   as BillToState,
             ADR.Zip                     as BillToZipcode,
             ADR.Country                 as BillToCountry,
             ADR.CountryCode             as BillToCountryCode,
             case when ADR.AddressTypeCode = 'CBT' then ADR.AttentionName
                  else '' 
              end                        as BillToAttnName,
             case when ADR.AddressTypeCode = 'CBT' then ADR.PhoneVoice2
                  else '' 
              end                        as BillToAttnPhoneVoice1,
             case when ADR.AddressTypeCode = 'CBT' then ADR.PhoneVoiceExt2
                  else '' 
              end                        as BillToAttnPhoneVoiceExt1,  
             ADR.PhoneFax                as BillToPhoneFax, 
             ADR.PhoneVoice1             as BillToPhoneVoice1, 
             ADR.PhoneVoiceExt1          as BillToPhoneVoiceExt1,
             ADR.PhoneVoice2             as BillToPhoneVoice2,
             ADR.PhoneVoiceExt2          as BillToPhoneVoiceExt2,
             ADR.URL                     as AddressURL,
			 case when ADR.CountryCode = 'CAN' then 'CAD'
				  else 'USD'
			 end					    as CurrencyCode,
			 C.VendorFlag               as VendorFlag
    From   Customers.dbo.Account A with (nolock)
    inner join
           Customers.dbo.Company C with (nolock)
    on     A.CompanyIDSeq     =   C.IDSeq
    and    A.CompanyIDSeq     = @IPVC_CompanyID
    and    C.IDSeq            = @IPVC_CompanyID
    and    A.AccountTypeCode  = 'AHOFF'
    and    A.PropertyIDSeq    is null    
    left outer join
           Customers.dbo.Address ADR with (nolock)
    on     A.CompanyIDSeq      = ADR.CompanyIDSeq
    and    C.IDSeq             = ADR.CompanyIDSeq
    and    A.CompanyIDSeq     = @IPVC_CompanyID
    and    C.IDSeq            = @IPVC_CompanyID
    and    ADR.CompanyIDSeq   = @IPVC_CompanyID
    and    ADR.AddressTypeCode = 'CBT'
    and    A.PropertyIDSeq    is null
    and    ADR.PropertyIDSeq  is null  
    --------------------------------------------------------------------------------
    ---Gather Records into @LT_FinalResultsToEpicor For Property Based Accounts with same SameAsPMCAddressFlag = 1 
    --- for passed companyid
    insert into @LT_FinalResultsToEpicor(CompanyIDSeq,PropertyIDSeq,AccountIDSeq,AccountTypeCode,AccountName,ActiveFlag,SiteMasterID,EpicorCustomerCode,
                BillToAccountName,
                BillToAddressLine1,BillToAddressLine2,BillToCity,BillToState,BillToZipcode,BillToCountry,BillToCountryCode,
                BillToAttnName,BillToAttnPhoneVoice1,BillToAttnPhoneVoiceExt1,BillToPhoneFax,BillToPhoneVoice1,BillToPhoneVoiceExt1,BillToPhoneVoice2,BillToPhoneVoiceExt2,AddressURL,
				CurrencyCode,VendorFlag)
    Select distinct
            A.companyIDSeq              as companyIDSeq,
            A.PropertyIDSeq             as propertyIDSeq,
            A.IDSeq                     as AccountIDSeq,
            A.AccountTypeCode           as AccountTypeCode,
            P.Name                      as AccountName,
            A.ActiveFlag                as ActiveFlag,
            P.SiteMasterID              as SiteMasterID,
            A.EpicorCustomerCode        as EpicorCustomerCode,
            (case when ADR.SameAsPMCAddressFlag = 1
                       then C.Name
                     else P.Name 
                end
            )                           as BillToAccountName,
            ADR.AddressLine1            as BillToAddressLine1,
            ADR.AddressLine2            as BillToAddressLine2,
            ADR.City                    as BillToCity,
            ADR.State                   as BillToState,
            ADR.Zip                     as BillToZipcode,
            ADR.Country                 as BillToCountry,
            ADR.CountryCode             as BillToCountryCode,
             case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.AttentionName
                  when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                     then isnull((select rtrim(ltrim(AttentionName))
                           from Customers.dbo.Address with (nolock) 
                           where companyIDSeq = @IPVC_CompanyID
                             and (PropertyIDSeq is null or PropertyIDSeq = '')
                             and AddressTypeCode = 'CBT'),'')
                  else '' 
              end                        as BillToAttnName,
             case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.PhoneVoice2
                  when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                     then isnull((select rtrim(ltrim(PhoneVoice2))
                           from Customers.dbo.Address ADR with (nolock) 
                           where ADR.companyIDSeq = @IPVC_CompanyID
                             and (PropertyIDSeq is null or PropertyIDSeq = '')
                             and ADR.AddressTypeCode = 'CBT'),'')
                  else '' 
              end                        as BillToAttnPhoneVoice1,
             case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.PhoneVoiceExt2
                  when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                     then isnull((select rtrim(ltrim(PhoneVoiceExt2))
                           from Customers.dbo.Address ADR with (nolock) 
                           where ADR.companyIDSeq = @IPVC_CompanyID
                             and (PropertyIDSeq is null or PropertyIDSeq = '')
                             and ADR.AddressTypeCode = 'CBT'),'')
                  else '' 
              end                       as BillToAttnPhoneVoiceExt1, 
            ADR.PhoneFax                as BillToPhoneFax, 
            ADR.PhoneVoice1             as BillToPhoneVoice1, 
            ADR.PhoneVoiceExt1          as BillToPhoneVoiceExt1,
            ADR.PhoneVoice2             as BillToPhoneVoice2,
            ADR.PhoneVoiceExt2          as BillToPhoneVoiceExt2,
            ADR.URL                     as AddressURL,
			case when ADR.CountryCode = 'CAN' then 'CAD'
				  else 'USD'
			 end					    as CurrencyCode,
			 P.VendorFlag               as VendorFlag
    From   Customers.dbo.Account A with (nolock)
    inner join
           Customers.dbo.Property P with (nolock)
    on    A.CompanyIDSeq      = P.PMCIdSeq
    and   A.PropertyIDSeq     = P.IDSeq
    and   A.CompanyIDSeq      = @IPVC_CompanyID    
    and   A.AccountTypeCode   = 'APROP'  
    and   A.PropertyIDSeq    is not null    
    inner join
          Customers.dbo.Company C with (nolock)
    on     A.CompanyIDSeq     = C.IDSeq
    and    A.CompanyIDSeq     = @IPVC_CompanyID
    and    C.IDSeq            = @IPVC_CompanyID
    and    A.AccountTypeCode  = 'APROP'
    and    A.PropertyIDSeq    is not null
    inner join
           Customers.dbo.Address ADR with (nolock)
    on     A.CompanyIDSeq      = ADR.CompanyIDSeq
    and    A.PropertyIDSeq     = ADR.PropertyIDSeq
    and    ADR.CompanyIDSeq    = @IPVC_CompanyID
    and    ADR.SameAsPMCAddressFlag = 1
    and    ADR.AddressTypeCode = 'PBT'
    and    ADR.PropertyIDSeq    is not null        
  END 
  --------------------------------------------------------------------------------  
  ELSE IF (@IPVC_CompanyID is not null) and (@IPVC_PropertyID <> '' and @IPVC_PropertyID IS NOT NULL)
  BEGIN
    ---Gather Records into @LT_FinalResultsToEpicor For Property Based Account
    insert into @LT_FinalResultsToEpicor(CompanyIDSeq,PropertyIDSeq,AccountIDSeq,AccountTypeCode,AccountName,ActiveFlag,SiteMasterID,EpicorCustomerCode,
                BillToAccountName,
                BillToAddressLine1,BillToAddressLine2,BillToCity,BillToState,BillToZipcode,BillToCountry,BillToCountryCode,
                BillToAttnName,BillToAttnPhoneVoice1,BillToAttnPhoneVoiceExt1,BillToPhoneFax,BillToPhoneVoice1,BillToPhoneVoiceExt1,BillToPhoneVoice2,BillToPhoneVoiceExt2,AddressURL,
				CurrencyCode,VendorFlag)
    Select distinct
            A.companyIDSeq              as companyIDSeq,
            A.PropertyIDSeq             as propertyIDSeq,
            A.IDSeq                     as AccountIDSeq,
            A.AccountTypeCode           as AccountTypeCode,
            P.Name                      as AccountName,
            A.ActiveFlag                as ActiveFlag,
            P.SiteMasterID              as SiteMasterID,
            A.EpicorCustomerCode        as EpicorCustomerCode,
            (case when ADR.SameAsPMCAddressFlag = 1
                       then C.Name
                     else P.Name 
                end
            )                           as BillToAccountName,
            ADR.AddressLine1            as BillToAddressLine1,
            ADR.AddressLine2            as BillToAddressLine2,
            ADR.City                    as BillToCity,
            ADR.State                   as BillToState,
            ADR.Zip                     as BillToZipcode,
            ADR.Country                 as BillToCountry,
            ADR.CountryCode             as BillToCountryCode,
             case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.AttentionName
                  when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                     then isnull((select rtrim(ltrim(AttentionName))
                           from Customers.dbo.Address with (nolock) 
                           where companyIDSeq = @IPVC_CompanyID
                             and (PropertyIDSeq is null or PropertyIDSeq = '')
                             and AddressTypeCode = 'CBT'),'')
                  else '' 
              end                        as BillToAttnName,
             case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.PhoneVoice2
                  when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                     then isnull((select rtrim(ltrim(PhoneVoice2))
                           from Customers.dbo.Address ADR with (nolock) 
                           where ADR.companyIDSeq = @IPVC_CompanyID
                             and (PropertyIDSeq is null or PropertyIDSeq = '')
                             and ADR.AddressTypeCode = 'CBT'),'')
                  else '' 
              end                        as BillToAttnPhoneVoice1,
             case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.PhoneVoiceExt2
                  when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                     then isnull((select rtrim(ltrim(PhoneVoiceExt2))
                           from Customers.dbo.Address ADR with (nolock) 
                           where ADR.companyIDSeq = @IPVC_CompanyID
                             and (PropertyIDSeq is null or PropertyIDSeq = '')
                             and ADR.AddressTypeCode = 'CBT'),'')
                  else '' 
              end                       as BillToAttnPhoneVoiceExt1, 
            ADR.PhoneFax                as BillToPhoneFax, 
            ADR.PhoneVoice1             as BillToPhoneVoice1, 
            ADR.PhoneVoiceExt1          as BillToPhoneVoiceExt1,
            ADR.PhoneVoice2             as BillToPhoneVoice2,
            ADR.PhoneVoiceExt2          as BillToPhoneVoiceExt2,
            ADR.URL                     as AddressURL,
			case when ADR.CountryCode = 'CAN' then 'CAD'
				  else 'USD'
			 end					    as CurrencyCode,
			 P.VendorFlag               as VendorFlag 
      From   Customers.dbo.Account A with (nolock)
      inner join
             Customers.dbo.Property P with (nolock)
      on    A.CompanyIDSeq      = P.PMCIdSeq
      and   A.PropertyIDSeq     = P.IDSeq
      and   A.CompanyIDSeq      = @IPVC_CompanyID
      and   A.PropertyIDSeq     = @IPVC_PropertyID 
      and   A.AccountTypeCode   = 'APROP'  
      and   A.PropertyIDSeq    is not null
      inner join
             Customers.dbo.Company C with (nolock)
      on     A.CompanyIDSeq     = C.IDSeq
      and    A.CompanyIDSeq     = @IPVC_CompanyID
      and    C.IDSeq            = @IPVC_CompanyID
      and    A.AccountTypeCode  = 'APROP'
      and    A.PropertyIDSeq    is not null
      left outer join
             Customers.dbo.Address ADR with (nolock)
      on     A.CompanyIDSeq      = ADR.CompanyIDSeq
      and    A.PropertyIDSeq     = ADR.PropertyIDSeq
      and    ADR.CompanyIDSeq    = @IPVC_CompanyID
      and    ADR.PropertyIDSeq   = @IPVC_PropertyID
      and    ADR.AddressTypeCode = 'PBT'
      and    ADR.PropertyIDSeq    is not null        
  END
  ---------------------------------------------------------------------------------------------
  ---Final Select 
  ---------------------------------------------------------------------------------------------
  select distinct 
         CompanyIDSeq                    as CompanyIDSeq,
         coalesce(PropertyIDSeq,'')      as PropertyIDSeq,
         AccountIDSeq                    as AccountIDSeq,
         AccountTypeCode                 as AccountTypeCode,
         coalesce(AccountName,'')        as AccountName,
         ActiveFlag                      as ActiveFlag,
         coalesce(SiteMasterID,'')       as SiteMasterID,
         coalesce(EpicorCustomerCode,'') as EpicorCustomerCode,
         coalesce(BillToAccountName,'')  as BillToAccountName,
         coalesce(BillToAddressLine1,'') as BillToAddressLine1,
         coalesce(BillToAddressLine2,'') as BillToAddressLine2,
         coalesce(BillToCity,'')         as BillToCity,
         coalesce(BillToState,'')        as BillToState,
         coalesce(BillToZipcode,'')      as BillToZipcode,
         coalesce(BillToCountry,'')      as BillToCountry,
         coalesce(BillToCountryCode,'')  as BillToCountryCode,
         coalesce(BillToAttnName,'')     as BillToAttnName,
         coalesce(BillToAttnPhoneVoice1,'')    as BillToAttnPhoneVoice1,
         coalesce(BillToAttnPhoneVoiceExt1,'') as BillToAttnPhoneVoiceExt1,
         coalesce(BillToPhoneFax,'')           as BillToPhoneFax,
         coalesce(BillToPhoneVoice1,'')        as BillToPhoneVoice1,
         coalesce(BillToPhoneVoiceExt1,'')     as BillToPhoneVoiceExt1,
         coalesce(BillToPhoneVoice2,'')        as BillToPhoneVoice2,
         coalesce(BillToPhoneVoiceExt2,'')     as BillToPhoneVoiceExt2,
         coalesce(AddressURL,'')               as AddressURL,
		 CurrencyCode					as CurrencyCode,
		 VendorFlag						as VendorFlag
  from   @LT_FinalResultsToEpicor
  order by AccountTypeCode asc
 ---------------------------------------------------------------------------------------------
END
GO
