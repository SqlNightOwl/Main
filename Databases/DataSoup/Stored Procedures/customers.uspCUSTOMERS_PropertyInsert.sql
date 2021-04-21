SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_PropertyInsert
-- Description     : This procedure gets called for Creation of Brand New Property
--                    This procedure takes care of Inserting Only Company Records.
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_PropertyInsert  Passing Input Parameters
-- Revision History:
-- Author          : SRS
-- 05/31/2011      : STH  TFS 647 to Identify migrated companies.
-- 09/06/2011	   : Mahaboob TFS 924 -- To include any new properties added to existing active/inactive price caps, whose Property selection is all sites.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_PropertyInsert] (@IPVC_CompanyIDSeq           varchar(50),                     --> This is the CompanyID, to which the property needs to be created.(Mandatory) 
                                                      @IPVC_PropertyIDSeq          varchar(50) ='',                 --> For Brand New Property it will be blank string passed from UI.
                                                                                                                        --   This is for extra validation in that UI cannot call this proc on Edit mode with Valid PropertyID tied to it.
                                                      @IPVC_PropertyName           varchar(255),                    --> Name of Property to be created brand new                                                     
                                                      @IPVC_Phase                  varchar(100)='',                 --> This is Phase of Property. Default is NULL or Blank.
                                                      @IPVC_StatusTypecode         varchar(10) ='ACTIV',            --> UI will pass based on Value of Status drop down.Default ACTIV
                                                      @IPVC_OwnerIDSeq             varchar(50),                     --> OwnerIDSeq is Mandatory              
                                                      @IPVC_OwnerName              varchar(50),                     --> This is already available in UI in the drop down

                                                      @IPI_Units                   int,                             --> Units. UI should enforce it is Non Zero. 
                                                      @IPI_Beds                    int          =0,                 --> Beds. UI should enforce it is Non Zero if StudentlivingFlag is checked. 
                                                      @IPI_PPUPercentage           Numeric(18,2)=100,               --> PPUPercentage. 
                                                      @IPI_QuoteableUnits          int,                             --> QuoteableUnits. UI should enforce it is Non Zero. 
                                                      @IPI_QuoteableBeds           int          =0,                 --> Beds. UI should enforce it is Non Zero if StudentlivingFlag is checked. 
                                                      @IPVC_SiteMasterID           varchar(50)  ='',                --> Valid 7 digit SitemasterID from UI. Default is NULL
                                                      
                                                      @IPI_SubPropertyFlag         int          =0,                 --> In UI, if NO in dropdown then 0 by default, If Yes then 1 for SubpropertyFlag
                                                      @IPVC_CustomBundlesProductBreakDownTypeCode varchar(4)= 'NOBR',-->  This is CustomBundlesProductBreakDownTypeCode. For Brand new Property creation
                                                                                                                     --   UI is hardcoding to 'NOBR' when Expand Custom Bundle is UnChecked. Else when checked it 'YEBR'
                                                      @IPI_SeparateInvoiceByFamilyFlag            int=0,             --> In UI when SeparateInvoiceByFamilyFlag is checked then 1, else 0                                                      
                                                      @IPI_ConventionalFlag        int          =0,                  --> Conventional Flag
                                                      @IPI_HUDFlag                 int          =0,                  --> HUD Flag
                                                      @IPI_TaxCreditFlag           int          =0,                  --> Tax Credit Flag
                                                      @IPI_StudentLivingFlag       int          =0,                  --> StudentLivingFlag
                                                      @IPI_RHSFlag                 int          =0,                  --> RHSFlag
                                                      @IPI_VendorFlag          int          =0,                  --> VendorFlag
                                                      @IPI_GSAEntityFlag           int          =0,                  --> GSAEntityFlag
                                                      @IPI_RetailFlag              int          =0,                  --> RetailFlag
                                                      @IPI_MilitaryPrivatizedFlag  int          =0,                  --> MilitaryPrivatizedFlag
                                                      @IPI_SeniorLivingFlag        int          =0,                  --> SeniorLivingFlag
                                                      @IPBI_UserIDSeq              bigint,                           --> This is UserID of person logged on and creating this company in OMS.(Mandatory)
                                                      @Migration                   bit          =0                   --> This flag if set true will skip the call to get Legacy Registration Code     
													 )
