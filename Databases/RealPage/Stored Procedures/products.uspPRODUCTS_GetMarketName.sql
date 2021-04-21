SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-----------------------------------------------------------------------------------------------  
-- purpose    : Get Market Values  
--              This proc will return MarketName by Market Code.  
  
-- Syntax     : EXEC dbo.[uspPRODUCTS_GetMarketName]  'RAFF'
 
-- Date         Author                  Comments  
-- -----------  -------------------     ---------------------------  
-- 01/05/2011   DNETHUNURI              Initial Creation.  
-----------------------------------------------------------------------------------------------  

CREATE PROCEDURE [products].[uspPRODUCTS_GetMarketName] 
						@IPVC_MarketCode VARCHAR(4)
AS  
BEGIN  
  SET NOCOUNT ON;  
 
          SELECT  
                  MAX(COALESCE(MKT.ShortName,FM.Name,PT.Name))       AS MarketName  
                 
                  FROM Products.dbo.Producttype PT WITH (NOLOCK)  
                  INNER JOIN  
                       Products.dbo.Product P WITH (NOLOCK)  
                  ON   P.ProducttypeCode = PT.Code  
                  INNER JOIN  
                       Products.dbo.Charge C WITH (NOLOCK)  
                  ON   P.Code = C.ProductCode  
                  AND  P.Priceversion = C.Priceversion  
                  AND  C.ReportingTypeCode = 'ACSF'                   
                  INNER JOIN  
                       Products.dbo.Family FM WITH (NOLOCK)  
                  ON   P.FamilyCode = FM.Code  
                  LEFT OUTER JOIN  
                       Products.dbo.Market MKT WITH (NOLOCK)  
                  ON   PT.MarketCode = MKT.Code  
				WHERE  COALESCE(MKT.Code,FM.Code,PT.Code) =  @IPVC_MarketCode              
                  GROUP BY COALESCE(MKT.Code,FM.Code,PT.Code)  
       
END
GO
