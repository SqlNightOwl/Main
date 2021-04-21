SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCTS_AddFamily
-- Description     : This proc is called by Product Administration Family Management to Add New Family
-- Input Parameters: @IPVC_FamilyCode,@IPVC_FamilyName
-- Returns         : None
--                   If validation error is returned, UI will have to trap it 
--                     and log it customers.dbo.Errorlog table and also show to User in UI



-- Code Example    : 
/*
Exec PRODUCTS.dbo.uspPRODUCTS_AddFamily 
                       @IPVC_FamilyCode = 'NFM'  --> This is the new Familycode 
                      ,@IPVC_FamilyName = 'New Family'  --> This is the new FamilyName 
                      ,@IPVC_FamilyDescription ='New Family Description' --> This is new FamilyDescription 
                      ,@IPVC_FamilyEpicorPostingCode = 'RPI'
                      ,@IPVC_FamilyTaxwareCompanyCode= '01'
                      ,@IPVC_FamilyBusinessUnitLogo  = 'RealPage'
                      ,@IPI_PrintFamilyNoticeFlag    = 0
                      ,@IPBI_UserIDSeq                = 123
*/


-- Revision History:
-- Author          : SRS
-- 09/27/2011      : Stored Procedure Created. TFS 701 (Product Administration Family Management)
------------------------------------------------------------------------------------------------------
Create PROCEDURE [products].[uspPRODUCTS_AddFamily]  (@IPVC_FamilyCode                 varchar(10),              ---->MANDATORY : This is the upto 3 character Unique Family Code for adding new Family
                                                 @IPVC_FamilyName                 varchar(50),              ---->MANDATORY : This is Family Name for the new Family 
                                                 @IPVC_FamilyDescription          varchar(100)='',          ---->OPTIONAL  : This is Family Description. Default is same as Family Name
                                                 @IPVC_FamilyEpicorPostingCode    varchar(10) = 'RPI',      ---->MANDATORY : This is EpicorPostingCode for Family. RPI or ALW or YUK etc (UI Default is RPI)
                                                 @IPVC_FamilyTaxwareCompanyCode   varchar(10) = '01' ,      ---->MANDATORY : This is TaxwareCompanyCode for Family. 01 or 08 or 11 etc (UI Default 01)
                                                 @IPVC_FamilyBusinessUnitLogo     varchar(50) = 'RealPage', ---->MANDATORY : This is business unit log for the family. RealPage or ALWizard or Domin-8CANADA etc. (UI default RealPage)
                                                 @IPI_PrintFamilyNoticeFlag       int         = 0,          ---->MANDATORY : This is only for Special families like Domin-8 USA where extra addendum goes with corresponding Family Invoice.
                                                                                                            ---              Only Domin-8 USA has this setting turned on as 1 for now.
                                                                                                            ---              For all other families, the default is 0
                                                 @IPBI_UserIDSeq                  bigint= -1                ---->MANDATORY : UI will pass UserId of the person doing the operation
                                                )
