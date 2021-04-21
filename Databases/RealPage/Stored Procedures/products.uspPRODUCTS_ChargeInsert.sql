SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_ChargeInsert]
-- Description     : This procedure Adds CHARge Record
 
            --IPN_,IPVC_,IPC_,IPM_,IPD_


------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ChargeInsert]             (
								@IPVC_ProductCode VARCHAR(30),                    
								@IPN_PriceVersion NUMERIC(18,0),                            
								@IPC_ChargeTypeCode CHAR(3), 
								@IPC_MeasureCode CHAR(6), 
								@IPC_FrequencyCode CHAR(6), 
								@IPVC_SiebelProductID VARCHAR(30), 
								@IPM_CHARgeAmount MONEY,          
								@IPI_MinUnits INT,    
								@IPI_MaxUnits INT,    
								@IPD_UnitBasis DECIMAL(18,5),
								@IPB_FlatPriceFlag BIT, 
								@IPM_DollarMinimum MONEY,         
								@IPB_DollarMinimumEnabledFlag BIT, 
								@IPM_DollarMaximum MONEY,         
								@IPB_DollarMaximumEnabledFlag BIT, 
								@IPB_MINThresholdOverrideFlag BIT, 
								@IPB_MaxThresholdOverrideFlag BIT, 
								@IPN_DiscountMaxPercent NUMERIC(30,5),                      
								@IPN_CommissionMaxPercent NUMERIC(30,5),                    
								@IPB_QuantityEnabledFlag BIT, 
								@IPB_QuantityMultiplierFlag BIT, 
								@IPB_PriceByPPUPercentageEnabledFlag BIT, 
								@IPB_PriceByBedEnabledFlag BIT, 
								@IPVC_DisplayType VARCHAR(50),                                        
								@IPB_DisabledFlag BIT,
								@IPDT_StartDate DATETIME,               
								@IPDT_EndDate DATETIME,                 								                              
								@IPVC_RevenueTierCode VARCHAR(30)='',                
								@IPVC_RevenueAccountCode VARCHAR(32)='',               
								@IPVC_DeferredRevenueAccountCode VARCHAR(32)='',       
								@IPVC_TaxwareCode VARCHAR(20)='',          
								@IPVC_RevenueRecognitionCode VARCHAR(3), 
								@IPB_SRSDisplayQuantityFlag BIT, 
								@IPB_CreditCardPercentageEnabledFlag BIT, 
								@IPN_CredtCardPricingPercentage NUMERIC(30,3),             
								@IPVC_ReportingTypeCode VARCHAR(4), 
								@IPI_SeparateInvoiceGroupNumber BIGINT, 
								@IPB_ExplodeQuantityatOrderFlag BIT, 
								@IPB_MarkAsPrINTedFlag BIT, 
								@IPB_CrossFireCallPricingEnabledFlag BIT, 
								@IPVC_MPFPublicationName VARCHAR(100),             
								@IPVC_ReportCategoryName VARCHAR(100),                                                                                   
								@IPVC_ReportSubcategoryName1 VARCHAR(100),                                                                               
								@IPVC_ReportSubcategoryName2 VARCHAR(100),                                                                               
								@IPVC_ReportSubcategoryName3 VARCHAR(100),                                                                              
								@IPB_DisplayTransactionalProductPriceOnInvoiceFlag BIT =1,
								@IPI_LeadDays INT,
                                                                @IPB_ChargeEnabler BIT,
                                                                @IPB_ProrateFirstMonthFlag         BIT = 0, 
                                                                @IPB_AllowLongerContractFlag       BIT = 0,
                                                                @IPB_ValidateSiteMasterIDFlag      BIT = 0,
                                                                @IPBI_UserIDSeq                    bigint  --> This is UserID of person logged on (Mandatory) 
                                                                )
                                                       
