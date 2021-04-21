SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_SetExceptionRuleAndDetail]
-- Description     : This is the Main SP called Setting Exception Rule Header and Detail
-- Input Parameters: As indicated below.
-- Syntax          : 
/*
--New Rule
Exec CUSTOMERS.dbo.uspCUSTOMERS_SetExceptionRuleAndDetail @IPVC_CompanyIDSeq='C0901000002',
                                                          @IPBI_RuleIDSeq=0,
                                                          @IPVC_RuleDescription = 'Sample Description',
                                                          @IPVC_RuleType='None',
                                                          @IPVC_BillToAddressTypeCode = 'DFT',
                                                          @IPVC_DeliveryOptionCode = 'CPRTL',
                                                          @IPXML_ItemCodeList = '<root><row listcode="" /></root>',
                                                          @IPXML_ApplyToOMSIDList = '<root><row applytoomsid="" /></root>',
                                                          @IPBI_UserIDSeq = 127,
														  @IPI_ShowSiteNameOnInvoiceFlag = 0 or 1
--Existing Rule
Exec CUSTOMERS.dbo.uspCUSTOMERS_SetExceptionRuleAndDetail @IPVC_CompanyIDSeq='C0901000002',
                                                          @IPBI_RuleIDSeq=1,
                                                          @IPVC_RuleDescription = 'Sample Description',
                                                          @IPVC_RuleType='None',
                                                          @IPVC_BillToAddressTypeCode = 'DFT',
                                                          @IPVC_DeliveryOptionCode = 'EMAIL',
                                                          @IPXML_ItemCodeList = '<root><row listcode="" /></root>',
                                                          @IPXML_ApplyToOMSIDList = '<root><row applytoomsid="" /></root>',
                                                          @IPBI_UserIDSeq = 127
                                                          @IPI_ShowSiteNameOnInvoiceFlag = 0 or 1
*/
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 7915) Multiple Billing Address enhancement
-- 07/12/2011	   : Mahaboob (Defect 627) Show SiteName on Invoice
-- 08/23/2011      : Naval Kishore Modified to comment validation for saving default as SMAIL.(627)
-- 11/04/2011      : TFS 1514 : DB Ameliorate performance by removing unneeded Transaction...
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_SetExceptionRuleAndDetail] (@IPVC_CompanyIDSeq             varchar(50),    --> CompanyIDSeq (Mandatory) : UI Knows this
                                                                 @IPBI_RuleIDSeq                bigint=0,       --> RuleIDSeq    (Mandatory) : 
                                                                                                                -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                                                                                -- For Brand New Rule Pass in 0 for @IPBI_RuleIDSeq.
                                                                                                                -- For Existing Rule (For Edit and Save), Pass in Specific RuleIDSeq
                                                                 @IPVC_RuleDescription          varchar(50)='', -- RuleDescription: This is short description of Rule that User May Type
                                                                                                                -- Default is '' or Blank.
                                                                 @IPVC_RuleType                 varchar(50),    --> RuleType:  Values None,Family,Category,Product,ProductType(Future)
                                                                                                                -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                                                                                -- Radio button Selection value for Rule Type in UI
                                                                 @IPI_ApplyToCustomBundleFlag   int = 0,        --> This is ApplyToCustomBundle Check box setting in UI. Default is unchecked 0
                                                                 @IPVC_BillToAddressTypeCode    varchar(3),     -->BillToAddressTypeCode (Mandatory)
                                                                                                                -- This is user selection based on drop down for Billing Address.
                                                                                                                -- if User selection is For "Default", UI will pass dummy code 'DFT'
                                                                                                                -- if user Selection is any other value, then Code will be like 'PBT' or 'CBT' or 'PB1' or 'R01' etc.
                                                                 @IPVC_DeliveryOptionCode       varchar(5),      -->DeliveryOptionCode (Mandatory)
                                                                                                                -- Based on User Selection from drop down (SMAIL, CPRTL,EMAIL etc)
                                                                 @IPXML_ItemCodeList            xml,            --> XML (First Result set based on Radio Button selection for RuleType) (Mandatory) 
                                                                                                                --  This is xml of Selected List (Family List or Category List or Product List or Productype List(future))
                                                                                                                -- If No selection, then Xml will have Atleast One Blank Row
                                                                 @IPXML_ApplyToOMSIDList        xml,             --> XML (Second Result set for ApplyToOMSIDList) (Mandatory) 
                                                                                                                --  This is xml of Selected List (Apply to OMS ID - PMC, Properties or both)
                                                                                                                -- If No selection, then Xml will have Atleast One Blank Row                                                                 
                                                                 @IPBI_UserIDSeq                bigint,         --> This is UserID of person logged on (Mandatory)  
																
                                                                 @IPI_ShowSiteNameOnInvoiceFlag int             --> if SiteName to be displayed on Invoice, UI will pass 1, else 0. 
                                                                )
