SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : ORDERS
-- Procedure Name  : [uspCUSTOMERS_GetExceptionRuleDetailProducts]
-- Description     : This is the Main SP called for Listing of all ExceptionRules
-- Input Parameters: @IPVC_CompanyIDSeq and @IPBI_RuleIDSeq
-- Syntax          : 
/*
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailProducts @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_PlatFormCode='ALL',@IPVC_FamilyCode = 'ALL'
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailProducts @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_PlatFormCode='ALL',@IPVC_FamilyCode = 'LSD'
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailProducts @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_PlatFormCode='DMD',@IPVC_FamilyCode = 'ALL'
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailProducts @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_PlatFormCode='DMD',@IPVC_FamilyCode = 'LSD'
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailProducts @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_PlatFormCode='DMD',@IPVC_FamilyCode = 'OSD'
Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetailProducts @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_PlatFormCode='DMD',@IPVC_FamilyCode = 'CFR'

*/
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 7915) Multiple Billing Address enhancement
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetExceptionRuleDetailProducts] (@IPVC_CompanyIDSeq          varchar(50),     -- CompanyIDSeq (Mandatory) : UI Knows this
                                                                      @IPBI_RuleIDSeq             bigint  = 0,     -- RuleIDSeq    (Optional) : 
                                                                                                                   -- For Existing UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                                                                                   -- For Brand new, UI will pass @IPBI_RuleIDSeq=0 
                                                                      @IPVC_PlatFormCode          varchar(10) = 'ALL',-- Platform Drop down (optional)
                                                                                                                   -- UI should call Exec PRODUCTS.dbo.uspPRODUCTS_PlatformList.SQL to populate Platform Drop down
                                                                                                                   -- UI drop down shows Platform Name and along with a dummy 'ALL' to denote all platform
                                                                                                                   -- If user selects ALL by default, pass @IPVC_PlatFormCode as 'ALL'
                                                                                                                   -- if user select a specific platform name, then UI will pass in specific platform Code (hidden in UI)                                                                  
                                                                      @IPVC_FamilyCode            varchar(10) = 'ALL', -- Family Drop down (optional)
                                                                                                                   -- UI should call Exec PRODUCTS.dbo.uspPRODUCTS_FamilyList to populate Family Drop down
                                                                                                                   -- UI drop down shows Family Name and along with a dummy 'ALL' to denote all Family
                                                                                                                   -- If user selects ALL by default, pass @IPVC_FamilyCode as 'ALL'
                                                                                                                   -- if user select a specific Family name, then UI will pass in specific Family Code (hidden in UI for corresponding drop down value)                                                                  
                                                                      @IPVC_CategoryCode          varchar(10) = 'ALL' -- Category Drop down (optional)
                                                                                                                   -- UI should call Exec PRODUCTS.dbo.uspPRODUCTS_GetCategory to populate Family Drop down
                                                                                                                   -- UI drop down shows Category Name and along with a dummy 'ALL' to denote all Categories
                                                                                                                   -- If user selects ALL by default, pass @IPVC_FamilyCode as 'ALL'
                                                                                                                   -- if user select a specific Categort name, then UI will pass in specific Category Code (hidden in UI for corresponding drop down value)                                                                  

                                                                     )
AS
BEGIN 
  set nocount on; 
  -------------------------------------------------------------------------------------------------------------------
  ---Variable validation and initialization
  select @IPVC_PlatFormCode = nullif(ltrim(rtrim(@IPVC_PlatFormCode)),''),
         @IPVC_FamilyCode   = nullif(ltrim(rtrim(@IPVC_FamilyCode)),''),
         @IPVC_CategoryCode = nullif(ltrim(rtrim(@IPVC_CategoryCode)),'');
  select @IPVC_PlatFormCode = (case when @IPVC_PlatFormCode = 'ALL' then NULL
                                    else @IPVC_PlatFormCode
                               end),
         @IPVC_FamilyCode = (case when @IPVC_FamilyCode = 'ALL' then NULL
                                    else @IPVC_FamilyCode
                               end),
         @IPVC_CategoryCode = (case when @IPVC_CategoryCode = 'ALL' then NULL
                                    else @IPVC_CategoryCode
                               end)
  ------------------------------------------------------------------------------------------------------------------
  --NOTE : UI will bind Resultset1(Available) for Left hand side Available (LHS)
  --       UI will bind Resultset2(Selected) for Right hand side Available (RHS)
  --       UI will Look at Resultset1(Available) and Resultset2(Selected) and remove already selected ones from LHS based on CODE and Not Name
  -------------------------------------------------------------------------------------------------------------------
  --Step 1 :Resultset1(Available)  : Get all Product List value for LHS (Left Hand side available), based on Input parameter.
  -------------------------------------------------------------------------------------------------------------------
  SELECT   ltrim(rtrim(PRD.Code)) as Code,Max(PRD.[DisplayName])  as [Name]
  FROM     PRODUCTS.dbo.[Product] PRD with (nolock)  
  inner join
          (select ltrim(rtrim(P.Code)) as ProductCode, Max(P.Priceversion) as Priceversion
           from   Products.dbo.Product P with (nolock)
           group by ltrim(rtrim(P.Code))
          ) S
  on     PRD.Code                = S.ProductCode
  and    PRD.Priceversion        = S.Priceversion
  --and  PRD.disabledflag = 0 
  and    PRD.PlatFormCode = coalesce(@IPVC_PlatFormCode,PRD.PlatFormCode)
  and    PRD.FamilyCode   = coalesce(@IPVC_FamilyCode,PRD.FamilyCode)
  and    PRD.CategoryCode = coalesce(@IPVC_CategoryCode,PRD.CategoryCode)
  where  PRD.PlatFormCode = coalesce(@IPVC_PlatFormCode,PRD.PlatFormCode)
  and    PRD.FamilyCode   = coalesce(@IPVC_FamilyCode,PRD.FamilyCode)
  and    PRD.CategoryCode = coalesce(@IPVC_CategoryCode,PRD.CategoryCode)
  group by  ltrim(rtrim(PRD.Code)) 
  order by [Name] asc 
  -------------------------------------------------------------------------------------------------------------------
  --Step 2 : Resultset2(Selected) : Get Product List value for RHS (Right Hand side available), based on Input parameter.
  --        This is the list already saved the Rule for this Company  @IPVC_CompanyIDSeq and @IPBI_RuleIDSeq
  -------------------------------------------------------------------------------------------------------------------
  SELECT   ltrim(rtrim(PRD.Code)) as Code,Max(PRD.[DisplayName])  as [Name]
  FROM     PRODUCTS.dbo.[Product] PRD with (nolock)
  inner join
          (select ltrim(rtrim(P.Code)) as ProductCode, Max(P.Priceversion) as Priceversion
           from   Products.dbo.Product P with (nolock)
           group by ltrim(rtrim(P.Code))
          ) S
  on     PRD.Code                = S.ProductCode
  and    PRD.Priceversion        = S.Priceversion
  where exists (select top 1 1
                   from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
                   where  IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
                   and    IDER.RuleIDSeq           = @IPBI_RuleIDSeq                   
                   and    IDER.RuleType            = 'Product'
                   and    IDER.ApplyToProductCode  = PRD.Code
                  )
  group by  ltrim(rtrim(PRD.Code)) 
  order by [Name] asc 
  -------------------------------------------------------------------------------------------------------------------
END
GO
