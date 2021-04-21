SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec uspQUOTES_CreateAccountsForQuoteToOrders @IPVC_QuoteID = 'Q0901000014',@IPBI_UserIDSeq = 123

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_CreateAccountsForQuoteToOrders
-- Description     : This procedure creates Orders For a given approved quote.
-- Input Parameters: 1. @IPVC_QuoteID   as varchar(20)
--                   
-- OUTPUT          : Account info Results for Epicor Push
--  
--                   
-- Code Example    : exec QUOTES.dbo.uspQUOTES_CreateAccountsForQuoteToOrders @IPVC_QuoteID = 3
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 12/11/2006      : Stored Procedure Created.
-- 01/28/2008      : Added bill to country code 
-- 06/11/2010      : Shashi Bhushan  Defect #7656 Altered procedure to send attn name and phone from address table instead of Contact table to Epicor.
-- 05/09/2011	   : Surya Kondapalli Task#388 - Epicor Integration for Domin-8 transactions to be pushed to Canadian DB
-- 09/04/2011      : Mahaboob Defect #1244 -- VendorFlag incorporated in the Final Select List
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_CreateAccountsForQuoteToOrders]  (@IPVC_QuoteID    varchar(50),
                                                                @IPBI_UserIDSeq  bigint --> This is UserID of person logged on (Mandatory)                                      
                                                               )
