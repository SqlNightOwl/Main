CREATE TABLE [customers].[Property]
(
[IDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PriceTypeCode] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Property_PriceTypeCode] DEFAULT ('Normal'),
[ThresholdOverrideFlag] [bit] NOT NULL CONSTRAINT [DF_Property_ThresholdOverrideFlag] DEFAULT ((0)),
[SiteMasterID] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Number] [varchar] (12) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Name] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PMCIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[OwnerIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OwnerName] [varchar] (255) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Property_OwnerName] DEFAULT (''),
[Units] [int] NOT NULL CONSTRAINT [DF_Property_Units] DEFAULT ((0)),
[Beds] [int] NOT NULL CONSTRAINT [DF_Property_Beds] DEFAULT ((0)),
[PPUPercentage] [int] NOT NULL CONSTRAINT [DF_Property_PPUPercentage] DEFAULT ((100)),
[YearBuilt] [smallint] NULL,
[SubPropertyFlag] [bit] NOT NULL CONSTRAINT [DF_Property_SubPropertyFlag] DEFAULT ((0)),
[ConventionalFlag] [bit] NOT NULL CONSTRAINT [DF_Property_ConventionalFlag] DEFAULT ((1)),
[StudentLivingFlag] [bit] NOT NULL CONSTRAINT [DF_Property_StudentLiving] DEFAULT ((0)),
[HUDFlag] [bit] NOT NULL CONSTRAINT [DF_Property_HUDFlag] DEFAULT ((0)),
[RHSFlag] [bit] NOT NULL CONSTRAINT [DF_Property_RHSFlag] DEFAULT ((0)),
[TaxCreditFlag] [bit] NOT NULL CONSTRAINT [DF_Property_TaxCreditFlag] DEFAULT ((0)),
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Property_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL CONSTRAINT [DF_Property_ModifiedDate] DEFAULT (getdate()),
[SiebelRowID] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceTerm] [int] NULL,
[SiebelID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[StatusTypeCode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Property_StatusTypeCode] DEFAULT ('ACTIV'),
[TransferPMCIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[TransferDate] [datetime] NULL,
[QuotableUnits] [int] NOT NULL CONSTRAINT [DF_Property_QuotableUnits] DEFAULT ((0)),
[QuotableBeds] [int] NOT NULL CONSTRAINT [DF_Property_QuotableBeds] DEFAULT ((0)),
[LegacyRegistrationCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Phase] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_CUSTOMERS_Property_Phase] DEFAULT (''),
[CustomBundlesProductBreakDownTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Property_CustomBundlesProductBreakDownTypeCode] DEFAULT ('DEFC'),
[EpicorCustomerCode] [varchar] (8) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[VendorFlag] [bit] NOT NULL CONSTRAINT [DF_Property_VendorFlag] DEFAULT ((0)),
[RECORDSTAMP] [timestamp] NOT NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SeparateInvoiceByFamilyFlag] [bit] NOT NULL CONSTRAINT [DF_Property_SeparateInvoiceByFamilyFlag] DEFAULT ((0)),
[SendInvoiceToClientFlag] [bit] NOT NULL CONSTRAINT [DF_Property_SendInvoiceToClientFlag] DEFAULT ((1)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Property_CreatedByIDSeq] DEFAULT ((-1)),
[RetailFlag] [bit] NOT NULL CONSTRAINT [DF_Property_RetailFlag] DEFAULT ((0)),
[GSAEntityFlag] [bit] NOT NULL CONSTRAINT [DF_Property_GSAEntityFlag] DEFAULT ((0)),
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Property_SystemLogDate] DEFAULT (getdate()),
[MilitaryPrivatizedFlag] [bit] NOT NULL CONSTRAINT [DF_Property_MilitaryPrivatizedFlag] DEFAULT ((0)),
[SeniorLivingFlag] [bit] NOT NULL CONSTRAINT [DF_Property_SeniorLivingFlag] DEFAULT ((0)),
[RECORDCRC] AS (binary_checksum([IDSeq],[PriceTypeCode],[ThresholdOverrideFlag],[SiteMasterID],[Number],[Name],[PMCIDSeq],[OwnerIDSeq],[OwnerName],[Units],[Beds],[PPUPercentage],[YearBuilt],[SubPropertyFlag],[ConventionalFlag],[StudentLivingFlag],[HUDFlag],[RHSFlag],[TaxCreditFlag],[PriceTerm],[SiebelID],[StatusTypeCode],[QuotableUnits],[QuotableBeds],[LegacyRegistrationCode],[Phase],[CustomBundlesProductBreakDownTypeCode],[EpicorCustomerCode],[VendorFlag],[SeparateInvoiceByFamilyFlag],[SendInvoiceToClientFlag],[RetailFlag],[GSAEntityFlag],[MilitaryPrivatizedFlag],[SeniorLivingFlag]))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [customers].[TRG_CUSTOMERS_PropertyAuditTrail] on [customers].[Property] AFTER UPDATE
AS
if (SELECT TRIGGER_NESTLEVEL(object_ID('TRG_CUSTOMERS_PropertyAuditTrail'))) = 1
BEGIN 
  set nocount on;
  ----------------------------------------------------------------------
  --declare Local Variables
  ----------------------------------------------------------------------
  declare @LI_PreviousUnits                INT
  declare @LI_PreviousBeds                 INT
  declare @LI_PreviousPPUPercentage        INT  
  declare @LN_PreviousRecordCRC            numeric(30,0)
  declare @LN_CurrentRecordCRC             numeric(30,0)
  declare @LI_CurrentUnits                 INT
  declare @LI_CurrentBeds                  INT
  declare @LI_CurrentPPUPercentage         INT
  declare @LVC_PropertyIDSeq               varchar(50)  
  declare @LVC_PMCIDSeq                    varchar(50)

  declare @LBI_CreatedByIDSeq              bigint
  declare @LBI_ModifiedByIDSeq             bigint

  declare @LI_Min                       int
  declare @LI_Max                       int
  declare @LI_IMin                      int
  declare @LI_IMax                      int
  declare @LVC_OrderID                  Varchar(50)
  -----------------------------------------------------------------------
  create table #LT_OrdersProperty   
                               (Seq                      int not null identity(1,1),
                                orderid                  varchar(50)
                               )
  create table #LT_DELETEDProperty   
                               (Seq                      int not null identity(1,1),
                                PropertyIDSeq            varchar(50),
                                units                    int,
                                Beds                     int,
                                PPUPercentage            int,                                
                                RecordCRC                numeric(30,0)
                               )
  create table #LT_INSERTEDProperty 
                               (Seq                      int not null identity(1,1),
                                PropertyIDSeq            varchar(50),
                                PMCIDSeq                 varchar(50),
                                units                    int,
                                Beds                     int,
                                PPUPercentage            int,
                                RecordCRC                numeric(30,0),
                                CreatedByIDSeq           bigint,
                                ModifiedByIDSeq          bigint
                               ) 
  select @LI_Min=1,@LI_Max=0,@LI_IMin=1,@LI_IMax=0
  ----------------------------------------------------------------------  
  --- Fire the trigger code whenever any column is updated.
  Insert into #LT_DELETEDProperty(PropertyIDSeq,Units,Beds,PPUPercentage,RecordCRC)
  select IDSeq as PropertyIDSeq,Units,Beds,PPUPercentage,RecordCRC
  from   DELETED 
    
  Insert into #LT_INSERTEDProperty(PropertyIDSeq,PMCIDSeq,Units,Beds,PPUPercentage,RecordCRC,CreatedByIDSeq,ModifiedByIDSeq)
  select IDSeq as PropertyIDSeq,PMCIDSeq,Units,Beds,PPUPercentage,RecordCRC,CreatedByIDSeq,ModifiedByIDSeq
  from   INSERTED  

  select @LI_min=1,@LI_Max = count(Seq) from #LT_INSERTEDProperty with (nolock)
  While @LI_min <= @LI_Max
  begin 
    select @LI_CurrentUnits=D.Units,@LI_CurrentBeds=D.Beds,@LI_CurrentPPUPercentage=D.PPUPercentage,           
           @LN_CurrentRecordCRC = D.RecordCRC,
           @LVC_PropertyIDSeq=D.PropertyIDSeq,@LVC_PMCIDSeq = PMCIDSeq,
           @LBI_CreatedByIDSeq = D.CreatedByIDSeq,
           @LBI_ModifiedByIDSeq= D.ModifiedByIDSeq
    from   #LT_INSERTEDProperty D with (nolock)  where Seq = @LI_min 

    select @LI_PreviousUnits =S.Units,@LI_PreviousBeds=S.Beds,@LI_PreviousPPUPercentage=S.PPUPercentage,
           @LN_PreviousRecordCRC = S.RecordCRC
    from   #LT_DELETEDProperty  S with (nolock) where Seq = @LI_min and S.PropertyIDSeq = @LVC_PropertyIDSeq 
    ---------------------------------------------------------------------
    if (@LN_PreviousRecordCRC <> @LN_CurrentRecordCRC)
    begin
      ---Insert Deleted Records into PropertyHistory Table when @LN_PreviousRecordCRC <> @LN_CurrentRecordCRC
      Insert into Customers.dbo.PropertyHistory(PropertyIDSeq,PriceTypeCode,ThresholdOverrideFlag,SiteMasterID,
                                                Number,Name,PMCIDSeq,OwnerIDSeq,OwnerName,Units,Beds,PPUPercentage,
                                                YearBuilt,SubPropertyFlag,ConventionalFlag,StudentLivingFlag,
                                                HUDFlag,RHSFlag,TaxCreditFlag,
                                                CreatedbyIDSeq,ModifiedByIDSeq,
                                                CreatedDate,ModifiedDate,SiebelRowID,PriceTerm,SiebelID,
                                                StatusTypeCode,TransferPMCIDSeq,TransferDate,QuotableUnits,
                                                QuotableBeds,LegacyRegistrationCode,Phase,
                                                CustomBundlesProductBreakDownTypeCode,EpicorCustomerCode,
                                                VendorFlag,SeparateInvoiceByFamilyFlag,
                                                RetailFlag,GSAEntityFlag,SendInvoiceToClientFlag,
                                                MilitaryPrivatizedFlag,SeniorLivingFlag)
      select S.IDSeq as PropertyIDSeq,PriceTypeCode,ThresholdOverrideFlag,SiteMasterID,Number,
               Name,PMCIDSeq,OwnerIDSeq,OwnerName,Units,Beds,PPUPercentage,YearBuilt,SubPropertyFlag,
               ConventionalFlag,StudentLivingFlag,HUDFlag,RHSFlag,TaxCreditFlag,
               CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate,
               SiebelRowID,PriceTerm,SiebelID,StatusTypeCode,TransferPMCIDSeq,TransferDate,
               QuotableUnits,QuotableBeds,LegacyRegistrationCode,Phase,CustomBundlesProductBreakDownTypeCode,
               EpicorCustomerCode,VendorFlag,SeparateInvoiceByFamilyFlag,RetailFlag,GSAEntityFlag,SendInvoiceToClientFlag,
               MilitaryPrivatizedFlag,SeniorLivingFlag
      from   DELETED S where S.IDSeq = @LVC_PropertyIDSeq and S.RecordCRC =  @LN_PreviousRecordCRC
      -------------------------------------------------------------------
      --- Fire the below section of trigger code ONLY when UNITS,BEDS,PPUPERCENTAGE columns are updated.
      IF (UPDATE(Units) OR UPDATE(Beds) OR UPDATE(PPUPercentage))
      begin
        --Insert into CUSTOMERS.DBO.PropertyUnitHistory only when any of    
        --  Units,beds or PPUPercentage are changed
        If (@LI_PreviousUnits <> @LI_CurrentUnits) OR
           (@LI_PreviousBeds  <> @LI_CurrentBeds)  OR
           (@LI_PreviousPPUPercentage <> @LI_CurrentPPUPercentage)
        begin --> Begin for If (@LI_PreviousUnits <> @LI_CurrentUnits)...
          Insert into CUSTOMERS.DBO.PropertyUnitHistory(PropertyIDSeq,PMCIDSeq,
                                                        PreviousUnits,PreviousBeds,PreviousPPUPercentage,
                                                        CurrentUnits,CurrentBeds,CurrentPPUPercentage,
                                                        CreatedByIDSeq,ModifiedByIDSeq,ModifiedDate
                                                        )
          select @LVC_PropertyIDSeq        as PropertyIDSeq,
                 @LVC_PMCIDSeq             as PMCIDSeq,
                 @LI_PreviousUnits         as PreviousUnits,
                 @LI_PreviousBeds          as PreviousBeds,
                 @LI_PreviousPPUPercentage as PreviousPPUPercentage,
                 @LI_CurrentUnits          as CurrentUnits,
                 @LI_CurrentBeds           as CurrentBeds,
                 @LI_CurrentPPUPercentage  as CurrentPPUPercentage,
                 @LBI_CreatedByIDSeq       as CreatedByIDseq,
                 @LBI_ModifiedByIDSeq      as ModifiedByIDSeq,
                 GETDATE()                 as ModifiedDate
          ---------------------------------------------------------------
          --Get Related Orders and Reprice as Units,Beds,PPU have changed.
          insert into #LT_OrdersProperty(orderid)
          select distinct OrderIDSeq as orderid
          from   ORDERS.DBO.[Order]  with (nolock)
          where  PropertyIDSeq = @LVC_PropertyIDSeq
          and    PropertyIDSeq is not null

          select @LI_IMin=1,@LI_IMax = count(Seq) from #LT_OrdersProperty with (nolock)
          while  @LI_IMin <= @LI_IMax
          begin
            select @LVC_OrderID = orderid from #LT_OrdersProperty with (nolock) where Seq = @LI_IMin
            Update Orders.dbo.OrderItem with (rowlock)
            set    Units = @LI_CurrentUnits,
                   Beds  = @LI_CurrentBeds,
                   PPUPercentage=@LI_CurrentPPUPercentage
            where  OrderIDSeq   =@LVC_OrderID
            and    Statuscode <> 'EXPD'
            /*
            and   (
                   LastBillingPeriodToDate is NULL 
                       OR
                   LastBillingPeriodToDate < Coalesce(canceldate,Enddate)
                   )
            */
            exec ORDERS.DBO.uspORDERS_SyncOrderGroupAndOrderItem @IPVC_OrderID=@LVC_OrderID
            select @LI_IMin = @LI_IMin+1 
          end ---> end for inner while loop
          truncate table #LT_OrdersProperty
         ----------------------------------------------------------------
        end --> End for If (@LI_PreviousUnits <> @LI_CurrentUnits)...
        --------------------------------------------------------------------- 
      end -- End for if (UPDATE(Units) OR UPDATE(Beds) OR UPDATE(PPUPercentage))      
      -------------------------------------
    end --> End for if (@LN_PreviousRecordCRC <> @LN_CurrentRecordCRC)...
    select @LI_min = @LI_min + 1
  end      
  ----------------------------------------
  --Final cleanup
  if (object_id('tempdb.dbo.#LT_OrdersProperty') is not null) 
  begin
    drop table #LT_OrdersProperty
  end 
  if (object_id('tempdb.dbo.#LT_DELETEDProperty') is not null) 
  begin
    drop table #LT_DELETEDProperty
  end
  if (object_id('tempdb.dbo.#LT_INSERTEDProperty') is not null) 
  begin
    drop table #LT_INSERTEDProperty
  end 
  ----------------------------------------
