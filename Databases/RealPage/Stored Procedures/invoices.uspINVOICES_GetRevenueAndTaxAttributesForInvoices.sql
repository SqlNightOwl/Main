SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec Invoices.dbo.uspINVOICES_GetRevenueAndTaxAttributesForInvoices @IPVC_InvoiceIDSeq = 'I0809000015',
@IPBI_InvoiceGroupIDSeq = 23303,@IPBI_InvoiceItemIDSeq=155659,@IPVC_ChargeTypeCode='ACS',@IPI_IsCustomBundleFlag = 0


Exec Invoices.dbo.uspINVOICES_GetRevenueAndTaxAttributesForInvoices @IPVC_InvoiceIDSeq = 'I0804000164',
@IPBI_InvoiceGroupIDSeq = 88,@IPBI_InvoiceItemIDSeq=55962,@IPVC_ChargeTypeCode='ILF',@IPI_IsCustomBundleFlag = 1
*/

----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_GetRevenueAndTaxAttributesForInvoices]
-- Description     : This procedure gets Revenue And TaxAttributes for Invoiceitem
-- Input Parameters: See Below
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.DBO.[uspINVOICES_GetRevenueAndTaxAttributesForInvoices]  Parameters
-- 
-- Revision History:
-- Author          : SRS
-- 09/16/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetRevenueAndTaxAttributesForInvoices] (@IPVC_InvoiceIDSeq         varchar(50),
                                                                            @IPBI_InvoiceGroupIDSeq    bigint,
                                                                            @IPBI_InvoiceItemIDSeq     bigint=0,
                                                                            @IPVC_ChargeTypeCode       varchar(20),
                                                                            @IPI_IsCustomBundleFlag    int = 0
                                                                           )
