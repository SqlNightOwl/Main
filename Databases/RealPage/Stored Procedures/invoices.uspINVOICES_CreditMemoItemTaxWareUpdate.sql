SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_CreditMemoItemTaxWareUpdate]
-- Description     : Updates CreditMemo item rows from TaxWare
-- Revision History:
-- Author          : SRS
-- 08/13/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_CreditMemoItemTaxWareUpdate] (
  @IPVC_InvoiceID                         varchar(50),
  @IPVC_CreditMemoID                      varchar(50),
  @IPBI_CreditMemoItemID                  bigint,
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
  @IPN_GSTTaxAmount						  money,
  @IPN_PSTTaxAmount                       money,
  @IPN_GSTTaxRate						  numeric(30, 5),
  @IPN_PSTTaxRate                         numeric(30, 5)
)
AS
BEGIN
  set nocount on;
  ----------------------------------------------------------------------------------
  UPDATE INVOICES.dbo.CreditMemoItem
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
	  TaxwareGSTCountryTaxAmount				 = @IPN_GSTTaxAmount,
	  TaxwareGSTCountryTaxPercent				 = @IPN_GSTTaxRate,
	  TaxwarePSTStateTaxAmount					 = CASE WHEN ISNULL(@IPVC_TaxableCountryCode, '') = 'CAN' THEN @IPN_PSTTaxAmount ELSE 0.00 END,
	  TaxwarePSTStateTaxPercent					 = CASE WHEN ISNULL(@IPVC_TaxableCountryCode, '') = 'CAN' THEN @IPN_PSTTaxRate ELSE 0.00 END
  where IDSeq              = @IPBI_CreditMemoItemID
  and   CreditMemoIDSeq    = @IPVC_CreditMemoID
  ----------------------------------------------------------------------------------
  ---Call Sync Proc to sync Invoice Tables
  exec INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID=@IPVC_InvoiceID
  ----------------------------------------------------------------------------------
END



GO
