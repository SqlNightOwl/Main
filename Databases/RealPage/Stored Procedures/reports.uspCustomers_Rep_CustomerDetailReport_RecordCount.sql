SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------      
-- Database  Name  : CUSTOMERS      
-- Procedure Name  : [uspCustomers_Rep_CustomerDetailReport_RecordCount]      
-- Description     : This procedure gets Record Count for the report "Customer Detail Report"
-- Input Parameters: All Input Parameters are Optional
-- Code Example    : exec [dbo].[uspCustomers_Rep_CustomerDetailReport_RecordCount]    
--													@IPVC_CompanyID    = 'C0812000008',
--													@IPVC_CustomerName = '',
--													@IPVC_AccountID    = '',
--													@IPVC_AccountName  = '',
--				
-- Revision History:      
-- Author          : Mahaboob Mohammad      
------------------------------------------------------------------------------------------------------      
CREATE PROCEDURE [reports].[uspCustomers_Rep_CustomerDetailReport_RecordCount]      
(      
 @IPVC_CompanyID     VARCHAR(50)  = '',  
 @IPVC_CustomerName  VARCHAR(100) = '',  
 @IPVC_AccountID     VARCHAR(50)  = '',  
 @IPVC_AccountName   VARCHAR(100) = '',
 @IPVC_RelComAccountID varchar(50) = '',
 @IPVC_RelProAccountID varchar(50) = ''    
)        
AS        
BEGIN           
SET NOCOUNT ON     
 --------------------------------------------------------------------------  
  SET @IPVC_CompanyID     = NULLIF(@IPVC_CompanyID,'')  
  SET @IPVC_AccountID     = NULLIF(@IPVC_AccountID,'')  
  SET @IPVC_AccountName   = @IPVC_AccountName  
    
--------------------------------------------------------------------------  
Select C.IDSeq                                                                            AS CustomerID,  
       MAX(C.Name)                                                                        AS CustomerName,  
       A.IDSeq                                                                            AS AccountID,  
       MAX(COALESCE(PROP.Name,C.Name))                                                    AS AccountName,  
       MAX(COALESCE(AD.AddressLine1,''))                                                  AS AccountAddress,  
       MAX(COALESCE(AD.city,''))                                                          AS Accountcity,  
       MAX(COALESCE(AD.[state],''))                                                       AS Accountstate,  
	   UPPER(MAX(COALESCE(AD.[country],'')))                                              AS Country, 
       MAX(COALESCE(AD.zip,''))                                                           AS Accountzip,  
       MAX(COALESCE(AD.PhoneVoice1,AD.PhoneVoice2,''))                                    AS AccountPhone,  
       (CASE WHEN(A.ActiveFlag = 1) THEN 'Active'  
        ELSE 'InActive'  
       END)																				  AS AccountStatus,
       MAX(Prop.IDSeq)																	  AS PropertyID	
INTO  #CustomerDetailReport							
FROM  CUSTOMERS.dbo.Company  C WITH (NOLOCK)  
INNER JOIN  
      CUSTOMERS.dbo.ACCOUNT  A WITH (NOLOCK)  
ON    A.CompanyIDSeq = C.IDSeq  
AND   A.ActiveFlag = 1  
--and   C.Statustypecode = 'ACTIV'  
LEFT OUTER JOIN  
      CUSTOMERS.dbo.Property Prop WITH (NOLOCK)  
ON    A.PropertyIDSeq = Prop.IDSeq  
AND   A.ActiveFlag = 1  
AND   Prop.StatusTypeCode = 'ACTIV'  
INNER JOIN  
      CUSTOMERS.dbo.Address AD WITH (NOLOCK)  
