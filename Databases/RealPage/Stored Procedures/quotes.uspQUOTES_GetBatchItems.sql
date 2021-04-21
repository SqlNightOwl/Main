SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [quotes].[uspQUOTES_GetBatchItems]
	@IPI_PageNumber int = 1
	,@IPI_RowsPerPage int = 20
	,@IPBI_BatchID bigint
AS
BEGIN
	DECLARE @totrows int;SELECT @totrows=count(1) from [dbo].[BBQRequest] WHERE [BatchID]=@IPBI_BatchID
	DECLARE @LastProc datetime
	SELECT @LastProc = [LastProcessed]
		FROM [dbo].[BBQBatch]
		WHERE [ID]=@IPBI_BatchID
	SELECT [ID] AS [RequestID]
		,[BatchID]
		,[Kind] AS [Kind]
		,ISNULL([Note],'') AS [Note]
		,[Created] AS [Created]
		,case when [Completed]<=@LastProc then [Completed] else '' end as [Completed]
		,case when [Completed]<=@LastProc then 1 else 2 end as [Status]
		,[Parameter]
		,@totrows as [TotalBatchCountForPaging]
	  FROM [dbo].[BBQRequest]
	  WHERE [BatchID]=@IPBI_BatchID
	  ORDER BY [ID] asc
  RETURN(0)

END

GO
