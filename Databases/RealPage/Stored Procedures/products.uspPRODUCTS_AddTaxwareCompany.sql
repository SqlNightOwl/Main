SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_AddTaxwareCompany
-- Description     : This proc is called by Product Administration TaxwareCompany Management to Add New TaxwareCompany(s)
-- Input Parameters: @IPVC_TaxwareCompanyCode,@IPVC_TaxwareCompanyName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_AddTaxwareCompany 
                       @IPVC_TaxwareCompanyCode = '12'                --> This is the new TaxwareCompanycode 
                      ,@IPVC_TaxwareCompanyName = 'Abc Test'          --> This is the new TaxwareCompanyName 
                      ,@IPVC_TaxwareCompanyDescription =  'Abc Test'  --> This is the new TaxwareCompanyDescription                 
                      ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxwareCompany Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_AddTaxwareCompany]  (@IPVC_TaxwareCompanyCode          varchar(20),     ---->MANDATORY : This is the upto 3 character Unique TaxwareCompany Code for adding new TaxwareCompany
                                                         @IPVC_TaxwareCompanyName          varchar(70),     ---->MANDATORY : This is TaxwareCompany Name for the new TaxwareCompany 
                                                         @IPVC_TaxwareCompanyDescription   varchar(100)='', ---->OPTIONAL  : This is Product Type Description. Default is same as Product Type Name                                                       
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
          @LDT_SystemDate                 = Getdate();
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
  --Validation 2: @IPVC_TaxwareCompanyCode or @IPVC_TaxwareCompanyName should be unique and should not already exists
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.TaxwareCompany TC with (nolock)
             where   (TC.TaxwareCompanyCode = @IPVC_TaxwareCompanyCode)
            )
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Code already exists in the system. TaxwareCompany Code should be unique for new TaxwareCompany additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.TaxwareCompany PT with (nolock)
             where   (PT.Name = @IPVC_TaxwareCompanyName)
            )
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Name already exists in the system. TaxwareCompany Name should be unique for new TaxwareCompany additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if (not exists (select  Top 1 1
                  from    PRODUCTS.dbo.TaxwareCompany TC with (nolock)
                  where   (TC.TaxwareCompanyCode = @IPVC_TaxwareCompanyCode)                  
                 )
         AND
      not exists (select  Top 1 1
                  from    PRODUCTS.dbo.TaxwareCompany TC with (nolock)
                  where   (TC.Name = @IPVC_TaxwareCompanyName)
                 )
     )
  begin
    Insert into Products.dbo.TaxwareCompany(TaxwareCompanyCode,Name,Description,CreatedByIDSeq,CreatedDate,SystemLogDate)
    select @IPVC_TaxwareCompanyCode as Code,@IPVC_TaxwareCompanyName as Name,coalesce(@IPVC_TaxwareCompanyDescription,@IPVC_TaxwareCompanyName) as Description,           
           @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate;
  end
  ------------------------------------------
END--> Main End
GO
