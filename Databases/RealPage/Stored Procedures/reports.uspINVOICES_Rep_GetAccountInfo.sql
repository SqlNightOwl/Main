SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_Rep_GetAccountInfo
-- Description     : This procedure gets Invoice Details pertaining to passed InvoiceID
-- Input Parameters: 1. @IPVC_InvoiceIDSeq   as varchar(50)
--      
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_Rep_GetAccountInfo @IPVC_InvoiceID ='I1108000144'
    
-- 
-- 
-- Revision History:
-- 2011-06-14      : SRS. Added PrePaidFlag. when 1 SRS to display PrePaid Water Mark. When 0, No PrePaid watermark.
-- 2010-04-23      : Larry Wilson. (7499) Add BusinessUnit column to result set. Selects RemitTo address and Logo
-- 2006-12-01      : Vinod Krishnan. Stored Procedure Created.
-- 2011-07-12      : Mahaboob Defect #627 Stored Procedure Modified to Display SiteName on Invoice
-- 2011-08-24      : SRS: PCR 627 CompanyName and Property Name is already available on the Invoice Header Record 
--                   This feature applies only to site invoices which have Billing Address PBT that have
--                   Same as PMC Flag  checked and ShowSiteNameOnInvoiceFlag for corresponding Invoice Delivery Rule
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspINVOICES_Rep_GetAccountInfo] (@IPVC_InvoiceID  varchar(50))
AS
BEGIN 
  set nocount on; 
  ---------------------------------------------------------------------------------
  --Local Variable Declaration and Initialization
  declare @LI_ShowSiteNameOnInvoiceFlag  int,
          @LVC_CompanyIDSeq              varchar(50),
          @LVC_PropertyIDSeq             varchar(50)
  set @LI_ShowSiteNameOnInvoiceFlag = 0;

  select Top 1 @LVC_CompanyIDSeq=I.CompanyIDSeq,@LVC_PropertyIDSeq=I.PropertyIDSeq
  from   Invoices.dbo.Invoice I with (nolock)
  where  I.InvoiceIDSeq = @IPVC_InvoiceID
  and    I.PropertyIDSeq is not null
  and    I.BillToAccountName <> coalesce(I.PropertyName,'')
  ---------------------------------------------------------------------------------
  ---> TFS#627 : If a Property Invoice that goes to PBT address (default)
  --      and does have IDE Rule setting for ShowSiteNameOnInvoiceFlag, then show Propertyname on the Invoice.
  --      Else show the default BillToAccountName (which will be Property name for property Invoice and Company Name for Company Invoice) which are recorded on the invoice.
  if (@LVC_PropertyIDSeq is not null)
  BEGIN
  ------------------------------------------
      ;with 
      CBWithOMSID      (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as 
       (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
               (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
               ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT')
                              ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 1
        and    X.ApplyToOMSIDSeq is not null
        and    X.ApplyToOMSIDSeq = @LVC_PropertyIDSeq
       ),
      ------------------------------------------
      CBWithNoOMSID    (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
       (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,X.BillToAddressTypeCode,X.DeliveryOptionCode,
               Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
               (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
                   ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT')
                                      ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 1
        and    X.ApplyToOMSIDSeq is null
       ),
      ------------------------------------------
      AllNullWithOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0
        and    X.ApplyToOMSIDSeq is not null
        and    X.ApplyToOMSIDSeq = @LVC_PropertyIDSeq
        and    coalesce(X.ApplyToProductCode,X.ApplyToProductTypeCode,X.ApplyToCategoryCode,X.ApplyToFamilyCode,'ABCDEF') = 'ABCDEF'
       ),
      ------------------------------------------
      AllNullWithNoOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0
        and    X.ApplyToOMSIDSeq is null
        and    coalesce(X.ApplyToProductCode,X.ApplyToProductTypeCode,X.ApplyToCategoryCode,X.ApplyToFamilyCode,'ABCDEF') = 'ABCDEF'
       ),
      ------------------------------------------
      CTEProductWithOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToProductCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToProductCode is not null
        and    X.ApplyToOMSIDSeq    is not null
        and    X.ApplyToOMSIDSeq = @LVC_PropertyIDSeq
       ),  
      ------------------------------------------
      CTEProductWithNoOMSID (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToProductCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToProductCode is not null
        and    X.ApplyToOMSIDSeq    is null
       ),  
      ------------------------------------------
      CTEProductTypeWithOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductTypeCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductTypeCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToProductTypeCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToProductTypeCode is not null
        and    X.ApplyToOMSIDSeq        is not null
        and    X.ApplyToOMSIDSeq = @LVC_PropertyIDSeq
       ),
      ------------------------------------------
      CTEProductTypeWithNoOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToProductTypeCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToProductTypeCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToProductTypeCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToProductTypeCode is not null
        and    X.ApplyToOMSIDSeq        is null
       ),
      ------------------------------------------
      CTECategoryWithOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToCategoryCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToCategoryCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCategoryCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToCategoryCode is not null
        and    X.ApplyToOMSIDSeq     is not null
        and    X.ApplyToOMSIDSeq = @LVC_PropertyIDSeq
       ),
      ------------------------------------------
      CTECategoryWithNoOMSID   (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToCategoryCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToCategoryCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToCategoryCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToCategoryCode is not null
        and    X.ApplyToOMSIDSeq     is null
       ),
      ------------------------------------------
      CTEFamilyWithOMSID        (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToFamilyCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToFamilyCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToFamilyCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToFamilyCode is not null
        and    X.ApplyToOMSIDSeq   is not null
        and    X.ApplyToOMSIDSeq = @LVC_PropertyIDSeq
       ),
      ------------------------------------------
      CTEFamilyWithNoOMSID        (RuleIDSeq,ApplyToCustomBundleFlag,ApplyToFamilyCode,ApplyToOMSIDSeq,BillToAddressTypeCode,DeliveryOptionCode,ShowSiteNameOnInvoiceFlag,IType,rn) as
      (select X.RuleIDSeq,X.ApplyToCustomBundleFlag,X.ApplyToFamilyCode,X.ApplyToOMSIDSeq,coalesce(X.BillToAddressTypeCode,'PBT') as BillToAddressTypeCode,X.DeliveryOptionCode,
              Convert(int,X.ShowSiteNameOnInvoiceFlag) as ShowSiteNameOnInvoiceFlag,
              (Case when X.BillToAddressTypeCode is null then 'A' when X.BillToAddressTypeCode like 'PB%' then 'P' else 'C' end) as IType,
              ROW_NUMBER() OVER (PARTITION BY X.ApplyToOMSIDSeq,X.ApplyToFamilyCode,
                                              coalesce(X.BillToAddressTypeCode,'PBT')
                                  ORDER BY coalesce(X.BillToAddressTypeCode,'PBT') DESC) rn
        from   CUSTOMERS.dbo.InvoiceDeliveryExceptionRuleDetail X with (nolock)
        where  X.companyIDSeq = @LVC_CompanyIDSeq
        and    X.ApplyToCustomBundleFlag = 0    
        and    X.ApplyToFamilyCode is not null
        and    X.ApplyToOMSIDSeq   is null
       ),
      ------------------------------------------
  CTE_II (InvoiceIDSeq,CompanyIDSeq,PropertyIDSeq,BillToAddressTypeCode,BillToDeliveryOptionCode,
          Productcode,ProductTypeCode,CategoryCode,Familycode,CustomBundlenameEnabledFlag
         ) as 
   (select  I.InvoiceIDSeq,I.CompanyIDSeq,I.PropertyIDSeq,I.BillToAddressTypeCode,I.BillToDeliveryOptionCode,
            PROD.Code as Productcode,PROD.ProductTypeCode,PROD.CategoryCode,PROD.Familycode,IG.CustomBundlenameEnabledFlag as CustomBundlenameEnabledFlag
    from    Invoices.dbo.Invoice     I  with (nolock)
    inner join
            Invoices.dbo.InvoiceItem II with (nolock)
    on     II.InvoiceIDSeq              = I.InvoiceIDSeq
    and    I.InvoiceIDSeq               = @IPVC_InvoiceID
    and    II.InvoiceIDSeq              = @IPVC_InvoiceID
    and    I.PropertyIDSeq is not null
    and    I.BillToAccountName <> coalesce(I.PropertyName,'')
    inner join
           Invoices.dbo.InvoiceGroup IG with (nolock)
    on     IG.Invoiceidseq = I.Invoiceidseq
    and    IG.Invoiceidseq = II.Invoiceidseq
    and    IG.InvoiceIDSeq = @IPVC_InvoiceID
    and    IG.IDSeq        = II.InvoiceGroupIDSeq
    and    IG.OrderIDSeq   = II.OrderIDSeq
    and    IG.OrderGroupIDSeq = II.OrderGroupIDSeq
    inner join
           Products.dbo.Product PROD with (nolock)
    on     II.ProductCode  = PROD.Code
    and    II.PriceVersion = PROD.PriceVersion
    group by I.InvoiceIDSeq,I.CompanyIDSeq,I.PropertyIDSeq,I.BillToAddressTypeCode,I.BillToDeliveryOptionCode,
             PROD.Code,PROD.ProductTypeCode,PROD.CategoryCode,PROD.Familycode,IG.CustomBundlenameEnabledFlag
   )
  select Top 1 @LI_ShowSiteNameOnInvoiceFlag=(Case when CTE_II.CustomBundlenameEnabledFlag = 1
                                                     then coalesce(
                                                                   (case when CBWithOMSID.RuleIDSeq is not null then CBWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                  ,(case when CBWithNoOMSID.RuleIDSeq is not null then CBWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                  ,(case when AllNullWithOMSID.RuleIDSeq is not null then AllNullWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                  ,(case when AllNullWithNoOMSID.RuleIDSeq is not null then AllNullWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                  ,0
                                                                 )
                                                   else coalesce(
                                                                 (case when CTEProductWithOMSID.RuleIDSeq is not null then CTEProductWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEProductTypeWithOMSID.RuleIDSeq is not null then CTEProductTypeWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTECategoryWithOMSID.RuleIDSeq is not null then CTECategoryWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEFamilyWithOMSID.RuleIDSeq is not null then CTEFamilyWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when AllNullWithOMSID.RuleIDSeq is not null then AllNullWithOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEProductWithNoOMSID.RuleIDSeq is not null then CTEProductWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEProductTypeWithNoOMSID.RuleIDSeq is not null then CTEProductTypeWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTECategoryWithNoOMSID.RuleIDSeq is not null then CTECategoryWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when CTEFamilyWithNoOMSID.RuleIDSeq is not null then CTEFamilyWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,(case when AllNullWithNoOMSID.RuleIDSeq is not null then AllNullWithNoOMSID.ShowSiteNameOnInvoiceFlag else Null end)
                                                                ,0
                                                               )
                                              end)

  from   CTE_II
  -----------------------------------------------------
  left outer join
                   CBWithOMSID
  on   CTE_II.CustomBundlenameEnabledFlag = CBWithOMSID.ApplyToCustomBundleFlag
  and  CTE_II.CustomBundlenameEnabledFlag       = 1
  and  CBWithOMSID.ApplyToCustomBundleFlag      = 1
  and  CBWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq               = coalesce(CBWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CBWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CBWithOMSID.DeliveryOptionCode
  ----------------
  left outer join
                   CBWithNoOMSID
  on   CTE_II.CustomBundlenameEnabledFlag = CBWithNoOMSID.ApplyToCustomBundleFlag
  and  CTE_II.CustomBundlenameEnabledFlag = 1
  and  CBWithNoOMSID.ApplyToCustomBundleFlag     = 1
  and  CBWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq               = coalesce(CBWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CBWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CBWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   AllNullWithOMSID
  on   AllNullWithOMSID.ApplyToCustomBundleFlag = 0
  and  AllNullWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(AllNullWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = AllNullWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = AllNullWithOMSID.DeliveryOptionCode
  ----------------
  left outer join
                   AllNullWithNoOMSID
  on   AllNullWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  AllNullWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(AllNullWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = AllNullWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = AllNullWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEProductWithOMSID
  on   CTE_II.ProductCode                 = CTEProductWithOMSID.ApplyToProductCode  
  and  CTEProductWithOMSID.ApplyToCustomBundleFlag = 0
  and  CTEProductWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEProductWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEProductWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEProductWithOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEProductWithNoOMSID
  on   CTE_II.ProductCode                 = CTEProductWithNoOMSID.ApplyToProductCode  
  and  CTEProductWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  CTEProductWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEProductWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEProductWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEProductWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEProductTypeWithOMSID
  on   CTE_II.ProductTypeCode             = CTEProductTypeWithOMSID.ApplyToProductTypeCode    
  and  CTEProductTypeWithOMSID.ApplyToCustomBundleFlag = 0
  and  CTEProductTypeWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEProductTypeWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEProductTypeWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEProductTypeWithOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEProductTypeWithNoOMSID
  on   CTE_II.ProductTypeCode             = CTEProductTypeWithNoOMSID.ApplyToProductTypeCode    
  and  CTEProductTypeWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  CTEProductTypeWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEProductTypeWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEProductTypeWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEProductTypeWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTECategoryWithOMSID
  on   CTE_II.CategoryCode                = CTECategoryWithOMSID.ApplyToCategoryCode    
  and  CTECategoryWithOMSID.ApplyToCustomBundleFlag = 0
  and  CTECategoryWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTECategoryWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTECategoryWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTECategoryWithOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTECategoryWithNoOMSID
  on   CTE_II.CategoryCode                = CTECategoryWithNoOMSID.ApplyToCategoryCode  
  and  CTECategoryWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  CTECategoryWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTECategoryWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTECategoryWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTECategoryWithNoOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEFamilyWithOMSID
  on   CTE_II.FamilyCode                  = CTEFamilyWithOMSID.ApplyToFamilyCode  
  and  CTEFamilyWithOMSID.ApplyToCustomBundleFlag = 0
  and  CTEFamilyWithOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEFamilyWithOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEFamilyWithOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEFamilyWithOMSID.DeliveryOptionCode
  -----------------------------------------------------
  left outer join
                   CTEFamilyWithNoOMSID
  on   CTE_II.FamilyCode                  = CTEFamilyWithNoOMSID.ApplyToFamilyCode  
  and  CTEFamilyWithNoOMSID.ApplyToCustomBundleFlag = 0
  and  CTEFamilyWithNoOMSID.rn = 1
  and  CTE_II.PropertyIDSeq = coalesce(CTEFamilyWithNoOMSID.ApplyToOMSIDSeq,CTE_II.PropertyIDSeq)
  and  CTE_II.BillToAddressTypeCode       = CTEFamilyWithNoOMSID.BillToAddressTypeCode
  and  CTE_II.BillToDeliveryOptionCode    = CTEFamilyWithNoOMSID.DeliveryOptionCode
  ----------------------------------------------------- 
  where CTE_II.InvoiceIDSeq               = @IPVC_InvoiceID
  and   CTE_II.CompanyIDSeq               = @LVC_CompanyIDSeq
  and   CTE_II.PropertyIDSeq              = @LVC_PropertyIDSeq
  END
  ---------------------------------------------------------------------------------
  Select  Top 1
                I.InvoiceIDSeq                                  'InvoiceNo',
                I.AccountIDSeq                                  'AccountID',
                coalesce(I.PropertyName,I.CompanyName)          'AccountName',
                I.[Units]                                       'NoOfUnits',
                I.PropertyIDSeq,
                I.CompanyIDSeq,
                convert(varchar(20),I.InvoiceDate,101)          'InvoiceDate',
                '30 days'                                       'InvoiceTerm',
                (I.ILFChargeAmount + I.AccessChargeAmount + I.TransactionChargeAmount + I.ShippingandHandlingAmount + I.TaxAmount) 'TotalDue',
                convert(varchar(20), I.InvoiceDueDate, 101)     'DueDate',
                I.TaxAmount                                     'TaxAmount',
                I.EpicorCustomerCode                            'EpicorCode',
                -------------------------------------------------------------
                (case when @LI_ShowSiteNameOnInvoiceFlag = 1
                       then coalesce(I.PropertyName,I.BillToAccountName)
                      else I.BillToAccountName
                 end)                                           'BillingName',      ---> This should be used for Billing Address section
                I.BillToAddressLine1                            'BillingAddress1',
                I.BillToAddressLine2                            'BillingAddress2',
                I.BillToCity                                    'BillingCity',
                I.BillToState + ' ' + I.BillToZip               'BillingStateZip',
                Upper(I.BillToCountry)                          'BillingCountry',
               -------------------------------------------------------------
                I.ShipToAccountName                             'ShipToAccountName', ---> This should be used for Shipping Address section
                I.ShipToAddressLine1                            'ShippingAddress1',
                I.ShipToAddressLine2                            'ShippingAddress2',
                I.ShipToCity                                    'ShippingCity',
                I.ShipToState + ' ' + I.ShipToZip               'ShippingStateZip',
                Upper(I.ShipToCountry)                          'ShippingCountry',
               -------------------------------------------------------------
                I.PrintCount                                    'PrintCount',
                lower([dbo].[fnGetInvoiceLogoDefinition](@IPVC_InvoiceID)) as [BusinessUnit],
                I.PrintFlag                                                as PrintFlag, 
                I.PrePaidFlag                                              as PrePaidFlag                
  From Invoices.dbo.Invoice I with (nolock) 
  Where I.InvoiceIDSeq = @IPVC_InvoiceID
END 
GO
