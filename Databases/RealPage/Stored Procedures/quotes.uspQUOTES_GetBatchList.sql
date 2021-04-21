SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [quotes].[uspQUOTES_GetBatchList]
	@IPI_PageNumber int = 1
	,@IPI_RowsPerPage int = 20
	,@IPBI_BatchID bigint = NULL
	,@IPBI_Submitter bigint = NULL
	,@IPI_BatchKind int = NULL
AS
BEGIN
	declare @totrows int
	select @totrows=count(1) from [dbo].[BBQBatch]
	WHERE [BatchKind]=coalesce(@IPI_BatchKind,[BatchKind])
	  AND [SubmitterID]=coalesce(@IPBI_Submitter,[SubmitterID])
	SELECT b.[ID] as [BatchID]
		  ,b.[BatchKind]
		  ,b.[TotalRequestCount],b.[CompletedRequestCount]
		  ,b.[SubmitterID]
		  ,u.[FirstName]+' '+u.[Lastname] AS [SubmitterName]
		  ,b.[Created],b.[LastProcessed]
		  ,@totrows as [TotalBatchCountForPaging]
	  FROM [dbo].[BBQBatch] b
	  LEFT OUTER JOIN [SECURITY].[dbo].[User] u ON u.[IDSeq]=b.[SubmitterID]
	WHERE b.[ID]=coalesce(@IPBI_BatchID,b.[ID])
	  AND [BatchKind]=coalesce(@IPI_BatchKind,[BatchKind])
	  AND [SubmitterID]=coalesce(@IPBI_Submitter,[SubmitterID])
	ORDER BY [Created] desc
END

GO
