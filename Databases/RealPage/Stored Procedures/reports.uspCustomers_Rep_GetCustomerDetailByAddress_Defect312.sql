SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : CUSTOMERS      
-- Procedure Name  : [uspCustomers_Rep_GetCustomerDetailByAddress]      
-- Description     : This procedure gets Details based on Customer.
-- Input Parameters: All Input Parameters are Optional
-- Code Example    : exec [dbo].[uspCustomers_Rep_GetCustomerDetailByAddress]    
--													@IPVC_CompanyID    = 'C0812000008',
--													@IPVC_CustomerName = '',
--				
-- Revision History:      
-- Author          : Anand Chakravarthy      
-- 06/24/2010      : Stored Procedure Created.
-- 12/31/2010	   : Surya Kiran Defect # 8661 - Darla has put in a report request to know what PMC's have a synch turned on and what date they synch
-- 12/31/2010	   : Surya Kiran Defect # 8662 - OMS Reports needs to include the Related Company System ID
-- 12/04/2011	   : Raghavender Defect# 9223 - modifications for the Customer Details for Ops Merchant Import needed to add column for country. 
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspCustomers_Rep_GetCustomerDetailByAddress_Defect312]      
(      
 @IPVC_CompanyID       VARCHAR(50)  = '',
 @IPVC_CustomerName    VARCHAR(100) = '',
 @IPVC_PropertyID      VARCHAR(50)  = '',
 @IPVC_PropertyName    VARCHAR(100) = '',
 @IPVC_RelComAccountID VARCHAR(50)  = '',
 @IPVC_RelProAccountID VARCHAR(50)  = '',  
 @IncludeProperties    BIT
 )      
AS      
BEGIN           
SET NOCOUNT ON     
 --------------------------------------------------------------------------  
  SET @IPVC_CompanyID     = NULLIF(@IPVC_CompanyID,'')  
  SET @IPVC_PropertyID    = NULLIF(@IPVC_PropertyID,'')  
