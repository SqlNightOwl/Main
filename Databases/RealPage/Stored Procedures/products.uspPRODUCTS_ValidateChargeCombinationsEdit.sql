SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [products].[uspPRODUCTS_ValidateChargeCombinationsEdit]
								@IPVC_ProductCode varchar(50),
								@IPN_PriceVersion numeric(18,0),
								@IPVC_ChargeType varchar(50),
								@IPC_MeasureCode char(6),
								@IPC_FrequencyCode char(3),
								@IPC_DisplayType char(6),
								@IPC_ChargeID int
								 
								 

AS
BEGIN
	DECLARE @IPLC_Combinations VARCHAR(30)	
	DECLARE @IPLC_MeasureCode  VARCHAR(6)	
	DECLARE @IPLC_FrequencyCode VARCHAR(6)	
	DECLARE @IPLC_DisplayType  VARCHAR(6)	
    
	SELECT  @IPLC_MeasureCode=rtrim(ltrim(MeasureCode)),
			@IPLC_FrequencyCode=rtrim(ltrim(FrequencyCode)),
			@IPLC_DisplayType=rtrim(ltrim(DisplayType)) 
			FROM charge WHERE 
			ProductCode= @IPVC_ProductCode
			and  MeasureCode = @IPC_MeasureCode 
			and  FrequencyCode = @IPC_FrequencyCode 
			and  ChargeTypeCode=@IPVC_ChargeType
			and  ProductCode=@IPVC_ProductCode
			and  PriceVersion=@IPN_PriceVersion
			and  DisplayType =@IPC_DisplayType
			and  ChargeIDSeq=@IPC_ChargeID

    SET @IPLC_Combinations =@IPLC_MeasureCode+@IPLC_FrequencyCode+@IPLC_DisplayType
 	IF(@IPLC_Combinations = rtrim(ltrim(@IPC_MeasureCode))+rtrim(ltrim(@IPC_FrequencyCode))+rtrim(ltrim(@IPC_DisplayType)))
		BEGIN
		 SELECT 'Success' as res ,'' as msg
			return -1
		END
  
	 ELSE
		IF(@IPC_DisplayType='BOTH')   
				BEGIN
				IF exists (SELECT  top 1 1 FROM charge WHERE 
													ProductCode= @IPVC_ProductCode
													and  MeasureCode = @IPC_MeasureCode 
													and  FrequencyCode = @IPC_FrequencyCode 
													and  ChargeTypeCode=@IPVC_ChargeType
													and  ProductCode=@IPVC_ProductCode
													and  PriceVersion=@IPN_PriceVersion
													and  DisplayType in( 'SITE','PMC'))
								BEGIN			
            								SELECT 'failed' as res ,'Charge already exists for SITE or PMC,you cannot select display type BOTH' as msg 
								END
								ELSE
									BEGIN
										SELECT 'Success' as res,'' as msg
									END
				END

		ElSE
				IF(@IPC_DisplayType in ('SITE'))
				BEGIN
					if exists (SELECT  top 1 1 FROM charge WHERE 
														ProductCode= @IPVC_ProductCode
														and  MeasureCode = @IPC_MeasureCode 
														and  FrequencyCode = @IPC_FrequencyCode 
														and  ChargeTypeCode=@IPVC_ChargeType
														and  ProductCode=@IPVC_ProductCode
														and  PriceVersion=@IPN_PriceVersion
														and  DisplayType in ('BOTH','SITE'))
											BEGIN			
            											SELECT 'failed' as res ,'Charge already exists for SITE' as msg 
											END
										  ELSE
											BEGIN
												SELECT 'Success' as res, '' as msg
											END
                 END
            ELSE
				IF(@IPC_DisplayType ='PMC')
				BEGIN
					if exists (SELECT  top 1 1 FROM charge WHERE 
														ProductCode= @IPVC_ProductCode
														and  MeasureCode = @IPC_MeasureCode 
														and  FrequencyCode = @IPC_FrequencyCode 
														and  ChargeTypeCode=@IPVC_ChargeType
														and  ProductCode=@IPVC_ProductCode
														and  PriceVersion=@IPN_PriceVersion
														and  DisplayType in ('BOTH','PMC'))
											BEGIN			
            											SELECT 'failed' as res ,'Charge already exists FOR PMC ' as msg 
											END
										ELSE
											BEGIN
												SELECT 'Success' as res ,'' as msg
											END
                 END
                
            
 





 
     
END
GO
