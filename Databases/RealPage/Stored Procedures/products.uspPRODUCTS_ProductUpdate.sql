SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ProductUpdate]
	(  
                                                    @IPVC_DisplayName            varchar(70),   
                                                    @IPVC_Description            varchar(255),  
                                                    @IPC_PlatformCode            char(3),  
                                                    @IPC_FamilyCode              char(3),   
                                                    @IPC_CategoryCode            char(3),   
                                                    @IPC_ItemCode                char(15),  
                                                    @IPDT_StartDate              datetime,   
                                                    @IPDT_EndDate                datetime,  
                                                    @IPB_SOCFlag		 bit, 
						    @IPB_StockBundleFlag	 bit, 
						    @IPB_PriceCapEnabledFlag	 bit,
						    @IPB_ExcludeBookingsFlag	 bit,
						    @IPB_RegAdminProductFlag	 bit,
						    @IPB_MPFPublicationFlag	 bit,
						    @IPB_OptionFlag              bit,  
                                                    @IPVC_ModifiedBy             varchar(50),  
                                                    @IPC_ProductTypeCode         char(3),  
                                                    @IPC_ProductCode             char(30),  
                                                    @IPN_PriceVersion            numeric(18,0),  
                                                    @IPB_PendingApprovalFlag     bit,
						    @IPB_DisableFlag		 bit,
  						    @IPVC_LegacyProductCode      varchar(10),
						    @IPVC_StockBundleIdentifierCode varchar(6),
						    @IPB_AutoFulFillFlag	 BIT,
                                                    @IPBI_UserIDSeq              bigint,  --> This is UserID of person logged on (Mandatory) 
                                                    @IPI_PrePaidFlag             int = 0
                                                    )       
AS  
BEGIN   
----------------------------------------------------------------------------  
-- Local Variable Declaration  
----------------------------------------------------------------------------  
 declare @LC_NewPriceVersion char(30)  
 declare @LDT_SystemDate     datetime;
  
  select @LDT_SystemDate = getdate();   
----------------------------------------------------------------------------  
  
IF @IPB_PendingApprovalFlag=1  
BEGIN  
SET  @IPVC_StockBundleIdentifierCode= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_StockBundleIdentifierCode)),'') = '' THEN NULL
ELSE @IPVC_StockBundleIdentifierCode END
SET  @IPVC_LegacyProductCode= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_LegacyProductCode)),'') = '' THEN NULL
ELSE @IPVC_LegacyProductCode END
 --DELETE FROM ProductInvalidCombo WHERE FirstProductCode=@ProductCode AND FirstProductPriceVersion=@PriceVersion  
  
 UPDATE Product SET   Code = @IPC_PlatformCode + '-' + @IPC_FamilyCode + '-' + @IPC_CategoryCode + '-' + @IPC_ProductTypeCode + '-' + @IPC_ItemCode,       
                      PriceVersion    =  @IPN_PriceVersion,  
                      [Name]          =  @IPVC_DisplayName,  
                      DisplayName     =  @IPVC_DisplayName,   
                      Description     =  @IPVC_Description,  
                      PlatformCode    =  @IPC_PlatformCode ,  
                      FamilyCode      =  @IPC_FamilyCode,  
                      CategoryCode    =  @IPC_CategoryCode,  
                      ItemCode        =  @IPC_ItemCode,     
                      SOCFlag         =  @IPB_SOCFlag, 
  		      StockBundleFlag = @IPB_StockBundleFlag,		
		      PriceCapEnabledFlag      = @IPB_PriceCapEnabledFlag,	
		      ExcludeForBookingsFlag   = @IPB_ExcludeBookingsFlag,	
		      RegAdminProductFlag      = @IPB_RegAdminProductFlag,	
		      MPFPublicationFlag       = @IPB_MPFPublicationFlag,		
		      OptionFlag               = @IPB_OptionFlag,  
                      ProductTypeCode          = @IPC_ProductTypeCode,  
    		      LegacyProductCode        = @IPVC_LegacyProductCode,
		      StockBundleIdentifierCode= @IPVC_StockBundleIdentifierCode,
		      AutoFulFillFlag          = @IPB_AutoFulFillFlag,
                      PrePaidFlag              = @IPI_PrePaidFlag,
                      ModifiedByIDSeq = @IPBI_UserIDSeq,
                      ModifiedDate    = @LDT_SystemDate,
                      SystemLogDate   = @LDT_SystemDate
  WHERE   Code        =   @IPC_ProductCode 
  and     PriceVersion=   @IPN_PriceVersion;  
