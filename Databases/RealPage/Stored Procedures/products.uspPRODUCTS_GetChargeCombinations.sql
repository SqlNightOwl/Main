SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_GetChargeCombinations]
								@IPVC_ProductCode VARCHAR(50),
								@IPN_PriceVersion NUMERIC(18,0),
								@IPVC_ChargeType  VARCHAR(50)

AS
BEGIN

    SELECT      MeasureCode,
                FrequencyCode,
                DisplayType 
    FROM Products.dbo.Charge with(nolock)
    WHERE ProductCode=@IPVC_ProductCode
    AND   PriceVersion = @IPN_PriceVersion
	AND   ChargeTypeCode=@IPVC_ChargeType 
END
GO
