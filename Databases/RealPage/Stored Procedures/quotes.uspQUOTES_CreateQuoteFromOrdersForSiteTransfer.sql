SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [quotes].[uspQUOTES_CreateQuoteFromOrdersForSiteTransfer] (
                                                                 @IPVC_FromCompanyID    varchar(50), 
                                                                 @IPVC_FromPropertyID   varchar(50), 
                                                                 @IPVC_ToCompanyID      varchar(50), 
                                                                 @IPVC_ToPropertyID     varchar(50), 
                                                                 @IPVC_CreatedBy        varchar(70),
                                                                 @IPVC_QuoteID          varchar(50),
                                                                 @IPI_Units             int,
                                                                 @IPI_Beds              int,
                                                                 @IPI_PPUPercentage     int
                                                                )	
AS
BEGIN
  set nocount on
  ---------------------------------------------------------------------------------------
  --Declare Local Variables
  declare @LI_Min            int
  declare @LI_Max            int
  declare @LI_QuoteGroupID   bigint  
  
  declare @LVC_OrderIDSeq    varchar(50)
  declare @LBI_GroupIDSeq    bigint
  declare @LBI_QuoteItemIDSeq  bigint
 
  declare @LVC_DocumentIDSeq varchar(50)
  declare @LVC_Name          varchar(500)
  declare @LVC_Description   varchar(8000)
  ---------------------------------------------------------------------------------------
  create table #tempEligibleOrderGroups (Seq                             bigint not null identity(1,1),
                                         OrderIDSeq                      varchar(50),
                                         GroupIDSeq                      Bigint,
                                         CustomBundleNameEnabledFlag     int
                                        )
  create table #tempDocumentsForEligibleOrders (Seq                      bigint not null identity(1,1),
                                                Name                     varchar(500)  NULL,
                                                Description              varchar(8000) NULL
                                               )
  ---------------------------------------------------------------------------------------
  --Step 1 : Update New Generated Quote for @IPVC_ToCompanyID to denote it is 
  --         a quote reverse generated  from all active Orders of 
  --         @IPVC_FromCompanyID and @IPVC_FromPropertyID, Upon transfer to @IPVC_ToPropertyID
  Update QUOTES.dbo.Quote set TransferredFlag = 1
  Where  QuoteIDSeq    = @IPVC_QuoteID
  and    CustomerIDSeq = @IPVC_ToCompanyID
  ---------------------------------------------------------------------------------------
  --Step 1.1: Insert into ORDERS.dbo.SiteTransferOrderLog 
  --          This will hold a short snapshot containing statues,
  --          of all Orderitems that qualify for transfer
  --          from @IPVC_FromPropertyID to @IPVC_ToPropertyID
  Insert into ORDERS.dbo.SiteTransferOrderLog(FromOrderIDSeq,FromCompanyIDSeq,FromPropertyIDSeq,FromQuoteIDSeq,
                                             ToCompanyIDSeq,ToPropertyIDSeq,ToQuoteIDSeq,
                                             FromOrderStatusCode,FromOrderItemIDSeq,FromOrderItemStatusCode,
                                             TOCreatedBy,CreatedDate
                                            )
  select distinct O.OrderIDSeq as FromOrderIDSeq,
         @IPVC_FromCompanyID as FromCompanyIDSeq,@IPVC_FromPropertyID as FromPropertyIDSeq,
         O.Quoteidseq  as FromQuoteIDSeq,@IPVC_ToCompanyID as ToCompanyIDSeq,@IPVC_ToPropertyID as ToPropertyIDSeq,
         @IPVC_QuoteID as ToQuoteIDSeq,
         O.StatusCode  as FromOrderStatusCode,OI.IDSEQ as FromOrderItemIDSeq,
         OI.StatusCode as FromOrderItemStatusCode,
         @IPVC_CreatedBy as TOCreatedBy,getdate() as CreatedDate
  from   ORDERS.dbo.[Order]     O  with (nolock)
  inner join
         ORDERS.dbo.OrderItem OI with (nolock)
  on     O.OrderIDSeq = OI.OrderIDSeq
  and    O.CompanyIDSeq  = @IPVC_FromCompanyID
  and    O.PropertyIDSeq = @IPVC_FromPropertyID
  ---------------------------------------------------------------------------------------
  --Step 2: Get All eligible Orders and Groups pertaining to @IPVC_FromPropertyID
  --        in temp table #tempEligibleOrderGroups
  Insert into #tempEligibleOrderGroups(OrderIDSeq,GroupIDSeq,CustomBundleNameEnabledFlag)
  select distinct O.OrderIDSeq,OG.IDSeq,OG.CustomBundleNameEnabledFlag
  from   ORDERS.dbo.[Order]     O  with (nolock)
  inner join
         ORDERS.dbo.OrderGroup  OG with (nolock)
  on     O.OrderIDSeq    = OG.OrderIDSeq
  and    O.CompanyIDSeq  = @IPVC_FromCompanyID
  and    O.PropertyIDSeq = @IPVC_FromPropertyID
  and    OG.OrderGroupType = 'SITE'
  and    exists (select top 1 1
                 from   ORDERS.dbo.OrderItem OI with (nolock)
                 where  O.OrderIDSeq = OI.OrderIDSeq
                 and    OG.IDSeq     = OI.OrderGroupIDSeq
                 and ((OI.ChargeTypeCode = 'ILF' and OI.StatusCode <> 'CNCL')
                                    OR
                       (OI.ChargeTypeCode = 'ACS' and OI.ActivationEndDate IS NULL 
                        and (OI.StatusCode <> 'CNCL' or OI.StatusCode <> 'EXPD')
                       )
                                    OR
                      (OI.ChargeTypeCode = 'ACS' and 
                          convert(datetime,Convert(varchar(50),OI.ActivationEndDate,101))  >= 
                          convert(datetime,Convert(varchar(50),getdate(),101))
                       and (OI.StatusCode <> 'CNCL' or OI.StatusCode <> 'EXPD')
                      )
                     )
                 and   OI.productcode <> 'DMD-PSR-ADM-ADM-AMTF'
                 )
  Order by OG.CustomBundleNameEnabledFlag asc
  --------------------------------------------------------------------------------------- 
  --Step 3: Loop Through #tempEligibleOrderGroups and insert records in 
  ---       Quotes.dbo.Group, Quotes.dbo.GroupProperties,Quotes.dbo.Quoteitem  
  select @LI_Min = 1,@LI_Max = count(*) from #tempEligibleOrderGroups with (nolock)
  While @LI_Min <= @LI_Max
  begin
    select @LVC_OrderIDSeq = OrderIDSeq,@LBI_GroupIDSeq = GroupIDSeq
    from   #tempEligibleOrderGroups with (nolock)
    where  SEQ = @LI_Min
    ------------------------------------------------------
    ----Insert into QUOTES.dbo.[Group]
    BEGIN TRANSACTION;
    Insert into QUOTES.dbo.[Group](QuoteIDSeq,DiscAllocationCode,Name,Description,
                                   CustomerIDSeq,Sites,Units,Beds,PPUPercentage,
                                   ShowDetailPriceFlag,AllowProductCancelFlag,
                                   GroupType,CustomBundleNameEnabledFlag,
                                   TransferredFlag)
    Select distinct
           @IPVC_QuoteID as QuoteIDSeq,OG.DiscAllocationCode,OG.Name,OG.Description,
           @IPVC_ToCompanyID as CustomerIDSeq,1 as Sites,
           @IPI_Units as Units,@IPI_Beds as Beds,@IPI_PPUPercentage as PPUPercentage,
           1 as ShowDetailPriceFlag,OG.AllowProductCancelFlag,OG.OrderGroupType,
           OG.CustomBundleNameEnabledFlag,1 as TransferredFlag
    from   ORDERS.dbo.OrderGroup OG with (nolock)
    where  OG.OrderIDSeq = @LVC_OrderIDSeq
    and    OG.IDSeq      = @LBI_GroupIDSeq
    select @LI_QuoteGroupID =  SCOPE_IDENTITY() 
    COMMIT TRANSACTION; 
    ------------------------------------------------------
    ----Insert into QUOTES.dbo.[GroupProperties]  
    Insert into QUOTES.dbo.GroupProperties(QuoteIDSeq,GroupIDSeq,PropertyIDSeq,CustomerIDSeq,
                                           PriceTypeCode,ThresholdOverrideFlag,
                                           Units,Beds,PPUPercentage,TransferredFlag)
    select distinct 
           @IPVC_QuoteID as QuoteIDSeq,@LI_QuoteGroupID as GroupIDSeq,
           @IPVC_ToPropertyID as PropertyIDSeq,@IPVC_ToCompanyID as CustomerIDSeq,
           OGP.PriceTypeCode,OGP.ThresholdOverrideFlag,
           @IPI_Units as Units,@IPI_Beds as Beds,@IPI_PPUPercentage as PPUPercentage,
           1 as TransferredFlag
    from   ORDERS.dbo.OrderGroupProperties OGP with (nolock)
    where  OGP.OrderIDSeq        = @LVC_OrderIDSeq
    and    OGP.OrderGroupIDSeq   = @LBI_GroupIDSeq
    and    OGP.CompanyIDSeq      = @IPVC_FromCompanyID
    and    OGP.PropertyIDSeq     = @IPVC_FromPropertyID
    ------------------------------------------------------
    ----Insert into QUOTES.dbo.QuoteItem
    Insert into QUOTES.dbo.QuoteItem(QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,
                                     FamilyCode,PublicationYear,PublicationQuarter,AllowProductCancelFlag,PriceVersion,
                                     Sites,Units,Beds,PPUPercentage,Quantity,MinUnits,MaxUnits,
                                     ChargeAmount,DiscountPercent,
                                     TotalDiscountPercent,
                                     NetChargeAmount,NetExtChargeAmount,
                                     CapMaxUnitsFlag,DollarMinimum,DollarMaximum,credtcardpricingpercentage,
                                     excludeforbookingsflag,crossfiremaximumallowablecallvolume)
    select distinct 
           @IPVC_QuoteID as QuoteIDSeq,@LI_QuoteGroupID as GroupIDSeq,
           OI.ProductCode,OI.ChargeTypeCode,OI.FrequencyCode,OI.MeasureCode,
           OI.FamilyCode,OI.PublicationYear,OI.PublicationQuarter,OI.AllowProductCancelFlag,OI.PriceVersion,
           1 as Sites,@IPI_Units as Units,@IPI_Beds as Beds,@IPI_PPUPercentage as PPUPercentage,
           OI.Quantity,OI.MinUnits,OI.MaxUnits,
           OI.ChargeAmount,
           (CASE when (OI.ChargeTypeCode = 'ILF'  
                       and OI.LastBillingPeriodFromDate is not null and OI.LastBillingPeriodToDate is not null) 
                    then 100
                 else OI.DiscountPercent
            end) as DiscountPercent,           
           (CASE when (OI.ChargeTypeCode = 'ILF' 
                       and OI.LastBillingPeriodFromDate is not null and OI.LastBillingPeriodToDate is not null)
                    then 100
                 else OI.TotalDiscountPercent
            end) as TotalDiscountPercent,           
           (CASE when (OI.ChargeTypeCode = 'ILF' 
                       and OI.LastBillingPeriodFromDate is not null and OI.LastBillingPeriodToDate is not null)
                   then 0.00
                 else (OI.NetChargeAmount)/(Case when OI.effectiveQuantity = 0 then 1 else OI.effectiveQuantity end)
            end) as NetChargeAmount,  
           (CASE when (OI.ChargeTypeCode = 'ILF' 
                       and OI.LastBillingPeriodFromDate is not null and OI.LastBillingPeriodToDate is not null)
                   then 0.00
                 else OI.NetChargeAmount
            end) as NetExtChargeAmount, 
           OI.CapMaxUnitsFlag,OI.DollarMinimum,OI.DollarMaximum,OI.credtcardpricingpercentage,
           OI.excludeforbookingsflag,OI.crossfiremaximumallowablecallvolume
    from  ORDERS.dbo.OrderItem OI with (nolock)
    where OI.OrderIDSeq        = @LVC_OrderIDSeq
    and   OI.OrderGroupIDSeq   = @LBI_GroupIDSeq       
    and   ((OI.ChargeTypeCode = 'ILF' and OI.StatusCode <> 'CNCL')
                                    OR
           (OI.ChargeTypeCode = 'ACS' and OI.ActivationEndDate IS NULL 
            and (OI.StatusCode <> 'CNCL' or OI.StatusCode <> 'EXPD')
            )
                                    OR
           (OI.ChargeTypeCode = 'ACS' and 
               convert(datetime,Convert(varchar(50),OI.ActivationEndDate,101))  >= 
               convert(datetime,Convert(varchar(50),getdate(),101))
            and (OI.StatusCode <> 'CNCL' or OI.StatusCode <> 'EXPD')
            )
          )
    and OI.productcode <> 'DMD-PSR-ADM-ADM-AMTF'
    and OI.IDSEQ = (select max(X.IDSEQ)
                    From   ORDERS.dbo.OrderItem X with (nolock)
                    where  OI.OrderIDSeq        = X.OrderIDSeq
                    and    OI.OrderGroupIDSeq   = X.OrderGroupIDSeq
                    and    OI.OrderIDSeq        = @LVC_OrderIDSeq
                    and    OI.OrderGroupIDSeq   = @LBI_GroupIDSeq
                    and    X.OrderIDSeq         = @LVC_OrderIDSeq
                    and    X.OrderGroupIDSeq    = @LBI_GroupIDSeq                    
                    and    OI.ProductCode       = X.ProductCode
                    and    OI.ChargeTypeCode    = X.ChargeTypeCode
                    and    OI.MeasureCode       = X.MeasureCode
                    and    OI.FrequencyCode     = X.FrequencyCode
                    and   ((X.ChargeTypeCode = 'ILF' and X.StatusCode <> 'CNCL')
                                    OR
                           (X.ChargeTypeCode = 'ACS' and X.ActivationEndDate IS NULL 
                            and (X.StatusCode <> 'CNCL' or X.StatusCode <> 'EXPD')
                           )
                                    OR
                           (X.ChargeTypeCode = 'ACS' and 
                               convert(datetime,Convert(varchar(50),X.ActivationEndDate,101))  >= 
                               convert(datetime,Convert(varchar(50),getdate(),101))
                            and (X.StatusCode <> 'CNCL' or X.StatusCode <> 'EXPD')
                           )
                          )
                    and X.productcode <> 'DMD-PSR-ADM-ADM-AMTF'
                   )
    ------------------------------------------------------
    EXEC Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@IPVC_QuoteID,@IPI_GroupID=@LI_QuoteGroupID 
    ------------------------------------------------------
    select @LI_Min = @LI_Min + 1
  end
  ------------------------------------------------------------------------------------------
  select @LI_QuoteGroupID = NULL
  --Step 4: Create a new  Quotes.dbo.Group, Quotes.dbo.GroupProperties,Quotes.dbo.Quoteitem 
  ---       and add Management Transfer Fee product.
  ----Insert into QUOTES.dbo.[Group]
  BEGIN TRANSACTION;
    Insert into QUOTES.dbo.[Group](QuoteIDSeq,DiscAllocationCode,Name,Description,
                                   CustomerIDSeq,Sites,Units,Beds,PPUPercentage,
                                   ShowDetailPriceFlag,AllowProductCancelFlag,
                                   GroupType,CustomBundleNameEnabledFlag,
                                   TransferredFlag)
    Select distinct
           @IPVC_QuoteID as QuoteIDSeq,'IND' as DiscAllocationCode,'Mgmnt Transfer Fee Bundle' as Name,
           'Management/Owner Transfer Fee Bundle' as Description,
           @IPVC_ToCompanyID as CustomerIDSeq,1 as Sites,
           @IPI_Units as Units,@IPI_Beds as Beds,@IPI_PPUPercentage as PPUPercentage,
           1 as ShowDetailPriceFlag,0 AllowProductCancelFlag,'SITE' OrderGroupType,
           0 as CustomBundleNameEnabledFlag,1 as TransferredFlag
    select @LI_QuoteGroupID =  SCOPE_IDENTITY() 
  COMMIT TRANSACTION; 
  ----Insert into QUOTES.dbo.[GroupProperties]  
  Insert into QUOTES.dbo.GroupProperties(QuoteIDSeq,GroupIDSeq,PropertyIDSeq,CustomerIDSeq,
                                         PriceTypeCode,ThresholdOverrideFlag,
                                         Units,Beds,PPUPercentage,TransferredFlag)
  select distinct 
           @IPVC_QuoteID as QuoteIDSeq,@LI_QuoteGroupID as GroupIDSeq,
           @IPVC_ToPropertyID as PropertyIDSeq,@IPVC_ToCompanyID as CustomerIDSeq,
           'Normal' as PriceTypeCode,0 as ThresholdOverrideFlag,
           @IPI_Units as Units,@IPI_Beds as Beds,@IPI_PPUPercentage as PPUPercentage,
           1 as TransferredFlag
  ----Insert into QUOTES.dbo.QuoteItem
  Insert into QUOTES.dbo.QuoteItem(QuoteIDSeq,GroupIDSeq,ProductCode,ChargeTypeCode,FrequencyCode,MeasureCode,
                                   FamilyCode,PublicationYear,PublicationQuarter,AllowProductCancelFlag,PriceVersion,
                                   Sites,Units,Beds,PPUPercentage,Quantity,MinUnits,MaxUnits,
                                   ChargeAmount,DiscountPercent,DiscountAmount,
                                   TotalDiscountPercent,TotalDiscountAmount,
                                   NetChargeAmount,NetExtChargeAmount,
                                   CapMaxUnitsFlag,DollarMinimum,DollarMaximum,credtcardpricingpercentage,
                                   excludeforbookingsflag,crossfiremaximumallowablecallvolume)
  select distinct 
           @IPVC_QuoteID as QuoteIDSeq,@LI_QuoteGroupID as GroupIDSeq,
           P.Code,C.ChargeTypeCode,C.FrequencyCode,C.MeasureCode,
           P.FamilyCode,NULL as PublicationYear,NULL as  PublicationQuarter,
           0 as AllowProductCancelFlag,P.PriceVersion,
           1 as Sites,@IPI_Units as Units,@IPI_Beds as Beds,@IPI_PPUPercentage as PPUPercentage,
           1 as Quantity,C.MinUnits,C.MaxUnits,
           C.ChargeAmount,0 as DiscountPercent,0 as DiscountAmount,
           0 as TotalDiscountPercent,0 as TotalDiscountAmount,
           C.ChargeAmount as NetChargeAmount,C.ChargeAmount NetExtChargeAmount,
           0 as CapMaxUnitsFlag,C.DollarMinimum,C.DollarMaximum,C.credtcardpricingpercentage,
           0 as excludeforbookingsflag,0 as crossfiremaximumallowablecallvolume 
  from   PRODUCTS.DBO.PRODUCT P  with (nolock)
  inner join 
         PRODUCTS.DBO.CHARGE  C with (nolock)
  ON     P.CODE         = C.PRODUCTCODE
  AND    P.PriceVersion = C.PriceVersion
  AND    P.CODE         = 'DMD-PSR-ADM-ADM-AMTF' 
  AND    C.PRODUCTCODE  = 'DMD-PSR-ADM-ADM-AMTF' 
  AND    P.DisabledFlag = 0 and C.DisabledFlag = 0 
  ----------------------------------------------------------
  EXEC Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@IPVC_QuoteID,@IPI_GroupID=@LI_QuoteGroupID 
  -----------------------------------------------------------
  ---Final Update to realign GroupNames for the current Quote
  ------------------------------------------------------------
  Update G
  set    G.Name        = S.NewName
  from   QUOTES.DBO.[Group] G  with (nolock)
  Inner Join
        (select T2.QuoteIDSeq,
                T2.IDSeq as GroupID,
                T2.Name  as OldName,
     	         'Custom Bundle ' + 
                convert(varchar(50),(select count(*) 
                                     from QUOTES.DBO.[Group] T1 with (nolock)  
                                     where T1.QuoteIDSeq = T2.QuoteIDSeq
                                     and   T1.QuoteIDSeq = @IPVC_QuoteID
                                     and   T2.QuoteIDSeq = @IPVC_QuoteID
                                     and   T1.IDSeq     <= T2.IDSeq
                                     and   charindex('Custom Bundle',T1.name)=1 
                                     and   T1.CustomBundleNameEnabledFlag = 0                                     
                                    )
                                 )        as NewName
         from  QUOTES.DBO.[Group] T2 with (nolock) 
         where QuoteIDSeq = @IPVC_QuoteID
         and   charindex('Custom Bundle',T2.name)=1
         and   T2.CustomBundleNameEnabledFlag = 0
         ) S
  On    G.QuoteIDSeq = S.QuoteIDSeq
  and   G.IDSeq      = S.GroupID
  and   G.Name       = S.OldName
  and   G.QuoteIDSeq = @IPVC_QuoteID
  where G.QuoteIDSeq = @IPVC_QuoteID
  ----------------------------------------------------------------------------------
  --Copy Footnotes Documents from Orders of @IPVC_FromCompanyID,@IPVC_FromPropertyID
  Insert into #tempDocumentsForEligibleOrders(Name,Description)
  Select Distinct S.Name,S.Description
  From   DOCUMENTS.dbo.Document S with (nolock)
  where  S.CompanyIDSeq = @IPVC_FromCompanyID
  and    S.OrderIdseq is not null 
  and    S.Documenttypecode = 'FNOT'
  and    S.QuoteIDSeq is null
  and    S.ActiveFlag = 1
  and    S.OrderIdseq in (select OrderIdseq from #tempEligibleOrderGroups with (nolock) )

  select Top 1 @LBI_QuoteItemIDSeq = QI.IDSeq
  from   Quotes.dbo.QuoteItem QI with (nolock)
  where  QI.QuoteIDSeq  = @IPVC_QuoteID
  and    QI.ProductCode = 'DMD-OSD-PAY-PAY-PPAY'  
  order by QI.IDSeq asc


  ---Loop thro and Insert Footnotes Documents for New Quote @IPVC_QuoteID pertaining to
  ---  @IPVC_ToCompanyID and @IPVC_ToPropertyID
  select @LI_Min = 1,@LI_Max = count(*) from #tempDocumentsForEligibleOrders with (nolock)
  While @LI_Min <= @LI_Max
  begin
    select @LVC_Name = Name,@LVC_Description = Description
    from   #tempDocumentsForEligibleOrders with (nolock)
    where  SEQ = @LI_Min
    ------------------------------------------------------    
    if not exists(select top 1 1 from DOCUMENTS.dbo.Document S with (nolock)
                  where  S.CompanyIDSeq = @IPVC_ToCompanyID
                  and    S.QuoteIDSeq   = @IPVC_QuoteID 
                  and    S.Documenttypecode = 'FNOT'
                  and    S.Activeflag   = 1
                  and    S.Name         = @LVC_Name
                  and    S.Description  = @LVC_Description
                 )
    begin TRY
      BEGIN TRANSACTION; 
        update DOCUMENTS.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
        set    IDSeq = IDSeq+1,
               GeneratedDate =CURRENT_TIMESTAMP

        select @LVC_DocumentIDSeq = DocumentIDSeq
        from   DOCUMENTS.DBO.IDGenerator with (NOLOCK)

        Insert into DOCUMENTS.dbo.Document(DocumentIDSeq,DocumentTypeCode,DocumentLevelCode,Name,Description,
                                           CompanyIDSeq,QuoteIDSeq,QuoteItemIDSeq,ActiveFlag,CreatedBy,ModifiedBy,CreatedDate,ModifiedDate)
        select  @LVC_DocumentIDSeq as DocumentIDSeq,'FNOT' as DocumentTypeCode, 'DOC' as DocumentLevelCode,
                @LVC_Name as Name,@LVC_Description as Description,@IPVC_ToCompanyID as CompanyIDSeq,
                @IPVC_QuoteID as QuoteIDSeq,(case when @LVC_Name = 'Payment Footnote' then @LBI_QuoteItemIDSeq else NULL end),
               1 as ActiveFlag,@IPVC_CreatedBy as CreatedBy,@IPVC_CreatedBy as ModifiedBy,
                Getdate() as CreatedDate,Getdate() as ModifiedDate
      COMMIT TRANSACTION;
    end TRY
    begin CATCH    
      -- XACT_STATE:
      -- If 1, the transaction is committable.
      -- If -1, the transaction is uncommittable and should be rolled back.
      -- XACT_STATE = 0 means that there is no transaction and COMMIT or ROLLBACK would generate an error.
      if (XACT_STATE()) = -1
      begin
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
      end
      else if (XACT_STATE()) = 1
      begin
        IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
      end   
      select @LVC_DocumentIDSeq = NULL
      EXEC CUSTOMERS.[dbo].[uspCUSTOMERS_RaiseError] 'Document Insert Section For SiteTransfer'
      return  
    end CATCH        
    ------------------------------------------------------ 
    select @LVC_DocumentIDSeq = NULL   
    select @LI_Min = @LI_Min + 1
  end
  ------------------------------------------------------
  EXEC Quotes.dbo.uspQUOTES_SyncGroupAndQuote @IPVC_QuoteID=@IPVC_QuoteID
  --------------------------------------------------
  --Final Cleanup
  IF @@TRANCOUNT > 0 COMMIT TRANSACTION;
  drop table #tempEligibleOrderGroups
  drop table #tempDocumentsForEligibleOrders
  --------------------------------------------------
  --Final Select 
  SELECT @IPVC_QuoteID AS QuoteIDseq 
END
GO
