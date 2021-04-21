SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_CreateAccountsForCompanyProperty]
-- Description     : This procedure creates Accounts For a given Company and Property.
-- Input Parameters: 1. @IPVC_CompanyID   as varchar(50)
--                   
-- OUTPUT          : Account info Results for Epicor Push
--                   
-- Code Example    : exec [uspCUSTOMERS_CreateAccountsForCompanyProperty] @IPVC_CompanyID = '', @IPVC_PropertyID = '', @IPBI_UserIDSeq = 0
-- 
-- 
-- Revision History:
-- Author          : Satya B
-- 08/30/2011      : Stored Procedure Created.
--				   : --1013 - Need to create Account ID's for OMS Customers where they do not exist when creating the enabler records
-- 09/04/2011      : Mahaboob Defect #1244 -- VendorFlag incorporated in the Final Select List
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CreateAccountsForCompanyProperty] (@IPVC_CompanyID    varchar(50),
																    @IPVC_PropertyID    varchar(50),
                                                                    @IPBI_UserIDSeq    bigint --> This is UserID of person logged on (Mandatory)                                      
                                                                    )
AS
BEGIN
  -------------------------------------------------------------------------------------------------
  --Declaring Local Variables
  DECLARE	@LVC_AccountIDGen           numeric(10,0), 
			@LVC_CompanyAccountID       varchar(50),
			@LVC_PropertyAccountID      varchar(50)   
  SELECT @LVC_AccountIDGen = 0, @LVC_CompanyAccountID = '', @LVC_PropertyAccountID = ''
  -------------------------------------------------------------------------------------------------
  --Declaring Local Temporary Tables 
  DECLARE @LT_FinalResultsToEpicor TABLE (CompanyIDSeq             varchar(50),
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
  -------------------------------------------------------------------------------------------------
    if exists (select top 1 1 
             from  CUSTOMERS.dbo.Account (nolock) 
             where CompanyIDSeq=@IPVC_CompanyID
             and   PropertyIDSeq is null
             and   ActiveFlag = 1)
    begin
      select Top 1 @LVC_CompanyAccountID = IDSeq 
      from  CUSTOMERS.dbo.Account (nolock) 
      where CompanyIDSeq=@IPVC_CompanyID
      and   PropertyIDSeq is null
      and   ActiveFlag = 1
    end
    else
    begin
      begin TRY
        BEGIN TRANSACTION;
        ----------------------------------------
        --- New Account : Insert (For Company)
        ----------------------------------------
        update CUSTOMERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
        set    IDSeq = IDSeq+1,
               GeneratedDate =CURRENT_TIMESTAMP
        where  TypeIndicator = 'A'

        select @LVC_CompanyAccountID = IDGeneratorSeq
        from   CUSTOMERS.DBO.IDGenerator with (NOLOCK)  
        where  TypeIndicator = 'A' 
        
        Insert into CUSTOMERS.DBO.Account(IDSeq,AccountTypeCode,CompanyIDSeq,PropertyIDSeq,Startdate,ActiveFlag,CreatedByIDSeq)
        select @LVC_CompanyAccountID,'AHOFF',@IPVC_CompanyID,NULL as PropertyIDSeq,getdate() as startdate,1,@IPBI_UserIDSeq as CreatedByIDSeq
               
        COMMIT TRANSACTION;
      end TRY
      begin CATCH
        --select 'GroupType=PMC: New Account Generation failed' as ErrorSection,XACT_STATE() as TransactionState,ERROR_MESSAGE() AS ErrorMessage; 
        -- XACT_STATE:
           -- If 1, the transaction is committable.
           -- If -1, the transaction is uncommittable and should be rolled back.
           -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
        if (XACT_STATE()) = -1
        begin
          IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        end
        else if (XACT_STATE()) = 1
        begin
          IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
        end 
		exec CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'GroupType=PMC: New Account Generation failed'
		RETURN                 
      end CATCH
    end
    ---------------------------------------------------------------------------------------------------
    ---Gather Records into @LT_FinalResultsToEpicor For Company Based Account
    insert into @LT_FinalResultsToEpicor (CompanyIDSeq,PropertyIDSeq,AccountIDSeq,AccountTypeCode,AccountName,ActiveFlag,SiteMasterID,EpicorCustomerCode,BillToAccountName,BillToAddressLine1,BillToAddressLine2,BillToCity,BillToState,BillToZipcode,BillToCountry,BillToCountryCode,BillToAttnName,BillToAttnPhoneVoice1,BillToAttnPhoneVoiceExt1,BillToPhoneFax,BillToPhoneVoice1,BillToPhoneVoiceExt1,BillToPhoneVoice2,BillToPhoneVoiceExt2,AddressURL,CurrencyCode,VendorFlag)
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
		   end					       as CurrencyCode,
		   C.VendorFlag				   as VendorFlag
    From   Customers.dbo.Account A with (nolock)
    inner join
           Customers.dbo.Company C with (nolock)
    on     A.CompanyIDSeq     =   C.IDSeq
    and    A.IDSeq            = @LVC_CompanyAccountID
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
--    if @LVC_GroupType <> 'PMC'
--    begin
--      declare cursor_groupproperties scroll cursor for
--      select distinct GP.PropertyIDSeq,GP.PriceTypeCode,GP.ThresholdOverrideFlag
--      from   QUOTES.dbo.[GroupProperties] GP (nolock)
--      where  GP.QuoteIDSeq    = @IPVC_QuoteID
--      and    GP.GroupIDSeq    = @LI_GroupID
--      and    GP.CustomerIDSeq = @LVC_CompanyIDSeq
--      open cursor_groupproperties
--      fetch cursor_groupproperties into @LVC_PropertyIDSeq,@LVC_PriceTypeCode,@LI_ThresholdOverrideFlag
--      while @@fetch_status = 0
--      begin    
        if exists (select top 1 1 
                 from  CUSTOMERS.dbo.Account (nolock) 
                 where CompanyIDSeq=@IPVC_CompanyID
                 and   PropertyIDSeq= @IPVC_PropertyID
                 and   ActiveFlag = 1
                )
        begin
          select Top 1 @LVC_PropertyAccountID = IDSeq 
          from  CUSTOMERS.dbo.Account (nolock) 
          where CompanyIDSeq=@IPVC_CompanyID
          and   PropertyIDSeq=@IPVC_PropertyID
          and   ActiveFlag = 1
        end
        else
        begin
          BEGIN TRANSACTION;
          -----------------------------------------
          --- New Account : Insert (For Property)
          -----------------------------------------
          update CUSTOMERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
          set    IDSeq = IDSeq+1,
                 GeneratedDate =CURRENT_TIMESTAMP
          where  TypeIndicator = 'A'

          select @LVC_PropertyAccountID = IDGeneratorSeq
          from   CUSTOMERS.DBO.IDGenerator with (NOLOCK)  
          where  TypeIndicator = 'A'         

          Insert into CUSTOMERS.DBO.Account(IDSeq,AccountTypeCode,CompanyIDSeq,PropertyIDSeq,Startdate,ActiveFlag,CreatedByIDSeq)
          select @LVC_PropertyAccountID,'APROP',@IPVC_CompanyID,@IPVC_PropertyID,Getdate() as Startdate,1,@IPBI_UserIDSeq as CreatedByIDSeq
          COMMIT TRANSACTION;        
        end 
        ---------------------------------------------------------------------------------------------------
        ---Gather Records into @LT_FinalResultsToEpicor For Property Based Account
        insert into @LT_FinalResultsToEpicor(CompanyIDSeq,PropertyIDSeq,AccountIDSeq,AccountTypeCode,AccountName,ActiveFlag,SiteMasterID,EpicorCustomerCode,BillToAccountName,BillToAddressLine1,BillToAddressLine2,BillToCity,BillToState,BillToZipcode,BillToCountry,BillToCountryCode,BillToAttnName,BillToAttnPhoneVoice1,BillToAttnPhoneVoiceExt1,BillToPhoneFax,BillToPhoneVoice1,BillToPhoneVoiceExt1,BillToPhoneVoice2,BillToPhoneVoiceExt2,AddressURL,CurrencyCode,VendorFlag)
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
              end                          as BillToAttnName,
              case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.PhoneVoice2
                   when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                        then isnull((select rtrim(ltrim(PhoneVoice2))
                                     from Customers.dbo.Address with (nolock) 
                                     where companyIDSeq = @IPVC_CompanyID
                                      and (PropertyIDSeq is null or PropertyIDSeq = '')
                                      and AddressTypeCode = 'CBT'),'')
                  else '' 
              end                          as BillToAttnPhoneVoice1,
              case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.PhoneVoiceExt2
                   when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                        then isnull((select rtrim(ltrim(PhoneVoiceExt2))
                                     from Customers.dbo.Address with (nolock) 
                                     where companyIDSeq = @IPVC_CompanyID
                                      and (PropertyIDSeq is null or PropertyIDSeq = '')
                                      and AddressTypeCode = 'CBT'),'')
                  else '' 
              end                          as BillToAttnPhoneVoiceExt1, 
               ADR.PhoneFax                as BillToPhoneFax, 
               ADR.PhoneVoice1             as BillToPhoneVoice1, 
               ADR.PhoneVoiceExt1          as BillToPhoneVoiceExt1,
               ADR.PhoneVoice2             as BillToPhoneVoice2,
               ADR.PhoneVoiceExt2          as BillToPhoneVoiceExt2,
               ADR.URL                     as AddressURL,
			   case when ADR.CountryCode = 'CAN' then 'CAD'
				  else 'USD'
		       end					       as CurrencyCode,
			   P.VendorFlag                as VendorFlag
        From   Customers.dbo.Account A with (nolock)
        inner join
               Customers.dbo.Property P with (nolock)
        on    A.CompanyIDSeq      = P.PMCIdSeq
        and   A.PropertyIDSeq     = P.IDSeq
        and   A.IDSeq             = @LVC_PropertyAccountID
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
  ---------------------------------------------------------------------------------------------------       
  ---Final Select 
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
		 coalesce(CurrencyCode,'')             as CurrencyCode,
		 coalesce(VendorFlag,'')			   as VendorFlag
  from   @LT_FinalResultsToEpicor
  order by AccountTypeCode asc
 ---------------------------------------------------------------------------------------------
END -- :Main End
GO
