SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_RegAdminGetParametersForClient_Master] (@IPVC_AccountID varchar(50))
AS
BEGIN 
  set nocount on;
  --------------------------------------------
  If EXISTS(Select 1 From CUSTOMERS.dbo.Account Where IDSeq=@IPVC_AccountID)
  Begin
    Declare @AccountType VarChar(5), @CompanyIDSeq VarChar(50), @PropertyIDSeq VarChar(50);
    Select @AccountType=AccountTypeCode, @CompanyIDSeq=CompanyIDSeq, @PropertyIDSeq=PropertyIDSeq
    From CUSTOMERS.dbo.Account with (nolock) Where IDSeq=@IPVC_AccountID
    If @AccountType='AHOFF'
    Begin
      SELECT 
        CMP.StatusTypeCode                                          As Status,
        LEFT(CMP.LegacyRegistrationCode,4)                          As LegacyCode,
        ''                                                          As ParentLegacyCode,
        LEFT(CMP.[Name],30)                                         As Firm_Name,
        ISNULL(LEFT(ADR.AddressLine1,30),'No Address')              As Addr, 
        ISNULL(LEFT(ADR.City,30),'No City')                         As City,
        ISNULL(LEFT(ADR.State,2),'XX')                              As State,
        ISNULL(LEFT(ADR.Zip,5),'XXXXX')                             As Zip, 
        ISNULL(LEFT(REPLACE(REPLACE(REPLACE(REPLACE(ADR.PhoneVoice1,'-',''),')',''),'(',''),' ',''),10),' ')
                                                                    As Phone,
        Convert (VarChar,ISNULL(ACT.StartDate,ACT.CreatedDate),101) As StartDate
      From   CUSTOMERS.dbo.Company CMP with (nolock) 
        JOIN CUSTOMERS.dbo.Address ADR with (nolock) On CMP.IDSeq=ADR.CompanyIDSeq
        JOIN CUSTOMERS.dbo.Account ACT with (nolock) ON ACT.CompanyIDSeq=ADR.CompanyIDSeq
      Where CMP.IDSeq=@CompanyIDSeq 
        And ADR.AddressTypeCode='COM' 
        And CMP.LegacyRegistrationCode Is Not NULL
        And ACT.AccountTypeCode='AHOFF'
    End
    Else
    Begin
      Declare @tblTemp Table (
        StatusTypeCode   VarChar(5),
        LegacyCode       Char(4), 
        ParentLegacyCode Char(4),
        Firm_Name        VarChar(30),
        Addr             VarChar(30),
        City             VarChar(30),
        State            Char(2),
        Zip              VarChar(5),
        Phone            VarChar(10),
        StartDate        DateTime
      )

      INSERT INTO @tblTemp (StatusTypeCode, LegacyCode, Firm_Name, Addr, City, State, Zip, Phone, StartDate)
      Select
        PROP.StatusTypeCode,
        LEFT(PROP.LegacyRegistrationCode,4),
        LEFT(PROP.[Name],30),
        ISNULL(LEFT(ADR.AddressLine1,30),'No Address'), 
        ISNULL(LEFT(ADR.City,30),'No City'),
        ISNULL(LEFT(ADR.State,2),'XX'),
        ISNULL(LEFT(ADR.Zip,5),'XXXXX'), 
        ISNULL(LEFT(REPLACE(REPLACE(REPLACE(REPLACE(ADR.PhoneVoice1,'-',''),')',''),'(',''),' ',''),10),' '),
        Convert (VarChar,ISNULL(ACT.StartDate,ACT.CreatedDate),101)
      From CUSTOMERS.dbo.[Property] PROP with (nolock) 
        JOIN CUSTOMERS.dbo.Address ADR with (nolock) ON ADR.PropertyIDSeq=PROP.IDSeq
        JOIN CUSTOMERS.dbo.Account ACT with (nolock) ON ACT.PropertyIDSeq=PROP.IDSeq
      Where PROP.IDSeq=@PropertyIDSeq 
        And ADR.AddressTypeCode='PRO' 
        And PROP.LegacyRegistrationCode Is Not NULL
        And ACT.AccountTypeCode='APROP'

      UPDATE @tblTemp Set ParentLegacyCode=(Select Top 1 LegacyRegistrationCode From CUSTOMERS.dbo.Company with (nolock) Where IDSeq=@CompanyIDSeq)
      
      Select 
        StatusTypeCode   As Status,
        LegacyCode       As LegacyCode,
        ParentLegacyCode As ParentLegacyCode,
        Firm_Name        As Firm_Name,
        Addr             As Addr,
        City             As City,
        State            As State,
        Zip              As Zip, 
        Phone            As Phone,
        StartDate        As StartDate
      From @tblTemp

    End
  End
END

/*
EXEC [CUSTOMERS].dbo.[uspCUSTOMERS_RegAdminGetParametersForClient_Master] @IPVC_AccountID='A0803000024'
EXEC [CUSTOMERS].dbo.[uspCUSTOMERS_RegAdminGetParametersForClient_Master] @IPVC_AccountID='A0803000025'
*/

GO
