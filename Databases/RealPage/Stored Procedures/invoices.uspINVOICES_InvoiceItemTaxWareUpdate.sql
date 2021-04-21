SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_InvoiceItemTaxWareUpdate]
-- Description     : Updates InvoiceItem rows from TaxWare
-- Revision History:
-- Author          : Eric Font
-- 11/25/2007       : Stored Procedure Created.
------------------------------------------------------------------------------------------------------

CREATE PROCEDURE [invoices].[uspINVOICES_InvoiceItemTaxWareUpdate] (
  @IPVC_InvoiceID                         varchar(20),
  @IPVC_InvoiceItemID                     varchar(20),
  @IPN_TaxPercent                         numeric(30, 5), 
  @IPN_TaxAmount                          money,
  @IPN_StateTaxAmount                     money,
  @IPN_CountyTaxAmount                    money,
  @IPN_CityTaxAmount                      money,
  @IPN_SecStateTaxAmount                  money,
  @IPN_SecCountyTaxAmount                 money,
  @IPN_SecCityTaxAmount                   money,
  @IPN_StateTaxRate                       numeric(30, 5),
  @IPN_CountyTaxRate                      numeric(30, 5),
  @IPN_CityTaxRate                        numeric(30, 5),
  @IPN_SecStateTaxRate                    numeric(30, 5),
  @IPN_SecCountyTaxRate                   numeric(30, 5),
  @IPN_SecCityTaxRate                     numeric(30, 5),
  @IPN_StateBasis                         money,
  @IPN_CountyBasis                        money,
  @IPN_CityBasis                          money,
  @IPN_SecStateBasis                      money,
  @IPN_SecCountyBasis                     money,
  @IPN_SecCityBasis                       money,
  @IPVC_JurisZip                          varchar(20),
  @IPVC_JurisCity                         varchar(70),
  @IPVC_JurisCounty                       varchar(70),
  @IPVC_JurisZipSec                       varchar(20),
  @IPVC_JurisCitySec                      varchar(70),
  @IPVC_JurisCountySec                    varchar(70),
  @IPVC_StrStateType                      char(1),
  @IPVC_StrCountyType                     char(1),
  @IPVC_StrCityType                       char(1),
  @IPVC_StrSecStateType                   char(1),
  @IPVC_StrSecCountyType                  char(1),
  @IPVC_StrSecCityType                    char(1),
  @IPVC_TaxableAddressLine1               varchar(500)='',
  @IPVC_TaxableAddressLine2               varchar(500)='',           
  @IPVC_TaxableCity                       varchar(500)='',
  @IPVC_TaxableState                      varchar(100)='',
  @IPVC_TaxableZip                        varchar(50) ='',
  @IPVC_TaxableCountryCode                varchar(50) ='',
  @IPVC_TaxableCounty                     varchar(100)='',
  @IPVC_TaxableAddressTypeCode            varchar(3)  ='',
  @IPI_EOMProcessorFlag					  int = 0,
  @IPN_GSTTaxAmount						  money,
  @IPN_PSTTaxAmount                       money,
  @IPN_GSTTaxRate						  numeric(30, 5),
  @IPN_PSTTaxRate                         numeric(30, 5)
)
AS
BEGIN
  set nocount on;
  ----------------------------------------------------------------------------------
  UPDATE INVOICES.dbo.InvoiceItem
  set TaxPercent                                 = @IPN_TaxPercent,
      TaxAmount                                  = @IPN_TaxAmount,
      TaxwarePrimaryStateTaxAmount               = CASE WHEN ISNULL(@IPVC_TaxableCountryCode, '') = 'USA' THEN @IPN_StateTaxAmount ELSE 0.00 END,
      TaxwarePrimaryCountyTaxAmount              = @IPN_CountyTaxAmount,
      TaxwarePrimaryCityTaxAmount                = @IPN_CityTaxAmount,
      TaxwareSecondaryStateTaxAmount             = @IPN_SecStateTaxAmount,
      TaxwareSecondaryCountyTaxAmount            = @IPN_SecCountyTaxAmount,
      TaxwareSecondaryCityTaxAmount              = @IPN_SecCityTaxAmount,
      TaxwarePrimaryStateTaxPercent              = CASE WHEN ISNULL(@IPVC_TaxableCountryCode, '') = 'USA' THEN @IPN_StateTaxRate ELSE 0.00 END,
      TaxwarePrimaryCountyTaxPercent             = @IPN_CountyTaxRate,
      TaxwarePrimaryCityTaxPercent               = @IPN_CityTaxRate,
      TaxwareSecondaryStateTaxPercent            = @IPN_SecStateTaxRate,
      TaxwareSecondaryCountyTaxPercent           = @IPN_SecCountyTaxRate,
      TaxwareSecondaryCityTaxPercent             = @IPN_SecCityTaxRate,
      TaxwarePrimaryStateTaxBasisAmount          = @IPN_StateBasis,
      TaxwarePrimaryCountyTaxBasisAmount         = @IPN_CountyBasis,
      TaxwarePrimaryCityTaxBasisAmount           = @IPN_CityBasis,
      TaxwareSecondaryStateTaxBasisAmount        = @IPN_SecStateBasis,
      TaxwareSecondaryCountyTaxBasisAmount       = @IPN_SecCountyBasis,
      TaxwareSecondaryCityTaxBasisAmount         = @IPN_SecCityBasis,
      TaxwarePrimaryStateJurisdictionZipCode     = @IPVC_JurisZip,
      TaxwarePrimaryCityJurisdiction             = @IPVC_JurisCity,
      TaxwarePrimaryCountyJurisdiction           = @IPVC_JurisCounty,
      TaxwareSecondaryStateJurisdictionZipCode   = @IPVC_JurisZipSec,
      TaxwareSecondaryCityJurisdiction           = @IPVC_JurisCitySec,
      TaxwareSecondaryCountyJurisdiction         = @IPVC_JurisCountySec,
      TaxwarePrimaryStateSalesUseTaxIndicator    = @IPVC_StrStateType,
      TaxwarePrimaryCountySalesUseTaxIndicator   = @IPVC_StrCountyType,
      TaxwarePrimaryCitySalesUseTaxIndicator     = @IPVC_StrCityType,
      TaxwareSecondaryStateSalesUseTaxIndicator  = @IPVC_StrSecStateType,
      TaxwareSecondaryCountySalesUseTaxIndicator = @IPVC_StrSecCountyType,
      TaxwareSecondaryCitySalesUseTaxIndicator   = @IPVC_StrSecCityType,
      TaxableAddressLine1                        = Nullif(@IPVC_TaxableAddressLine1,''),
      TaxableAddressLine2                        = Nullif(@IPVC_TaxableAddressLine2,''),
      TaxableCity                                = Nullif(@IPVC_TaxableCity,''),
      TaxableState                               = Nullif(@IPVC_TaxableState,''),
      TaxableZip                                 = Nullif(@IPVC_TaxableZip,''),
      TaxableCountryCode                         = Nullif(@IPVC_TaxableCountryCode,''),
      TaxableCounty                              = Nullif(@IPVC_TaxableCounty,''),
      TaxableAddressTypeCode                     = Nullif(@IPVC_TaxableAddressTypeCode,''),
	  TaxwareGSTCountryTaxAmount				 = @IPN_GSTTaxAmount,
	  TaxwareGSTCountryTaxPercent				 = @IPN_GSTTaxRate,
	  TaxwarePSTStateTaxAmount					 = CASE WHEN ISNULL(@IPVC_TaxableCountryCode, '') = 'CAN' THEN @IPN_PSTTaxAmount ELSE 0.00 END,
	  TaxwarePSTStateTaxPercent					 = CASE WHEN ISNULL(@IPVC_TaxableCountryCode, '') = 'CAN' THEN @IPN_PSTTaxRate ELSE 0.00 END
  where IDSeq        = @IPVC_InvoiceItemID
  and   InvoiceIDSeq = @IPVC_InvoiceID

  ----------------------------------------------------------------------------------
  ---Call Sync Proc to sync Invoice Tables
IF (@IPI_EOMProcessorFlag = 0)
BEGIN
  exec INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID=@IPVC_InvoiceID
END

  ----------------------------------------------------------------------------------
END

GO
