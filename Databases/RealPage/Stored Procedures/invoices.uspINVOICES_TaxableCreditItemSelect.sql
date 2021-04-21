SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_TaxableCreditItemsSelect
-- Description     : This procedure gets the invoice items that are taxable.
-- EXEC [dbo].[uspINVOICES_TaxableCreditItemSelect] 'I1106000091', 3237092
-- Revision History:
-- Author          : DC
-- 4/11/2007        : Stored Procedure Created.
-- 02/22/2010      : Naval Kishore Modified to add TaxwareCompanyCode.
-- 06/15/2011		: Satya added new column CalculateTaxFlag (Work Item #725)
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_TaxableCreditItemSelect] (@IPVC_InvoiceID varchar(50), @IPVC_InvoiceItemID bigint)
AS
BEGIN
  set nocount on;
  ------------------------------------------------------------------
  SELECT II.TaxableAddressLine1                                                        as AddressLine1,
         II.TaxableAddressLine2                                                        as AddressLine2,
         II.TaxableCity                                                                as City,
         II.TaxableState                                                               as State,
         II.TaxableZip                                                                 as Zip,
         II.TaxableCountryCode                                                         as CountryCode,
         I.AccountIDSeq                                                                as CustomerNumber,
         II.IDSeq                                                                      as InvoiceITemIDSeq,
         II.TaxWareCode                                                                as TaxWareCode,
         II.OrderItemIDSeq                                                             as OrderItemIDSeq,
         II.ShippingAndHandlingAmount                                                  as FreightAmount,
         convert(nvarchar,II.CreatedDate,101)                                          as CreatedDate,
         II.NetChargeAmount                                                            as NetChargeAmount,
         II.TaxableCounty                                                              as Taxablecounty,
         II.TaxableCountryCode                                                         as TaxableCountryCode,
         II.TaxableAddressTypeCode                                                     as TaxableAddressTypeCode,
         I.TaxwareCompanyCode                                                          as TaxwareCompanyCode,
         Coalesce(TC.CalculateTaxFlag,0)                                               as CalculateTaxFlag        
  FROM  Invoices.dbo.Invoice     I  with (nolock)
  INNER JOIN
        Invoices.dbo.InvoiceItem II with (nolock)
  ON    I.Invoiceidseq  = II.InvoiceIdSeq
  and   I.InvoiceIDSeq  = @IPVC_InvoiceID
  and   II.InvoiceIDSeq = @IPVC_InvoiceID
  and   II.IDSeq        = @IPVC_InvoiceItemID 
-------------------------------------------------------------------------------  
  LEFT OUTER JOIN
        PRODUCTS.dbo.TaxableCountry TC with (nolock)
  ON    I.TaxwareCompanyCode   = TC.TaxwareCompanyCode
  and   II.TaxableCountryCode  = TC.TaxableCountryCode       
-------------------------------------------------------------------------------   
  WHERE I.InvoiceIDSeq    = @IPVC_InvoiceID
  and   II.InvoiceIDSeq   = @IPVC_InvoiceID
  and   II.IDSeq          = @IPVC_InvoiceItemID
END
GO
