SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
----------------------------------------------------------------------------------------------------
-- Database  Name  : Invoices
-- Procedure Name  : uspINVOICES_UpdateInvoiceXMLFromValidation
-- Description     : This procedure is called on Inbound from Lanvera section to update InvoiceXML
-- Input Parameters: 1. @IPVC_BatchGenerationID  as varchar(100),@IPVC_BusinessUnit (Optional)
--      
-- Code Example    : Exec INVOICES.dbo.uspINVOICES_GetInvoiceAsXML passing parameters.
--                                 
-- 
-- Revision History:
-- Author          : Terry Sides
-- 02/19/2010      : Stored Procedure Created.              
------------------------------------------------------------------------------------------------------
CREATE PROCEDURE [invoices].[uspINVOICES_UpdateInvoiceXMLFromValidation] (@InvoiceIDSeq           varchar(13),
                                                                     @Lanvera_DeliveryMethod varchar(10),
                                                                     @Lanvera_LineItemCount  int,
                                                                     @Lanvera_InvoiceTotal   money,                                                                     
                                                                     @DocumentID             varchar(13),
                                                                     @IPBI_UserIDSeq         bigint = NULL
                                                                    )
AS
BEGIN
  set nocount on;
  ---------------------------------
  declare @LI_VersionNumber  bigint;
  ---------------------------------
  BEGIN TRY
    select @LI_VersionNumber = Max(VersionNumber) 
    from   InvoiceXML with (NoLock)
    where  InvoiceIDSeq = @InvoiceIDSeq

    Update InvoiceXML 
    set    Lanvera_DeliveryMethod = @Lanvera_DeliveryMethod,
           Lanvera_LineItemCount  = @Lanvera_LineItemCount,
           Lanvera_InvoiceTotal   = @Lanvera_InvoiceTotal,
           DocumentIDSeq          = @DocumentID,
           InboundProcessStatus   = 1,
           ModifiedByIDSeq        = @IPBI_UserIDSeq,
           ModifiedDate           = Getdate()
   Where  InvoiceIDSeq   = @InvoiceIDSeq 
   and    VersionNumber  = @LI_VersionNumber
  END TRY
  BEGIN CATCH
    declare @ErrorMessage    varchar(1000);
    declare @ErrorSeverity   Int;
    declare @ErrorState      Int;
    declare @ErrorText       varchar(8000);
    Set @ErrorMessage     = 'InBound uspINVOICES_UpdateInvoiceXMLFromValidation '+ ERROR_MESSAGE();
    Set @ErrorSeverity    = ERROR_SEVERITY();
    Set @ErrorState       = ERROR_STATE();  
    Set @ErrorText        = @ErrorMessage + @ErrorSeverity + @ErrorState;

    Update InvoiceXML 
    set    InboundProcessStatus   = 2,
           ModifiedByIDSeq        = @IPBI_UserIDSeq,
           ModifiedDate           = Getdate()
    Where  InvoiceIDSeq   = @InvoiceIDSeq 
    and    VersionNumber  = @LI_VersionNumber
  END CATCH
END

GO
