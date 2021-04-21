SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_PreValidateExceptionRuleDetail]
-- Description     : This is the Main SP called Setting Exception Rule Header and Detail
-- Input Parameters: As indicated below.
-- Syntax          : 
/*
--New Rule
Exec CUSTOMERS.dbo.uspCUSTOMERS_PreValidateExceptionRuleDetail @IPVC_CompanyIDSeq='C0901000005',
                                                          @IPBI_RuleIDSeq=0,
                                                          @IPVC_RuleDescription = 'Sample Description',
                                                          @IPVC_RuleType='None',
                                                          @IPVC_BillToAddressTypeCode = 'DFT',
                                                          @IPVC_DeliveryOptionCode = 'EMAIL',
                                                          @IPXML_ItemCodeList = '<root><row listcode="" /></root>',
                                                          @IPXML_ApplyToOMSIDList = '<root><row applytoomsid="" /></root>',
                                                          @IPBI_UserIDSeq = 127
--Existing Rule
Exec CUSTOMERS.dbo.uspCUSTOMERS_PreValidateExceptionRuleDetail @IPVC_CompanyIDSeq='C0901000005',
                                                          @IPBI_RuleIDSeq=1,
                                                          @IPVC_RuleDescription = 'Sample Description',
                                                          @IPVC_RuleType='None',
                                                          @IPVC_BillToAddressTypeCode = 'DFT',
                                                          @IPVC_DeliveryOptionCode = 'EMAIL',
                                                          @IPXML_ItemCodeList = '<root><row listcode="" /></root>',
                                                          @IPXML_ApplyToOMSIDList = '<root><row applytoomsid="" /></root>',
                                                          @IPBI_UserIDSeq = 127

*/
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 692) Multiple Billing Address Validation enhancement for EMAIL
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_PreValidateExceptionRuleDetail] 
                                                                (@IPVC_CompanyIDSeq            varchar(50),     --> CompanyIDSeq (Mandatory) : UI Knows this
                                                                 @IPBI_RuleIDSeq               bigint=0,        --> RuleIDSeq    (Mandatory) : 
                                                                                                                -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                                                                                -- For Brand New Rule Pass in 0 for @IPBI_RuleIDSeq.
                                                                                                                -- For Existing Rule (For Edit and Save), Pass in Specific RuleIDSeq
                                                                 @IPVC_RuleDescription         varchar(50)='',  -- RuleDescription: This is short description of Rule that User May Type
                                                                                                                -- Default is '' or Blank.
                                                                 @IPVC_RuleType                varchar(50),     --> RuleType:  Values None,Family,Category,Product,ProductType(Future)
                                                                                                                -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                                                                                -- Radio button Selection value for Rule Type in UI
                                                                 @IPI_ApplyToCustomBundleFlag  int = 0,         --> This is ApplyToCustomBundle Check box setting in UI. Default is unchecked 0
                                                                 @IPVC_BillToAddressTypeCode   varchar(3),      -->BillToAddressTypeCode (Mandatory)
                                                                                                                -- This is user selection based on drop down for Billing Address.
                                                                                                                -- if User selection is For "Default", UI will pass dummy code 'DFT'
                                                                                                                -- if user Selection is any other value, then Code will be like 'PBT' or 'CBT' or 'PB1' or 'R01' etc.
                                                                 @IPVC_DeliveryOptionCode      varchar(5),      -->DeliveryOptionCode (Mandatory)
                                                                                                                -- Based on User Selection from drop down (SMAIL, CPRTL,EMAIL etc)
                                                                 @IPXML_ItemCodeList           xml,             --> XML (First Result set based on Radio Button selection for RuleType) (Mandatory) 
                                                                                                                --  This is xml of Selected List (Family List or Category List or Product List or Productype List(future))
                                                                                                                -- If No selection, then Xml will have Atleast One Blank Row
                                                                 @IPXML_ApplyToOMSIDList       xml,             --> XML (Second Result set for ApplyToOMSIDList) (Mandatory) 
                                                                                                                --  This is xml of Selected List (Apply to OMS ID - PMC, Properties or both)
                                                                                                                -- If No selection, then Xml will have Atleast One Blank Row                                                                 
                                                                 @IPBI_UserIDSeq               bigint           --> This is UserID of person logged on (Mandatory)  
                                                                )