END  
----------------------------------------------------------------------------  
IF @IPB_PendingApprovalFlag=0  
BEGIN  
  
select @LC_NewPriceVersion = max(PriceVersion) from product where Code = @IPC_ProductCode  
if @LC_NewPriceVersion is null
begin
  select @LC_NewPriceVersion = 100
end
else
begin
  select @LC_NewPriceVersion = @LC_NewPriceVersion + 100
end

INSERT INTO Product ( Code,       
                      PriceVersion,  
                      [Name],  
                      DisplayName,   
                      Description,  
                      PlatformCode,  
                      FamilyCode,  
                      CategoryCode,  
                      ItemCode,     
                      StartDate,   
                      EndDate ,  
                      SOCFlag, 
		      DisabledFlag, 
		      StockBundleFlag, 
		      PriceCapEnabledFlag,
		      ExcludeForBookingsFlag,
		      RegAdminProductFlag,
		      MPFPublicationFlag,
		      OptionFlag,
                      ProductTypeCode,  
                      PendingApprovalFlag,
		      LegacyProductCode,
		      StockBundleIdentifierCode,
		      AutoFulFillFlag,
                      PrePaidFlag,
                      CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate)  
  
  select               @IPC_PlatformCode + '-' + @IPC_FamilyCode + '-' + @IPC_CategoryCode + '-' + @IPC_ProductTypeCode + '-' + @IPC_ItemCode,   
                       @LC_NewPriceVersion,
                       @IPVC_DisplayName,  
                       @IPVC_DisplayName,  
                       @IPVC_Description,  
                       @IPC_PlatformCode,   
                       @IPC_FamilyCode,  
                       @IPC_CategoryCode,  
                       @IPC_ItemCode,    
                       @IPDT_StartDate,  
                       @IPDT_EndDate,   
                       @IPB_SOCFlag,
		       1,	
		       @IPB_StockBundleFlag, 
		       @IPB_PriceCapEnabledFlag,
		       @IPB_ExcludeBookingsFlag,
		       @IPB_RegAdminProductFlag,
		       @IPB_MPFPublicationFlag,
		       @IPB_OptionFlag, 
                       @IPC_ProductTypeCode,  
                       1,@IPVC_LegacyProductCode,
                       @IPVC_StockBundleIdentifierCode,
		       @IPB_AutoFulFillFlag,
                       @IPI_PrePaidFlag,
                       @IPBI_UserIDSeq as CreatedByIDSeq,
                       NULL            as ModifiedByIDSeq,
                       @LDT_SystemDate as CreatedDate,
                       NULL            as ModifiedDate 
  where not exists (select top 1 1 
                      from   Products.dbo.Product P with (nolock)
                      where  P.Code = @IPC_PlatformCode + '-' + @IPC_FamilyCode + '-' + @IPC_CategoryCode + '-' + @IPC_ProductTypeCode + '-' + @IPC_ItemCode
                      and    P.Priceversion = @LC_NewPriceVersion
                     )
END  


    -------------------------------------------------------
    --Interim solution Domin-8 PrePaid
    Update P
    Set    P.PrePaidFlag = 1
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
  SELECT Code,PriceVersion from Products.dbo.Product
  where code      =@IPC_PlatformCode + '-' + @IPC_FamilyCode + '-' + @IPC_CategoryCode + '-' + @IPC_ProductTypeCode + '-' + @IPC_ItemCode 
  and PriceVersion=@LC_NewPriceVersion
  ----------------------------------------------------------------------------    
  IF(@IPVC_StockBundleIdentifierCode is null or @IPVC_StockBundleIdentifierCode = '')
  BEGIN
    IF EXISTS(SELECT top 1 1  FROM StockProductLookUp WHERE stockproductcode = @IPC_ProductCode and stockproductpriceversion =@IPN_PriceVersion)
    BEGIN
      DELETE FROM dbo.StockProductLookUp WHERE StockProductCode=@IPC_ProductCode AND StockProductPriceVersion=@IPN_PriceVersion 
    END
  END
  ----------------------------------------------------------------------------
  
END  
GO
