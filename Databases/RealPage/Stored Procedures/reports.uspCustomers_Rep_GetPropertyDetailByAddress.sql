SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : CUSTOMERS      
-- Procedure Name  : [uspCustomers_Rep_GetPropertyDetailByAddress]      
-- Description     : This procedure gets Details based on Customer.
-- Input Parameters: All Input Parameters are Optional
-- Code Example    : exec [dbo].[uspCustomers_Rep_GetPropertyDetailByAddress]    
--													@IPVC_CompanyID    = 'C0812000008',
--													@IPVC_CustomerName = '',
--				
-- Revision History:      
-- Author          : Anand Chakravarthy      
-- 06/24/2010      : Stored Procedure Created.
-- 12/31/2010	   : Surya Kiran Defect # 8661 - Darla has put in a report request to know what PMC's have a synch turned on and what date they synch
-- 12/31/2010	   : Surya Kiran Defect # 8662 - OMS Reports needs to include the Related Company System ID
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspCustomers_Rep_GetPropertyDetailByAddress]      
(      
 @IPVC_CompanyID     varchar(50)  = '',
 @IPVC_PropertyID     varchar(50)  = '',
 @IPVC_PropertyName   varchar(100) = '',
 @IPVC_RelComAccountID varchar(50) = '',
 @IPVC_RelProAccountID varchar(50) = ''  
)      
AS      
BEGIN         
SET NOCOUNT ON   
 --------------------------------------------------------------------------
  SET @IPVC_CompanyID     = NULLIF(@IPVC_CompanyID,'')
  SET @IPVC_PropertyID    = NULLIF(@IPVC_PropertyID,'')  
--------------------------------------------------------------------------
  Select
       C.IDSeq                                                                            AS CustomerID,
       P.IDSeq										  AS PropertyID,
       MAX(P.Name)									  AS PropertyName,
       MAX(P.SiteMasterID) 							          AS SiteMasterID,
       MAX(COALESCE(aCOM.PhoneVoice1,''))			                          AS PhoneVoice1,
       MAX(COALESCE(aCOM.PhoneFax,''))				                          AS Fax,
       MAX(COALESCE(aCOM.Email,''))				                          AS Email,
       MAX(CBPT.[Description])                                                            AS CustomBundlesProductBreakDownTypeCode,
       (CASE WHEN MAX(convert(int,P.SeparateInvoiceByFamilyFlag)) = 1 THEN 'Yes'
	   ELSE 'No'															                      
	   END)										  AS SeparateInvoiceByFamilyFlag,
       MAX(COALESCE(aCOM.AddressLine1,''))                                                AS AddressLine1,
       MAX(COALESCE(aCOM.AddressLine2,''))                                                AS AddressLine2,
       MAX(COALESCE(aCOM.city,''))                                                        AS City,
       MAX(COALESCE(aCOM.[state],''))                                                     AS [State],
       MAX(COALESCE(aCOM.zip,''))                                                         AS Zip,
       MAX(COALESCE(aCOM.CountryCode,''))                                                 AS CountryCode,
       MAX(COALESCE(aCBT.AttentionName,''))                                               AS AttentionName,
       MAX(COALESCE(aCBT.Email,''))					                  AS BillingEmail,
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
       P.IDSeq										  AS PropertyIDSeq,
       MAX(P.SiteMasterID) 							          AS PropertySiteMasterID,
       MAX(P.Units)									  AS Units,
       MAX(P.Beds)									  AS Beds,
       MAX(P.Phase)									  AS Phase,					
       MAX(P.PPUPercentage)								  AS PPU,
       MAX(P.OwnerName)									  AS [Owner],
       MAX(C.OrderSynchStartMonth)   						          AS OrderSynchStartMonth,
       convert(varchar(100),'')                                                           as RelatedCompanyInterfaceName,
       convert(varchar(100),'')                                                           as RelatedCompanyAccountID,
       convert(varchar(100),'')                                                           as RelatedPropertyInterfaceName,
       convert(varchar(100),'')                                                           as RelatedPropertyAccountID 
  into #LT_GetCustomerDetailByAddress
  FROM Customers.dbo.Property P WITH (NOLOCK)
  INNER JOIN Customers.dbo.Company C WITH (NOLOCK)
	    ON  P.PMCIDSeq = C.IDSeq
            AND  C.IDSeq = isnull(@IPVC_CompanyID,C.IDSeq)
            AND   P.IDSeq       = ISNULL(@IPVC_PropertyID,P.IDSeq)
  INNER JOIN Customers.dbo.Address aCOM WITH (NOLOCK)
		ON  P.PMCIDSeq = aCOM.CompanyIDSeq
                AND P.IDSeq = aCOM.PropertyIDSeq
		AND aCOM.AddressTypeCode = 'PRO' 
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
  WHERE C.IDSeq = ISNULL(@IPVC_CompanyID,C.IDSeq)  
  AND   P.IDSeq = ISNULL(@IPVC_PropertyID,P.IDSeq)
  AND   P.Name  LIKE '%' + @IPVC_PropertyName + '%'
  GROUP BY C.IDSeq,P.IDSeq


 
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
 Inner join Customers.dbo.InterfacedSystem ISys WITH (NOLOCK)  
 ON    ISD.InterfacedSystemCode = ISys.Code  
 Inner join Customers.dbo.InterfacedSystemIDType IST WITH (NOLOCK)  
 ON    ISD.InterfacedSystemIDTypeCode = IST.Code
 
 ------------------------------------------------------------------------------
 --Final Select
 ------------------------------------------------------------------------------
 SELECT *
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
