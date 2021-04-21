SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : uspCUSTOMERS_ContactUpdate
-- Description     : This procedure gets Order Details pertaining to passed 
--                        CustomerName,City,State,ZipCode,PropertyID and StatusType
-- Input Parameters:   @ContactID        as   varchar
--                     @CompanyID        as   varchar
--                     @FirstName        as   varchar
--                     @LastName         as   varchar
--                     @AddressLine1     as   varchar
--                     @AddressLine2     as   varchar            
--                     @City             as   varchar
--                     @State            as   char
--                     @Zip              as   varchar
--                     @ContactTypeCode  as   varchar
--                     @PhoneVoice1      as   varchar
--                     @PhoneVoiceExt1   as   varchar  
--                     @PhoneFax         as   varchar
--                     @Email            as   varchar
--                     @AddrID           as   varchar
--                     @Title             as   char
-- 
-- OUTPUT          : updates the Customers..Address and Customers..Contact
-- Code Example    : Exec CUSTOMERS.dbo.[uspCUSTOMERS_ContactUpdate]
--                     @ContactID        =    '11'
--                     @CompanyID        =   'A0000004078'
--                     @FirstName        =   '4000 NORTH'
--                     @LastName         =   ''
--                     @AddressLine1     =   '1815 N BOOMER RD'
--                     @AddressLine2     =   'STILLWATER'
--                     @City             =   'STILLWATER'
--                     @State             =   'OK'
--                     @Zip              =   '74075-3402'
--                     @ContactTypeCode  =   
--                     @PhoneVoice1      =   '4053728545'
--                     @PhoneFax         =   '405-372-8809'
--                     @Email            =   'north@gmail.com'
--                     @AddrID           =   '1'
--                     @Title             =   ''
	
-- Revision History:
-- Author          : RP
-- 11/25/2006      : Stored Procedure Created.
-- 12/20/2006      : Changed by Naval KISHORE Changed Variable Names, added variables
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ContactUpdate] (@ContactID       varchar(50), 
                                                     @CompanyID       varchar(50), 
                                                     @FirstName       varchar(100),
                                                     @LastName        varchar(100),
                                                     @AddressLine1    varchar(200),
                                                     @AddressLine2    varchar(100),
                                                     @City            varchar(70),
                                                     @State           char(2),
                                                     @Zip             varchar(10),
                                                     @ContactTypeCode varchar(10),
                                                     @PhoneVoice1     varchar(50),
                                                     @PhoneVoiceExt1  varchar(10), 
                                                     @PhoneFax        varchar(50), 
                                                     @Email           varchar(100),
                                                     @AddrID          varchar(10),
                                                     @Title           char(20),
                                                     @chkSameAsPMC    bit=0,
                                                     @Longitude       decimal(18,6),
                                                     @Latitude        decimal(18,6),
                                                     @MSANumber       varchar(10),
                                                     @Country         varchar(30),
                                                     @CountryCode     varchar(3) = null,
                                                     @IPBI_UserIDSeq  bigint     --> This is UserID of person logged on and creating this company in OMS.(Mandatory)
                                                    )  
AS
BEGIN 
  set nocount on;
  ------------------------------------------------------------------
  --                Local Variable Declarations                   --
  ------------------------------------------------------------------
  declare @LDT_SystemDate     datetime
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
  --Step 1 : Update Contact Address 
  ------------------------------------------------------------------
  UPDATE CUSTOMERS.dbo.Address
  SET    PhoneVoice1     =   @PhoneVoice1,
         PhoneVoiceExt1  =   @PhoneVoiceExt1, 
         PhoneFax        =   @PhoneFax, 
         Email           =   @Email,
         AddressLine1    =   @AddressLine1,
         AddressLine2    =   @AddressLine2,
         City            =   @City,
         State           =   @State,
         Zip             =   @Zip,         
         SameAsPMCAddressFlag = @chkSameAsPMC,
         Latitude        =   @Latitude,
         Longitude       =   @Longitude,
         MSANumber       =   @MSANumber,
         Country         =   @Country,
         CountryCode     =   @CountryCode,
         ModifiedByIDSeq =   @IPBI_UserIDSeq,
         ModifiedDate    =   @LDT_SystemDate,
         SystemLogDate   =   @LDT_SystemDate
  WHERE  IDSeq           =   @AddrID
  and    CompanyIDSeq    =   @CompanyID
  and    AddresstypeCode =   'CON'
  ------------------------------------------------------------------
  --Step 1 : Update Contact Address 
  ------------------------------------------------------------------
  select @LVC_UserName = U.FirstName + ' ' + U.LastName
  from   Security.dbo.[User] U with (nolock)
  where  U.IDSeq = @IPBI_UserIDSeq

 
  UPDATE Contact
  SET    ContactTypeCode =   @ContactTypeCode, 
         FirstName       =   @FirstName, 
         LastName        =   @LastName,
         Title           =   @Title,         
         ContactEmail    =   @Email,
         ModifiedBy      =   @LVC_UserName,
         ModifiedDate    =   @LDT_SystemDate
  WHERE  IDSeq           =   @ContactID
  ------------------------------------------------------------------
END
GO
