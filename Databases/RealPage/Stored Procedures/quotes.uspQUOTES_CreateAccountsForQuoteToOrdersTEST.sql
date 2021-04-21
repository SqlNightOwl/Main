SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--exec uspQUOTES_CreateAccountsForQuoteToOrdersTEST @IPVC_QuoteID = 'Q0000000012'

----------------------------------------------------------------------------------------------------
-- Database  Name  : QUOTES
-- Procedure Name  : uspQUOTES_CreateAccountsForQuoteToOrdersTEST
-- Description     : This procedure creates Orders For a given approved quote.
-- Input Parameters: 1. @IPVC_QuoteID   as varchar(20)
--                   
-- OUTPUT          : Account info Results for Epicor Push
--  
--                   
-- Code Example    : exec QUOTES.dbo.uspQUOTES_CreateAccountsForQuoteToOrdersTEST @IPVC_QuoteID = 3
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 12/11/2006      : Stored Procedure Created.
-- 01/28/2008      : Added bill to country code 
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [quotes].[uspQUOTES_CreateAccountsForQuoteToOrdersTEST]  (@IPVC_QuoteID  varchar(50)                                      
                                                               )
AS
BEGIN
  set nocount on 
  -------------------------------------------------------------------------------------------------
  --Declaring Local Variables
  declare @LVC_OrderStatusCode        varchar(50)
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

  select @LVC_OrderStatusCode = 'APPR'  -- Hardcoded to Approved (Temporary)
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
                                          AddressURL               varchar(255)                                          
                                         )  
  -------------------------------------------------------------------------------------------------
  --Initial Validation based on Input @IPVC_QuoteID
  /*if  not exists(select top 1 1 from Quotes.dbo.[Quote] (nolock) where QuoteIDSeq      = @IPVC_QuoteID)  
  begin 
    select 'Quote for QuoteID = ' + @IPVC_QuoteID + ' does not exist in Quote System'
    return 
  end
  else if not exists(select top 1 1 from Quotes.dbo.[Quote] (nolock) where QuoteIDSeq = @IPVC_QuoteID and QuoteStatusCode='APR')  
  begin 
    select 'Quote for QuoteID = ' + @IPVC_QuoteID + ' is not approved to turn into a Final Order'
    return 
  end
  else if not exists(select top 1 1 from Quotes.dbo.[Group] (nolock) where QuoteIDSeq = @IPVC_QuoteID)
  begin
    select 'No Bundles exist in Quote System for QuoteID = ' + @IPVC_QuoteID 
    return 
  end
  else if not exists(select top 1 1 from Quotes.dbo.[QuoteItem] (nolock) where QuoteIDSeq = @IPVC_QuoteID)
  begin
    select 'No Products exist in Quote System for QuoteID = ' + @IPVC_QuoteID 
    return 
  end*/
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
                 from  CUSTOMERS.dbo.Account (nolock) 
                 where CompanyIDSeq=@LVC_CompanyIDSeq
                 and   PropertyIDSeq is null
                 and   ActiveFlag = 1
                )
    begin
      select Top 1 @LVC_CompanyAccountID = IDSeq 
      from  CUSTOMERS.dbo.Account (nolock) 
      where CompanyIDSeq=@LVC_CompanyIDSeq
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
        
        Insert into CUSTOMERS.DBO.Account(IDSeq,AccountTypeCode,CompanyIDSeq,PropertyIDSeq,Startdate,ActiveFlag,CreatedBy
                                          )
        select @LVC_CompanyAccountID,'AHOFF',@LVC_CompanyIDSeq,NULL as PropertyIDSeq,getdate() as startdate,1,'MIS Admin'
               
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
    insert into @LT_FinalResultsToEpicor (CompanyIDSeq,PropertyIDSeq,AccountIDSeq,AccountTypeCode,AccountName,ActiveFlag,SiteMasterID,EpicorCustomerCode,BillToAccountName,BillToAddressLine1,BillToAddressLine2,BillToCity,BillToState,BillToZipcode,BillToCountry,BillToCountryCode,BillToAttnName,BillToAttnPhoneVoice1,BillToAttnPhoneVoiceExt1,BillToPhoneFax,BillToPhoneVoice1,BillToPhoneVoiceExt1,BillToPhoneVoice2,BillToPhoneVoiceExt2,AddressURL)
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
		   ADR.CountryCode			   as BillToCountryCode,	
           (select Top 1 CONT.FirstName + ',' + CONT.LastName
            from   CUSTOMERS.DBO.CONTACT CONT with (nolock)
            where  A.CompanyIDSeq     = CONT.CompanyIDSeq 
            and    A.CompanyIDSeq     = @LVC_CompanyIDSeq
            and    CONT.CompanyIDSeq  = @LVC_CompanyIDSeq
            and    CONT.PropertyIDSeq    is null
            and    CONT.ContactTypeCode = 'BIL'
           )                           as BillToAttnName,
           (select Top 1 X.PhoneVoice1
            from   CUSTOMERS.DBO.Address X        with (nolock)
            inner join CUSTOMERS.DBO.CONTACT CONT with (nolock)
            on     X.idseq        = CONT.AddressIDSeq
            and    A.CompanyIDSeq = CONT.CompanyIDSeq 
            and    A.CompanyIDSeq     = @LVC_CompanyIDSeq
            and    CONT.CompanyIDSeq  = @LVC_CompanyIDSeq
            and    CONT.PropertyIDSeq    is null
            and    CONT.ContactTypeCode = 'BIL'
           )                           as BillToAttnPhoneVoice1,
           (select Top 1 X.PhoneVoiceExt1
            from   CUSTOMERS.DBO.Address X        with (nolock)
            inner join CUSTOMERS.DBO.CONTACT CONT with (nolock)
            on     X.idseq        = CONT.AddressIDSeq
            and    A.CompanyIDSeq = CONT.CompanyIDSeq 
            and    A.CompanyIDSeq     = @LVC_CompanyIDSeq
            and    CONT.CompanyIDSeq  = @LVC_CompanyIDSeq
            and    CONT.PropertyIDSeq    is null
            and    CONT.ContactTypeCode = 'BIL'
           )                           as BillToAttnPhoneVoiceExt1,  
           ADR.PhoneFax                as BillToPhoneFax, 
           ADR.PhoneVoice1             as BillToPhoneVoice1, 
           ADR.PhoneVoiceExt1          as BillToPhoneVoiceExt1,
           ADR.PhoneVoice2             as BillToPhoneVoice2,
           ADR.PhoneVoiceExt2          as BillToPhoneVoiceExt2,
           ADR.URL                     as AddressURL
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
                 from  CUSTOMERS.dbo.Account (nolock) 
                 where CompanyIDSeq=@LVC_CompanyIDSeq
                 and   PropertyIDSeq= @LVC_PropertyIDSeq
                 and   ActiveFlag = 1
                )
        begin
          select Top 1 @LVC_PropertyAccountID = IDSeq 
          from  CUSTOMERS.dbo.Account (nolock) 
          where CompanyIDSeq=@LVC_CompanyIDSeq
          and   PropertyIDSeq=@LVC_PropertyIDSeq
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
select @LVC_PropertyAccountID
          Insert into CUSTOMERS.DBO.Account(IDSeq,AccountTypeCode,CompanyIDSeq,PropertyIDSeq,Startdate,ActiveFlag,CreatedBy)
          select @LVC_PropertyAccountID,'APROP',@LVC_CompanyIDSeq,@LVC_PropertyIDSeq,Getdate() as Startdate,1,'MIS Admin'                 
          COMMIT TRANSACTION;        
        end 
        ---------------------------------------------------------------------------------------------------
        ---Gather Records into @LT_FinalResultsToEpicor For Property Based Account
        insert into @LT_FinalResultsToEpicor(CompanyIDSeq,PropertyIDSeq,AccountIDSeq,AccountTypeCode,AccountName,ActiveFlag,SiteMasterID,EpicorCustomerCode,BillToAccountName,BillToAddressLine1,BillToAddressLine2,BillToCity,BillToState,BillToZipcode,BillToCountry,BillToCountryCode,BillToAttnName,BillToAttnPhoneVoice1,BillToAttnPhoneVoiceExt1,BillToPhoneFax,BillToPhoneVoice1,BillToPhoneVoiceExt1,BillToPhoneVoice2,BillToPhoneVoiceExt2,AddressURL)
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
               (select Top 1 CONT.FirstName + ',' + CONT.LastName
                from   CUSTOMERS.DBO.CONTACT CONT with (nolock)
                where  A.CompanyIDSeq = CONT.CompanyIDSeq 
                and    A.PropertyIDSeq= CONT.PropertyIDSeq
                and    A.CompanyIDSeq      = @LVC_CompanyIDSeq
                and    A.PropertyIDSeq     = @LVC_PropertyIDSeq 
                and    CONT.CompanyIDSeq   = @LVC_CompanyIDSeq
                and    CONT.PropertyIDSeq  = @LVC_PropertyIDSeq 
                and    CONT.PropertyIDSeq    is not null
                and    CONT.ContactTypeCode = 'BIL'
               )                           as BillToAttnName,
               (select Top 1 X.PhoneVoice1
                from   CUSTOMERS.DBO.Address X        with (nolock)
                inner join CUSTOMERS.DBO.CONTACT CONT with (nolock)
                on     X.idseq        = CONT.AddressIDSeq
                and    A.CompanyIDSeq = CONT.CompanyIDSeq 
                and    A.PropertyIDSeq= CONT.PropertyIDSeq
                and    A.CompanyIDSeq      = @LVC_CompanyIDSeq
                and    A.PropertyIDSeq     = @LVC_PropertyIDSeq 
                and    CONT.CompanyIDSeq   = @LVC_CompanyIDSeq
                and    CONT.PropertyIDSeq  = @LVC_PropertyIDSeq 
                and    CONT.PropertyIDSeq   is not null
                and    CONT.ContactTypeCode = 'BIL'
               )                           as BillToAttnPhoneVoice1,
               (select Top 1 X.PhoneVoiceExt1
                from   CUSTOMERS.DBO.Address X        with (nolock)
                inner join CUSTOMERS.DBO.CONTACT CONT with (nolock)
                on     X.idseq        = CONT.AddressIDSeq
                and    A.CompanyIDSeq = CONT.CompanyIDSeq 
                and    A.PropertyIDSeq= CONT.PropertyIDSeq
                and    A.CompanyIDSeq      = @LVC_CompanyIDSeq
                and    A.PropertyIDSeq     = @LVC_PropertyIDSeq 
                and    CONT.CompanyIDSeq   = @LVC_CompanyIDSeq
                and    CONT.PropertyIDSeq  = @LVC_PropertyIDSeq 
                and    CONT.PropertyIDSeq    is not null
                and    CONT.ContactTypeCode = 'BIL'
               )                           as BillToAttnPhoneVoiceExt1,  
               ADR.PhoneFax                as BillToPhoneFax, 
               ADR.PhoneVoice1             as BillToPhoneVoice1, 
               ADR.PhoneVoiceExt1          as BillToPhoneVoiceExt1,
               ADR.PhoneVoice2             as BillToPhoneVoice2,
               ADR.PhoneVoiceExt2          as BillToPhoneVoiceExt2,
               ADR.URL                     as AddressURL
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
         coalesce(AddressURL,'')               as AddressURL
  from   @LT_FinalResultsToEpicor
  order by AccountTypeCode asc
 ---------------------------------------------------------------------------------------------
END -- :Main End
GO
