SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [invoices].[uspINVOICES_GetTaxableInvoiceGroups] (@IPVC_InvoiceID varchar(20))
AS
BEGIN
  
  select IG.IDSeq as InvoiceGroupIDSeq,II.ChargeTypeCode,Max(convert(int,IG.CustomBundleNameEnabledFlag)) as CustomBundleNameEnabledFlag
  FROM  Invoices.dbo.Invoice I with (nolock)
  Inner Join
        Invoices.dbo.InvoiceGroup IG with (nolock)
  on    I.InvoiceIdSeq = IG.InvoiceIdseq   
  --and   I.Printflag = 0
  INNER JOIN
        Invoices.dbo.InvoiceItem II with (nolock)
  ON    I.Invoiceidseq  = II.InvoiceIdSeq
  and   IG.Invoiceidseq = II.Invoiceidseq
  and   IG.IDseq        = II.InvoiceGroupIDseq 
  and   II.InvoiceIDSeq = @IPVC_InvoiceID
  and   IG.InvoiceIDSeq = @IPVC_InvoiceID
  and   I.InvoiceIDSeq  = @IPVC_InvoiceID
  group by I.InvoiceIdseq,IG.IDSeq,II.InvoiceGroupIDseq,II.ChargeTypeCode
END

GO