AS
BEGIN --> Main Begin
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  ---------------------------------------------------------------------------------------------------------------------------------------------
  declare @LVC_ErrorCodeSection     varchar(1000);
  select @IPVC_BillToAddressTypeCode = (case when @IPVC_BillToAddressTypeCode = 'DFT' then NULL
                                             else nullif(ltrim(rtrim(@IPVC_BillToAddressTypeCode)),'')
                                        end);

  create table #LT_ApplyToOMSIDListToValidate (SEQ                      int          not null identity(1,1) Primary Key,
                                               CompanyIDSeq             varchar(50)  Null,
                                               ApplyToOMSID             varchar(50)  Null
                                              ) ON [PRIMARY];
  ---------------------------------------------------------------------------------------------------------------------------------------------
  --Step 0 : Process ApplyToOMSIDList XML 
  --Process Input XML
  -----------------------------------------------------------------------------------
  declare @idoc  int
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPXML_ApplyToOMSIDList
  -----------------------------------------------------------------------------------  
  --OPENXML to read XML and Insert Data into #LT_ItemCodeList
  ----------------------------------------------------------------------------------- 
  begin TRY
    insert into #LT_ApplyToOMSIDListToValidate(CompanyIDSeq,ApplyToOMSID)
    select @IPVC_CompanyIDSeq      as CompanyIDSeq,
           A.ApplyToOMSID          as ApplyToOMSID
    from (select nullif(ltrim(rtrim(ApplyToOMSID)),'') as applytoomsid
          from  OPENXML (@idoc,'root/row',1) 
          with (applytoomsid    varchar(11)
                )
          ) A
    group by A.ApplyToOMSID
  end TRY
  begin CATCH
    select @LVC_ErrorCodeSection = 'Proc:uspCUSTOMERS_PreValidateExceptionRuleDetail - /root/row XML ReadSection; Error Parsing @IPXML_ApplyToOMSIDList'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection;
    if @idoc is not null
    begin
      EXEC sp_xml_removedocument @idoc
      set @idoc = NULL
    end
    return
  end CATCH;
  if @idoc is not null
  begin
    EXEC sp_xml_removedocument @idoc
    set @idoc = NULL
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------
  if not exists(select Top 1 1 from #LT_ApplyToOMSIDListToValidate with (nolock))
  begin
    insert into #LT_ApplyToOMSIDListToValidate(CompanyIDSeq,ApplyToOMSID)
    select @IPVC_CompanyIDSeq as CompanyIDSeq,NULL as ApplyToOMSID
  end
  ---------------------------------------------------------------------------------------------------------------------------------------------
  ---Validation : Check if Email ID is present for corresponding ApplyToOMSID from input XML and return 
  --              a resultset to show in the Error Modal Dialog with export to excel option

  ----> If this result set is empty resultset, then UI will allow SAVE for final call of Proc uspCUSTOMERS_SetExceptionRuleAndDetail
  ----> If this result set is non empty resulset, then Error Dialog modal popsup in UI showing this resultset with export to excel option
  ---     for users to correct email address using customer property modal, before coming back to set the special email delivery option rule.
  ---------------------------------------------------------------------------------------------------------------------------------------------
  ;WITH CTE_Address (CompanyIDSeq,CompanyName,CompanyStatus,PropertyIDSeq,PropertyName,PropertyStatus,AddressTypecode,AddressTypeName,BillToEMAILID,ErrorMessage)
   AS
   (select  @IPVC_CompanyIDSeq                                                as CompanyIDSeq
            ,C.Name                                                           as CompanyName
            ,C.StatusTypeCode                                                 as CompanyStatus
            ,Addr.PropertyIDSeq                                               as PropertyIDSeq
            ,P.Name                                                           as PropertyName
            ,P.StatusTypeCode                                                 as PropertyStatus
            ,Addr.AddressTypecode                                             as AddressTypecode
            ,Adt.Name                                                         as AddressTypeName
            ,coalesce(nullif(ltrim(rtrim(Addr.Email)),''),'')                 as BillToEMAILID 
            ,'DeliveryOption : EMAIL requires valid Email for this ' +
             (case when Addr.PropertyIDSeq is null then 'Company.'
                   else 'Property.'
              end)                                                            as ErrorMessage         
    from   CUSTOMERS.dbo.Address Addr with (nolock)
    inner join
           CUSTOMERS.dbo.AddressType  Adt with (nolock) 
    on     Addr.CompanyIDSeq    = @IPVC_CompanyIDSeq
    and    Addr.AddressTypecode = Adt.Code
    and    Adt.Type             = 'BILLING'
    and    Addr.AddressTypecode = coalesce(@IPVC_BillToAddressTypeCode,(case when Addr.PropertyIDSeq is not null then 'PBT' else 'CBT' end)) 
    and    (@IPVC_DeliveryOptionCode = 'EMAIL' 
               and 
            coalesce(nullif(ltrim(rtrim(Addr.Email)),''),'ABCDEF') = 'ABCDEF'
           )
    inner join
           CUSTOMERS.dbo.Company C with (nolock)
    on     Addr.CompanyIDSeq = C.IDSeq
    and    Addr.CompanyIDSeq = @IPVC_CompanyIDSeq
    and    C.IDSeq           = @IPVC_CompanyIDSeq
    left outer join
           CUSTOMERS.dbo.Property P with (nolock)
    on    Addr.PropertyIDSeq= P.IDSeq
    and   Addr.CompanyIDSeq = P.PMCIDSeq
    and   C.IDSeq           = P.PMCIDSeq
    and   Addr.CompanyIDSeq = @IPVC_CompanyIDSeq
    and   C.IDSeq           = @IPVC_CompanyIDSeq
    and   P.PMCIDSeq        = @IPVC_CompanyIDSeq
    and   P.StatusTypeCode  = 'ACTIV'
    where Addr.CompanyIDSeq = @IPVC_CompanyIDSeq
    and   C.IDSeq           = @IPVC_CompanyIDSeq
    and    (@IPVC_DeliveryOptionCode = 'EMAIL' 
               and 
            coalesce(nullif(ltrim(rtrim(Addr.Email)),''),'ABCDEF') = 'ABCDEF'
           )
   )
  select  CTE_Address.CompanyIDSeq                as CompanyIDSeq
         ,CTE_Address.CompanyName                 as CompanyName
         ,CTE_Address.PropertyIDSeq               as PropertyIDSeq
         ,CTE_Address.PropertyName                as PropertyName
         ,CTE_Address.AddressTypecode             as AddressTypecode
         ,CTE_Address.AddressTypeName             as AddressTypeName
         ,CTE_Address.BillToEMAILID               as BillToEMAILID
         ,CTE_Address.ErrorMessage                as ErrorMessage
  from CTE_Address CTE_Address with (nolock)
  inner join
         #LT_ApplyToOMSIDListToValidate Xxml with (nolock)
  on     CTE_Address.CompanyIDSeq = Xxml.CompanyIDSeq
  and    CTE_Address.CompanyIDSeq = @IPVC_CompanyIDSeq
  and    Xxml.CompanyIDSeq        = @IPVC_CompanyIDSeq
  and   (
           (
            CTE_Address.AddressTypecode like 'PB%'                                            and
            CTE_Address.CompanyIdSeq  = Xxml.CompanyIDSeq                                     and
            CTE_Address.PropertyIDSeq = coalesce(Xxml.ApplyToOMSID,CTE_Address.PropertyIDSeq) and 
            CTE_Address.PropertyIDSeq is not null                                             and
            CTE_Address.PropertyStatus = 'ACTIV'             
           )
            OR
           (
            CTE_Address.AddressTypecode NOT like 'PB%'                                        and
            CTE_Address.CompanyIdSeq  = Xxml.CompanyIdSeq                                     and
            CTE_Address.CompanyIdSeq = coalesce(Xxml.ApplyToOMSID,CTE_Address.CompanyIdSeq)   and            
            CTE_Address.PropertyIDSeq is  null 
           )
         )
  where  CTE_Address.CompanyIDSeq = @IPVC_CompanyIDSeq
  order by CTE_Address.CompanyIDSeq ASC,CTE_Address.PropertyIDSeq ASC; 
  -----------------------------------------------------------------------------------------------------------
  ---Final Cleanup
  if (object_id('tempdb.dbo.#LT_ApplyToOMSIDListToValidate') is not null) 
  begin
    drop table #LT_ApplyToOMSIDListToValidate
  end;
  -----------------------------------------------------------------------------------------------------------
END --> Main End
GO
