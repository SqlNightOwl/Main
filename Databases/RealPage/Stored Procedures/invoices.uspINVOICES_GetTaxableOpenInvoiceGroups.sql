SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_GetTaxableOpenInvoiceGroups]
-- Description     : This procedure gets the taxable open Invoice Groups (Defect ID:317)
-- Revision History:
-- Author          : Mahaboob Mohammad
-- 05/06/2011      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetTaxableOpenInvoiceGroups] (@IPVC_ProductCode varchar(30))  
AS  
BEGIN  
    
  select IG.IDSeq as InvoiceGroupIDSeq,II.ChargeTypeCode,Max(convert(int,IG.CustomBundleNameEnabledFlag)) as CustomBundleNameEnabledFlag, I.InvoiceIDSeq  
  FROM  Invoices.dbo.Invoice I with (nolock)  
  Inner Join  
        Invoices.dbo.InvoiceGroup IG with (nolock)  
  on    I.InvoiceIdSeq = IG.InvoiceIdseq     
  and   I.Printflag = 0 and I.SentToEpicorFlag = 0
  INNER JOIN  
        Invoices.dbo.InvoiceItem II with (nolock)  
  ON    I.Invoiceidseq  = II.InvoiceIdSeq  
  and   IG.Invoiceidseq = II.Invoiceidseq  
  and   IG.IDseq        = II.InvoiceGroupIDseq   
 
   inner Join  
               PRODUCTS.dbo.Charge C with (nolock)  
        on     II.ProductCode    = C.ProductCode  
        and    II.PriceVersion   = C.PriceVersion  
        and    II.ChargeTypeCode = C.ChargeTypeCode  
        and    II.MeasureCode    = C.MeasureCode  
        and    II.FrequencyCode  = C.FrequencyCode  
        and    II.ProductCode     = @IPVC_ProductCode   
        and    C.ProductCode      = @IPVC_ProductCode  
  group by I.InvoiceIdseq,IG.IDSeq,II.InvoiceGroupIDseq,II.ChargeTypeCode  
END  
GO
