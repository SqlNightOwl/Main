SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_DeleteTaxwareCompany
-- Description     : This proc is called by Product Administration TaxwareCompany Management to an Existing TaxwareCompany
-- Input Parameters: @IPVC_TaxwareCompanyCode
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_DeleteTaxwareCompany 
                          @IPVC_TaxwareCompanyCode = 'ABC'  ---> This is the existing TaxwareCompany that is to be deleted
                         ,@IPBI_UserIDSeq    = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration TaxwareCompany Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_DeleteTaxwareCompany]  (@IPVC_TaxwareCompanyCode    varchar(10),     ---->MANDATORY : This is the upto 6 character Unique TaxwareCompany Code of existing TaxwareCompany                                                                                                                                           
                                                            @IPBI_UserIDSeq             bigint= -1      ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                           )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500); 
 
  select  @IPVC_TaxwareCompanyCode = UPPER(NullIf(ltrim(rtrim(@IPVC_TaxwareCompanyCode)),'')),
          @LDT_SystemDate          = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_TaxwareCompanyCode cannot be blank or null
  If (@IPVC_TaxwareCompanyCode is null)
  begin
    select @LVC_CodeSection = 'Error: TaxwareCompany Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end  
  ------------------------------------------
  --Validation 2: @IPVC_TaxwareCompanyCode should not be referenced by any Product Charge irrespective of Version
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Family FM with (nolock)
             where   FM.TaxwareCompanyCode = @IPVC_TaxwareCompanyCode
            )
  begin
    select @LVC_CodeSection = 'Error: Taxware Company Code is actively referenced by atleast one Family record. TaxwareCompany cannot be deleted.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 3: @IPVC_TaxwareCompanyCode should not be referenced by any Diverse TaxwareCompany for Account
  --              BL to be filled in when that piece is done down the road. 
  ------------------------------------------
  Delete TC
  from   PRODUCTS.dbo.TaxwareCompany TC with (nolock)
  where  (TC.TaxwareCompanyCode =  @IPVC_TaxwareCompanyCode);  
  ------------------------------------------
END--> Main End
GO
