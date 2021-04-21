SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_ValidateChargeCombinations]
												(	@IPVC_ProductCode		VARCHAR(50),
													@IPN_PriceVersion		NUMERIC(18,0),
													@IPVC_ChargeTypeCode	VARCHAR(50),
													@IPC_MeasureCode		CHAR(6),
													@IPC_FrequencyCode		CHAR(3),
													@IPVC_DisplayType		CHAR(6),
													@OPC_Valid				VARCHAR(50) OUTPUT,
													@OPC_Msg				VARCHAR(1000) OUTPUT
															)
								 

AS
BEGIN
DECLARE @LVC_DisplayType   VARCHAR(6)
SELECT  @LVC_DisplayType = @IPVC_DisplayType

IF (@IPVC_ChargeTypeCode = 'ILF') -- ChargeTypeCode = 'ILF' STARTs
	BEGIN
		--===================================================================================================
		--  if @IPVC_DisplayType = BOTH and if already another displaytype exists then error
		--===================================================================================================
        IF (@IPVC_DisplayType = 'BOTH')
          BEGIN
			If exists( select top 1 1 
					   from Products.dbo.Charge with (nolock) 
					   where ProductCode = @IPVC_ProductCode 
						and PriceVersion = @IPN_PriceVersion 
						and  MeasureCode = @IPC_MeasureCode 
						and  FrequencyCode = @IPC_FrequencyCode 
						and DisplayType in ('SITE','PMC')
                        and chargetypecode='ILF' )
					BEGIN
						SELECT @OPC_Valid='failed' ,@OPC_Msg ='Display type BOTH can not be selected,Charge already exists for SITE or PMC' 
						return -1 
						--SELECT 'failed-1'   
					   
					END  
		 ELSE
					BEGIN
						If exists( select top 1 1 
								   from Products.dbo.Charge with (nolock) 
								   where ProductCode   = @IPVC_ProductCode 
									and  PriceVersion  = @IPN_PriceVersion 
									and  MeasureCode   = @IPC_MeasureCode 
									and  FrequencyCode = @IPC_FrequencyCode 
									and  DisplayType in (@LVC_DisplayType,'BOTH')
									and  chargetypecode='ILF' )
								BEGIN
									SELECT @OPC_Valid='failed' ,@OPC_Msg ='Charge already exists for '+@IPVC_DisplayType+' with same combinations of Measure/Frequency/DisplayType'
									return -1 
									--SELECT 'failed-1'   
								   
								END
						ELSE
					BEGIN
						If exists( select top 1 1 
								   from Products.dbo.Charge with (nolock) 
								   where ProductCode	= @IPVC_ProductCode 
									and  PriceVersion	= @IPN_PriceVersion 
									and  MeasureCode	= @IPC_MeasureCode 
									and  FrequencyCode	= @IPC_FrequencyCode 
									and  DisplayType	not in (@LVC_DisplayType)
									and  chargetypecode='ILF' )
								BEGIN
									SELECT @OPC_Valid='Edit' ,@OPC_Msg =''
									return -1 
									--SELECT 'failed-1'   
								   
								END



						SELECT @OPC_Valid='Success' ,@OPC_Msg ='' 
						return -1     
						--SELECT 'succe'    
				END		 
					END  
          END
		--===================================================================================================
		--  if @IPVC_DisplayType already exists in charge table then error
		--===================================================================================================
        IF (@IPVC_DisplayType = @LVC_DisplayType)
          BEGIN
			If exists( select top 1 1 
					   from Products.dbo.Charge with (nolock) 
					   where ProductCode = @IPVC_ProductCode 
						and PriceVersion = @IPN_PriceVersion 
						and  MeasureCode = @IPC_MeasureCode 
						and  FrequencyCode = @IPC_FrequencyCode 
						and DisplayType in (@LVC_DisplayType,'BOTH')
                        and chargetypecode='ILF' )
					BEGIN
						SELECT @OPC_Valid='failed' ,@OPC_Msg ='Charge already exists for '+@IPVC_DisplayType+' with same combinations of Measure/Frequency/DisplayType'
						return -1 
						--SELECT 'failed-1'   
					   
					END  
				ELSE
					BEGIN
								If exists( select top 1 1 
								   from Products.dbo.Charge with (nolock) 
								   where ProductCode	= @IPVC_ProductCode 
									and  PriceVersion	= @IPN_PriceVersion 
									and  MeasureCode	= @IPC_MeasureCode 
									and  FrequencyCode	= @IPC_FrequencyCode 
									and  DisplayType	not in (@LVC_DisplayType)
									and  chargetypecode='ILF' )
								BEGIN
									SELECT @OPC_Valid='Edit' ,@OPC_Msg =''
									return -1 
									--SELECT 'failed-1'   
								   
								END
						SELECT @OPC_Valid='Success' ,@OPC_Msg =' ' 
						return -1     
						--SELECT 'succe'    
						 
					END  
          END

    END -- ChargeTypeCode = 'ILF' ENDS
