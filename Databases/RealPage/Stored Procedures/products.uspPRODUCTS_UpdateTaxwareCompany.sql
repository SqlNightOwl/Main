SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_UpdateTaxwareCompany
-- Description     : This proc is called by Product Administration TaxwareCompany Management to Update Existing TaxwareCompanys
-- Input Parameters: @IPVC_TaxwareCompanyCode,@IPVC_TaxwareCompanyName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_UpdateTaxwareCompany 
                       @IPVC_TaxwareCompanyCode = 'RACK'  --> This is the existing TaxwareCompanycode 
                      ,@IPVC_TaxwareCompanyName = 'Rack1' --> This is the new updated TaxwareCompanyName This is used for PPC Report Primary Product listing. (important) 0 or 1 from checkbox
                      ,@IPI_PPCReportPrimaryProductFlag = 0
                      ,@IPBI_UserIDSeq    = 76
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxwareCompany Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_UpdateTaxwareCompany]  (@IPVC_TaxwareCompanyCode          varchar(10),      ---->MANDATORY : This is the upto 3 character Unique TaxwareCompany Code of existing TaxwareCompany
                                                            @IPVC_TaxwareCompanyName          varchar(70),      ---->MANDATORY : This is new TaxwareCompany Name for the existing TaxwareCompany
                                                            @IPVC_TaxwareCompanyDescription   varchar(100)='',  ---->OPTIONAL  : This is Product Type Description. Default is same as Product Type Name                                                        
                                                            @IPBI_UserIDSeq                   bigint= -1       ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                           )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_TaxwareCompanyCode        = UPPER(NullIf(ltrim(rtrim(@IPVC_TaxwareCompanyCode)),'')),
          @IPVC_TaxwareCompanyName        = NullIf(ltrim(rtrim(@IPVC_TaxwareCompanyName)),''),
          @IPVC_TaxwareCompanyDescription = NullIf(NullIf(ltrim(rtrim(@IPVC_TaxwareCompanyDescription)),'0'),''),
          @LDT_SystemDate              = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_TaxwareCompanyCode or @IPVC_TaxwareCompanyName cannot be blank or null
  If (@IPVC_TaxwareCompanyCode is null)
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  if len(@IPVC_TaxwareCompanyCode) > 10
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Code cannot be more than 10 characters';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  If (@IPVC_TaxwareCompanyName is null)
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Name cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  --Validation 2: @IPVC_TaxwareCompanyName should be unique and should not already exists
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.TaxwareCompany TC with (nolock)
             where   (TC.Name =  @IPVC_TaxwareCompanyName)
             and     (TC.TaxwareCompanyCode <> @IPVC_TaxwareCompanyCode)   
            )
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Name already exists for a different TaxwareCompany Code in the system. TaxwareCompany Name should be unique.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.TaxwareCompany TC with (nolock)
             where   (TC.TaxwareCompanyCode =  @IPVC_TaxwareCompanyCode) 
             and     (
                      (TC.Name        <> @IPVC_TaxwareCompanyName)
                         OR
                      (TC.Description <> coalesce(@IPVC_TaxwareCompanyDescription,@IPVC_TaxwareCompanyName))                        
                     )
            )
  begin
    Update TC
    set    TC.Name            = @IPVC_TaxwareCompanyName
          ,TC.Description     = coalesce(@IPVC_TaxwareCompanyDescription,@IPVC_TaxwareCompanyName)         
          ,TC.ModifiedByIdSeq = @IPBI_UserIDSeq
          ,TC.ModifiedDate    = @LDT_SystemDate 
          ,TC.SystemLogDate   = @LDT_SystemDate
    from  PRODUCTS.dbo.TaxwareCompany TC with (nolock)
    where (TC.TaxwareCompanyCode =  @IPVC_TaxwareCompanyCode) 
    and   (
           (TC.Name        <> @IPVC_TaxwareCompanyName)
                OR
           (TC.Description <> coalesce(@IPVC_TaxwareCompanyDescription,@IPVC_TaxwareCompanyName))                        
          )         
  end
  ------------------------------------------
END--> Main End
GO
