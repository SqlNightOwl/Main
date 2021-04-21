SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_RevenueCodesSelect] 
(
	    @IPVC_ProductCode      varchar(50),                                                                        
        @IPVC_FrequencyCode    varchar(6),                                                                                                         
        @IPVC_MeasureCode      varchar(6),      
        @IPVC_ILFFrequencyCode varchar(6),  
        @IPVC_ILFMeasureCode   varchar(6),                      
        @IPN_PriceVersion      numeric(18,0)
)
AS 
BEGIN 
set nocount on;
----------------------------------------------------------------
		DECLARE @ChargeIDSeq bigint
		SET @ChargeIDSeq = 0	
		
		SELECT @ChargeIDSeq = ChargeIDSeq
		FROM   Products.dbo.Charge C with (nolock)
		WHERE  C.ProductCode    = @IPVC_ProductCode  
		and   C.DisabledFlag   = 0  
		and   C.MeasureCode    = @IPVC_ILFMeasureCode 
		and   C.FrequencyCode  = @IPVC_ILFFrequencyCode
		and   C.PriceVersion   = @IPN_PriceVersion
		and   C.Chargetypecode = 'ILF'

		SELECT  C.RevenueAccountCode,
				C.RevenueRecognitionCode, 
				F.EpicorPostingCode 'PostingCode',
				P.DisplayName
		FROM   Products.dbo.Charge C with (nolock)
		inner join Products.dbo.Product P with (nolock)
		on C.ProductCode = P.Code and C.PriceVersion = P.PriceVersion and C.ChargeIDSeq=@ChargeIDSeq
		inner join Products.dbo.Family  F with (nolock)
		on P.FamilyCode = F.Code
	
        
		SET @ChargeIDSeq = 0

		SELECT  @ChargeIDSeq = ChargeIDSeq
		FROM    Products.dbo.Charge C with (nolock)
		WHERE   C.ProductCode    = @IPVC_ProductCode  
		and     C.DisabledFlag   = 0  
		and     C.MeasureCode    = @IPVC_MeasureCode 
		and     C.FrequencyCode  = @IPVC_FrequencyCode
		and     C.PriceVersion   = @IPN_PriceVersion
		and     C.Chargetypecode = 'ACS'

		SELECT  C.RevenueAccountCode,
				C.RevenueRecognitionCode, 
				F.EpicorPostingCode 'PostingCode',
				P.DisplayName
		FROM   Products.dbo.Charge C with (nolock)
		inner join Products.dbo.Product P with (nolock)
		on C.ProductCode = P.Code and C.PriceVersion = P.PriceVersion and C.ChargeIDSeq=@ChargeIDSeq
		inner join Products.dbo.Family  F with (nolock)
		on P.FamilyCode = F.Code
		  
END

 
GO