ELSE 
	BEGIN -- ChargeTypeCode = 'ACS' START
		IF(@IPVC_DisplayType='BOTH')   
				BEGIN
				IF exists (SELECT  top 1 1 FROM charge WHERE 
							ProductCode= @IPVC_ProductCode
							and  MeasureCode = @IPC_MeasureCode 
							and  FrequencyCode = @IPC_FrequencyCode 
							and  ChargeTypeCode=@IPVC_ChargeTypeCode
							and  PriceVersion=@IPN_PriceVersion
							and  DisplayType in( 'SITE','PMC'))
					BEGIN			
						SELECT @OPC_Valid='failed',@OPC_Msg='Charge already exists for Site or PMC with same combinations of Measure/Frequency/DisplayType'
					END
					ELSE
						BEGIN
							if exists (SELECT  top 1 1 FROM charge WHERE 
										ProductCode= @IPVC_ProductCode
										and  MeasureCode = @IPC_MeasureCode 
										and  FrequencyCode = @IPC_FrequencyCode 
										and  ChargeTypeCode=@IPVC_ChargeTypeCode
										and  PriceVersion=@IPN_PriceVersion
										and  DisplayType in ('BOTH',@LVC_DisplayType))
								BEGIN			
									SELECT @OPC_Valid='failed' ,@OPC_Msg='Charge already exists for  '+ @IPVC_DisplayType +' with same combinations of Measure/Frequency/DisplayType'
									return -1
								END
							If exists( select top 1 1 
								   from Products.dbo.Charge with (nolock) 
								   where ProductCode	= @IPVC_ProductCode 
									and  PriceVersion	= @IPN_PriceVersion 
									and  MeasureCode	= @IPC_MeasureCode 
									and  FrequencyCode	= @IPC_FrequencyCode 
									and  DisplayType	not in (@LVC_DisplayType)
									and  chargetypecode=@IPVC_ChargeTypeCode )
								BEGIN
									SELECT @OPC_Valid='Edit' ,@OPC_Msg =''
									return -1 
									--SELECT 'failed-1'   
								   
								END

							SELECT @OPC_Valid='Success',@OPC_Msg=''  
						END
				END

		ElSE
			IF(@IPVC_DisplayType = @LVC_DisplayType)
				BEGIN
					if exists (SELECT  top 1 1 FROM charge WHERE 
								ProductCode= @IPVC_ProductCode
								and  MeasureCode = @IPC_MeasureCode 
								and  FrequencyCode = @IPC_FrequencyCode 
								and  ChargeTypeCode=@IPVC_ChargeTypeCode
								 
								and  PriceVersion=@IPN_PriceVersion
								and  DisplayType in ('BOTH',@LVC_DisplayType))
						BEGIN			
							SELECT @OPC_Valid='failed' ,@OPC_Msg='Charge already exists for  '+ @IPVC_DisplayType +' with same combinations of Measure/Frequency/DisplayType'
							return -1
						END
					  ELSE
						If exists( select top 1 1 
								   from Products.dbo.Charge with (nolock) 
								   where ProductCode	= @IPVC_ProductCode 
									and  PriceVersion	= @IPN_PriceVersion 
									and  MeasureCode	= @IPC_MeasureCode 
									and  FrequencyCode	= @IPC_FrequencyCode 
									and  DisplayType	not in (@LVC_DisplayType)
									and  chargetypecode=@IPVC_ChargeTypeCode )
								BEGIN
									SELECT @OPC_Valid='Edit' ,@OPC_Msg =''
									return -1 
									--SELECT 'failed-1'   
								END

						BEGIN
							SELECT @OPC_Valid='Success',@OPC_Msg=''  
						END
                 END
           
    END   -- ChargeTypeCode = 'ILF' ENDS
--/******************************************************************************************/
  /******************************************************************************************/
     
END
GO
