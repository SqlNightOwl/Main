SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : [uspINVOICES_BatchProcessStatus]   
-- Description     : Inserts an entry into the batch process table to begin the epicor push
-- Input Parameters: @IPVC_BatchCode varchar(20)
--                     
-- Revision History:  
-- Author          : DCANNON
-- 5/1/2007       : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspINVOICES_BatchProcessStatus] (
                                                      @IPVC_BatchCode             varchar(20),
                                                      @IPVC_Status                varchar(30)
                                                      )  
AS  
BEGIN
  update BatchProcess 
  set Status = @IPVC_Status
  where EpicorBatchCode = @IPVC_BatchCode
END
  

GO