AS
BEGIN
  set nocount on 
  -------------------------------------------------------------------------------------------------
  --Declaring Local Variables
  declare @LVC_GroupType              varchar(50)
  declare @LI_GroupID                 int
  declare @LVC_CompanyIDSeq           varchar(50)    
  declare @LVC_AccountIDGen           numeric(10,0)
  declare @LVC_CompanyAccountID       varchar(50)
  declare @LVC_PropertyAccountID      varchar(50)   
  declare @LI_OrderID                 bigint
  declare @LI_OrderGroupID            bigint
  declare @LVC_PropertyIDSeq          varchar(50)  
  declare @LVC_PriceTypeCode          varchar(50)
  declare @LI_ThresholdOverrideFlag   int      
  -------------------------------------------------------------------------------------------------
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
                                          CurrencyCode             varchar(3),
                                          VendorFlag               bit 	                                          
                                         ) 
  -------------------------------------------------------------------------------------------------
  declare cursor_group scroll cursor for 
  select distinct G.grouptype,G.IDSeq  as groupid,G.CustomerIDSeq as CompanyIDSeq
  from   Quotes.dbo.[Group] G (nolock)
  where  G.QuoteIDSeq =  @IPVC_QuoteID
  open cursor_group
  fetch cursor_group into @LVC_GroupType,@LI_GroupID,@LVC_CompanyIDSeq
  while @@fetch_status = 0
  begin
    --------------------------------------------------------------------------------
    if exists (select top 1 1 
                 from  CUSTOMERS.dbo.Account A with (nolock) 
                 where A.CompanyIDSeq   =  @LVC_CompanyIDSeq
                 and   A.AccountTypeCode= 'AHOFF'
                 and   A.PropertyIDSeq is null
                 and   A.ActiveFlag     = 1
                )
    begin
      select Top 1 @LVC_CompanyAccountID = A.IDSeq 
      from   CUSTOMERS.dbo.Account A with (nolock) 
      where  A.CompanyIDSeq   =  @LVC_CompanyIDSeq
      and    A.AccountTypeCode= 'AHOFF'
      and    A.PropertyIDSeq is null
      and    A.ActiveFlag = 1
    end
    else if exists (select top 1 1 
                    from  CUSTOMERS.dbo.Account A with (nolock) 
                    where A.CompanyIDSeq  = @LVC_CompanyIDSeq
                    and   A.PropertyIDSeq is null
                    and   A.ActiveFlag    = 0
                   )
    begin
      ;with CTE_CompAccount (CompanyIDSeq,startdate)
       as (select A.CompanyIDSeq     as CompanyIDSeq
                 ,Max(startdate)     as startdate
           from   CUSTOMERS.dbo.Account A with (nolock) 
           where  A.CompanyIDSeq   = @LVC_CompanyIDSeq
           and    A.AccountTypeCode= 'AHOFF'
           and    A.PropertyIDSeq is null
           and    A.ActiveFlag     = 0
           group by A.CompanyIDSeq
          )
       ,CTE_MaxCompAccount (CompanyIDSeq,AccountIDSeq)
        as (select X.CompanyIDSeq  as CompanyIDSeq
                  ,Max(X.IDSeq)    as AccountIDSeq
            from   CUSTOMERS.dbo.Account X with (nolock) 
            inner join
                   CTE_CompAccount  CTE_CompAccount
            on     X.CompanyIDSeq   = CTE_CompAccount.CompanyIDSeq
            and    X.CompanyIDSeq   = @LVC_CompanyIDSeq
            and    X.AccountTypeCode= 'AHOFF'
            and    X.PropertyIDSeq is null
            and    X.ActiveFlag     = 0
            and    X.startdate      = CTE_CompAccount.startdate
            group by X.CompanyIDSeq
           )
       Update A
       set    A.ActiveFlag      = 1
             ,A.ModifiedDate    = getdate()
             ,A.ModifiedByIDSeq = @IPBI_UserIDSeq
             ,A.SystemLogDate   = getdate()
       from  Customers.dbo.Account A with (nolock)
       inner join
             CTE_MaxCompAccount CTE_MaxCompAccount
       on     A.CompanyIDSeq   = CTE_MaxCompAccount.CompanyIDSeq
       and    A.IDSeq          = CTE_MaxCompAccount.AccountIDSeq
       and    A.CompanyIDSeq   = @LVC_CompanyIDSeq
       and    A.AccountTypeCode= 'AHOFF'
       and    A.PropertyIDSeq is null
       and    A.ActiveFlag     = 0


      select Top 1 @LVC_CompanyAccountID = A.IDSeq 
      from   CUSTOMERS.dbo.Account A with (nolock) 
      where  A.CompanyIDSeq   =  @LVC_CompanyIDSeq
      and    A.AccountTypeCode= 'AHOFF'
      and    A.PropertyIDSeq is null
      and    A.ActiveFlag = 1 
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
        select @LVC_CompanyAccountID,'AHOFF' as AccountTypeCode,@LVC_CompanyIDSeq,NULL as PropertyIDSeq,getdate() as startdate,1,@IPBI_UserIDSeq as CreatedByIDSeq
               
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
	return;                 
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
           (case when ADR.CountryCode = 'CAN'
                   then 'CAD'
		 else 'USD'            
            end)                       as CurrencyCode,
            C.VendorFlag               as VendorFlag
    From   Customers.dbo.Account A with (nolock)
    inner join
           Customers.dbo.Company C with (nolock)
    on     A.CompanyIDSeq     =   C.IDSeq
    and    A.IDSeq            = @LVC_CompanyAccountID
    and    A.CompanyIDSeq     = @LVC_CompanyIDSeq
    and    C.IDSeq            = @LVC_CompanyIDSeq
    and    A.AccountTypeCode  = 'AHOFF'
    and    A.PropertyIDSeq    is null
    left outer join
           Customers.dbo.Address ADR with (nolock)
    on     A.CompanyIDSeq      = ADR.CompanyIDSeq
    and    C.IDSeq             = ADR.CompanyIDSeq
    and    A.CompanyIDSeq     = @LVC_CompanyIDSeq
    and    C.IDSeq            = @LVC_CompanyIDSeq
    and    ADR.CompanyIDSeq   = @LVC_CompanyIDSeq
    and    ADR.AddressTypeCode = 'CBT'
    and    A.PropertyIDSeq    is null
    and    ADR.PropertyIDSeq  is null
    --------------------------------------------------------------------------------
    if @LVC_GroupType <> 'PMC'
    begin
      declare cursor_groupproperties scroll cursor for
      select distinct GP.PropertyIDSeq,GP.PriceTypeCode,GP.ThresholdOverrideFlag
      from   QUOTES.dbo.[GroupProperties] GP (nolock)
      where  GP.QuoteIDSeq    = @IPVC_QuoteID
      and    GP.GroupIDSeq    = @LI_GroupID
      and    GP.CustomerIDSeq = @LVC_CompanyIDSeq
      open cursor_groupproperties
      fetch cursor_groupproperties into @LVC_PropertyIDSeq,@LVC_PriceTypeCode,@LI_ThresholdOverrideFlag
      while @@fetch_status = 0
      begin 
        if exists (select top 1 1 
                   from  CUSTOMERS.dbo.Account A (nolock) 
                   where A.CompanyIDSeq   = @LVC_CompanyIDSeq
                   and   A.PropertyIDSeq  = @LVC_PropertyIDSeq
                   and   A.AccountTypeCode= 'APROP' 
                   and   A.PropertyIDSeq is not null
                   and   A.ActiveFlag = 1
                )
        begin
          select Top 1 @LVC_PropertyAccountID = A.IDSeq 
          from   CUSTOMERS.dbo.Account A (nolock) 
          where  A.CompanyIDSeq  =@LVC_CompanyIDSeq
          and    A.PropertyIDSeq =@LVC_PropertyIDSeq
          and    A.AccountTypeCode= 'APROP'
          and    A.PropertyIDSeq is not null 
          and    A.ActiveFlag = 1
        end
        else if exists (select top 1 1 
                        from  CUSTOMERS.dbo.Account A (nolock) 
                        where A.CompanyIDSeq   = @LVC_CompanyIDSeq
                        and   A.PropertyIDSeq  = @LVC_PropertyIDSeq
                        and   A.AccountTypeCode= 'APROP' 
                        and   A.PropertyIDSeq is not null
                        and   A.ActiveFlag     = 0                         
                       )
        begin         
          ;with CTE_PropAccount (CompanyIDSeq,PropertyIDSeq,startdate)
           as (select A.CompanyIDSeq      as CompanyIDSeq,
                      A.PropertyIDSeq     as PropertyIDSeq,
                      Max(startdate)      as startdate
               from   CUSTOMERS.dbo.Account A (nolock) 
               where  A.CompanyIDSeq   = @LVC_CompanyIDSeq
               and    A.propertyidseq  = @LVC_PropertyIDSeq
               and    A.AccountTypeCode= 'APROP'
               and    A.PropertyIDSeq is not null
               and    A.ActiveFlag     = 0
               group by A.CompanyIDSeq,A.PropertyIDSeq
              )
          ,CTE_MaxPropAccount (CompanyIDSeq,PropertyIDSeq,AccountIDSeq)
           as (select X.CompanyIDSeq      as CompanyIDSeq
                     ,X.PropertyIDSeq     as PropertyIDSeq
                     ,Max(X.IDSeq)        as AccountIDSeq
               from   CUSTOMERS.dbo.Account X (nolock) 
               inner join
                      CTE_PropAccount  CTE_PropAccount
               on     X.CompanyIDSeq   = CTE_PropAccount.CompanyIDSeq
               and    X.PropertyIDSeq  = CTE_PropAccount.PropertyIDSeq
               and    X.CompanyIDSeq   = @LVC_CompanyIDSeq
               and    X.propertyidseq  = @LVC_PropertyIDSeq
               and    X.AccountTypeCode= 'APROP'
               and    X.PropertyIDSeq is not null
               and    X.ActiveFlag     = 0
               and    X.startdate      = CTE_PropAccount.startdate
               GROUP BY X.CompanyIDSeq,X.PropertyIDSeq
              )
          Update A
          set    A.ActiveFlag      = 1
                ,A.ModifiedDate    = getdate()
                ,A.ModifiedByIDSeq = @IPBI_UserIDSeq
                ,A.SystemLogDate   = getdate()      
          from  Customers.dbo.Account A with (nolock)
          inner join
                CTE_MaxPropAccount CTE_MaxPropAccount
          on     A.CompanyIDSeq   = CTE_MaxPropAccount.CompanyIDSeq
          and    A.PropertyIDSeq  = CTE_MaxPropAccount.PropertyIDSeq
          and    A.IDSeq          = CTE_MaxPropAccount.AccountIDSeq
          and    A.CompanyIDSeq   = @LVC_CompanyIDSeq
          and    A.propertyidseq  = @LVC_PropertyIDSeq
          and    A.AccountTypeCode= 'APROP'
          and    A.PropertyIDSeq is not null
          and    A.ActiveFlag     = 0


          select Top 1 @LVC_PropertyAccountID = A.IDSeq 
          from   CUSTOMERS.dbo.Account A (nolock) 
          where  A.CompanyIDSeq  = @LVC_CompanyIDSeq
          and    A.PropertyIDSeq = @LVC_PropertyIDSeq
          and    A.AccountTypeCode= 'APROP'
          and    A.PropertyIDSeq is not null 
          and    A.ActiveFlag = 1
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
          select @LVC_PropertyAccountID,'APROP' as AccountTypeCode,@LVC_CompanyIDSeq,@LVC_PropertyIDSeq,Getdate() as Startdate,1,@IPBI_UserIDSeq as CreatedByIDSeq
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
                                     where companyIDSeq = @LVC_CompanyIDSeq
                                      and (PropertyIDSeq is null or PropertyIDSeq = '')
                                      and AddressTypeCode = 'CBT'),'')
                  else '' 
              end                          as BillToAttnName,
              case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.PhoneVoice2
                   when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                        then isnull((select rtrim(ltrim(PhoneVoice2))
                                     from Customers.dbo.Address with (nolock) 
                                     where companyIDSeq = @LVC_CompanyIDSeq
                                      and (PropertyIDSeq is null or PropertyIDSeq = '')
                                      and AddressTypeCode = 'CBT'),'')
                  else '' 
              end                          as BillToAttnPhoneVoice1,
              case when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 0 then ADR.PhoneVoiceExt2
                   when ADR.AddressTypeCode = 'PBT' and ADR.SameAsPMCAddressFlag = 1 
                        then isnull((select rtrim(ltrim(PhoneVoiceExt2))
                                     from Customers.dbo.Address with (nolock) 
                                     where companyIDSeq = @LVC_CompanyIDSeq
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
              (case when ADR.CountryCode = 'CAN'
                      then 'CAD'
		    else 'USD'            
               end)                       as CurrencyCode,
              0                           as VendorFlag  ----> Property Does not have a  Vendor concept. It applies only to Company.
        From   Customers.dbo.Account A with (nolock)
        inner join
               Customers.dbo.Property P with (nolock)
        on    A.CompanyIDSeq      = P.PMCIdSeq
        and   A.PropertyIDSeq     = P.IDSeq
        and   A.IDSeq             = @LVC_PropertyAccountID
        and   A.CompanyIDSeq      = @LVC_CompanyIDSeq
        and   A.PropertyIDSeq     = @LVC_PropertyIDSeq 
        and   A.AccountTypeCode   = 'APROP'  
        and   A.PropertyIDSeq    is not null
        inner join
               Customers.dbo.Company C with (nolock)
        on     A.CompanyIDSeq     = C.IDSeq
        and    A.CompanyIDSeq     = @LVC_CompanyIDSeq
        and    C.IDSeq            = @LVC_CompanyIDSeq
        and    A.AccountTypeCode  = 'APROP'
        and    A.PropertyIDSeq    is not null
        left outer join
               Customers.dbo.Address ADR with (nolock)
        on     A.CompanyIDSeq      = ADR.CompanyIDSeq
        and    A.PropertyIDSeq     = ADR.PropertyIDSeq
        and    ADR.CompanyIDSeq    = @LVC_CompanyIDSeq
        and    ADR.PropertyIDSeq   = @LVC_PropertyIDSeq
        and    ADR.AddressTypeCode = 'PBT'
        and    ADR.PropertyIDSeq    is not null
        ---------------------------------------------------------------------------------------------------       
        fetch next from cursor_groupproperties into @LVC_PropertyIDSeq,@LVC_PriceTypeCode,@LI_ThresholdOverrideFlag
      end
      close cursor_groupproperties
      deallocate cursor_groupproperties
    end
    -------------------------------------------------------------------------------- 
    fetch next from cursor_group into @LVC_GroupType,@LI_GroupID,@LVC_CompanyIDSeq
  end
  close cursor_group
  deallocate cursor_group
  --------------------------------------------------------------------------------------------  
  ---Final Select 
  select distinct 
         @IPVC_QuoteID                   as QuoteIDSeq,
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
         coalesce(VendorFlag,'0')              as VendorFlag
  from   @LT_FinalResultsToEpicor
  order by AccountTypeCode asc
 ---------------------------------------------------------------------------------------------
END -- :Main End
GO
