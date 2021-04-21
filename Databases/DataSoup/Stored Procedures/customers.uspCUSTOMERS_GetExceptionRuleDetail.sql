SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
------------------------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetExceptionRuleDetail]
-- Description     : This is the Main SP called for Listing the details of a specific Exception Rule
-- Input Parameters: @IPVC_CompanyIDSeq, @IPBI_RuleIDSeq, @IPVC_RuleType
-- Syntax          : Exec CUSTOMERS.dbo.uspCUSTOMERS_GetExceptionRuleDetail @IPVC_CompanyIDSeq='C0901000002',@IPBI_RuleIDSeq=1,@IPVC_RuleType='Family'
------------------------------------------------------------------------------------------------------------------------------------------
-- Revision History:
-- 01/15/2011      : SRS (Defect 7915) Multiple Billing Address enhancement
-- 07/05/2011	   : Mahaboob (Defect #627) Show Site name on Invoice for site invoices sent to company
------------------------------------------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [customers].[uspCUSTOMERS_GetExceptionRuleDetail] (@IPVC_CompanyIDSeq          varchar(50),     -- CompanyIDSeq (Mandatory) : UI Knows this
                                                              @IPBI_RuleIDSeq             bigint,          -- RuleIDSeq    (Mandatory) : 
                                                                                                           -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList
                                                              @IPVC_RuleType              varchar(50)      -- RuleType:  Values None,Family,Category,Product,ProductType(Future)
                                                                                                           -- UI knows this from results of SP call uspCUSTOMERS_ExceptionRuleHeaderList   
                                                              )
AS
BEGIN 
  set nocount on;
  SET CONCAT_NULL_YIELDS_NULL OFF;
  -----------------------------------------------------
  ---Step 1 : First Resultset KeyList 
  -----------------------------------------------------
  select IDER.ApplyToFamilyCode as KeyListCode,Max(FML.Name) as KeyListValue
  from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
  inner join
         Products.dbo.Family FML with (nolock)
  on     IDER.ApplyToFamilyCode = FML.Code
  and    IDER.CompanyIDSeq      = @IPVC_CompanyIDSeq
  and    IDER.RuleIDSeq         = @IPBI_RuleIDSeq
  and    IDER.RuleType          = @IPVC_RuleType
  and    IDER.RuleType          = 'Family'
  group by IDER.ApplyToFamilyCode,FML.Code
  --------
  UNION
  --------
  select IDER.ApplyToCategoryCode as KeyListCode,Max(CAT.Name) as KeyListValue
  from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
  inner join
         Products.dbo.Category CAT with (nolock)
  on     IDER.ApplyToCategoryCode = CAT.Code
  and    IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
  and    IDER.RuleIDSeq           = @IPBI_RuleIDSeq
  and    IDER.RuleType            = @IPVC_RuleType
  and    IDER.RuleType            = 'Category'
  group by IDER.ApplyToCategoryCode,CAT.Code
  --------
  UNION
  --------
  select IDER.ApplyToProductTypeCode as KeyListCode,Max(PT.Name) as KeyListValue
  from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
  inner join
         Products.dbo.ProductType PT with (nolock)
  on     IDER.ApplyToProductTypeCode = PT.Code
  and    IDER.CompanyIDSeq           = @IPVC_CompanyIDSeq
  and    IDER.RuleIDSeq              = @IPBI_RuleIDSeq
  and    IDER.RuleType               = @IPVC_RuleType
  and    IDER.RuleType               = 'ProductType'
  group by IDER.ApplyToProductTypeCode,PT.Code
  --------
  UNION
  --------
  select IDER.ApplyToProductCode as KeyListCode,Max(PRD.DisplayName) as KeyListValue
  from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
  inner join
         Products.dbo.Product PRD with (nolock)
  on     IDER.ApplyToProductCode  = PRD.Code
  and    IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
  and    IDER.RuleIDSeq           = @IPBI_RuleIDSeq
  and    IDER.RuleType            = @IPVC_RuleType
  and    IDER.RuleType            = 'Product'
  inner join
         (select ltrim(rtrim(P.Code)) as ProductCode, Max(P.Priceversion) as Priceversion
          from   Products.dbo.Product P with (nolock)
          group by ltrim(rtrim(P.Code))
         ) S
  on    IDER.ApplyToProductCode = S.ProductCode
  and   PRD.Code                = S.ProductCode
  and   PRD.Priceversion        = S.Priceversion
  group by IDER.ApplyToProductCode,PRD.Code,S.ProductCode
  Order by KeyListValue asc;
  -----------------------------------------------------
  ---Step 2 : Second Resultset ApplyToOMSIDList 
  -----------------------------------------------------
  select IDER.ApplyToOMSIDSeq as ApplyToOMSID,Max(COM.Name) ApplyToOMSIDValue
  from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
  inner join
         CUSTOMERS.dbo.Company COM with (nolock)
  on     IDER.ApplyToOMSIDSeq     = COM.IDSeq
  and    IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
  and    IDER.RuleIDSeq           = @IPBI_RuleIDSeq
  and    IDER.RuleType            = @IPVC_RuleType
  group by IDER.ApplyToOMSIDSeq,COM.IDSeq
  --------
  UNION
  --------
  select IDER.ApplyToOMSIDSeq as ApplyToOMSID,Max(PRP.Name) ApplyToOMSIDValue
  from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
  inner join
         CUSTOMERS.dbo.Property PRP with (nolock)
  on     IDER.ApplyToOMSIDSeq     = PRP.IDSeq
  and    IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
  and    IDER.RuleIDSeq           = @IPBI_RuleIDSeq
  and    IDER.RuleType            = @IPVC_RuleType
  group by IDER.ApplyToOMSIDSeq,PRP.IDSeq
  Order by ApplyToOMSIDValue asc
  -----------------------------------------------------
  ---Step 3 : Third Resultset Billing Address 
  -----------------------------------------------------
  ---All Records of a given Rule will/should have same BillToAddressTypeCode.
  ---So Select Top 1 should suffice.
  select top 1
         coalesce(IDER.BillToAddressTypeCode,'DFT') as BillToAddressTypeCode,
         (case when  coalesce(IDER.BillToAddressTypeCode,'DFT') = 'DFT' then 'Default'
               else  coalesce(ADDRProp.AddressLine1,ADDR.AddressLine1)+','+
                     coalesce(ADDRProp.City,ADDR.City)                +','+
                     coalesce(ADDRProp.State,ADDR.State)              +','+
                     coalesce(ADDRProp.Zip,ADDR.Zip)                  +','+
                     coalesce(ADDRProp.Country,ADDR.Country)        
          end) as BillToAddressValue
  from  CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
  left outer join
        CUSTOMERS.dbo.Address ADDR with (nolock)
  on    IDER.CompanyIDSeq        = ADDR.CompanyIDSeq
  and   IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
  and   ADDR.CompanyIDSeq        = @IPVC_CompanyIDSeq
  and   IDER.RuleIDSeq           = @IPBI_RuleIDSeq
  and   IDER.RuleType            = @IPVC_RuleType
  and   Coalesce(IDER.BillToAddressTypeCode,'DFT') = Coalesce(ADDR.AddressTypeCode,'DFT')
  and   ADDR.AddressTypeCode not like 'PB%'
  left outer join
        Customers.dbo.AddressType ATC with (nolock)
  on    ADDR.AddressTypeCode = ATC.Code
  and   ATC.Type = 'BILLING'
  left outer join
        CUSTOMERS.dbo.Address ADDRProp with (nolock)
  on    IDER.CompanyIDSeq        = ADDRProp.CompanyIDSeq
  and   IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
  and   ADDRProp.CompanyIDSeq    = @IPVC_CompanyIDSeq
  and   IDER.RuleIDSeq           = @IPBI_RuleIDSeq
  and   IDER.RuleType            = @IPVC_RuleType
  and   Coalesce(IDER.BillToAddressTypeCode,'DFT') = Coalesce(ADDRProp.AddressTypeCode,'DFT')
  and   IDER.ApplyToOMSIDSeq     = ADDRProp.PropertyIDSeq 
  and   ADDRProp.AddressTypeCode like 'PB%'
  left outer join
        Customers.dbo.AddressType ATCP with (nolock)
  on    ADDRProp.AddressTypeCode = ATCP.Code
  and   ATCP.Type = 'BILLING'
  where IDER.CompanyIDSeq        = @IPVC_CompanyIDSeq
  and   IDER.RuleIDSeq           = @IPBI_RuleIDSeq
  and   IDER.RuleType            = @IPVC_RuleType  
  and   Coalesce(ATCP.Type,ATC.Type) = 'BILLING'
  -----------------------------------------------------
  ---Step 4 : Fourth Resultset Delivery Option 
  -----------------------------------------------------
  ---All Records of a given Rule will/should have same DeliveryOptionCode.
  ---So Select Top 1 should suffice.
  select Top 1 
         IDER.DeliveryOptionCode as DeliveryOptionCode,
         DOPC.Name               as DeliveryOptionValue
  from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDER with (nolock)
  inner join
         CUSTOMERS.dbo.DeliveryOption DOPC with (nolock)
  on     IDER.DeliveryOptionCode = DOPC.Code
  and    IDER.CompanyIDSeq       = @IPVC_CompanyIDSeq
  and    IDER.RuleIDSeq          = @IPBI_RuleIDSeq
  and    IDER.RuleType           = @IPVC_RuleType
 -----------------------------------------------------
  ---Step 5 : Fifth Resultset ShowSiteNameOnInvoice 
  -----------------------------------------------------
  select Top 1 
         IDERD.ShowSiteNameOnInvoiceFlag as ShowSiteNameOnInvoiceFlag
  from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail IDERD with (nolock)
  where  IDERD.CompanyIDSeq       = @IPVC_CompanyIDSeq
  and    IDERD.RuleIDSeq          = @IPBI_RuleIDSeq
  and    IDERD.RuleType           = @IPVC_RuleType
END
GO
