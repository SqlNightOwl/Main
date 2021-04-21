SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_GetInvoiceXMLforValidation
-- Description     : This procedure is called initially to get all Invoices for Inbound Processing
-- Input Parameters: 
--      
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_GetInvoiceXMLforValidation 
-- 
-- Revision History:
-- Author          : Terry Sides
-- 03/25/2010      : Stored Procedure Created.   
-- 05/19/2011      : TFS 597   -- Scott Hensley    --  The Select "*" was causing an out of memory exception.  Updated to limited fields
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_GetInvoiceXMLforValidation]
AS
BEGIN
  SET NOCOUNT ON;
  --------------------------
  Select 
       [VersionNumber]
      ,[InvoiceIDSeq]
      ,[BillingCycleDate]
      ,[AccountIDSeq]
      ,[CustomerIDSeq]
      ,[PropertyIDSeq] 
      ,[OutboundProcessStatus]
      ,[InboundProcessStatus]
      ,[ErrorText]
      ,[PrintFlag]
      ,[EmailFlag]
      ,[BusinessUnit]
      ,[SendToEmailAddress]
      ,[InvoiceTotal]
      ,[ProductCount]
      ,[LineItemCount]
      ,[Lanvera_DeliveryMethod]
      ,[Lanvera_LineItemCount]
      ,[Lanvera_InvoiceTotal]
      ,[DocumentIDSeq]
      ,[BatchGenerationID]  
  from  INVOICES.dbo.InvoiceXML ixOutter with (nolock)
  Where ixOutter.OutboundProcessStatus = 1 
  and   ixOutter.inboundProcessStatus  = 0 
  and   ixOutter.VersionNumber = (Select Max(VersionNumber) 
                                  from   INVOICES.dbo.InvoiceXML ixInner with (NoLock)
                                  Where  ixInner.InvoiceIDSeq = ixOutter.InvoiceIDSeq
                                 )
END

GO
