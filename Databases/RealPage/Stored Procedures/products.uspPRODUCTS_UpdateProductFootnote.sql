SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : PRODUCTS  
-- Procedure Name  : [uspPRODUCTS_UpdateProductFootnote]  
-- Description     : This procedure updates charge footnote Details  
-- Input Parameters: @IPC_ChargeID       as    char  
              
  
  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [products].[uspPRODUCTS_UpdateProductFootnote]  
                                                    @IPI_IDSeq	   INT,  
													@PVC_FootNote  VARCHAR(300)  
               
                                                       
                                                           
AS  
BEGIN  
UPDATE Products.dbo.ProductFootnote SET Footnote=@PVC_FootNote WHERE IDSeq=@IPI_IDSeq   
END  
GO
