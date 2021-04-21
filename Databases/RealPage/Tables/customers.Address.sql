CREATE TABLE [customers].[Address]
(
[IDSeq] [int] NOT NULL IDENTITY(1, 1),
[CompanyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[PropertyIDSeq] [char] (11) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AddressTypeCode] [char] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL,
[AddressLine1] [varchar] (200) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[AddressLine2] [varchar] (100) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[City] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[County] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[State] [char] (2) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Zip] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoice1] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoiceExt1] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoice2] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoiceExt2] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneFax] [varchar] (14) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Email] [varchar] (2000) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[URL] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SameAsPMCAddressFlag] [bit] NOT NULL CONSTRAINT [DF_Address_SameAsPMCAddressFlag] DEFAULT ((0)),
[CreatedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[ModifiedBy] [varchar] (70) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CreatedDate] [datetime] NOT NULL CONSTRAINT [DF_Address_CreateDate] DEFAULT (getdate()),
[ModifiedDate] [datetime] NULL CONSTRAINT [DF_Address_ModifiedDate] DEFAULT (getdate()),
[AttentionName] [varchar] (50) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[GeoCodeFlag] [bit] NOT NULL CONSTRAINT [DF_Address_GeoCodeFlag] DEFAULT ((0)),
[GeoCodeMatch] [varchar] (4) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Latitude] [decimal] (18, 6) NULL,
[Longitude] [decimal] (18, 6) NULL,
[MSANumber] [varchar] (6) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Country] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[Sieb77AddrID] [varchar] (15) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[CountryCode] [varchar] (3) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[RECORDSTAMP] [timestamp] NOT NULL,
[ModifiedByIDSeq] [bigint] NULL,
[PhoneVoice3] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoiceExt3] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoice4] [varchar] (30) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[PhoneVoiceExt4] [varchar] (10) COLLATE SQL_Latin1_General_CP850_CI_AI NULL,
[SystemLogDate] [datetime] NOT NULL CONSTRAINT [DF_Address_SystemLogDate] DEFAULT (getdate()),
[CreatedByIDSeq] [bigint] NOT NULL CONSTRAINT [DF_Address_CreatedByIDSeq] DEFAULT ((-1)),
[RECORDCRC] AS (binary_checksum([CompanyIDSeq],[PropertyIDSeq],[AddressTypeCode],[AddressLine1],[AddressLine2],[City],[County],[State],[Zip],[PhoneVoice1],[PhoneVoiceExt1],[PhoneVoice2],[PhoneVoiceExt2],[PhoneVoice3],[PhoneVoiceExt3],[PhoneVoice4],[PhoneVoiceExt4],[PhoneFax],[Email],[URL],[SameAsPMCAddressFlag],[AttentionName],[GeoCodeFlag],[GeoCodeMatch],[Latitude],[Longitude],[MSANumber],[Country],[CountryCode]))
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [customers].[TRG_CUSTOMERS_AddressAuditTrail] on [customers].[Address] AFTER UPDATE
AS
if (SELECT TRIGGER_NESTLEVEL(object_ID('TRG_CUSTOMERS_AddressAuditTrail'))) = 1
BEGIN 
  set nocount on;
  ----------------------------------------------------------------------
  --declare Local Variables
  ---------------------------------------------------------------------- 
  declare @LN_PreviousRecordCRC        numeric(30,0)
  declare @LN_CurrentRecordCRC         numeric(30,0) 

  
  
  declare @LBI_AddressIDSeq            bigint
  declare @LVC_AddressTypecode         varchar(20)
  declare @LVC_CompanyIDSeq            varchar(50)
  declare @LVC_PropertyIDSeq           varchar(50)
  declare @LVC_InvoiceIDSeq            varchar(50)


  declare @LI_Min                       int
  declare @LI_Max                       int 
  declare @LI_iMin                      int
  declare @LI_iMax                      int  
  ----------------------------------------------------------------------- 
  create table #LT_DELETEDADDRESS 
                               (Seq                      int not null identity(1,1),
                                AddressIDSeq             bigint,   
                                AddressTypecode          varchar(20),
                                CompanyIDSeq             varchar(50),
                                PropertyIDSeq            varchar(50),
                                Email                    varchar(max),
                                RecordCRC                numeric(30,0)
                               )
  create table #LT_INSERTEDADDRESS 
                               (Seq                      int not null identity(1,1),
                                AddressIDSeq             bigint, 
                                AddressTypecode          varchar(20),
                                CompanyIDSeq             varchar(50),
                                PropertyIDSeq            varchar(50),
                                Email                    varchar(max),
                                RecordCRC                numeric(30,0)
                               ) 

  create table #LT_INVOICESADDRESS   (Seq                      int not null identity(1,1),
                                      InvoiceIDSeq             varchar(50)
                                     )             
  select @LI_Min=1,@LI_Max=0
  ----------------------------------------------------------------------  
  --- Fire the trigger code whenever any column is updated.
  Insert into #LT_DELETEDADDRESS(AddressIDSeq,AddressTypecode,CompanyIDSeq,PropertyIDSeq,Email,RecordCRC)
  select IDSeq as AddressIDSeq,AddressTypecode,CompanyIDSeq,PropertyIDSeq,Email,RecordCRC
  from   DELETED 
    
  Insert into #LT_INSERTEDADDRESS(AddressIDSeq,AddressTypecode,CompanyIDSeq,PropertyIDSeq,Email,RecordCRC)
  select IDSeq as AddressIDSeq,AddressTypecode,CompanyIDSeq,PropertyIDSeq,Email,RecordCRC
  from   INSERTED  
  select @LI_min=1,@LI_Max = count(Seq) from #LT_INSERTEDADDRESS with (nolock)
  While @LI_min <= @LI_Max
  begin 
    select @LBI_AddressIDSeq         =D.AddressIDSeq,
           @LVC_AddressTypecode      =D.AddressTypecode,
           @LVC_CompanyIDSeq         =D.CompanyIDSeq,
           @LVC_PropertyIDSeq        =D.PropertyIDSeq,           
           @LN_CurrentRecordCRC      =D.RecordCRC           
    from   #LT_INSERTEDADDRESS D with (nolock)  where Seq = @LI_min 

    select @LN_PreviousRecordCRC = S.RecordCRC
    from   #LT_DELETEDADDRESS  S with (nolock) where Seq = @LI_min 
    and    S.AddressIDSeq = @LBI_AddressIDSeq and S.AddressTypecode = @LVC_AddressTypecode
    ---------------------------------------------------------------------
    if (@LN_PreviousRecordCRC <> @LN_CurrentRecordCRC)
    begin
      ---Insert Deleted Records into PropertyHistory Table when @LN_PreviousRecordCRC <> @LN_CurrentRecordCRC
      Insert into Customers.dbo.AddressHistory(AddressIDSeq,CompanyIDSeq,PropertyIDSeq,AddressTypeCode,
                                               AddressLine1,AddressLine2,City,County,State,Zip,
                                               PhoneVoice1,PhoneVoiceExt1,PhoneVoice2,PhoneVoiceExt2,PhoneFax,Email,URL,
                                               SameAsPMCAddressFlag,CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate,
                                               AttentionName,GeoCodeFlag,GeoCodeMatch,Latitude,Longitude,MSANumber,
                                               Country,Sieb77AddrID,CountryCode,
                                               PhoneVoice3,PhoneVoiceExt3,PhoneVoice4,PhoneVoiceExt4)
      select S.IDSeq as AddressIDSeq,CompanyIDSeq,PropertyIDSeq,AddressTypeCode,
             AddressLine1,AddressLine2,City,County,State,Zip,
             PhoneVoice1,PhoneVoiceExt1,PhoneVoice2,PhoneVoiceExt2,PhoneFax,Email,URL,
             SameAsPMCAddressFlag,CreatedByIDSeq,ModifiedByIDSeq,CreatedDate,ModifiedDate,
             AttentionName,GeoCodeFlag,GeoCodeMatch,Latitude,Longitude,MSANumber,
             Country,Sieb77AddrID,CountryCode,
             PhoneVoice3,PhoneVoiceExt3,PhoneVoice4,PhoneVoiceExt4
      from   DELETED S 
      where  S.IDSeq           = @LBI_AddressIDSeq 
      and    S.AddressTypecode = @LVC_AddressTypecode 
      and    S.RecordCRC       = @LN_PreviousRecordCRC

      -----------------------------
      Insert into #LT_INVOICESADDRESS(InvoiceIDSeq)
      select I.InvoiceIDSeq
      from   Invoices.dbo.Invoice I with (nolock)
      inner join
             Customers.dbo.Address A with (nolock)
      on     I.CompanyIdSeq        = A.CompanyIdSeq    
      and    I.PrintFlag           = 0      
      and    I.CompanyIDSeq        = @LVC_CompanyIDSeq
      and    I.BillToAddressTypeCode  = A.Addresstypecode
      and   (
             (I.BillToAddressTypeCode = A.Addresstypecode and 
              I.BillToAddressTypeCode like 'PB%'          and
              I.CompanyIdSeq  = A.CompanyIdSeq            and
              I.PropertyIDSeq = A.PropertyIDSeq           and 
              I.PropertyIDSeq is not null                 and
              A.PropertyIDSeq is not null                 
             )
              OR
             (I.BillToAddressTypeCode = A.Addresstypecode and 
              I.BillToAddressTypeCode NOT like 'PB%'      and
              I.CompanyIdSeq  = A.CompanyIdSeq            
             )
           )
      and (
            I.BillToAddressLine1 <> A.AddressLine1 
             OR 
            coalesce(ltrim(rtrim(I.BillToAddressLine2)),'') <> coalesce(ltrim(rtrim(A.AddressLine2)),'')
             OR 
            I.BillToCity <> A.City
             OR
            I.BillToState <> A.State
             OR 
            I.BillToZip <> A.Zip
             OR 
            coalesce(ltrim(rtrim(I.BillToCountry)),'') <> coalesce(ltrim(rtrim(A.Country)),'')
             OR
            coalesce(ltrim(rtrim(I.BillToEmailAddress)),'') <> coalesce(ltrim(rtrim(A.Email)),'')
          )
      where  I.PrintFlag              = 0      
      and    I.CompanyIDSeq           = @LVC_CompanyIDSeq
      and    I.CompanyIdSeq           = A.CompanyIdSeq
      and    I.BillToAddressTypeCode  = A.Addresstypecode

      select @LI_imin=1,@LI_iMax = count(Seq) from #LT_INVOICESADDRESS with (nolock)
      while  @LI_imin <= @LI_iMax
      begin
        select @LVC_InvoiceIDSeq = S.InvoiceIDSeq from #LT_INVOICESADDRESS S with (nolock) where S.Seq = @LI_imin
        exec INVOICES.dbo.uspINVOICES_SyncInvoiceTables @IPVC_InvoiceID=@LVC_InvoiceIDSeq
        select @LI_imin = @LI_imin +1 
      end      
      -------------------------------------------------------------------      
    end --> End for if (@LN_PreviousRecordCRC <> @LN_CurrentRecordCRC)...
    select @LI_min = @LI_min + 1
  end      
  ----------------------------------------
  --Final cleanup
  if (object_id('tempdb.dbo.#LT_DELETEDADDRESS') is not null) 
  begin
    drop table #LT_DELETEDADDRESS
  end  
  if (object_id('tempdb.dbo.#LT_INSERTEDADDRESS') is not null) 
  begin
    drop table #LT_INSERTEDADDRESS
  end
  if (object_id('tempdb.dbo.#LT_INVOICESADDRESS') is not null) 
  begin
    drop table #LT_INVOICESADDRESS
  end
  ----------------------------------------
