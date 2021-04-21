SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspORDERS_MBADOExceptionRulesEngine
-- Description     : This procedure gets Applicable MBA Applicable Exception Rules for a Given CompanyID
-- Input Parameters: @IPVC_CompanyIDSeq      as varchar(50)
-- Syntax          : 
/*
EXEC ORDERS.dbo.uspORDERS_MBADOExceptionRulesEngine  @IPVC_CompanyIDSeq='C0901010086'  
EXEC ORDERS.dbo.uspORDERS_MBADOExceptionRulesEngine  @IPVC_CompanyIDSeq='C0901000061'
*/
-- Revision History:
-- Author          : SRS
-- 02/14/2010      : SRS (Defect 7915) Multiple Billing Address enhancement. SP Created.
-----------------------------------------------------------------------------------------------------------------------------
Create PROCEDURE [orders].[uspORDERS_MBADOExceptionRulesEngine] (@IPVC_CompanyIDSeq varchar(50) --> This is the CompanyID
                                                             )
as
BEGIN
  set nocount on;
  ------------------------------------------
  ;with 
  CBWithOMSID      (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as 
   (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
           (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
           ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 1
    and    X.ApplyToOMSIDSeq is not null
   ),
  ------------------------------------------
  CBWithNoOMSID    (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
   (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
           (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
           ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 1
    and    X.ApplyToOMSIDSeq is null
   ),
  ------------------------------------------
  AllNullWithOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0
    and    X.ApplyToOMSIDSeq is not null
    and    coalesce(X.ApplyToProductCode,X.ApplyToProductTypeCode,X.ApplyToCategoryCode,X.ApplyToFamilyCode,'ABCDEF') = 'ABCDEF'
   ),
  ------------------------------------------
  AllNullWithNoOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0
    and    X.ApplyToOMSIDSeq is null
    and    coalesce(X.ApplyToProductCode,X.ApplyToProductTypeCode,X.ApplyToCategoryCode,X.ApplyToFamilyCode,'ABCDEF') = 'ABCDEF'
   ),
  ------------------------------------------
  CTEProductWithOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductCode,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductCode,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0    
    and    X.ApplyToProductCode is not null
    and    X.ApplyToOMSIDSeq    is not null
   ),  
  ------------------------------------------
  CTEProductWithNoOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductCode,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductCode,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0    
    and    X.ApplyToProductCode is not null
    and    X.ApplyToOMSIDSeq    is null
   ),  
  ------------------------------------------
  CTEProductTypeWithOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductTypeCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductTypeCode,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductTypeCode,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0    
    and    X.ApplyToProductTypeCode is not null
    and    X.ApplyToOMSIDSeq        is not null
   ),
  ------------------------------------------
  CTEProductTypeWithNoOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductTypeCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductTypeCode,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductTypeCode,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0    
    and    X.ApplyToProductTypeCode is not null
    and    X.ApplyToOMSIDSeq        is null
   ),
  ------------------------------------------
  CTECategoryWithOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToCategoryCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToCategoryCode,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToCategoryCode,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0    
    and    X.ApplyToCategoryCode is not null
    and    X.ApplyToOMSIDSeq     is not null
   ),
  ------------------------------------------
  CTECategoryWithNoOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToCategoryCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToCategoryCode,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToCategoryCode,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0    
    and    X.ApplyToCategoryCode is not null
    and    X.ApplyToOMSIDSeq     is null
   ),
  ------------------------------------------
  CTEFamilyWithOMSID        (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToFamilyCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToFamilyCode,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToFamilyCode,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0    
    and    X.ApplyToFamilyCode is not null
    and    X.ApplyToOMSIDSeq   is not null
   ),
  ------------------------------------------
  CTEFamilyWithNoOMSID        (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToFamilyCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,IType,rn) as
  (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToFamilyCode,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
          (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
          ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToFamilyCode,
                                          (Case when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end)
                              ORDER BY BillToAddressTypeCode DESC) rn
    from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
    where  X.companyIDSeq = @IPVC_CompanyIDSeq
    and    X.ApplyToCustomBundleFlag = 0    
    and    X.ApplyToFamilyCode is not null
    and    X.ApplyToOMSIDSeq   is null
   ),
  ------------------------------------------
  OrderRecords     (companyidseq,Propertyidseq,AccountIDSeq,OrderApplyToOMSID,
                    CustomBundlenameEnabledFlag,Productcode,ProductTypeCode,CategoryCode,Familycode,PlatFormCode,
                    OrderIDSeq,OrderGroupIDSeq,OrderitemIDseq,CurrentBillToAddressTypecode,CurrentBillToDeliveryOptionCode,
                    DefaultBillToAddressTypecode,DefaultBillToDeliveryOptionCode) as
  (select O.companyidseq,nullif(O.Propertyidseq,'') as Propertyidseq,O.AccountIDSeq,
          coalesce(nullif(O.Propertyidseq,''),O.companyidseq) as OrderApplyToOMSID,
          convert(int,OG.CustomBundlenameEnabledFlag) as CustomBundlenameEnabledFlag,
          OI.Productcode,P.ProductTypeCode,P.CategoryCode,P.Familycode,P.PlatFormCode,
          OI.OrderIDSeq,OI.OrderGroupIDSeq,OI.IDSeq   as OrderitemIDseq,
          OI.BillToAddressTypecode                                                 as CurrentBillToAddressTypecode,
          coalesce(OI.BillToDeliveryOptionCode,'SMAIL')                            as CurrentBillToDeliveryOptionCode,
          (case when nullif(O.Propertyidseq,'') is null then 'CBT' else 'PBT' end) as DefaultBillToAddressTypecode,
          'SMAIL'                                                                  as DefaultBillToDeliveryOptionCode
   from   Orders.dbo.[Order] O with (nolock)
   inner join
          Orders.dbo.[OrderGroup] OG with (nolock)
   on     OG.OrderIDSeq      = O.OrderIDSeq
   inner join 
          Orders.dbo.Orderitem OI with (nolock) 
   on     OI.Orderidseq      = O.Orderidseq
   and    OI.Orderidseq      = OG.Orderidseq
   and    OI.OrderGroupIDSeq = OG.IDseq
   and    O.CompanyIDSeq     = @IPVC_CompanyIDSeq
   inner join
          Products.dbo.product P with (nolock)
   on     OI.Productcode     = P.Code
   and    OI.Priceversion    = P.Priceversion
  )
  ------------------------------------------------------------------
  select  OrderRecords.companyidseq                             as companyidseq,
          OrderRecords.Propertyidseq                            as propertyidseq,
          OrderRecords.AccountIDSeq                             as accountidseq,
          OrderRecords.Productcode                              as productcode,
          OrderRecords.CustomBundlenameEnabledFlag              as custombundlenameenabledflag,
          OrderRecords.OrderIDSeq                               as orderidseq,
          OrderRecords.OrderGroupIDSeq                          as ordergroupidseq,
          OrderRecords.OrderitemIDseq                           as orderitemidseq,
          OrderRecords.CurrentBillToAddressTypecode             as currentbilltoaddresstypecode,
          OrderRecords.CurrentBillToDeliveryOptionCode          as currentbilltodeliveryoptioncode,
          -----------------------------------------------------------
          (Case when OrderRecords.CustomBundlenameEnabledFlag = 1
                          then coalesce(
                                         (case when CBWithOMSID.RuleIDSeq is not null then coalesce(CBWithOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when CBWithNoOMSID.RuleIDSeq is not null then coalesce(CBWithNoOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when AllNullWithOMSID.RuleIDSeq is not null then coalesce(AllNullWithOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when AllNullWithNoOMSID.RuleIDSeq is not null then coalesce(AllNullWithNoOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,OrderRecords.DefaultBillToAddressTypecode
                                       )
                          else coalesce(
                                         (case when CTEProductWithOMSID.RuleIDSeq is not null then coalesce(CTEProductWithOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when CTEProductTypeWithOMSID.RuleIDSeq is not null then coalesce(CTEProductTypeWithOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when CTECategoryWithOMSID.RuleIDSeq is not null then coalesce(CTECategoryWithOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when CTEFamilyWithOMSID.RuleIDSeq is not null then coalesce(CTEFamilyWithOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when AllNullWithOMSID.RuleIDSeq is not null then coalesce(AllNullWithOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when CTEProductWithNoOMSID.RuleIDSeq is not null then coalesce(CTEProductWithNoOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when CTEProductTypeWithNoOMSID.RuleIDSeq is not null then coalesce(CTEProductTypeWithNoOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when CTECategoryWithNoOMSID.RuleIDSeq is not null then coalesce(CTECategoryWithNoOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when CTEFamilyWithNoOMSID.RuleIDSeq is not null then coalesce(CTEFamilyWithNoOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,(case when AllNullWithNoOMSID.RuleIDSeq is not null then coalesce(AllNullWithNoOMSID.BillToAddressTypeCode,OrderRecords.DefaultBillToAddressTypecode) else Null end)
                                        ,OrderRecords.DefaultBillToAddressTypecode                    
                                        )                
           end)                                                 as newbilltoaddresstypecode,
          -----------------------------------------------------------
          (Case when OrderRecords.CustomBundlenameEnabledFlag = 1
                          then coalesce(
                                         (case when CBWithOMSID.RuleIDSeq is not null then coalesce(CBWithOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when CBWithNoOMSID.RuleIDSeq is not null then coalesce(CBWithNoOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when AllNullWithOMSID.RuleIDSeq is not null then coalesce(AllNullWithOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when AllNullWithNoOMSID.RuleIDSeq is not null then coalesce(AllNullWithNoOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,OrderRecords.DefaultBillToDeliveryOptionCode
                                       )

                          else coalesce(
                                         (case when CTEProductWithOMSID.RuleIDSeq is not null then coalesce(CTEProductWithOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when CTEProductTypeWithOMSID.RuleIDSeq is not null then coalesce(CTEProductTypeWithOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when CTECategoryWithOMSID.RuleIDSeq is not null then coalesce(CTECategoryWithOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when CTEFamilyWithOMSID.RuleIDSeq is not null then coalesce(CTEFamilyWithOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when AllNullWithOMSID.RuleIDSeq is not null then coalesce(AllNullWithOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when CTEProductWithNoOMSID.RuleIDSeq is not null then coalesce(CTEProductWithNoOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when CTEProductTypeWithNoOMSID.RuleIDSeq is not null then coalesce(CTEProductTypeWithNoOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when CTECategoryWithNoOMSID.RuleIDSeq is not null then coalesce(CTECategoryWithNoOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when CTEFamilyWithNoOMSID.RuleIDSeq is not null then coalesce(CTEFamilyWithNoOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,(case when AllNullWithNoOMSID.RuleIDSeq is not null then coalesce(AllNullWithNoOMSID.DeliveryOptionCode,OrderRecords.DefaultBillToDeliveryOptionCode) else Null end)
                                        ,OrderRecords.DefaultBillToDeliveryOptionCode                    
                                        ) 
        
           end)                                                as newbilltodeliveryoptioncode
  ------------------------------------------------------------------
  from             OrderRecords 
  left outer join
                   CBWithOMSID
  on   OrderRecords.CustomBundlenameEnabledFlag = CBWithOMSID.ApplyToCustomBundleFlag
  and  OrderRecords.CustomBundlenameEnabledFlag = 1
  and  CBWithOMSID.ApplyToCustomBundleFlag      = 1
  and  CBWithOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CBWithOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CBWithOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CBWithOMSID.IType in ('A','C'))
       )
  ----------------
  left outer join
                   CBWithNoOMSID
  on   OrderRecords.CustomBundlenameEnabledFlag = CBWithNoOMSID.ApplyToCustomBundleFlag
  and  OrderRecords.CustomBundlenameEnabledFlag = 1
  and  CBWithNoOMSID.ApplyToCustomBundleFlag    = 1
  and  CBWithNoOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CBWithNoOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CBWithNoOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CBWithNoOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
  left outer join
                   AllNullWithOMSID
  on   AllNullWithOMSID.ApplyToCustomBundleFlag = 0
  and  AllNullWithOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(AllNullWithOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((AllNullWithOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (AllNullWithOMSID.IType in ('A','C'))
       )
  ----------------
  left outer join
                   AllNullWithNoOMSID
  on   AllNullWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  AllNullWithNoOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(AllNullWithNoOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((AllNullWithNoOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (AllNullWithNoOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
  left outer join
                   CTEProductWithOMSID
  on   OrderRecords.ProductCode                 = CTEProductWithOMSID.ApplyToProductCode
  and  CTEProductWithOMSID.ApplyToCustomBundleFlag       = 0
  and  CTEProductWithOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CTEProductWithOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CTEProductWithOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CTEProductWithOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
  left outer join
                   CTEProductWithNoOMSID
  on   OrderRecords.ProductCode                 = CTEProductWithNoOMSID.ApplyToProductCode
  and  CTEProductWithNoOMSID.ApplyToCustomBundleFlag       = 0
  and  CTEProductWithNoOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CTEProductWithNoOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CTEProductWithNoOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CTEProductWithNoOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
  left outer join
                   CTEProductTypeWithOMSID
  on   OrderRecords.ProductTypeCode             = CTEProductTypeWithOMSID.ApplyToProductTypeCode  
  and  CTEProductTypeWithOMSID.ApplyToCustomBundleFlag   = 0
  and  CTEProductTypeWithOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CTEProductTypeWithOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CTEProductTypeWithOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CTEProductTypeWithOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
  left outer join
                   CTEProductTypeWithNoOMSID
  on   OrderRecords.ProductTypeCode             = CTEProductTypeWithNoOMSID.ApplyToProductTypeCode  
  and  CTEProductTypeWithNoOMSID.ApplyToCustomBundleFlag   = 0
  and  CTEProductTypeWithNoOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CTEProductTypeWithNoOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CTEProductTypeWithNoOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CTEProductTypeWithNoOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
  left outer join
                   CTECategoryWithOMSID
  on   OrderRecords.CategoryCode                = CTECategoryWithOMSID.ApplyToCategoryCode  
  and  CTECategoryWithOMSID.ApplyToCustomBundleFlag      = 0
  and  CTECategoryWithOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CTECategoryWithOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CTECategoryWithOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CTECategoryWithOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
  left outer join
                   CTECategoryWithNoOMSID
  on   OrderRecords.CategoryCode                = CTECategoryWithNoOMSID.ApplyToCategoryCode  
  and  CTECategoryWithNoOMSID.ApplyToCustomBundleFlag      = 0
  and  CTECategoryWithNoOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CTECategoryWithNoOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CTECategoryWithNoOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CTECategoryWithNoOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
  left outer join
                   CTEFamilyWithOMSID
  on   OrderRecords.FamilyCode                  = CTEFamilyWithOMSID.ApplyToFamilyCode  
  and  CTEFamilyWithOMSID.ApplyToCustomBundleFlag        = 0
  and  CTEFamilyWithOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CTEFamilyWithOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CTEFamilyWithOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CTEFamilyWithOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
  left outer join
                   CTEFamilyWithNoOMSID
  on   OrderRecords.FamilyCode                  = CTEFamilyWithNoOMSID.ApplyToFamilyCode  
  and  CTEFamilyWithNoOMSID.ApplyToCustomBundleFlag        = 0
  and  CTEFamilyWithNoOMSID.rn = 1
  and  OrderRecords.OrderApplyToOMSID = coalesce(CTEFamilyWithNoOMSID.ApplyToOMSIDSeq,OrderRecords.OrderApplyToOMSID)
  and  ((CTEFamilyWithNoOMSID.IType in ('A','P') and OrderRecords.PropertyIDSeq is not null)
          OR
        (CTEFamilyWithNoOMSID.IType in ('A','C'))
       )
  -----------------------------------------------------
 where OrderRecords.CompanyIDSeq     = @IPVC_CompanyIDSeq
 order by OrderRecords.OrderitemIDseq
END
GO