AS
BEGIN 
  set nocount on ;  
  SET CONCAT_NULL_YIELDS_NULL OFF;
  --------------------------------------------------------------------
  If (@IPI_IsCustomBundleFlag=1) -- Custom Bundle
  begin
    Select Distinct P.DisplayName                                     as ProductName,
           ----------------------------------------------------
           ---Revenue Finance Related Info : Section 1
           II.RevenueAccountCode                                      as RevenueAccountCode,
           coalesce(nullif(II.DeferredRevenueAccountCode,''),'N/A')   as DeferredRevenueAccountCode,
           II.RevenueTierCode                                         as RevenueTierCode,
           (case when II.RevenueRecognitionCode = 'IRR'
                   then 'Immediate Revenue Recognition'
                 when II.RevenueRecognitionCode = 'SRR'
                   then 'Scheduled Revenue Recognition'
                 when II.RevenueRecognitionCode = 'MRR'
                   then 'Manual Revenue Recognition'
                 else 'Unknown'
            end)                                                      as RevenueRecognition,    
            
            ----------------------------------------------------
            ---Tax Related Info : Section 2
            coalesce(nullif(II.TaxwareCode,''),'N/A')                                            as TaxwareCode,
            II.TaxAmount                                                                         as TotalTax,
            coalesce(nullif(II.TaxableAddressLine1,''),'N/A')                                    as TaxableAddressLine1,
            coalesce(nullif(II.TaxableAddressLine2,''),'')                                       as TaxableAddressLine2,
            coalesce(nullif(II.TaxableCity,''),'N/A')                                            as TaxableCity,
            coalesce(nullif(II.TaxableState,''),'N/A')                                           as TaxableState,
            coalesce(nullif(II.TaxableZip,''),'N/A')                                             as TaxableZip,
            coalesce(nullif(II.TaxableCountryCode,''),'N/A')                                     as TaxableCountryCode,
            ----------------------------------------------------
            ---Tax Related Info : Section 3
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(II.TaxwarePrimaryStateJurisdictionZipCode,''), 'N/A')
				 ELSE 'N/A' END																	 as PrimaryStateJurisdictionZipCode,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(II.TaxwarePrimaryStateTaxPercent, 0)
				 ELSE coalesce(II.TaxwarePSTStateTaxPercent, 0) END								 as PrimaryStateTaxPercent,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode,''),'N/A') = 'USA'
				 THEN coalesce(II.TaxwarePrimaryStateTaxAmount, 0)
				 ELSE coalesce(II.TaxwarePSTStateTaxAmount, 0) END								 as PrimaryStateTaxAmount,
			--Old Columns
            --coalesce(nullif(II.TaxwarePrimaryStateJurisdictionZipCode,''),'N/A')                 as PrimaryStateJurisdictionZipCode,
            --coalesce(II.TaxwarePrimaryStateTaxPercent,0)                                         as PrimaryStateTaxPercent,
            --coalesce(II.TaxwarePrimaryStateTaxAmount,0)                                          as PrimaryStateTaxAmount,
            ---------------------------------
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(II.TaxwareSecondaryStateJurisdictionZipCode, ''), 'N/A')
				 ELSE 'N/A' END																	 as SecondaryStateJurisdictionZipCode,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(II.TaxwareSecondaryStateTaxPercent, 0) 
				 ELSE 0.00000 END																 as SecondaryStateTaxPercent,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(II.TaxwareSecondaryStateTaxAmount, 0)
				 ELSE 0.0000 END																 as SecondaryStateTaxAmount,
			--Old Columns
            --coalesce(nullif(II.TaxwareSecondaryStateJurisdictionZipCode,''),'N/A')               as SecondaryStateJurisdictionZipCode,
            --coalesce(II.TaxwareSecondaryStateTaxPercent,0)                                       as SecondaryStateTaxPercent,
            --coalesce(II.TaxwareSecondaryStateTaxAmount,0)                                        as SecondaryStateTaxAmount,
            ---------------------------------
            coalesce(nullif(II.TaxwarePrimaryCityJurisdiction,''),'N/A')                         as PrimaryCityJurisdiction,
            coalesce(II.TaxwarePrimaryCityTaxPercent,0)                                          as PrimaryCityTaxPercent,
            coalesce(II.TaxwarePrimaryCityTaxAmount,0)                                           as PrimaryCityTaxAmount,
            ---------------------------------
            coalesce(nullif(II.TaxwareSecondaryCityJurisdiction,''),'N/A')                       as SecondaryCityJurisdiction,
            coalesce(II.TaxwareSecondaryCityTaxPercent,0)                                        as SecondaryCityTaxPercent,
            coalesce(II.TaxwareSecondaryCityTaxAmount,0)                                         as SecondaryCityTaxAmount,
            ---------------------------------
            coalesce(nullif(II.TaxwarePrimaryCountyJurisdiction,''),'N/A')                       as PrimaryCountyJurisdiction,
            coalesce(II.TaxwarePrimaryCountyTaxPercent,0)                                        as PrimaryCountyTaxPercent,
            coalesce(II.TaxwarePrimaryCountyTaxAmount,0)                                         as PrimaryCountyTaxAmount,
            ---------------------------------
            coalesce(nullif(II.TaxwareSecondaryCountyJurisdiction,''),'N/A')                     as SecondaryCountyJurisdiction,
            coalesce(II.TaxwareSecondaryCountyTaxPercent,0)                                      as SecondaryCountyTaxPercent,
            coalesce(II.TaxwareSecondaryCountyTaxAmount,0)                                       as SecondaryCountyTaxAmount,
            ---------------------------------
			--New Columns --#272
			'N/A'																				 as PrimaryCountryJurisdiction,
			coalesce(II.TaxwareGSTCountryTaxPercent, 0)	  										 as PrimaryCountryTaxPercent,
			coalesce(II.TaxwareGSTCountryTaxAmount, 0) 											 as PrimaryCountryTaxAmount,
			---------------------------------
			'N/A'   as SecondaryCountryJurisdiction,
			0.00000 as SecondaryCountryTaxPercent,
			0.0000  as SecondaryCountryTaxAmount
			---------------------------------

    from    INVOICES.dbo.InvoiceItem II with (nolock)
    inner Join
            Products.dbo.Product     P  with (nolock)
    on      II.ProductCode       = P.Code
    and     II.PriceVersion      = P.Priceversion
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     II.InvoiceGroupIDSeq = @IPBI_InvoiceGroupIDSeq
    and     II.ChargeTypecode    = @IPVC_ChargeTypeCode
    where   II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     II.InvoiceGroupIDSeq = @IPBI_InvoiceGroupIDSeq
    and     II.ChargeTypecode    = @IPVC_ChargeTypeCode
  end
  else if (@IPI_IsCustomBundleFlag=0) -- Alacarte Products
  begin
    Select Distinct P.DisplayName                                    as  ProductName,
           ----------------------------------------------------
           ---Revenue Finance Related Info : Section 1
           II.RevenueAccountCode                                      as RevenueAccountCode,
           coalesce(nullif(II.DeferredRevenueAccountCode,''),'N/A')   as DeferredRevenueAccountCode,
           II.RevenueTierCode                                         as RevenueTierCode,
           (case when II.RevenueRecognitionCode = 'IRR'
                   then 'Immediate Revenue Recognition'
                 when II.RevenueRecognitionCode = 'SRR'
                   then 'Scheduled Revenue Recognition'
                 when II.RevenueRecognitionCode = 'MRR'
                   then 'Manual Revenue Recognition'
                 else 'Unknown'
            end)                                                      as RevenueRecognition,    
            
            ----------------------------------------------------
            ---Tax Related Info : Section 2
            coalesce(nullif(II.TaxwareCode,''),'N/A')                                            as TaxwareCode,
            II.TaxAmount                                                                         as TotalTax,
            coalesce(nullif(II.TaxableAddressLine1,''),'N/A')                                    as TaxableAddressLine1,
            coalesce(nullif(II.TaxableAddressLine2,''),'')                                       as TaxableAddressLine2,
            coalesce(nullif(II.TaxableCity,''),'N/A')                                            as TaxableCity,
            coalesce(nullif(II.TaxableState,''),'N/A')                                           as TaxableState,
            coalesce(nullif(II.TaxableZip,''),'N/A')                                             as TaxableZip,
            coalesce(nullif(II.TaxableCountryCode,''),'N/A')                                     as TaxableCountryCode,
            ----------------------------------------------------
            ---Tax Related Info : Section 3
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(II.TaxwarePrimaryStateJurisdictionZipCode,''), 'N/A')
				 ELSE 'N/A' END																	 as PrimaryStateJurisdictionZipCode,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(II.TaxwarePrimaryStateTaxPercent, 0)
				 ELSE coalesce(II.TaxwarePSTStateTaxPercent, 0) END								 as PrimaryStateTaxPercent,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode,''),'N/A') = 'USA'
				 THEN coalesce(II.TaxwarePrimaryStateTaxAmount, 0)
				 ELSE coalesce(II.TaxwarePSTStateTaxAmount, 0) END								 as PrimaryStateTaxAmount,
			--Old Columns
            --coalesce(nullif(II.TaxwarePrimaryStateJurisdictionZipCode,''),'N/A')                 as PrimaryStateJurisdictionZipCode,
            --coalesce(II.TaxwarePrimaryStateTaxPercent,0)                                         as PrimaryStateTaxPercent,
            --coalesce(II.TaxwarePrimaryStateTaxAmount,0)                                          as PrimaryStateTaxAmount,
            ---------------------------------
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(II.TaxwareSecondaryStateJurisdictionZipCode, ''), 'N/A')
				 ELSE 'N/A' END																	 as SecondaryStateJurisdictionZipCode,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(II.TaxwareSecondaryStateTaxPercent, 0) 
				 ELSE 0.00000 END																 as SecondaryStateTaxPercent,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(II.TaxwareSecondaryStateTaxAmount, 0)
				 ELSE 0.0000 END																 as SecondaryStateTaxAmount,
			--Old Columns
            --coalesce(nullif(II.TaxwareSecondaryStateJurisdictionZipCode,''),'N/A')               as SecondaryStateJurisdictionZipCode,
            --coalesce(II.TaxwareSecondaryStateTaxPercent,0)                                       as SecondaryStateTaxPercent,
            --coalesce(II.TaxwareSecondaryStateTaxAmount,0)                                        as SecondaryStateTaxAmount,
            ---------------------------------
            coalesce(nullif(II.TaxwarePrimaryCityJurisdiction,''),'N/A')                         as PrimaryCityJurisdiction,
            coalesce(II.TaxwarePrimaryCityTaxPercent,0)                                          as PrimaryCityTaxPercent,
            coalesce(II.TaxwarePrimaryCityTaxAmount,0)                                           as PrimaryCityTaxAmount,
            ---------------------------------
            coalesce(nullif(II.TaxwareSecondaryCityJurisdiction,''),'N/A')                       as SecondaryCityJurisdiction,
            coalesce(II.TaxwareSecondaryCityTaxPercent,0)                                        as SecondaryCityTaxPercent,
            coalesce(II.TaxwareSecondaryCityTaxAmount,0)                                         as SecondaryCityTaxAmount,
            ---------------------------------
            coalesce(nullif(II.TaxwarePrimaryCountyJurisdiction,''),'N/A')                       as PrimaryCountyJurisdiction,
            coalesce(II.TaxwarePrimaryCountyTaxPercent,0)                                        as PrimaryCountyTaxPercent,
            coalesce(II.TaxwarePrimaryCountyTaxAmount,0)                                         as PrimaryCountyTaxAmount,
            ---------------------------------
            coalesce(nullif(II.TaxwareSecondaryCountyJurisdiction,''),'N/A')                     as SecondaryCountyJurisdiction,
            coalesce(II.TaxwareSecondaryCountyTaxPercent,0)                                      as SecondaryCountyTaxPercent,
            coalesce(II.TaxwareSecondaryCountyTaxAmount,0)                                       as SecondaryCountyTaxAmount,
            ---------------------------------
			--New Columns --#272
			'N/A'																				 as PrimaryCountryJurisdiction,
			coalesce(II.TaxwareGSTCountryTaxPercent, 0)	  										 as PrimaryCountryTaxPercent,
			coalesce(II.TaxwareGSTCountryTaxAmount, 0) 											 as PrimaryCountryTaxAmount,
			---------------------------------
			'N/A'   as SecondaryCountryJurisdiction,
			0.00000 as SecondaryCountryTaxPercent,
			0.0000  as SecondaryCountryTaxAmount
			---------------------------------

    from    INVOICES.dbo.InvoiceItem II with (nolock)
    inner Join
            Products.dbo.Product     P  with (nolock)
    on      II.ProductCode       = P.Code
    and     II.PriceVersion      = P.Priceversion
    and     II.IDSeq             = @IPBI_InvoiceItemIDSeq
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     II.InvoiceGroupIDSeq = @IPBI_InvoiceGroupIDSeq    
    and     II.ChargeTypecode    = @IPVC_ChargeTypeCode 
    where   II.IDSeq             = @IPBI_InvoiceItemIDSeq
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     II.InvoiceGroupIDSeq = @IPBI_InvoiceGroupIDSeq    
    and     II.ChargeTypecode    = @IPVC_ChargeTypeCode
  end
END
GO
