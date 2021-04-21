SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : CUSTOMERS
-- Procedure Name  : [uspCUSTOMERS_GetReportParameters]
-- Description     : This procedure returns the Report List
-- 
-- OUTPUT          : RecordSet of fields describing the Report.
-- Code Example    : Exec PRODUCTS.dbo.[uspCUSTOMERS_GetReportParameters] 
-- 
-- Revision History:
-- Author          : Naval Kishore Singh
-- 07/02/2007      : Stored Procedure Created.
--
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [reports].[uspCUSTOMERS_GetReportParameters]( @ReportIDSeq int) 
AS
BEGIN
-------------------------------------------------------------------------
--to get report parameters
------------------------------------------------------------------------

SELECT 
  [Name]                                     As [Name], 
  SRSParameter                               As [SRSParameter], 
  SRSValueType                               As [SRSValueType], 
  SRSValueLength                             As [SRSValueLength], 
  IsNull(ParameterXML, '')                   As [ParameterXML],
  RequiredFlag                               As [RequiredFlag],
  Cast(IsNull(SPOnlyFlag,'0') As VarChar(1)) As [SPOnlyFlag]
FROM [CUSTOMERS].dbo.[ReportParameter] with (nolock)
WHERE ReportIDSeq = @ReportIDSeq 
ORDER BY SortSeq 

-------------------------------------------------------------------------
--to get report path
------------------------------------------------------------------------
SELECT 
  R.[Name]                                      As [Name],
  R.SRSPath                                     As [SRSPath],
  R.ExportType                                  As [ExportType],
  IsNull(SP.SPName,'')                          As [SPName],
  Cast(IsNull(Excel2007Only,'0') As VarChar(1)) As [Excel2007Only],
  LabelComments									As [LabelComments]
FROM [CUSTOMERS].dbo.[Report] R with (nolock)
LEFT OUTER JOIN [CUSTOMERS].dbo.[ReportAssociatedSPCalls] SP with (nolock)
ON R.IDSeq=SP.ReportIDSeq
WHERE R.IDSeq = @ReportIDSeq

------------------------------------------------------------------------
END

--EXEC [uspCUSTOMERS_GetReportParameters] 44
GO
