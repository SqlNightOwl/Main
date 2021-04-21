SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : PRODUCTS  
-- Procedure Name  : [uspPRODUCTS_DeleteChargeFootnote]  
-- Description     : This procedure deletes ChargeFootNote    

  
  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [products].[uspPRODUCTS_DeleteChargeFootnote]  
                                               @IPC_FootNoteID int  
                
               
                                                       
                                                           
AS  
BEGIN  
 DELETE FROM ChargeFootnote where IDSeq=@IPC_FootNoteID  
END  
GO
