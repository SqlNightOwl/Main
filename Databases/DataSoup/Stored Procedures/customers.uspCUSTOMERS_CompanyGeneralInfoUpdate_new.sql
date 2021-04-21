SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_CompanyInsert
-- Description     : This procedure gets called for Edit and Save of Company Related Attributes only
--                    This procedure takes care of Updating Company Information
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_CompanyGeneralInfoUpdate  Passing Input Parameters
-- Revision History:
-- Author          : SRS
-- 2010-07-14      : LWW- Support ability to leave Company.DeliveryOptionCode intact when appropriate
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_CompanyGeneralInfoUpdate_new] (@IPVC_CompanyIDSeq           varchar(50),          --> CompanyIDSeq identifying the Unique Company record for Update                                                                                               
                                                     @IPVC_CompanyName            varchar(255),         --> Name of Company to be be updated
                                                     @IPVC_StatusTypecode         varchar(10) ='ACTIV', --> Status of Company from Drop down.
                                                     @IPI_OwnerFlag               int         = 0,          --> If OwnerFlag in UI is checked this is 1. Else 0.
                                                     @IPVC_SignatureText          varchar(255)= '',         --> This is optional signature line for the company
                                                     @IPI_OrderSynchStartMonth    int         = 0,          --> This is Sync Term Drop down value from UI. Default is 0
                                                     @IPVC_SiteMasterID           varchar(50) ='',          --> Valid 7 digit SitemasterID from UI. Default is NULL
                                                     @IPI_MultiFamilyFlag         int         = 0,          --> If MultiFamily in UI is checked this is 1. Else 0.
                                                     @IPI_CommercialFlag          int         = 0,          --> If Commercial in UI is checked this is 1. Else 0.
                                                     @IPI_GSAEntityFlag           int         = 0,          --> If GSAEntity  in UI is checked this is 1. Else 0.
                                                     @IPVC_CompanyBillingEmail    varchar(4000)='',      --> Email ID Corresponding to Email Text field in UI from Company Billing Address Section
                                                                                                         -- This is Email Address Corresponding to Company Billing Address Section
                                                     @IPBI_UserIDSeq              bigint,                 --> This is UserID of person logged on and creating this company in OMS.(Mandatory)
													 @IPI_OpsSupplierFlag         int         = 0         --> If OpsSupplierFlag in UI is checked this is 1. Else 0.
                                                    )
AS 
BEGIN
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL off;
  ----------------------------------------------------------------------------
  -- Local Variable Declaration
  declare @LDT_SystemDate      datetime
  declare @LVC_CodeSection     varchar(1000)
  ---------------------------------------------------------------------------- 
  ---Inital validation
  if not exists(select top 1 1 
                from   Customers.dbo.Company C with (nolock)
                where  C.IDSeq  = @IPVC_CompanyIDSeq                
               )
  begin
    select @LVC_CodeSection='Proc :uspCUSTOMERS_CompanyGeneralInfoUpdate - CompanyID: ' + @IPVC_CompanyIDSeq + ' already does not exists in the system.' 
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return
  end
  ----------------------------------------------------------------------------
  --Initialization of Variables.
  select @LDT_SystemDate     = Getdate(),
         @IPVC_CompanyName   = LTRIM(RTRIM(UPPER(@IPVC_CompanyName))),
         @IPVC_SiteMasterID  = (case when isnumeric(@IPVC_SiteMasterID)= 0 then NULL else  NULLIF(@IPVC_SiteMasterID,'') end),
         @IPVC_SignatureText = LTRIM(RTRIM(NULLIF(@IPVC_SignatureText,'')))
  ----------------------------------------------------------------------------
  --Step 1: Update Company for important Attributes.
  ----------------------------------------------------------------------------
  update  CUSTOMERS.dbo.Company
  set     Name                 = @IPVC_CompanyName,
          OwnerFlag            = @IPI_OwnerFlag,
          SignatureText        = @IPVC_SignatureText,
          SiteMasterID         = @IPVC_SiteMasterID, 
          OrderSynchStartMonth = @IPI_OrderSynchStartMonth,         
          MultiFamilyFlag      = @IPI_MultiFamilyFlag,
          CommercialFlag       = @IPI_CommercialFlag,
          GSAEntityFlag        = @IPI_GSAEntityFlag,
          OpsSupplierFlag      = @IPI_OpsSupplierFlag,
          StatusTypeCode       = @IPVC_StatusTypecode,
          ModifiedByIDSeq      = @IPBI_UserIDSeq,
          ModifiedDate         = @LDT_SystemDate,
          SystemLogDate        = @LDT_SystemDate
  where   IDSeq = @IPVC_CompanyIDSeq  
  ----------------------------------------------------------------------------
  --Step 2: Update/Delete for @IPI_OwnerFlag
  ----------------------------------------------------------------------------
  if (@IPI_OwnerFlag=1)
  begin
    Insert into Customers.dbo.CustomerOwner(CustomerIDSeq,OwnerIDSeq)
    select @IPVC_CompanyIDSeq as CustomerIDSeq,@IPVC_CompanyIDSeq as OwnerIDSeq
    where  not exists(select top 1 1
                      from   Customers.dbo.CustomerOwner CO with (nolock)
                      where  CO.OwnerIDSeq = @IPVC_CompanyIDSeq
                     )
  end
  else if (@IPI_OwnerFlag=0)
  begin
    Delete from Customers.dbo.CustomerOwner where OwnerIDSeq = @IPVC_CompanyIDSeq
  end 
  ----------------------------------------------------------------------------
  --Step 3: Update for keeping Customer Name updated in Corresponding Quotes.
  --        Important.
  ----------------------------------------------------------------------------
  Update Quotes.dbo.Quote 
  set    CompanyName    = @IPVC_CompanyName
  where  CustomerIDSeq  = @IPVC_CompanyIDSeq
  and    (CompanyName <> @IPVC_CompanyName)
  ----------------------------------------------------------------------------
  ---Finally Account Related Update
  Exec CUSTOMERS.DBO.useCUSTOMERS_UpdateAccountStatus
                         @IPVC_CompanyIDSeq   = @IPVC_CompanyIDSeq,
                         @IPVC_PropertyIDSeq  = NULL,
                         @IPVC_StatusTypecode = @IPVC_StatusTypecode,
                         @IPVC_AccountTypeCode= 'AHOFF',
                         @IPBI_UserIDSeq      = @IPBI_UserIDSeq
  ----------------------------------------------------------------------------
END
GO