ON    AD.CompanyIDSeq = A.CompanyIDSeq  
AND   AD.CompanyIDSeq = ISNULL(@IPVC_CompanyID,AD.CompanyIDSeq)  
AND   COALESCE(A.propertyidseq,'') = ISNULL(AD.propertyidseq,'')  
AND   AD.AddressTypeCode           = (CASE A.AccountTypeCode WHEN 'APROP' Then 'PRO' ELSE 'COM' END)  
WHERE   
     (Prop.name LIKE '%'+ @IPVC_AccountName +'%' OR C.[name] LIKE '%'+ @IPVC_AccountName +'%')  
AND   C.IDSeq = ISNULL(@IPVC_CompanyID,C.IDSeq)  
AND   A.IDSeq = ISNULL(@IPVC_AccountID,A.IDSeq)  
AND   (C.name LIKE '%'+ @IPVC_CustomerName +'%')  
GROUP BY C.IDSeq,A.IDSeq, A.ActiveFlag  

 ALTER TABLE #CustomerDetailReport ADD OrderSynchStartMonth INT
 ALTER TABLE #CustomerDetailReport ADD RelatedCompanyInterfaceName VARCHAR(50)
 ALTER TABLE #CustomerDetailReport ADD RelatedCompanyAccountID VARCHAR(50)
 ALTER TABLE #CustomerDetailReport ADD RelatedPropertyInterfaceName VARCHAR(50)
 ALTER TABLE #CustomerDetailReport ADD RelatedPropertyAccountID VARCHAR(50)

UPDATE T
 SET T.OrderSynchStartMonth = C.OrderSynchStartMonth,
	 RelatedCompanyInterfaceName = ISys.Name,
	 RelatedCompanyAccountID =  ISD.InterfacedSystemID
 FROM #CustomerDetailReport T
 LEFT OUTER JOIN Customers.dbo.Company C WITH (NOLOCK)
    ON c.IDSeq = T.CustomerID
 LEFT OUTER JOIN Customers.dbo.InterfacedSystemIdentifier ISD WITH (NOLOCK)  
    ON    C.IDSeq = ISD.CompanyIDSeq  
    AND   ISD.RecordType = 'AHOFF'  
    AND   ISD.PropertyIDSeq IS NULL 
 LEFT OUTER JOIN Customers.dbo.InterfacedSystem ISys WITH (NOLOCK)  
    ON    ISD.InterfacedSystemCode = ISys.Code  
 LEFT OUTER JOIN Customers.dbo.InterfacedSystemIDType IST WITH (NOLOCK)  
    ON    ISD.InterfacedSystemIDTypeCode = IST.Code 
 
  UPDATE T
 SET RelatedPropertyInterfaceName = ISys.Name,
	 RelatedPropertyAccountID =  ISD.InterfacedSystemID
 FROM #CustomerDetailReport T
 LEFT OUTER JOIN  
           InterfacedSystemIdentifier ISD WITH (NOLOCK)  
    ON     T.PropertyID    = ISD.PropertyIDSeq  
    AND    T.CustomerID = ISD.CompanyIDSeq  
    AND   ISD.RecordType = 'APROP'  
    AND   ISD.PropertyIDSeq is not null  
 LEFT OUTER JOIN  
		  InterfacedSystem ISys WITH (NOLOCK)  
    ON    ISD.InterfacedSystemCode = ISys.Code  
  LEFT OUTER JOIN  
          InterfacedSystemIDType IST WITH (NOLOCK)  
    ON    ISD.InterfacedSystemIDTypeCode = IST.Code
    
SELECT COUNT(1) 'Record Count'
FROM  #CustomerDetailReport
WHERE (@IPVC_RelProAccountID = '' OR (@IPVC_RelProAccountID <> '' AND RelatedPropertyAccountID LIKE '%' + @IPVC_RelProAccountID + '%'))      
	 AND (@IPVC_RelComAccountID = '' OR (@IPVC_RelComAccountID <> '' AND   RelatedCompanyAccountID LIKE '%' + @IPVC_RelComAccountID + '%'))        
      
DROP TABLE #CustomerDetailReport

END  
GO
