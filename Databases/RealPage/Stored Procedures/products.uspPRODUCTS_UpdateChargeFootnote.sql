SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------  
-- Database  Name  : PRODUCTS  
-- Procedure Name  : [uspPRODUCTS_UpdateChargeFootnote]  
-- Description     : This procedure updates ChargeFootNote Details  
 
              
  
  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [products].[uspPRODUCTS_UpdateChargeFootnote]  
                                                    @IPI_IDSeq		INT,  
													@PVC_FootNote   TEXT  
               
                                                       
                                                           
AS  
BEGIN  
UPDATE Products.dbo.ChargeFootnote SET Footnote=@PVC_FootNote WHERE IDSeq=@IPI_IDSeq   
END  
GO
