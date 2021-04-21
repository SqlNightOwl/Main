SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CompanyInsert
-- Description     : This procedure gets called for Creation of Brand New Company
--                    This procedure takes care of Inserting Only Company Records.
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_CompanyInsert  Passing Input Parameters
-- Revision History:
-- Author          : SRS
-- 2011-05-31      : STH  TFS 647 to Identify migrated companies.
-- 2011-07-28      : Mahaboob ( Defect #909 ) --  Modified procedure to insert "ExecutiveIDSeq" into "Company" table. 
-----------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CompanyInsert] (@IPVC_CompanyIDSeq           varchar(50) ='',                  --> For Brand New Company it will be blank string passed from UI.
                                                                                                                    --   This is for extra validation in that UI cannot call this proc on Edit mode with Valid CompanyID tied to it.
                                                     @IPVC_CompanyName            varchar(255),                     --> Name of Company to be created brand new                                                     
                                                     @IPVC_StatusTypecode         varchar(10) ='ACTIV',             --> UI will pass based on Value of Status drop down.Default ACTIV
                                                                                                                    --   Obviously user would not want to create a brand new Inactive status Company
                                                     @IPI_OwnerFlag               int         = 0,                  --> If OwnerFlag in UI is checked this is 1. Else 0.
                                                     @IPVC_SignatureText          varchar(255)= '',                 --> This is optional signature line for the company
                                                     @IPI_OrderSynchStartMonth    int         = 0,                  --> This is Sync Term Drop down value from UI. Default is 0
                                                     @IPVC_CustomBundlesProductBreakDownTypeCode varchar(4)= 'NOBR',--> This is CustomBundlesProductBreakDownTypeCode. For Brand new company creation, this option is disabled.
                                                                                                                    --   UI is hardcoding to 'NOBR' and sending currently.
                                                     @IPVC_SiteMasterID           varchar(50) ='',                  --> Valid 7 digit SitemasterID from UI. Default is NULL
                                                     @IPI_MultiFamilyFlag         int         = 0,                  --> If MultiFamily in UI is checked this is 1. Else 0.
                                                     @IPI_VendorFlag              int         = 0,                  --> If Vendor in UI is checked this is 1. Else 0.
                                                     @IPI_GSAEntityFlag           int         = 0,                  --> If GSAEntity  in UI is checked this is 1. Else 0.
                                                     @IPBI_UserIDSeq              bigint,                           --> This is UserID of person logged on and creating this company in OMS.(Mandatory)
													 @IPVC_ExecutiveCompanyIDSeq  varchar(50),                       --> ExecutiveCompanyID, passed from UI.
													 @Migration                   bit         = 0                   --> This flag if set true will skip the call to get Legacy Registration Code
                                                    )
