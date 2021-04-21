SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_OwnerUpdate] (
                                                        @IPVC_OwnerIDSeq   varchar(50), 
                                                        @IPVC_Name         varchar(255),                                                        
                                                        @IPVC_AddressLine1 varchar(200), 
                                                        @IPVC_AddressLine2 varchar(200), 
                                                        @IPVC_City         varchar(100), 
                                                        @IPC_State         varchar(2), 
                                                        @IPVC_Zip          varchar(10),
                                                        @IPVC_Country      varchar(30),
                                                        @IPVC_CountryCode  varchar(3) = null,
                                                        @IPBI_UserIDSeq    bigint     --> This is UserID of person logged on and creating this company in OMS.(Mandatory)
                                                  ) 
AS
BEGIN 
  set nocount on;
  ------------------------------------------------------------------
  --                Local Variable Declarations                   --
  ------------------------------------------------------------------
  declare @LDT_SystemDate     datetime
  ------------------------------------------------------------------
  select @LDT_SystemDate      = getdate(),
         @IPVC_Name           = LTRIM(RTRIM(UPPER(@IPVC_Name))),
         @IPVC_AddressLine1   = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_AddressLine1,'')))),
         @IPVC_AddressLine2   = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_AddressLine2,'')))),
         @IPVC_City           = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_City,'')))),
         @IPC_State           = UPPER(LTRIM(RTRIM(NULLIF(@IPC_State,'')))),
         @IPVC_Zip            = LTRIM(RTRIM(NULLIF(@IPVC_Zip,''))),
         @IPVC_Country        = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_Country,'')))),
         @IPVC_CountryCode    = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_CountryCode,''))))         
  ------------------------------------------------------------------
  --Step 1 : Update Owner
  ------------------------------------------------------------------
  Update CUSTOMERS.dbo.Company
  set    Name                = @IPVC_Name,
         ModifiedByIDSeq     = @IPBI_UserIDSeq,
         ModifiedDate        = @LDT_SystemDate,
         SystemLogDate       = @LDT_SystemDate
  where  IDSeq = @IPVC_OwnerIDSeq
  and    (Name <> @IPVC_Name)
  ------------------------------------------------------------------
  --Step 2 : Update/Insert Company Address.
  ------------------------------------------------------------------
  if exists (select top 1 1 
                 from   CUSTOMERS.dbo.Address with (nolock)
                 where  CompanyIdSeq   = @IPVC_OwnerIDSeq
                 and    AddressTypeCode='COM'
                 )
  begin
    Update Customers.dbo.Address
    set    AddressLine1        = @IPVC_AddressLine1,
           AddressLine2        = @IPVC_AddressLine2,
           City                = @IPVC_City,
           State               = @IPC_State,
           Zip                 = @IPVC_Zip,
           Country             = @IPVC_Country,
           CountryCode         = @IPVC_CountryCode,
           ModifiedByIDSeq     = @IPBI_UserIDSeq,
           ModifiedDate        = @LDT_SystemDate,
           SystemLogDate       = @LDT_SystemDate 
    where  CompanyIDSeq  = @IPVC_OwnerIDSeq
    and    AddressTypeCode = 'COM'
    and    PropertyIDSeq is null
  end
  else
  begin
    Insert into Customers.dbo.Address(CompanyIDSeq,PropertyIDSeq,AddressTypeCode,
                                      AddressLine1,AddressLine2,City,State,Zip,
                                      Country,CountryCode,
                                      CreatedByIDSeq,CreatedDate,SystemLogDate)
      select @IPVC_OwnerIDSeq as CompanyIDSeq,NULL as PropertyIDSeq,'COM' as AddressTypeCode,
             @IPVC_AddressLine1 as AddressLine1,@IPVC_AddressLine2  as AddressLine2,@IPVC_City as City,@IPC_State as State,@IPVC_Zip as Zip,          
             @IPVC_Country  as Country,@IPVC_CountryCode as CountryCode,
             @IPBI_UserIDSeq as  CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
      where (len(@IPVC_AddressLine1) > 0 and len(@IPVC_City) > 0)
  end
END
GO
