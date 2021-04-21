SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		  KRK
-- Create date: 05/21/2007
-- Description:	Creates a new quote when the property is being transferred and returns the recordset
--              of details of quote.
-- =============================================
CREATE PROCEDURE [quotes].[uspQUOTES_GetBundlesToTransfer] (
                                                          @IPVC_CustomerID     varchar(50),
                                                          @IPVC_PropertyID     varchar(50),
                                                          @IPI_Units           int,
                                                          @IPI_Beds            int,
                                                          @IPVC_CreatedBy      varchar(70),
                                                          @IPI_CreatedByID     int 
                                                        )      

AS
BEGIN   
        declare @LVC_NewQuoteID varchar(50)
        declare @LVC_NewGroupID bigint
        /*
              Temporary Table for Quotes.dbo.GroupProperties    
        */
        declare @LT_GroupProperties table
        (
            QuoteIDSeq              varchar(50),
            GroupIDSeq              bigint,
            PropertyIDSeq           varchar(12),
            CustomerIDSeq           varchar(12),
            PriceTypeCode           varchar(20),
            ThresholdOverrideFlag   int,
            AnnualizedILFAmount     money,
            AnnualizedAccessAmount  money,
            Units                   int,
            Beds                    int,
            PPUPercentage           int
        )
        /*
              Temporary Table for Quotes.dbo.Group
        */
        declare @LT_Group table
        (
            QuoteIDSeq                    varchar(50),
            GroupIDSeq                    bigint,
            DiscAllocationCode            char(3),
            Name                          varchar(70),
            Description                   varchar(255),
            CustomerIDSeq                 varchar(12),
            OverrideFlag                  bit,
            Sites                         int,
            Units                         int,
            Beds                          int,
            PPUPercentage                 int,
            ILFExtYearChargeAmount        money,
            ILFDiscountPercent            numeric(30,5),
            ILFDiscountAmount             money,
            ILFNetExtYearChargeAmount     money,
            AccessExtYear1ChargeAmount    money,
            AccessExtYear2ChargeAmount    money,
            AccessExtYear3ChargeAmount    money,
            AccessDiscountPercent         numeric(30,5),
            AccessDiscountAmount          money,   
            AccessNetExtYear1ChargeAmount money,
            AccessNetExtYear2ChargeAmount money,
            AccessNetExtYear3ChargeAmount money,                     
            ShowDetailPriceFlag           bit,
            AllowProductCancelFlag        bit,
            GroupType                     varchar(70),
            CustomBundleNameEnabledFlag   bit
        )

        /*
                Temporary table for Quotes.dbo.QuoteItem
        */

        declare @LT_QuoteItemSummary table
        (
            QuoteIDSeq                    varchar(12),
            GroupIDSeq                    bigint,
            ProductCode                   char(30),
            ChargeTypeCode                char(3),
            FrequencyCode                 char(6),
            MeasureCode                   char(6),
            FamilyCode                    char(3),
            PublicationYear               varchar(10),
            PublicationQuarter            varchar(10),
            AllowProductCancelFlag        bit,
            PriceVersion                  numeric(18,0),
            Sites                         int,
            Units                         int,
            Beds                          int,
            PPUPercentage                 int,
            Quantity decimal(18,2),
            MinUnits int,
            MaxUnits int,
            Multiplier decimal(18,5),
            QuantityEnabledFlag bit,            
            ChargeAmount money,
            ExtChargeAmount money,
            Extyear1ChargeAmount money,
            ExtYear2ChargeAmount money,
            Extyear3ChargeAmount money,
            DiscountPercent numeric(30,5),
            DiscountAmount money,
            NetChargeAmount money,
            NetExtChargeAmount money,            
            NetExtYear1ChargeAmount money,
            NetExtYear2ChargeAmount money,
            NetExtYear3ChargeAmount money
        )

        /* Declaring Temporary table for Quotes.dbo.Quote*/

        declare @LT_QuoteSummary table
        (        
          QuoteIDSeq varchar(22) ,
          CustomerIDSeq char(11) ,
          CompanyName varchar(255) ,
          Sites int     ,
          Units int     ,
          Beds int     ,
          OverrideFlag bit  ,
          OverrideSites int,
          OverrideUnits int ,
          ILFExtYearChargeAmount money ,
          ILFDiscountPercent numeric(30, 5) ,
          ILFDiscountAmount money  ,
          ILFNetExtYearChargeAmount money   ,
          AccessExtYear1ChargeAmount money ,
          AccessExtYear2ChargeAmount money ,
          AccessExtYear3ChargeAmount money ,
          AccessYear1DiscountPercent numeric(30, 5),
          AccessYear1DiscountAmount money ,
          AccessYear2DiscountPercent numeric(30, 5) ,
          AccessYear2DiscountAmount float ,
          AccessYear3DiscountPercent numeric(30, 5)   ,
          AccessYear3DiscountAmount money,
          AccessNetExtYear1ChargeAmount money ,
          AccessNetExtYear2ChargeAmount money ,
          AccessNetExtYear3ChargeAmount money ,
          QuoteStatusCode char(4) ,
          CreatedBy varchar(70) ,
          ModifiedBy varchar(70) ,
          CreatedByDisplayName varchar(70) ,
          ModifiedByDisplayName varchar(70) ,
          SubmittedDate datetime ,
          AcceptanceDate datetime ,
          ApprovalDate datetime ,
          ExpirationDate datetime ,
          CreateDate datetime,
          ModifiedDate datetime,
          CreatedByIDSeq bigint ,
          ModifiedByIDSeq bigint 
        )

        /*
            declare Temporary QuoteID table
        */

            declare @LT_QuoteIDs table
            (
                QuoteIDSeq varchar(12)
            )
        /* Inserting into Temporary Group Properties*/

        insert into @LT_GroupProperties
        (
            QuoteIDSeq,
            GroupIDSeq,
            PropertyIDSeq,
            CustomerIDSeq,
            PriceTypeCode,
            ThresholdOverrideFlag,
            AnnualizedILFAmount,
            AnnualizedAccessAmount,
            Units,
            Beds,
            PPUPercentage
        )
        select 
            QuoteIDSeq,
            GroupIDSeq,
            PropertyIDSeq,
            CustomerIDSeq,
            PriceTypeCode,
            ThresholdOverrideFlag,
            AnnualizedILFAmount,
            AnnualizedAccessAmount,
            Units,
            Beds,
            PPUPercentage
        from Quotes.dbo.GroupProperties where PropertyIDSeq = @IPVC_PropertyID

        --select * from @LT_GroupProperties

        /* Inserting into Temporary Group*/

        insert into @LT_Group
        (
                    QuoteIDSeq,
                    GroupIDSeq,
                    DiscAllocationCode,
                    Name,
                    Description,
                    CustomerIDSeq,
                    OverrideFlag,
                    Sites,
                    Units,
                    Beds,
                    PPUPercentage,
                    ILFExtYearChargeAmount,
                    ILFDiscountPercent,
                    ILFDiscountAmount,
                    ILFNetExtYearChargeAmount,
                    AccessExtYear1ChargeAmount,
                    AccessExtYear2ChargeAmount,
                    AccessExtYear3ChargeAmount,
                    AccessDiscountPercent,
                    AccessDiscountAmount,   
                    AccessNetExtYear1ChargeAmount,
                    AccessNetExtYear2ChargeAmount,
                    AccessNetExtYear3ChargeAmount,                             
                    ShowDetailPriceFlag,                   
                    AllowProductCancelFlag,
                    GroupType,
                    CustomBundleNameEnabledFlag            
        )

        select 
                    quote_grp.QuoteIDSeq,
                    quote_grp.IDSeq,
                    quote_grp.DiscAllocationCode,
                    quote_grp.Name,
                    quote_grp.Description,
                    quote_grp.CustomerIDSeq,
                    quote_grp.OverrideFlag,
                    quote_grp.Sites,
                    quote_grp.Units,
                    quote_grp.Beds,
                    quote_grp.PPUPercentage,
                    quote_grp.ILFExtYearChargeAmount,
                    quote_grp.ILFDiscountPercent,
                    quote_grp.ILFDiscountAmount,
                    quote_grp.ILFNetExtYearChargeAmount,
                    quote_grp.AccessExtYear1ChargeAmount,
                    quote_grp.AccessExtYear2ChargeAmount,
                    quote_grp.AccessExtYear3ChargeAmount,
                    quote_grp.AccessDiscountPercent,
                    quote_grp.AccessDiscountAmount,   
                    quote_grp.AccessNetExtYear1ChargeAmount,
                    quote_grp.AccessNetExtYear2ChargeAmount,
                    quote_grp.AccessNetExtYear3ChargeAmount,                             
                    quote_grp.ShowDetailPriceFlag,                                        
                    quote_grp.AllowProductCancelFlag,
                    quote_grp.GroupType,
                    quote_grp.CustomBundleNameEnabledFlag            
        from Quotes.dbo.[Group] quote_grp

        inner join @LT_GroupProperties grp_pro

        on quote_grp.IDSeq = grp_pro.GroupIDSeq 

        --select * from @LT_GroupProperties

        --select * from @LT_Group

        insert into @LT_QuoteItemSummary
        (
                QuoteIDSeq,
                GroupIDSeq,
                ProductCode,
                ChargeTypeCode,
                FrequencyCode,
                MeasureCode,
                FamilyCode,
                PublicationYear,
                PublicationQuarter,
                AllowProductCancelFlag,
                PriceVersion,
                Sites,
                Units,
                Beds,
                PPUPercentage,
                Quantity,
                MinUnits,
                MaxUnits,
                Multiplier,
                QuantityEnabledFlag,                
                ChargeAmount,
                ExtChargeAmount,
                Extyear1ChargeAmount,
                ExtYear2ChargeAmount,
                Extyear3ChargeAmount,
                DiscountPercent,
                DiscountAmount,
                NetChargeAmount,
                NetExtChargeAmount,                
                NetExtYear1ChargeAmount,
                NetExtYear2ChargeAmount,
                NetExtYear3ChargeAmount
        )
        select 
                q_item.QuoteIDSeq,
                q_item.GroupIDSeq,
                q_item.ProductCode,
                q_item.ChargeTypeCode,
                q_item.FrequencyCode,
                q_item.MeasureCode,
                q_item.FamilyCode,
                q_item.PublicationYear,
                q_item.PublicationQuarter,
                q_item.AllowProductCancelFlag,
                q_item.PriceVersion,
                q_item.Sites,
                q_item.Units,
                q_item.Beds,
                q_item.PPUPercentage,
                q_item.Quantity,
                q_item.MinUnits,
                q_item.MaxUnits,
                q_item.Multiplier,
                q_item.QuantityEnabledFlag,                
                q_item.ChargeAmount,
                q_item.ExtChargeAmount,
                q_item.Extyear1ChargeAmount,
                q_item.ExtYear2ChargeAmount,
                q_item.Extyear3ChargeAmount,
                q_item.DiscountPercent,
                q_item.DiscountAmount,
                q_item.NetChargeAmount,
                q_item.NetExtChargeAmount,                
                q_item.NetExtYear1ChargeAmount,
                q_item.NetExtYear2ChargeAmount,
                q_item.NetExtYear3ChargeAmount

        from Quotes.dbo.QuoteItem q_item

        inner join @LT_Group q_group on 

        q_group.GroupIDSeq = q_item.GroupIDSeq

        insert into @LT_QuoteIDs
        (
          QuoteIDSeq
        )
        select
              distinct QuoteIDSeq
        from  @LT_QuoteItemSummary

        insert into @LT_QuoteSummary
        (
                   QuoteIDSeq,
                   CustomerIDSeq,
                   CompanyName,
                   Sites,
                   Units,
                   Beds,
                   OverrideFlag,
                   OverrideSites,
                   OverrideUnits,
                   ILFExtYearChargeAmount,
                   ILFDiscountPercent,
                   ILFDiscountAmount,
                   ILFNetExtYearChargeAmount,
                   AccessExtYear1ChargeAmount,
                   AccessExtYear2ChargeAmount,
                   AccessExtYear3ChargeAmount,
                   AccessYear1DiscountPercent,
                   AccessYear1DiscountAmount,
                   AccessYear2DiscountPercent,
                   AccessYear2DiscountAmount,
                   AccessYear3DiscountPercent,
                   AccessYear3DiscountAmount,
                   AccessNetExtYear1ChargeAmount,
                   AccessNetExtYear2ChargeAmount,
                   AccessNetExtYear3ChargeAmount,
                   QuoteStatusCode,
                   CreatedBy,
                   ModifiedBy,
                   CreatedByDisplayName,
                   ModifiedByDisplayName,
                   SubmittedDate,
                   AcceptanceDate,
                   ApprovalDate,
                   ExpirationDate,
                   CreateDate,
                   ModifiedDate,
                   CreatedByIDSeq,
                   ModifiedByIDSeq
        )

        select
                   quot.QuoteIDSeq,
                   quot.CustomerIDSeq,
                   quot.CompanyName,
                   quot.Sites,
                   quot.Units,
                   quot.Beds,
                   quot.OverrideFlag,
                   quot.OverrideSites,
                   quot.OverrideUnits,
                   quot.ILFExtYearChargeAmount,
                   quot.ILFDiscountPercent,
                   quot.ILFDiscountAmount,
                   quot.ILFNetExtYearChargeAmount,
                   quot.AccessExtYear1ChargeAmount,
                   quot.AccessExtYear2ChargeAmount,
                   quot.AccessExtYear3ChargeAmount,
                   quot.AccessYear1DiscountPercent,
                   quot.AccessYear1DiscountAmount,
                   quot.AccessYear2DiscountPercent,
                   quot.AccessYear2DiscountAmount,
                   quot.AccessYear3DiscountPercent,
                   quot.AccessYear3DiscountAmount,
                   quot.AccessNetExtYear1ChargeAmount,
                   quot.AccessNetExtYear2ChargeAmount,
                   quot.AccessNetExtYear3ChargeAmount,
                   quot.QuoteStatusCode,
                   quot.CreatedBy,
                   quot.ModifiedBy,
                   quot.CreatedByDisplayName,
                   quot.ModifiedByDisplayName,
                   quot.SubmittedDate,
                   quot.AcceptanceDate,
                   quot.ApprovalDate,
                   quot.ExpirationDate,
                   quot.CreateDate,
                   quot.ModifiedDate,
                   quot.CreatedByIDSeq,
                   quot.ModifiedByIDSeq
        from      Quotes.dbo.Quote quot

        inner join @LT_QuoteIDs q_item

        on q_item.QuoteIDSeq = quot.QuoteIDSeq

        /*
              Adding the new records to the tables        
        */  

        /*
              Generate the new QuoteID and GroupID      
        */
    

              UPDATE QUOTES.DBO.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
              set    IDSeq = IDSeq+1,
                     GeneratedDate =CURRENT_TIMESTAMP      

              select @LVC_NewQuoteID = QuoteIDSeq
              from   QUOTES.DBO.IDGenerator with (NOLOCK) 

      /*
                Inserting into Quotes.dbo.Quote 
      */
    

        insert into Quotes.dbo.Quote
        (
                   QuoteIDSeq,
                   CustomerIDSeq,
                   CompanyName,
                   Sites,
                   Units,
                   Beds,
                   OverrideFlag,
                   OverrideSites,
                   OverrideUnits,
                   ILFExtYearChargeAmount,
                   ILFDiscountPercent,
                   ILFDiscountAmount,
                   ILFNetExtYearChargeAmount,
                   AccessExtYear1ChargeAmount,
                   AccessExtYear2ChargeAmount,
                   AccessExtYear3ChargeAmount,
                   AccessYear1DiscountPercent,
                   AccessYear1DiscountAmount,
                   AccessYear2DiscountPercent,
                   AccessYear2DiscountAmount,
                   AccessYear3DiscountPercent,
                   AccessYear3DiscountAmount,
                   AccessNetExtYear1ChargeAmount,
                   AccessNetExtYear2ChargeAmount,
                   AccessNetExtYear3ChargeAmount,
                   QuoteStatusCode,
                   CreatedBy,
                   ModifiedBy,
                   CreatedByDisplayName,
                   ModifiedByDisplayName,
                   SubmittedDate,
                   AcceptanceDate,
                   ApprovalDate,
                   ExpirationDate,
                   CreateDate,
                   ModifiedDate,
                   CreatedByIDSeq,
                   ModifiedByIDSeq
        )

        select
                   @LVC_NewQuoteID as QuoteIDSeq,
                   @IPVC_CustomerID as CustomerIDSeq,
                   (select Name from Customers.dbo.Company where IDSeq = @IPVC_CustomerID) as CompanyName,
                   1 as Sites,
                   @IPI_Units as Units,
                   @IPI_Beds as Beds,
                   0 as OverrideFlag,
                   1 as OverrideSites,
                   0 as OverrideUnits,
                   sum(quot.ILFExtYearChargeAmount) as ILFExtYearChargeAmount,
                   sum(quot.ILFDiscountPercent) as ILFDiscountPercent,
                   sum(quot.ILFDiscountAmount) as ILFDiscountAmount,
                   sum(quot.ILFNetExtYearChargeAmount) as ILFNetExtYearChargeAmount,
                   sum(quot.AccessExtYear1ChargeAmount) as AccessExtYear1ChargeAmount,
                   sum(quot.AccessExtYear2ChargeAmount) as AccessExtYear2ChargeAmount,
                   sum(quot.AccessExtYear3ChargeAmount) as AccessExtYear3ChargeAmount,
                   sum(quot.AccessYear1DiscountPercent) as AccessYear1DiscountPercent,
                   sum(quot.AccessYear1DiscountAmount) as AccessYear1DiscountAmount,
                   sum(quot.AccessYear2DiscountPercent) as AccessYear2DiscountPercent,
                   sum(quot.AccessYear2DiscountAmount) as AccessYear2DiscountAmount,
                   sum(quot.AccessYear3DiscountPercent) as AccessYear3DiscountPercent,
                   sum(quot.AccessYear3DiscountAmount) as AccessYear3DiscountAmount,
                   sum(quot.AccessNetExtYear1ChargeAmount) as AccessNetExtYear1ChargeAmount,
                   sum(quot.AccessNetExtYear2ChargeAmount) as AccessNetExtYear2ChargeAmount,
                   sum(quot.AccessNetExtYear3ChargeAmount) as AccessNetExtYear3ChargeAmount,
                   'NSU' as QuoteStatusCode,
                   @IPVC_CreatedBy as CreatedBy,
                   @IPVC_CreatedBy as ModifiedBy,
                   @IPVC_CreatedBy as CreatedByDisplayName,
                   @IPVC_CreatedBy as ModifiedByDisplayName,
                   null as SubmittedDate,
                   null as AcceptanceDate,
                   null as ApprovalDate,
                   null as ExpirationDate,
                   getdate() as CreateDate,
                   getdate() as ModifiedDate,
                   @IPI_CreatedByID as CreatedByIDSeq,
                   @IPI_CreatedByID as ModifiedByIDSeq
        from       @LT_QuoteSummary quot   
              
        /*
                  Inserting new record to Quotes.dbo.Group
        */

        insert into Quotes.dbo.[Group]
        (
                    QuoteIDSeq,
                    DiscAllocationCode,
                    Name,
                    Description,
                    CustomerIDSeq,
                    OverrideFlag,
                    Sites,
                    Units,
                    Beds,
                    PPUPercentage,
                    ILFExtYearChargeAmount,
                    ILFDiscountPercent,
                    ILFDiscountAmount,
                    ILFNetExtYearChargeAmount,
                    AccessExtYear1ChargeAmount,
                    AccessExtYear2ChargeAmount,
                    AccessExtYear3ChargeAmount,
                    AccessDiscountPercent,
                    AccessDiscountAmount,   
                    AccessNetExtYear1ChargeAmount,
                    AccessNetExtYear2ChargeAmount,
                    AccessNetExtYear3ChargeAmount,                             
                    ShowDetailPriceFlag,
                    AllowProductCancelFlag,
                    GroupType,
                    CustomBundleNameEnabledFlag            
        )
        select
                    @LVC_NewQuoteID as QuoteIDSeq,
                    'IND' as DiscAllocationCode,
                    'Custom Bundle 1' as Name,
                    'Custom Bundle 1' as Description,
                    @IPVC_CustomerID as CustomerIDSeq,
                    0 as OverrideFlag,
                    1 as Sites,
                    @IPI_Units as Units,
                    @IPI_Beds as Beds,
                    0 as PPUPercentage,
                    sum(grp.ILFExtYearChargeAmount) as ILFExtYearChargeAmount,
                    sum(grp.ILFDiscountPercent) as ILFDiscountPercent,
                    sum(grp.ILFDiscountAmount) as ILFDiscountAmount,
                    sum(grp.ILFNetExtYearChargeAmount) as ILFNetExtYearChargeAmount,
                    sum(grp.AccessExtYear1ChargeAmount) as AccessExtYear1ChargeAmount,
                    sum(grp.AccessExtYear2ChargeAmount) as AccessExtYear2ChargeAmount,
                    sum(grp.AccessExtYear3ChargeAmount) as AccessExtYear3ChargeAmount,
                    sum(grp.AccessDiscountPercent) as AccessDiscountPercent,
                    sum(grp.AccessDiscountAmount) as AccessDiscountAmount,   
                    sum(grp.AccessNetExtYear1ChargeAmount) as AccessNetExtYear1ChargeAmount,
                    sum(grp.AccessNetExtYear2ChargeAmount) as AccessNetExtYear2ChargeAmount,
                    sum(grp.AccessNetExtYear3ChargeAmount) as AccessNetExtYear3ChargeAmount,                             
                    0 as ShowDetailPriceFlag,
                    1 as AllowProductCancelFlag,
                    'SITE' as GroupType,
                    0 as CustomBundleNameEnabledFlag            
        from @LT_Group grp
        
        insert into Quotes.dbo.QuoteItem
        (
                QuoteIDSeq,
                GroupIDSeq,
                ProductCode,
                ChargeTypeCode,
                FrequencyCode,
                MeasureCode,
                FamilyCode,
                PublicationYear,
                PublicationQuarter,
                AllowProductCancelFlag,
                PriceVersion,
                Sites,
                Units,
                Beds,
                PPUPercentage,
                Quantity,
                MinUnits,
                MaxUnits,
                Multiplier,
                QuantityEnabledFlag,                
                ChargeAmount,
                ExtChargeAmount,
                Extyear1ChargeAmount,
                ExtYear2ChargeAmount,
                Extyear3ChargeAmount,
                DiscountPercent,
                DiscountAmount,
                NetChargeAmount,
                NetExtChargeAmount,               
                NetExtYear1ChargeAmount,
                NetExtYear2ChargeAmount,
                NetExtYear3ChargeAmount
        )
        select
                @LVC_NewQuoteID as QuoteIDSeq,
                (select max(IDSeq) from Quotes.dbo.[Group]) as GroupIDSeq,
                qitem.ProductCode,
                qitem.ChargeTypeCode,
                qitem.FrequencyCode,
                qitem.MeasureCode,
                qitem.FamilyCode,
                qitem.PublicationYear,
                qitem.PublicationQuarter,
                qitem.AllowProductCancelFlag,
                qitem.PriceVersion,
                1 as Sites,
                @IPI_Units as Units,
                @IPI_Beds as Beds,
                qitem.PPUPercentage,
                qitem.Quantity,
                qitem.MinUnits,
                qitem.MaxUnits,
                qitem.Multiplier,
                qitem.QuantityEnabledFlag,               
                qitem.ChargeAmount,
                qitem.ExtChargeAmount,
                qitem.Extyear1ChargeAmount,
                qitem.ExtYear2ChargeAmount,
                qitem.Extyear3ChargeAmount,
                qitem.DiscountPercent,
                qitem.DiscountAmount,
                qitem.NetChargeAmount,
                qitem.NetExtChargeAmount,                
                qitem.NetExtYear1ChargeAmount,
                qitem.NetExtYear2ChargeAmount,
                qitem.NetExtYear3ChargeAmount
        from    @LT_QuoteItemSummary qitem

        insert into Quotes.dbo.GroupProperties
        (
            QuoteIDSeq,
            GroupIDSeq,
            PropertyIDSeq,
            CustomerIDSeq,
            PriceTypeCode,
            ThresholdOverrideFlag,
            AnnualizedILFAmount,
            AnnualizedAccessAmount,
            Units,
            Beds,
            PPUPercentage
        )
        select 
            @LVC_NewQuoteID as QuoteIDSeq,
            (select max(IDSeq) from Quotes.dbo.[Group]) as GroupIDSeq,
            @IPVC_PropertyID as PropertyIDSeq,
            @IPVC_CustomerID as CustomerIDSeq,
            'Normal' as PriceTypeCode,
            0 as ThresholdOverrideFlag,
            sum(gpro.AnnualizedILFAmount) as AnnualizedILFAmount,
            sum(gpro.AnnualizedAccessAmount) as AnnualizedAccessAmount,
            @IPI_Units as Units,
            @IPI_Beds as Beds,
            0 as PPUPercentage
        from @LT_GroupProperties gpro


        /* Adding Management Transfer Fee*/

        insert into Quotes.dbo.QuoteItem
             (
                            QuoteIDSeq,
                            GroupIDSeq,
                            ProductCode,
                            ChargeTypeCode,
                            FrequencyCode,
                            MeasureCode,
                            FamilyCode,
                            PublicationYear,
                            PublicationQuarter,
                            AllowProductCancelFlag,
                            PriceVersion,
                            Sites,
                            Units,
                            Beds,
                            PPUPercentage,
                            Quantity,
                            MinUnits,
                            MaxUnits,
                            Multiplier,
                            QuantityEnabledFlag,                            
                            ChargeAmount,
                            ExtChargeAmount,
                            Extyear1ChargeAmount,
                            ExtYear2ChargeAmount,
                            Extyear3ChargeAmount,
                            DiscountPercent,
                            DiscountAmount,
                            NetChargeAmount,
                            NetExtChargeAmount,                           
                            NetExtYear1ChargeAmount,
                            NetExtYear2ChargeAmount,
                            NetExtYear3ChargeAmount
                    )
            select 
                            @LVC_NewQuoteID as QuoteIDSeq,
                            (select max(IDSeq) from Quotes.dbo.[Group]) as GroupIDSeq,
                            prod.Code,
                            charg.ChargeTypeCode,
                            charg.FrequencyCode,
                            charg.MeasureCode,
                            prod.FamilyCode,
                            null as PublicationYear,
                            null as PublicationQuarter,
                            1 as AllowProductCancelFlag,
                            charg.PriceVersion,
                            1 as Sites,
                            '0' as Units,
                            '0' as Beds,
                            0 as PPUPercentage,
                            0 as Quantity,
                            charg.MinUnits,
                            charg.MaxUnits,
                            0 as Multiplier,
                            0 as QuantityEnabledFlag,                            
                            charg.ChargeAmount,
                            0 as ExtChargeAmount,
                            0 as Extyear1ChargeAmount,
                            0 as ExtYear2ChargeAmount,
                            0 as Extyear3ChargeAmount,
                            0 as DiscountPercent,
                            0 as DiscountAmount,
                            0 as NetChargeAmount,
                            0 as NetExtChargeAmount,                             
                            0 as NetExtYear1ChargeAmount,
                            0 as NetExtYear2ChargeAmount,
                            0 as NetExtYear3ChargeAmount

            from       Products.dbo.Product prod with (nolock)
            inner join Products.dbo.Charge charg with (nolock)
            on    prod.Code         = charg.ProductCode 
            and   Prod.PriceVersion = charg.PriceVersion
            and   prod.Code         = 'DMD-PSR-ADM-ADM-AMTF'
            and   charg.ProductCode = 'DMD-PSR-ADM-ADM-AMTF'
            and   Prod.DisabledFlag = 0
            and   Charg.Disabledflag= 0 
            where prod.Code = 'DMD-PSR-ADM-ADM-AMTF'
            and   Prod.PriceVersion = charg.PriceVersion
            and   prod.Code         = 'DMD-PSR-ADM-ADM-AMTF'
            and   charg.ProductCode = 'DMD-PSR-ADM-ADM-AMTF'
            and   Prod.DisabledFlag = 0
            and   Charg.Disabledflag= 0 
        /*
              Final select
        */

          declare @LT_Summary table
          (
              productname varchar(255),
              units int,
              ilflistprice money,
              accesslistprice money,
              discountpercent int,
              discountamount money,
              ilfnetprice money,
              accessnetprice money
          )

          insert into @LT_Summary
          (
              productname,
              units,
              ilflistprice,
              accesslistprice,
              discountpercent,
              discountamount,
              ilfnetprice,
              accessnetprice
          )

          select 

                prod.DisplayName as productname,
                qitem.units as units,
                grp.ILFExtYearChargeAmount as ilflistprice,
                grp.AccessExtYear1ChargeAmount    as accesslistprice,
                grp.ILFDiscountPercent         as discountpercent,
                grp.ILFDiscountAmount         as discountamount,
                grp.ILFNetExtYearChargeAmount                         as ilfnetprice,
                grp.AccessNetExtYear1ChargeAmount                     as accessnetprice

          from Quotes.dbo.QuoteItem qitem with (nolock)
          inner join Products.dbo.Product prod with (nolock)
          on    qitem.ProductCode = prod.Code
          and   qitem.PriceVersion= prod.PriceVersion
          inner join Quotes.dbo.[Group] grp with (nolock)
          on qitem.QuoteIDSeq     = grp.QuoteIDSeq
          where qitem.QuoteIDSeq  = @LVC_NewQuoteID


          select 
                productname,
                units,
                convert(numeric(10,2),ilflistprice)        as ilflistprice,
                convert(numeric(10,2),accesslistprice)     as accesslistprice,
                convert(numeric(10,2),discountpercent)     as discountpercent,
                convert(numeric(10,2),discountamount)      as discountamount,
                convert(numeric(10,2),ilfnetprice)         as ilfnetprice,
                convert(numeric(10,2),accessnetprice)      as accessnetprice
          from @LT_Summary

          select 
                sum(convert(numeric(10,2),ilflistprice))        as ilflistprice,
                sum(convert(numeric(10,2),accesslistprice))     as accesslistprice,
                sum(convert(numeric(10,2),discountpercent))     as discountpercent,
                sum(convert(numeric(10,2),discountamount))      as discountamount,
                sum(convert(numeric(10,2),ilfnetprice))         as ilfnetprice,
                sum(convert(numeric(10,2),accessnetprice))      as accessnetprice
          from @LT_Summary          

          select 
                  @LVC_NewQuoteID as QuoteID,
                       (select max(IDSeq) from Quotes.dbo.[Group]) as GroupIDSeq

END

GO