AS
BEGIN 
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  -----------------------------------------------------------------------------------------------------------
  declare @LVC_ErrorCodeSection     varchar(1000),
          @LDT_SystemDate           datetime,
          @LBI_RuleIDSeq            bigint,
          @LBI_HistoryRevisionID    bigint,
          @LVC_SQL                  varchar(8000)

  create table #LT_ItemCodeList    (SEQ                      int not null identity(1,1) Primary Key,
                                    ListCode                 varchar(500)  Null
                                   ) ON [PRIMARY];

  create table #LT_ApplyToOMSIDList (SEQ                      int not null identity(1,1) Primary Key,
                                     ApplyToOMSIDSeq          varchar(11)  Null
                                    ) ON [PRIMARY];

  CREATE TABLE #LT_InvoiceDeliveryExceptionRuleDetail(
                                    [IDSeq]                          [bigint]       IDENTITY(1,1) NOT NULL PRIMARY KEY,
	                            [RuleIDSeq]                      [bigint]       NOT NULL,
                                    ---------------------------------------------------
                                    --Keys
                                    [RuleType]                       [varchar](50)  NOT NULL, --> Family,Category,Product,ProductType(Future)
                                    [CompanyIDSeq]                   [char](11)     NOT NULL, 
                                    [ApplyToOMSIDSeq]                [varchar](11)  NULL, --> Null means apply to all (This stores CompanyIDSeq if applyto is companyID, PropertyIDSeq if applyto is PropertyID)                                    
                                    [ApplyToFamilyCode]              [varchar](3)   NULL, --> Null means apply to all 
                                    [ApplyToCategoryCode]            [varchar](3)   NULL, --> Null means apply to all 
                                    [ApplyToProductTypeCode]         [varchar](3)   NULL, --> Null means apply to all (Future)
                                    [ApplyToProductCode]             [varchar](30)  NULL, --> Null means apply to all 
                                    [ApplyToCustomBundleFlag]        int            NOT NULL  DEFAULT (0),
                                    ---------------------------------------------------
                                    [BillToAddressTypeCode]          [varchar](3)   NULL, ---> Null means Default CBT or PBT as applicable.
                                    [DeliveryOptionCode]             [varchar](5)   NOT NULL DEFAULT ('SMAIL'),-->Default is Snail Mail
                                    [ShowSiteNameOnInvoiceFlag]      [int]          NOT NULL DEFAULT (0), 
                                    ---------------------------------------------------
                                    [RECORDCRC]                      AS (binary_checksum([CompanyIDSeq],
	                                                                                 [ApplyToOMSIDSeq],                                                                                         
	                                                                                 [ApplyToFamilyCode],
	                                                                                 [ApplyToCategoryCode],
                                                                                         [ApplyToProductTypeCode],
	                                                                                 [ApplyToProductCode], 
                                                                                         [ApplyToCustomBundleFlag],
                                                                                         [BillToAddressTypeCode],
                                                                                         [DeliveryOptionCode],
                                                                                         [ShowSiteNameOnInvoiceFlag]
                                                                                        )
                                                                         )
                                   ) ON [PRIMARY];
  -----------------------------------------------------------------------------------------------------------
  select @LDT_SystemDate                    = Getdate(),
         @IPVC_RuleDescription              = nullif(ltrim(rtrim(@IPVC_RuleDescription)),''),
         @IPVC_BillToAddressTypeCode        = (case when Coalesce(nullif(ltrim(rtrim(@IPVC_BillToAddressTypeCode)),''),'DFT') = 'DFT'
                                                       then NULL
                                                    else  nullif(ltrim(rtrim(@IPVC_BillToAddressTypeCode)),'')
                                               end)
  -----------------------------------------------------------------------------------------------------------
  --Step 0 : Process ItemCodeList XML,ApplyToOMSIDList XML and 
  --         also Populate Temp Table #LT_InvoiceDeliveryExceptionRuleDetail
  --Process Input XML
  -----------------------------------------------------------------------------------
  declare @idoc  int
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPXML_ItemCodeList
  -----------------------------------------------------------------------------------  
  --OPENXML to read XML and Insert Data into #LT_ItemCodeList
  ----------------------------------------------------------------------------------- 
  begin TRY
    insert into #LT_ItemCodeList(ListCode)
    select A.ListCode
    from (select nullif(ltrim(rtrim(ListCode)),'') as listcode
          from  OPENXML (@idoc,'root/row',1) 
          with (listcode    varchar(500)
                )
          ) A
  end TRY
  begin CATCH
    select @LVC_ErrorCodeSection = 'Proc:uspCUSTOMERS_SetExceptionRuleAndDetail - /root/row XML ReadSection; Error Parsing @IPXML_ItemCodeList'
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
  -----------------------------------------------------------------------------------
  --Create Handle to access newly created internal representation of the XML document
  -----------------------------------------------------------------------------------
  EXEC sp_xml_preparedocument @idoc OUTPUT,@IPXML_ApplyToOMSIDList
  -----------------------------------------------------------------------------------  
  --OPENXML to read XML and Insert Data into #LT_ItemCodeList
  ----------------------------------------------------------------------------------- 
  begin TRY
    insert into #LT_ApplyToOMSIDList(ApplyToOMSIDSeq)
    select A.ApplyToOMSID
    from (select nullif(ltrim(rtrim(ApplyToOMSID)),'') as applytoomsid
          from  OPENXML (@idoc,'root/row',1) 
          with (applytoomsid    varchar(11)
                )
          ) A
  end TRY
  begin CATCH
    select @LVC_ErrorCodeSection = 'Proc:uspCUSTOMERS_SetExceptionRuleAndDetail - /root/row XML ReadSection; Error Parsing @IPXML_ApplyToOMSIDList'
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
  -----------------------------------------------------------------------------------------------------------
  if not exists(select Top 1 1 from #LT_ItemCodeList with (nolock))
  begin
    insert into #LT_ItemCodeList(ListCode)
    select NULL as ListCode
  end
  if not exists(select Top 1 1 from #LT_ApplyToOMSIDList with (nolock))
  begin
    insert into #LT_ApplyToOMSIDList(ApplyToOMSID)
    select NULL as ApplyToOMSID
  end
  -----------------------------------------------------------------------------------------------------------
  --Step 1 : Header Table : InvoiceDeliveryExceptionRule
  -- If already exists, then Update existing Rule Header. Else create a brand new Rule Header
  -----------------------------------------------------------------------------------------------------------
  if exists (select Top 1 1 
             from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRule IDERH with (nolock)
             where  IDERH.CompanyIDSeq = @IPVC_CompanyIDSeq
             and    IDERH.RuleIDSeq    = @IPBI_RuleIDSeq
            )
  begin
    select @LBI_RuleIDSeq = @IPBI_RuleIDSeq;
    Exec CUSTOMERS.dbo.uspCUSTOMERS_ExceptionRuleHeaderUpdate @IPVC_CompanyIDSeq   = @IPVC_CompanyIDSeq,
                                                              @IPBI_RuleIDSeq      = @IPBI_RuleIDSeq,
                                                              @IPVC_RuleType       = @IPVC_RuleType,
                                                              @IPVC_RuleDescription= @IPVC_RuleDescription,
                                                              @IPBI_UserIDSeq      = @IPBI_UserIDSeq;
  end
  else
  begin
    BEGIN TRY
      BEGIN TRANSACTION IDERH;
        -----------------------------------------------
        select @LBI_RuleIDSeq = coalesce((select Max(IDER.RuleIDSeq)
                                          from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRule IDER with (nolock)
                                          where  IDER.CompanyIDSeq = @IPVC_CompanyIDSeq
                                          ),0)+1;

        Insert into CUSTOMERS.dbo.InvoiceDeliveryExceptionRule(RuleIDSeq,CompanyIDSeq,RuleType,RuleDescription,CreatedByIDSeq,CreatedDate,SystemLogDate)
        select @LBI_RuleIDSeq  as RuleIDSeq,@IPVC_CompanyIDSeq as CompanyIDSeq,@IPVC_RuleType as RuleType,@IPVC_RuleDescription as RuleDescription,
               @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate;
        -----------------------------------------------
      COMMIT TRANSACTION IDERH;
    END TRY
    BEGIN CATCH
      if (XACT_STATE()) = -1
      begin
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION IDERH;
      end
      else 
      if (XACT_STATE()) = 1
      begin
        IF @@TRANCOUNT > 0 COMMIT TRANSACTION IDERH;
      end
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION IDERH;
      select @LVC_ErrorCodeSection = 'Proc:uspCUSTOMERS_SetExceptionRuleAndDetail - Creating New Rule Failed.' + 'Company:' + @IPVC_CompanyIDSeq+';RuleType:'+@IPVC_RuleType+';'
      Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
      return; 
    end CATCH
  end
  -----------------------------------------------------------------------------------------------------------
  select @LVC_SQL = 'Insert into #LT_InvoiceDeliveryExceptionRuleDetail(RuleIDSeq,RuleType,CompanyIDSeq,DeliveryOptionCode,BillToAddressTypeCode,ApplyToCustomBundleFlag,ApplyToOMSIDSeq'+
                    (case when @IPVC_RuleType = 'None'        then ''
                          when @IPVC_RuleType = 'Family'      then ',ApplyToFamilyCode'
                          when @IPVC_RuleType = 'Category'    then ',ApplyToCategoryCode'
                          when @IPVC_RuleType = 'ProductType' then ',ApplyToProductTypeCode'
                          when @IPVC_RuleType = 'Product'     then ',ApplyToProductCode'
                          else ''
                     end) + ', ShowSiteNameOnInvoiceFlag)' + char(13)
  select @LVC_SQL = @LVC_SQL +
                    ' Select S.RuleIDSeq,S.RuleType,S.CompanyIDSeq,S.DeliveryOptionCode,S.BillToAddressTypeCode,ApplyToCustomBundleFlag,OMSL.ApplyToOMSIDSeq' +
                    (case when @IPVC_RuleType = 'None'        then ''
                          else ',IL.ListCode '
                     end)    + char(13) + ', S.ShowSiteNameOnInvoiceFlag' + 
                    ' from ' + char(13) + 
                                '(Select ' + convert(varchar(50),@LBI_RuleIDSeq)                       +                ' as RuleIDSeq'                  + ',' + Char(13)   + 
                                          char(39) + @IPVC_RuleType                                    + Char(39)     + ' as RuleType'                   + ',' + Char(13)   + 
                                          char(39) + @IPVC_CompanyIDSeq                                + Char(39)     + ' as CompanyIDSeq'               + ',' + Char(13)   + 
                                          char(39) + @IPVC_DeliveryOptionCode                          + Char(39)     + ' as DeliveryOptionCode'         + ',' + Char(13)   + 
                                          char(39) + convert(varchar(50),@IPI_ApplyToCustomBundleFlag) + Char(39)     + ' as ApplyToCustomBundleFlag'    + ',' + Char(13)   + 

                                          (case when @IPVC_BillToAddressTypeCode is null 
                                                  then  'NULL'
                                                else char(39) + @IPVC_BillToAddressTypeCode + Char(39)
                                           end)                                              + ' as BillToAddressTypeCode'       +  ',' + Char(13)   +  
										  char(39) + convert(varchar(1), @IPI_ShowSiteNameOnInvoiceFlag)                        + Char(39)     + ' as ShowSiteNameOnInvoiceFlag'      +  Char(13)   +
                                ') S '        + char(13)  +
                                'Cross Join ' + char(13)  +
                                '#LT_ApplyToOMSIDList OMSL with (nolock) ' + char(13)  +
                                (case when @IPVC_RuleType <> 'None'
                                       then  'Cross Join ' + char(13)  + '#LT_ItemCodeList     IL with (nolock)   '
                                       else ''
                                end)          + char(13) +  
                    ' Group by S.RuleIDSeq,S.RuleType,S.CompanyIDSeq,S.DeliveryOptionCode,S.BillToAddressTypeCode,S.ApplyToCustomBundleFlag,OMSL.ApplyToOMSIDSeq' + 
                    (case when @IPVC_RuleType = 'None'        then ''
                          else ',IL.ListCode '
                     end)    + char(13) + ', S.ShowSiteNameOnInvoiceFlag'        
  --select @LVC_SQL
  exec(@LVC_SQL);
 ---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
  begin
    GOTO DoOperation 
    GOTO FinalCleanUp   
    return;
  end
 ---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
DoOperation:
  BEGIN TRY    
      --------------------------------------------------------------------------------------------
      --Step 3 : Create History Records -
      --         Move Conflicting previously existing Rule data for this company to History Table.
      --------------------------------------------------------------------------------------------
      select @LBI_HistoryRevisionID = coalesce((select Max(IH.HistoryRevisionID)
                                                from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetailHistory IH with (nolock)
                                                where  IH.CompanyIDSeq = @IPVC_CompanyIDSeq
                                                ),0)+1;
    
      Delete  D
      output @LBI_HistoryRevisionID as HistoryRevisionID,deleted.RuleIDSeq as RuleIDSeq,deleted.RuleType as RuleType,
             deleted.CompanyIDSeq as CompanyIDSeq,deleted.ApplyToOMSIDSeq as ApplyToOMSIDSeq,
             deleted.ApplyToFamilyCode as ApplyToFamilyCode,deleted.ApplyToCategoryCode as ApplyToCategoryCode,
             deleted.ApplyToProductTypeCode as ApplyToProductTypeCode,deleted.ApplyToProductCode as ApplyToProductCode,
             deleted.ApplyToCustomBundleFlag as ApplyToCustomBundleFlag,
             deleted.BillToAddressTypeCode as BillToAddressTypeCode,deleted.DeliveryOptionCode as DeliveryOptionCode,
             deleted.CreatedDate as CreatedDate,deleted.CreatedByIDSeq as CreatedByIDSeq,
             @LDT_SystemDate as ModifiedDate,@IPBI_UserIDSeq as ModifiedByIDSeq,@LDT_SystemDate as SystemLogDate,
             deleted.ShowSiteNameOnInvoiceFlag as ShowSiteNameOnInvoiceFlag
      into   Customers.dbo.InvoiceDeliveryExceptionRuleDetailHistory(HistoryRevisionID,RuleIDSeq,RuleType,CompanyIDSeq,ApplyToOMSIDSeq,
                                                                     ApplyToFamilyCode,ApplyToCategoryCode,ApplyToProductTypeCode,ApplyToProductCode,
                                                                     ApplyToCustomBundleFlag,
                                                                     BillToAddressTypeCode,DeliveryOptionCode,CreatedDate,CreatedByIDSeq,
                                                                     ModifiedDate,ModifiedByIDSeq,SystemLogDate,ShowSiteNameOnInvoiceFlag
                                                                    )  
      from CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail D with (nolock)       
      inner join
           #LT_InvoiceDeliveryExceptionRuleDetail S with (nolock)
      on     D.CompanyIDSeq    = S.CompanyIDSeq  
      and    coalesce(D.ApplyToOMSIDSeq,'ABC')        = coalesce(S.ApplyToOMSIDSeq,'ABC')
      and    coalesce(D.ApplyToFamilyCode,'ABC')      = coalesce(S.ApplyToFamilyCode,'ABC')
      and    coalesce(D.ApplyToCategoryCode,'ABC')    = coalesce(S.ApplyToCategoryCode,'ABC')
      and    coalesce(D.ApplyToProductTypeCode,'ABC') = coalesce(S.ApplyToProductTypeCode,'ABC')
      and    coalesce(D.ApplyToProductCode,'ABC')     = coalesce(S.ApplyToProductCode,'ABC')
      and    D.ApplyToCustomBundleFlag                = S.ApplyToCustomBundleFlag 
      and    D.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    S.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    D.RuleIDSeq       <> @LBI_RuleIDSeq;
   
      Delete  D
      output @LBI_HistoryRevisionID as HistoryRevisionID,deleted.RuleIDSeq as RuleIDSeq,deleted.RuleType as RuleType,
             deleted.CompanyIDSeq as CompanyIDSeq,deleted.ApplyToOMSIDSeq as ApplyToOMSIDSeq,
             deleted.ApplyToFamilyCode as ApplyToFamilyCode,deleted.ApplyToCategoryCode as ApplyToCategoryCode,
             deleted.ApplyToProductTypeCode as ApplyToProductTypeCode,deleted.ApplyToProductCode as ApplyToProductCode,
             deleted.ApplyToCustomBundleFlag as ApplyToCustomBundleFlag,
             deleted.BillToAddressTypeCode as BillToAddressTypeCode,deleted.DeliveryOptionCode as DeliveryOptionCode,
             deleted.CreatedDate as CreatedDate,deleted.CreatedByIDSeq as CreatedByIDSeq,
             @LDT_SystemDate as ModifiedDate,@IPBI_UserIDSeq as ModifiedByIDSeq,@LDT_SystemDate as SystemLogDate,
			 deleted.ShowSiteNameOnInvoiceFlag as ShowSiteNameOnInvoiceFlag
      into   Customers.dbo.InvoiceDeliveryExceptionRuleDetailHistory(HistoryRevisionID,RuleIDSeq,RuleType,CompanyIDSeq,ApplyToOMSIDSeq,
                                                                     ApplyToFamilyCode,ApplyToCategoryCode,ApplyToProductTypeCode,ApplyToProductCode,
                                                                     ApplyToCustomBundleFlag,
                                                                     BillToAddressTypeCode,DeliveryOptionCode,CreatedDate,CreatedByIDSeq,
                                                                     ModifiedDate,ModifiedByIDSeq,SystemLogDate, ShowSiteNameOnInvoiceFlag
                                                                    )   
      from CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail D with (nolock)       
      inner join
           #LT_InvoiceDeliveryExceptionRuleDetail S with (nolock)
      on     D.CompanyIDSeq    = S.CompanyIDSeq 
      and    D.RuleIDSeq       = S.RuleIDSeq  
      and    D.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    S.CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    D.RuleIDSeq       = @LBI_RuleIDSeq
      and    S.RuleIDSeq       = @LBI_RuleIDSeq
      and    D.RECORDCRC       <> S.RECORDCRC;  

      Delete CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail
      where  CompanyIDSeq    = @IPVC_CompanyIDSeq
      and    RuleIDSeq       = @LBI_RuleIDSeq;
      ------------------------------------------------------------------
      --Step 4 : Finally Insert into InvoiceDeliveryExceptionRuleDetail
      ------------------------------------------------------------------      
      begin
        Insert into Customers.dbo.InvoiceDeliveryExceptionRuleDetail(RuleIDSeq,RuleType,CompanyIDSeq,ApplyToOMSIDSeq,
                                                                     ApplyToFamilyCode,ApplyToCategoryCode,
                                                                     ApplyToProductTypeCode,ApplyToProductCode,
                                                                     ApplyToCustomBundleFlag,
                                                                     BillToAddressTypeCode,DeliveryOptionCode,
                                                                     CreatedDate,CreatedByIDSeq,SystemLogDate, ShowSiteNameOnInvoiceFlag 
                                                                     )
        select S.RuleIDSeq,S.RuleType,S.CompanyIDSeq,S.ApplyToOMSIDSeq,
               S.ApplyToFamilyCode,S.ApplyToCategoryCode,S.ApplyToProductTypeCode,S.ApplyToProductCode,
               S.ApplyToCustomBundleFlag,
               S.BillToAddressTypeCode,S.DeliveryOptionCode,
               @LDT_SystemDate as CreatedDate,@IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as SystemLogDate, ShowSiteNameOnInvoiceFlag
        from   #LT_InvoiceDeliveryExceptionRuleDetail S with (nolock)
      end    
    -----------------------------------------------------------------------------------------------------------
    ---Step 5 : Apply Latest and greatest applicable rules to all Orders pertaining to Company in question
    EXEC ORDERS.dbo.uspORDERS_ApplyMBADOExceptionRules  @IPVC_CompanyIDSeq=@IPVC_CompanyIDSeq,@IPBI_UserIDSeq=@IPBI_UserIDSeq
    -----------------------------------------------------------------------------------------------------------
  end TRY
  begin CATCH    
    select @LVC_ErrorCodeSection = 'Proc:uspCUSTOMERS_SetExceptionRuleAndDetail. Creating Rule Details Failed.' + 'Company:' + @IPVC_CompanyIDSeq+';RuleType:'+@IPVC_RuleType+';'
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_ErrorCodeSection
    GOTO FinalCleanUp
    return;                 
  end CATCH;
---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
FinalCleanUp:
  -----------------
  --Final Clean up
  -----------------
  Delete D
  from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRule D with (nolock)
  where  D.CompanyIDSeq    = @IPVC_CompanyIDSeq
  and    not exists (select Top 1 1
                     from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail S with (nolock)
                     where  D.CompanyIDSeq    = S.CompanyIDSeq 
                     and    D.RuleIDSeq       = S.RuleIDSeq 
                     and    S.CompanyIDSeq    = @IPVC_CompanyIDSeq
                    );
  if (object_id('tempdb.dbo.#LT_ItemCodeList') is not null) 
  begin
    drop table #LT_ItemCodeList
  end;
  if (object_id('tempdb.dbo.#LT_ApplyToOMSIDList') is not null) 
  begin
    drop table #LT_ApplyToOMSIDList
  end;
  if (object_id('tempdb.dbo.#LT_InvoiceDeliveryExceptionRuleDetail') is not null) 
  begin
    drop table #LT_InvoiceDeliveryExceptionRuleDetail
  end;
---~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~--
END
GO
