SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_GetProductSelect]
			 (      
                                                        @ProductCode	CHAR(30),      
                                                        @PriceVersion	NUMERIC(18,0)      
                                                       )      
                                                        
AS      
BEGIN -- Main BEGIN starts at Col 01      
          
        /*********************************************************************************************/      
        /*                Table 1: Select statement from Product                                                     */        
        /*********************************************************************************************/      
      
       SELECT		  Code,  
					  PriceVersion,      
                      [Name],      
                      DisplayName,       
                      [Description],      
                      PlatformCode,      
                      FamilyCode,      
                      CategoryCode,      
                      ItemCode,       
                      convert(VARCHAR(12),P.StartDate,101)   as StartDate,      
                      convert(VARCHAR(12),P.EndDate,101)     as EndDate,        
                      StartDate,       
                      EndDate ,      
                      SOCFlag,    
				     StockBundleFlag,     
				     PriceCapEnabledFlag,    
				     ExcludeForBookingsFlag,    
				     RegAdminProductFlag,    
				     MPFPublicationFlag,    
				     ReportPrimaryProductFlag,       
					 OptionFlag,      
					 CreatedBy,      
					 ProductTypeCode,      
					 PendingApprovalFlag,
					 DisabledFlag,    
					 LegacyProductCode ,
					 StockBundleIdentifierCode,
                     AutoFulFillFlag,
(SELECT Count(1) FROM StockProductLookUp WHERE stockproductcode = @ProductCode and stockproductpriceversion =@PriceVersion) AS StockAssociatedCount    
    
        FROM          Products.dbo.Product P   with(nolock)    
        WHERE         code= @ProductCode AND PriceVersion=@PriceVersion      
      
        /*********************************************************************************************/      
        /*                Table 2: Select statement from ProductInvalidCombo                                                     */        
        /*********************************************************************************************/      
       
        SELECT       SecondProductCode       
        FROM         Products.dbo.ProductInvalidCombo       
        WHERE        FirstProductCode=@ProductCode AND FirstProductPriceVersion=@PriceVersion      
      
      /*********************************************************************************************/      
        /*                Table 3: Select statement from Charge                                                     */        
        /*********************************************************************************************/      
      
        SELECT Count(1) AS ChargeCount 
								FROM  Products.dbo.Charge 
								WHERE ProductCode =@ProductCode   
                                                                   
END -- Main END starts at Col 01
GO
