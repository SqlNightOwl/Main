SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCT_ProductListCount
-- Description     : This procedure gets the count of the Products.
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec PRODUCTS.DBO.uspPRODUCTS_ProductListCount  Passing Input Parameters
-- Revision History:
-- Author          : Mahaboob Mohammad
-- 2011-06-15      : Defect #319
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ProductListCount]
									    (@IPVC_ProductName     as  varchar(255),  
										 @IPC_FamilyCode       as  char(3),  
                                         @IPI_ViewProducts     as  char(3),  
                                         @IPC_Category         as  char(3),  
                                         @IPC_Platform         as  char(3),  
										 @IPVC_DisplayName     as  varchar(255),  
                                         @IPC_ProductType      as  char(3),
										 @IPV_StatusFlag       as  varchar(10) 
                                        )  
AS  
BEGIN-->Main Begin  
  ----------------------------------------------------------------------------  
  --Final Select   
  ----------------------------------------------------------------------------  
 if( @IPV_StatusFlag=0 and @IPV_StatusFlag <>'') 
Begin
  WITH tablefinal AS   
       ----------------------------------------------------------    
       (SELECT count(tableinner.[ID])                as [Count]  
        FROM  
           ----------------------------------------------------------   
          (select  *  
           from  
             ----------------------------------------------------------  
            (  
              SELECT   
                P.Code                                 as [ID]                  
              FROM  Products.dbo.Product P with (nolock)  
              INNER JOIN   
                    Products.dbo.Family F with (nolock)  
              ON    P.FamilyCode = F.Code  
              AND   P.DisabledFlag = 0 
            -- AND   ((@IPVC_ProductName is not null and  P.[Name] like '%' + @IPVC_ProductName + '%') or @IPVC_ProductName     = '')  
              AND   ((@IPVC_DisplayName is not null and  P.[DisplayName] like '%' + @IPVC_DisplayName + '%') or @IPVC_DisplayName     = '')  
              AND   ((@IPC_FamilyCode   is not null and  P.FamilyCode =  @IPC_FamilyCode )    or @IPC_FamilyCode     = '')  
              AND   ((@IPI_ViewProducts is not null and  P.SOCFlag    = @IPI_ViewProducts )   or @IPI_ViewProducts   = '')  
              AND   exists (select top 1 1 from  
                            Products.dbo.Charge X with (nolock)  
                            where  P.Code         = X.productcode  
                            and    P.PriceVersion = X.PriceVersion  
                            and    P.DisabledFlag = X.DisabledFlag  
                            and    X.Displaytype  <> 'OTHER'  
                           ) 
--			INNER JOIN    
--                            Products.dbo.Charge X with (nolock)  
--                            on     P.Code         = X.productcode  
--                            and    P.PriceVersion = X.PriceVersion  
--                            and    P.DisabledFlag = X.DisabledFlag  
--                            and    X.Displaytype  <> 'OTHER'   
              INNER JOIN   
                    Products.dbo.ProductType PT with (nolock)  
              ON    P.ProductTypeCode = PT.Code  
              AND  ((@IPC_ProductType is not null and P.ProductTypeCode like '%' + @IPC_ProductType + '%') or @IPC_ProductType = '')  
              INNER JOIN  
                   Products.dbo.Category C with (nolock)  
              ON   P.CategoryCode = C.Code  
              AND  ((@IPC_Category is not null and P.CategoryCode like '%' + @IPC_Category + '%') or @IPC_Category = '')  
              INNER JOIN   
                   Products.dbo.[Platform] PF with (nolock)  
              ON   P.PlatformCode = PF.Code  
              AND  ((@IPC_Platform is not null and P.PlatformCode like '%' + @IPC_Platform + '%') or @IPC_Platform = '')  
			    AND  (( @IPV_StatusFlag  is not null and P.PendingApprovalFlag =  @IPV_StatusFlag ) or  @IPV_StatusFlag = '')      
           ------------------------------------------------------------------  
            )source  
           --------------------------------------------------------------------  
           )tableinner  
          ----------------------------------------------------------------------  
         )  
         SELECT  tablefinal.[Count]     
         from     tablefinal  

    --------------------------------------------------------------------------------  
    
END-->Main End  
ELSE
IF( @IPV_StatusFlag=1)

