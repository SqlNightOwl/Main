SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
---------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : [uspINVOICES_Rep_GetInstantInvoicePaymentDetail]
-- Description     : This procedure gets Instant Invoice Payment Detail
-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(15)
--      
-- Code Example    : Exec INVOICES.dbo.[uspINVOICES_Rep_GetInstantInvoicePaymentDetail] 
-- 
-- 
-- Revision History:
-- Author          : Satya B
-- 09/08/2011      : Stored Procedure Created. This is used only in SRS report Instant Invoice From
--                   
---------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspINVOICES_Rep_GetInstantInvoicePaymentDetail](
---------------------------------------------------------------------------------------------------
				@IPVC_PMCID			 VARCHAR(11)  = '',
				@IPVC_PMCName		 VARCHAR(255) = '',
				@IPVC_PMCAccountID   VARCHAR(11)  = '',
				@IPVC_SiteID		 VARCHAR(11)  = '',
				@IPVC_SiteName		 VARCHAR(255) = '',
				@IPVC_SiteAccountID  VARCHAR(11)  = '',
				@IPVC_StartDate		 VARCHAR(10)  = '',
				@IPVC_EndDate		 VARCHAR(10)  = '',
				@IPVC_ReferenceID	 VARCHAR(100) = '',
				@IPVC_InvoiceID		 VARCHAR(22)  = '' )
---------------------------------------------------------------------------------------------------
AS
BEGIN 
  SET NOCOUNT ON; 
  
  SELECT i.CompanyIDSeq AS PMCID, i.CompanyName AS PMCName, i.AccountIDSeq AS PMCAccountID, 
		 i.PropertyIDSeq AS SiteID, i.PropertyName AS SiteName, 
		 CASE WHEN ISNULL(i.PropertyIDSeq, '') <> '' THEN i.AccountIDSeq ELSE NULL END AS SiteAccountID,
		 i.EpicorCustomerCode AS EpicorID, ip.PaymentTransactionAuthorizationCode AS ReferenceID,
		 ip.PaymentTransactionDate AS PaymentDate, i.InvoiceIDSeq AS InvoiceID, ip.TotalPaidAmount AS Amount,
		 ip.PaymentMethod AS PaymentType, ip.InvoiceTotalAmount AS InvoiceAmount, i.BillToEmailAddress AS SentToEmailAddress,
		 q.Requestedby AS RequestorName
  FROM dbo.InvoicePayment ip WITH (NOLOCK)
  INNER JOIN dbo.Invoice i WITH (NOLOCK) ON ip.InvoiceIDSeq = i.InvoiceIDSeq
  INNER JOIN QUOTES.dbo.Quote q WITH (NOLOCK) ON ip.QuoteIDSeq = q.QuoteIDSeq
  WHERE (ISNULL(@IPVC_PMCID, '') = '' OR i.CompanyIDSeq = @IPVC_PMCID)
  AND (ISNULL(@IPVC_PMCName, '') = '' OR i.CompanyName = @IPVC_PMCName)
  AND (ISNULL(@IPVC_PMCAccountID, '') = '' OR i.AccountIDSeq = @IPVC_PMCAccountID)
  AND (ISNULL(@IPVC_SiteID, '') = '' OR i.PropertyIDSeq = @IPVC_SiteID)
  AND (ISNULL(@IPVC_SiteName, '') = '' OR i.PropertyName = @IPVC_SiteName)
  AND (ISNULL(@IPVC_SiteAccountID, '') = '' OR i.AccountIDSeq = @IPVC_SiteAccountID)
  AND (ISNULL(@IPVC_StartDate, '') = '' OR 
		CONVERT(INT, CONVERT(VARCHAR, ip.PaymentTransactionDate, 112)) BETWEEN 
			CONVERT(INT, CONVERT(VARCHAR, CONVERT(DATETIME, @IPVC_StartDate), 112)) AND 
			CONVERT(INT, CONVERT(VARCHAR, CONVERT(DATETIME, @IPVC_EndDate), 112)))
  AND (ISNULL(@IPVC_ReferenceID, '') = '' OR ip.PaymentTransactionAuthorizationCode = @IPVC_ReferenceID)
  AND (ISNULL(@IPVC_InvoiceID, '') = '' OR i.InvoiceIDSeq = @IPVC_InvoiceID)
END
GO
