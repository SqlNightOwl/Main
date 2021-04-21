SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [invoices].[fnGetInvoiceLogoDefinition](@IPVC_InvoiceIDSeq varchar(50)) 
returns varchar(100)
as
BEGIN  
  ---------------------------------------------
  declare @LI_SeparateInvoiceGroupNumber bigint;
  declare @LVC_LogoDefinition            varchar(100)
  ----------------------------------------------
  select top 1 @LI_SeparateInvoiceGroupNumber = I.SeparateInvoiceGroupNumber
  from   Invoices.dbo.Invoice I with (nolock)
  where  I.InvoiceIDSeq = @IPVC_InvoiceIDSeq
  ----------------------------------------------
  --Final Select
  ----------------------------------------------
  select Top 1 @LVC_LogoDefinition = coalesce(IRM.LogoDefinition,'RealPage')
  from   Products.dbo.InvoiceReportMapping IRM with (nolock)
  where  IRM.SeparateInvoiceGroupNumber = @LI_SeparateInvoiceGroupNumber
  ----------------------------------------------
  return coalesce(@LVC_LogoDefinition,'RealPage') 
END


GO
