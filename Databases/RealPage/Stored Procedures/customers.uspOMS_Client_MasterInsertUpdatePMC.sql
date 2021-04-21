SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspOMS_Client_MasterInsertUpdatePMC] (
  @Code Char(4), 
  @Firm_Name VarChar(50), 
  @Addr VarChar(50), 
  @City VarChar(30), 
  @State Char(2), 
  @Zip VarChar(10), 
  @Phone VarChar(10),
  @StartDate DateTime
)
AS
BEGIN 

--If Not Exists (Select 1 From ACCTDB.dbo.Client_Master Where AcctNo=@Code)
  If Not Exists (Select 1 From CUSTOMERS.dbo.Client_Master Where AcctNo=@Code)
  Begin -- INSERT PMC INTO Client_Master
--INSERT Into ACCTDB.dbo.Client_Master(
    INSERT Into CUSTOMERS.dbo.Client_Master(
      AcctNo,Chk_Digit,Client_Pswd,Att_Name,
      Firm_Name,Addr,City,
      State,Zip,Phone,Firm_Cd,
      Mkt_Ind,Firm_Type,Regn,Ar_Terr,Ar_Terr_Pyr,
      MSR_Terr,MSR_Terr_Pyr,Telmkt_Terr,Telmkt_Terr_Pyr,
      Proc_Method,Contact1_Nm,Start_Dt,Bill_Att_Name,Bill_Firm_Name,
      Bill_Addr,Bill_AcctNo,Bill_Phone,Reg_AcctNo,Parent_AcctNo
    ) 
    Values (
      @Code,'X','X','?province?', 
      @Firm_Name,@Addr,@City,@State,@Zip,@Phone,'XX',
      '91','X','R1','A1','A1','A1','A1','A1','A1',
      'X','Contact Name',@StartDate,'Bill Att Name','Bill Name',
      'Bill Addr','XXXX','????','XXXX',@Code
    )
  End
  Else
  Begin -- UPDATE PMC in Client_Master --
--    UPDATE ACCTDB.dbo.Client_Master
    UPDATE CUSTOMERS.dbo.Client_Master
      Set Firm_Name= @Firm_Name,
          Addr=      @Addr,
          City=      @City,
          State=     @State,
          Zip=       @Zip,
          Phone=     @Phone
    Where AcctNo=@Code
  End

END

--SELECT * From CUSTOMERS.dbo.Client_Master

GO
