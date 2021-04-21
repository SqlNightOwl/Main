SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : uspInvoices_SyncInvoiceTablesAndNotes  
-- Description     : This procedure Syncs data and Item Notes in InvoiceTables
-- Input Parameters: @OrderIDSeq
-- OUTPUT          :   
--  
--                     
-- Code Example    : Exec Invoices.dbo.uspInvoices_SyncInvoiceTablesAndNotes 386 
--                     
-- Revision History:  
-- Author          : Shashi Bhushan
-- 04/17/2008      : Stored Procedure Created.  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspInvoices_SyncInvoiceTablesAndNotes](@IPVC_OrderIDSeq varchar(50))  
AS  
BEGIN
  set nocount on; 
  -------------------------------------------------------------------------------------------------
  --Declaring Local Variables
  -------------------------------------------------------------------------------------------------
  DECLARE @LI_MIN           INT;
  DECLARE @LI_MAX           INT;
  DECLARE @LVC_InvoiceIDSeq VARCHAR(50);
  -------------------------------------------------------------------------------------------------
  --Declaring Local Table Variables
  -------------------------------------------------------------------------------------------------
  DECLARE @TblInvoicesSet TABLE (
                                 Seq           INT  IDENTITY(1,1) NOT NULL,
                                 InvoiceIDSeq  VARCHAR(50)
                                )  
  -------------------------------------------------------------------------------------------------
  INSERT INTO @TblInvoicesSet(InvoiceIDSeq) 
  SELECT   I.InvoiceIDSeq 
  FROM     Invoices.dbo.Invoice     I with (nolock)
  inner join
           INVOICES.dbo.INVOICEITEM II with (nolock)
  on       I.InvoiceIDSeq   = II.InvoiceIDSeq
  and      I.Printflag      = 0
  and      II.OrderIDSeq    = @IPVC_OrderIDSeq
  group by I.InvoiceIDSeq

  SELECT @LI_MIN = 1
  SELECT @LI_MAX = max(Seq) FROM @TblInvoicesSet

  WHILE @LI_MIN <= @LI_MAX
  BEGIN
    SELECT @LVC_InvoiceIDSeq=InvoiceIDSeq FROM @TblInvoicesSet WHERE Seq=@LI_MIN
    ------------------------------------------------------------------------------------
    -- Procedure to Insert the LineItem Notes into InvoiceLineItem table
    ------------------------------------------------------------------------------------ 
    BEGIN TRY       
      Exec Invoices.dbo.uspInvoices_PopulateInvoiceItemNotes @IPVC_InvoiceID  = @LVC_InvoiceIDSeq,
                                                             @IPVC_OrderIDSeq = @IPVC_OrderIDSeq;
    END TRY
    BEGIN CATCH
    END   CATCH    
    ------------------------------------------------------------------------------------
    --Sync $$$ amount totals now.
    ------------------------------------------------------------------------------------ 
    BEGIN TRY
      Exec Invoices.dbo.uspInvoices_SyncInvoiceTables @IPVC_InvoiceID = @LVC_InvoiceIDSeq;
    END TRY
    BEGIN CATCH
    END   CATCH    
    ------------------------------------------------------------------------------------        
    SELECT @LI_MIN = @LI_MIN + 1
  END   
END  
GO
