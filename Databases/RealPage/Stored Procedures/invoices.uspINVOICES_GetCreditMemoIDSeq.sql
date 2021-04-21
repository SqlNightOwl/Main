SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : uspINVOICES_GetCreditMemoIDSeq   
-- Description     : This procedure gets the creditmemoidseq 
-- Input Parameters:   
-- OUTPUT          : CreditMemoIDSeq 
--  
--                     
-- Code Example    : Exec Invoices.dbo.uspINVOICES_GetCreditMemoIDSeq
-- Revision History:  
-- Author          : Kiran Kusumba  
-- 1/25/2008       : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspINVOICES_GetCreditMemoIDSeq] 
AS
BEGIN
update INVOICES.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
      set    IDSeq = IDSeq+1,
             GeneratedDate =CURRENT_TIMESTAMP 
      where  TypeIndicator = 'R'

      select IDGeneratorSeq AS CreditMemoIDSeq
      from   INVOICES.DBO.IDGenerator with (NOLOCK)  
      where  TypeIndicator = 'R'
END
GO