BEGIN
WITH tablefinal AS   
       ----------------------------------------------------------    
       (SELECT count(tableinner.[ID])                as [Count]  
        FROM  
           ----------------------------------------------------------   
          (select  *  
           from  
             ----------------------------------------------------------  
            (  
              SELECT   
                P.Code                                 as [ID]                  
              FROM  Products.dbo.Product P with (nolock)  
              INNER JOIN   
                    Products.dbo.Family F with (nolock)  
              ON    P.FamilyCode = F.Code  
              AND   P.DisabledFlag = 1 
              --AND   ((@IPVC_ProductName is not null and  P.[Name] like '%' + @IPVC_ProductName + '%') or @IPVC_ProductName     = '')  
              AND   ((@IPVC_DisplayName is not null and  P.[DisplayName] like '%' + @IPVC_DisplayName + '%') or @IPVC_DisplayName     = '')  
              AND   ((@IPC_FamilyCode   is not null and  P.FamilyCode =  @IPC_FamilyCode )    or @IPC_FamilyCode     = '')  
              AND   ((@IPI_ViewProducts is not null and  P.SOCFlag    = @IPI_ViewProducts )   or @IPI_ViewProducts   = '')  
              INNER JOIN   
                    Products.dbo.ProductType PT with (nolock)  
              ON    P.ProductTypeCode = PT.Code  
              AND  ((@IPC_ProductType is not null and P.ProductTypeCode like '%' + @IPC_ProductType + '%') or @IPC_ProductType = '')  
              INNER JOIN  
                   Products.dbo.Category C with (nolock)  
              ON   P.CategoryCode = C.Code  
              AND  ((@IPC_Category is not null and P.CategoryCode like '%' + @IPC_Category + '%') or @IPC_Category = '')  
              INNER JOIN   
                   Products.dbo.[Platform] PF with (nolock)  
              ON   P.PlatformCode = PF.Code  
              AND  ((@IPC_Platform is not null and P.PlatformCode like '%' + @IPC_Platform + '%') or @IPC_Platform = '')  
			    AND  (( @IPV_StatusFlag  is not null and P.PendingApprovalFlag =  1 ) or  @IPV_StatusFlag = '')      
           ------------------------------------------------------------------  
            )source  
           --------------------------------------------------------------------  
           )tableinner  
          ----------------------------------------------------------------------  
         )  
         SELECT  tablefinal.[Count]     
        from     tablefinal 
   END
--CODE TO GET INACTIVE PRODUCTS COUNT  
ELSE  
IF( @IPV_StatusFlag=2)  
  
BEGIN  
WITH tablefinal AS     
       ----------------------------------------------------------      
       (SELECT count(tableinner.[ID])                as [Count]    
        FROM    
           ----------------------------------------------------------     
          (select  *    
           from    
             ----------------------------------------------------------    
            (    
              SELECT     
                P.Code                                 as [ID]                    
              FROM  Products.dbo.Product P with (nolock)    
              INNER JOIN     
                    Products.dbo.Family F with (nolock)    
              ON    P.FamilyCode = F.Code    
              AND   P.DisabledFlag = 1   
     AND   P.PendingApprovalFlag =  0  
              --AND   ((@IPVC_ProductName is not null and  P.[Name] like '%' + @IPVC_ProductName + '%') or @IPVC_ProductName     = '')    
              AND   ((@IPVC_DisplayName is not null and  P.[DisplayName] like '%' + @IPVC_DisplayName + '%') or @IPVC_DisplayName     = '')    
              AND   ((@IPC_FamilyCode   is not null and  P.FamilyCode =  @IPC_FamilyCode )    or @IPC_FamilyCode     = '')    
              AND   ((@IPI_ViewProducts is not null and  P.SOCFlag    = @IPI_ViewProducts )   or @IPI_ViewProducts   = '')    
     INNER JOIN  
               (  
     SELECT Code, MAX(PriceVersion) 'LatestPriceVersion'  
     FROM PRODUCT  
     GROUP BY Code  
               )T1  
              ON  T1.Code = P.Code AND P.PriceVersion = T1.LatestPriceVersion  
              INNER JOIN     
                    Products.dbo.ProductType PT with (nolock)    
              ON    P.ProductTypeCode = PT.Code    
              AND  ((@IPC_ProductType is not null and P.ProductTypeCode like '%' + @IPC_ProductType + '%') or @IPC_ProductType = '')    
              INNER JOIN    
                   Products.dbo.Category C with (nolock)    
              ON   P.CategoryCode = C.Code    
              AND  ((@IPC_Category is not null and P.CategoryCode like '%' + @IPC_Category + '%') or @IPC_Category = '')    
              INNER JOIN     
                   Products.dbo.[Platform] PF with (nolock)    
              ON   P.PlatformCode = PF.Code    
              AND  ((@IPC_Platform is not null and P.PlatformCode like '%' + @IPC_Platform + '%') or @IPC_Platform = '')    
--       AND  (( @IPV_StatusFlag  is not null and P.PendingApprovalFlag =  1 ) or  @IPV_StatusFlag = '')        
           ------------------------------------------------------------------    
            )source    
           --------------------------------------------------------------------    
           )tableinner    
          ----------------------------------------------------------------------    
         )    
         SELECT  tablefinal.[Count]       
        from     tablefinal   
   END  
--END OF CODE TO GET INACTIVE PRODUCTS COUNT  
ELSE
 
