SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : INVOICES
-- Procedure Name  : [uspINVOICES_UpdateTransactionDetails]
-- Description     : Updates the Transaction details based on the input parameters passed
-- 
-- Revision History:
-- Author          : Shashi Bhushan
-- 05/08/2008      : Stored Procedure Created.
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_UpdateTransactionDetails] 
                                                             (
                                                               @IPVC_TransactionID BIGINT,
                                                               @IPVC_Description   VARCHAR(70),
                                                               @IPDT_Date          DATETIME,                    
                                                               @IPM_Cost           MONEY
                                                              )

AS
BEGIN
   UPDATE Invoices.dbo.InvoiceItem
   SET    TransactionItemName       = @IPVC_Description,
          TransactionDate           = @IPDT_Date,
          ExtChargeAmount           = @IPM_Cost,
          NetChargeAmount           = @IPM_Cost
   WHERE  OrderItemTransactionIDSeq = @IPVC_TransactionID
END


--Exec Invoices.[dbo].[uspINVOICES_UpdateTransactionDetails] 
--														@IPVC_TransactionID =1344,
--														@IPVC_Description   ='shashi',
--														@IPDT_Date          ='05/09/2008',                    
--														@IPM_Cost           = 13
GO
