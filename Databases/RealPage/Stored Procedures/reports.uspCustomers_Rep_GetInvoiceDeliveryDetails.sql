SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : CUSTOMERS      
-- Procedure Name  : [uspCustomers_Rep_GetInvoiceDeliveryDetails]      
-- Description     : This procedure gets Details based on Customer.
-- Input Parameters: All Input Parameters are Optional
-- Code Example    : exec [dbo].[uspCustomers_Rep_GetInvoiceDeliveryDetails]    
--													@IPVC_CompanyID    = 'C1106019160',
--													@IPVC_CustomerName = '',
--													@IPVC_StartDate    = '',
--													@IPVC_EndDate	   = ''
--				
-- Revision History:      
-- Author          : Naval Kishore      
-- 08/30/2011      : Stored Procedure Created.
-- 09/30/2011      : Mahaboob -- Defect #312 -- Modified the procedure as per new changes suggested by Cheryl.
-- 10/12/2011      : Mahaboob -- Defect #312 -- Modified the procedure as per new changes suggested by Jason.
-- 10/13/2011      : Mahaboob -- Defect #312 -- Modified the procedure as per new changes suggested by Arjuna.
------------------------------------------------------------------------------------------------------         
CREATE PROCEDURE [reports].[uspCustomers_Rep_GetInvoiceDeliveryDetails]        
(        
 @IPVC_CompanyID       VARCHAR(50)  = '',  
 @IPVC_CustomerName    VARCHAR(100) = '',  
 @IPVC_StartDate      DATETIME  = '',  
 @IPVC_EndDate     DATETIME = ''  
 )        
AS        
BEGIN             
SET NOCOUNT ON       
 --------------------------------------------------------------------------    
  SET @IPVC_CompanyID     = NULLIF(@IPVC_CompanyID,'')    
--  SET @IPVC_PropertyID    = NULLIF(@IPVC_PropertyID,'')    
--------------------------------------------------------------------------    
DECLARE @RuleName varchar(255), @DeliveryOption varchar(70), @Products varchar(50), @Category varchar(30), @Family varchar(30), @IsDefaultRuleExists bit   
SELECT  @RuleName = '', @DeliveryOption = 'Print and Mail', @Products = 'All', @Category = 'All', @Family = 'All',  @IsDefaultRuleExists = 0 

