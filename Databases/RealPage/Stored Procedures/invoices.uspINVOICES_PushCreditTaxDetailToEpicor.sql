SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_PushCreditTaxDetailToEpicor]
-- Description     : This procedure select tax data from CreditMemoItem table                
-- Revision History:
-- Author          : Shashi Bhsuhan
-- 03/18/2009      : Stored Procedure Created.
-- 09/08/2009      : Shashi Bhushan #6992 altered to select TaxableCountryCode column value
----------------------------------------------------------------------------------------------------

CREATE PROCEDURE [invoices].[uspINVOICES_PushCreditTaxDetailToEpicor]
   ( 
	 @IPVC_CreditMemoID      varchar(50)
   )
AS
BEGIN
	SELECT row_number() OVER(ORDER BY II.TaxableCountryCode) AS SequenceID,
           II.TaxableState,
		  SUM(CMI.NetCreditAmount + CMI.ShippingAndHandlingCreditAmount) AS TaxableAmount,
		  SUM(CMI.NetCreditAmount + CMI.ShippingAndHandlingCreditAmount) AS GrossAmount,
		  SUM(CMI.TaxAmount)       AS TaxAmount,
		  SUM(CMI.TaxAmount)       AS FinalTaxAmount,
           II.TaxableCountryCode   AS TaxableCountryCode
	FROM Invoices.dbo.CreditMemoItem CMI WITH (NOLOCK)
	INNER JOIN
		 Invoices.dbo.InvoiceItem II WITH (NOLOCK)
	  ON CMI.InvoiceIDSeq      = II.InvoiceIDseq
	 AND CMI.InvoiceGroupIDSeq = II.InvoiceGroupIDSeq
	 AND CMI.InvoiceItemIDSeq  = II.IDSEq
	WHERE CMI.CreditMemoIDSeq  = @IPVC_CreditMemoID
    GROUP BY II.TaxableState,II.TaxableCountryCode
	 
END
GO
