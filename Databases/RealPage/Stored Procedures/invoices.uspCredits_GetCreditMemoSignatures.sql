SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : [uspCredits_GetCreditMemoSignatures]  
-- Description     : This procedure get data from creditMemo table   
-- Input Parameters: @CreditMemoIDSeq
-- OUTPUT          :   
--  
--                     
-- Code Example    : Exec Invoices.dbo.[uspCredits_GetCreditMemoSignatures] 386 
--                     
-- Revision History:  
-- Author          : Naval Kishore Singh
-- 12/27/2007      : Stored Procedure Created.  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspCredits_GetCreditMemoSignatures] (@CreditMemoIDSeq varchar(50))  
AS  
BEGIN
----------------------------------------------------------------------------------
--              Selecting from Credit Memo Table
----------------------------------------------------------------------------------
   SELECT  CreditStatusCode,
  		   IncludeAccountsManagerSignatureFlag,
		   IncludeSoftwareRevenueDirectorSignatureFlag,
		   IncludeVicePresidentFinanceSignatureFlag,
		   IncludeProductManagerSignatureFlag,		  
		   IncludeVicePresidentSalesSignatureFlag,
		   IncludeChiefFinancialOfficerSignatureFlag
   FROM    Invoices..CreditMemo
   WHERE   CreditMemoIDSeq = @CreditMemoIDSeq    
END  
-----------------------------------------------------------------------------------------------
GO
