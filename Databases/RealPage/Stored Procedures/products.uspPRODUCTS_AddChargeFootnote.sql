SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_AddChargeFootnote]
-- Description     : This procedure gets ChargeFootNote Details
-- Input Parameters: @IPC_ChargeID       as    char
            


------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_AddChargeFootnote]
                                                    @IPC_ChargeID INT,
													@PVC_FootNote  VARCHAR(300)
													
                                                     
                                                    					
AS
BEGIN
DECLARE     @LVC_ProductCode CHAR(30),                   
			@LVC_PriceVersion  NUMERIC(18,3),                  
			@LVC_ChargeTypeCode CHAR(3),
			@LVC_MeasureCode CHAR(6),
			@LVC_FrequencyCode CHAR(6)

SELECT @LVC_ProductCode=ProductCode	FROM Products.dbo.Charge with (nolock) WHERE ChargeIDseq=@IPC_ChargeID
SELECT @LVC_PriceVersion=PriceVersion FROM Products.dbo.Charge with (nolock) WHERE ChargeIDseq=@IPC_ChargeID
SELECT @LVC_ChargeTypeCode=ChargeTypeCode FROM Products.dbo.Charge with (nolock) WHERE ChargeIDseq=@IPC_ChargeID
SELECT @LVC_MeasureCode=MeasureCode FROM Products.dbo.Charge with (nolock) WHERE ChargeIDseq=@IPC_ChargeID
SELECT @LVC_FrequencyCode=FrequencyCode FROM Products.dbo.Charge with (nolock) WHERE ChargeIDseq=@IPC_ChargeID

INSERT INTO Products.dbo.ChargeFootnote(
										 ChargeIDSeq,
										 ProductCode,
										 PriceVersion,
										 ChargeTypeCode,
										 MeasureCode,
										 FrequencyCode,
										 FootNote,
										 DisabledFlag
                                        )
							     VALUES(
                                        @IPC_ChargeID,
										@LVC_ProductCode,
										@LVC_PriceVersion,
										@LVC_ChargeTypeCode,
										@LVC_MeasureCode,
										@LVC_FrequencyCode,
										@PVC_FootNote,
										1
									   )	
END
GO
