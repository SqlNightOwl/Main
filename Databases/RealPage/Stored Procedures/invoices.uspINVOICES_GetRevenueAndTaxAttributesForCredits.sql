SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
Exec Invoices.dbo.uspINVOICES_GetRevenueAndTaxAttributesForCredits @IPVC_CreditMemoIDSeq = 'R0809000002',@IPBI_CreditMemoItemIDSeq = 1560,
@IPVC_InvoiceIDSeq = 'I0809000004',
@IPBI_InvoiceGroupIDSeq = 23289,@IPBI_InvoiceItemIDSeq=137677,@IPVC_ChargeTypeCode='ACS',@IPI_IsCustomBundleFlag = 0

Exec Invoices.dbo.uspINVOICES_GetRevenueAndTaxAttributesForCredits @IPVC_CreditMemoIDSeq = 'R0805000068',@IPBI_CreditMemoItemIDSeq = 6909,
@IPVC_InvoiceIDSeq = 'I0805000049',
@IPBI_InvoiceGroupIDSeq = 2895,@IPBI_InvoiceItemIDSeq=6909,@IPVC_ChargeTypeCode='ACS',@IPI_IsCustomBundleFlag = 1
*/
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_GetRevenueAndTaxAttributesForCredits]
-- Description     : This procedure gets Revenue And TaxAttributes for Invoiceitem
-- Input Parameters: See Below
--                   
-- OUTPUT          : 
-- Code Example    : Exec INVOICES.DBO.[uspINVOICES_GetRevenueAndTaxAttributesForCredits]  Parameters
-- 
-- Revision History:
-- Author          : SRS
-- 09/16/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetRevenueAndTaxAttributesForCredits]  (@IPVC_CreditMemoIDSeq      varchar(50),
                                                                            @IPBI_CreditMemoItemIDSeq  bigint=0,        
                                                                            @IPVC_InvoiceIDSeq         varchar(50),
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
            coalesce(nullif(CMI.TaxwareCode,''),'N/A')                                            as TaxwareCode,
            CMI.TaxAmount                                                                         as TotalTax,
            coalesce(nullif(II.TaxableAddressLine1,''),'N/A')                                     as TaxableAddressLine1,
            coalesce(nullif(II.TaxableAddressLine2,''),'')                                        as TaxableAddressLine2,
            coalesce(nullif(II.TaxableCity,''),'N/A')                                             as TaxableCity,
            coalesce(nullif(II.TaxableState,''),'N/A')                                            as TaxableState,
            coalesce(nullif(II.TaxableZip,''),'N/A')                                              as TaxableZip,
            coalesce(nullif(II.TaxableCountryCode,''),'N/A')                                      as TaxableCountryCode,
            ----------------------------------------------------
            ---Tax Related Info : Section 3
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(CMI.TaxwarePrimaryStateJurisdictionZipCode, ''), 'N/A') 
				 ELSE 'N/A' END																	  as PrimaryStateJurisdictionZipCode,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(CMI.TaxwarePrimaryStateTaxPercent, 0), 0) 
				 ELSE coalesce(nullif(CMI.TaxwarePSTStateTaxPercent, 0), 0) END					  as PrimaryStateTaxPercent,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(CMI.TaxwarePrimaryStateTaxAmount, 0), 0) 
				 ELSE coalesce(nullif(CMI.TaxwarePSTStateTaxAmount, 0), 0) END					  as PrimaryStateTaxAmount,
			-- Old Columns	
			--coalesce(nullif(CMI.TaxwarePrimaryStateJurisdictionZipCode, ''), 'N/A')				as PrimaryStateJurisdictionZipCode,
            --coalesce(CMI.TaxwarePrimaryStateTaxPercent,0)                                         as PrimaryStateTaxPercent,
            --coalesce(CMI.TaxwarePrimaryStateTaxAmount,0)                                          as PrimaryStateTaxAmount,
            ---------------------------------
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(CMI.TaxwareSecondaryStateJurisdictionZipCode,''),'N/A')
				 ELSE 'N/A' END																	  as SecondaryStateJurisdictionZipCode,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(CMI.TaxwareSecondaryStateTaxPercent, 0)
				 ELSE 0.00000 END																  as SecondaryStateTaxPercent,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(CMI.TaxwareSecondaryStateTaxAmount, 0)
				 ELSE 0.0000 END																  as SecondaryStateTaxAmount,
			-- Old Columns
			--coalesce(nullif(CMI.TaxwareSecondaryStateJurisdictionZipCode,''),'N/A')			  as SecondaryStateJurisdictionZipCode,
			--coalesce(CMI.TaxwareSecondaryStateTaxPercent, 0)									  as SecondaryStateTaxPercent,
			--coalesce(CMI.TaxwareSecondaryStateTaxAmount, 0)									  as SecondaryStateTaxAmount,
            ---------------------------------
            coalesce(nullif(CMI.TaxwarePrimaryCityJurisdiction,''),'N/A')                         as PrimaryCityJurisdiction,
            coalesce(CMI.TaxwarePrimaryCityTaxPercent,0)                                          as PrimaryCityTaxPercent,
            coalesce(CMI.TaxwarePrimaryCityTaxAmount,0)                                           as PrimaryCityTaxAmount,
            ---------------------------------
            coalesce(nullif(CMI.TaxwareSecondaryCityJurisdiction,''),'N/A')                       as SecondaryCityJurisdiction,
            coalesce(CMI.TaxwareSecondaryCityTaxPercent,0)                                        as SecondaryCityTaxPercent,
            coalesce(CMI.TaxwareSecondaryCityTaxAmount,0)                                         as SecondaryCityTaxAmount,
            ---------------------------------
            coalesce(nullif(CMI.TaxwarePrimaryCountyJurisdiction,''),'N/A')                       as PrimaryCountyJurisdiction,
            coalesce(CMI.TaxwarePrimaryCountyTaxPercent,0)                                        as PrimaryCountyTaxPercent,
            coalesce(CMI.TaxwarePrimaryCountyTaxAmount,0)                                         as PrimaryCountyTaxAmount,
            ---------------------------------
            coalesce(nullif(CMI.TaxwareSecondaryCountyJurisdiction,''),'N/A')                     as SecondaryCountyJurisdiction,
            coalesce(CMI.TaxwareSecondaryCountyTaxPercent,0)                                      as SecondaryCountyTaxPercent,
            coalesce(CMI.TaxwareSecondaryCountyTaxAmount,0)                                       as SecondaryCountyTaxAmount,
            ---------------------------------
			--New Columns --#272
			'N/A'																				  as PrimaryCountryJurisdiction,
			coalesce(CMI.TaxwareGSTCountryTaxPercent, 0)										  as PrimaryCountryTaxPercent,
			coalesce(CMI.TaxwareGSTCountryTaxAmount, 0) 										  as PrimaryCountryTaxAmount,
			---------------------------------
			'N/A'   as SecondaryCountryJurisdiction,
			0.00000 as SecondaryCountryTaxPercent,
			0.0000  as SecondaryCountryTaxAmount
			---------------------------------

    from    INVOICES.dbo.InvoiceItem II with (nolock)
    inner join
            INVOICES.dbo.CreditMemoItem CMI with (nolock)
    on      II.InvoiceIDSeq      = CMI.InvoiceIDSeq
    and     II.InvoiceGroupIDSeq = CMI.InvoiceGroupIDSeq
    and     II.IDSeq             = CMI.InvoiceItemIDSeq
    and     CMI.CreditMemoIDSeq  = @IPVC_CreditMemoIDSeq    
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     II.InvoiceGroupIDSeq = @IPBI_InvoiceGroupIDSeq
    and     II.ChargeTypecode    = @IPVC_ChargeTypeCode
    inner Join
            Products.dbo.Product     P  with (nolock)
    on      II.ProductCode       = P.Code
    and     II.PriceVersion      = P.Priceversion    
    where   CMI.CreditMemoIDSeq  = @IPVC_CreditMemoIDSeq    
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     II.InvoiceGroupIDSeq = @IPBI_InvoiceGroupIDSeq
    and     II.ChargeTypecode    = @IPVC_ChargeTypeCode
  end
  else if (@IPI_IsCustomBundleFlag=0) -- Alacarte Products
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
            coalesce(nullif(CMI.TaxwareCode,''),'N/A')                                            as TaxwareCode,
            CMI.TaxAmount                                                                         as TotalTax,
            coalesce(nullif(II.TaxableAddressLine1,''),'N/A')                                     as TaxableAddressLine1,
            coalesce(nullif(II.TaxableAddressLine2,''),'')                                        as TaxableAddressLine2,
            coalesce(nullif(II.TaxableCity,''),'N/A')                                             as TaxableCity,
            coalesce(nullif(II.TaxableState,''),'N/A')                                            as TaxableState,
            coalesce(nullif(II.TaxableZip,''),'N/A')                                              as TaxableZip,
            coalesce(nullif(II.TaxableCountryCode,''),'N/A')                                      as TaxableCountryCode,
            ----------------------------------------------------
            ---Tax Related Info : Section 3
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(CMI.TaxwarePrimaryStateJurisdictionZipCode, ''), 'N/A') 
				 ELSE 'N/A' END																	  as PrimaryStateJurisdictionZipCode,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(CMI.TaxwarePrimaryStateTaxPercent, 0), 0) 
				 ELSE coalesce(nullif(CMI.TaxwarePSTStateTaxPercent, 0), 0) END					  as PrimaryStateTaxPercent,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(CMI.TaxwarePrimaryStateTaxAmount, 0), 0) 
				 ELSE coalesce(nullif(CMI.TaxwarePSTStateTaxAmount, 0), 0) END					  as PrimaryStateTaxAmount,
			-- Old Columns	
			--coalesce(nullif(CMI.TaxwarePrimaryStateJurisdictionZipCode, ''), 'N/A')				as PrimaryStateJurisdictionZipCode,
            --coalesce(CMI.TaxwarePrimaryStateTaxPercent,0)                                         as PrimaryStateTaxPercent,
            --coalesce(CMI.TaxwarePrimaryStateTaxAmount,0)                                          as PrimaryStateTaxAmount,
            ---------------------------------
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(nullif(CMI.TaxwareSecondaryStateJurisdictionZipCode,''),'N/A')
				 ELSE 'N/A' END																	  as SecondaryStateJurisdictionZipCode,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(CMI.TaxwareSecondaryStateTaxPercent, 0)
				 ELSE 0.00000 END																  as SecondaryStateTaxPercent,
			CASE WHEN coalesce(nullif(II.TaxableCountryCode, ''), 'N/A') = 'USA'
				 THEN coalesce(CMI.TaxwareSecondaryStateTaxAmount, 0)
				 ELSE 0.0000 END																  as SecondaryStateTaxAmount,
			-- Old Columns
			--coalesce(nullif(CMI.TaxwareSecondaryStateJurisdictionZipCode,''),'N/A')			  as SecondaryStateJurisdictionZipCode,
			--coalesce(CMI.TaxwareSecondaryStateTaxPercent, 0)									  as SecondaryStateTaxPercent,
			--coalesce(CMI.TaxwareSecondaryStateTaxAmount, 0)									  as SecondaryStateTaxAmount,
            ---------------------------------

            coalesce(nullif(CMI.TaxwarePrimaryCityJurisdiction,''),'N/A')                         as PrimaryCityJurisdiction,
            coalesce(CMI.TaxwarePrimaryCityTaxPercent,0)                                          as PrimaryCityTaxPercent,
            coalesce(CMI.TaxwarePrimaryCityTaxAmount,0)                                           as PrimaryCityTaxAmount,
            ---------------------------------
            coalesce(nullif(CMI.TaxwareSecondaryCityJurisdiction,''),'N/A')                       as SecondaryCityJurisdiction,
            coalesce(CMI.TaxwareSecondaryCityTaxPercent,0)                                        as SecondaryCityTaxPercent,
            coalesce(CMI.TaxwareSecondaryCityTaxAmount,0)                                         as SecondaryCityTaxAmount,
            ---------------------------------
            coalesce(nullif(CMI.TaxwarePrimaryCountyJurisdiction,''),'N/A')                       as PrimaryCountyJurisdiction,
            coalesce(CMI.TaxwarePrimaryCountyTaxPercent,0)                                        as PrimaryCountyTaxPercent,
            coalesce(CMI.TaxwarePrimaryCountyTaxAmount,0)                                         as PrimaryCountyTaxAmount,
            ---------------------------------
            coalesce(nullif(CMI.TaxwareSecondaryCountyJurisdiction,''),'N/A')                     as SecondaryCountyJurisdiction,
            coalesce(CMI.TaxwareSecondaryCountyTaxPercent,0)                                      as SecondaryCountyTaxPercent,
            coalesce(CMI.TaxwareSecondaryCountyTaxAmount,0)                                       as SecondaryCountyTaxAmount,
            ---------------------------------
			--New Columns --#272
			'N/A'																				  as PrimaryCountryJurisdiction,
			coalesce(CMI.TaxwareGSTCountryTaxPercent, 0)										  as PrimaryCountryTaxPercent,
			coalesce(CMI.TaxwareGSTCountryTaxAmount, 0) 										  as PrimaryCountryTaxAmount,
			---------------------------------
			'N/A'   as SecondaryCountryJurisdiction,
			0.00000 as SecondaryCountryTaxPercent,
			0.0000  as SecondaryCountryTaxAmount
			---------------------------------
    from    INVOICES.dbo.InvoiceItem II with (nolock)
    inner join
            INVOICES.dbo.CreditMemoItem CMI with (nolock)
    on      II.InvoiceIDSeq      = CMI.InvoiceIDSeq
    and     II.InvoiceGroupIDSeq = CMI.InvoiceGroupIDSeq
    and     II.IDSeq             = CMI.InvoiceItemIDSeq
    and     CMI.CreditMemoIDSeq  = @IPVC_CreditMemoIDSeq
    and     CMI.IDSeq            = @IPBI_CreditMemoItemIDSeq
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     II.IDSeq             = @IPBI_InvoiceItemIDSeq
    and     II.InvoiceGroupIDSeq = @IPBI_InvoiceGroupIDSeq
    and     II.ChargeTypecode    = @IPVC_ChargeTypeCode
    inner Join
            Products.dbo.Product     P  with (nolock)
    on      II.ProductCode       = P.Code
    and     II.PriceVersion      = P.Priceversion    
    where   CMI.CreditMemoIDSeq  = @IPVC_CreditMemoIDSeq
    and     CMI.IDSeq            = @IPBI_CreditMemoItemIDSeq
    and     II.InvoiceIDSeq      = @IPVC_InvoiceIDSeq
    and     II.IDSeq             = @IPBI_InvoiceItemIDSeq
    and     II.InvoiceGroupIDSeq = @IPBI_InvoiceGroupIDSeq
    and     II.ChargeTypecode    = @IPVC_ChargeTypeCode
  end
END
GO
