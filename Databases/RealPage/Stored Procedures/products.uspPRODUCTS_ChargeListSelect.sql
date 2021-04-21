SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[uspPRODUCTS_ChargeListSelect]    Script Date: 11/11/2008 ******/

-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ChargeListSelect]
			  
													@IPC_ProductCode    varchar(30),    
                                                    @IPN_PriceVersion   numeric(18,0),    
                                                    @IPC_ChargeTypeCode varchar(3),
													@IPC_ReportTypeCode varchar(4),    
                                                    @IPI_PageNumber     int,     
                                                    @IPI_RowsPerPage    int    
                                                             
AS    
BEGIN        
-----------------------------------------------------------------------------------------        
  SELECT * FROM (        
    ---------------------------------------------------------------------------------        
    SELECT TOP  (@IPI_RowsPerPage * @IPI_PageNumber)         
        
      C.ChargeIDSeq                          as ChargeID,        
      C.MeasureCode                          as MeasureCode,   
   C.DisplayType                          as DisplayType,     
   C.PriceVersion       as PriceVersion,       
      convert(numeric(10,5),C.ChargeAmount)  as ChargeAmount,        
      F.[Name]                               as Frequency,        
      R.[Name]                               as RevRecognition,        
      C.DeferredRevenueAccountCode           as DefRevAcctCode,        
      C.TaxwareCode                          as TaxwareCode,        
      C.MinUnits                             as MinUnits,        
      C.MaxUnits                             as MaxUnits,       
   C.DisabledFlag       as DisabledFlag,       
      convert(varchar(12),C.StartDate,101)   as StartDate,        
      convert(varchar(12),C.EndDate,101)     as EndDate,         
      row_number() over(order by C.ChargeIDSeq)   as RowNumber       
        
             
    FROM       Products.dbo.Charge    C with (nolock)        
    INNER JOIN Products.dbo.Frequency F with (nolock)        
    ON         C.FrequencyCode = F.Code          
    AND   C.ProductCode   =@IPC_ProductCode         
    AND   C.PriceVersion  =@IPN_PriceVersion        
    AND   C.ChargeTypeCode=@IPC_ChargeTypeCode  
       
    AND   C.Displaytype   <> 'OTHER'                  
    Left Outer Join        
               Products.dbo.RevenueRecognition R with (nolock)        
    ON         C.RevenueRecognitionCode = R.Code            
    WHERE C.ProductCode   =@IPC_ProductCode         
    AND   C.PriceVersion  =@IPN_PriceVersion        
    AND   C.ChargeTypeCode=@IPC_ChargeTypeCode  
	AND   C.ReportingTypeCode= @IPC_ReportTypeCode        
    AND   C.Displaytype   <> 'OTHER'        
  ) tbl        
 ---------------------------------------------------------------------------------        
 WHERE RowNumber > (@IPI_PageNumber-1) * @IPI_RowsPerPage        
        
  -----------------------------------------------------------------------------------------        
        
  -----------------------------------------------------------------------------------------        
  SELECT      COUNT(*)         
  FROM       Products.dbo.Charge    C with (nolock)        
  INNER JOIN Products.dbo.Frequency F with (nolock)        
  ON         C.FrequencyCode = F.Code        
  AND   C.ProductCode   =@IPC_ProductCode         
  AND   C.PriceVersion  =@IPN_PriceVersion        
  AND  C.ChargeTypeCode=@IPC_ChargeTypeCode        
  AND   C.Displaytype   <> 'OTHER'              
  Left Outer Join        
             Products.dbo.RevenueRecognition R with (nolock)        
  ON         C.RevenueRecognitionCode = R.Code            
  WHERE C.ProductCode   =@IPC_ProductCode         
  AND   C.PriceVersion  =@IPN_PriceVersion        
  AND   C.ChargeTypeCode=@IPC_ChargeTypeCode   
  AND   C.ReportingTypeCode= @IPC_ReportTypeCode          
  AND   C.Displaytype   <> 'OTHER'        
  -----------------------------------------------------------------------------------------        
        
END   
GO
