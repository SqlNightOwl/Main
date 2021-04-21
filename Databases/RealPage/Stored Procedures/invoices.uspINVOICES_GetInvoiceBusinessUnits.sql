SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspINVOICES_GetInvoiceBusinessUnits
-- Description     : This procedure selects all qualifiying Business Units
-- Input Parameters: @IPVC_DeliveryOptionCode      as varchar(50)
-- Syntax          : 
/*
EXEC INVOICES.dbo.uspINVOICES_GetInvoiceBusinessUnits  @IPVC_DeliveryOptionCode = 'Lanvera'
EXEC INVOICES.dbo.uspINVOICES_GetInvoiceBusinessUnits  @IPVC_DeliveryOptionCode = 'OPSEI'
*/
-- Revision History:
-- Author          : SRS
-- 02/21/2010      : SRS. SP Created
-----------------------------------------------------------------------------------------------------------------------------
Create PROCEDURE [invoices].[uspINVOICES_GetInvoiceBusinessUnits] (@IPVC_DeliveryOptionCode varchar(50)  ='Lanvera'
                                                             )
as
BEGIN
  set nocount on;
  ------------------------------------------
  if (@IPVC_DeliveryOptionCode = 'Lanvera')
  begin
    ---If BusinessUnit= lanvera, ie. Outbound Lanvera, Send all Invoice XMLs
    Select IXML.BusinessUnit
    from   INVOICES.dbo.InvoiceXML IXML with (nolock)
    Where  IXML.OutboundProcessStatus = 1
    and    IXML.InboundProcessStatus  = 0
    group by IXML.BusinessUnit    
  end
  else if (@IPVC_DeliveryOptionCode = 'OPSEI')
  begin  
    Select IXML.BusinessUnit
    from   INVOICES.dbo.InvoiceXML IXML with (nolock)
    Where  IXML.OutboundProcessStatus = 1
    and    IXML.InboundProcessStatus  = 0    
    and    Exists (select Top 1 1 
                   from   Invoices.dbo.Invoice I with (nolock)
                   where  IXML.InvoiceIDSeq   = I.InvoiceIDSeq
                   and    I.PrintFlag                = 1
                   and    I.MarkAsPrintedFlag        = 0
                   and    I.SendInvoiceToClientFlag  = 1
                   and    I.BillToDeliveryOptionCode = @IPVC_DeliveryOptionCode
                  )
    group by IXML.BusinessUnit 
  end
  ---------------
END
GO
