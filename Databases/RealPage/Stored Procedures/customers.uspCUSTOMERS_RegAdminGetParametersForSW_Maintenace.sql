SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [customers].[uspCUSTOMERS_RegAdminGetParametersForSW_Maintenace] (
  @IPVC_AccountID VarChar(50),
  @IPVC_OrderID VarChar(50),
  @IPVC_OrderItemID VarChar(50)
)
AS
BEGIN 
  set nocount on;
  --------------------------------------------
  Declare @CompanyID VarChar(50), @PropertyID VarChar(50)
  Select @CompanyID=CompanyIDSeq, @PropertyID=PropertyIDSeq From [CUSTOMERS].dbo.[Account] with (nolock) Where IDSeq=@IPVC_AccountID
  Declare @LegacyCode Char(4)
  Declare @ParentLegacyCode Char(4)
  If (@PropertyID Is NULL)
  Begin
    Select @LegacyCode=LegacyRegistrationCode From [CUSTOMERS].dbo.[Company] with (nolock) Where IDSeq=@CompanyID
    Set @ParentLegacyCode=''
  End
  Else
  Begin
    Select @LegacyCode=LegacyRegistrationCode From [CUSTOMERS].dbo.[Property] with (nolock) Where IDSeq=@PropertyID
    Select @ParentLegacyCode=LegacyRegistrationCode From [CUSTOMERS].dbo.[Company] with (nolock) 
      Where IDSeq=(Select PMCIDSeq From [CUSTOMERS].dbo.[Property] with (nolock) Where IDSeq=@PropertyID)
  End

  Select @LegacyCode                                                       As LegacyCode, 
         @ParentLegacyCode                                                 As ParentLegacyCode, 
         Left(P.LegacyProductCode,6)                                       As LegacyProductCode,
         OI.ChargeTypeCode                                                 As ChargeTypeCode,
         OI.StatusCode                                                     As StatusCode,
         OI.RenewalTypeCode                                                As RenewalCode,
         CONVERT(VarChar(20),ISNULL(OI.LastBillingPeriodFromDate,''), 101) As BillingPeriodFromDate,
         CONVERT(VarChar(20),ISNULL(OI.ILFStartDate,''), 101)              As ILFStartDate,
         CONVERT(VarChar(20),ISNULL(OI.ILFEndDate,''), 101)                As ILFEndDate,
         CONVERT(VarChar(20),ISNULL(OI.ActivationStartDate,''), 101)       As ActivationStartDate,
         CONVERT(VarChar(20),ISNULL(OI.ActivationEndDate,''), 101)         As ActivationEndDate,
         OI.OrderIDSeq                                                     as OrderIDSeq,
         OI.IDSeq                                                          as OrderItemIDSeq 
  From [ORDERS].dbo.[OrderItem] OI with (nolock) INNER JOIN [PRODUCTS].dbo.[Product] P with (nolock) ON OI.ProductCode=P.Code
  and  OI.PriceVersion = P.Priceversion
  and  OI.IDSeq=@IPVC_OrderItemID 
  And  P.RegAdminProductFlag=1
  Where  OI.IDSeq=@IPVC_OrderItemID And
         P.RegAdminProductFlag=1

END

/*
EXEC [CUSTOMERS].dbo.[uspCUSTOMERS_RegAdminGetParametersForSW_Maintenace] 'A0803000027','O0803000030', '241210'
*/


GO
