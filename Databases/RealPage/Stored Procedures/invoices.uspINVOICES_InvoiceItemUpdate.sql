SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : [uspINVOICES_InvoiceItemUpdate]
-- Description     : This procedure update the InvoiceItems with Id 
-- Input Parameters: 1. @IPVC_InvoiceItemID   as varchar(100)
--                   
-- OUTPUT          : Updates the InvoiceItem
--
--                   
-- Code Example    : Exec Invoices..uspINVOICES_InvoiceItemUpdate '240',100,100
-- 
-- Revision History:
-- Author          : STA
-- 12/1/2006       : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_InvoiceItemUpdate] (
                                                        @IPVC_InvoiceItemID numeric(38),
                                                        @CreditAmount numeric(10,2),
                                                        @TaxAmount numeric(10,2),
                                                        @NetPrice numeric(10,2),
                                                        @CreditFieldStatus numeric(1)
                                                        )
AS
BEGIN 
  ------------------------------------------------------------------------------------------
  --                  Update the InvocieItems in InvoiceItem Table
  ------------------------------------------------------------------------------------------
Declare @CrdAmount numeric(10,2)



 --select @CrdAmount = CreditAmount from Invoices..InvoiceItem where IDSeq = @IPVC_InvoiceItemID
 update  Invoices..invoiceitem 

 set     CreditAmount = @CreditAmount ,
         TaxAmount = @TaxAmount,
         NetChargeAmount = @NetPrice,
         AllowCreditFlag = @CreditFieldStatus

 WHERE   IDSeq  = @IPVC_InvoiceItemID 
 
  ------------------------------------------------------------------------------------------
END
--Exec Invoices..uspINVOICES_InvoiceItemUpdate 19,60,10,48


GO
