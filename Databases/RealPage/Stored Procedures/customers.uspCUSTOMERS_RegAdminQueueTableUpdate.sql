SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_RegAdminQueueTableUpdate]
-- Description     : Update values into the RegAdminQueue table - a later process will update REGISTERDB
--------------------------------------------------------------------------------------------------------
CREATE procedure [customers].[uspCUSTOMERS_RegAdminQueueTableUpdate] (
    @PushedToRegAdminFlag bit,
    @IPVC_CompanyID varchar(11) = NULL, 
    @IPVC_PropertyID varchar(11) = NULL,
    @IPVC_AccountID varchar(11) = NULL,
    @IPVC_OrderItemID varchar(11) = NULL
)
AS
BEGIN

  If (@IPVC_OrderItemID Is Not NULL And @IPVC_OrderItemID!='')
  Begin
    If Exists(Select 1 From CUSTOMERS.dbo.RegAdminQueue Where OrderItemIDSeq=@IPVC_OrderItemID)
    Begin
      Update CUSTOMERS.dbo.RegAdminQueue Set PushedToRegAdminFlag=@PushedToRegAdminFlag Where OrderItemIDSeq=@IPVC_OrderItemID
    End
  End
  Else
  Begin
    -- <EFont note="get AccountID">
    If (@IPVC_AccountID Is NULL Or @IPVC_AccountID='')
    Begin
      If @IPVC_PropertyID Is NULL Or @IPVC_PropertyID=''
      Begin
        Select @IPVC_AccountID=IDSeq From CUSTOMERS.dbo.Account Where CompanyIDSeq=@IPVC_CompanyID And PropertyIDSeq Is NULL
      End
      Else
      Begin
        Select @IPVC_AccountID=IDSeq From CUSTOMERS.dbo.Account Where CompanyIDSeq=@IPVC_CompanyID And PropertyIDSeq=@IPVC_PropertyID
      End
    End
    -- </EFont>

    If Exists(Select 1 From CUSTOMERS.dbo.RegAdminQueue Where AccountIDSeq=@IPVC_AccountID And OrderItemIDSeq Is NULL)
    Begin
      Update CUSTOMERS.dbo.RegAdminQueue Set PushedToRegAdminFlag=@PushedToRegAdminFlag Where AccountIDSeq=@IPVC_AccountID And OrderItemIDSeq Is NULL
    End
  End

END

GO
