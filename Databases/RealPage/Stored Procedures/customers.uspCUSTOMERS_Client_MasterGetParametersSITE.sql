SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_Client_MasterGetParametersSITE] (@IPVC_CompanyID varchar(11), @IPVC_PropertyID varchar(11))
AS
BEGIN 
  -- ACCOUNT MUST exist in the Account table
  If EXISTS(Select 1 From CUSTOMERS.dbo.Account Where CompanyIDSeq=@IPVC_CompanyID And PropertyIDSeq=@IPVC_PropertyID And AccountTypeCode='APROP')
  Begin
    Declare @tblTemp Table (
      Code Char(4), 
      ParentCode Char(4),
      Firm_Name VarChar(30),
      Addr VarChar(30),
      City VarChar(30),
      State Char(2),
      Zip VarChar(5),
      Phone VarChar(10),
      StartDate DateTime
    )

    INSERT INTO @tblTemp (Code,Firm_Name,Addr,City,State,Zip,Phone,StartDate)
    Select
      LEFT(PROP.LegacyRegistrationCode,4)                         As Code,
      LEFT(PROP.[Name],30)                                        As Firm_Name,
      ISNULL(LEFT(ADR.AddressLine1,30),'No Address')              As Addr, 
      ISNULL(LEFT(ADR.City,30),'No City')                         As City,
      ISNULL(LEFT(ADR.State,2),'XX')                              As State,
      ISNULL(LEFT(ADR.Zip,5),'XXXXX')                             As Zip, 
      ISNULL(LEFT(ADR.PhoneVoice1,10),' ')                        As Phone,
      Convert (VarChar,ISNULL(ACT.StartDate,ACT.CreatedDate),101) As StartDate
    From CUSTOMERS.dbo.[Property] PROP 
      JOIN CUSTOMERS.dbo.Address ADR ON ADR.PropertyIDSeq=PROP.IDSeq
      JOIN CUSTOMERS.dbo.Account ACT ON ACT.PropertyIDSeq=PROP.IDSeq
    Where PROP.IDSeq=@IPVC_PropertyID 
      And ADR.AddressTypeCode='PST' 
      And PROP.LegacyRegistrationCode Is Not NULL
      And ACT.AccountTypeCode='APROP'

    UPDATE @tblTemp Set ParentCode=(Select Top 1 LegacyRegistrationCode From CUSTOMERS.dbo.Company Where IDSeq=@IPVC_CompanyID)
    
    Select * From @tblTemp

  End
END

--EXEC [CUSTOMERS].dbo.[uspCUSTOMERS_Client_MasterGetParametersSITE] 'C0802000033', 'P0802000112'


GO
