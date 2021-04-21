SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : uspINVOICES_TaxableInvoiceItemsSelect
-- Description     : This procedure gets the invoices that haven't been printed
-- Revision History:
-- Author          : DC
-- 4/11/2007        : Stored Procedure Created.
-- 03/24/2008		: Naval Kishore Modified to get CountryCode
-- 08/10/2009      : Shashi Bhushan #6411 (Tax in Denver city or county for non Screening on Demand products)
-- 02/22/2010      : Naval Kishore Modified to add TaxwareCompanyCode. 
-- 10/19/2011      : TFS 1375 Performance
-- 11/04/2011      : TFS 1514 : OrderItemIDSeq is already returned by final resultset. Added OrderIDSeq,OrderGroupIDSeq as well.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_TaxableInvoiceItemsSelect] (@IPVC_InvoiceID                  varchar(50),
                                                                @IPI_InvoiceGroupIDSeq           varchar(50)   ='',
                                                                @IPVC_ChargeTypeCode             varchar(50)   ='',
                                                                @IPI_CustomBundleNameEnabledFlag int = 0)
AS
BEGIN
  set nocount on;
  ------------------------------------------------------------------
  select @IPVC_ChargeTypeCode   = nullif(@IPVC_ChargeTypeCode,'');
  select @IPI_InvoiceGroupIDSeq = nullif(@IPI_InvoiceGroupIDSeq,'');
  ------------------------------------------------------------------
  ---Step 1 : Before returning the Dataset for Taxware,update
  --- Mandatory Taxrelated Columns in Invoiceitem
  ;with II_CTE (InvoiceIDSeq,InvoiceGroupIDSeq,InvoiceitemIDSeq,
                AddressLine1,AddressLine2,City,State,Zip,CountryCode,Taxablecounty,TaxableAddressTypeCode
               )
  as       (SELECT II.InvoiceIDSeq,II.InvoiceGroupIDSeq,II.IDSeq as InvoiceitemIDSeq,
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
           ON    II.InvoiceIdSeq = I.Invoiceidseq
           and   I.PrintFlag     = 0 
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
         )
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
         II_CTE S
  on  IX.InvoiceIDSeq      = S.InvoiceIDSeq
  and IX.InvoiceGroupIDSeq = S.InvoiceGroupIDSeq
  and IX.IDSeq             = S.InvoiceitemIDSeq
  and IX.InvoiceIDSeq      = @IPVC_InvoiceID
  and S.InvoiceIDSeq       = @IPVC_InvoiceID
  and (
        (IX.TaxableAddressLine1   <> S.AddressLine1)
           OR
        (IX.TaxableCity            <> S.City)
           OR
        (IX.TaxableState           <> S.State)
           OR
        (IX.TaxableZip             <> S.Zip)
           OR
        (IX.TaxableCountryCode     <> S.CountryCode)
           OR
        (IX.TaxableAddressTypeCode <> S.TaxableAddressTypeCode)
      );
  ------------------------------------------------------------------
  --SPECIAL UPDATE SECTION ONLY FOR DENVER : Interim Solution (#6411)
  --> Applicable only to DENVER TaxableCity and DENVER TaxableCounty
  --  only in COLORADO State. It was found there are other City Names
  --  and county names called DENVER in Other state(s) for which this 
  --  special update is NOT Applicable.
  ------------------------------------------------------------------
  UPDATE II
  SET    II.TaxwareCode        = '80015',
         II.DefaultTaxwareCode = '80015'
  FROM Invoices.dbo.Invoice I WITH (NOLOCK) 
  INNER JOIN
       Invoices.dbo.Invoiceitem II  WITH (NOLOCK)
  ON   I.InvoiceIDSeq  = II.InvoiceIDSeq
  and  I.PrintFlag     = 0
  and  I.InvoiceIDSeq  = @IPVC_InvoiceID
  and  II.InvoiceIDSeq = @IPVC_InvoiceID
  and  II.InvoiceGroupIDSeq = coalesce(@IPI_InvoiceGroupIDSeq,II.InvoiceGroupIDSeq)
  and  II.ChargeTypeCode    = coalesce(@IPVC_ChargeTypeCode,II.ChargeTypeCode)
  and  II.TaxableState = 'CO'     
  and  (
        II.TaxableCity   like  '%DENVER%'
        OR
        II.TaxableCounty like  '%DENVER%'
       )
  INNER JOIN
      Products.dbo.Charge C WITH (NOLOCK)
  ON  II.Productcode    = C.productcode 
  and II.Priceversion   = C.priceversion
  and II.Chargetypecode = C.Chargetypecode 
  and II.Measurecode    = C.Measurecode
  and II.Frequencycode  = C.Frequencycode
  and C.Taxwarecode     = '80010'
  and (
       (II.TaxwareCode        <> '80015')
          OR
       (II.DefaultTaxwareCode <> '80015') 
      )      
  WHERE I.InvoiceIDSeq  = @IPVC_InvoiceID
  and   II.InvoiceIDSeq = @IPVC_InvoiceID
  and   II.InvoiceGroupIDSeq = coalesce(@IPI_InvoiceGroupIDSeq,II.InvoiceGroupIDSeq)
  and   II.ChargeTypeCode    = coalesce(@IPVC_ChargeTypeCode,II.ChargeTypeCode)
  and   C.Taxwarecode   = '80010'
  ------------------------------------------------------------------
  --Step 2: Final Select for Taxware call
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
         Coalesce(TC.CalculateTaxFlag,0)                                               as CalculateTaxFlag,
         II.OrderIDSeq                                                                 as OrderIDSeq,
         II.OrderGroupIDSeq                                                            as OrderGroupIDSeq
  FROM  Invoices.dbo.Invoice I with (nolock)
  INNER JOIN
        Invoices.dbo.InvoiceItem II with (nolock)
  ON    I.Invoiceidseq  = II.InvoiceIdSeq
  and   I.PrintFlag     = 0 
  and   II.InvoiceIDSeq = @IPVC_InvoiceID
  and   I.InvoiceIDSeq  = @IPVC_InvoiceID
  and   II.InvoiceGroupIDSeq = coalesce(@IPI_InvoiceGroupIDSeq,II.InvoiceGroupIDSeq)
  and   II.ChargeTypeCode    = coalesce(@IPVC_ChargeTypeCode,II.ChargeTypeCode)
  -------------------------------------------------------------------------------
  ---If @IPI_CustomBundleNameEnabledFlag=0, the get InvoiceItems
  --  that are not already processed for Taxware.
  ---If @IPI_CustomBundleNameEnabledFlag=0, get all InvoiceItems because Taxware call
  ---   invoice logic to find highest tax yielding code and determining tax for individual
  ---   items based on that.
  and  (
         (
          (@IPI_CustomBundleNameEnabledFlag = 0)
               AND
          (II.TaxPercent = 0 or II.TaxAmount = 0)
         ) 
               OR
        (@IPI_CustomBundleNameEnabledFlag = 1)
       )
  -------------------------------------------------------------------------------  
  LEFT OUTER JOIN
        PRODUCTS.dbo.TaxableCountry TC with (nolock)
  ON    I.TaxwareCompanyCode   = TC.TaxwareCompanyCode
  and   II.TaxableCountryCode  = TC.TaxableCountryCode       
  WHERE II.InvoiceIDSeq = @IPVC_InvoiceID
 
  ------------------------------------------------------------------
END
GO