as
BEGIN --> Main Begin
  set nocount on; 
  ------------------------------------------
  declare @LDT_SystemDate  datetime,
          @LVC_CodeSection varchar(500),
          @LI_SortSeq      int; 
 
  select  @IPVC_FamilyCode              = UPPER(NullIf(ltrim(rtrim(@IPVC_FamilyCode)),'')),
          @IPVC_FamilyName              = NullIf(ltrim(rtrim(@IPVC_FamilyName)),''),
          @IPVC_FamilyDescription       = NullIf(NullIf(ltrim(rtrim(@IPVC_FamilyDescription)),'0'),''),  
          @IPVC_FamilyEpicorPostingCode = NullIf(ltrim(rtrim(@IPVC_FamilyEpicorPostingCode)),''), 
          @IPVC_FamilyTaxwareCompanyCode= NullIf(ltrim(rtrim(@IPVC_FamilyTaxwareCompanyCode)),''), 
          @IPVC_FamilyBusinessUnitLogo  = NullIf(ltrim(rtrim(@IPVC_FamilyBusinessUnitLogo)),''),
          @LDT_SystemDate   = Getdate();
  ------------------------------------------
  --Validation 1 : @IPVC_FamilyCode or @IPVC_FamilyName cannot be blank or null
  If (@IPVC_FamilyCode is null)
  begin
    select @LVC_CodeSection = 'Error: Family Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  If ( (isnumeric(@IPVC_FamilyCode) = 1) 
            OR 
       (PATINDEX('%[^A-Z]%',@IPVC_FamilyCode) > 0)
     )
  begin
    select @LVC_CodeSection = 'Error: Family Code cannot be numeric or alpha numeric.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if len(@IPVC_FamilyCode) > 3
  begin
    select @LVC_CodeSection = 'Error: Family Code cannot be more than 3 characters';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  If (@IPVC_FamilyName is null)
  begin
    select @LVC_CodeSection = 'Error: Family Name cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  If (@IPVC_FamilyEpicorPostingCode is null)
  begin
    select @LVC_CodeSection = 'Error: Epicor Posting Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  if len(@IPVC_FamilyEpicorPostingCode) < 3
  begin
    select @LVC_CodeSection = 'Error: Epicor Posting Code cannot be less than 3 characters';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  If (@IPVC_FamilyTaxwareCompanyCode is null)
  begin
    select @LVC_CodeSection = 'Error: Taxware Company Code cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  If (@IPVC_FamilyBusinessUnitLogo is null)
  begin
    select @LVC_CodeSection = 'Error: BusinessUnitLogo for Family cannot be blank.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if (@IPI_PrintFamilyNoticeFlag not in (0,1))
  begin
    select @LVC_CodeSection = 'Error: Print Family Notice Flag to add addendum with Invoice(s) for specific Family can only be 1 for YES or 0 for No.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if Not exists (select Top 1 1
                 from   OMSREPORTS.dbo.araccts ACT with (nolock)
                 where  ACT.posting_code = @IPVC_FamilyEpicorPostingCode
                )
  begin
    select @LVC_CodeSection = 'Error: Epicor Posting Code is not found or set up yet in Araccts in Epicor. Please Set up Epicor Posting Code first for this code before using this Posting Code for this family.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if Not exists (select Top 1 1
                 from   Products.dbo.TaxwareCompany TC with (nolock)
                 where  TC.TaxwareCompanyCode = @IPVC_FamilyTaxwareCompanyCode
                )
  begin
    select @LVC_CodeSection = 'Error: Taxware Company is not found or set up yet. Please Set up Taxware Company first for this code before using this new TaxwareCompanyCode.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end

  if Not exists (select Top 1 1
                 from   Products.dbo.TaxableCountry TAXC with (nolock)
                 where  TAXC.TaxwareCompanyCode = @IPVC_FamilyTaxwareCompanyCode
                )
  begin
    select @LVC_CodeSection = 'Error: Taxable Country is not found or set up yet for this TaxwareCompanyCode. Please Set up Taxable Country first for this code before using this new TaxwareCompanyCode.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  --Validation 2: @IPVC_FamilyCode or @IPVC_FamilyName should be unique and should not already exists
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Family FM with (nolock)
             where   (FM.Code = @IPVC_FamilyCode)
            )
  begin
    select @LVC_CodeSection = 'Error: Family Code already exists in the system. Family Code should be unique for new Family additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  if exists (select  Top 1 1
             from    PRODUCTS.dbo.Family FM with (nolock)
             where   (FM.Name = @IPVC_FamilyName)
            )
  begin
    select @LVC_CodeSection = 'Error: Family Name already exists in the system. Family Name should be unique for new Family additions.';
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection;
    return;
  end
  ------------------------------------------
  if (not exists (select  Top 1 1
                  from    PRODUCTS.dbo.Family FM with (nolock)
                  where   (FM.Code = @IPVC_FamilyCode)                  
                 )
         AND
      not exists (select  Top 1 1
                  from    PRODUCTS.dbo.Family FM with (nolock)
                  where   (FM.Name = @IPVC_FamilyName)
                 )
     )
  begin
    select @LI_SortSeq = Max(FM.SortSeq)+ 10 from PRODUCTS.dbo.Family FM with (nolock)

    Insert into Products.dbo.Family(Code,Name,Description,EpicorPostingCode,TaxwareCompanyCode,BusinessUnitLogo,PrintFamilyNoticeFlag,
                                    SortSeq,CreatedByIDSeq,CreatedDate,SystemLogDate)
    select @IPVC_FamilyCode as Code,@IPVC_FamilyName as Name,coalesce(@IPVC_FamilyDescription,@IPVC_FamilyName) as Description,
           @IPVC_FamilyEpicorPostingCode as  EpicorPostingCode,@IPVC_FamilyTaxwareCompanyCode as TaxwareCompanyCode,
           @IPVC_FamilyBusinessUnitLogo  as BusinessUnitLogo,@IPI_PrintFamilyNoticeFlag as PrintFamilyNoticeFlag,
           @LI_SortSeq as SortSeq,
           @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate;
  end
  ------------------------------------------
END--> Main End
GO
