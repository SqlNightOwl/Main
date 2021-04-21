SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_InvoiceItemTaxAmountUpdate]
-- Description     : Updates the tax amount for a single item
-- Revision History:
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-09-18   Larry Wilson          set [RECALCComplete] to indicate completion (PCR-6250)
-- 2007-11-26   Eric Font             initial implementation
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
-----------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_InvoiceItemTaxAmountUpdate] (
  @IPVC_InvoiceID varchar(20),
  @IPVC_InvoiceItemID varchar(20),
  @IPN_TaxPercent numeric(30, 5), 
  @IPN_TaxAmount money,
  @IPN_StateTaxAmount money,
  @IPN_CountyTaxAmount money,
  @IPN_CityTaxAmount money,
  @IPN_SecStateTaxAmount money,
  @IPN_SecCountyTaxAmount money,
  @IPN_SecCityTaxAmount money,
  @IPN_StateTaxRate numeric(30, 5),
  @IPN_CountyTaxRate numeric(30, 5),
  @IPN_CityTaxRate numeric(30, 5),
  @IPN_SecStateTaxRate numeric(30, 5),
  @IPN_SecCountyTaxRate numeric(30, 5),
  @IPN_SecCityTaxRate numeric(30, 5),
  @IPN_StateBasis money,
  @IPN_CountyBasis money,
  @IPN_CityBasis money,
  @IPN_SecStateBasis money,
  @IPN_SecCountyBasis money,
  @IPN_SecCityBasis money,
  @IPVC_JurisZip varchar(20),
  @IPVC_JurisCity varchar(70),
  @IPVC_JurisCounty varchar(70),
  @IPVC_JurisZipSec varchar(20),
  @IPVC_JurisCitySec varchar(70),
  @IPVC_JurisCountySec varchar(70),
  @IPVC_StrStateType char(1),
  @IPVC_StrCountyType char(1),
  @IPVC_StrCityType char(1),
  @IPVC_StrSecStateType char(1),
  @IPVC_StrSecCountyType char(1),
  @IPVC_StrSecCityType char(1),
  @IPN_GSTTaxAmount			  money = 0,
  @IPN_PSTTaxAmount                       money = 0,
  @IPN_GSTTaxRate			  numeric(30,5) = 0.00,
  @IPN_PSTTaxRate                         numeric(30,5) = 0.00
)
AS
BEGIN
  UPDATE [dbo].[InvoiceItem]
  SET RECALCTaxPercent                                 = @IPN_TaxPercent,
      RECALCTaxAmount                                  = @IPN_TaxAmount,
      RECALCTaxwarePrimaryStateTaxAmount               = @IPN_StateTaxAmount,
      RECALCTaxwarePrimaryCountyTaxAmount              = @IPN_CountyTaxAmount,
      RECALCTaxwarePrimaryCityTaxAmount                = @IPN_CityTaxAmount,
      RECALCTaxwareSecondaryStateTaxAmount             = @IPN_SecStateTaxAmount,
      RECALCTaxwareSecondaryCountyTaxAmount            = @IPN_SecCountyTaxAmount,
      RECALCTaxwareSecondaryCityTaxAmount              = @IPN_SecCityTaxAmount,
      RECALCTaxwarePrimaryStateTaxPercent              = @IPN_StateTaxRate,
      RECALCTaxwarePrimaryCountyTaxPercent             = @IPN_CountyTaxRate,
      RECALCTaxwarePrimaryCityTaxPercent               = @IPN_CityTaxRate,
      RECALCTaxwareSecondaryStateTaxPercent            = @IPN_SecStateTaxRate,
      RECALCTaxwareSecondaryCountyTaxPercent           = @IPN_SecCountyTaxRate,
      RECALCTaxwareSecondaryCityTaxPercent             = @IPN_SecCityTaxRate,
      RECALCTaxwarePrimaryStateTaxBasisAmount          = @IPN_StateBasis,
      RECALCTaxwarePrimaryCountyTaxBasisAmount         = @IPN_CountyBasis,
      RECALCTaxwarePrimaryCityTaxBasisAmount           = @IPN_CityBasis,
      RECALCTaxwareSecondaryStateTaxBasisAmount        = @IPN_SecStateBasis,
      RECALCTaxwareSecondaryCountyTaxBasisAmount       = @IPN_SecCountyBasis,
      RECALCTaxwareSecondaryCityTaxBasisAmount         = @IPN_SecCityBasis,
      RECALCTaxwarePrimaryStateJurisdictionZipCode     = @IPVC_JurisZip,
      RECALCTaxwarePrimaryCityJurisdiction             = @IPVC_JurisCity,
      RECALCTaxwarePrimaryCountyJurisdiction           = @IPVC_JurisCounty,
      RECALCTaxwareSecondaryStateJurisdictionZipCode   = @IPVC_JurisZipSec,
      RECALCTaxwareSecondaryCityJurisdiction           = @IPVC_JurisCitySec,
      RECALCTaxwareSecondaryCountyJurisdiction         = @IPVC_JurisCountySec,
      RECALCTaxwarePrimaryStateSalesUseTaxIndicator    = @IPVC_StrStateType,
      RECALCTaxwarePrimaryCountySalesUseTaxIndicator   = @IPVC_StrCountyType,
      RECALCTaxwarePrimaryCitySalesUseTaxIndicator     = @IPVC_StrCityType,
      RECALCTaxwareSecondaryStateSalesUseTaxIndicator  = @IPVC_StrSecStateType,
      RECALCTaxwareSecondaryCountySalesUseTaxIndicator = @IPVC_StrSecCountyType,
      RECALCTaxwareSecondaryCitySalesUseTaxIndicator   = @IPVC_StrSecCityType,
      RECALCTaxwareGSTCountryTaxAmount		       = @IPN_GSTTaxAmount,
      RECALCTaxwareGSTCountryTaxPercent		       = @IPN_GSTTaxRate,
      RECALCTaxwarePSTStateTaxAmount		       = (CASE WHEN ISNULL(TaxableCountryCode, '') = 'CAN' THEN @IPN_PSTTaxAmount ELSE 0.00 END),
      RECALCTaxwarePSTStateTaxPercent		       = (CASE WHEN ISNULL(TaxableCountryCode, '') = 'CAN' THEN @IPN_PSTTaxRate ELSE 0.00 END),
      [RECALCComplete] = 1
  where IDSeq = @IPVC_InvoiceItemID
  and   InvoiceIDSeq = @IPVC_InvoiceID
END
GO