AS 
BEGIN
  set nocount on;  
  SET CONCAT_NULL_YIELDS_NULL off;
  ----------------------------------------------------------------------------
  -- Local Variable Declaration
  ---------------------------------------------------------------------------- 
  declare @LVC_PropertyIDSeq   varchar(50)
  declare @LDT_SystemDate      datetime
  declare @LVC_CodeSection     varchar(1000)  
  Declare @LVC_RegCode         varchar(4)
  Declare @LVC_PriceTypeCode   varchar(20)
  ----------------------------------------------------------------------------
  ---Inital validation
  if exists(select top 1 1 
            from   Customers.dbo.Property P with (nolock)
            where  P.IDSeq  = @IPVC_PropertyIDSeq
            and    len(NULLIF(@IPVC_PropertyIDSeq,'')) > 0
           )
  begin
    select @LVC_CodeSection='PropertyID: ' + @IPVC_PropertyIDSeq + ' already exists in the system. Wrong Proc call uspCUSTOMERS_PropertyInsert from UI. Only uspCUSTOMERS_PropertyUpdate should be initiated.'
    select '-1' as PropertyID
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  ----------------------------------------------------------------------------
  --Initialization of Variables.
  select @LDT_SystemDate     = Getdate(),       
         @IPVC_PropertyName  = LTRIM(RTRIM(UPPER(@IPVC_PropertyName))),
         @IPVC_Phase         = LTRIM(RTRIM(UPPER(@IPVC_Phase))), 
         @IPVC_SiteMasterID  = (case when isnumeric(@IPVC_SiteMasterID)= 0 then NULL else  NULLIF(@IPVC_SiteMasterID,'') end),
         @IPVC_OwnerName     = LTRIM(RTRIM(NULLIF(@IPVC_OwnerName,''))),
         @LVC_PriceTypeCode  = (Case when (@IPI_StudentLivingFlag=1 and @IPI_Beds  < 100) then 'Small'
                                     when (@IPI_StudentLivingFlag=0 and @IPI_Units < 100) then 'Small'
                                     else 'Normal'
                                end)
  ----------------------------------------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION PROP;  
      ---------------------------------------------------------------------------------
      --Step 1 : get unique New PropertyID generated for this Brand New Property Creation
      ---------------------------------------------------------------------------------
      update CUSTOMERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
      set    IDSeq = IDSeq+1,
             GeneratedDate =CURRENT_TIMESTAMP 
      where  TypeIndicator = 'P'

      select @LVC_PropertyIDSeq = IDGeneratorSeq
      from   CUSTOMERS.DBO.IDGenerator with (NOLOCK)  
      where  TypeIndicator = 'P'
      ---------------------------------------------------------------------------------
      --Step 2 : get unique Registration Code for New Company      
	  if @Migration = 0  --TFS 647
         EXEC CUSTOMERS.dbo.uspCUSTOMERS_GetLegacyRegistrationCode @LVC_RegCode output
      ---------------------------------------------------------------------------------
      --Step 3: Insert Property Record.
      ---------------------------------------------------------------------------------
      Insert into Customers.dbo.Property(IDSeq,Name,Phase,StatusTypeCode,
                                         PMCIDSeq,OwnerIDSeq,OwnerName,
                                         PriceTypeCode,SiteMasterID,LegacyRegistrationCode,
                                         Units,Beds,PPUPercentage,
                                         QuotableUnits,QuotableBeds,
                                         SubPropertyFlag,ConventionalFlag,StudentLivingFlag,
                                         HUDFlag,RHSFlag,TaxCreditFlag,VendorFlag,
                                         RetailFlag,GSAEntityFlag,MilitaryPrivatizedFlag,SeniorLivingFlag,                                         
                                         CustomBundlesProductBreakDownTypeCode,SeparateInvoiceByFamilyFlag,
                                         SendInvoiceToClientFlag,
                                         CreatedByIDSeq,CreatedDate,SystemLogDate)
      select @LVC_PropertyIDSeq as IDSeq,@IPVC_PropertyName as [Name],@IPVC_Phase as Phase,@IPVC_StatusTypecode as StatusTypeCode,
             @IPVC_CompanyIDSeq as PMCIDSeq,@IPVC_OwnerIDSeq as OwnerIDSeq,@IPVC_OwnerName as OwnerName,
             @LVC_PriceTypeCode as PriceTypeCode,@IPVC_SiteMasterID as SiteMasterID,@LVC_RegCode as LegacyRegistrationCode,
             @IPI_Units as Units,@IPI_Beds as Beds,@IPI_PPUPercentage as PPUPercentage,
             @IPI_QuoteableUnits as QuotableUnits,@IPI_QuoteableBeds as QuotableBeds,
             @IPI_SubPropertyFlag as SubPropertyFlag,@IPI_ConventionalFlag as ConventionalFlag,@IPI_StudentLivingFlag as StudentLivingFlag,
             @IPI_HUDFlag as HUDFlag,@IPI_RHSFlag as RHSFlag,@IPI_TaxCreditFlag as TaxCreditFlag,@IPI_VendorFlag as VendorFlag,
             @IPI_RetailFlag as RetailFlag,@IPI_GSAEntityFlag as GSAEntityFlag,@IPI_MilitaryPrivatizedFlag,@IPI_SeniorLivingFlag,  
             @IPVC_CustomBundlesProductBreakDownTypeCode as CustomBundlesProductBreakDownTypeCode,@IPI_SeparateInvoiceByFamilyFlag as SeparateInvoiceByFamilyFlag,
             1 as SendInvoiceToClientFlag,
             @IPBI_UserIDSeq as  CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
      ---------------------------------------------------------------------------------
      --	To include any new properties added to existing active/inactive price caps, whose Property selection is all sites.
      ------------------------------------------------------------------------------------------------------------------------
      Declare @minIDSeq bigint, @maxIDSeq bigint
      Declare @LVBI_PriceCapIDSeq bigint, @LVI_CompnayPropertiesCount int, @LVI_PriceCapPropertiesCount int
      select  @minIDSeq = min(IDSeq), @maxIDSeq = max(IDSeq) from Customers.dbo.PriceCap where CompanyIDSeq = @IPVC_CompanyIDSeq
      select  @LVI_CompnayPropertiesCount  =  Customers.dbo.GetProperties(@IPVC_CompanyIDSeq) - 1
     
      while( @minIDSeq <= @maxIDSeq )
      begin
           select  @LVBI_PriceCapIDSeq = @minIDSeq 
		   select  @LVI_PriceCapPropertiesCount = count(PriceCapIDSeq) from Customers.dbo.PriceCapProperties where PriceCapIDSeq = @LVBI_PriceCapIDSeq and PropertyIDSeq is not null
           if( @LVI_CompnayPropertiesCount = @LVI_PriceCapPropertiesCount )
           begin
				---------------------------------------------------------------------------------------------------  
				   -- Adding to PriceCapProperties  
				   insert into Customers.dbo.PriceCapProperties  
				   (  
						  PriceCapIDSeq,  
						  CompanyIDSeq,                    
						  PropertyIDSeq  
				   )  
				   values
				   (  
						  @LVBI_PriceCapIDSeq,  
						  @IPVC_CompanyIDSeq,  
						  @LVC_PropertyIDSeq            
					)
		  
			    ----------------------------------------------------------------------------------------------------  
				  -- Adding to PriceCapPropertiesHistory  
		  
				   insert into Customers.dbo.PriceCapPropertiesHistory  
				   (  
						  PriceCapIDSeq,  
						  CompanyIDSeq,                    
						  PropertyIDSeq  
				   )  
				   values
				   (  
						  @LVBI_PriceCapIDSeq,  
						  @IPVC_CompanyIDSeq,  
						  @LVC_PropertyIDSeq            
					) 
                ---------------------------------------------------------------------------------------------------  
          end           
      	  select  @minIDSeq = min(IDSeq) from Customers.dbo.PriceCap where CompanyIDSeq = @IPVC_CompanyIDSeq and IDSeq > @minIDSeq
      end
      -----------------------------------------------------------------------------------------------------------------------------
    COMMIT TRANSACTION PROP; 
  END TRY
  BEGIN CATCH
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION PROP;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION PROP;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION PROP;   
    ------------------------      
    select @LVC_CodeSection =  'Proc :uspCUSTOMERS_CompanyInsert;Error Creating Property Record For: '+ @IPVC_PropertyName
    ------------------------
    select '-1' as PropertyID     
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;                  
  END CATCH; 
  -------------------------------------------------------------------------------
  ---Final Return to UI
  -------------------------------------------------------------------------------
  select @LVC_PropertyIDSeq as PropertyID
  -------------------------------------------------------------------------------
END
GO
