SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : PRODUCTS
-- Procedure Name  : [uspPRODUCTS_ChargeUpdate]
-- Description     : This procedure inserts ProductCode,PriceVersion,ChargeTypeCode,
--                      MeasureCode,FrequencyCode,DisplayType, ChargeAmount, MinUnits ,
--                      MaxUnits, MinThresholdOverride, MaxThresholdOverride, StartDate,
--                      EndDate, RevenueTierCode,RevenueAccountCode,DeferredRevenueAccountCode,
--                      TaxwareCode,QuantityEnabledFlag, QuantityMultiplierFlag, CreatedBy,
--                      CreateDate 
 
--
-- Revision History:
-- Author          : Raghavender
-- 11/11/2008      : Stored Procedure Created.
-- 02/18/2010      : Naval Kishore Modified Stored Procedure to set @IPB_DisabledFlag.
-- 11/04/2011      : TFS 1514
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [products].[uspPRODUCTS_ChargeUpdate] (				
                                                   @IPVC_ProductCode					VARCHAR(30),                    
                                                   @IPN_PriceVersion					NUMERIC(18,0),                            
                                                   @IPC_ChargeTypeCode					CHAR(3), 
                                                   @IPC_MeasureCode					CHAR(6), 
                                                   @IPC_FrequencyCode					CHAR(6), 
                                                   @IPVC_SiebelProductID				VARCHAR(30), 
                                                   @IPM_ChargeAmount					MONEY,          
                                                   @IPI_MinUnits					INT,    
                                                   @IPI_MaxUnits					INT,    
                                                   @IPD_UnitBasis					DECIMAL(18,5),
                                                   @IPB_FlatPriceFlag					BIT, 
                                                   @IPM_DollarMinimum					MONEY,         
                                                   @IPB_DollarMinimumEnabledFlag		        BIT, 
                                                   @IPM_DollarMaximum					MONEY,         
                                                   @IPB_DollarMaximumEnabledFlag		        BIT, 
                                                   @IPB_MinThresholdOverrideFlag		        BIT, 
                                                   @IPB_MaxThresholdOverrideFlag		        BIT, 
                                                   @IPN_DiscountMaxPercent				NUMERIC(30,5),                      
                                                   @IPN_CommissionMaxPercent			        NUMERIC(30,5),                    
                                                   @IPB_QuantityEnabledFlag			        BIT, 
                                                   @IPB_QuantityMultiplierFlag			        BIT, 
                                                   @IPB_PriceByPPUPercentageEnabledFlag                 BIT, 
                                                   @IPB_PriceByBedEnabledFlag			        BIT, 
                                                   @IPVC_DisplayType					VARCHAR(50),                                        
                                                   @IPB_DisabledFlag					BIT,                                                   
                                                   @IPVC_RevenueTierCode				VARCHAR(30)='',                
                                                   @IPVC_RevenueAccountCode			        VARCHAR(32)='',               
                                                   @IPVC_DeferredRevenueAccountCode	                VARCHAR(32)='',       
                                                   @IPVC_TaxwareCode					VARCHAR(20)='',          
                                                   @IPVC_RevenueRecognitionCode		                VARCHAR(3), 
                                                   @IPB_SRSDisplayQuantityFlag			        BIT, 
                                                   @IPB_CreditCardPercentageEnabledFlag                 BIT, 
                                                   @IPI_CredtCardPricingPercentage		        NUMERIC(30,3),             
                                                   @IPI_SeparateInvoiceGroupNumber		        bigint, 
                                                   @IPB_ExplodeQuantityatOrderFlag		        BIT, 
                                                   @IPB_MarkAsPrintedFlag				BIT, 
                                                   @IPB_CrossFireCallPricingEnabledFlag                 BIT, 
                                                   @IPVC_MPFPublicationName			        VARCHAR(100),             
                                                   @IPVC_ReportCategoryName			        VARCHAR(100),                                                                                   
                                                   @IPVC_ReportSubcategoryName1		                VARCHAR(100),                                                                               
                                                   @IPVC_ReportSubcategoryName2		                VARCHAR(100),                                                                               
                                                   @IPVC_ReportSubcategoryName3		                VARCHAR(100),
                                                   @IPI_ChargeIDSeq					BIGINT,
                                                   @IPDT_StartDate					DATETIME,
                                                   @IPB_DisplayTransactionalProductPriceOnInvoiceFlag   BIT =1,
                                                   @IPI_LeadDays                                        INT,
                                                   @IPB_ChargeEnabler                                   BIT,
                                                   @IPB_ProrateFirstMonthFlag                           BIT = 0,
                                                   @IPB_AllowLongerContractFlag                         BIT = 0,
                                                   @IPB_ValidateSiteMasterIDFlag                        BIT = 0,
                                                   @IPBI_UserIDSeq                                      bigint  --> This is UserID of person logged on (Mandatory) 
                                                   )     
