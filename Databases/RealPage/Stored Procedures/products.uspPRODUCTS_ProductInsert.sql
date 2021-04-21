SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ProductInsert]
			 (                          @IPVC_ProductName			VARCHAR(70),
                                                    @IPVC_DisplayName            	VARCHAR(70),   
                                                    @IPVC_Description            	VARCHAR(255),  
                                                    @IPC_PlatformCode           	CHAR(3),  
                                                    @IPC_FamilyCode             	CHAR(3),   
                                                    @IPC_CategoryCode           	CHAR(3),   
                                                    @IPC_ItemCode               	CHAR(15),  
                                                    @IPDT_StartDate              	DATETIME,   
                                                    @IPDT_EndDate                	DATETIME,  
                                                    @IPB_SOCFlag			BIT, 
						    @IPB_StockBundleFlag		BIT, 
						    @IPB_PriceCapEnabledFlag		BIT,
						    @IPB_ExcludeBookingsFlag		BIT,
						    @IPB_RegAdminProductFlag		BIT,
						    @IPB_MPFPublicationFlag		BIT,
						    @IPB_OptionFlag             	BIT,  
                                                    @IPC_ProductTypeCode        	CHAR(3),  
						    @IPVC_LegacyProductCode      	VARCHAR(6),
						    @IPVC_StockBundleIdentifierCode     VARCHAR(6),
						    @IPB_AutoFulFillFlag		BIT,
                                                    @IPBI_UserIDSeq                     bigint,  --> This is UserID of person logged on (Mandatory) 
                                                    @IPI_PrePaidFlag                    int = 0
                                                   )       