as 
BEGIN
  set nocount on;  
  SET CONCAT_NULL_YIELDS_NULL off;
  ----------------------------------------------------------------------------
  -- Local Variable Declaration
  ---------------------------------------------------------------------------- 
  declare @LVC_CompanyIDSeq    varchar(50)
  declare @LDT_SystemDate      datetime
  declare @LVC_CodeSection     varchar(1000)
  declare @LI_PMCFlag          int
  Declare @LVC_RegCode         varchar(4)
  declare @LVC_ExecutiveCompanyIDSeq  varchar(50)
  ----------------------------------------------------------------------------
  ---Inital validation
  if exists(select top 1 1 
            from   Customers.dbo.Company C with (nolock)
            where  C.IDSeq  = @IPVC_CompanyIDSeq
            and    len(NULLIF(@IPVC_CompanyIDSeq,'')) > 0
           )
  begin
    select @LVC_CodeSection='CompanyID: ' + @IPVC_CompanyIDSeq + ' already exists in the system. Wrong Proc call uspCUSTOMERS_CompanyInsert from UI. Only uspCUSTOMERS_CompanyUpdate should be initiated.'
    select '-1' as CompanyID
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  ----------------------------------------------------------------------------
  --Initialization of Variables.
  select @LDT_SystemDate			= Getdate(),
         --@LI_PMCFlag				= 1,   ---> By default all company's created are PMC class.
		 @LI_PMCFlag				= @IPI_MultiFamilyFlag,
         @IPVC_CompanyName			= LTRIM(RTRIM(UPPER(@IPVC_CompanyName))),
         @IPVC_SiteMasterID			= (case when isnumeric(@IPVC_SiteMasterID)= 0 then NULL else  NULLIF(@IPVC_SiteMasterID,'') end),
         @IPVC_SignatureText		= LTRIM(RTRIM(NULLIF(@IPVC_SignatureText,''))),
		 @LVC_ExecutiveCompanyIDSeq = ( case 
										 when LTRIM(RTRIM(UPPER(@IPVC_ExecutiveCompanyIDSeq))) = '' then NULL
										 else LTRIM(RTRIM(UPPER(@IPVC_ExecutiveCompanyIDSeq)))
										 end
                                      )
  ----------------------------------------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION COMP;  
      ---------------------------------------------------------------------------------
      --Step 1 : get unique New CompanyID generated for this Brand New Company Creation
      ---------------------------------------------------------------------------------
      update CUSTOMERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
      set    IDSeq = IDSeq+1,
             GeneratedDate =CURRENT_TIMESTAMP 
      where  TypeIndicator = 'C'

      select @LVC_CompanyIDSeq = IDGeneratorSeq
      from   CUSTOMERS.DBO.IDGenerator with (NOLOCK)  
      where  TypeIndicator = 'C'
      ---------------------------------------------------------------------------------
      --Step 2 : get unique Registration Code for New Company  
	  if @Migration = 0   --TFS 647  
         EXEC CUSTOMERS.dbo.uspCUSTOMERS_GetLegacyRegistrationCode @LVC_RegCode output
      ---------------------------------------------------------------------------------
      --Step 3: Insert Company Record.
      ---------------------------------------------------------------------------------
      Insert into Customers.dbo.Company (IDSeq,Name,StatusTypecode,SiteMasterID,
                                         PMCFlag,OwnerFlag,SignatureText,
                                         LegacyRegistrationCode,OrderSynchStartMonth,
                                         CustomBundlesProductBreakDownTypeCode,
                                         SendInvoiceToClientFlag,
                                         MultiFamilyFlag,VendorFlag,GSAEntityFlag,CreatedByIDSeq,CreatedDate,SystemLogDate, ExecutiveCompanyIDSeq
                                        )
     select @LVC_CompanyIDSeq    as IDSeq,@IPVC_CompanyName as [Name],@IPVC_StatusTypecode   as StatusTypecode,@IPVC_SiteMasterID as SiteMasterID,
            @LI_PMCFlag          as PMCFlag,@IPI_OwnerFlag  as OwnerFlag,@IPVC_SignatureText as SignatureText,
            @LVC_RegCode         as LegacyRegistrationCode,@IPI_OrderSynchStartMonth as OrderSynchStartMonth,
            @IPVC_CustomBundlesProductBreakDownTypeCode   as CustomBundlesProductBreakDownTypeCode,
            1                    as SendInvoiceToClientFlag,
            @IPI_MultiFamilyFlag as MultiFamilyFlag,@IPI_VendorFlag as VendorFlag,@IPI_GSAEntityFlag as GSAEntityFlag,
            @IPBI_UserIDSeq      as CreatedByIDSeq,@LDT_SystemDate      as CreatedDate,@LDT_SystemDate       as SystemLogDate,
			@LVC_ExecutiveCompanyIDSeq  as ExecutiveCompanyIDSeq
      ---------------------------------------------------------------------------------
      --Step 4: If Ownerflag is turned on , Create CustomerOwner record.
      ---------------------------------------------------------------------------------
      if (@IPI_OwnerFlag=1)
      begin
        Insert into Customers.dbo.CustomerOwner(CustomerIDSeq,OwnerIDSeq)
        select @LVC_CompanyIDSeq as CustomerIDSeq,@LVC_CompanyIDSeq as OwnerIDSeq
      end
      ---------------------------------------------------------------------------------
    COMMIT TRANSACTION COMP; 
  END TRY
  BEGIN CATCH
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION COMP;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION COMP;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION COMP;   
    ------------------------      
    select @LVC_CodeSection =  'Proc :uspCUSTOMERS_CompanyInsert;Error Creating Company Record For: '+ @IPVC_CompanyName
    ------------------------
    select '-1' as CompanyID     
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;                  
  END CATCH; 
  -------------------------------------------------------------------------------
  ---Final Return to UI
  -------------------------------------------------------------------------------
  select @LVC_CompanyIDSeq as CompanyID
  -------------------------------------------------------------------------------
END
GO
