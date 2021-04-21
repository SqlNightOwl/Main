SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
-- procedure  : dbo.uspTAXRECALCINVOICES_CreditItemSelect
-- purpose    : obtain CreditMemoItem ID's for one specific Invoice
-- parameters : identify one Invoice, by InvoiceIDSeq
-- returns    : None.
-- remarks    :
	Observe that in this procedure, no control bits are even looked at. 
	Here we are given an InvoiceID, because the FindWork procedure determined that this invoice needs work. 
	Thus we are obliged to return all Credit Memo Items that are attached to said Invoice, without regard for whether 
	they seem to need recalculation, or whether recalculation has already been done.  Those two bits may be in
	any state, in various situations.  Here, it just doesn't matter. 
--
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-09-18   Larry Wilson             revised: acquire full set of invoice's credits, conditionally
-- 2009-09-11   Larry Wilson             initial implementation  (PCR-6250)
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
*/
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_CreditItemSelect] (@InvoiceIDSeq varchar(22))
AS
BEGIN
  set nocount on;
  -------------------------------------
  SELECT ii.[IDSeq]                                 as [InvoiceItemID]
	,ci.[IDSeq]                                 AS [CreditItemID]
	,i.[InvoiceIDSeq]                           as [InvoiceID]
	,c.[CreditMemoIDSeq]                        AS [CreditMemoID]
	,c.[CreditTypeCode]                         AS [CreditType]
	,ISNULL(c.[CreditMemoDate],c.[CreatedDate]) AS [CreditMemoDate]
	,ci.[NetCreditAmount]                       AS [NetCreditAmount]
	,ci.[ShippingAndHandlingCreditAmount]       AS [FreightAmount],
        -------------------------------------------------
        II.TaxableAddressLine1                      as AddressLine1,
        II.TaxableAddressLine2                      as AddressLine2,
        II.TaxableCity                              as City,
        II.TaxableState                             as State,
        II.TaxableZip                               as Zip,
        II.TaxableCountryCode                       as CountryCode,
        I.AccountIDSeq                              as CustomerNumber,
        II.TaxWareCode                              as TaxWareCode,
        II.TaxableCounty                            as Taxablecounty,
        II.TaxableCountryCode                       as TaxableCountryCode,
        II.TaxableAddressTypeCode                   as TaxableAddressTypeCode,
        I.TaxwareCompanyCode                        as TaxwareCompanyCode,
        Coalesce(TC.CalculateTaxFlag,0)             as CalculateTaxFlag

  FROM   [dbo].[CreditMemoItem] ci WITH (NOLOCK)
  INNER JOIN [dbo].[CreditMemo] c  WITH (NOLOCK) 
  on    ci.[CreditMemoIDSeq]= c.[CreditMemoIDSeq]
  and   ci.[InvoiceIDSeq]    =@InvoiceIDSeq
  and   c.[InvoiceIDSeq]     =@InvoiceIDSeq
  INNER JOIN [dbo].[InvoiceItem] ii WITH (NOLOCK) 
  ON    ii.[IDSeq]=ci.[InvoiceItemIDSeq]
  and   ii.[InvoiceIDSeq]     =@InvoiceIDSeq  
  INNER JOIN [dbo].[Invoice] i WITH (NOLOCK) 
  ON    ii.[InvoiceIDSeq]    =i.[InvoiceIDSeq]
  and   ii.[InvoiceIDSeq]    =@InvoiceIDSeq  
  and   i.[InvoiceIDSeq]     =@InvoiceIDSeq
  LEFT OUTER JOIN
        PRODUCTS.dbo.TaxableCountry TC with (nolock)
  ON    I.TaxwareCompanyCode   = TC.TaxwareCompanyCode
  and   II.TaxableCountryCode  = TC.TaxableCountryCode   
  WHERE i.[InvoiceIDSeq]     =@InvoiceIDSeq
  and   c.[InvoiceIDSeq]     =@InvoiceIDSeq
  ORDER BY ci.[InvoiceItemIDSeq] asc

  RETURN(0)
END
GO
