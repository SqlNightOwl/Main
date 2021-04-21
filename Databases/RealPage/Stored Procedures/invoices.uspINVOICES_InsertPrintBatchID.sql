SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------    
-- Database  Name  : INVOICES    
-- Procedure Name  : [uspINVOICES_InsertPrintBatchID]    
-- Description     : Inserts data into table [PrintBatch] and updates the BatchID column in Invoice table based on Invoices passed
--    
-- Created         : Shashi Bhushan
-- 10/01/2008      : 
------------------------------------------------------------------------------------------------------    
CREATE PROCEDURE [invoices].[uspINVOICES_InsertPrintBatchID] (
                                                          @IPVC_InvoiceString varchar(8000),
                                                          @IPVC_PrintedBy varchar(255)
                                                         )
AS    
BEGIN     
----------------------------------
--Declaring Local variables
  Declare @ScopeIdentity int
----------------------------------
  Insert into [invoices].[dbo].[PrintBatch](PrintDate,PrintedBy)
  values (getdate(),@IPVC_PrintedBy)
  
  SELECT @ScopeIdentity=scope_identity()
    
  Update [invoices].[dbo].[Invoice]
  set   PrintBatchID = @ScopeIdentity
  where InvoiceIDSeq in (select SplitString from INVOICES.dbo.[fnGenericSplitString] (@IPVC_InvoiceString))
    
END 
------------------------
-- For debuggin purpose
------------------------
--Exec Invoices.dbo.[uspINVOICES_InsertPrintBatchID] @IPVC_InvoiceString='I0801000027|', @IPVC_PrintedBy = 'Kiran Kusumba'I0709000147|I0711000067|I0709000179|I0711000032|I0711000068|I0711000069|I0712000005|I0712000007|I0711000063|I0711000064|'


  
  
  
  

GO