AS  
BEGIN   
  DECLARE @LN_ProductCode  VARCHAR(30)
  DECLARE @LC_PriceVersion NUMERIC(18,0)
  declare @LDT_SystemDate     datetime;
  
  select @LDT_SystemDate = getdate(); 

  SET @LN_ProductCode=@IPC_PlatformCode + '-' + @IPC_FamilyCode + '-' + @IPC_CategoryCode + '-' + @IPC_ProductTypeCode + '-' + @IPC_ItemCode 
  ----------------------------------------------------------------------
  If exists (select Top 1 1 
             from   Products.dbo.Product With (nolock)
             where  code=@LN_ProductCode
            )
  and exists (select Top 1 1 
              from   Products.dbo.Product With (nolock)
              where  code=@LN_ProductCode
              and    disabledflag        = 0
              and    pendingApprovalflag = 0
              )
  and exists (select Top 1 1 
              from   Products.dbo.Product With (nolock)
              where  code=@LN_ProductCode
              and    disabledflag        = 1
              and    pendingApprovalflag = 1
              )
  begin
    SELECT  Code,PriceVersion FROM Products.dbo.Product with (nolock) 
    WHERE   Code=@LN_ProductCode 
    and     disabledflag = 1
    and     pendingApprovalflag = 1
  end
  ------------------
  else If exists(select Top 1 1 
                 from   Products.dbo.Product With (nolock)
                 where  code=@LN_ProductCode
                 )
 and exists (select Top 1 1 
             from   Products.dbo.Product With (nolock)
             where  code=@LN_ProductCode
             and    disabledflag        = 0
             and    pendingApprovalflag = 0
             )
 and not exists (select Top 1 1 
                 from   Products.dbo.Product With (nolock)
                 where  code=@LN_ProductCode
                 and    disabledflag        = 1
                 and    pendingApprovalflag = 1
              )
 begin
   SELECT @LC_PriceVersion =Max(PriceVersion)+100 
   FROM   Product 
   WHERE  Code=@LN_ProductCode
   and    disabledflag        = 0
   and    PendingApprovalFlag = 0

   EXEC Products.dbo.uspPRODUCTS_ReviseProduct	 @Code=@LN_ProductCode,
	                                         @PriceVersion=@LC_PriceVersion, 
                                                 @IPBI_UserIDSeq = @IPBI_UserIDSeq

   select top 1 ltrim(rtrim(P.Code)) as [Code],P.Priceversion as [Priceversion]
   from   Products.dbo.Product P with (nolock)
   where  P.Code                = @LN_ProductCode   
   and    P.disabledflag        = 1
   and    P.PendingApprovalFlag = 1
 end
 ------------------ 
 else if not exists (select Top 1 1 
                     from   Products.dbo.Product With (nolock)
                     where  code=@LN_ProductCode                     
                    )
 begin
   select @LC_PriceVersion= 100

   DECLARE @LI_SortSeq             bigint
   DECLARE @ProducttypeSortSeq     bigint
   DECLARE @ExistingProductTypeSeq bigint
   Select @ProducttypeSortSeq = SortSeq From Products.dbo.ProductType with (nolock) Where Code = @IPC_ProductTypeCode
   Select @ExistingProductTypeSeq = Max(SortSeq) From Products.dbo.Product with (nolock) Where ProductTypeCode = @IPC_ProductTypeCode
   Select @LI_SortSeq= coalesce(@ExistingProductTypeSeq, @ProducttypeSortSeq) + 1

   SET  @IPVC_StockBundleIdentifierCode= nullif(ltrim(rtrim(@IPVC_StockBundleIdentifierCode)),'')
   SET  @IPVC_LegacyProductCode= nullif(ltrim(rtrim(@IPVC_LegacyProductCode)),'') 

   INSERT INTO Products.dbo.Product (Code,       
                      PriceVersion,  
                      [Name],  
                      DisplayName,   
                      [Description],  
                      PlatformCode,  
                      FamilyCode,  
                      CategoryCode,  
                      ItemCode,
		      SortSeq,     
                      StartDate,   
                      EndDate ,  
                      SOCFlag,
		      StockBundleFlag, 
		      PriceCapEnabledFlag,
		      ExcludeForBookingsFlag,
		      RegAdminProductFlag,
		      MPFPublicationFlag,
		      DisabledFlag,   
                      OptionFlag,  
                      ProductTypeCode,  
                      LegacyProductCode,
		      PendingApprovalFlag,
		      StockBundleIdentifierCode,
		      AutoFulFillFlag,
                      PrePaidFlag,
                      CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate)  
  
   select              @LN_ProductCode,   
                       100,  
                       @IPVC_DisplayName,  
                       @IPVC_DisplayName,  
                       @IPVC_Description,  
                       @IPC_PlatformCode,   
		       @IPC_FamilyCode,  
                       @IPC_CategoryCode,  
                       @IPC_ItemCode,
		       @LI_SortSeq,    
                       @IPDT_StartDate,  
                       '12/31/2050',   
                       @IPB_SOCFlag,
		       @IPB_StockBundleFlag, 
		       @IPB_PriceCapEnabledFlag,
		       @IPB_ExcludeBookingsFlag,
		       @IPB_RegAdminProductFlag,
		       @IPB_MPFPublicationFlag,
		       1,  
                       @IPB_OptionFlag,   
                       @IPC_ProductTypeCode,  
                       @IPVC_LegacyProductCode,	
		       1,
		       @IPVC_StockBundleIdentifierCode,
		       @IPB_AutoFulFillFlag,
                       @IPI_PrePaidFlag,
                       @IPBI_UserIDSeq as CreatedByIDSeq,
                       NULL            as ModifiedByIDSeq,
                       @LDT_SystemDate as CreatedDate,
                       NULL            as ModifiedDate 
    where not exists (select top 1 1 
                      from   Products.dbo.Product P with (nolock)
                      where  P.Code = @LN_ProductCode
                     );

    -------------------------------------------------------
    --Interim solution Domin-8 PrePaid
    Update P
    Set    P.PrePaidFlag     = 1
          ,P.AutoFulFillFlag = 1
    from   Products.dbo.Product P with (nolock)
    where  P.FamilyCode in ('DMN','DCN')
    and   (  
           (P.DisplayName like '%PREPAID%')
             OR
           exists (select top 1 1
                   from   Products.dbo.Product X with (nolock) 
                   where  X.FamilyCode in ('DMN','DCN') 
                   and    X.DisplayName like '%PREPAID%'
                   and    X.Code = P.Code
                   )  
           );
    -------------------------------------------------------
    --Final Return to UI
    SELECT  Code,PriceVersion 
    FROM    Products.dbo.Product with(nolock) 
    WHERE   Code=@LN_ProductCode;
    -------------------------------------------------------
  end

					 
               
              
    
END -- Main END starts at Col 01
GO
