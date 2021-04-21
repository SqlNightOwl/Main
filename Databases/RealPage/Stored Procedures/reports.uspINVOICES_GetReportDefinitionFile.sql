SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
exec INVOICES.dbo.uspINVOICES_GetReportDefinitionFile @IPVC_InvoiceID='I0905016642'
exec INVOICES.dbo.uspINVOICES_GetReportDefinitionFile @IPVC_InvoiceID='I0905016650'
exec INVOICES.dbo.uspINVOICES_GetReportDefinitionFile @IPVC_InvoiceID='I0905016658'
exec INVOICES.dbo.uspINVOICES_GetReportDefinitionFile @IPVC_InvoiceID='I0905016658'
*/
----------------------------------------------------------------------------------------------------  
-- Database  Name  : INVOICES  
-- Procedure Name  : uspINVOICES_GetReportDefinitionFile  
-- 
-- Description     : Gets Report Definition File to Use for Generate Invoice
--
-- Input Parameters: @IPVC_InvoiceID  varchar(50)
--
-- Returns         : Report Definition File Record.
--                     
-- Code Example    : Exec uspINVOICES_GetReportDefinitionFile
--   
-- Revision History:  
-- Author          : SRS
-- 09/23/2009      : Stored Procedure Created.  
--  
------------------------------------------------------------------------------------------------------ 
CREATE PROCEDURE [reports].[uspINVOICES_GetReportDefinitionFile] (@IPVC_InvoiceID       varchar(50)
                                                     )
AS
BEGIN   
  set nocount on;
  ---------------------------------------------
  declare @LI_SeparateInvoiceGroupNumber bigint;
  ----------------------------------------------
  select top 1 @LI_SeparateInvoiceGroupNumber = I.SeparateInvoiceGroupNumber
  from   Invoices.dbo.Invoice I with (nolock)
  where  I.InvoiceIDSeq = @IPVC_InvoiceID
  ----------------------------------------------
  --Final Select
  ----------------------------------------------
  select Top 1 coalesce(IRM.ReportDefinitionFile,'Invoice1') as ReportDefinitionFile 
  from   Products.dbo.InvoiceReportMapping IRM with (nolock)
  where  IRM.SeparateInvoiceGroupNumber = @LI_SeparateInvoiceGroupNumber
  ----------------------------------------------
END
GO
