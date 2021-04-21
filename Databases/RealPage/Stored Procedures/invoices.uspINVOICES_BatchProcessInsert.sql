SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : [uspINVOICES_BatchProcessInsert]   
-- Description     : Inserts an entry into the batch process table to begin the epicor push
-- Input Parameters: @IPVC_BatchCode varchar(20)
--                     
-- Revision History:  
-- Author          : DCANNON
-- 5/1/2007       : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspINVOICES_BatchProcessInsert] (
                                                      @IPVC_BatchCode             varchar(20),
                                                      @IPI_CreatedByIDSeq         bigint
                                                      )  
AS  
BEGIN
  declare @LVC_Name varchar(50)
  select @LVC_Name = FirstName + ' ' + LastName
  from Security.dbo.[User]
  where IDSeq = @IPI_CreatedByIDSeq

  insert into BatchProcess (EpicorBatchCode, Status, InvoiceCount, SuccessCount, FailureCount, 
                  CreatedBy, CreatedByIDSeq)
  select @IPVC_BatchCode, 'PENDING', (select count(*) from Invoice where EpicorBatchCode = @IPVC_BatchCode),
    0, 0, @LVC_Name, @IPI_CreatedByIDSeq
END
  

GO
