SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
--------------------------------
-- procedure  : dbo.uspTAXRECALCINVOICES_CreditItemTaxAmountUpdate
-- purpose    : push updated CreditItem values back to the db
-- parameters : 32 facts about taxation on this one Credit Memo item
-- returns    : nothing special
--
--   Date                   Name                 Comment
-----------------------------------------------------------------------------
-- 2009-09-18   Larry Wilson          set [RECALCComplete] to indicate completion
-- 2009-09-15   Larry Wilson          initial implementation (PCR-6250)
--
-- Copyright  : copyright (c) 2009.  RealPage Inc.
--              This module is the confidential & proprietary property of RealPage Inc.
-----------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspTAXRECALCINVOICES_CreditItemTaxAmountUpdate] (
	@CreditItemID bigint
	,@IPN_TaxPercent numeric(30, 5)
	,@IPN_TaxAmount money
	,@IPN_StateTaxAmount money
	,@IPN_CountyTaxAmount money
	,@IPN_CityTaxAmount money
	,@IPN_SecStateTaxAmount money
	,@IPN_SecCountyTaxAmount money
	,@IPN_SecCityTaxAmount money
	,@IPN_StateTaxRate numeric(30, 5)
	,@IPN_CountyTaxRate numeric(30, 5)
	,@IPN_CityTaxRate numeric(30, 5)
	,@IPN_SecStateTaxRate numeric(30, 5)
	,@IPN_SecCountyTaxRate numeric(30, 5)
	,@IPN_SecCityTaxRate numeric(30, 5)
	,@IPN_StateBasis money
	,@IPN_CountyBasis money
	,@IPN_CityBasis money
	,@IPN_SecStateBasis money
	,@IPN_SecCountyBasis money
	,@IPN_SecCityBasis money
	,@IPVC_JurisZip varchar(20)
	,@IPVC_JurisCity varchar(70)
	,@IPVC_JurisCounty varchar(70)
	,@IPVC_JurisZipSec varchar(20)
	,@IPVC_JurisCitySec varchar(70)
	,@IPVC_JurisCountySec varchar(70)
	,@IPVC_StrStateType char(1)
	,@IPVC_StrCountyType char(1)
	,@IPVC_StrCityType char(1)
	,@IPVC_StrSecStateType char(1)
	,@IPVC_StrSecCountyType char(1)
	,@IPVC_StrSecCityType char(1)
)
AS
BEGIN
	IF NOT EXISTS (SELECT TOP 1 1 FROM [dbo].[CreditMemoItem] WITH (NOLOCK) WHERE [IDSeq]=@CreditItemID )
	BEGIN
		SELECT '0' AS confirmAction,
				'CreditItemID ' + convert(varchar,@CreditItemID) + ' does not exist' AS responseMsg
		RETURN(2)
	END
	UPDATE [dbo].[CreditMemoItem]
	  SET RECALCTaxPercent                               = @IPN_TaxPercent,
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
		[RECALCComplete] = 1
	WHERE [IDSeq]=@CreditItemID

	SELECT '1' AS confirmAction,
			'done' AS responseMsg
	RETURN(0)
END
GO
