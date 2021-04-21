SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : uspPRODUCT_ProductList
-- Description     : This procedure gets the list of the Products.
-- Input Parameters: As Below in Sequential order.
-- Code Example    : Exec PRODUCTS.DBO.uspPRODUCTS_ProductList  Passing Input Parameters
-- Revision History:
-- Author          : Mahaboob Mohammad
-- 2011-06-15      : Defect #319
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ProductList]
			 (@IPI_PageNumber       as  int,   
			  @IPI_RowsPerPage      as  int,   
			  @IPVC_ProductName     as  varchar(255),  
			  @IPC_FamilyCode       as  varchar(3),  
			  @IPI_ViewProducts     as  varchar(3),  
			  @IPC_Category         as  varchar(3),  
			  @IPC_Platform         as  varchar(3),  
			  @IPVC_DisplayName     as  varchar(255),  
			  @IPC_ProductType      as  varchar(3),
			  @IPV_StatusFlag       as  varchar(10)
			  
     )  
AS  
BEGIN--> Main Begin  
 if( @IPV_StatusFlag=0 and @IPV_StatusFlag<>'') 

Begin
----------------------------------------------------------------------------  
  --Final Select   
  ----------------------------------------------------------------------------  
  WITH tablefinal AS   
       ----------------------------------------------------------    
       (SELECT tableinner.*  
        FROM  
           ----------------------------------------------------------   
          (select  row_number() over(order by 
												source.SortFamily Asc,
												source.SortPlatform Asc, 
												source.SortCategory Asc,
												source.SortProductType Asc,
												source.SortProdct Asc )  
                                         as RowNumber,  
                   source.*  
           from  
             ----------------------------------------------------------    
          (  
			SELECT   
                P.Code                                 as ProductCode,
				P.DisabledFlag						   as Flag,  
                P.PriceVersion                         as PriceVersion,  
                P.[Name]                               as ProductName,  
                C.[Name]                               as Category,  
                F.[Name]                               as Family,  
                PF.[Name]							   as [Platform],  
                P.DisplayName                          as DisplayName,  
                PT.[Name]                              as ProductType,   
                P.PendingApprovalFlag				   as [Status], 
				P.CreateDate						   as CreateDate,
				F.SortSeq							   as SortFamily,
				PF.SortSeq							   as SortPlatform,
				C.SortSeq							   as SortCategory,
				PT.SortSeq							   as SortProductType,
				P.SortSeq							   as SortProdct
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

--               INNER JOIN    
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
			  AND  ((@IPV_StatusFlag is not null and P.PendingApprovalFlag =  @IPV_StatusFlag) or @IPV_StatusFlag = '') 
			     
           ------------------------------------------------------------------  
           )source  
          --------------------------------------------------------------------  
          )tableinner  
         ----------------------------------------------------------------------  
         WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage  
         AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage   
        )  
       SELECT  tablefinal.RowNumber,  
               tablefinal.ProductCode         as ProductCode,  
				
				tablefinal.Flag        as DisableFlag, 
               tablefinal.PriceVersion        as PriceVersion,  
        tablefinal.ProductName         as ProductName,  
               tablefinal.Category            as Category,  
               tablefinal.Family              as Family,  
               tablefinal.[Platform]          as [Platform],  
        tablefinal.DisplayName         as DisplayName,   
        tablefinal.ProductType         as ProductType ,
  tablefinal.Status         as [Status],   
       convert(varchar(12),tablefinal.CreateDate,101)  as CreateDate
      from     tablefinal   order by SortFamily Asc,SortPlatform Asc, SortCategory Asc,SortProductType Asc,SortProdct Asc  

END-->Main End						 
									  
ELSE
 if( @IPV_StatusFlag=1) 
