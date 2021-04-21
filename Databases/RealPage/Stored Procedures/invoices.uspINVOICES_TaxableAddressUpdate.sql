SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_TaxableAddressUpdate
-- Description     : This procedure Updates Taxable Address columns in InvoiceItems
--                   before Taxware call is being made.
-- Revision History:
-- Author          : SRS
-- 1/15/2008       : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_TaxableAddressUpdate] (@IPVC_InvoiceID  varchar(50)
                                                          )
AS
BEGIN
  set nocount on;  
  ------------------------------------------------------------------
  ---Step 1 : Before returning the Dataset for Taxware,update
  --- Mandatory Taxrelated Columns in Invoiceitem
  UPDATE IX
  set    IX.TaxableAddressLine1    = S.AddressLine1,
         IX.TaxableAddressLine2    = S.AddressLine2,
         IX.TaxableCity            = S.City,
         IX.TaxableState           = S.State,
         IX.TaxableZip             = S.Zip,
         IX.TaxableCountryCode     = S.CountryCode,
         IX.TaxableCounty          = S.Taxablecounty,
         IX.TaxableAddressTypeCode = S.TaxableAddressTypeCode
  From   INVOICES.dbo.InvoiceItem IX with (nolock)
  inner join
         (SELECT II.InvoiceIDSeq,II.InvoiceGroupIDSeq,II.IDSeq as InvoiceitemIDSeq,
              (case when P.PlatformCode = 'PRM' 
                       then coalesce(nullif(II.TaxableAddressLine1,''),I.ShipToAddressLine1)
                       else coalesce(nullif(II.TaxableAddressLine1,''),AD.AddressLine1)
               end)                                                                           as AddressLine1,
              (case when P.PlatformCode = 'PRM' 
                       then coalesce(nullif(II.TaxableAddressLine2,''),nullif(I.ShipToAddressLine2,''))
                    else coalesce(nullif(II.TaxableAddressLine2,''),nullif(AD.AddressLine2,''))
               end)                                                                           as AddressLine2,
              (case when P.PlatformCode = 'PRM' 
                       then coalesce(nullif(II.TaxableCity,''),I.ShipToCity)
                    else coalesce(nullif(II.TaxableCity,''),AD.City)
               end)                                                                           as City,
              (case when P.PlatformCode = 'PRM' 
                       then coalesce(nullif(II.TaxableState,''),I.ShipToState)
                    else coalesce(nullif(II.TaxableState,''),AD.State)
               end)                                                                           as State,
              (case when P.PlatformCode = 'PRM' 
                       then coalesce(nullif(II.TaxableZip,''),I.ShipToZip)
                    else coalesce(nullif(II.TaxableZip,''),AD.Zip) 
               end)                                                                           as Zip,
              (case when P.PlatformCode = 'PRM' 
                       then coalesce(nullif(II.TaxableCountryCode,''),I.ShipToCountryCode)
                    else coalesce(nullif(II.TaxableCountryCode,''),AD.CountryCode)
               end)                                                                           as CountryCode,
              (case when P.PlatformCode = 'PRM' 
                       then coalesce(nullif(II.TaxableCounty,''),I.ShipToCounty,AD.county)
                    else coalesce(nullif(II.TaxableCounty,''),AD.county)
               end)                                                                           as Taxablecounty,
              (case when P.PlatformCode = 'PRM' 
                       then coalesce(nullif(II.TaxableAddressTypeCode,''),
                             (CASE AC.AccountTypeCode WHEN 'APROP' Then 'PST' ELSE 'CST' END)
                            )
                    else coalesce(nullif(II.TaxableAddressTypeCode,''),AD.AddressTypeCode)
               end)                                                                           as TaxableAddressTypeCode
           FROM  Invoices.dbo.Invoice     I with (nolock)
           INNER JOIN
                 Invoices.dbo.InvoiceItem II with (nolock)
           ON    I.Invoiceidseq  = II.InvoiceIdSeq  
           and   II.InvoiceIDSeq = @IPVC_InvoiceID
           and   I.InvoiceIDSeq  = @IPVC_InvoiceID
           INNER JOIN
                 Products.dbo.Product P with (nolock)
           ON    II.Productcode  = P.Code
           and   II.Priceversion = P.priceversion     
           INNER JOIN
                 Customers.dbo.Account AC with (nolock)
           ON    AC.IDSeq        = I.AccountIDSeq  
           INNER JOIN
                 CUSTOMERS.dbo.Address AD with (nolock)
           ON    AC.CompanyIDSeq=AD.CompanyIDSeq
           and   coalesce(AC.propertyidseq,'') = coalesce(AD.propertyidseq,'')
           and   AD.AddressTypeCode=(CASE AC.AccountTypeCode WHEN 'APROP' Then 'PRO' ELSE 'COM' END)
           WHERE II.InvoiceIDSeq = @IPVC_InvoiceID
           and   AD.AddressTypeCode=(CASE AC.AccountTypeCode WHEN 'APROP' Then 'PRO' ELSE 'COM' END)  
         ) S
  on  IX.InvoiceIDSeq      = S.InvoiceIDSeq
  and IX.InvoiceGroupIDSeq = S.InvoiceGroupIDSeq
  and IX.IDSeq             = S.InvoiceitemIDSeq
  and IX.InvoiceIDSeq      = @IPVC_InvoiceID
  and S.InvoiceIDSeq       = @IPVC_InvoiceID
  ------------------------------------------------------------------
END

GO
