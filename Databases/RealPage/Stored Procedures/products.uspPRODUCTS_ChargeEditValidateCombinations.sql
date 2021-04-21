SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[uspPRODUCTS_ChargeEditValidateCombinations]    Script Date: 11/11/2008 ******/

CREATE PROCEDURE [products].[uspPRODUCTS_ChargeEditValidateCombinations]
								@IPVC_ProductCode		VARCHAR(50),
								@IPN_PriceVersion		NUMERIC(18,0),
								@IPVC_ChargeTypeCode	VARCHAR(50),
								@IPC_MeasureCode		CHAR(6),
								@IPC_FrequencyCode		CHAR(3),
								@IPVC_DisplayType		CHAR(6),
								@IPI_ChargeIDSeq		INT,
								@OPC_Valid				VARCHAR(50) OUTPUT,
								@OPC_Msg				VARCHAR(1000) OUTPUT
																	
AS
BEGIN
--	Select @IPI_ChargeIDSeq     = 2442,
--		   @IPVC_ChargeTypeCode = 'ILF',
--		   @IPVC_DisplayType    = 'BOTH'
		--===================================================================================================
        -- Code Starts FROM here
		--===================================================================================================
Declare
		@LVC_MeasureCode   VARCHAR(6),
		@LVC_FrequencyCode VARCHAR(6),
		@LVC_DisplayType   VARCHAR(6),
		@LVC_ProductCode   VARCHAR(50),
		@LVN_PriceVersion  NUMERIC(18,0)

SELECT	@LVC_MeasureCode   = MeasureCode,
		@LVC_FrequencyCode = FrequencyCode,
		@LVC_DisplayType   = DisplayType,
		@LVC_ProductCode   = ProductCode,
		@LVN_PriceVersion  = PriceVersion
FROM Products.dbo.Charge with (nolock)
WHERE ChargeIDSeq = @IPI_ChargeIDSeq

If (@IPVC_ChargeTypeCode = 'ILF') -- ChargeTypeCode = 'ILF' STARTs
	BEGIN
		--===================================================================================================
		--  if @IPVC_DisplayType = BOTH and if already another displaytype exists then error
		--===================================================================================================
        IF (@IPVC_DisplayType = 'BOTH')
          BEGIN
			If exists( SELECT TOP 1 1 
					   FROM Products.dbo.Charge with (nolock) 
					   where ProductCode = @IPVC_ProductCode 
						and PriceVersion = @IPN_PriceVersion 
                        and MeasureCode = @IPC_MeasureCode
                        and FrequencyCode = @IPC_FrequencyCode
						and DisplayType in ('SITE','PMC')
						and ChargeIDseq <> @IPI_ChargeIDSeq
						and @IPVC_DisplayType = 'BOTH'
                        and chargetypecode='ILF' )
					BEGIN
						SELECT @OPC_Valid='failed' ,@OPC_Msg =' Display type BOTH can not be selected,Charge already exists for display type Site or PMC' 
						RETURN -1 
						--SELECT 'failed-1'   
					   
					END  
				ELSE
					BEGIN
						SELECT @OPC_Valid='Success' ,@OPC_Msg =' ' 
						RETURN -1     
						--SELECT 'succe'    
						 
					END  
          END
		--===================================================================================================
		--  if @IPVC_DisplayType already exists in charge table then error
		--===================================================================================================
        IF (@IPVC_DisplayType <> 'BOTH')
          BEGIN

				If exists( SELECT TOP 1 1 
							   FROM Products.dbo.Charge with (nolock) 
							   where ProductCode = @IPVC_ProductCode 
								and PriceVersion = @IPN_PriceVersion 
								and DisplayType = 'BOTH' 
								and ChargeIDseq <> @IPI_ChargeIDSeq
								and MeasureCode = @IPC_MeasureCode
								and FrequencyCode = @IPC_FrequencyCode
								and chargetypecode='ILF')
						BEGIN
							SELECT @OPC_Valid='failed' ,@OPC_Msg ='Display type BOTH  exists with  same combination of Measure/Frequency/DisplayType'  
							RETURN -1 
		--					SELECT 'failed-2'  
		--						RETURN -1      
						END

				If exists( SELECT TOP 1 1 
						   FROM Products.dbo.Charge with (nolock) 
						   where ProductCode = @IPVC_ProductCode 
							and PriceVersion = @IPN_PriceVersion 
								and MeasureCode = @IPC_MeasureCode
								and FrequencyCode = @IPC_FrequencyCode
							and DisplayType = @IPVC_DisplayType 
							and ChargeIDseq <> @IPI_ChargeIDSeq
							and chargetypecode='ILF')
						BEGIN
							SELECT @OPC_Valid='failed' ,@OPC_Msg ='charge already exists with the display type  '+ @IPVC_DisplayType  
							RETURN -1 
							 
						END
						ELSE
							BEGIN
							SELECT @OPC_Valid='Success' ,@OPC_Msg =' ' 
							RETURN -1 
							    
							END
			END
    END -- ChargeTypeCode = 'ILF' ENDS
