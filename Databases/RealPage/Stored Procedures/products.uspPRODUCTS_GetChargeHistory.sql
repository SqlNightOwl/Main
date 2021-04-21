SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_GetChargeHistory]
-- Description     : This procedure gets ChargeID,MeasureCode,Frequency,RevRecognition,DefRevAcctCode,
--                   TaxwareCode,MinUnits,MaxUnits,StartDate,EndDate,RowNumber pertaining to passed 
--                   ProductCode,priceversion,chargetypecode
-- Input Parameters: @IPC_ProductCode       as    char
--                   @IPN_PriceVersion      as    numeric
--                   @IPC_ChargeTypeCode    as    char
-- OUTPUT          : ChargeID,MeasureCode,Frequency,RevRecognition,DefRevAcctCode,
--                   TaxwareCode,MinUnits,MaxUnits,StartDate,EndDate,RowNumber
-- Code Example    : exec [dbo].[uspPRODUCTS_GetChargeHistory] 'DMD-SBL-CNV-CNV-CSCV',100,'',1,20 
-- Author          : Naval Kishore Singh 
-- 06/07/2007      : Stored Procedure Created.

------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetChargeHistory]
                                                    @IPC_ProductCode char(30),
                                                    @IPC_ChargeTypeCode char(3),
                                                    @IPI_PageNumber int, 
                                                    @IPI_RowsPerPage int
                                                    					
AS
BEGIN
-----------------------------------------------------------------------------------------
  SELECT * FROM (
    ---------------------------------------------------------------------------------
    SELECT TOP  (@IPI_RowsPerPage * @IPI_PageNumber) 

      C.ChargeIDSeq                          as ChargeID,
      C.ProductCode                          as ProductCode,
      C.PriceVersion                         as PriceVersion,
      C.ChargeTypeCode                       as ChargeTypeCode,
      C.MeasureCode                          as MeasureCode,
      C.ChargeAmount                         as ChargeAmount,
      F.[Name]                               as Frequency,
      C.MinUnits                             as MinUnits,
      C.MinThresholdOverride                 as MinThresholdOverride,
      C.MaxUnits                             as MaxUnits,
      C.MaxThresholdOverride                 as MaxThresholdOverride,
      convert(varchar(12),C.StartDate,101)   as StartDate,
      convert(varchar(12),C.EndDate,101)     as EndDate,	
      row_number() over(order by C.ChargeIDSeq)   as RowNumber

     
    FROM Products.dbo.Charge C with (nolock)

    INNER JOIN Products.dbo.Frequency F with (nolock)
      ON  C.FrequencyCode = F.Code
    
    WHERE C.ProductCode = @IPC_ProductCode 
           AND C.ChargeTypeCode=@IPC_ChargeTypeCode) tbl
 ---------------------------------------------------------------------------------

  WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage

  -----------------------------------------------------------------------------------------

  -----------------------------------------------------------------------------------------
  SELECT      COUNT(*) 
  FROM Products.dbo.Charge C 

  INNER JOIN Products.dbo.Frequency F with (nolock)
      ON  C.FrequencyCode = F.Code
       
    WHERE C.ProductCode = @IPC_ProductCode 
            AND C.ChargeTypeCode=@IPC_ChargeTypeCode
  -----------------------------------------------------------------------------------------

END

--exec [dbo].[uspPRODUCTS_GetChargeHistory] 'DMD-SBL-SLV-SLV-CSLV','ILF',1,20 

GO
