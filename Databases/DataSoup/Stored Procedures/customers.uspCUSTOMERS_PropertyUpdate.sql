SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_PropertyUpdate
-- Description     : This procedure gets called for Edit and Save of Property Related Attributes only
--                    This procedure takes care of Updating Company Information
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_PropertyUpdate  Passing Input Parameters
-- Revision History:
-- Author          : SRS
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_PropertyUpdate] (@IPVC_CompanyIDSeq           varchar(50),                     --> This is the CompanyID, to which the property needs to be created.(Mandatory) 
                                                      @IPVC_PropertyIDSeq          varchar(50),                     --> For Edit Existing Property it  passed from UI.(Mandatory)
                                                      @IPVC_PropertyName           varchar(255),                    --> Name of Property
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
                                                      @IPBI_UserIDSeq              bigint                            --> This is UserID of person logged on and creating this company in OMS.(Mandatory)
                                                     )
AS 
BEGIN
  set nocount on;  
  SET CONCAT_NULL_YIELDS_NULL off;
  ----------------------------------------------------------------------------
  -- Local Variable Declaration
  ---------------------------------------------------------------------------- 
  declare @LDT_SystemDate      datetime
  Declare @LVC_PriceTypeCode   varchar(20)
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
  --Step 1 : Update General Attributes for Existing Property passed.
  ----------------------------------------------------------------------------
  Update Customers.dbo.Property
  set    [Name]                 = @IPVC_PropertyName,
         Phase                  = @IPVC_Phase,
         StatusTypeCode         = @IPVC_StatusTypecode,
         OwnerIDSeq             = @IPVC_OwnerIDSeq,
         OwnerName              = @IPVC_OwnerName,
         PriceTypeCode          = @LVC_PriceTypeCode,
         SiteMasterID           = @IPVC_SiteMasterID,
         Units                  = @IPI_Units,
         Beds                   = @IPI_Beds,
         PPUPercentage          = @IPI_PPUPercentage,
         QuotableUnits          = @IPI_QuoteableUnits,
         QuotableBeds           = @IPI_QuoteableBeds, 
         SubPropertyFlag        = @IPI_SubPropertyFlag,
         ConventionalFlag       = @IPI_ConventionalFlag,
         StudentLivingFlag      = @IPI_StudentLivingFlag,
         HUDFlag                = @IPI_HUDFlag,
         RHSFlag                = @IPI_RHSFlag,
         TaxCreditFlag          = @IPI_TaxCreditFlag,
         VendorFlag         = @IPI_VendorFlag,
         RetailFlag             = @IPI_RetailFlag,
         GSAEntityFlag          = @IPI_GSAEntityFlag,
         MilitaryPrivatizedFlag = @IPI_MilitaryPrivatizedFlag,
         SeniorLivingFlag       = @IPI_SeniorLivingFlag,
         CustomBundlesProductBreakDownTypeCode = @IPVC_CustomBundlesProductBreakDownTypeCode,
         SeparateInvoiceByFamilyFlag           = @IPI_SeparateInvoiceByFamilyFlag,
         SendInvoiceToClientFlag=1, --> This should be always 1.         
         ModifiedByIDSeq     = @IPBI_UserIDSeq,
         ModifiedDate        = @LDT_SystemDate,
         SystemLogDate       = @LDT_SystemDate
  where  IDSeq     = @IPVC_PropertyIDSeq
  and    PMCIDSeq  = @IPVC_CompanyIDSeq
  ----------------------------------------------------------------------------
  ---Account Related Update
  Exec CUSTOMERS.DBO.useCUSTOMERS_UpdateAccountStatus
                         @IPVC_CompanyIDSeq   = @IPVC_CompanyIDSeq,
                         @IPVC_PropertyIDSeq  = @IPVC_PropertyIDSeq,
                         @IPVC_StatusTypecode = @IPVC_StatusTypecode,
                         @IPVC_AccountTypeCode= 'APROP',
                         @IPBI_UserIDSeq      = @IPBI_UserIDSeq
  ----------------------------------------------------------------------------
  --TFS 526,615 : Do Unit,Bed,PPU change post operation.
  EXEC ORDERS.dbo.uspORDERS_UnitBedPPUChangeOperation  
                               @IPVC_CompanyIDSeq   = @IPVC_CompanyIDSeq
                              ,@IPVC_PropertyIDSeq  = @IPVC_PropertyIDSeq
                              ,@IPI_CurrentUnits    = @IPI_Units
                              ,@IPI_CurrentBeds     = @IPI_Beds
                              ,@IPI_CurrentPPUPercentage = @IPI_PPUPercentage
                              ,@IPBI_UserIDSeq      = @IPBI_UserIDSeq 
  ----------------------------------------------------------------------------

END
GO