END
GO
ALTER TABLE [customers].[Address] ADD CONSTRAINT [PK_Address] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Customers_Address_CityStateZip] ON [customers].[Address] ([City], [State], [Zip]) INCLUDE ([AddressLine1], [AddressLine2], [AddressTypeCode], [AttentionName], [CompanyIDSeq], [Country], [CountryCode], [County], [CreatedByIDSeq], [CreatedDate], [Email], [IDSeq], [ModifiedByIDSeq], [ModifiedDate], [PhoneFax], [PhoneVoice1], [PhoneVoice2], [PhoneVoiceExt1], [PhoneVoiceExt2], [PropertyIDSeq], [SameAsPMCAddressFlag], [URL]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [INCX_Customers_Address_CompanyPropertyIDSeq] ON [customers].[Address] ([CompanyIDSeq], [PropertyIDSeq], [AddressTypeCode]) INCLUDE ([AddressLine1], [AddressLine2], [AttentionName], [City], [Country], [CountryCode], [County], [CreatedByIDSeq], [CreatedDate], [Email], [IDSeq], [ModifiedByIDSeq], [ModifiedDate], [PhoneFax], [PhoneVoice1], [PhoneVoice2], [PhoneVoiceExt1], [PhoneVoiceExt2], [SameAsPMCAddressFlag], [State], [URL], [Zip]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_Address_RECORDSTAMP] ON [customers].[Address] ([RECORDSTAMP]) ON [PRIMARY]
GO
ALTER TABLE [customers].[Address] WITH NOCHECK ADD CONSTRAINT [Address_has_AddressType] FOREIGN KEY ([AddressTypeCode]) REFERENCES [customers].[AddressType] ([Code])
GO
ALTER TABLE [customers].[Address] WITH NOCHECK ADD CONSTRAINT [Address_has_CompanyIDSeq] FOREIGN KEY ([CompanyIDSeq]) REFERENCES [customers].[Company] ([IDSeq])
GO
ALTER TABLE [customers].[Address] WITH NOCHECK ADD CONSTRAINT [Address_has_CountryCode] FOREIGN KEY ([CountryCode]) REFERENCES [customers].[Country] ([Code])
GO
ALTER TABLE [customers].[Address] WITH NOCHECK ADD CONSTRAINT [Address_has_PropertyIDSeq] FOREIGN KEY ([PropertyIDSeq]) REFERENCES [customers].[Property] ([IDSeq])
GO
