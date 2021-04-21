SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- ==========================================================================================
-- Author:		<Eric Font>
-- Create date: <01/28/2008>
-- Description:	<Come up with a UNIQUE registration code for each new PROPERTY and CUSTOMER>
-- ==========================================================================================
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetLegacyRegistrationCode] (@RegCode Char(4) output)
AS
BEGIN
  set nocount on
  /*
  Declare @CodeLen Int, @TmpID Char(32), @TmpSubString Char(4), @iCounter Int
  Set @CodeLen=4
  Set @iCounter=1
  Set @TmpID=Replace(NewID(),'-','')
  Set @TmpSubString=SubString(@TmpID,@iCounter,@CodeLen)

  While (
    Select LegacyRegistrationCode From CUSTOMERS..[Company] Where LegacyRegistrationCode=@TmpSubString
    Union
    Select LegacyRegistrationCode From CUSTOMERS..[Property] Where LegacyRegistrationCode=@TmpSubString
  ) Is Not NULL
  Begin
    Set @TmpSubString=SubString(@TmpID,@iCounter,@CodeLen)
    Set @iCounter=@iCounter+1
    If (Len(@TmpSubString)<@CodeLen)
    Begin
      Set @TmpID=Replace(NewID(),'-','')
      Set @iCounter=1
      Set @TmpSubString=SubString(@TmpID,@iCounter,@CodeLen)
    End
  End
  Set @RegCode=@TmpSubString
  */
  -------------------------------------------------------
  --Declaring Local Variables
  declare @TmpSubString   varchar(4)
  declare @FromTableValue varchar(4) 
  -------------------------------------------------------
  --Step 1: Defining a Label and code get 4 characters of Newid()
  Back: select @TmpSubString = Right(NewID(),4)
  -------------------------------------------------------
  --Step 2: Code to get the 4 digit code from Company and 
  --        Property table based on 4 digit code from step1

  Select @FromTableValue= S.LegacyRegistrationCode
  from(Select LegacyRegistrationCode
       From   CUSTOMERS.dbo.[Company] with (nolock)
       Where  LegacyRegistrationCode=@TmpSubString
       Union
       Select LegacyRegistrationCode 
       From   CUSTOMERS.dbo.[Property]  with (nolock) 
       Where  LegacyRegistrationCode=@TmpSubString
      ) S

  -------------------------------------------------------
  --Step 3: If Database value and newly generated value 
  --        of step 1 is equal, thn go to label "Back"
  --        to generate New 4 digit code and repeat the 
  --        operation.
  --        If 4 digit code from step 1 does not exists
  --        in database, then return as @RegCode
  if (@TmpSubString=@FromTableValue) 
  goto Back 
  -------------------------------------------------------
  select @RegCode=@TmpSubString
  -------------------------------------------------------
END

GO
