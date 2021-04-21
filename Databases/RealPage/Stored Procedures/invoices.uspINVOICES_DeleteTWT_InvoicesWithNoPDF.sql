SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_DeleteTWT_InvoicesWithNoPDF
-- Description     : This procedure deletes TWT_InvoicesWithNoPDF
-- Input Parameters: 
--      
-- OUTPUT          : 
--
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_DeleteTWT_InvoicesWithNoPDF;
    
-- 
-- 
-- Revision History:
-- Author          : SRS
-- 10/12/2009      : Stored Procedure Created.         
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_DeleteTWT_InvoicesWithNoPDF] 
AS
BEGIN 
  set nocount on;
  delete from INVOICES.dbo.TWT_InvoicesWithNoPDF;
END
GO
