SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_GetExceptionRuleDetailFamily]
-- Description     : This is the Main SP called for Listing of all ExceptionRules
-- Input Parameters: @IPVC_CompanyIDSeq and @IPBI_RuleIDSeq
-- Syntax          : 
/*
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailFamily @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_PlatFormCode='ALL'
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailFamily @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_PlatFormCode='PRM'
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailFamily @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_PlatFormCode='DMD'
*/
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 7915) Multiple Billing Address enhancement
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetExceptionRuleDetailFamily] (@IPVC_CompanyIDSeq          varchar(50),     -- CompanyIDSeq (Mandatory) : UI Knows this
                                                                    @IPBI_RuleIDSeq             bigint  = 0,     -- RuleIDSeq    (Optional) : 
                                                                                                                 -- For Existing UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                                                                                 -- For Brand new, UI will pass @IPBI_RuleIDSeq=0 
                                                                    @IPVC_PlatFormCode          varchar(10) = 'ALL'-- Platform Drop down (optional)
                                                                                                                   -- UI should call Exec PRODUCTS.dbo.uspPRODUCTS_PlatformList.SQL to populate Platform Drop down
                                                                                                                   -- UI drop down shows Platform Name and along with a dummy 'ALL' to denote all platform
                                                                                                                   -- If user selects ALL by default, pass @IPVC_PlatFormCode as 'ALL'
                                                                                                                   -- if user select a specific platform name, then UI will pass in specific platform Code (hidden in UI)                                                                  
                                                                  )
AS
BEGIN 
  set nocount on;  
  -------------------------------------------------------------------------------------------------------------------
  ---Variable validation and initialization
  select @IPVC_PlatFormCode = nullif(ltrim(rtrim(@IPVC_PlatFormCode)),'');
  select @IPVC_PlatFormCode = (case when @IPVC_PlatFormCode = 'ALL' then NULL
                                    else @IPVC_PlatFormCode
                               end)
  -------------------------------------------------------------------------------------------------------------------  
  --NOTE : UI will bind Resultset1(Available) for Left hand side Available (LHS)
  --       UI will bind Resultset2(Selected) for Right hand side Available (RHS)
  --       UI will Look at Resultset1(Available) and Resultset2(Selected) and remove already selected ones from LHS based on CODE and Not Name
  -------------------------------------------------------------------------------------------------------------------
  --Step 1 :Resultset1(Available)  : Get all Family List value for LHS (Left Hand side available), based on Input parameter.
  -------------------------------------------------------------------------------------------------------------------
  SELECT   FML.Code,FML.[Name] 
  FROM     PRODUCTS.dbo.[Family] FML with (nolock)
  WHERE    FML.Code not in ('ADM','RPM')
  and      exists (select top 1 1
                   from   Products.dbo.Product PRD with (nolock)
                   where  PRD.FamilyCode = FML.Code
                   and    PRD.PlatFormCode = coalesce(@IPVC_PlatFormCode,PRD.PlatFormCode)
                  )
  order by FML.[Name] asc 
  -------------------------------------------------------------------------------------------------------------------
  --Step 2 : Resultset2(Selected) : Get Family List value for RHS (Right Hand side available), based on Input parameter.
  --        This is the list already saved the Rule for this Company  @IPVC_CompanyIDSeq and @IPBI_RuleIDSeq
  -------------------------------------------------------------------------------------------------------------------
  SELECT   FML.Code,FML.[Name] 
  FROM     PRODUCTS.dbo.[Family] FML with (nolock)
  WHERE    FML.Code not in ('ADM','RPM')
  and      exists (select top 1 1
                   from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
                   where  IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
                   and    IDER.RuleIDSeq           = @IPBI_RuleIDSeq                   
                   and    IDER.RuleType            = 'Family'
                   and    IDER.ApplyToFamilyCode   = FML.Code
                  )
  order by FML.[Name] asc 
  -------------------------------------------------------------------------------------------------------------------
END
GO