ELSE 
	BEGIN -- ChargeTypeCode = 'ACS' START
		--===================================================================================================
		--  if @IPVC_DisplayType = BOTH and if already another displaytype exists then error
		--===================================================================================================
        IF (@IPVC_DisplayType = 'BOTH')
          BEGIN
			If exists( SELECT TOP 1 1 
					   FROM Products.dbo.Charge WITH (NOLOCK) 
					   WHERE ProductCode = @LVC_ProductCode 
						and PriceVersion = @LVN_PriceVersion 
						and DisplayType in ('SITE','PMC')
						and ChargeIDseq <> @IPI_ChargeIDSeq
                        and MeasureCode = @IPC_MeasureCode
                        and FrequencyCode = @IPC_FrequencyCode
						and @IPVC_DisplayType = 'BOTH'
                        and chargetypecode='ACS' )
					BEGIN
						SELECT @OPC_Valid='failed' ,@OPC_Msg ='Display type BOTH can not be selected,Charge already exists for SITE or PMC with same combination of Measure/Frequency/DisplayType'
						RETURN -1 
						     
					END  
			If exists( SELECT TOP 1 1 
					   FROM Products.dbo.Charge WITH (NOLOCK) 
					   WHERE ProductCode = @LVC_ProductCode 
						and PriceVersion = @LVN_PriceVersion 
						and DisplayType in ('BOTH')
						and ChargeIDseq <> @IPI_ChargeIDSeq
                        and MeasureCode = @IPC_MeasureCode
                        and FrequencyCode = @IPC_FrequencyCode
						and @IPVC_DisplayType = 'BOTH'
                        and chargetypecode='ACS' )
					BEGIN
						SELECT @OPC_Valid='failed' ,@OPC_Msg ='Display type BOTH can not be selected,Charge already exists for SITE or PMC with same combination of Measure/Frequency/DisplayType'
						RETURN -1 
						     
					END  
				ELSE
					BEGIN
						SELECT @OPC_Valid='Success' ,@OPC_Msg =' ' 
						RETURN -1     
						   
					END  
          END
		--===================================================================================================
		--  if @IPVC_DisplayType already exists in charge table then error
		--===================================================================================================
        IF (@IPVC_DisplayType <> 'BOTH')
          BEGIN

				If exists( SELECT TOP 1 1 
							   FROM Products.dbo.Charge with (nolock) 
							   where ProductCode = @IPVC_ProductCode 
								and PriceVersion = @IPN_PriceVersion 
								and DisplayType = 'BOTH' 
								and ChargeIDseq <> @IPI_ChargeIDSeq
								and MeasureCode = @IPC_MeasureCode
								and FrequencyCode = @IPC_FrequencyCode
								and chargetypecode='ACS')
						BEGIN
							SELECT @OPC_Valid='failed' ,@OPC_Msg ='Display type BOTH  exists with  same combination of Measure/Frequency/DisplayType'  
							RETURN -1 
		--					SELECT 'failed-2'  
		--						RETURN -1      
						END

				If exists( SELECT TOP 1 1 
						   FROM Products.dbo.Charge with (nolock) 
						   where ProductCode = @IPVC_ProductCode 
							and PriceVersion = @IPN_PriceVersion 
							and DisplayType = @IPVC_DisplayType 
							and ChargeIDseq <> @IPI_ChargeIDSeq
							and MeasureCode = @IPC_MeasureCode
							and FrequencyCode = @IPC_FrequencyCode
							and chargetypecode='ACS')
						BEGIN
							SELECT @OPC_Valid='failed' ,@OPC_Msg ='charge already exists with  same combination of Measure/Frequency/DisplayType'  
							RETURN -1 
		--					SELECT 'failed-2'  
		--						RETURN -1      
						END
						ELSE
							BEGIN
								SELECT @OPC_Valid='Success' ,@OPC_Msg =' ' 
								RETURN -1 
		--						SELECT 'succ' 
		--						RETURN -1       
							END
		END
        
	END   -- ChargeTypeCode = 'ACS' ENDS
END -- Procedure Ends Here
GO