END

  
GO
ALTER TABLE [customers].[Property] ADD CONSTRAINT [PK_Property] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Customers_Property_Name] ON [customers].[Property] ([Name], [IDSeq]) INCLUDE ([Beds], [OwnerIDSeq], [OwnerName], [PMCIDSeq], [PPUPercentage], [PriceTypeCode], [SiteMasterID], [StatusTypeCode], [Units]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Customers_Property_PMCIDSeq] ON [customers].[Property] ([PMCIDSeq], [IDSeq]) INCLUDE ([Beds], [Name], [OwnerIDSeq], [OwnerName], [PPUPercentage], [PriceTypeCode], [SiteMasterID], [StatusTypeCode], [Units]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Property_RECORDSTAMP] ON [customers].[Property] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [customers].[Property] WITH NOCHECK ADD CONSTRAINT [Property_has_CustomBundlesProductBreakDownTypeCode] FOREIGN KEY ([CustomBundlesProductBreakDownTypeCode]) REFERENCES [customers].[CustomBundlesProductBreakDownType] ([Code])
GO
ALTER TABLE [customers].[Property] WITH NOCHECK ADD CONSTRAINT [Property_has_Company_Owner] FOREIGN KEY ([OwnerIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
ALTER TABLE [customers].[Property] WITH NOCHECK ADD CONSTRAINT [Property_has_Company] FOREIGN KEY ([PMCIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
ALTER TABLE [customers].[Property] WITH NOCHECK ADD CONSTRAINT [Property_has_StatusTypeCode] FOREIGN KEY ([StatusTypeCode]) REFERENCES [customers].[StatusType] ([Code])
GO
