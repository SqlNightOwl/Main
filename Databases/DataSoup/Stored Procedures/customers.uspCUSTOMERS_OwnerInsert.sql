SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_OwnerInsert
-- Description     : This procedure inserts a Owner Record.
-- Input Parameters: 1. @IPVC_CompanyIDSeq varchar(11),
--                   2. @IPVC_Name varchar(100),
--                   3. @IPVC_CreatedBy varchar(70),
--                   4. @IPVC_AddressLine1 varchar(200),
--                   5. @IPVC_AddressLine2 varchar(100),
--                   6. @IPVC_City varchar(70),
--                   7. @IPC_State char(2),
--                   8. @IPVC_Zip varchar(10)
-- 
-- Code Example    : Exec CUSTOMERS.DBO.uspCUSTOMERS_OwnerInsert  
--                      @IPVC_CompanyIDSeq = 'A0000000001',
--                      @IPVC_Name = 'New Customer',
--                      @IPVC_CreatedBy 'SRA_OMS',
--                      @IPVC_AddressLine1 'Address Line 1',
--                      @IPVC_AddressLine2 'Address Line 2',
--                      @IPVC_City 'DALLAS',
--                      @IPC_State = 'CO',
--                      @IPVC_Zip = '12345'
-- 
-- Revision History:
-- Author          : STA, SRA Systems Limited.
-- 03/12/2007      : Stored Procedure Created.
-- 05/31/2011      : STH  TFS 647 to Identify migrated companies.
-- 08/29/2011````` : Mahaboob TFS-687 Update MultiFamilyFlag and PMCFlag as 0  when Owner record Inserted or Updated
----------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_OwnerInsert] 
                                                  (@IPVC_CompanyIDSeq   varchar(50),
                                                   @IPVC_Name           varchar(100),
                                                   @IPVC_AddressLine1   varchar(200),
                                                   @IPVC_AddressLine2   varchar(100),
                                                   @IPVC_City           varchar(70),
                                                   @IPC_State           varchar(2),
                                                   @IPVC_Zip            varchar(10),
                                                   @Longitude           decimal(18,6),
                                                   @Latitude            decimal(18,6),
                                                   @MSANumber           varchar(50),
                                                   @IPVC_Country        varchar(30),
                                                   @IPVC_CountryCode    varchar(3) = null,
                                                   @IPBI_UserIDSeq      bigint,    --> This is UserID of person logged on and creating this company in OMS.(Mandatory)
												   @Migration           bit   = 0  --> This flag if set true will skip the call to get Legacy Registration Code     
                                                  )
	
	
AS
BEGIN
  set nocount on;
  ------------------------------------------------------------------
  --                Local Variable Declarations                   --
  ------------------------------------------------------------------
  declare @LDT_SystemDate     datetime
  declare @LVC_RegCode        varchar(4)
  declare @LVC_OwnerIDSeq     VARCHAR(50)
  declare @LVC_CodeSection     varchar(1000)  
  ------------------------------------------------------------------
  select @LDT_SystemDate      = getdate(),
         @IPVC_Name           = LTRIM(RTRIM(UPPER(@IPVC_Name))),
         @IPVC_AddressLine1   = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_AddressLine1,'')))),
         @IPVC_AddressLine2   = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_AddressLine2,'')))),
         @IPVC_City           = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_City,'')))),
         @IPC_State           = UPPER(LTRIM(RTRIM(NULLIF(@IPC_State,'')))),
         @IPVC_Zip            = LTRIM(RTRIM(NULLIF(@IPVC_Zip,''))),
         @IPVC_Country        = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_Country,'')))),
         @IPVC_CountryCode    = UPPER(LTRIM(RTRIM(NULLIF(@IPVC_CountryCode,'')))),
         @MSANumber           = LTRIM(RTRIM(NULLIF(@MSANumber,'')))
  ------------------------------------------------------------------
  BEGIN TRY
    BEGIN TRANSACTION OWN;  
      ---------------------------------------------------------------------------------
      --Step 1 : get unique New CompanyID generated for this Brand New Company Creation
      ---------------------------------------------------------------------------------
      update CUSTOMERS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
      set    IDSeq = IDSeq+1,
             GeneratedDate =CURRENT_TIMESTAMP 
      where  TypeIndicator = 'C'

      select @LVC_OwnerIDSeq = IDGeneratorSeq
      from   CUSTOMERS.DBO.IDGenerator with (NOLOCK)  
      where  TypeIndicator = 'C'
      ---------------------------------------------------------------------------------
      --Step 2 : get unique Registration Code for New Company      
	  if @Migration = 0     --TFS 647
         EXEC CUSTOMERS.dbo.uspCUSTOMERS_GetLegacyRegistrationCode @LVC_RegCode output
      ---------------------------------------------------------------------------------
      --Step 3: Insert Owner Record.
      ---------------------------------------------------------------------------------
      Insert into Customers.dbo.Company (IDSeq,Name,StatusTypecode,
                                         PMCFlag,OwnerFlag,MultiFamilyFlag,
                                         LegacyRegistrationCode,
                                         CreatedByIDSeq,CreatedDate,SystemLogDate
                                        )
      select @LVC_OwnerIDSeq as IDSeq,@IPVC_Name as [Name],'ACTIV' as StatusTypecode,
             0 as PMCFlag,1 as OwnerFlag,0 as MultiFamilyFlag, @LVC_RegCode as LegacyRegistrationCode,
             @IPBI_UserIDSeq as CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
             
      ---------------------------------------------------------------------------------
      --Step 4: Insert CustomerOwner Record.
      ---------------------------------------------------------------------------------
      Insert into Customers.dbo.CustomerOwner(CustomerIDSeq,OwnerIDSeq)
      select @IPVC_CompanyIDSeq as CustomerIDSeq,@LVC_OwnerIDSeq as OwnerIDSeq
      ---------------------------------------------------------------------------------
      --Step 5: Insert Address Record.
      ---------------------------------------------------------------------------------
      Insert into Customers.dbo.Address(CompanyIDSeq,PropertyIDSeq,AddressTypeCode,
                                        AddressLine1,AddressLine2,City,State,Zip,
                                        Latitude,Longitude,MSANumber,
                                        Country,CountryCode,
                                        CreatedByIDSeq,CreatedDate,SystemLogDate)
      select @LVC_OwnerIDSeq as CompanyIDSeq,NULL as PropertyIDSeq,'COM' as AddressTypeCode,
             @IPVC_AddressLine1 as AddressLine1,@IPVC_AddressLine2  as AddressLine2,@IPVC_City as City,@IPC_State as State,@IPVC_Zip as Zip,          
             @Longitude as Latitude,@Longitude  as Longitude,@MSANumber as MSANumber,
             @IPVC_Country  as Country,@IPVC_CountryCode as CountryCode,
             @IPBI_UserIDSeq as  CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate
      where (len(@IPVC_AddressLine1) > 0 and len(@IPVC_City) > 0)
      ---------------------------------------------------------------------------------
    COMMIT TRANSACTION OWN; 
  END TRY
  BEGIN CATCH
    -- XACT_STATE:
    -- If 1, the transaction is committable.
    -- If -1, the transaction is uncommittable and should be rolled back.
    -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OWN;
    end
    else if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION OWN;
    end 
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION OWN;   
    ------------------------      
    select @LVC_CodeSection =  'Proc :uspCUSTOMERS_OwnerInsert;Error Creating Owner Record For: '+ @IPVC_Name
    ------------------------
    select '-1' as OwnerIDSeq     
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return;                  
  END CATCH; 
  -------------------------------------------------------------------------------
  ---Final Return to UI
  -------------------------------------------------------------------------------
  select @LVC_OwnerIDSeq as OwnerIDSeq
  -------------------------------------------------------------------------------
END
GO
