SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetChargeFootnote]
			  @IPC_ProductCode VARCHAR(300),
              @IPN_PriceVersion NUMERIC(18,0),
              @IPC_ReportType   Varchar(30), 
              @IPC_ChargeIDSeq  bigint                                      
AS
BEGIN
 
SELECT	CF.IDSeq,
        C.ChargeIDSeq,
		C.ProductCode,
        C.MeasureCode,
        C.FrequencyCode,
        C.ChargeTypeCode,
       CF.FootNote,
        P.PendingApprovalFlag 
FROM	
		  Products.dbo.Charge C WITH(NOLOCK)
LEFT JOIN Products.dbo.ChargeFootnote CF WITH(NOLOCK) 
       ON CF.ChargeIDSeq=C.ChargeIDSeq
JOIN      Products.dbo.Product P WITH(NOLOCK) 
       ON P.Code=C.ProductCode 
AND       C.PriceVersion = P.PriceVersion     
AND       C.PriceVersion = @IPN_PriceVersion
WHERE	C.ProductCode=@IPC_ProductCode 
AND     C.PriceVersion=@IPN_PriceVersion 
AND     C.Reportingtypecode = @IPC_ReportType
AND     C.ChargeIDSeq = @IPC_ChargeIDSeq
END
GO