--------------------------------------------------------------------------  
SELECT A.*  
INTO #LT_GetCustomerDetailByAddress    
FROM  
(  
 SELECT C.IDSeq                                                             AS CustomerID,  
       MAX(C.Name)                                                                        AS CustomerName,  
       MAX(C.SiteMasterID)                                                                AS SiteMasterID,  
       MAX(COALESCE(aCOM.PhoneVoice1,''))                      AS PhoneVoice1,  
       MAX(COALESCE(aCOM.PhoneFax,''))                              AS Fax,  
       MAX(COALESCE(aCOM.Email,''))                       AS Email,  
       MAX(C.OrderSynchStartMonth)                 AS OrderSynchStartMonth,  
       MAX(COALESCE(CBPT.[Description],''))                                               AS CustomBundlesProductBreakDownTypeCode,  
       (CASE WHEN MAX(convert(int,C.SeparateInvoiceByFamilyFlag)) = 1 THEN 'Yes'  
    ELSE 'No'                                       
    END)            AS SeparateInvoiceByFamilyFlag,  
       MAX(COALESCE(aCOM.AddressLine1,''))                                                AS AddressLine1,  
       MAX(COALESCE(aCOM.AddressLine2,''))                                                AS AddressLine2,  
       MAX(COALESCE(aCOM.city,''))                                                        AS City,  
       MAX(COALESCE(aCOM.[state],''))                                                     AS [State],  
       MAX(COALESCE(aCOM.zip,''))                                                         AS Zip,  
       MAX(COALESCE(aCOM.CountryCode,''))                                                 AS CountryCode,  
       MAX(COALESCE(aCBT.AttentionName,''))                                               AS AttentionName,  
       MAX(COALESCE(aCBT.Email,''))                       AS BillingEmail,  
       MAX(COALESCE(aCBT.AddressLine1,''))                                                AS BillingAddressLine1,  
       MAX(COALESCE(aCBT.AddressLine2,''))                                                AS BillingAddressLine2,  
       MAX(COALESCE(aCBT.city,''))                                                        AS Billingcity,  
       MAX(COALESCE(aCBT.[state],''))                                                     AS Billingstate,  
       MAX(COALESCE(aCBT.zip,''))                                                 AS Billingzip,  
       MAX(COALESCE(aCBT.CountryCode,''))                                                 AS Billingcountrycode,  
       MAX(COALESCE(aCST.AddressLine1,''))                                                AS ShippingAddressLine1,  
       MAX(COALESCE(aCST.AddressLine2,''))                                                AS ShippingAddressLine2,  
       MAX(COALESCE(aCST.city,''))                                                        AS Shippingcity,  
       MAX(COALESCE(aCST.[state],''))                                                     AS Shippingstate,  
       MAX(COALESCE(aCST.zip,''))                                                         AS Shippingzip,  
       MAX(COALESCE(aCST.CountryCode,''))                                                 AS Shippingcountrycode,  
       ''            AS PropertyIDSeq,  
       ''            AS PropertyName,  
       ''            AS PropertySiteMasterID,  
	  (Case when C.StatusTypeCode ='ACTIV' Then 'Active' else 'Inactive' end) as Status,				  
       (select isnull(Sum(units),'0') from Property Prop inner join company comp on Prop.PMCIDSeq=comp.Idseq where prop.pmcidseq=isnull(@IPVC_CompanyID,C.IDSeq))   as Units,
       ''            AS Beds,  
       ''               AS Phase,       
       ''            AS PPU,  
       ''            AS [Owner],  
       convert(varchar(100),'')                                                           as RelatedCompanyInterfaceName,  
       convert(varchar(100),'')                                                           as RelatedCompanyAccountID,  
       convert(varchar(100),'')                                                           as RelatedPropertyInterfaceName,  
       convert(varchar(100),'')                                                           as RelatedPropertyAccountID,
        MAX(COALESCE(IDER.RuleName, ''))													  as [Invoice Delivery Rule],
       MAX(COALESCE(IDER.RuleType, ''))													  as [Rule Type],
       MAX(COALESCE(DO.[Name], 'Print and Mail'))														  as [Delivery Option],
       MAX(COALESCE(aCBT.AttentionName, ''))											  as [Billing Contact Name]  
    FROM       Customers.dbo.Company c WITH (NOLOCK)  
    INNER JOIN Customers.dbo.Address aCOM WITH (NOLOCK)  
               ON c.IDSeq = aCOM.CompanyIDSeq  
               AND aCOM.AddressTypeCode = 'COM' AND aCOM.PropertyIDSeq IS NULL  
               AND C.IDSeq = isnull(@IPVC_CompanyID,C.IDSeq)   
    INNER JOIN Customers.dbo.Address aCST WITH (NOLOCK)  
  ON c.IDSeq = aCST.CompanyIDSeq   
  AND aCST.AddressTypeCode = 'CST' AND aCST.PropertyIDSeq IS NULL  
                AND C.IDSeq = isnull(@IPVC_CompanyID,C.IDSeq)  
    INNER JOIN Customers.dbo.Address aCBT WITH (NOLOCK)   
  ON c.IDSeq = aCBT.CompanyIDSeq   
  AND aCBT.AddressTypeCode = 'CBT' and aCBT.PropertyIDSeq IS NULL  
                AND C.IDSeq = isnull(@IPVC_CompanyID,C.IDSeq)  
    INNER JOIN Customers.dbo.CustomBundlesProductBreakDownType CBPT WITH (NOLOCK)   
         ON C.CustomBundlesProductBreakDownTypeCode = CBPT.Code 

  LEFT OUTER JOIN Customers.dbo.InvoiceDeliveryExceptionRule IDER
  ON C.IDSeq = IDER.CompanyIDSeq
  
  LEFT OUTER JOIN Customers.dbo.InvoiceDeliveryExceptionRuleDetail IDERD
  ON  IDER.RuleIDSeq = IDERD.RuleIDSeq and IDER.CompanyIDSeq = IDERD.CompanyIDSeq
   
  LEFT OUTER JOIN Customers.dbo.DeliveryOption DO
  ON DO.Code = IDERD.DeliveryOptionCode

         
WHERE C.IDSeq = isnull(@IPVC_CompanyID,C.IDSeq)  
AND   C.Name         LIKE '%' + @IPVC_CustomerName + '%'  
AND   (@IPVC_PropertyID = '' OR @IPVC_PropertyID IS NULL)  
AND   (@IPVC_PropertyName = '' OR @IPVC_PropertyName IS NULL)  
GROUP BY C.IDSeq,C.StatusTypeCode     
----------------------------------------------------------  
  UNION ALL  
----------------------------------------------------------  
Select C.IDSeq                                                                            AS CustomerID,  
       MAX(C.Name)                                                                        AS CustomerName,  
       MAX(C.SiteMasterID)                                                                AS SiteMasterID,  
       MAX(COALESCE(aCOM.PhoneVoice1,''))                             AS PhoneVoice1,  
       MAX(COALESCE(aCOM.PhoneFax,''))                              AS Fax,  
       MAX(COALESCE(aCOM.Email,''))                              AS Email,  
       MAX(C.OrderSynchStartMonth)                   AS OrderSynchStartMonth,  
       MAX(CBPT.[Description])                                                            AS CustomBundlesProductBreakDownTypeCode,  
       (CASE WHEN MAX(convert(int,P.SeparateInvoiceByFamilyFlag)) = 1 THEN 'Yes'  
    ELSE 'No'                                       
    END)            AS SeparateInvoiceByFamilyFlag,  
       MAX(COALESCE(aCOM.AddressLine1,''))                                                AS AddressLine1,  
       MAX(COALESCE(aCOM.AddressLine2,''))                                                AS AddressLine2,  
       MAX(COALESCE(aCOM.city,''))                                                        AS City,  
       MAX(COALESCE(aCOM.[state],''))                                                     AS [State],  
       MAX(COALESCE(aCOM.zip,''))                                                         AS Zip,  
       MAX(COALESCE(aCOM.CountryCode,''))                                                 AS CountryCode,  
       MAX(COALESCE(aCBT.AttentionName,''))                                               AS AttentionName,  
       MAX(COALESCE(aCBT.Email,''))                       AS BillingEmail,  
       MAX(COALESCE(aCBT.AddressLine1,''))                                                AS BillingAddressLine1,  
       MAX(COALESCE(aCBT.AddressLine2,''))                                                AS BillingAddressLine2,  
       MAX(COALESCE(aCBT.city,''))                                                        AS Billingcity,  
       MAX(COALESCE(aCBT.[state],''))                                                     AS Billingstate,  
       MAX(COALESCE(aCBT.zip,''))                                                         AS Billingzip,  
       MAX(COALESCE(aCBT.CountryCode,''))                                                 AS Billingcountrycode,  
       MAX(COALESCE(aCST.AddressLine1,''))                                                AS ShippingAddressLine1,  
       MAX(COALESCE(aCST.AddressLine2,''))                                                AS ShippingAddressLine2,  
       MAX(COALESCE(aCST.city,''))                                                        AS Shippingcity,  
       MAX(COALESCE(aCST.[state],''))                                                     AS Shippingstate,  
       MAX(COALESCE(aCST.zip,''))                                                         AS Shippingzip,  
       MAX(COALESCE(aCST.CountryCode,''))                                                 AS Shippingcountrycode,  
       P.IDSeq            AS PropertyIDSeq,  
       MAX(P.Name)           AS PropertyName,  
       MAX(P.SiteMasterID)                  AS PropertySiteMasterID,  
	   (Case when P.StatusTypeCode ='ACTIV' then 'Active' else 'Inactive' end) as Status,		
       MAX(P.Units)           AS Units, 
		 
       MAX(P.Beds)           AS Beds,  
       MAX(P.Phase)           AS Phase,       
       MAX(P.PPUPercentage)          AS PPU,  
       MAX(P.OwnerName)           AS [Owner],  
       convert(varchar(100),'')                                                           as RelatedCompanyInterfaceName,  
       convert(varchar(100),'')                                                           as RelatedCompanyAccountID,  
       convert(varchar(100),'')                                                           as RelatedPropertyInterfaceName,  
       convert(varchar(100),'')                                                           as RelatedPropertyAccountID,
       MAX(COALESCE(IDER.RuleName, ''))													  as [Invoice Delivery Rule],
       MAX(COALESCE(IDER.RuleType, ''))													  as [Rule Type],
       MAX(COALESCE(DO.[Name], 'Print and Mail'))														  as [Delivery Option],
       MAX(COALESCE(aCBT.AttentionName, ''))											  as [Billing Contact Name]  
  FROM Customers.dbo.Property P WITH (NOLOCK)  
  INNER JOIN Customers.dbo.Company C WITH (NOLOCK)  
     ON  P.PMCIDSeq = C.IDSeq  
     AND (@IncludeProperties = 1)  
            AND  C.IDSeq   = isnull(@IPVC_CompanyID,C.IDSeq)  
            AND   P.IDSeq  = ISNULL(@IPVC_PropertyID,P.IDSeq)  
  INNER JOIN Customers.dbo.Address aCOM WITH (NOLOCK)  
  ON  P.PMCIDSeq = aCOM.CompanyIDSeq  
                AND P.IDSeq    = aCOM.PropertyIDSeq  
  AND  aCOM.AddressTypeCode = 'PRO'   
                AND  C.IDSeq = isnull(@IPVC_CompanyID,C.IDSeq)  
  INNER JOIN Customers.dbo.Address aCST WITH (NOLOCK)  
  ON   P.PMCIDSeq = aCST.CompanyIDSeq  
                and  P.IDSeq = aCST.PropertyIDSeq   
  AND  aCST.AddressTypeCode = 'PST'  
                AND  C.IDSeq = isnull(@IPVC_CompanyID,C.IDSeq)   
  INNER JOIN Customers.dbo.Address aCBT WITH (NOLOCK)  
     ON  P.PMCIDSeq = aCBT.CompanyIDSeq  
            and P.IDSeq    = aCBT.PropertyIDSeq   
     AND aCBT.AddressTypeCode = 'PBT'  
            AND  C.IDSeq = isnull(@IPVC_CompanyID,C.IDSeq)  
  INNER JOIN Customers.dbo.CustomBundlesProductBreakDownType CBPT WITH (NOLOCK)   
  ON P.CustomBundlesProductBreakDownTypeCode = CBPT.Code
  
  LEFT OUTER JOIN Customers.dbo.InvoiceDeliveryExceptionRule IDER
  ON P.PMCIDSeq = IDER.CompanyIDSeq
  
  LEFT OUTER JOIN Customers.dbo.InvoiceDeliveryExceptionRuleDetail IDERD
  ON  IDER.RuleIDSeq = IDERD.RuleIDSeq and IDER.CompanyIDSeq = IDERD.CompanyIDSeq
   
  LEFT OUTER JOIN Customers.dbo.DeliveryOption DO
  ON DO.Code = IDERD.DeliveryOptionCode

  WHERE C.IDSeq = ISNULL(@IPVC_CompanyID,C.IDSeq)  
  AND   C.Name         LIKE '%' + @IPVC_CustomerName + '%'    
  AND   P.IDSeq = ISNULL(@IPVC_PropertyID,P.IDSeq)  
  AND   P.Name         LIKE '%' + @IPVC_PropertyName + '%'  
  AND   @IncludeProperties = 1   
  GROUP BY C.IDSeq,P.IDSeq,P.StatusTypeCode
) A  
  
   
 UPDATE T  
 SET     T.RelatedCompanyInterfaceName =  ISys.Name,  
  T.RelatedCompanyAccountID     =  ISD.InterfacedSystemID  
 FROM #LT_GetCustomerDetailByAddress T with (nolock)  
 Inner join  
      Customers.dbo.InterfacedSystemIdentifier ISD WITH (NOLOCK)    
 on    ISD.CompanyIDSeq = T.CustomerID   
 AND   ISD.RecordType = 'AHOFF'    
 AND   ISD.PropertyIDSeq IS NULL   
 and   ISD.CompanyIDSeq = ISNULL(@IPVC_CompanyID,ISD.CompanyIDSeq)  
 Inner join Customers.dbo.InterfacedSystem ISys WITH (NOLOCK)    
 ON    ISD.InterfacedSystemCode = ISys.Code    
 Inner join Customers.dbo.InterfacedSystemIDType IST WITH (NOLOCK)    
 ON    ISD.InterfacedSystemIDTypeCode = IST.Code  
  
 UPDATE T  
 SET     T.RelatedCompanyInterfaceName =  ISys.Name,  
  T.RelatedCompanyAccountID     =  ISD.InterfacedSystemID  
 FROM #LT_GetCustomerDetailByAddress T with (nolock)  
 Inner join  
      Customers.dbo.InterfacedSystemIdentifier ISD WITH (NOLOCK)    
 on    ISD.CompanyIDSeq = T.CustomerID   
 and   ISD.PropertyIDSeq= T.PropertyIDSeq  
 AND   ISD.RecordType = 'APROP'    
 AND   ISD.PropertyIDSeq IS not null     
 and   ISD.CompanyIDSeq = ISNULL(@IPVC_CompanyID,ISD.CompanyIDSeq)  
 and   ISD.PropertyIDSeq= ISNULL(@IPVC_PropertyID,ISD.PropertyIDSeq)   
 AND  (@IncludeProperties = 1)  
 Inner join Customers.dbo.InterfacedSystem ISys WITH (NOLOCK)    
 ON    ISD.InterfacedSystemCode = ISys.Code    
 Inner join Customers.dbo.InterfacedSystemIDType IST WITH (NOLOCK)    
 ON    ISD.InterfacedSystemIDTypeCode = IST.Code  
   
 ------------------------------------------------------------------------------  
 --Final Select  
 ------------------------------------------------------------------------------  
 SELECT CustomerID [Customer ID], CustomerName [PMC Name], PropertyIDSeq [Property ID], 
 PropertyName [Property Name], Units, Beds, PPU, [Invoice Delivery Rule], BillingEmail [Billing Email],
 BillingAddressLine1 [Billing Street Address Line 1], BillingAddressLine2 [Billing Street Address Line 2], 
 Billingcity [Billing City], Billingstate [Billing State], Billingzip [Billing Zip], 
 Billingcountrycode [Billing Country], [Billing Contact Name], [Delivery Option], [Rule Type]  
 FROM #LT_GetCustomerDetailByAddress   
 WHERE (@IPVC_RelProAccountID = '' or (@IPVC_RelProAccountID <> '' and   RelatedPropertyAccountID like '%' + @IPVC_RelProAccountID + '%'))        
 AND   (@IPVC_RelComAccountID = '' or (@IPVC_RelComAccountID <> '' and   RelatedCompanyAccountID  like '%' + @IPVC_RelComAccountID + '%'))          
 ORDER BY CustomerID DESC   
 ------------------------------------------------------------------------------  
 if (object_id('tempdb.dbo.#LT_GetCustomerDetailByAddress') is not null)   
 begin  
   drop table #LT_GetCustomerDetailByAddress  
 end   
 ------------------------------------------------------------------------------  
END  
GO