Begin
WITH tablefinal AS   
       ----------------------------------------------------------    
       (SELECT tableinner.*  
        FROM  
           ----------------------------------------------------------   
          (select  row_number() over(order by   source.SortFamily Asc,
												source.SortPlatform Asc, 
												source.SortCategory Asc,
												source.SortProductType Asc,
												source.SortProdct Asc )  
                                         as RowNumber,  
                   source.*  
           from  
             ----------------------------------------------------------    
          (  
     SELECT   
                P.Code                                 as ProductCode,
				P.DisabledFlag						   as Flag,  
                P.PriceVersion                         as PriceVersion,  
                P.[Name]                               as ProductName,  
                C.[Name]                               as Category,  
                F.[Name]                               as Family,  
                PF.[Name]							   as [Platform],  
                P.DisplayName                          as DisplayName,  
                PT.[Name]                              as ProductType ,  
                P.PendingApprovalFlag				   as [Status] ,
				P.CreateDate						   as CreateDate,
				F.SortSeq							   as SortFamily,
				PF.SortSeq							   as SortPlatform,
				C.SortSeq							   as SortCategory,
				PT.SortSeq							   as SortProductType,
				P.SortSeq							   as SortProdct
              FROM  Products.dbo.Product P with (nolock)  
              INNER JOIN   
                    Products.dbo.Family F with (nolock)  
              ON    P.FamilyCode = F.Code  
              AND   P.DisabledFlag = 1  
           --  AND   ((@IPVC_ProductName is not null and  P.[Name] like '%' + @IPVC_ProductName + '%') or @IPVC_ProductName     = '')  
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
			  AND  ((@IPV_StatusFlag is not null and P.PendingApprovalFlag =  1) or @IPV_StatusFlag = '') 
			            
           ------------------------------------------------------------------  
           )source  
          --------------------------------------------------------------------  
          )tableinner  
         ----------------------------------------------------------------------  
         WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage  
         AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage   
        )  
       SELECT  tablefinal.RowNumber,  
               tablefinal.ProductCode         as ProductCode,  
				
				tablefinal.Flag        as DisableFlag, 
               tablefinal.PriceVersion        as PriceVersion,  
        tablefinal.ProductName         as ProductName,  
               tablefinal.Category            as Category,  
               tablefinal.Family              as Family,  
               tablefinal.[Platform]          as [Platform],  
        tablefinal.DisplayName         as DisplayName,   
        tablefinal.ProductType         as ProductType ,
		tablefinal.Status         as [Status],   
       convert(varchar(12),tablefinal.CreateDate,101)  as CreateDate
      from     tablefinal order by SortFamily Asc,SortPlatform Asc, SortCategory Asc,SortProductType Asc,SortProdct Asc 
End

--CODE TO GET INACTIVE PRODUCTS LIST
ELSE
 if( @IPV_StatusFlag=2) 
Begin
WITH tablefinal AS   
       ----------------------------------------------------------    
       (SELECT tableinner.*  
        FROM  
           ----------------------------------------------------------   
          (select  row_number() over(order by   source.SortFamily Asc,
												source.SortPlatform Asc, 
												source.SortCategory Asc,
												source.SortProductType Asc,
												source.SortProdct Asc )  
                                         as RowNumber,  
                   source.*  
           from  
             ----------------------------------------------------------    
          (  
     SELECT   
                P.Code                                 as ProductCode,
				P.DisabledFlag						   as Flag,  
                P.PriceVersion                         as PriceVersion,  
                P.[Name]                               as ProductName,  
                C.[Name]                               as Category,  
                F.[Name]                               as Family,  
                PF.[Name]							   as [Platform],  
                P.DisplayName                          as DisplayName,  
                PT.[Name]                              as ProductType ,  
                P.PendingApprovalFlag				   as [Status] ,
				P.CreateDate						   as CreateDate,
				F.SortSeq							   as SortFamily,
				PF.SortSeq							   as SortPlatform,
				C.SortSeq							   as SortCategory,
				PT.SortSeq							   as SortProductType,
				P.SortSeq							   as SortProdct
              FROM  Products.dbo.Product P with (nolock)  
              INNER JOIN   
                    Products.dbo.Family F with (nolock)  
              ON    P.FamilyCode = F.Code  
              AND   P.DisabledFlag = 1   
			  AND   P.PendingApprovalFlag =  0  
           --  AND   ((@IPVC_ProductName is not null and  P.[Name] like '%' + @IPVC_ProductName + '%') or @IPVC_ProductName     = '')  
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
			 
			            
           ------------------------------------------------------------------  
           )source  
          --------------------------------------------------------------------  
          )tableinner  
         ----------------------------------------------------------------------  
         WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage  
         AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage   
        )  
       SELECT  tablefinal.RowNumber,  
               tablefinal.ProductCode         as ProductCode,  
				
				tablefinal.Flag        as DisableFlag, 
               tablefinal.PriceVersion        as PriceVersion,  
        tablefinal.ProductName         as ProductName,  
               tablefinal.Category            as Category,  
               tablefinal.Family              as Family,  
               tablefinal.[Platform]          as [Platform],  
        tablefinal.DisplayName         as DisplayName,   
        tablefinal.ProductType         as ProductType ,
		tablefinal.Status         as [Status],   
       convert(varchar(12),tablefinal.CreateDate,101)  as CreateDate
      from     tablefinal order by SortFamily Asc,SortPlatform Asc, SortCategory Asc,SortProductType Asc,SortProdct Asc 
End
--END OF CODE TO GET INACTIVE PRODUCTS LIST 
ELSE
	
	BEGIN