AS
BEGIN 
  set nocount on;
  ----------------------------
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

  Exec uspPRODUCTS_ChargeEditValidateCombinations @IPVC_ProductCode,@IPN_PriceVersion,@IPC_ChargeTypeCode,@IPC_MeasureCode,@IPC_FrequencyCode,@IPVC_DisplayType,@IPI_ChargeIDSeq ,@0PLC_RetVal output,@0PLC_RetMsg output
  IF(@0PLC_RetVal='Success')
  BEGIN
    if exists (select top 1 1 
               from   Products.dbo.Product P with (nolock)
               where  P.Code         =  @IPVC_ProductCode                    
               and    P.PriceVersion =  @IPN_PriceVersion
               and    P.PendingApprovalFlag = 1
              )
    begin
      ---If the product is still in PendingApprovalFlag state, keep the corresponding Charge records Disabled
      -- until it is Activated by Action-->Activate by the product administrator.
      select @IPB_DisabledFlag = 1
    end


    UPDATE  Products.dbo.Charge
    SET
            SiebelProductID					=		@IPVC_SiebelProductID, 
            ChargeAmount					=		@IPM_ChargeAmount,          
            MinUnits						=		@IPI_MinUnits,    
            MaxUnits						=		@IPI_MaxUnits,    
            UnitBasis						=		(case when @IPD_UnitBasis <= 0 then 1 else @IPD_UnitBasis end),
            FlatPriceFlag					=		@IPB_FlatPriceFlag, 
            DollarMinimum					=		@IPM_DollarMinimum,         
            DollarMinimumEnabledFlag		                =		@IPB_DollarMinimumEnabledFlag, 
            DollarMaximum					=		@IPM_DollarMaximum,         
            DollarMaximumEnabledFlag		                =		@IPB_DollarMaximumEnabledFlag, 
            MinThresholdOverride			        =		(case when convert(int,@IPB_FlatPriceFlag) = 1 then 1 else @IPB_MinThresholdOverrideFlag end), 
            MaxThresholdOverride			        =		(case when convert(int,@IPB_FlatPriceFlag) = 1 then 1 else @IPB_MaxThresholdOverrideFlag end), 
            DiscountMaxPercent				        =		@IPN_DiscountMaxPercent,                      
            CommissionMaxPercent			        =		@IPN_CommissionMaxPercent,                    
            QuantityEnabledFlag				        =		@IPB_QuantityEnabledFlag, 
            QuantityMultiplierFlag			        =		@IPB_QuantityMultiplierFlag, 
            PriceByPPUPercentageEnabledFlag                     =		@IPB_PriceByPPUPercentageEnabledFlag, 
            PriceByBedEnabledFlag			        =		@IPB_PriceByBedEnabledFlag, 
            DisplayType						=		@IPVC_DisplayType,                                        
            DisabledFlag					=		@IPB_DisabledFlag,            
            StartDate						=		@IPDT_StartDate,           
            RevenueTierCode					=		@IPVC_RevenueTierCode,                
            RevenueAccountCode				        =		@IPVC_RevenueAccountCode,               
            DeferredRevenueAccountCode		                =		@IPVC_DeferredRevenueAccountCode,       
            TaxwareCode						=		@IPVC_TaxwareCode,          
            RevenueRecognitionCode			        =		@IPVC_RevenueRecognitionCode, 
            SRSDisplayQuantityFlag			        =		@IPB_SRSDisplayQuantityFlag, 
            CreditCardPercentageEnabledFlag	                =		@IPB_CreditCardPercentageEnabledFlag, 
            CredtCardPricingPercentage		                =		@IPI_CredtCardPricingPercentage,              
            SeparateInvoiceGroupNumber		                =		@IPI_SeparateInvoiceGroupNumber, 
            ExplodeQuantityatOrderFlag		                =		@IPB_ExplodeQuantityatOrderFlag, 
            MarkAsPrintedFlag				        =		@IPB_MarkAsPrintedFlag, 
            CrossFireCallPricingEnabledFlag	                =		@IPB_CrossFireCallPricingEnabledFlag, 
            MPFPublicationName				        =		@IPVC_MPFPublicationName,             
            ReportCategoryName				        =		@IPVC_ReportCategoryName,                                                                                   
            ReportSubcategoryName1			        =		@IPVC_ReportSubcategoryName1,                                                                               
            ReportSubcategoryName2			        =		@IPVC_ReportSubcategoryName2,                                                                               
            ReportSubcategoryName3			        =		@IPVC_ReportSubcategoryName3,
            DisplayTransactionalProductPriceOnInvoiceFlag       =               (case when (Measurecode = 'TRAN')   
                                                                                        then @IPB_DisplayTransactionalProductPriceOnInvoiceFlag
                                                                                 else 0 end),
            LeadDays						=               (case when ChargeTypecode = 'ILF' then 1000
                                                                                      when FrequencyCode  = 'OT'  then 2000
                                                                                      else @IPI_LeadDays
                                                                                 end),                                   
            SystemAutoCreateEnablerFlag                         =               (case when Measurecode = 'TRAN' then @IPB_ChargeEnabler else 0 end),
            ProrateFirstMonthFlag                               =               (case when FrequencyCode in ('MN','YR') then @IPB_ProrateFirstMonthFlag else 0 end),
            AllowLongerContractFlag                             =               (case when FrequencyCode in ('MN','YR') then @IPB_AllowLongerContractFlag else 0 end),
            ValidateSiteMasterIDFlag                            =               (case when ChargeTypecode = 'ILF'  then 0
                                                                                      when ReportingTypecode = 'ANCF' then 0
                                                                                 else @IPB_ValidateSiteMasterIDFlag
                                                                                end),
            ModifiedByIDSeq                                     = @IPBI_UserIDSeq,
            ModifiedDate                                        = @LDT_SystemDate,
            SystemLogDate                                       = @LDT_SystemDate 
  WHERE       ChargeIDSeq  = @IPI_ChargeIDSeq 
  and         ProductCode  = @IPVC_ProductCode                    
  and PriceVersion         = @IPN_PriceVersion                            
  and ChargeTypeCode       = @IPC_ChargeTypeCode
  and MeasureCode	   = @IPC_MeasureCode 
  and FrequencyCode        = @IPC_FrequencyCode

  -------------------------------------------------------------------------------------------
  --UPDATE older versions of the same charge records on when the current version is an active version
  if exists (select top 1 1
             from   Products.dbo.Product P with (nolock)
             where  P.code         = @IPVC_ProductCode
             and    P.PriceVersion = @IPN_PriceVersion
             and    P.Disabledflag = 0
            )
  begin
     UPDATE Products.dbo.Charge  
     SET    RevenueTierCode                     = @IPVC_RevenueTierCode,                
	    RevenueAccountCode			= @IPVC_RevenueAccountCode,               
            DeferredRevenueAccountCode		= @IPVC_DeferredRevenueAccountCode,       
            TaxwareCode				= @IPVC_TaxwareCode,          
            RevenueRecognitionCode	        = @IPVC_RevenueRecognitionCode,            
            LeadDays                            = (case when ChargeTypecode = 'ILF' then 1000
                                                                                      when FrequencyCode  = 'OT'  then 2000
                                                                                      else @IPI_LeadDays
                                                                                 end),                
            DisplayTransactionalProductPriceOnInvoiceFlag = (case when (ltrim(rtrim(Measurecode)) = 'TRAN')   
                                                                   then @IPB_DisplayTransactionalProductPriceOnInvoiceFlag
                                                             else 0 end),
            SystemAutoCreateEnablerFlag         = (case when ltrim(rtrim(Measurecode)) = 'TRAN' then @IPB_ChargeEnabler else 0 end),
            ProrateFirstMonthFlag               = (case when ltrim(rtrim(FrequencyCode)) in ('MN','YR') then @IPB_ProrateFirstMonthFlag else 0 end),
            AllowLongerContractFlag             = (case when ltrim(rtrim(FrequencyCode)) in ('MN','YR') then @IPB_AllowLongerContractFlag else 0 end),
            ValidateSiteMasterIDFlag            = (case when ltrim(rtrim(ChargeTypeCode))     = 'ILF'  then 0
                                                        when ltrim(rtrim(ReportingTypeCode))  = 'ANCF' then 0
                                                        else @IPB_ValidateSiteMasterIDFlag
                                                   end),
            ModifiedByIDSeq                     = @IPBI_UserIDSeq,
            ModifiedDate                        = @LDT_SystemDate,
            SystemLogDate                       = @LDT_SystemDate   
     WHERE ProductCode	  = @IPVC_ProductCode 
     AND   PriceVersion	  <> @IPN_PriceVersion
     AND   ChargeTypeCode = @IPC_ChargeTypeCode 
     AND   MeasureCode	  = @IPC_MeasureCode
     AND   FrequencyCode  = @IPC_FrequencyCode
  end

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
        ---Mandatory : Update  Open Invoiceitems for Any Revenue related code changes.
        -- If DefaultTaxwareCode has changed due to charge update for taxwarecode, TaxPercent will be set to 0 for corresponding open Invoiceitem
        --  so that call of Exec Invoices.dbo. uspINVOICES_TaxableOpenInvoiceItemsSelect  will pick up for recalculating taxes.
        ---------------------------------------------------------------------------------------------------------------------------
        Update II
        set    II.RevenueAccountCode         = C.RevenueAccountCode,
               II.RevenueTierCode            = C.RevenueTierCode,
               II.DeferredRevenueAccountCode = C.DeferredRevenueAccountCode,
               II.revenuerecognitioncode     = C.revenuerecognitioncode,
               II.taxwarecode                = (Case when  (II.taxwarecode <> C.taxwarecode)
                                                       then C.taxwarecode
                                                     else II.taxwarecode
                                                end),
               II.DefaultTaxwareCode         = (Case when  (II.taxwarecode <> C.taxwarecode)
                                                       then C.taxwarecode
                                                     else II.DefaultTaxwareCode
                                                end),
               II.TaxPercent                 = (Case when  (II.taxwarecode <> C.taxwarecode)
                                                       then 0
                                                     else II.TaxPercent
                                                end)
        From   INVOICES.dbo.INVOICE I with (nolock) 
        inner Join 
               INVOICES.dbo.INVOICEITEM II with (nolock)
        on     I.InvoiceIDSeq     = II.InvoiceIDSeq 
        and    I.SentToEpicorFlag = 0 
        and    I.PrintFlag        = 0
        and    I.PrepaidFlag      = 0
        and    II.ProductCode     = @IPVC_ProductCode
        inner Join
               PRODUCTS.dbo.Charge C with (nolock)
        on     II.ProductCode    = C.ProductCode
        and    II.PriceVersion   = C.PriceVersion
        and    II.ChargeTypeCode = C.ChargeTypeCode
        and    II.MeasureCode    = C.MeasureCode
        and    II.FrequencyCode  = C.FrequencyCode
        and    II.ProductCode     = @IPVC_ProductCode 
        and    C.ProductCode      = @IPVC_ProductCode
        and   (
                (II.RevenueAccountCode <> C.RevenueAccountCode)
                   OR
                (II.RevenueTierCode    <> C.RevenueTierCode)
                   OR
                (coalesce(II.DeferredRevenueAccountCode,'')  <> coalesce(C.DeferredRevenueAccountCode,''))
                   OR
                (II.revenuerecognitioncode  <> C.revenuerecognitioncode)
                   OR
                (II.DefaultTaxwareCode      <> C.taxwarecode)
              )
        where  I.SentToEpicorFlag = 0 
        and    I.PrintFlag        = 0
        and    I.PrepaidFlag      = 0
        and    II.ProductCode     = @IPVC_ProductCode 
        and    C.ProductCode      = @IPVC_ProductCode
        and   (
                (II.RevenueAccountCode <> C.RevenueAccountCode)
                   OR
                (II.RevenueTierCode    <> C.RevenueTierCode)
                   OR
                (coalesce(II.DeferredRevenueAccountCode,'')  <> coalesce(C.DeferredRevenueAccountCode,''))
                   OR
                (II.revenuerecognitioncode  <> C.revenuerecognitioncode)
                   OR
                (II.DefaultTaxwareCode      <> C.taxwarecode)
              );  
  -------------------------------------------------------------------------------------------
  UPDATE Products.dbo.Product 
  SET    ModifiedByIDSeq = @IPBI_UserIDSeq,
         ModifiedDate    = @LDT_SystemDate,
         SystemLogDate   = @LDT_SystemDate 
  WHERE  Code         =@IPVC_ProductCode
  AND    PriceVersion =@IPN_PriceVersion
  -------------------------------------------------------------------------------------------
  END                      
  SELECT @0PLC_RetVal AS res,@0PLC_RetMsg AS msg
END -- Main END starts at Col 01
GO
