CREATE TABLE [documents].[IDGenerator]
(
[IDSeq] [numeric] (6, 0) NOT NULL,
[GeneratedDate] [datetime] NOT NULL CONSTRAINT [DF__IDGenerat__Gener__78A9CE29] DEFAULT (getdate()),
[DocumentIDSeq] AS (stuff((('D'+right(datepart(year,[GeneratedDate]),(2)))+stuff('00',(3)-len(datepart(month,[GeneratedDate])),len(datepart(month,[GeneratedDate])),CONVERT([varchar](50),datepart(month,[GeneratedDate]),(0))))+'000000',(12)-len([IDSeq]),len([IDSeq]),CONVERT([varchar](50),[IDSeq],(0)))),
[RECORDSTAMP] [timestamp] NOT NULL
) ON [PRIMARY]
GO
SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE TRIGGER [documents].[TRG_DOCUMENTS_IDGENERATOR] on [documents].[IDGenerator] AFTER UPDATE
AS
if (SELECT TRIGGER_NESTLEVEL(object_ID('TRG_DOCUMENTS_IDGENERATOR'))) = 1
BEGIN     
  IF   (SELECT CONVERT(BIGINT,
                       CONVERT(varchar(20),YEAR(GeneratedDate))+'00'+
                       REPLICATE('0',2-Len(MONTH(GeneratedDate))) + Convert(varchar(20),MONTH(GeneratedDate))
                       )
        FROM INSERTED) >
       (SELECT CONVERT(BIGINT,
                       CONVERT(varchar(20),YEAR(GeneratedDate))+'00'+
                       REPLICATE('0',2-Len(MONTH(GeneratedDate))) + Convert(varchar(20),MONTH(GeneratedDate))
                       )
        FROM DELETED)
  BEGIN
    begin TRY          
        Update DOCUMENTS.dbo.IDGenerator with (TABLOCKX,XLOCK,HOLDLOCK)
        set    IDSeq = 1        
    end TRY
    begin CATCH        
      EXEC CUSTOMERS.dbo.uspCUSTOMERS_RaiseError 'Error Generating New ID :TRG_DOCUMENTS_IDGENERATOR'
    end CATCH
  END  
END
GO
ALTER TABLE [documents].[IDGenerator] ADD CONSTRAINT [PK_DOCUMENTS_IDGenerator] PRIMARY KEY CLUSTERED  ([IDSeq]) ON [PRIMARY]
GO
CREATE NONCLUSTERED INDEX [IXN_IDGenerator_RECORDSTAMP] ON [documents].[IDGenerator] ([RECORDSTAMP]) ON [PRIMARY]
GO
