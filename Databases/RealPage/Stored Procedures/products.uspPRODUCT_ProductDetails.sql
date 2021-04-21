SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCT_ProductDetails
-- Description     : This procedure gets the Product Details
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec PRODUCTS.DBO.uspPRODUCT_ProductDetails  Passing Input Parameters
-- Revision History:
-- Author          : Mahaboob Mohammad
-- 2011-06-15      : Defect #319
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCT_ProductDetails]
(										    @IPC_ProductCode	CHAR(30),        
                                            @IPN_PriceVersion	NUMERIC(18,0)        
                                                    )             
AS        
BEGIN        
        
  SELECT         
      P.Code                                 AS ProductCode,        
      P.PriceVersion                         AS PriceVersion,        
      P.[Name]                               AS ProductName,   
	  P.PlatformCode							 AS PlatformCode,  
	  P.ProductTypeCode						AS ProductTypeCode,  
	  P.FamilyCode								AS FamilyCode,  
	  P.CategoryCode							AS CategoryCode,        
      P.ItemCode                             AS Itemcode,        
      P.DisplayName                          AS DisplayName,        
      P.Description                          AS [Description],        
      P.OptionFlag                           AS OptionFlag,        
      P.SOCFlag                              AS SOCFlag,     
	  p.StockBundleFlag       AS StockBundleFlag ,       
	  P.PriceCapEnabledFlag      AS PriceCapEnabledFlag,      
      P.ExcludeForBookingsFlag     AS ExcludeForBookingsFlag,      
      P.RegAdminProductFlag      AS RegAdminProductFlag,      
      P.MPFPublicationFlag      AS MPFPublicationFlag,      
		P.StockBundleIdentifierCode     AS StockBundleIdentifierCode,       
      P.DisabledFlag                         AS DisabledFlag,        
      convert(VARCHAR (15),P.StartDate,101)  AS StartDate,        
      convert(VARCHAR (15),P.EndDate,101)    AS EndDate,        
      P.CreatedBy                            AS CreatedBy,        
      P.ModifiedBy                           AS ModifiedBy,    
   isnull(P.LegacyProductCode ,'N/A')   AS LegacyProductCode,    
      convert(VARCHAR (15),P.CreateDate,101) AS CreatedDate,        
      convert(VARCHAR (15),P.ModifyDate,101) AS ModifyDate,        
      P.PendingApprovalFlag                  AS PendingApprovalFlag,    
      C.[Name]                               AS Category,        
      F.[Name]                               AS Family,        
      PF.[Name]                              AS PlatformType,              
      PT.[Name]                              AS ProductType,         
      P.AutoFulfillFlag                      AS AutoFulFillFlag,  
      row_number() OVER(ORDER BY P.[Name])   AS RowNumber, 
      (SELECT Count(*) FROM CHARGE WHERE ProductCode = @IPC_ProductCode and PriceVersion=@IPN_PriceVersion ) AS ChargeCount,
      (SELECT Count(*) FROM Product WHERE Code= @IPC_ProductCode and PendingApprovalFlag=1 and DisabledFlag=1 and PriceVersion > @IPN_PriceVersion) AS ReviseStatus,
      (SELECT Count(*) FROM StockProductLookUp WHERE stockproductcode = @IPC_ProductCode and stockproductpriceversion =@IPN_PriceVersion) AS StockAssociatedCount,    
      (SELECT Count(1) FROM Product PD WHERE PD.Code = @IPC_ProductCode and PendingApprovalFlag = 1 and DisabledFlag = 1 ) AS PendingApprovalCount,
      (SELECT Max(PriceVersion) FROM Product WHERE Code= @IPC_ProductCode ) AS ActivePriceVersion
             
    FROM Products.dbo.Product P with (nolock)        
        
    INNER JOIN Products.dbo.Family F with (nolock)        
      ON  P.FamilyCode = F.Code        
     -- and P.DisabledFlag = 0        
    INNER JOIN Products.dbo.ProductType PT with (nolock)        
      ON P.ProductTypeCode = PT.Code        
        
    INNER JOIN Products.dbo.Category C with (nolock)        
      ON P.CategoryCode = C.Code        
        
 INNER JOIN Products.dbo.[Platform] PF with (nolock)        
      ON P.PlatformCode = PF.Code        
        
WHERE P.Code = @IPC_ProductCode and P.PriceVersion=@IPN_PriceVersion        
        
END        			 
GO
