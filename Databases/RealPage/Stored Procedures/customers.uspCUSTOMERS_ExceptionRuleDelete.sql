SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_ExceptionRuleDelete]
-- Description     : This is the Main SP called for deleting ExceptionRuleDetails and ExceptionRuleHeader for a given Rule
-- Input Parameters: @IPI_PageNumber,@IPI_RowsPerPage,@IPVC_CompanyIDSeq and other parameters
-- Syntax          : Exec CUSTOMERS.dbo.uspCUSTOMERS_ExceptionRuleDelete @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_RuleType='Family'
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 7915) Multiple Billing Address enhancement
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_ExceptionRuleDelete] (@IPVC_CompanyIDSeq          varchar(50),     -- CompanyIDSeq (Mandatory) : UI Knows this
                                                           @IPBI_RuleIDSeq             bigint,          -- RuleIDSeq    (Mandatory) : 
                                                                                                           -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                           @IPVC_RuleType              varchar(50),     -- RuleType:  Values None,Family,Category,Product,ProductType(Future)
                                                                                                           -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                           @IPBI_UserIDSeq             bigint           --> This is UserID of person logged on (Mandatory)  
                                                          )
AS
BEGIN 
  set nocount on;
  declare @LVC_CodeSection varchar(1000)

  BEGIN TRY
    BEGIN TRANSACTION ERD;
      -----------------------------------------------------
      ---Step 1: Delete Child Table InvoiceDeliveryExceptionRuleDetail
      Delete from InvoiceDeliveryExceptionRuleDetail
      where  CompanyIDSeq = @IPVC_CompanyIDSeq
      and    RuleIDSeq    = @IPBI_RuleIDSeq
      and    RuleType     = @IPVC_RuleType
      -----------------------------------------------------
      ---Step 2: Delete Header Table InvoiceDeliveryExceptionRule
      Delete from InvoiceDeliveryExceptionRule
      where  CompanyIDSeq = @IPVC_CompanyIDSeq
      and    RuleIDSeq    = @IPBI_RuleIDSeq
      and    RuleType     = @IPVC_RuleType
      -----------------------------------------------
      --Step 3: Resync Rule after the delete operation of a rule and rule details
      EXEC ORDERS.dbo.uspORDERS_ApplyMBADOExceptionRules  @IPVC_CompanyIDSeq=@IPVC_CompanyIDSeq,@IPBI_UserIDSeq=@IPBI_UserIDSeq
 
    COMMIT TRANSACTION ERD;
  END TRY
  BEGIN CATCH
    if (XACT_STATE()) = -1
    begin
      IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION ERD;
    end
    else 
    if (XACT_STATE()) = 1
    begin
      IF @@TRANCOUNT > 0 COMMIT TRANSACTION ERD;
    end
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION ERD;
    select @LVC_CodeSection = 'Proc:uspCUSTOMERS_ExceptionRuleDelete. Deleting Rule Failed.' + 'Company:' + @IPVC_CompanyIDSeq+';RuleType:'+@IPVC_RuleType+';RuleID:' + convert(varchar(50),@IPBI_RuleIDSeq)
    Exec CUSTOMERS.DBO.uspCUSTOMERS_RaiseError  @IPVC_CodeSection = @LVC_CodeSection
    return; 
  end CATCH
END
GO
