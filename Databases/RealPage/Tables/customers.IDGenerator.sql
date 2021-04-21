CREATE TABLE [customers].[IDGenerator]
(
[IDSeq] [numeric] (6, 0) NOT NULL,
[TypeIndicator] [char] (1) COLLATE SQL_Latin1_General_CP850_CI_AI NOT NULL CONSTRAINT [DF_IDGenerator_TypeIndicator] DEFAULT ('A'),
[TypeIndicatorName] [varchar] (20) COLLATE SQL_Latin1_General_CP850_CI_AI NULL CONSTRAINT [DF_IDGenerator_TypeIndicatorName] DEFAULT ('Account'),
[GeneratedDate] [datetime] NOT NULL CONSTRAINT [DF__IDGenerat__Gener__566B5B6C] DEFAULT (getdate()),
[IDGeneratorSeq] AS (stuff((([TypeIndicator]+right(datepart(year,[GeneratedDate]),(2)))+stuff('00',(3)-len(datepart(month,[GeneratedDate])),len(datepart(month,[GeneratedDate])),CONVERT([varchar](50),datepart(month,[GeneratedDate]),(0))))+'000000',(12)-len([IDSeq]),len([IDSeq]),CONVERT([varchar](50),[IDSeq],(0)))),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [customers].[TRG_CUSTOMERS_IDGENERATOR] on [customers].[IDGenerator] AFTER UPDATE
AS
if (SELECT TRIGGER_NESTLEVEL(object_ID('TRG_CUSTOMERS_IDGENERATOR'))) = 1
BEGIN   
  declare @LVC_TypeIndicator  varchar(1)
  select @LVC_TypeIndicator=TypeIndicator from DELETED
  IF   (SELECT CONVERT(BIGINT,
                       CONVERT(varchar(20),YEAR(GeneratedDate))+'00'+
                       REPLICATE('0',2-Len(MONTH(GeneratedDate))) + Convert(varchar(20),MONTH(GeneratedDate))
                       )
        FROM INSERTED where  TypeIndicator = @LVC_TypeIndicator) >
       (SELECT CONVERT(BIGINT,
                       CONVERT(varchar(20),YEAR(GeneratedDate))+'00'+
                       REPLICATE('0',2-Len(MONTH(GeneratedDate))) + Convert(varchar(20),MONTH(GeneratedDate))
                       )
        FROM DELETED where  TypeIndicator = @LVC_TypeIndicator)
  BEGIN
    begin TRY           
        Update CUSTOMERS.dbo.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
        set    IDSeq = 1
        where  TypeIndicator = @LVC_TypeIndicator      
    end TRY
    begin CATCH        
      EXEC CUSTOMERS.dbo.uspCUSTOMERS_RaiseError 'Error Generating New ID :TRG_CUSTOMERS_IDGENERATOR'
    end CATCH
  END  
END
GO
ALTER TABLE [customers].[IDGenerator] ADD CONSTRAINT [PK_CUSTOMERS_IDGenerator] PRIMARY KEY CLUSTERED  ([TypeIndicator], [IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_IDGenerator_RECORDSTAMP] ON [customers].[IDGenerator] ([RECORDSTAMP]) ON [PRIMARY]
GO
