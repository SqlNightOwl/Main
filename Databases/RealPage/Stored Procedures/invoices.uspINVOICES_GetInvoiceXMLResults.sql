SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-----------------------------------------------------------------------------------------------------------------------------
-- Database  Name  : Orders
-- Procedure Name  : uspINVOICES_GetInvoiceXMLResults
-- Description     : This procedure selects all rows from InvoiceXML table for @IPVC_DeliveryOptionCode and/or @IPVC_BusinessUnit for OPSEI
-- Input Parameters: @IPVC_DeliveryOptionCode      as varchar(50),@IPVC_BusinessUnit as varchar(255)
-- Syntax          : 
/*
EXEC INVOICES.dbo.uspINVOICES_GetInvoiceXMLResults  @IPVC_DeliveryOptionCode = 'Lanvera'
EXEC INVOICES.dbo.uspINVOICES_GetInvoiceXMLResults  @IPVC_DeliveryOptionCode = 'OPSEI',@IPVC_BusinessUnit='eREI'
*/
-- Revision History:
-- Author          : SRS
-- 02/21/2010      : SRS. SP Created
-----------------------------------------------------------------------------------------------------------------------------
Create PROCEDURE [invoices].[uspINVOICES_GetInvoiceXMLResults] (@IPVC_DeliveryOptionCode varchar(50)  ='Lanvera',
                                                           @IPVC_BusinessUnit       varchar(255) ='' 
                                                          )
as
BEGIN
  set nocount on;
  ------------------------------------------
  if (@IPVC_DeliveryOptionCode = 'Lanvera')
  begin
    ---If BusinessUnit= lanvera, ie. Outbound Lanvera, Send all Invoice XMLs
    Select * from INVOICES.dbo.InvoiceXML IXML with (nolock)
    Where IXML.OutboundProcessStatus = 1
    and   IXML.InboundProcessStatus  = 0    
  end
  else if (@IPVC_DeliveryOptionCode = 'OPSEI')
  begin
    select @IPVC_BusinessUnit = nullif(@IPVC_BusinessUnit,'')

    ---If BusinessUnit is not Lanvera (OPSEI), 
    --- Send Invoice XMLs that is only MarkAsPrintedFlag = 0 and SendInvoiceToClientFlag = 1
    --  and are bound for BillToDeliveryOptionCode of OPSEI
    Select * from INVOICES.dbo.InvoiceXML IXML with (nolock)
    Where IXML.OutboundProcessStatus = 1
    and   IXML.InboundProcessStatus  = 0
    and   IXML.BusinessUnit          = coalesce(@IPVC_BusinessUnit,IXML.BusinessUnit)
    and    Exists (select Top 1 1 
                   from   Invoices.dbo.Invoice I with (nolock)
                   where  IXML.InvoiceIDSeq   = I.InvoiceIDSeq
                   and    I.PrintFlag                = 1
                   and    I.MarkAsPrintedFlag        = 0
                   and    I.SendInvoiceToClientFlag  = 1
                   and    I.BillToDeliveryOptionCode = @IPVC_DeliveryOptionCode
                  )
  end
  ---------------
END
GO
