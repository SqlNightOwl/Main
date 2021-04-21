SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [customers].[uspCUSTOMERS_ContactInsert] (
                                                    @CompanyID              varchar(50), 
                                                    @Title                  varchar(20),
                                                    @FirstName              varchar(100),
                                                    @LastName               varchar(100), 
                                                    @ContactTypeCode        varchar(10), 
                                                    @PhoneVoice1            varchar(50),
                                                    @PhoneVoiceExt1         varchar(10), 
                                                    @PhoneFax               varchar(50),
                                                    @Email                  varchar(100),
                                                    @AddressLine1           varchar(200),
                                                    @AddressLine2           varchar(100),
                                                    @City                   varchar(70),
                                                    @State                  char(2),
                                                    @Zip                    varchar(10),
                                                    @SameAsPMCAddressFlag   bit=0,
                                                    @Longitude              decimal(18,6),
                                                    @Latitude               decimal(18,6),
                                                    @MSANumber              varchar(10),
                                                    @Country                varchar(30),
                                                    @CountryCode            varchar(3),
                                                    @IPBI_UserIDSeq         bigint     --> This is UserID of person logged on and creating this company in OMS.(Mandatory)
                                                   )     
AS
BEGIN 
  set nocount on;
  ------------------------------------------------------------------
  --                Local Variable Declarations                   --
  ------------------------------------------------------------------
  declare @LDT_SystemDate     datetime
  declare @addressidseq       INT
  declare @LVC_UserName       varchar(255)
  ------------------------------------------------------------------
  select @LDT_SystemDate      = getdate(),
         @Title               = UPPER(LTRIM(RTRIM(NULLIF(@Title,'')))),
         @FirstName           = LTRIM(RTRIM(UPPER(@FirstName))),
         @LastName            = LTRIM(RTRIM(UPPER(@LastName))),
         @PhoneVoice1         = UPPER(LTRIM(RTRIM(NULLIF(@PhoneVoice1,'')))),
         @PhoneVoiceExt1      = UPPER(LTRIM(RTRIM(NULLIF(@PhoneVoiceExt1,'')))),
         @PhoneFax            = UPPER(LTRIM(RTRIM(NULLIF(@PhoneFax,'')))),
         @Email               = UPPER(LTRIM(RTRIM(NULLIF(@Email,'')))),
         @AddressLine1        = UPPER(LTRIM(RTRIM(NULLIF(@AddressLine1,'')))),
         @AddressLine2        = UPPER(LTRIM(RTRIM(NULLIF(@AddressLine2,'')))),
         @City                = UPPER(LTRIM(RTRIM(NULLIF(@City,'')))),
         @State               = UPPER(LTRIM(RTRIM(NULLIF(@State,'')))),
         @Zip                 = LTRIM(RTRIM(NULLIF(@Zip,''))),
         @Country             = UPPER(LTRIM(RTRIM(NULLIF(@Country,'')))),
         @CountryCode         = UPPER(LTRIM(RTRIM(NULLIF(@CountryCode,'')))),
         @MSANumber           = LTRIM(RTRIM(NULLIF(@MSANumber,'')))
  ------------------------------------------------------------------
  ---Step 1 : Insert Contact Address
  ------------------------------------------------------------------
  insert into Customers.dbo.Address(CompanyIDSeq,PropertyIDSeq,AddressTypeCode,SameAsPMCAddressFlag,
                                    AddressLine1,AddressLine2,City,State,Zip,
                                    PhoneVoice1,PhoneVoiceExt1,PhoneFax,Email,
                                    Latitude,Longitude,MSANumber,
                                    Country,CountryCode,
                                    CreatedByIDSeq,CreatedDate,SystemLogDate)
  select @CompanyID as CompanyIDSeq,NULL as PropertyIDSeq,'CON' as AddressTypeCode,@SameAsPMCAddressFlag as SameAsPMCAddressFlag,
         @AddressLine1 as AddressLine1,@AddressLine2  as AddressLine2,@City as City,@State as State,@Zip as Zip,  
         @PhoneVoice1 as PhoneVoice1,@PhoneVoiceExt1 as PhoneVoiceExt1,@PhoneFax as PhoneFax,@Email as Email,
         @Longitude as Latitude,@Longitude  as Longitude,@MSANumber as MSANumber,
         @Country  as Country,@CountryCode as CountryCode,
         @IPBI_UserIDSeq as  CreatedByIDSeq,@LDT_SystemDate as CreatedDate,@LDT_SystemDate as SystemLogDate

  select @AddressIDSeq = SCOPE_IDENTITY()
  ------------------------------------------------------------------
  --Step 2: Insert Contact
  ------------------------------------------------------------------
  select @LVC_UserName = U.FirstName + ' ' + U.LastName
  from   Security.dbo.[User] U with (nolock)
  where  U.IDSeq = @IPBI_UserIDSeq

  INSERT INTO Contact(CompanyIDSeq,ContactTypeCode,FirstName,LastName, 
                      AddressIDSeq,Salutation,Title,CreatedBy,CreateDate,ContactEmail
                      )
  select @CompanyID as CompanyIDSeq,@ContactTypeCode as ContactTypeCode,@FirstName as FirstName,@LastName as LastName,
         @AddressIDSeq as  AddressIDSeq, '' as Salutation,@Title as Title,
         @LVC_UserName as CreatedBy,@LDT_SystemDate as CreateDate,@Email as ContactEmail
  ------------------------------------------------------------------
END
GO
