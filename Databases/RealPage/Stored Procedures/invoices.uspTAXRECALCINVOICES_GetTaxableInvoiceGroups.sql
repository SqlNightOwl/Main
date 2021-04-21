SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_GetTaxableInvoiceGroups]
(
	@IPVC_InvoiceID varchar(20)
) AS
BEGIN
  SELECT ig.[IDSeq] AS [InvoiceGroupIDSeq]
  , ii.[ChargeTypeCode]
  , MAX(CONVERT(int,ig.[CustomBundleNameEnabledFlag])) AS [CustomBundleNameEnabledFlag]
  FROM  [dbo].[Invoice] i WITH (NOLOCK)
  INNER JOIN [dbo].[InvoiceGroup] ig WITH (NOLOCK) ON ig.[InvoiceIdseq]=i.[InvoiceIdSeq]
  INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) ON ii.[InvoiceIdSeq]=i.[Invoiceidseq]
  AND ig.Invoiceidseq = ii.Invoiceidseq
  AND ig.IDseq        = ii.InvoiceGroupIDseq 
  AND ii.InvoiceIDSeq = @IPVC_InvoiceID
  AND ig.InvoiceIDSeq = @IPVC_InvoiceID
  AND i.InvoiceIDSeq  = @IPVC_InvoiceID
  GROUP BY i.[InvoiceIdseq], ig.[IDSeq], ii.[InvoiceGroupIDseq], ii.[ChargeTypeCode]
END
GO