SELECT A.*    
INTO #LT_GetCustomerInvoiceDeliveryDetails      
FROM    
(    
 SELECT C.IDSeq                     AS CustomerID,    
       MAX(C.Name)                                                                        AS CustomerName,    
       MAX(C.SiteMasterID)                                                                AS SiteMasterID,    
       MAX(COALESCE(aCOM.PhoneVoice1,''))              AS PhoneVoice1,    
       MAX(COALESCE(aCOM.PhoneFax,''))                     AS Fax,    
       MAX(COALESCE(aCOM.Email,''))                AS Email,    
       MAX(COALESCE(aCOM.AddressLine1,''))                                                AS AddressLine1,    
       MAX(COALESCE(aCOM.AddressLine2,''))                                                AS AddressLine2,    
       MAX(COALESCE(aCOM.city,''))                                                        AS City,    
       MAX(COALESCE(aCOM.[state],''))                                                     AS [State],    
       MAX(COALESCE(aCOM.zip,''))                                                         AS Zip,    
       MAX(COALESCE(aCOM.CountryCode,''))                                                 AS CountryCode,    
       MAX(COALESCE(aCBT.AttentionName,''))                                               AS AttentionName,    
       MAX(COALESCE(aCBT.Email,''))                AS BillingEmail,    
       MAX(COALESCE(aCBT.AddressLine1,''))                                                AS BillingAddressLine1,    
       MAX(COALESCE(aCBT.AddressLine2,''))                                                AS BillingAddressLine2,    
       MAX(COALESCE(aCBT.city,''))                                                        AS Billingcity,    
       MAX(COALESCE(aCBT.[state],''))                                                     AS Billingstate,    
       MAX(COALESCE(aCBT.zip,''))                   AS Billingzip,    
       MAX(COALESCE(aCBT.CountryCode,''))                                                 AS Billingcountrycode,    
       MAX(COALESCE(aCST.AddressLine1,''))                                                AS ShippingAddressLine1,    
       MAX(COALESCE(aCST.AddressLine2,''))                                                AS ShippingAddressLine2,    
       MAX(COALESCE(aCST.city,''))                                                        AS Shippingcity,    
       MAX(COALESCE(aCST.[state],''))                                                     AS Shippingstate,    
       MAX(COALESCE(aCST.zip,''))                                                         AS Shippingzip,    
       MAX(COALESCE(aCST.CountryCode,''))                                                 AS Shippingcountrycode,    
       ''                      AS PropertyIDSeq,    
       ''                         AS PropertyName,    
       ''                         AS PropertySiteMasterID,    
   (Case when C.StatusTypeCode ='ACTIV' Then 'Active' else 'Inactive' end)     AS Status,        
       (select isnull(Sum(units),'0') from Property Prop inner join company comp on Prop.PMCIDSeq=comp.Idseq where prop.pmcidseq=isnull(@IPVC_CompanyID,C.IDSeq))   as Units,  
       ''                      AS Beds,    
       ''                      AS Phase,         
       ''                         AS PPU,    
       ''                         AS [Owner],  
    MAX(COALESCE(IDER.RuleDescription, IDER.RuleName, @RuleName))                AS RuleIDSeq,    
       MAX(COALESCE(DO.Name,@DeliveryOption))             AS DeliveryOptionCode,    
       
        MAX(COALESCE(Pr.DisplayName, @Products)) AS ApplyToProductCode, 
        MAX(COALESCE(Cr.Name, @Category))  AS ApplyToCategoryCode,
        MAX(COALESCE(Fm.Name, @Family)) AS ApplyToFamilyCode,
        IDER.RuleIDSeq as RuleSeq

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
 LEFT OUTER JOIN Customers.dbo.InvoiceDeliveryExceptionRuleDetail IDERD WITH (NOLOCK)    
 on IDERD.CompanyIDSeq = C.IDSeq  and ( IDERD.ApplyToOMSIDSeq is null or   IDERD.ApplyToOMSIDSeq = C.IDSeq ) 
 and   CONVERT(VARCHAR, IDERD.CreatedDate, 101) >= isnull( nullif(@IPVC_StartDate,'') ,CONVERT(VARCHAR, IDERD.CreatedDate, 101))      
 and   CONVERT(VARCHAR, IDERD.CreatedDate, 101) <= isnull( nullif(@IPVC_EndDate,'') ,CONVERT(VARCHAR, IDERD.CreatedDate, 101))         
 LEFT OUTER JOIN  Customers.dbo.InvoiceDeliveryExceptionRule IDER WITH (NOLOCK)    
    ON IDER.RuleIDSeq = IDERD.RuleIDSeq and IDER.CompanyIDSeq = IDERD.CompanyIDSeq      
 LEFT OUTER JOIN Products.dbo.product Pr WITH (NOLOCK)    
  ON IDERD.ApplyToProductCode = Pr.Code    
 LEFT OUTER JOIN Products.dbo.Category Cr WITH (NOLOCK)    
  ON IDERD.ApplyToCategoryCode = Cr.Code    
 LEFT OUTER JOIN Products.dbo.Family Fm WITH (NOLOCK)    
  ON IDERD.ApplyToFamilyCode = Fm.Code   
 LEFT OUTER JOIN Customers.dbo.DeliveryOption DO   
  ON IDERD.DeliveryOptionCode = DO.Code  
   
WHERE C.IDSeq =  isnull(@IPVC_CompanyID, C.IDSeq)    
and   C.Name         LIKE '%' + @IPVC_CustomerName + '%'      

      
GROUP BY C.IDSeq,C.StatusTypeCode,  IDER.RuleDescription, DeliveryOptionCode, ApplyToProductCode, ApplyToCategoryCode,  ApplyToFamilyCode, IDER.RuleIDSeq        
    
      
----------------------------------------------------------    
  UNION ALL    
----------------------------------------------------------    
Select C.IDSeq                                                                            AS CustomerID,    
       MAX(C.Name)                                                                        AS CustomerName,    
       MAX(C.SiteMasterID)                                                                AS SiteMasterID,    
       MAX(COALESCE(aCOM.PhoneVoice1,''))              AS PhoneVoice1,    
       MAX(COALESCE(aCOM.PhoneFax,''))               AS Fax,    
       MAX(COALESCE(aCOM.Email,''))                   AS Email,    
       MAX(COALESCE(aCOM.AddressLine1,''))                                                AS AddressLine1,    
       MAX(COALESCE(aCOM.AddressLine2,''))                                                AS AddressLine2,    
       MAX(COALESCE(aCOM.city,''))                                                        AS City,    
       MAX(COALESCE(aCOM.[state],''))                                                     AS [State],    
       MAX(COALESCE(aCOM.zip,''))                                                         AS Zip,    
       MAX(COALESCE(aCOM.CountryCode,''))                                                 AS CountryCode,    
       MAX(COALESCE(aCBT.AttentionName,''))                                               AS AttentionName,    
       MAX(COALESCE(aCBT.Email,''))                AS BillingEmail,    
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
       P.IDSeq                     AS PropertyIDSeq,    
       MAX(P.Name)                       AS PropertyName,    
       MAX(P.SiteMasterID)                     AS PropertySiteMasterID,    
    (Case when P.StatusTypeCode ='ACTIV' then 'Active' else 'Inactive' end)     AS Status,    
       MAX(P.Units)                    AS Units,   
     
       MAX(P.Beds)                       AS Beds,    
       MAX(P.Phase)                    AS Phase,         
       MAX(P.PPUPercentage)                  AS PPU,    
       MAX(P.OwnerName)                   AS [Owner],  
    MAX(COALESCE(IDER.RuleDescription, IDER.RuleName, @RuleName))                AS RuleIDSeq,    
     MAX(COALESCE(DO.Name,@DeliveryOption))             AS DeliveryOptionCode, 

        MAX(COALESCE(Pr.DisplayName, @Products)) AS ApplyToProductCode, 
        MAX(COALESCE(Cr.Name, @Category))  AS ApplyToCategoryCode,
        MAX(COALESCE(Fm.Name, @Family)) AS ApplyToFamilyCode,
        IDER.RuleIDSeq as RuleSeq         
  FROM Customers.dbo.Property P WITH (NOLOCK)      
  INNER JOIN Customers.dbo.Company C WITH (NOLOCK)      
     ON  P.PMCIDSeq = C.IDSeq  
  AND (
  EXISTS(SELECT TOP 1 1 FROM Customers.dbo.InvoiceDeliveryExceptionRuleDetail T1 WHERE T1.CompanyIDSeq = C.IDSeq and T1.ApplyToOMSIDSeq is null)   
   )

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
 LEFT OUTER JOIN Customers.dbo.InvoiceDeliveryExceptionRuleDetail IDERD WITH (NOLOCK)    
 on IDERD.CompanyIDSeq = C.IDSeq  and IDERD.ApplyToOMSIDSeq is null   
 
 and   CONVERT(VARCHAR, IDERD.CreatedDate, 101) >= isnull( nullif(@IPVC_StartDate,'') ,CONVERT(VARCHAR, IDERD.CreatedDate, 101))      
 and   CONVERT(VARCHAR, IDERD.CreatedDate, 101) <= isnull( nullif(@IPVC_EndDate,'') ,CONVERT(VARCHAR, IDERD.CreatedDate, 101))     
   
 LEFT OUTER JOIN  Customers.dbo.InvoiceDeliveryExceptionRule IDER WITH (NOLOCK)    
    ON IDER.RuleIDSeq = IDERD.RuleIDSeq and IDER.CompanyIDSeq = IDERD.CompanyIDSeq    
       
 LEFT OUTER JOIN Products.dbo.product Pr WITH (NOLOCK)    
  ON IDERD.ApplyToProductCode = Pr.Code    
 LEFT OUTER JOIN Products.dbo.Category Cr WITH (NOLOCK)    
  ON IDERD.ApplyToCategoryCode = Cr.Code    
 LEFT OUTER JOIN Products.dbo.Family Fm WITH (NOLOCK)    
  ON IDERD.ApplyToFamilyCode = Fm.Code    
 LEFT OUTER JOIN Customers.dbo.DeliveryOption DO   
  ON IDERD.DeliveryOptionCode = DO.Code  
WHERE C.IDSeq =  isnull(@IPVC_CompanyID, C.IDSeq)    
and   C.Name         LIKE '%' + @IPVC_CustomerName + '%'     
GROUP BY C.IDSeq,P.IDSeq,P.StatusTypeCode, IDER.RuleDescription, DeliveryOptionCode, ApplyToProductCode, ApplyToCategoryCode,  ApplyToFamilyCode, IDER.RuleIDSeq     
----------------------------------------------------------    
  UNION ALL    
----------------------------------------------------------    
Select C.IDSeq                                                                            AS CustomerID,    
       MAX(C.Name)                                                                        AS CustomerName,    
       MAX(C.SiteMasterID)                                                                AS SiteMasterID,    
       MAX(COALESCE(aCOM.PhoneVoice1,''))              AS PhoneVoice1,    
       MAX(COALESCE(aCOM.PhoneFax,''))               AS Fax,    
       MAX(COALESCE(aCOM.Email,''))                   AS Email,    
       MAX(COALESCE(aCOM.AddressLine1,''))                                                AS AddressLine1,    
       MAX(COALESCE(aCOM.AddressLine2,''))                                                AS AddressLine2,    
       MAX(COALESCE(aCOM.city,''))                                                        AS City,    
       MAX(COALESCE(aCOM.[state],''))                                                     AS [State],    
       MAX(COALESCE(aCOM.zip,''))                                                         AS Zip,    
       MAX(COALESCE(aCOM.CountryCode,''))                                                 AS CountryCode,    
       MAX(COALESCE(aCBT.AttentionName,''))                                               AS AttentionName,    
       MAX(COALESCE(aCBT.Email,''))                AS BillingEmail,    
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
       P.IDSeq                     AS PropertyIDSeq,    
       MAX(P.Name)                       AS PropertyName,    
       MAX(P.SiteMasterID)                     AS PropertySiteMasterID,    
    (Case when P.StatusTypeCode ='ACTIV' then 'Active' else 'Inactive' end)     AS Status,    
       MAX(P.Units)                    AS Units,   
     
       MAX(P.Beds)                       AS Beds,    
       MAX(P.Phase)                    AS Phase,         
       MAX(P.PPUPercentage)                  AS PPU,    
       MAX(P.OwnerName)                   AS [Owner],  
    MAX(COALESCE(IDER.RuleDescription, IDER.RuleName, @RuleName))                AS RuleIDSeq,    
     MAX(COALESCE(DO.Name,@DeliveryOption))             AS DeliveryOptionCode, 

        MAX(COALESCE(Pr.DisplayName, @Products)) AS ApplyToProductCode, 
        MAX(COALESCE(Cr.Name, @Category))  AS ApplyToCategoryCode,
        MAX(COALESCE(Fm.Name, @Family)) AS ApplyToFamilyCode,
        IDER.RuleIDSeq as RuleSeq          
  FROM Customers.dbo.Property P WITH (NOLOCK)      
  INNER JOIN Customers.dbo.Company C WITH (NOLOCK)      
     ON  P.PMCIDSeq = C.IDSeq      
  
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
 INNER JOIN Customers.dbo.InvoiceDeliveryExceptionRuleDetail IDERD WITH (NOLOCK)    
 on IDERD.CompanyIDSeq = C.IDSeq  and IDERD.ApplyToOMSIDSeq is not null   
 AND IDERD.ApplyToOMSIDSeq = P.IDSEQ     
 and   CONVERT(VARCHAR, IDERD.CreatedDate, 101) >= isnull( nullif(@IPVC_StartDate,'') ,CONVERT(VARCHAR, IDERD.CreatedDate, 101))      
 and   CONVERT(VARCHAR, IDERD.CreatedDate, 101) <= isnull( nullif(@IPVC_EndDate,'') ,CONVERT(VARCHAR, IDERD.CreatedDate, 101))     
   
 INNER JOIN  Customers.dbo.InvoiceDeliveryExceptionRule IDER WITH (NOLOCK)    
    ON IDER.RuleIDSeq = IDERD.RuleIDSeq and IDER.CompanyIDSeq = IDERD.CompanyIDSeq    
       
 LEFT OUTER JOIN Products.dbo.product Pr WITH (NOLOCK)    
  ON IDERD.ApplyToProductCode = Pr.Code    
 LEFT OUTER JOIN Products.dbo.Category Cr WITH (NOLOCK)    
  ON IDERD.ApplyToCategoryCode = Cr.Code    
 LEFT OUTER JOIN Products.dbo.Family Fm WITH (NOLOCK)    
  ON IDERD.ApplyToFamilyCode = Fm.Code    
 LEFT OUTER JOIN Customers.dbo.DeliveryOption DO   
  ON IDERD.DeliveryOptionCode = DO.Code  
WHERE C.IDSeq =  isnull(@IPVC_CompanyID, C.IDSeq)    
and   C.Name         LIKE '%' + @IPVC_CustomerName + '%'     
GROUP BY C.IDSeq,P.IDSeq,P.StatusTypeCode, IDER.RuleDescription, DeliveryOptionCode, ApplyToProductCode, ApplyToCategoryCode,  ApplyToFamilyCode, IDER.RuleIDSeq           
) A      
  
 ------------------------------------------------------------------------------    
 --Get Properties on which no Invoice Delivery Rules Defined.  
 ------------------------------------------------------------------------------    
 
 Select C.IDSeq                                                                            AS CustomerID,    
       MAX(C.Name)                                                                        AS CustomerName,    
       MAX(C.SiteMasterID)                                                                AS SiteMasterID,    
       MAX(COALESCE(aCOM.PhoneVoice1,''))              AS PhoneVoice1,    
       MAX(COALESCE(aCOM.PhoneFax,''))               AS Fax,    
       MAX(COALESCE(aCOM.Email,''))                   AS Email,    
       MAX(COALESCE(aCOM.AddressLine1,''))                                                AS AddressLine1,    
       MAX(COALESCE(aCOM.AddressLine2,''))                                                AS AddressLine2,    
       MAX(COALESCE(aCOM.city,''))                                                        AS City,    
       MAX(COALESCE(aCOM.[state],''))                                                     AS [State],    
       MAX(COALESCE(aCOM.zip,''))                                                         AS Zip,    
       MAX(COALESCE(aCOM.CountryCode,''))                                                 AS CountryCode,    
       MAX(COALESCE(aCBT.AttentionName,''))                                               AS AttentionName,    
       MAX(COALESCE(aCBT.Email,''))                AS BillingEmail,    
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
       P.IDSeq                     AS PropertyIDSeq,    
       MAX(P.Name)                       AS PropertyName,    
       MAX(P.SiteMasterID)                     AS PropertySiteMasterID,    
    (Case when P.StatusTypeCode ='ACTIV' then 'Active' else 'Inactive' end)     AS Status,    
       MAX(P.Units)                    AS Units,   
     
       MAX(P.Beds)                       AS Beds,    
       MAX(P.Phase)                    AS Phase,         
       MAX(P.PPUPercentage)                  AS PPU,    
       MAX(P.OwnerName)                   AS [Owner],  
       @RuleName                AS RuleIDSeq,    
       @DeliveryOption          AS DeliveryOptionCode, 
       @Products AS ApplyToProductCode, 
       @Category  AS ApplyToCategoryCode,
       @Family AS ApplyToFamilyCode,
       1 as RuleSeq  
