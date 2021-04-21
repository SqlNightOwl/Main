SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [reports].[uspPRODUCTS_Rep_GetProductsSummary] (@IPVC_GROUPID varchar(20))
AS
BEGIN
  ------------------------------------------------------------------------------------------------------
  set nocount on
  -- Declare Local Variables
  declare @LVC_UNITS_GREATER_THAN_100 varchar(10)
  declare @LI_CustomBundleFlag        int
  declare @LVC_CustomBundleName       varchar(255)
  declare @LVC_BundleCode             varchar(2)
  declare @LI_StudentLivingFlag       int
  declare @LVC_CompanyIDSeq           varchar(50)
  declare @LVC_CustomBundlesProductBreakDownTypeCode varchar(50)
  declare @LVC_GroupType              varchar(70)
  -------------------------------------------------
  declare @LT_QuoteProducts table
                           (SEQ                    int  not null identity(1,1),                            
                            unitsgreaterthan100    varchar(50) NOT NULL Default 'YES',                                              
                            ProductCode            varchar(255),
                            DisplayName            varchar(255),
                            ProdProductCode        varchar(255),
                            ProdProductDisplayName varchar(255),                                
                            FrequencyCode          varchar(50),
                            Billing                varchar(50),
                            MeasureCode            varchar(50),
                            Measure                varchar(50),    
                            ACSCreditCardPercentageEnabledFlag  int           not null DEFAULT 0,
                            ACSCredtCardPricingPercentage       numeric(30,2) not null DEFAULT 0.00,    
                            ILFCreditCardPercentageEnabledFlag  int           not null DEFAULT 0,
                            ILFCredtCardPricingPercentage       numeric(30,2) not null DEFAULT 0.00,                         
                            Quantity               numeric(30,2) NOT NULL DEFAULT 0,
                            AccessAmount           numeric(30,5) NOT NULL DEFAULT 0.00,
                            ILFAmount              numeric(30,5) NOT NULL DEFAULT 0.00,                            
                            ILFUnitBasis           decimal(30,5) NOT NULL DEFAULT 1,
                            BundleCode             varchar(2),
                            AdjustedILFAmount      as  (case when unitsgreaterthan100 = 'NO'  
                                                               and  MeasureCode = 'UNIT'
                                                               and  substring(ltrim(rtrim(ProdProductCode)),9,3) <> 'SCR'
                                                             then ILFAmount / (case when ILFUnitBasis=0 then 1 else ILFUnitBasis end)
                                                          else ILFAmount
                                                      end)
 
                            )
  ------------------------------------------------------------------------------------------------------
  /*
  ---This is Original logic as of 05/04/2007.
  if exists (select top 1 P.units from customers.dbo.property P with (nolock)
             inner join quotes.dbo.groupproperties GP with (nolock)
             on P.IDSeq = GP.PropertyIDSeq
             and  GP.GroupIDSeq = @IPVC_GROUPID
             and P.units > 100)
  begin
    select @LVC_UNITS_GREATER_THAN_100 = 'YES'
  end
  else
  begin
    select @LVC_UNITS_GREATER_THAN_100 = 'NO'
  end
  */
  --Changed logic as of 05/04/2007 per discussion with Hetal.
  -- PriceTypeCode= Normal takes precedence to Small
  -- in a case where there are a mixture of Normal and Small Sites in a Bundle,
  ---when ILF($) is shown for a bundle in Order form
  if exists (select top 1 1 
             from  Quotes.dbo.groupproperties GP with (nolock)
             where GP.GroupIDSeq = @IPVC_GROUPID
             and   GP.PriceTypeCode = 'Normal'
             )
  begin
    select @LVC_UNITS_GREATER_THAN_100 = 'YES'
  end
  else
  begin
    select @LVC_UNITS_GREATER_THAN_100 = 'NO'
  end

  if exists (select top 1 1 
             from Quotes.dbo.groupproperties GP with (nolock)
             where GP.GroupIDSeq = @IPVC_GROUPID
             and exists (select top 1 1 from
                         Customers.dbo.Property P with (nolock)
                         where P.StudentlivingFlag = 1
                         and   GP.PropertyIDSeq = P.IDSeq
                        )
            )
  begin
    select @LI_StudentLivingFlag = 1
  end
  else
  begin
    select @LI_StudentLivingFlag = 0
  end
  ----------------------------------------------------
  if exists(select top 1 1 from Quotes.dbo.[Group] G with (nolock)
            where  G.IDSeq = @IPVC_GROUPID
            and    G.CustomBundleNameEnabledFlag=1
           )
  begin
    select Top 1 @LVC_CompanyIDSeq     = G.customeridseq,
                 @LI_CustomBundleFlag  = 1,
                 @LVC_CustomBundleName = G.[Name],
                 @LVC_BundleCode       = 'CB'
    from   Quotes.dbo.[Group] G with (nolock)
    where  G.IDSeq = @IPVC_GROUPID
    and    G.CustomBundleNameEnabledFlag=1

    select @LVC_CustomBundlesProductBreakDownTypeCode = C.CustomBundlesProductBreakDownTypeCode
    from   CUSTOMERS.dbo.Company C with (nolock)
    where  C.IDSeq = @LVC_CompanyIDSeq
  end
  else
  begin
    select @LI_CustomBundleFlag=0,@LVC_CustomBundleName ='',@LVC_BundleCode= 'PR'
  end

  select @LVC_GroupType=GroupType from Quotes.dbo.[group] with (nolock) where IDSeq=@IPVC_GROUPID
  ------------------------------------------------------------------------------------------------------
  insert into @LT_QuoteProducts(unitsgreaterthan100,
                                ProductCode,DisplayName,ProdProductCode,ProdProductDisplayName,
                                FrequencyCode,Billing,MeasureCode,Measure,
                                Quantity,accessAmount,ILFAmount,ILFUnitBasis,BundleCode,
                                ACSCreditCardPercentageEnabledFlag,ACSCredtCardPricingPercentage,
                                ILFCreditCardPercentageEnabledFlag,ILFCredtCardPricingPercentage
                               )
  select distinct
         @LVC_UNITS_GREATER_THAN_100                    as unitsgreaterthan100,         
         (case when (@LI_CustomBundleFlag=1)
                   then ''
               else  QACS.productcode
          end
         )                                              as ProductCode,
         (case when (@LI_CustomBundleFlag=1)
                   then @LVC_CustomBundleName
               else  P.displayname
          end
         )                                              as DisplayName,
         QACS.productcode                               as ProdProductCode,
         P.displayname                                  as ProdProductDisplayName,
         QACS.FrequencyCode                             as FrequencyCode,
         (case when (P.CategoryCode = 'PAY' and
                     QACS.MeasureCode='TRAN')
                 then ''
               when (P.CategoryCode = 'PAY' and
                     CACS.SRSDisplayQuantityFlag=0)
                 then ''
               when (CACS.measurecode='TRAN' and CACS.FrequencyCode = 'OT') then 'Per Occurrence'
              else ltrim(rtrim(FR.Name))      
         end)                                           as Billing,                    
         (case when ((QACS.MeasureCode = 'UNIT')      and
                     (@LI_StudentLivingFlag = 1)      and
                     (CACS.PriceByBedEnabledFlag = 1)
                    )  then 'Bed'
                  else QACS.MeasureCode
             end
           )                                            as MeasureCode,                
         (case when ((QACS.MeasureCode = 'UNIT')      and
                     (@LI_StudentLivingFlag = 1)      and
                     (CACS.PriceByBedEnabledFlag = 1)
                    )  then 'Bed'
                  when (@LVC_GroupType = 'PMC' and QACS.MeasureCode = 'SITE')
                       then 'PMC'
                  else ltrim(rtrim(M.Name)) 
             end
          )                                             as Measure,
         (case when CACS.SRSDisplayQuantityFlag=0 then 0
              else coalesce(QACS.Quantity,0) 
          end)                                          as Quantity,
         coalesce(QACS.NetChargeAmount,0)               as accessAmount,
         coalesce(QILF.NetChargeAmount,0)               as ILFAmount,         
         coalesce(CILF.UnitBasis,1)                     as ILFUnitBasis,
         @LVC_BundleCode                                as BundleCode,
         coalesce(CACS.CreditCardPercentageEnabledFlag,0)
                                                        as ACSCreditCardPercentageEnabledFlag,
         coalesce(QACS.CredtCardPricingPercentage,
                  CACS.CredtCardPricingPercentage,0  
                 )                                      as ACSCredtCardPricingPercentage,
         coalesce(CILF.CreditCardPercentageEnabledFlag,0)
                                                        as ILFCreditCardPercentageEnabledFlag,
         coalesce(QILF.CredtCardPricingPercentage,
                  CILF.CredtCardPricingPercentage,0  
                 )                                      as ILFCredtCardPricingPercentage
    from    PRODUCTS.dbo.Product P with (nolock)
    inner join
            PRODUCTS.dbo.Family F  with (nolock)
    on      P.FamilyCode = F.Code  
    inner join 
            Quotes.dbo.Quoteitem QACS with (nolock)
    on      QACS.GroupIDSeq     = @IPVC_GROUPID
    and     QACS.ProductCode    = P.Code
    and     QACS.PriceVersion   = P.PriceVersion    
    and     QACS.ChargeTypeCode = 'ACS'   
    inner join
            Products.dbo.Charge CACS with (nolock)
    on      P.Code              = CACS.ProductCode
    and     P.PriceVersion      = CACS.PriceVersion
    and     QACS.ProductCode    = CACS.ProductCode
    and     QACS.PriceVersion   = CACS.PriceVersion               
    and     QACS.measurecode    = CACS.measurecode
    and     QACS.Frequencycode  = CACS.Frequencycode
    and     QACS.ChargeTypeCode = CACS.ChargeTypeCode
    and     CACS.ChargeTypeCode = 'ACS' 
    inner join 
           PRODUCTS.dbo.Measure M  with (nolock)
    ON     QACS.MeasureCode    = M.Code         
    inner join  PRODUCTS.dbo.Frequency FR with (nolock)
    ON     QACS.FrequencyCode  = FR.Code        
    left outer join 
           Quotes.dbo.Quoteitem QILF with (nolock)
    on     QILF.GroupIDSeq     = @IPVC_GROUPID
    and    QILF.ProductCode    = QACS.ProductCode
    and    QILF.PriceVersion   = QACS.PriceVersion
    and    QILF.ProductCode    = P.Code 
    and    QILF.PriceVersion   = P.PriceVersion    
    and    QILF.ChargeTypeCode = 'ILF'    
    left outer join 
           Products.dbo.Charge CILF with (nolock)
    on     P.Code              = CILF.ProductCode
    and    P.PriceVersion      = CILF.PriceVersion    
    and    CILF.ChargeTypeCode = 'ILF'
    and    CACS.ProductCode    = CILF.ProductCode
    and    CACS.PriceVersion   = CILF.PriceVersion
    and    QILF.ProductCode    = CILF.ProductCode
    and    QILF.measurecode    = CILF.measurecode
    and    QILF.Frequencycode  = CILF.Frequencycode
    and    QILF.ChargeTypeCode = CILF.ChargeTypeCode
  ------------------------------------------------------------------------------------------------------
  insert into @LT_QuoteProducts(unitsgreaterthan100,
                                ProductCode,DisplayName,ProdProductCode,ProdProductDisplayName,
                                FrequencyCode,Billing,MeasureCode,Measure,
                                Quantity,accessAmount,ILFAmount,ILFUnitBasis,BundleCode,
                                ACSCreditCardPercentageEnabledFlag,ACSCredtCardPricingPercentage,
                                ILFCreditCardPercentageEnabledFlag,ILFCredtCardPricingPercentage
                               )
  select distinct
         @LVC_UNITS_GREATER_THAN_100                    as unitsgreaterthan100,
         (case when (@LI_CustomBundleFlag=1)
                   then ''
               else  QILF.productcode
          end
         )                                              as ProductCode,
         (case when (@LI_CustomBundleFlag=1)
                   then @LVC_CustomBundleName
               else  P.displayname
          end
         )                                              as DisplayName,
         QILF.productcode                               as ProdProductCode,
         P.displayname                                  as ProdProductDisplayName,
         QILF.FrequencyCode                             as FrequencyCode,
         (case when (P.CategoryCode = 'PAY' and
                     QILF.MeasureCode='TRAN')               
                 then ''
               when (P.CategoryCode = 'PAY' and
                     CILF.SRSDisplayQuantityFlag=0)
                 then ''
               when (CILF.measurecode='TRAN' and CILF.FrequencyCode = 'OT') then 'Per Occurrence'
              else ltrim(rtrim(FR.Name))      
         end)                                           as Billing,
         (case when  ((QILF.MeasureCode = 'UNIT') and
                      (@LI_StudentLivingFlag = 1) and
                      (CILF.PriceByBedEnabledFlag = 1)
                     )  then 'Bed'
                  else QILF.MeasureCode
             end
           )                                            as MeasureCode,                
         (case when  ( (QILF.MeasureCode = 'UNIT') and
                       (@LI_StudentLivingFlag = 1) and
                       (CILF.PriceByBedEnabledFlag = 1)
                     )  then 'Bed'
                  when (@LVC_GroupType = 'PMC' and QILF.MeasureCode = 'SITE')
                       then 'PMC'
                  else ltrim(rtrim(M.Name)) 
             end
           )                                            as Measure,
         (case when CILF.SRSDisplayQuantityFlag=0 then 0
              else coalesce(QILF.Quantity,0)  
          end)                                          as Quantity,
         0.00                                           as accessAmount,
         coalesce(QILF.NetChargeAmount,0)               as ILFAmount,         
         coalesce(CILF.UnitBasis,1)                     as ILFUnitBasis,
         @LVC_BundleCode                                as BundleCode,
         0                                              as CreditCardPercentageEnabledFlag,
         0                                              as CredtCardPricingPercentage,
         coalesce(CILF.CreditCardPercentageEnabledFlag,0)
                                                        as ILFCreditCardPercentageEnabledFlag,
         coalesce(QILF.CredtCardPricingPercentage,
                  CILF.CredtCardPricingPercentage,0  
                 )                                      as ILFCredtCardPricingPercentage

    from    PRODUCTS.dbo.Product P with (nolock)
    inner join
            PRODUCTS.dbo.Family F  with (nolock)
    on      P.FamilyCode = F.Code  
    and  not exists (select TOP 1 X.ProductCode as ProductCode
                     from   @LT_QuoteProducts X
                     where  X.ProdProductCode = P.Code
                    )
    inner join 
           Quotes.dbo.Quoteitem QILF with (nolock)
    on     QILF.GroupIDSeq     = @IPVC_GROUPID
    and    QILF.ProductCode    = P.code
    and    QILF.PriceVersion   = P.PriceVersion    
    and    QILF.ChargeTypeCode = 'ILF'        
    and  not exists (select TOP 1 X.ProductCode as ProductCode
                     from   @LT_QuoteProducts X
                     where  QILF.ProductCode = X.productcode                   
                    )
    inner join
           Products.dbo.Charge CILF with (nolock)
    on     P.Code              = CILF.ProductCode
    and    P.PriceVersion      = CILF.PriceVersion 
    and    QILF.PriceVersion   = CILF.PriceVersion  
    and    CILF.ChargeTypeCode = 'ILF'  
    and    QILF.ProductCode    = CILF.ProductCode
    and    QILF.measurecode    = CILF.measurecode
    and    QILF.Frequencycode  = CILF.Frequencycode
    and    QILF.ChargeTypeCode = CILF.ChargeTypeCode  
    inner join 
           PRODUCTS.dbo.Measure M with (nolock)
    ON     QILF.MeasureCode = M.Code    
    inner join  PRODUCTS.dbo.Frequency FR with (nolock)
    ON     QILF.FrequencyCode = FR.Code  


  ------------------------------------------------------------------------------------------------------  
  --select * from @LT_QuoteProducts where productcode = 'DMD-OSD-ACT-ACT-AOAC'                           
  ------------------------------------------------------------------------------------------------------  
  ---FINAL SELECT     
  ------------------------------------------------------------------------------------------------------
  if (@LI_CustomBundleFlag=1)
  begin
    declare @LT_FinalResults table (seq            int not null identity(1,1),
                                    ProductCode    varchar(255),
                                    ProductName    varchar(255),
                                    FrequencyCode  varchar(50),
                                    Billing        varchar(100),
                                    MeasureCode    varchar(50),
                                    Measure        varchar(100),
                                    Quantity       varchar(100),
                                    AccessAmount   varchar(100),
                                    ILFAmount      varchar(100),
                                    BundleCode     varchar(2)                                    
                                    )
    
    Insert into @LT_FinalResults(ProductCode,ProductName,FrequencyCode,Billing,MeasureCode,Measure,
                                 Quantity,AccessAmount,ILFAmount,BundleCode)
    select A.ProductCode               as ProductCode,
           A.DisplayName               as ProductName,
           A.FrequencyCode             as FrequencyCode,
           A.Billing                   as Billing,
           A.MeasureCode               as MeasureCode,
           A.Measure                   as Measure,
           case when
                   substring(convert(varchar(100),sum(distinct A.Quantity)),
                             patindex('%.%',convert(varchar(100),sum(distinct A.Quantity))) + 1,
                             len(convert(varchar(100),sum(distinct A.Quantity)))) > 0
                  then Products.dbo.fn_formatCurrency(sum(distinct A.Quantity),1,3)
                else   Products.dbo.fn_formatCurrency(sum(distinct A.Quantity),0,0)
           end                                                          as Quantity,  
           (case when max(A.ACSCreditCardPercentageEnabledFlag)=1
                    then convert(varchar(50),max(A.ACSCredtCardPricingPercentage)) + 
                         '% + ' + Products.dbo.fn_formatCurrency(sum(A.AccessAmount),1,3)                 
                 else Products.dbo.fn_formatCurrency(sum(A.AccessAmount),1,3)
            end)                                                        as AccessAmount,
           (case when max(A.ILFCreditCardPercentageEnabledFlag)=1
                    then convert(varchar(50),max(A.ILFCredtCardPricingPercentage)) + 
                         '% + ' + Products.dbo.fn_formatCurrency(sum(A.AdjustedILFAmount),1,3)                
                 else Products.dbo.fn_formatCurrency(sum(A.AdjustedILFAmount),1,3)
            end)                                                       as ILFAmount,
           A.BundleCode                                                as BundleCode
    from @LT_QuoteProducts A
    group by A.ProductCode,A.DisplayName,A.FrequencyCode,A.Billing,A.MeasureCode,A.Measure,A.BundleCode
    order by A.DisplayName asc,A.Billing asc,A.Measure asc
     
    -----------------------------------------------------------------------------------
    if @LVC_CustomBundlesProductBreakDownTypeCode = 'YEBR'
    begin
      Insert into @LT_FinalResults(ProductCode,ProductName,FrequencyCode,Billing,MeasureCode,Measure,Quantity,AccessAmount,ILFAmount,BundleCode)
      select 
             A.ProdProductCode as ProductCode,A.ProdProductDisplayName as ProductName,
             A.FrequencyCode as FrequencyCode,
             A.Billing as Billing,A.MeasureCode,A.Measure as  Measure,0 as Quantity,'' as AccessAmount,'' as ILFAmount,
             'PC'  as BundleCode
      from   @LT_QuoteProducts A
      order by A.ProdProductDisplayName asc,A.Billing asc,A.Measure asc,A.BundleCode asc
    end
    ------------------------------------------------
    ---Final Select for  @LI_CustomBundleFlag = 1
    ------------------------------------------------
    select A.ProductCode               as ProductCode,
           A.ProductName               as ProductName,
           A.Billing                   as Billing,
           A.Measure                   as Measure,
           A.Quantity                  as Quantity,
           A.AccessAmount              as AccessAmount,
           A.ILFAmount                 as ILFAmount,
           A.BundleCode                as BundleCode
    from   @LT_FinalResults A
    order  by A.seq, A.BundleCode
  end
  else 
  begin
    ------------------------------------------------
    ---Final Select for  @LI_CustomBundleFlag = 0
    ------------------------------------------------
    select A.ProductCode               as ProductCode,
           A.DisplayName               as ProductName,
           A.Billing                   as Billing,
           A.Measure                   as Measure,
           case when
                   substring(convert(varchar(100),sum(distinct A.Quantity)),
                             patindex('%.%',convert(varchar(100),sum(distinct A.Quantity))) + 1,
                             len(convert(varchar(100),sum(distinct A.Quantity)))) > 0
                  then Products.dbo.fn_formatCurrency(sum(distinct A.Quantity),1,3)
                else   Products.dbo.fn_formatCurrency(sum(distinct A.Quantity),0,0)
           end                                                          as Quantity,
           (case when max(A.ACSCreditCardPercentageEnabledFlag)=1
                    then convert(varchar(50),max(A.ACSCredtCardPricingPercentage)) + 
                         '% + ' + Products.dbo.fn_formatCurrency(sum(A.AccessAmount),1,3)                 
                 else Products.dbo.fn_formatCurrency(sum(A.AccessAmount),1,3)
            end)                                                        as AccessAmount,
           (case when max(A.ILFCreditCardPercentageEnabledFlag)=1
                    then convert(varchar(50),max(A.ILFCredtCardPricingPercentage)) + 
                         '% + ' + Products.dbo.fn_formatCurrency(sum(A.AdjustedILFAmount),1,3)                
                 else Products.dbo.fn_formatCurrency(sum(A.AdjustedILFAmount),1,3)
            end)                                                       as ILFAmount,
           A.BundleCode                as BundleCode
    from @LT_QuoteProducts A
    group by A.ProductCode,A.DisplayName,A.FrequencyCode,A.Billing,A.MeasureCode,A.Measure,A.BundleCode
    order by A.DisplayName asc
  end  
  ------------------------------------------------------------------------------------------------------ 
END
GO
