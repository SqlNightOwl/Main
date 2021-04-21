CREATE TABLE [customers].[Company]
(
[IDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[SiteMasterID] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Name] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PMCFlag] [bit] NOT NULL CONSTRAINT [DF_Company_PMCFlag] DEFAULT ((1)),
[OwnerFlag] [bit] NOT NULL CONSTRAINT [DF_Company_OwnerFlag] DEFAULT ((0)),
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Company_CreatedDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL CONSTRAINT [DF_Company_ModifiedDate] DEFAULT (getdate()),
[SiebelRowID] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PriceTerm] [int] NULL,
[SiebelID] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SignatureText] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[StatusTypecode] [varchar] (5) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Company_StatusTypecode] DEFAULT ('ACTIV'),
[LegacyRegistrationCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[OrderSynchStartMonth] [int] NOT NULL CONSTRAINT [DF_Company_OrderSynchStartMonth] DEFAULT ((0)),
[CustomBundlesProductBreakDownTypeCode] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_Company_CustomBundlesProductBreakDownTypeCode] DEFAULT ('NOBR'),
[EpicorCustomerCode] [varchar] (8) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[ModifiedByIDSeq] [bigint] NULL,
[SeparateInvoiceByFamilyFlag] [bit] NOT NULL CONSTRAINT [DF_Company_SeparateInvoiceByFamilyFlag] DEFAULT ((0)),
[SendInvoiceToClientFlag] [bit] NOT NULL CONSTRAINT [DF_Company_SendInvoiceToClientFlag] DEFAULT ((1)),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Company_CreatedByIDSeq] DEFAULT ((-1)),
[MultiFamilyFlag] [bit] NOT NULL CONSTRAINT [DF_Company_MultiFamilyFlag] DEFAULT ((1)),
[VendorFlag] [bit] NOT NULL CONSTRAINT [DF_Company_VendorFlag] DEFAULT ((0)),
[GSAEntityFlag] [bit] NOT NULL CONSTRAINT [DF_Company_GSAEntityFlag] DEFAULT ((0)),
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Company_SystemLogDate] DEFAULT (getdate()),
[ExecutiveCompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDCRC] AS (binary_checksum([IDSeq],[SiteMasterID],[Name],[PMCFlag],[OwnerFlag],[PriceTerm],[SignatureText],[StatusTypecode],[LegacyRegistrationCode],[OrderSynchStartMonth],[CustomBundlesProductBreakDownTypeCode],[EpicorCustomerCode],[SeparateInvoiceByFamilyFlag],[SendInvoiceToClientFlag],[MultiFamilyFlag],[VendorFlag],[GSAEntityFlag]))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [customers].[TRG_CUSTOMERS_CompanyAuditTrail] on [customers].[Company] AFTER UPDATE
AS
if (SELECT TRIGGER_NESTLEVEL(object_ID('TRG_CUSTOMERS_CompanyAuditTrail'))) = 1
BEGIN 
  set nocount on;
  ----------------------------------------------------------------------
  --declare Local Variables
  ---------------------------------------------------------------------- 
  declare @LN_PreviousRecordCRC            numeric(30,0)
  declare @LN_CurrentRecordCRC             numeric(30,0)
  declare @LVC_CompanyIDSeq                varchar(50)  
  declare @LI_OwnerFlag                    int
  declare @LVC_CompanyName                 varchar(255)

  declare @LI_Min                       int
  declare @LI_Max                       int  
  ----------------------------------------------------------------------- 
  create table #LT_DELETEDCOMPANY (Seq                      int not null identity(1,1),
                                   CompanyIDSeq             varchar(50), 
                                   RecordCRC                numeric(30,0)
                                  )
  create table #LT_INSERTEDCOMPANY  
                               (Seq                      int not null identity(1,1),
                                CompanyIDSeq             varchar(50),
                                OwnerFlag                int, 
                                CompanyName              varchar(255),
                                RecordCRC                numeric(30,0)
                               ) 
  select @LI_Min=1,@LI_Max=0
  ----------------------------------------------------------------------  
  --- Fire the trigger code whenever any column is updated.
  Insert into #LT_DELETEDCOMPANY(CompanyIDSeq,RecordCRC)
  select IDSeq as CompanyIDSeq,RecordCRC
  from   DELETED 
    
  Insert into #LT_INSERTEDCOMPANY(CompanyIDSeq,OwnerFlag,CompanyName,RecordCRC)
  select IDSeq as CompanyIDSeq,OwnerFlag,Name,RecordCRC
  from   INSERTED  
  select @LI_min=1,@LI_Max = count(Seq) from #LT_INSERTEDCOMPANY with (nolock)
  While @LI_min <= @LI_Max
  begin 
    select @LVC_CompanyIDSeq=D.CompanyIDSeq,
           @LI_OwnerFlag    =D.OwnerFlag,
           @LVC_CompanyName =D.CompanyName,
           @LN_CurrentRecordCRC = D.RecordCRC           
    from   #LT_INSERTEDCOMPANY D with (nolock)  where Seq = @LI_min 

    select @LN_PreviousRecordCRC = S.RecordCRC
    from   #LT_DELETEDCOMPANY  S with (nolock) where Seq = @LI_min and S.CompanyIDSeq = @LVC_CompanyIDSeq
    ---------------------------------------------------------------------
    if (@LN_PreviousRecordCRC <> @LN_CurrentRecordCRC)
    begin
      ---Insert Deleted Records into PropertyHistory Table when @LN_PreviousRecordCRC <> @LN_CurrentRecordCRC
      Insert into Customers.dbo.CompanyHistory(CompanyIDSeq,SiteMasterID,Name,PMCFlag,OwnerFlag,CreatedByIDSeq,ModifiedByIDSeq,
                                               CreatedDate,ModifiedDate,SiebelRowID,PriceTerm,SiebelID,SignatureText,StatusTypecode,
                                               LegacyRegistrationCode,OrderSynchStartMonth,
                                               CustomBundlesProductBreakDownTypeCode,EpicorCustomerCode,SeparateInvoiceByFamilyFlag,
                                               MultiFamilyFlag,VendorFlag,GSAEntityFlag,
                                               SendInvoiceToClientFlag)
      select S.IDSeq as CompanyIDSeq,SiteMasterID,Name,PMCFlag,OwnerFlag,CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate,
             SiebelRowID,PriceTerm,SiebelID,SignatureText,StatusTypecode,LegacyRegistrationCode,OrderSynchStartMonth,
             CustomBundlesProductBreakDownTypeCode,EpicorCustomerCode,SeparateInvoiceByFamilyFlag,
             MultiFamilyFlag,VendorFlag,GSAEntityFlag,
             SendInvoiceToClientFlag
      from   DELETED S where S.IDSeq = @LVC_CompanyIDSeq and S.RecordCRC =  @LN_PreviousRecordCRC

      if (@LI_OwnerFlag = 1)
      begin
        Update Customers.dbo.Property with (rowlock)
        set    OwnerName = @LVC_CompanyName
        where  OwnerIDseq= @LVC_CompanyIDSeq
      end      
      -------------------------------------------------------------------      
    end --> End for if (@LN_PreviousRecordCRC <> @LN_CurrentRecordCRC)...
    select @LI_min = @LI_min + 1
  end      
  ----------------------------------------
  --Final cleanup  
  if (object_id('tempdb.dbo.#LT_DELETEDCOMPANY') is not null) 
  begin
    drop table #LT_DELETEDCOMPANY
  end
  if (object_id('tempdb.dbo.#LT_INSERTEDCOMPANY') is not null) 
  begin
    drop table #LT_INSERTEDCOMPANY
  end 
  ----------------------------------------
END
GO
ALTER TABLE [customers].[Company] WITH NOCHECK ADD CONSTRAINT [CK_Company_OrderSynchStartMonth] CHECK (([OrderSynchStartMonth]>=(0) AND [OrderSynchStartMonth]<=(12)))
GO
ALTER TABLE [customers].[Company] ADD CONSTRAINT [PK_Company] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Customers_Company_Name] ON [customers].[Company] ([Name], [IDSeq]) INCLUDE ([CustomBundlesProductBreakDownTypeCode], [EpicorCustomerCode], [OrderSynchStartMonth], [OwnerFlag], [PMCFlag], [SiteMasterID], [StatusTypecode]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Company_RECORDSTAMP] ON [customers].[Company] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [customers].[Company] WITH NOCHECK ADD CONSTRAINT [Company_has_CustomBundlesProductBreakDownTypeCode] FOREIGN KEY ([CustomBundlesProductBreakDownTypeCode]) REFERENCES [customers].[CustomBundlesProductBreakDownType] ([Code])
GO
ALTER TABLE [customers].[Company] WITH NOCHECK ADD CONSTRAINT [Company_has_StatusTypeCode] FOREIGN KEY ([StatusTypecode]) REFERENCES [customers].[StatusType] ([Code])
GO