INTO #LT_GetPropertiesWithNoInvoiceRules      
  FROM Customers.dbo.Property P WITH (NOLOCK)      
  INNER JOIN Customers.dbo.Company C WITH (NOLOCK)      
     ON  P.PMCIDSeq = C.IDSeq  
  
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

WHERE C.IDSeq =  isnull(@IPVC_CompanyID, C.IDSeq)    
and   C.Name         LIKE '%' + @IPVC_CustomerName + '%'     
GROUP BY C.IDSeq,P.IDSeq,P.StatusTypeCode

  
 ------------------------------------------------------------------------------    
 --Final Select    
 ------------------------------------------------------------------------------    
     
 SELECT C.*    
 FROM #LT_GetCustomerInvoiceDeliveryDetails C
 UNION ALL
 SELECT A.*    
 FROM #LT_GetPropertiesWithNoInvoiceRules A
 LEFT OUTER JOIN #LT_GetCustomerInvoiceDeliveryDetails B
 ON A.PropertyIDSeq = B.PropertyIDSeq 
 WHERE B.PropertyIDSeq is null
 ORDER BY CustomerID,  PropertyIDSeq, RuleSeq   
  
 ------------------------------------------------------------------------------    
 if (object_id('tempdb.dbo.#LT_GetCustomerInvoiceDeliveryDetails') is not null)     
 begin    
   drop table #LT_GetCustomerInvoiceDeliveryDetails   
 end  
 if (object_id('tempdb.dbo.#LT_GetPropertiesWithNoInvoiceRules') is not null)     
 begin    
   drop table #LT_GetPropertiesWithNoInvoiceRules   
 end        
 ------------------------------------------------------------------------------  
END  
GO
