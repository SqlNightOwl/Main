SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------  
-- Database  Name  : Invoices  
-- Procedure Name  : [uspCredits_CreditMemoSignatureUpdate]  
-- Description     : This procedure get data from creditMemo table   
-- Input Parameters: @CreditMemoIDSeq
-- OUTPUT          :    
--                     
-- Code Example    : Exec Invoices.dbo.[uspCredits_CreditMemoSignatureUpdate] 386 
--                     
-- Revision History:  
-- Author          : Naval Kishore Singh
-- 12/27/2007      : Stored Procedure Created.  
------------------------------------------------------------------------------------------------------  
CREATE PROCEDURE [invoices].[uspCredits_CreditMemoSignatureUpdate] (@CreditMemoIDSeq		                        varchar(50),
													           @IncludeAccountsManagerSignatureFlag         bit,
													           @IncludeChiefFinancialOfficerSignatureFlag   bit,
													           @IncludeProductManagerSignatureFlag          bit,
													           @IncludeSoftwareRevenueDirectorSignatureFlag bit,
													           @IncludeVicePresidentFinanceSignatureFlag    bit,															  
													           @IncludeVicePresidentSalesSignatureFlag      bit)  
AS  
BEGIN
	DECLARE @CreditStatus varchar(10)
    SELECT @CreditStatus =  CreditStatusCode FROM CreditMemo WHERE CreditMemoIDSeq =@CreditMemoIDSeq
----------------------------------------------------------------------------------
--              Selecting from Credit Memo Table
----------------------------------------------------------------------------------
  UPDATE Invoices..CreditMemo  
  SET    IncludeAccountsManagerSignatureFlag         = @IncludeAccountsManagerSignatureFlag,
	     IncludeSoftwareRevenueDirectorSignatureFlag = @IncludeSoftwareRevenueDirectorSignatureFlag ,
	     IncludeVicePresidentFinanceSignatureFlag    = @IncludeVicePresidentFinanceSignatureFlag,
	     IncludeProductManagerSignatureFlag          = @IncludeProductManagerSignatureFlag,		  
	     IncludeVicePresidentSalesSignatureFlag      = @IncludeVicePresidentSalesSignatureFlag,
	     IncludeChiefFinancialOfficerSignatureFlag   = @IncludeChiefFinancialOfficerSignatureFlag
  WHERE  CreditMemoIDSeq = @CreditMemoIDSeq    
IF(@CreditStatus='APPR')
	BEGIN
		UPDATE	Invoices..CreditMemo 
		SET		PrintFlag=1 
		WHERE   CreditMemoIDSeq = @CreditMemoIDSeq  
	END  

END  
-----------------------------------------------------------------------------------------------
GO
