SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_GetExceptionRuleDetailCategory]
-- Description     : This is the Main SP called for Listing of all ExceptionRules
-- Input Parameters: @IPVC_CompanyIDSeq and @IPBI_RuleIDSeq
-- Syntax          : 
/*
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailCategory @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_FamilyCode = 'ALL'
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailCategory @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_FamilyCode = 'LSD'
*/
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 7915) Multiple Billing Address enhancement
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetExceptionRuleDetailCategory] (@IPVC_CompanyIDSeq          varchar(50),     -- CompanyIDSeq (Mandatory) : UI Knows this
                                                                      @IPBI_RuleIDSeq             bigint  = 0,     -- RuleIDSeq    (Optional) : 
                                                                                                                   -- For Existing UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                                                                                   -- For Brand new, UI will pass @IPBI_RuleIDSeq=0 
                                                                      @IPVC_FamilyCode            varchar(10) = 'ALL' -- UI should call Exec PRODUCTS.dbo.uspPRODUCTS_FamilyList.SQL to populate Family Drop down
                                                                                                                   -- UI drop down shows Family Name and along with a dummy 'ALL' to denote all Family
                                                                                                                   -- If user selects ALL by default, pass @IPVC_FamilyCode as 'ALL'
                                                                                                                   -- if user select a specific Family name, then UI will pass in specific Family Code (hidden in UI for corresponding drop down value)                                                                  
                                                                     )
AS
BEGIN 
  set nocount on;
  -------------------------------------------------------------------------------------------------------------------
  ---Variable validation and initialization 
  select @IPVC_FamilyCode = nullif(ltrim(rtrim(@IPVC_FamilyCode)),'');
  select @IPVC_FamilyCode = (case when @IPVC_FamilyCode = 'ALL' then NULL
                                    else @IPVC_FamilyCode
                               end)

  ------------------------------------------------------------------------------------------------------------------
  --NOTE : UI will bind Resultset1(Available) for Left hand side Available (LHS)
  --       UI will bind Resultset2(Selected) for Right hand side Available (RHS)
  --       UI will Look at Resultset1(Available) and Resultset2(Selected) and remove already selected ones from LHS based on CODE and Not Name
  -------------------------------------------------------------------------------------------------------------------
  --Step 1 :Resultset1(Available)  : Get all Category List value for LHS (Left Hand side available), based on Input parameter.
  -------------------------------------------------------------------------------------------------------------------
  SELECT   CAT.Code,CAT.[Name] 
  FROM     PRODUCTS.dbo.[Category] CAT with (nolock)
  where exists (select top 1 1
                from   Products.dbo.Product PRD with (nolock)
                where  PRD.CategoryCode = CAT.Code
                and      PRD.FamilyCode = coalesce(@IPVC_FamilyCode,PRD.FamilyCode)
               )  
  order by CAT.[Name] asc 
  -------------------------------------------------------------------------------------------------------------------
  --Step 2 : Resultset2(Selected) : Get Category List value for RHS (Right Hand side available), based on Input parameter.
  --        This is the list already saved the Rule for this Company  @IPVC_CompanyIDSeq and @IPBI_RuleIDSeq
  -------------------------------------------------------------------------------------------------------------------
  SELECT   CAT.Code,CAT.[Name] 
  FROM     PRODUCTS.dbo.[Category] CAT with (nolock)
  where exists (select top 1 1
                   from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
                   where  IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
                   and    IDER.RuleIDSeq           = @IPBI_RuleIDSeq                   
                   and    IDER.RuleType            = 'Category'
                   and    IDER.ApplyToCategoryCode   = CAT.Code
                  )
  order by CAT.[Name] asc 
  -------------------------------------------------------------------------------------------------------------------
END
GO
