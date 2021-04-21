SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : uspINVOICES_InvocePrintBatchUpdate   
-- Description     : Updates sta.
-- Input Parameters: @IPVC_InvoiceString varchar(8000)
--                     
-- Code Example    : Exec Invoices.dbo.uspINVOICES_InvocePrintBatchUpdate(@IPVC_InvoiceString)
--   
-- Revision History:  
-- Author          : Bhavesh Shah
-- 08/07/2008      : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [invoices].[uspINVOICES_InvocePrintBatchUpdate] 
(
  @IPI_PrintBatchID bigint
  , @IPVC_InvoiceString varchar(max)
)
AS
BEGIN
  UPDATE INVOICES.DBO.INVOICE SET 
    PrintBatchID = @IPI_PrintBatchID
  OUTPUT 
    INSERTED.InvoiceIDSeq as InvoiceIDSeq
  Where
    InvoiceIDSeq in (select SplitString from INVOICES.dbo.[fnGenericSplitString] (@IPVC_InvoiceString))
End

GO