BEGIN
WITH tablefinal AS   
       ----------------------------------------------------------    
       (SELECT count(tableinner.[ID])                as [Count]  
        FROM  
           ----------------------------------------------------------   
          (select  *  
           from  
             ----------------------------------------------------------  
            (  
              SELECT   
                P.Code                                 as [ID]                  
              FROM  Products.dbo.Product P with (nolock)  
              INNER JOIN   
                    Products.dbo.Family F with (nolock)  
              ON    P.FamilyCode = F.Code  
              AND   P.DisabledFlag = 0 
              AND   ((@IPVC_ProductName is not null and  P.[Name] like '%' + @IPVC_ProductName + '%') or @IPVC_ProductName     = '')  
              AND   ((@IPVC_DisplayName is not null and  P.[Name] like '%' + @IPVC_DisplayName + '%') or @IPVC_DisplayName     = '')  
              AND   ((@IPC_FamilyCode   is not null and  P.FamilyCode =  @IPC_FamilyCode )    or @IPC_FamilyCode     = '')  
              AND   ((@IPI_ViewProducts is not null and  P.SOCFlag    = @IPI_ViewProducts )   or @IPI_ViewProducts   = '')  
              AND   exists (select top 1 1 from  
                            Products.dbo.Charge X with (nolock)  
                            where  P.Code         = X.productcode  
                            and    P.PriceVersion = X.PriceVersion  
                            and    P.DisabledFlag = X.DisabledFlag  
                            and    X.Displaytype  <> 'OTHER'  
                           ) 
--			INNER JOIN    
--                            Products.dbo.Charge X with (nolock)  
--                            on     P.Code         = X.productcode  
--                            and    P.PriceVersion = X.PriceVersion  
--                            and    P.DisabledFlag = X.DisabledFlag  
--                            and    X.Displaytype  <> 'OTHER'   
              INNER JOIN   
                    Products.dbo.ProductType PT with (nolock)  
              ON    P.ProductTypeCode = PT.Code  
              AND  ((@IPC_ProductType is not null and P.ProductTypeCode like '%' + @IPC_ProductType + '%') or @IPC_ProductType = '')  
              INNER JOIN  
                   Products.dbo.Category C with (nolock)  
              ON   P.CategoryCode = C.Code  
              AND  ((@IPC_Category is not null and P.CategoryCode like '%' + @IPC_Category + '%') or @IPC_Category = '')  
              INNER JOIN   
                   Products.dbo.[Platform] PF with (nolock)  
              ON   P.PlatformCode = PF.Code  
              AND  ((@IPC_Platform is not null and P.PlatformCode like '%' + @IPC_Platform + '%') or @IPC_Platform = '')  
			    AND   P.PendingApprovalFlag =  0   
          UNION ALL
                SELECT   
                P.Code                                 as [ID]                  
              FROM  Products.dbo.Product P with (nolock)  
              INNER JOIN   
                    Products.dbo.Family F with (nolock)  
              ON    P.FamilyCode = F.Code  
              AND   P.DisabledFlag = 1 
              AND   ((@IPVC_ProductName is not null and  P.[Name] like '%' + @IPVC_ProductName + '%') or @IPVC_ProductName     = '')  
              AND   ((@IPVC_DisplayName is not null and  P.[Name] like '%' + @IPVC_DisplayName + '%') or @IPVC_DisplayName     = '')  
              AND   ((@IPC_FamilyCode   is not null and  P.FamilyCode =  @IPC_FamilyCode )    or @IPC_FamilyCode     = '')  
              AND   ((@IPI_ViewProducts is not null and  P.SOCFlag    = @IPI_ViewProducts )   or @IPI_ViewProducts   = '')  
              INNER JOIN   
                    Products.dbo.ProductType PT with (nolock)  
              ON    P.ProductTypeCode = PT.Code  
              AND  ((@IPC_ProductType is not null and P.ProductTypeCode like '%' + @IPC_ProductType + '%') or @IPC_ProductType = '')  
              INNER JOIN  
                   Products.dbo.Category C with (nolock)  
              ON   P.CategoryCode = C.Code  
              AND  ((@IPC_Category is not null and P.CategoryCode like '%' + @IPC_Category + '%') or @IPC_Category = '')  
              INNER JOIN   
                   Products.dbo.[Platform] PF with (nolock)  
              ON   P.PlatformCode = PF.Code  
              AND  ((@IPC_Platform is not null and P.PlatformCode like '%' + @IPC_Platform + '%') or @IPC_Platform = '')  
			  AND   P.PendingApprovalFlag =  1                   
           ------------------------------------------------------------------  
            )source  
           --------------------------------------------------------------------  
           )tableinner  
          ----------------------------------------------------------------------  
         )  
         SELECT  tablefinal.[Count]      
         from     tablefinal 
End
END
GO