WITH tablefinal AS   
       ----------------------------------------------------------    
       (SELECT tableinner.*  
        FROM  
           ----------------------------------------------------------   
          (select  row_number() over(order by 	source.SortFamily Asc,
												source.SortPlatform Asc, 
												source.SortCategory Asc,
												source.SortProductType Asc,
												source.SortProdct Asc )  
                                         as RowNumber,  
                   source.*  
           from  
             ----------------------------------------------------------    
          (  
     SELECT    
                P.Code                                 as ProductCode,
				P.DisabledFlag						   as Flag,  
                P.PriceVersion                         as PriceVersion,  
                P.[Name]                               as ProductName,  
                C.[Name]                               as Category,  
                F.[Name]                               as Family,  
                PF.[Name]							   as [Platform],  
                P.DisplayName                          as DisplayName,  
                PT.[Name]                              as ProductType,   
                 P.PendingApprovalFlag				   as [Status] ,
				P.CreateDate						   as CreateDate,
				F.SortSeq							   as SortFamily,
				PF.SortSeq							   as SortPlatform,
				C.SortSeq							   as SortCategory,
				PT.SortSeq							   as SortProductType,
				P.SortSeq							   as SortProdct
              FROM  Products.dbo.Product P with (nolock)  
              INNER JOIN   
                    Products.dbo.Family F with (nolock)  
              ON    P.FamilyCode = F.Code  
              AND   P.DisabledFlag = 0  
           --  AND   ((@IPVC_ProductName is not null and  P.[Name] like '%' + @IPVC_ProductName + '%') or @IPVC_ProductName     = '')  
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

--               INNER JOIN    
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
			  AND  (P.PendingApprovalFlag =  0)
				 
				UNION ALL
			         SELECT   
                P.Code                                 as ProductCode,
				P.DisabledFlag						   as Flag,  
                P.PriceVersion                         as PriceVersion,  
                P.[Name]                               as ProductName,  
                C.[Name]                               as Category,  
                F.[Name]                               as Family,  
                PF.[Name]							   as [Platform],  
                P.DisplayName                          as DisplayName,  
                PT.[Name]                              as ProductType ,  
                P.PendingApprovalFlag				   as [Status] ,
				P.CreateDate						   as CreateDate,
				F.SortSeq							   as SortFamily,
				PF.SortSeq							   as SortPlatform,
				C.SortSeq							   as SortCategory,
				PT.SortSeq							   as SortProductType,
				P.SortSeq							   as SortProdct
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
			  AND   P.PendingApprovalFlag =  1

              UNION ALL
                    SELECT   
                P.Code                                 as ProductCode,
				P.DisabledFlag						   as Flag,  
                P.PriceVersion                         as PriceVersion,  
                P.[Name]                               as ProductName,  
                C.[Name]                               as Category,  
                F.[Name]                               as Family,  
                PF.[Name]							   as [Platform],  
                P.DisplayName                          as DisplayName,  
                PT.[Name]                              as ProductType ,  
                P.PendingApprovalFlag				   as [Status] ,
				P.CreateDate						   as CreateDate,
				F.SortSeq							   as SortFamily,
				PF.SortSeq							   as SortPlatform,
				C.SortSeq							   as SortCategory,
				PT.SortSeq							   as SortProductType,
				P.SortSeq							   as SortProdct
              FROM  Products.dbo.Product P with (nolock)  
              INNER JOIN   
                    Products.dbo.Family F with (nolock)  
              ON    P.FamilyCode = F.Code  
              AND   P.DisabledFlag = 1   
			  AND   P.PendingApprovalFlag =  0  
           --  AND   ((@IPVC_ProductName is not null and  P.[Name] like '%' + @IPVC_ProductName + '%') or @IPVC_ProductName     = '')  
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
                  

			 
           ------------------------------------------------------------------  
           )source  
          --------------------------------------------------------------------  
          )tableinner  
         ----------------------------------------------------------------------  
         WHERE tableinner.RowNumber >  (@IPI_PageNumber-1) * @IPI_RowsPerPage  
         AND   tableinner.RowNumber <= (@IPI_PageNumber)   * @IPI_RowsPerPage   
        )  
       SELECT  tablefinal.RowNumber,  
               tablefinal.ProductCode         as ProductCode,  
				
				tablefinal.Flag        as DisableFlag, 
               tablefinal.PriceVersion        as PriceVersion,  
        tablefinal.ProductName         as ProductName,  
               tablefinal.Category            as Category,  
               tablefinal.Family              as Family,  
               tablefinal.[Platform]          as [Platform],  
        tablefinal.DisplayName         as DisplayName,   
        tablefinal.ProductType         as ProductType ,  
        tablefinal.Status         as [Status],   
       convert(varchar(12),tablefinal.CreateDate,101)  as CreateDate
      from     tablefinal  order by SortFamily Asc,SortPlatform Asc, SortCategory Asc,SortProductType Asc,SortProdct Asc 
	END
End
GO