AS
BEGIN 
  set nocount on;
  DECLARE @0PLC_RetVal VARCHAR(50)
  DECLARE @0PLC_RetMsg VARCHAR(400) 
  declare @LDT_SystemDate     datetime;

  select @LDT_SystemDate = getdate(); 

  select @IPVC_ProductCode  = ltrim(rtrim(@IPVC_ProductCode)),
         @IPC_ChargeTypeCode= ltrim(rtrim(@IPC_ChargeTypeCode)),
         @IPC_MeasureCode   = ltrim(rtrim(@IPC_MeasureCode)),
         @IPC_FrequencyCode = ltrim(rtrim(@IPC_FrequencyCode)),
         @IPVC_SiebelProductID =  Nullif(Nullif(ltrim(rtrim(@IPC_FrequencyCode)),'123'),'')

  ---------------------------------------------------------------------
  SET  @IPVC_RevenueTierCode= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_RevenueTierCode)),'') = '' THEN NULL
                                              ELSE @IPVC_RevenueTierCode END
  select @IPVC_RevenueTierCode = Nullif(Nullif(Nullif(@IPVC_RevenueTierCode,''),' '),'NULL')
  ---------------------------------------------------------------------
  SET  @IPVC_RevenueAccountCode= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_RevenueAccountCode)),'') = '' THEN NULL
                                              ELSE @IPVC_RevenueAccountCode END
  select @IPVC_RevenueAccountCode =  Nullif(Nullif(Nullif(@IPVC_RevenueAccountCode,''),' '),'NULL')
  ---------------------------------------------------------------------
  SET  @IPVC_TaxwareCode= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_TaxwareCode)),'') = '' THEN NULL
                                              ELSE @IPVC_TaxwareCode END
  select @IPVC_TaxwareCode =  Nullif(Nullif(Nullif(@IPVC_TaxwareCode,''),' '),'NULL')
  ---------------------------------------------------------------------
  SET  @IPVC_DeferredRevenueAccountCode= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_DeferredRevenueAccountCode)),'') = '' THEN NULL
                                              ELSE @IPVC_DeferredRevenueAccountCode END
  select @IPVC_DeferredRevenueAccountCode =  Nullif(Nullif(Nullif(@IPVC_DeferredRevenueAccountCode,''),' '),'NULL')
  ---------------------------------------------------------------------
  SET  @IPVC_MPFPublicationName= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_MPFPublicationName)),'') = '' THEN NULL
                                      ELSE @IPVC_MPFPublicationName END  
  select @IPVC_MPFPublicationName =   Nullif(Nullif(Nullif(@IPVC_MPFPublicationName,''),' '),'NULL')
  ---------------------------------------------------------------------
  SET  @IPVC_ReportCategoryName= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_ReportCategoryName)),'') = '' THEN NULL
                                      ELSE @IPVC_ReportCategoryName END

  SET  @IPVC_ReportSubcategoryName1= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_ReportSubcategoryName1)),'') = '' THEN NULL
  ELSE @IPVC_ReportSubcategoryName1 END

  SET  @IPVC_ReportSubcategoryName2= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_ReportSubcategoryName2)),'') = '' THEN NULL
  ELSE @IPVC_ReportSubcategoryName2 END

  SET  @IPVC_ReportSubcategoryName3= CASE WHEN  ISNULL(LTRIM(RTRIM(@IPVC_ReportSubcategoryName3)),'') = '' THEN NULL
  ELSE @IPVC_ReportSubcategoryName3 END


  EXEC uspPRODUCTS_ValidateCHARgeCombinations @IPVC_ProductCode,@IPN_PriceVersion,@IPC_CHARgeTypeCode,@IPC_MeasureCode,@IPC_FrequencyCode,@IPVC_DisplayType,@0PLC_RetVal OUTPUT,@0PLC_RetMsg OUTPUT
  IF(@0PLC_RetVal='Success')
  BEGIN
    INSERT INTO Products.dbo.Charge 
									(		ProductCode,                    
											PriceVersion,                            
											CHARgeTypeCode, 
											MeasureCode, 
											FrequencyCode, 
											SiebelProductID, 
											CHARgeAmount,          
											MinUnits,    
											MaxUnits,    
											UnitBasis,
											FlatPriceFlag, 
											DollarMinimum,         
											DollarMinimumEnabledFlag, 
											DollarMaximum,         
											DollarMaximumEnabledFlag, 
											MINThresholdOverride, 
											MaxThresholdOverride, 
											DiscountMaxPercent,                      
											CommissionMaxPercent,                    
											QuantityEnabledFlag, 
											QuantityMultiplierFlag, 
											PriceByPPUPercentageEnabledFlag, 
											PriceByBedEnabledFlag, 
											DisplayType,                                        
											DisabledFlag,
											StartDate,               
											EndDate,                 											              
											RevenueTierCode,                
											RevenueAccountCode,               
											DeferredRevenueAccountCode,       
											TaxwareCode,          
											RevenueRecognitionCode, 
											SRSDisplayQuantityFlag, 
											CreditCardPercentageEnabledFlag, 
											CredtCardPricingPercentage,              
											ReportingTypeCode, 
											SeparateInvoiceGroupNumber, 
											ExplodeQuantityatOrderFlag, 
											MarkAsPrINTedFlag, 
											CrossFireCallPricingEnabledFlag, 
											MPFPublicationName,             
											ReportCategoryName,                                                                                   
											ReportSubcategoryName1,                                                                               
											ReportSubcategoryName2,                                                                               
											ReportSubcategoryName3,
											DisplayTransactionalProductPriceOnInvoiceFlag,
											LeadDays,
                                                                                        SystemAutoCreateEnablerFlag,
                                                                                        ProrateFirstMonthFlag,
                                                                                        AllowLongerContractFlag,
                                                                                        ValidateSiteMasterIDFlag,
                                                                                        CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate                                  
											)
  SELECT      
											@IPVC_ProductCode,                    
											@IPN_PriceVersion,                            
											@IPC_ChargeTypeCode, 
											@IPC_MeasureCode, 
											@IPC_FrequencyCode, 
											@IPVC_SiebelProductID, 
											@IPM_CHARgeAmount,          
											@IPI_MinUnits,    
											@IPI_MaxUnits,    
											(case when @IPD_UnitBasis <= 0 then 1 else @IPD_UnitBasis end),
											@IPB_FlatPriceFlag, 
											@IPM_DollarMinimum,         
											@IPB_DollarMinimumEnabledFlag, 
											@IPM_DollarMaximum,         
											@IPB_DollarMaximumEnabledFlag, 
											(case when convert(int,@IPB_FlatPriceFlag) = 1 then 1 else @IPB_MINThresholdOverrideFlag end), 
											(case when convert(int,@IPB_FlatPriceFlag) = 1 then 1 else @IPB_MaxThresholdOverrideFlag end), 
											@IPN_DiscountMaxPercent,                      
											@IPN_CommissionMaxPercent,                    
											@IPB_QuantityEnabledFlag, 
											@IPB_QuantityMultiplierFlag, 
											@IPB_PriceByPPUPercentageEnabledFlag, 
											@IPB_PriceByBedEnabledFlag, 
											@IPVC_DisplayType,                                        
											1,
                                                                                        @IPDT_StartDate,               
											@IPDT_EndDate, 										              
											@IPVC_RevenueTierCode,                
											@IPVC_RevenueAccountCode,               
											@IPVC_DeferredRevenueAccountCode,       
											@IPVC_TaxwareCode,          
											@IPVC_RevenueRecognitionCode, 
											@IPB_SRSDisplayQuantityFlag, 
											@IPB_CreditCardPercentageEnabledFlag, 
											@IPN_CredtCardPricingPercentage,              
											@IPVC_ReportingTypeCode, 
											@IPI_SeparateInvoiceGroupNumber, 
											@IPB_ExplodeQuantityatOrderFlag, 
											@IPB_MarkAsPrINTedFlag, 
											@IPB_CrossFireCallPricingEnabledFlag, 
											@IPVC_MPFPublicationName,             
											@IPVC_ReportCategoryName,                                                                                   
											@IPVC_ReportSubcategoryName1,                                                                               
											@IPVC_ReportSubcategoryName2,                                                                               
											@IPVC_ReportSubcategoryName3,                                                                              
											(case when (ltrim(rtrim(@IPC_MeasureCode)) = 'TRAN')   
                                                                                                then @IPB_DisplayTransactionalProductPriceOnInvoiceFlag
                                                                                         else 0 end),
											(case when ltrim(rtrim(@IPC_ChargeTypeCode)) = 'ILF' then 1000
                                                                                              when ltrim(rtrim(@IPC_FrequencyCode))  = 'OT'  then 2000
                                                                                              else @IPI_LeadDays
                                                                                         end),
                                                                                        (case when ltrim(rtrim(@IPC_MeasureCode)) = 'TRAN' then @IPB_ChargeEnabler else 0 end),
                                                                                        (case when ltrim(rtrim(@IPC_FrequencyCode)) in ('MN','YR') then @IPB_ProrateFirstMonthFlag else 0 end),
                                                                                        (case when ltrim(rtrim(@IPC_FrequencyCode)) in ('MN','YR') then @IPB_AllowLongerContractFlag else 0 end),
                                                                                        (case when ltrim(rtrim(@IPC_ChargeTypeCode))     = 'ILF'  then 0
                                                                                              when ltrim(rtrim(@IPVC_ReportingTypeCode)) = 'ANCF' then 0
                                                                                              else @IPB_ValidateSiteMasterIDFlag
                                                                                         end),
                                                                                        @IPBI_UserIDSeq as CreatedByIDSeq,
                                                                                        NULL            as ModifiedByIDSeq,
                                                                                        @LDT_SystemDate as CreatedDate,
                                                                                        NULL            as ModifiedDate

        -----------------------------------------------------------------------

        --Other special updates -> Mandatory
        Update C
        set    C.DisplayTransactionalProductPriceOnInvoiceFlag=0,
               C.ModifiedByIDSeq = @IPBI_UserIDSeq,
               C.ModifiedDate    = @LDT_SystemDate,
               C.SystemLogDate   = @LDT_SystemDate    
        from   Products.dbo.Charge  C with (nolock)
        inner join Products.dbo.Product P with (nolock)
        on    C.ProductCode     = P.Code
        and   C.PriceVersion    = P.PriceVersion
        and  (C.Measurecode = 'TRAN'  and P.FamilyCode = 'LSD')
        and   C.ProductCode    =@IPVC_ProductCode  
        and   C.DisplayTransactionalProductPriceOnInvoiceFlag <> 0 ---> This update is Price version agnostic

        --1.AllowLongerContractFlag
        Update C
        set    C.AllowLongerContractFlag=1,
               C.ModifiedByIDSeq = @IPBI_UserIDSeq,
               C.ModifiedDate    = @LDT_SystemDate,
               C.SystemLogDate   = @LDT_SystemDate
        from   Products.dbo.Charge  C with (nolock)
        inner join Products.dbo.Product P with (nolock)
        on    C.ProductCode     = P.Code
        and   C.PriceVersion    = P.PriceVersion
        and   C.ChargetypeCode = 'ACS'
        and   (P.FamilyCode     in  ('VEL') OR P.ItemCode in ('CCPP','CCRP'))
        and   C.FrequencyCode   in  ('MN','YR')
        and   C.ProductCode    =@IPVC_ProductCode 
        and   C.AllowLongerContractFlag <> 1 ---> This update is Price version agnostic
        ---------------------------------
        --2.ProrateFirstMonthFlag is automatic for subscription Ops and Velocity Family products and AL Wizard
        Update C
        set    C.ProrateFirstMonthFlag = 1,
               C.ModifiedByIDSeq = @IPBI_UserIDSeq,
               C.ModifiedDate    = @LDT_SystemDate,
               C.SystemLogDate   = @LDT_SystemDate
        from   Products.dbo.Charge  C with (nolock)
        inner join Products.dbo.Product P with (nolock)
        on    C.ProductCode     = P.Code
        and   C.PriceVersion    = P.PriceVersion
        and   C.ChargetypeCode = 'ACS'
        and   (P.FamilyCode     in  ('SMS','VEL','ALW','REI','ERE'))
        and   C.FrequencyCode   in  ('MN','YR')
        and   C.ProductCode    =@IPVC_ProductCode 
        and   C.ProrateFirstMonthFlag <> 1 ---> This update is Price version agnostic
        ---------------------------------
        --3. SeparateInvoiceGroupNumber     
        Update C
        set    C.SeparateInvoiceGroupNumber = (Case when P.ItemCode = 'CSAP'            then 1
                                                    when (P.FamilyCode = 'OSD' and P.CategoryCode = 'PAY' and C.Measurecode = 'TRAN') 
                                                                                        then 1
                                                    when P.FamilyCode = 'OSD'           then 0
                                                    when P.FamilyCode = 'SMS'           then 2
                                                    when P.FamilyCode = 'VEL'           then 3
                                                    when P.FamilyCode = 'EGS'           then 5
                                                    when P.FamilyCode = 'ALW'           then 6
                                                    when P.FamilyCode in ('REI','ERE')  then 7
                                                    when P.FamilyCode = 'DCN'           then 8
                                                    when P.FamilyCode = 'CLD'           then 9
                                                    else @IPI_SeparateInvoiceGroupNumber
                                                end),
               C.ModifiedByIDSeq = @IPBI_UserIDSeq,
               C.ModifiedDate    = @LDT_SystemDate,
               C.SystemLogDate   = @LDT_SystemDate
        from   Products.dbo.Charge  C with (nolock)
        inner join Products.dbo.Product P with (nolock)
        on    C.ProductCode     = P.Code
        and   C.PriceVersion    = P.PriceVersion
        and   C.ProductCode     = @IPVC_ProductCode 
        and   C.SeparateInvoiceGroupNumber <> (Case when P.ItemCode = 'CSAP'            then 1
                                                    when (P.FamilyCode = 'OSD' and P.CategoryCode = 'PAY' and C.Measurecode = 'TRAN') 
                                                                                        then 1
                                                    when P.FamilyCode = 'OSD'           then 0
                                                    when P.FamilyCode = 'SMS'           then 2
                                                    when P.FamilyCode = 'VEL'           then 3
                                                    when P.FamilyCode = 'EGS'           then 5
                                                    when P.FamilyCode = 'ALW'           then 6
                                                    when P.FamilyCode in ('REI','ERE')  then 7
                                                    when P.FamilyCode = 'DCN'           then 8
                                                    when P.FamilyCode = 'CLD'           then 9
                                                    else @IPI_SeparateInvoiceGroupNumber
                                                end)
         ---> This update is Price version agnostic
        ---------------------------------
        --4. LeadDays
        Update C
        set    C.LeadDays = (Case when C.Chargetypecode = 'ILF' then 1000
                                  when C.Frequencycode  = 'OT'  then 2000
                                  else @IPI_LeadDays
                             end), 
               C.ModifiedByIDSeq = @IPBI_UserIDSeq,
               C.ModifiedDate    = @LDT_SystemDate,
               C.SystemLogDate   = @LDT_SystemDate
        from   Products.dbo.Charge  C with (nolock)
        inner join Products.dbo.Product P with (nolock)
        on    C.ProductCode     = P.Code
        and   C.PriceVersion    = P.PriceVersion
        and   C.ProductCode     = @IPVC_ProductCode 
        and   C.ChargeTypeCode  = @IPC_ChargeTypeCode 
        and   C.MeasureCode	= @IPC_MeasureCode
        and   C.FrequencyCode   = @IPC_FrequencyCode
        and   C.LeadDays <> (Case when C.Chargetypecode = 'ILF' then 1000
                                  when C.Frequencycode  = 'OT'  then 2000
                                  else @IPI_LeadDays
                             end) ---> This update is Price version agnostic         
        -----------------------------------------------------------------------
        --5. PriceCapEnabledFlag
        Update P
        set    P.PriceCapEnabledFlag = 1,
               P.ModifiedByIDSeq = @IPBI_UserIDSeq,
               P.ModifiedDate    = @LDT_SystemDate,
               P.SystemLogDate   = @LDT_SystemDate
        from   Products.dbo.Charge C with (nolock)
        inner join
              Products.dbo.Product P with (nolock)
        on     C.Productcode = P.Code
        and    C.Priceversion= P.Priceversion
        and    C.FrequencyCode in ('YR','MN')	
        and    C.ProductCode     = @IPVC_ProductCode 
        and    P.PriceCapEnabledFlag <> 1
        ----------------------------------------------------------------------------------------------------------------------------
        --6.Interim solution Domin-8 PrePaid
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
        --7.Interim solution Domin-8 PrePaid
        Update  C
        set     C.LeadDays = (Case when C.ChargeTypecode = 'ILF' then 1000 else 2000 end)
               ,C.QuantityEnabledFlag = (Case when C.MeasureCode = 'TRAN' then 0
                                              when C.MeasureCode <> 'TRAN' and C.FrequencyCode = 'OT' then 1
                                              else 1
                                         end)
               ,C.SRSDisplayQuantityFlag = 1
               ,C.QuantityMultiplierFlag = 1
               ,C.MarkAsPrintedFlag      = 1
        from   Products.dbo.Charge C with (nolock) 
        inner join
               Products.dbo.Product P with (nolock)
        on     C.Productcode =P.Code
        and    C.Priceversion=P.Priceversion
        and    P.FamilyCode in ('DMN','DCN')
        where  P.FamilyCode in ('DMN','DCN')
        and    P.PrePaidFlag = 1;
      ---------------------------------------------------------------------------------------------------------------------------- 
  END  
	IF(@0PLC_RetVal='Edit')
	BEGIN
		Declare @LPVC_ChargeId Varchar(20)
		Select	@LPVC_ChargeId =( select top 1 ChargeIDSeq from charge 
		where	productCode=@IPVC_ProductCode 
			and ChargeTypeCode =@IPC_CHARgeTypeCode 
			and PriceVersion=@IPN_PriceVersion and MeasureCode=@IPC_MeasureCode  and FrequencyCode=@IPC_FrequencyCode)
 		Update Charge Set DisplayType='BOTH' where ChargeIdSeq=@LPVC_ChargeId

	END
  -----------------------------
  UPDATE Products.dbo.Product 
  SET    ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate
  WHERE   Code         =@IPVC_ProductCode 
  AND     PriceVersion =@IPN_PriceVersion
  -----------------------------------------------------------------------		
  SELECT @0PLC_RetVal AS res,@0PLC_RetMsg AS msg
END
GO
