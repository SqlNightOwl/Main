SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspCredits_Rep_GetAccountInfo
-- Description     : This procedure gets Credit Details pertaining to passed CreditID
-- Input Parameters: 1. @IPVC_CreditIDSeq   as varchar(15)
--      
-- Code Example    : Exec INVOICES.dbo.uspCredits_Rep_GetAccountInfo @CreditMemoIDSeq = 'R0907000198'
    
-- 
-- 
-- Revision History:
-- 2010-07-30      : Larry Wilson Add Business Unit identifer to result set #7951
-- 2009-07-15      : Shashi Bhushan Modified to add S&H amount in totalcreditamount col value #6745
-- 2009-06-01      : Naval Kishore modified Sp to get Country Name.
-- 2007-10-07      : Kiran Kusumba: Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspCredits_Rep_GetAccountInfo] (
                                                           @CreditMemoIDSeq  VARCHAR(50)  
                                                         )
AS
BEGIN 

 SET NOCOUNT ON 
 DECLARE @LVC_CreditType VARCHAR(255)
 DECLARE @LVC_CreditTypeCode VARCHAR(6)
 DECLARE @LVC_CreditReasonCode VARCHAR(6)
 DECLARE @LVC_CreditReason VARCHAR(255)
 DECLARE @LVC_TotalCreditAmount VARCHAR(255)

 SELECT @LVC_CreditTypeCode = CreditTypeCode, @LVC_CreditReasonCode = CreditReasonCode 
 FROM Invoices.dbo.CreditMemo with (nolock)
 WHERE CreditMemoIDSeq = @CreditMemoIDSeq 
      
 SELECT @LVC_CreditType = Description FROM Invoices.dbo.CreditType 
 WHERE Code = @LVC_CreditTypeCode

 SELECT @LVC_CreditReason = ReasonName FROM Orders.dbo.Reason with (nolock)
 WHERE Code = @LVC_CreditReasonCode

 SET @LVC_TotalCreditAmount = (SELECT  (ISNULL( Quotes.DBO.fn_FormatCurrency(convert(numeric(10,2),isnull(CrM.TotalNetCreditAmount,0))
								      + isnull(sum(CrI.ShippingAndHandlingCreditAmount),0.00) +  convert(numeric(10,2),isnull(sum(CrI.TaxAmount),0)),2,2),'0'))  
                              FROM    Invoices.dbo.CreditMemoItem CrI with (nolock)
                              inner join   
									  Invoices.dbo.CreditMemo CrM with (nolock)
                                ON CrM.CreditMemoIDSeq = CrI.CreditMemoIDSeq
                              WHERE  CrI.CreditMemoIDSeq =   @CreditMemoIDSeq  
                              GROUP BY CrM.TotalNetCreditAmount)  

 SELECT C.CreditMemoIDSeq		   'CreditNo',
		@LVC_CreditType 'CreditType',	
		C.InvoiceIDSeq 'InvoiceNo',
		CONVERT(nvarchar,I.InvoiceDate,101)  'InvoiceDate',
		I.AccountIDSeq 'AccountID',
		isnull(I.PropertyName, I.CompanyName) 'AccountName',
		@LVC_TotalCreditAmount 'TotalCreditAmount',	
		@LVC_CreditReason 'Reason',
		C.Comments 'Comments',
		isnull(I.PropertyName, I.CompanyName) 'MainName',
		I.BillToAccountName 'BillingName',
		I.ShipToAddressLine1  'MainAddress1',
		I.ShipToAddressLine2	'MainAddress2',
	    I.ShipToCity   'MainCity',
		I.ShipToState + ' ' + I.ShipToZip	as 'MainStateZip',
		UPPER(I.ShipToCountry)              as 'MainCountry',
		I.BillToAddressLine1 'BillingAddress1',
		I.BillToAddressLine2 'BillingAddress2',
		I.BillToCity 'BillingCity',
		I.BillToState + ' ' + I.BillToZip as 'BillingStateZip',
		UPPER(I.BillToCountry)            as 'BillingCountry',
        I.EpicorCustomerCode              as 'EpicorID',
		C.DoNotPrintCreditReasonFlag   as 'DoNotPrintCreditReason',
		C.DoNotPrintCreditCommentsFlag as 'DoNotPrintCreditComments',
		C.IncludeAccountsManagerSignatureFlag as 'IncludeAccountsManagerSignatureFlag',
		C.IncludeSoftwareRevenueDirectorSignatureFlag as 'IncludeSoftwareRevenueDirectorSignatureFlag',
		C.IncludeVicePresidentFinanceSignatureFlag as 'IncludeVicePresidentFinanceSignatureFlag',
		C.IncludeProductManagerSignatureFlag as 'IncludeProductManagerSignatureFlag',
		C.IncludeVicePresidentSalesSignatureFlag as 'IncludeVicePresidentSalesSignatureFlag',
		C.IncludeChiefFinancialOfficerSignatureFlag as 'IncludeChiefFinancialOfficerSignatureFlag',
		C.CreditStatusCode  as 'CreditStatusCode'
	, lower([dbo].[fnGetInvoiceLogoDefinition](C.InvoiceIDSeq)) as [BusinessUnit]
 FROM Invoices.dbo.CreditMemo C (nolock) 
 INNER JOIN Invoices.dbo.Invoice I
 ON    C.InvoiceIDSeq = I.InvoiceIDSeq
 WHERE C.CreditMemoIDSeq = @CreditMemoIDSeq
END 
GO
