SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_Client_MasterGetParametersPMC] (@IPVC_CompanyID varchar(11))
AS
BEGIN 
  -- ACCOUNT MUST exist in the Account table
  If EXISTS(Select 1 From CUSTOMERS.dbo.Account Where CompanyIDSeq=@IPVC_CompanyID And AccountTypeCode='AHOFF')
  Begin
    SELECT 
      LEFT(CMP.LegacyRegistrationCode,4)                          As Code,
      LEFT(CMP.[Name],30)                                         As Firm_Name,
      ISNULL(LEFT(ADR.AddressLine1,30),'No Address')              As Addr, 
      ISNULL(LEFT(ADR.City,30),'No City')                         As City,
      ISNULL(LEFT(ADR.State,2),'XX')                              As State,
      ISNULL(LEFT(ADR.Zip,5),'XXXXX')                             As Zip, 
      ISNULL(LEFT(ADR.PhoneVoice1,10),' ')                        As Phone,
      Convert (VarChar,ISNULL(ACT.StartDate,ACT.CreatedDate),101) As StartDate
    From CUSTOMERS.dbo.Company CMP 
      JOIN CUSTOMERS.dbo.Address ADR On CMP.IDSeq=ADR.CompanyIDSeq
      JOIN CUSTOMERS.dbo.Account ACT ON ACT.CompanyIDSeq=ADR.CompanyIDSeq
    Where CMP.IDSeq=@IPVC_CompanyID 
      And ADR.AddressTypeCode='CST' 
      And CMP.LegacyRegistrationCode Is Not NULL
      And ACT.AccountTypeCode='AHOFF'
  End
END

--EXEC [CUSTOMERS].dbo.[uspCUSTOMERS_Client_MasterGetParametersPMC] 'C0802000030'

GO
